function [TurboErr, n, BlockLengthHalf, place] = AM2_4(H, maxFrames, K, snrRange, calcPlace)
% AM2_4 Szimulációs mag az LDPC kódoláshoz
% Bemenetek:
%   H         - Paritásellenőrző mátrix (ritka/sparse logikai mátrix)
%   maxFrames - Szimulált keretek száma SNR pontonként
%   K         - Kódolt blokkok száma (alapértelmezett: 20)
%   snrRange  - SNR (Jel-zaj viszony) tartomány vektor
%   calcPlace - (0/1) Logikai kapcsoló a 'place' vektor kiszámításához
%
% Kimenetek:
%   TurboErr  - A kiszámolt bithibaarány vektor (BER)
%   n         - Információs bitek száma
%   BlockLengthHalf - Fél blokkhossz
%   place     - Helyvektor (opcionális, üres [] ha calcPlace == 0)

% Alapértelmezett értékek kezelése, ha nem adnánk meg mindent
if nargin < 5 || isempty(calcPlace), calcPlace = 0; end
if nargin < 4 || isempty(snrRange), snrRange = 1:0.5:5; end
if nargin < 3 || isempty(K), K = 20; end
if nargin < 2 || isempty(maxFrames), maxFrames = 1000; end

% Kódoló és Dekódoló objektumok inicializálása
cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);

n = cfgLDPCEnc.NumInformationBits;
BlockLengthHalf = cfgLDPCDec.BlockLength / 2;

numframes = 1;
TurboErr = zeros(1, length(snrRange)); % Előfoglalás a sebességért

if calcPlace
    place = zeros(1, K);
else
    place = [];
end

for snr_idx = 1:length(snrRange)
    snr = snrRange(snr_idx);
    error_count = zeros(1, maxFrames);
    
    for k_idx = 1:maxFrames
        data = cell(1, K);
        codedData = cell(1, K);
        cD1 = cell(1, K);
        
        for j = 1:K
            data{j} = randi([0 1], n, numframes, 'int8');
        end
        
        for j = 1:K
            codedData{j} = ldpcEncode(data{j}, cfgLDPCEnc);
            cD1{j} = reshape(codedData{j}, [2 BlockLengthHalf])';
        end
        
        input = pskmod(cD1{1}(:,1), 2, 0);
        for j = 1:K-1
            input1 = bi2de([cD1{j}(:,2), cD1{j+1}(:,1)], "left-msb");
            input = [input; pskmod(input1, 4, pi/4)];
        end
        input = [input; pskmod(cD1{K}(:,2), 2, 0)];
        
        output = awgn(input, snr, 'measured');
        
        LLR = cell(1, K);
        decodedData = cell(1, K);
        ErrCount = zeros(1, K);
        
        for j = 1:K-1
            LLR1Half = pskdemod(output(BlockLengthHalf*(j-1)+1:BlockLengthHalf*j),2,0,OutputType="llr");
            LLR2Half = reshape(pskdemod(output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1)),4,pi/4,OutputType="llr"),[2 BlockLengthHalf])';
            LLR{j} = [LLR1Half, LLR2Half(:,1)];
            LlrActual = LLR{j}';
            
            decodedData{j} = ldpcDecode(LlrActual(:), cfgLDPCDec, 10);
            
            EstimatedCodeword = ldpcEncode(decodedData{j}, cfgLDPCEnc);
            EstimatedCodeword = reshape(EstimatedCodeword, [2 BlockLengthHalf])';
            SecondPartECWinFourier = pskmod(EstimatedCodeword(:,2), 2, pi/2);
            output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1)) = output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1)) - 1/sqrt(2)*SecondPartECWinFourier;    
        end
        
        % Itt kicseréltem a keménykódolt 20-as számokat a 'K' változóra a rugalmasságért!
        LLR{K} = reshape(pskdemod(output(BlockLengthHalf*(K-1)+1:BlockLengthHalf*(K+1)),2,0,OutputType="llr"),[BlockLengthHalf 2]);
        LlrActual = LLR{K}';
        decodedData{K} = ldpcDecode(LlrActual(:), cfgLDPCDec, 10);
        
        for j = 1:K
            ErrCount(j) = biterr(data{j}, decodedData{j});
        end
        
        error_count(k_idx) = sum(ErrCount)/K;
        
        if calcPlace && any(ErrCount ~= 0)
            [~, j_max] = max(ErrCount);
            place(j_max) = place(j_max) + 1;
        end
    end
    TurboErr(snr_idx) = mean(error_count)/n;
end

end