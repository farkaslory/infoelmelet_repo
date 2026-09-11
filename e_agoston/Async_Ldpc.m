function [BlockLengthHalf, n, LdpcErr_2] = Async_Ldpc(H, snr_range, K, numTrials)
% ASYNC_LDPC  Tobbfelhasznalos (szuperponalt), aszinkron QPSK-s LDPC
% BER-szimulacio.
%
% A Sync_Ldpc-vel ellentetben itt K db LDPC-kodszo van egyszerre, egy
% szimbolummal eltolva, QPSK-szuperpozicioval egymasba fesulve modulalva
% egyetlen jelfolyamba, majd soros interferencia-kioltassal (successive
% interference cancellation) dekodolva: a mar dekodolt kodszavakat
% ujrakodoljuk, es a hozzajuk tartozo jelet levonjuk a maradek jelbol,
% mielott a kovetkezo kodszot dekodolnank.
%
% Bemenet:
%   H         - parity-check matrix (mar "encoder-ready", pl. make_h_encodable utan)
%   snr_range - a lefuttatando SNR-ertekek (dB), pl. 2:0.5:8
%   K         - egyidejuleg szuperponalt kodszavak (felhasznalok) szama
%   numTrials - (opcionalis) probak szama SNR-ertekenkent, alapertelmezett 1000
%
% Kimenet:
%   BlockLengthHalf - a H matrix N kodszohosszanak fele (QPSK szimbolumok szama / kodszo)
%   n               - az adott kodnak az infobit hossza (N-M)
%   LdpcErr_2       - BER-ertekek vektora, snr_range-nek megfelelo sorrendben
%
% Hasznalat a fo scriptben (ugyanugy, mint Sync_Ldpc eseten, a H mar
% make_h_encodable-on atesett valtozat legyen):
%   [BlockLengthHalf, n, LdpcErr_2] = Async_Ldpc(H, snr_range, K, numTrials);
%   save(outputPath, 'BlockLengthHalf', 'n', 'K', 'LdpcErr_2', 'snr_range');
if nargin < 2 || isempty(snr_range)
    snr_range = 2:0.5:8;     
end
if nargin < 3 || isempty(K)
    K = 20;       
end
if nargin < 4 || isempty(numTrials)
    numTrials = 1000;
end

%% LDPC encoder/decoder elokeszitese
% Ugyanugy, mint Sync_Ldpc-ben: a konfiguracio itt, a H matrixbol epul
% fel, igy a fuggveny onmagaban is mukodik. (Az eredeti valtozatban a
% Code/Decode hivasok a fo script vegen definialt sajat wrapper-
% fuggvenyeket hasznaltak, amik kulon fajlbol nem lettek volna
% lathatoak - itt ezert kozvetlenul ldpcEncode/ldpcDecode-ot hivunk,
% ugyanugy, ahogy Sync_Ldpc is teszi.)
cfgLDPCEnc = ldpcEncoderConfig(H);
cfgLDPCDec = ldpcDecoderConfig(H);
n = cfgLDPCEnc.NumInformationBits;
BlockLengthHalf = cfgLDPCDec.BlockLength / 2;
maxnumiter = 10; % Number of Iteration for the belief-propagation decoder

numframes = 1; % egy kodszo/proba SNR-ertekenkent (az eredeti kodban ez a valtozo definialatlan volt)

place = zeros(1, K); % diagnosztika: melyik "felhasznalonal" (kodszonal) volt a legtobb hiba egy-egy probaban

%% LDPC szimulacio SNR-enkent
LdpcErr_2 = [];
for snr = snr_range
    err = zeros(1, numTrials);
    for k = 1:numTrials
        % --- K db kódszó véletlen infóbitjeinek generálása és kódolása ---
        for j = 1:K
            data{j} = randi([0 1], n, numframes, 'int8');
        end
        for j = 1:K
            codedData{j} = ldpcEncode(data{j}, cfgLDPCEnc);
            cD1{j} = reshape(codedData{j}, [2 BlockLengthHalf])';
        end

        % --- QPSK-szuperpozíciós moduláció: a kódszavak egymásba fésülve ---
        input = pskmod(cD1{1}(:, 1), 2, 0);
        for j = 1:K-1
            input1 = bi2de([cD1{j}(:, 2), cD1{j+1}(:, 1)], "left-msb");
            input = [input; pskmod(input1, 4, pi/4)];
        end
        input = [input; pskmod(cD1{K}(:, 2), 2, 0)];
        output = awgn(input, snr);

        % --- Sorbani dekódolás és interferencia-kioltás ---
        for j = 1:K-1
            LLR1Half{j} = pskdemod(output(BlockLengthHalf*(j-1)+1:BlockLengthHalf*j), 2, 0, OutputType="llr");
            LLR2Half = reshape(pskdemod(output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1)), 4, pi/4, OutputType="llr"), [2 BlockLengthHalf])';
            LLR{j} = [LLR1Half{j}, LLR2Half(:, 1)];
            LlrActual = LLR{j}';
            decodedData{j} = ldpcDecode(LlrActual(:), cfgLDPCDec, maxnumiter);
            EstimatedCodeword = ldpcEncode(decodedData{j}, cfgLDPCEnc);
            EstimatedCodeword = reshape(EstimatedCodeword, [2 BlockLengthHalf])';
            SecondPartECWinFourier = pskmod(EstimatedCodeword(:, 2), 2, pi/2);
            output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1)) = output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1)) - 1/sqrt(2)*SecondPartECWinFourier;
        end
        LLR{K} = reshape(pskdemod(output(BlockLengthHalf*(K-1)+1:BlockLengthHalf*(K+1)), 2, 0, OutputType="llr"), [BlockLengthHalf 2]);
        LlrActual = LLR{K}';
        decodedData{K} = ldpcDecode(LlrActual(:), cfgLDPCDec, maxnumiter);

        % --- Hibaszámlálás ---
        for j = 1:K
            ErrCount(j) = biterr(data{j}, decodedData{j});
        end
        err(k) = sum(ErrCount) / K;
        if any(ErrCount)
            [~, j] = max(ErrCount);
            place(j) = place(j) + 1;
        end
    end
    LdpcErr_2(end+1) = mean(err) / n;
    snr
end
end