clear;

%%FONTOS!!! 
% kell ehhez a kódhoz a 'read_alist_2.m' fv. és a 'make_h_encodable.h' fv. hogy működjön!

% Ez a script egy adott mappában lévő alist-fájlokban leírt LDPC-kódokon
% (parity-check mátrixokon) fut le sorban, és mindegyikhez leméri a
% bithiba-arányát (BER) egy SNR-tartományon.
%
% Minden fájlhoz kimenetként egy .mat fájlt ment a program, amiben:
% 'BlockLengthHalf', 'n', 'K', 'LdpcErr_2', 'snr_range' vannak elmentve:
%
% K - kódszavak száma
% n - az adott kódnak az infóbit hossza (N-M)
% LdpcErr_2 -  a tényleges eredmény, egy vektor, ahol minden elem egy adott
%   SNR-értékhez tartozó átlagos bithiba-arány (BER)
% BlockLengthHalf - A H mátrix N hosszú kódjának a fele
% snr_range - ez azt adja meg, hogy milyen pontossággal futtattuk le a
%   kódot, pl. hogy 2:0,5:8 (2-től 8-ig 0,5-ösével a számok)
inputFolderName = 'Par WiMax alist';% a fájl nevének a formátumának olyannak kell lennie, hogy:
%"*Fájl neve* alist", ez azért kell, hogy majd az output fájl lehessen ugyanolyan néven, csupán az mat
outputFolderName = strrep(inputFolderName, 'alist', 'mat');
if ~exist(outputFolderName, 'dir')
    mkdir(outputFolderName);
end
%% Bemeneti fájlok összegyűjtése
% .txt ÉS .alist kiterjesztésű fájlokat is keresünk (nem csak
% a szigorúan ".alist.txt"-re végződőket), mert a fájlok formátuma
% fájlonként eltérő.
fileListTxt = dir(fullfile(inputFolderName, '*.txt'));
fileListAlist = dir(fullfile(inputFolderName, '*.alist'));
fileList = [fileListTxt; fileListAlist];
folderSize = length(fileList);
if folderSize == 0
    error('Nem talalhatoak .txt vagy .alist fajlok a "%s" mappaban! Ellenorizd a mappa nevet.', inputFolderName);
end
%% Fájlonkénti feldolgozás
% A try/catch miatt egy hibás/nem támogatott formátumú fájl nem állítja
% le a teljes futást, csak kimarad, és a program a következő fájllal
% folytatja.
for i = 1:folderSize
    % A fájl létrehozása:
    currentFileName = fileList(i).name;
    inputPath = fullfile(inputFolderName, currentFileName);
    [~, baseName, ~] = fileparts(currentFileName);% itt leválasztjuk a fájl nevét, pl. hogy wimax_0.75A
    baseName = strrep(baseName, '.alist', '');% ha ".alist.txt" formátumú volt a név
    outputPath = fullfile(outputFolderName, [char(baseName), '.mat']);
    try
        %% H mátrix beolvasása és LDPC-encoder/decoder előkészítése
        [H, N, ~] = read_alist_2(inputPath);   % az eredeti M-et eldobjuk, mert amúgy is felülírnánk
        if mod(N, 2) ~= 0
            % Az itt használt QPSK-szuperpozíciós séma bitpáronként dolgozik
            % (lásd BlockLengthHalf = N/2), ezért csak páros N-ű kódokkal
            % működik.
            fprintf("Kihagyva: %s (N=%d paratlan, ez a modulacio csak paros N-nel mukodik)\n", baseName, N);
            continue;
        end
        [H, M] = make_h_encodable(H);   % biztosítja, hogy ldpcEncoderConfig el tudja fogadni H-t
        n = N - M;
        cfgLDPCEnc = ldpcEncoderConfig(H);
        numframes = 1;
        cfgLDPCDec = ldpcDecoderConfig(H);
        BlockLengthHalf = N/2;
        K = 20; % Number of codewords to process
        LdpcErr_2 = [];
        place = zeros(1, K);% Itt eredetileg az volt, hogy place zeros(1,20)
        snr_range = 2:0.5:8;% Hogy ne legyen 2 órás a futási idő, ezt érdemes sok fájl esetén (2+) lejjebb venni.
        %% LDPC szimuláció SNR-enként
        for snr = snr_range
            error = zeros(1, 1000);
            for k = 1:1000
                % --- K db kódszó véletlen infóbitjeinek generálása és kódolása ---
                for j = 1:K
                    data{j} = randi([0 1], n, numframes, 'int8');
                end
                for j = 1:K
                    codedData{j} = Code(data{j}, cfgLDPCEnc);
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
                    decodedData{j} = Decode(LlrActual(:), cfgLDPCDec);
                    EstimatedCodeword = Code(decodedData{j}, cfgLDPCEnc);
                    EstimatedCodeword = reshape(EstimatedCodeword, [2 BlockLengthHalf])';
                    SecondPartECWinFourier = pskmod(EstimatedCodeword(:, 2), 2, pi/2);
                    output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1)) = output(BlockLengthHalf*j+1:BlockLengthHalf*(j+1)) - 1/sqrt(2)*SecondPartECWinFourier;
                end
                LLR{K} = reshape(pskdemod(output(BlockLengthHalf*(K-1)+1:BlockLengthHalf*(K+1)), 2, 0, OutputType="llr"), [BlockLengthHalf 2]);% Itt eredetileg a K-k helyett 20-asok voltak.
                LlrActual = LLR{K}';
                decodedData{K} = Decode(LlrActual(:), cfgLDPCDec);
                % --- Hibaszámlálás ---
                for j = 1:K
                    ErrCount(j) = biterr(data{j}, decodedData{j});
                end
                error(k) = sum(ErrCount) / K;
                if any(ErrCount)% ErrCount ~= 0-t kicseréltem erre, nem tudom, hogy így jobb/rosszabb-e, de nem dob hibát
                    [m, j] = max(ErrCount);
                    place(j) = place(j) + 1;
                end
            end
            LdpcErr_2(end+1) = mean(error) / n;
            snr
        end
        %% Eredmény mentése
        save(outputPath, 'BlockLengthHalf', 'n', 'K', 'LdpcErr_2', 'snr_range');
        fprintf("Mentve %s.mat\n", baseName);
    catch ME
        fprintf("Kihagyva: %s - hiba: %s\n", currentFileName, ME.message);
        continue;
    end
end
%% Segédfüggvények: LDPC kódolás és dekódolás
function output = Code(InfBits, Params)
output = ldpcEncode(InfBits, Params);
end
function EstimatedInfBits = Decode(LogLikelihoodRation, Params)
maxnumiter = 10;
EstimatedInfBits = ldpcDecode(LogLikelihoodRation, Params, maxnumiter);
end
fprintf("A program lefutott.\n");
