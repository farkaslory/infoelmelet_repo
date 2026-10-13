function runSim(funcName, inputFolder, outputFolder, opts)
% RUNSIM Kötegelt szimulációfuttató az összes bemeneti mátrixra
%
% Bemenetek:
%   funcName     - Futtatandó moduláció: "AM2_4", "AM4_16", "Sync_LDPC", "Sync_LDPC_16"
%   inputFolder  - Bemeneti mátrixokat (.txt) tartalmazó mappa
%   outputFolder - Kimeneti eredmények (.mat) célmappája
%   opts         - Opcionális szimulációs paraméterek (Name=Value)

arguments
    funcName     (1,1) string
    inputFolder  (1,1) string = "bemeneti_matrixok"
    outputFolder (1,1) string = "osszehasonlito_eredmenyek"
    opts.maxFrames     (1,1) double = 1000
    opts.snrRange      (1,:) double = 15:0.5:25
    opts.K             (1,1) double = 20
end

% 1. Párhuzamos környezet ellenőrzése
if isempty(gcp('nocreate'))
    parpool;
end

% 2. Mappák ellenőrzése
if ~isfolder(inputFolder)
    error("batchRunSimulation:folderNotFound", ...
        "A bemeneti mappa nem található: %s", inputFolder);
end
if ~isfolder(outputFolder), mkdir(outputFolder); end

txtFiles = dir(fullfile(inputFolder, "*.txt"));
numFiles = numel(txtFiles);
if numFiles == 0
    error("batchRunSimulation:noFiles", ...
        "Nem található .txt mátrixfájl itt: %s", inputFolder);
end

% Automatikus fájlnév-címke a korábbi plotter kompatibilitáshoz
switch funcName
    case "Sync_LDPC",    saveTag = "Sync_QPSK";
    case "Sync_LDPC_16", saveTag = "Sync_16QAM";
    otherwise,           saveTag = funcName;
end

fprintf("\n=======================================================\n");
fprintf(" KÖTEGELT SZIMULÁCIÓ INDÍTÁSA: %s (%d db mátrix)\n", funcName, numFiles);
fprintf(" Bemenet: %s  -->  Kimenet: %s\n", inputFolder, outputFolder);
fprintf("=======================================================\n");

% 3. Végighaladás a mátrixokon
for i = 1:numFiles
    currentFile = txtFiles(i).name;
    baseName    = erase(currentFile, ".txt");
    matrixPath  = fullfile(inputFolder, currentFile);

    fprintf("\n[%d/%d] Feldolgozás: %s\n", i, numFiles, baseName);

    try
        H = readTurboCode(matrixPath);

        % Univerzális modulációs motor hívása
        res = runMod(funcName, H, ...
            maxFrames=opts.maxFrames, ...
            snrRange=opts.snrRange, ...
            K=opts.K);

        % .mat mentés a plotter számára szabványos változónevekkel
        outMatPath = fullfile(outputFolder, sprintf("%s_%s.mat", baseName, saveTag));

        ber             = res.ber;
        n               = res.n;
        BlockLength     = res.BlockLength;
        place           = res.place;
        snrRange        = res.snrRange;
        maxFrames       = res.maxFrames;
        K               = res.K;

        save(outMatPath, "ber", "n", "BlockLength", "place", "snrRange", "maxFrames", "K");
        fprintf("     [OK] Mentve: %s\n", outMatPath);

    catch ME
        warning("Hiba a(z) %s mátrix feldolgozásakor: %s", baseName, ME.message);
    end
end

fprintf("\n=== A(z) %s szimulációsorozat sikeresen befejeződött! ===\n", funcName);
end