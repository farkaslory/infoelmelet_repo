function batchSimu(inputFolder, outputFolder, snrRange, maxFrames, K)
    % BATCHSIMU - Egy mappa összes .txt AList fájlját feldolgozza

    % Ha nincsenek megadva paraméterek, alapértelmezetteket használunk
    if nargin < 1, inputFolder = 'Matrixok'; end
    if nargin < 2, outputFolder = 'Eredmenyek'; end
    if nargin < 3, snrRange = 1:0.5:5; end
    if nargin < 4, maxFrames = 100; end
    if nargin < 5, K = 20; end

    % Ellenőrizzük, létezik-e a bemeneti mappa
    if ~isfolder(inputFolder)
        error('A bemeneti mappa nem létezik: %s', inputFolder);
    end

    % Ha a kimeneti mappa nem létezik, létrehozzuk
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    % Kikeressük az összes .txt fájlt a bemeneti mappából
    txtFiles = dir(fullfile(inputFolder, '*.txt'));
    numFiles = length(txtFiles);

    if numFiles == 0
        fprintf('Nem találtam .txt fájlt a %s mappában.\n', inputFolder);
        return;
    end

    fprintf('--- Batch feldolgozás indítása: %d fájl ---\n', numFiles);
    
    for i = 1:numFiles
        % Fájlnevek összeállítása
        baseFileName = txtFiles(i).name;
        [~, nameWithoutExt, ~] = fileparts(baseFileName);
        
        fullInputPath = fullfile(inputFolder, baseFileName);
        matOutputPath = fullfile(outputFolder, [nameWithoutExt, '.mat']);
        matOutputSPath = fullfile(outputFolder, [nameWithoutExt, '_S.mat']);
        
        fprintf('[%d/%d] Feldolgozás: %s ... ', i, numFiles, baseFileName);
        
        try
            % 1. Mátrix beolvasása a korábbi függvénnyel
            H_sparse = readTurboCode(fullInputPath);
        
            % 2. Szimuláció futtatása a magfüggvénnyel
            % Paraméterek: H, maxFrames, K, snrRange, calcPlace (0 vagy 1)
            [TurboErr, n, BlockLengthHalf, place] = AM4_16(H_sparse, maxFrames, K, snrRange, 1);
        
            % 3. Eredmények kimentése a .mat fájlba
            save(matOutputPath, 'TurboErr', 'n', 'BlockLengthHalf', 'snrRange', 'place');

            % 4. Szimuláció futtatása a magfüggvénnyel szinkronra
            % Paraméterek: H, maxFrames, K, snrRange, calcPlace (0 vagy 1)
            [SyncErr, n, BlockLengthHalf] = Sync_LDPC_16(H_sparse, K*maxFrames, snrRange);
        
            % 5. Eredmények kimentése a .mat fájlba
            save(matOutputSPath, 'SyncErr', 'n', 'BlockLengthHalf', 'snrRange');
           
            fprintf('KÉSZ.\n');
            
        catch ME
            % Ha hiba van (pl. nem teljes rangú mátrix), átugorjuk
            fprintf('HIBA!\n  Ok: %s\n', ME.message);
        end
    end
end