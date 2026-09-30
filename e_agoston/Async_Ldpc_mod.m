
function [BlockLengthHalf, n, LdpcErr_2] = Async_Ldpc_mod(H, snr_range, K, numTrials)
% ASYNC_LDPC  Tobbfelhasznalos (szuperponalt), aszinkron QPSK-s LDPC
% BER-szimulacio (MATLAB R2019 kompatibilis verzio).
%
% Bemenet:
%   H         - parity-check matrix (mar "encoder-ready", pl. make_h_encodable utan)
%   snr_range - a lefuttatando SNR-ertekek (dB), pl. 2:0.5:8
%   K         - egyidejuleg szuperponalt kodszavak (felhasznalok) szama
%   numTrials - (opcionalis) probak szama SNR-ertekenkent, alapertelmezett 1000
%
% Kimenet:
%   BlockLengthHalf - a H matrix N kodszohosszanak fele 
%   n               - az adott kodnak az infobit hossza (N-M)
%   LdpcErr_2       - BER-ertekek vektora

if nargin < 2 || isempty(snr_range)
    snr_range = 2:0.5:8;     
end
if nargin < 3 || isempty(K)
    K = 20;       
end
if nargin < 4 || isempty(numTrials)
    numTrials = 1000;
end

%% LDPC encoder/decoder elokeszitese (System Object modszer)
% H matrix mereteibol kinyerjuk a parametereket:
[M_H, N_H] = size(H);
n = N_H - M_H;
BlockLengthHalf = N_H / 2;
maxnumiter = 10; % Number of Iteration for the belief-propagation decoder
numframes = 1; 
place = zeros(1, K); 

% 2019-ben használt System Object-ek letrehozasa:
cfgLDPCEnc = comm.LDPCEncoder('ParityCheckMatrix', H);
cfgLDPCDec = comm.LDPCDecoder('ParityCheckMatrix', H, 'MaximumIterationCount', maxnumiter);

%% LDPC szimulacio SNR-enkent
LdpcErr_2 = [];
for snr = snr_range
    err = zeros(1, numTrials);
    for k = 1:numTrials
        % --- K db kódszó véletlen infóbitjeinek generálása és kódolása ---
        for j = 1:K
            % A comm.LDPCEncoder alapbol double tipust preferal int8 helyett
            data{j} = randi([0 1], n, numframes); 
        end
        for j = 1:K
            % ldpcEncode() helyett a step() fuggvenyt hasznaljuk az objektumhoz
            codedData{j} = step(cfgLDPCEnc, data{j}); 
            cD1{j} = reshape(codedData{j}, [2 BlockLengthHalf])';
        end
        
        % --- QPSK-szuperpozíciós moduláció: a kódszavak egymásba fésülve ---
        input = pskmod(cD1{1}(:, 1), 2, 0);
        for j = 1:K-1
            input1 = bi2de([cD1{j}(:, 2), cD1{j+1}(:, 1)], 'left-msb'); % Szimpla aposztrof
            input = [input; pskmod(input1, 4, pi/4)];
        end
        input = [input; pskmod(cD1{K}(:, 2), 2, 0)];
        output = awgn(input, snr);
        
        % --- Sorbani dekódolás és interferencia-kioltás ---
        for j = 1:K-1
            % OutputType="llr" kicserelve 'OutputType', 'llr' formara
            LLR1Half{j} = pskdemod(output(BlockLengthHalf*(j-1)+1:BlockLengthHalf*j), 2, 0, 'OutputType', 'llr');
            LLR2Half = reshape(pskdemod(output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1)), 4, pi/4, 'OutputType', 'llr'), [2 BlockLengthHalf])';
            LLR{j} = [LLR1Half{j}, LLR2Half(:, 1)];
            LlrActual = LLR{j}';
            
            % ldpcDecode() helyett step() hivas
            decodedData{j} = step(cfgLDPCDec, LlrActual(:)); 
            
            % Ujrakodolas
            EstimatedCodeword = step(cfgLDPCEnc, decodedData{j});
            EstimatedCodeword = reshape(EstimatedCodeword, [2 BlockLengthHalf])';
            
            SecondPartECWinFourier = pskmod(EstimatedCodeword(:, 2), 2, pi/2);
            output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1)) = output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1)) - 1/sqrt(2)*SecondPartECWinFourier;
        end
        
        LLR{K} = reshape(pskdemod(output(BlockLengthHalf*(K-1)+1:BlockLengthHalf*(K+1)), 2, 0, 'OutputType', 'llr'), [BlockLengthHalf 2]);
        LlrActual = LLR{K}';
        
        % Utolso felhasznalo dekodolasa
        decodedData{K} = step(cfgLDPCDec, LlrActual(:));
        
        % --- Hibaszámlálás ---
        for j = 1:K
            ErrCount(j) = biterr(data{j}, decodedData{j});
        end
        err(k) = sum(ErrCount) / K;
        if any(ErrCount)
            [~, j_max] = max(ErrCount); % j_max, hogy ne írja felül a ciklusváltozót
            place(j_max) = place(j_max) + 1;
        end
    end
    LdpcErr_2(end+1) = mean(err) / n;
    snr
end
end
