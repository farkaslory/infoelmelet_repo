function simuLDPC(funcName, outputFolder, inputFolder, opts)
% SIMULDPC Kötegelt szimulációfuttató az összes bemeneti .alist mátrixra
%
% Az AAC_mod.m script függvényes változata: egy mappa összes .alist formátumú
% LDPC-kódjára (.alist vagy .txt kiterjesztésű fájlok) lefuttatja a kiválasztott
% modulációs szimulációt, és minden mátrixhoz egy .mat fájlt ment.
%
% Bemenetek:
%   funcName     - Futtatandó moduláció: "AM2_4", "AM4_16", "Sync_LDPC", "Sync_LDPC_16"
%   inputFolder  - Bemeneti mátrixokat (.alist vagy .txt) tartalmazó mappa
%   outputFolder - Kimeneti eredmények (.mat) célmappája
%   opts         - Opcionális szimulációs paraméterek (Name=Value)
%                  maxFrames (alap: 1000), snrRange (alap: 5:0.5:15), K (alap: 20)
%
% Kimenet: nincs, az eredmények fájlba kerülnek. Minden .mat fájl tartalma:
%   funcName    - a szimulációt futtató függvény neve
%   ber         - BER-értékek vektora (snrRange-dzsel azonos hosszú)
%   n           - az adott kód infóbit-hossza (N-M)
%   BlockLength - a kódszó hossza (N)
%   place       - hibaeloszlás a láncban ([] ha nem lett számolva)
%   snrRange    - a lefuttatott SNR-értékek [dB]
%   maxFrames   - próbák száma SNR-értékenként
%   K           - kódszavak száma a láncban
%
% Szükséges: runMod.m (az univerzális modulációs motor, ugyanaz, amit a runSim
% is használ). A read_alist_2 és a make_h_encodable a fájl végén található
% (lokális függvények), ezekhez külön fájl nem kell.

arguments
    funcName     (1,1) string
    outputFolder (1,1) string = "LDPCk mat"
    inputFolder  (1,1) string = "LDPCk alist"
    opts.maxFrames     (1,1) double = 1000
    opts.snrRange      (1,:) double = 5:0.5:15
    opts.K             (1,1) double = 20
end

% 1. Párhuzamos környezet ellenőrzése
if isempty(gcp('nocreate'))
    parpool;
end

% 2. Mappák ellenőrzése
if ~isfolder(inputFolder)
    error("simuLDPC:folderNotFound", ...
        "A bemeneti mappa nem található: %s", inputFolder);
end
if ~isfolder(outputFolder), mkdir(outputFolder); end

% .txt ÉS .alist kiterjesztésű fájlokat is keresünk, mert az alist-fájlok
% kiterjesztése fájlonként eltérő.
alistFiles = [dir(fullfile(inputFolder, "*.txt")); dir(fullfile(inputFolder, "*.alist"))];
numFiles = numel(alistFiles);
if numFiles == 0
    error("simuLDPC:noFiles", ...
        "Nem található .txt vagy .alist mátrixfájl itt: %s", inputFolder);
end

% Automatikus fájlnév-címke a korábbi plotter kompatibilitáshoz
switch funcName
    case "Sync_Ldpc",    saveTag = "Sync_QPSK";
    case "Sync_LDPC_16", saveTag = "Sync_16QAM";
    otherwise,           saveTag = funcName;
end

fprintf("\n=======================================================\n");
fprintf(" KÖTEGELT SZIMULÁCIÓ INDÍTÁSA: %s (%d db mátrix)\n", funcName, numFiles);
fprintf(" Bemenet: %s  -->  Kimenet: %s\n", inputFolder, outputFolder);
fprintf("=======================================================\n");

% 3. Végighaladás a mátrixokon
% A try/catch miatt egy hibás/nem támogatott formátumú fájl nem állítja le a
% teljes futást, csak kimarad, és a program a következő fájllal folytatja.
for i = 1:numFiles
    currentFile = alistFiles(i).name;
    [~, baseName, ~] = fileparts(currentFile);
    baseName    = erase(baseName, ".alist");   % ha ".alist.txt" formátumú volt a név
    matrixPath  = fullfile(inputFolder, currentFile);

    fprintf("\n[%d/%d] Feldolgozás: %s\n", i, numFiles, baseName);

    try
        % .alist beolvasása
        [H, N, ~] = read_alist_2(matrixPath);   % az eredeti M-et eldobjuk, mert a make_h_encodable úgyis újraszámolja

        if mod(N, 2) ~= 0
            % Az itt használt szuperpozíciós séma bitpáronként dolgozik
            % (BlockLengthHalf = N/2), ezért csak páros N-ű kódokkal működik.
            fprintf("     [KIHAGYVA] N=%d páratlan, ez a moduláció csak páros N-nel működik\n", N);
            continue;
        end

        % H előkészítése, hogy az ldpcEncoderConfig el tudja fogadni
        H = make_h_encodable(H);

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

        % a funcName a függvény bemenete, ezért közvetlenül menthető
        save(outMatPath, "funcName", "ber", "n", "BlockLength", "place", "snrRange", "maxFrames", "K");
        fprintf("     [OK] Mentve: %s\n", outMatPath);

    catch ME
        warning("Hiba a(z) %s mátrix feldolgozásakor: %s", baseName, ME.message);
    end
end

fprintf("\n=== A(z) %s szimulációsorozat sikeresen befejeződött! ===\n", funcName);
end