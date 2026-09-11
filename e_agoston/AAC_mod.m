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
    
    numTrials = 1000;% Az SNR is egy finomítási tényező, de ez azt csinálja, hogy mennyire mélyen számolja ki minden egyes SNR értéket (1000 az ajánlott)
    
    snr_range = 2:0.5:8; % Hogy ne legyen 2 órás a futási idő, ezt érdemes sok fájl esetén (2+) lejjebb venni.
    
    K = 20; % Number of codewords to process % Ezek csak az aszinkron kódoknál kellenek, szinkronnál csak lehet úgy hagyni ahogy van
    
    inputFolderName = 'Random LDPCk alist';% a fájl nevének a formátumának olyannak kell lennie, hogy:
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
    
            %% LDPC szimuláció SNR-enként
    
            [LdpcErr_2, n, BlockLengthHalf, ~] = AM4_16(H, numTrials, K, snr_range);% Ide kell beilleszteni az áhított algoritmust, csak figyelni kell rá, hogy a BlockLengthHalf, n és a LdpcErr_2 az ki legyen valahol számolva (általában az algoritmus adja vissza)
    
            %% Eredmény mentése
            save(outputPath, 'BlockLengthHalf', 'n', 'K', 'LdpcErr_2', 'snr_range');% szinkron-van is el lesz mentve a K, de valójában nincsen felhasználva
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
