function plotNK2(inputFolder, outputFolder)
% PLOTNK2 Azonos N és K paraméterű .mat fájlok közös grafikonra rajzolása
% Szűrés és színezés kategóriák szerint (bidir, gray, soft, sync).
%
% Bemenetek:
%   inputFolder  - A .mat fájlokat tartalmazó mappa (alapértelmezett: "osszehasonlito_eredmenyek")
%   outputFolder - A generált .png grafikonok mentési mappája

    arguments
        inputFolder  (1,1) string = "osszehasonlito_eredmenyek"
        outputFolder (1,1) string = inputFolder
    end

    if ~isfolder(inputFolder)
        error("plotResultsByNK:folderNotFound", "A bemeneti mappa nem létezik: %s", inputFolder);
    end
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    % 1. Mappában lévő összes .mat fájl beolvasása
    matFiles = dir(fullfile(inputFolder, "*.mat"));
    if isempty(matFiles)
        error("plotResultsByNK:noFiles", "Nem található .mat fájl a mappában: %s", inputFolder);
    end

    numAllFiles = numel(matFiles);
    fileNames   = string({matFiles.name});
    fileN       = nan(numAllFiles, 1);
    fileK       = nan(numAllFiles, 1);

    % 2. N és K paraméterek kinyerése kis- és nagybetű-függetlenül
    for i = 1:numAllFiles
        tokens = regexp(fileNames(i), "n(\d+)_k(\d+)", "tokens", "once", "ignorecase");
        if ~isempty(tokens)
            fileN(i) = str2double(tokens(1));
            fileK(i) = str2double(tokens(2));
        end
    end

    % Csak az érvényes N és K paraméterrel rendelkező fájlok megtartása
    validMask = ~isnan(fileN) & ~isnan(fileK);
    fileNames = fileNames(validMask);
    fileN     = fileN(validMask);
    fileK     = fileK(validMask);

    if isempty(fileNames)
        error("plotResultsByNK:noValidNK", "Egyetlen fájlnévben sem található 'N<szám>_K<szám>' minta!");
    end

    % 3. Egyedi (N, K) párok számbavétele és a visszaszámláló inicializálása
    uniqueNK = unique([fileN, fileK], "rows", "stable");
    osszesMatrixCsoport = size(uniqueNK, 1);
    hatralevoMatrixok   = osszesMatrixCsoport;

    fprintf("============================================================\n");
    fprintf(" Összesen %d db egyedi (N, K) mátrixcsoport található.\n", osszesMatrixCsoport);
    fprintf("============================================================\n");

    % 4. Végighaladás az (N, K) párokon és a hátralévő számláló léptetése
    for idx = 1:osszesMatrixCsoport
        aktualisN = uniqueNK(idx, 1);
        aktualisK = uniqueNK(idx, 2);

        matchingMask  = (fileN == aktualisN) & (fileK == aktualisK);
        matchingFiles = fileNames(matchingMask);

        fprintf("\n-> Feldolgozás: N = %d, K = %d (%d db .mat fájl)...\n", ...
            aktualisN, aktualisK, numel(matchingFiles));

        % Grafikon létrehozása az aktuális (N, K) párhoz
        createNKPlot(inputFolder, outputFolder, aktualisN, aktualisK, matchingFiles);

        % Számláló levonása
        hatralevoMatrixok = hatralevoMatrixok - 1;
        fprintf("   [OK] Kész! Hátralévő (N, K) mátrixcsoportok száma: %d\n", hatralevoMatrixok);
    end

    fprintf("\n=== Minden grafikon sikeresen elkészült! (Hátralévő: %d) ===\n", hatralevoMatrixok);
end

%% ========================================================================
%  GRAFIKONKÉSZÍTŐ ÉS KATEGÓRIA-SZÍNEZŐ SEGÉDFÜGGVÉNY
%% ========================================================================
function createNKPlot(inDir, outDir, N_val, K_val, groupFiles)
    plotTitle = sprintf("Bithiba-arány (BER) összehasonlítás: N = %d, K = %d", N_val, K_val);
    fig = figure(Name=plotTitle, NumberTitle="off", ...
        Color="black", Position=[100, 100, 1000, 720], Visible="off");
    ax = axes(fig); hold(ax, "on");

    % Rögzített színpaletta a sötét háttérhez (kontrasztos RGB értékek)
    COLOR_BIDIR = [0.00, 0.65, 1.00];  % Élénk kék
    COLOR_GRAY  = [1.00, 0.45, 0.10];  % Élénk narancs
    COLOR_SOFT  = [0.85, 0.30, 0.95];  % Élénk lila / magenta
    COLOR_SYNC  = [1.00, 0.90, 0.20];  % Élénk sárga
    COLOR_OTHER = [0.20, 0.85, 0.35];  % Zöld (ha egyéb elnevezésű lenne)

    legendEntries = string.empty;
    allX = double.empty;
    allY = double.empty;

    for i = 1:numel(groupFiles)
        fName = groupFiles(i);
        fullPath = fullfile(inDir, fName);

        [snr, ber] = loadSnrAndBer(fullPath);
        [vx, vy]   = filterValidPoints(snr, ber);

        if isempty(vx)
            continue;
        end

        fLower = lower(fName);

        % Kulcsszó szerinti stílus- és színmeghatározás
        if contains(fLower, "sync")
            % Sync: saját szín és szaggatott vonal
            c         = COLOR_SYNC;
            lineStyle = ":";
            lineWidth = 2.4;
            marker    = "s";
        elseif contains(fLower, "bidir")
            % Bidir: saját szín és folytonos vonal
            c         = COLOR_BIDIR;
            lineStyle = "-";
            lineWidth = 2.0;
            marker    = "o";
        elseif contains(fLower, "gray")
            % Gray: saját szín és folytonos vonal
            c         = COLOR_GRAY;
            lineStyle = "-";
            lineWidth = 2.0;
            marker    = "o";
        elseif contains(fLower, "soft")
            % Soft: saját szín és folytonos vonal
            c         = COLOR_SOFT;
            lineStyle = "-";
            lineWidth = 2.0;
            marker    = "o";
        else
            % Egyéb aszinkron változatok: folytonos vonal
            c         = COLOR_OTHER;
            lineStyle = "-";
            lineWidth = 2.0;
            marker    = "o";
        end

        semilogy(ax, vx, vy, ...
            LineStyle=lineStyle, LineWidth=lineWidth, Color=c, ...
            Marker=marker, MarkerSize=5, MarkerFaceColor=c);

        legendEntries(end+1) = erase(fName, ".mat");
        allX = [allX, vx];
        allY = [allY, vy];
    end

    if isempty(allX)
        close(fig);
        fprintf("   [Figyelem] Nincs érvényes pozitív BER adat N=%d, K=%d esetén.\n", N_val, K_val);
        return;
    end

    % Dinamikus tengelyskálázás (szoros illesztés a szélekhez)
    xMin = min(allX);
    xMax = max(allX);
    xMargin = (xMax - xMin) * 0.03;
    if xMargin == 0, xMargin = 0.5; end
    xlim(ax, [xMin - xMargin, xMax + xMargin]);

    yMin = min(allY);
    yMax = max(allY);
    ylim(ax, [yMin * 0.70, min(1.0, yMax * 1.25)]);

    % Stílusbeállítások
    set(ax, YScale="log");
    grid(ax, "on"); grid(ax, "minor"); box(ax, "on");
    ax.FontSize = 11; ax.LineWidth = 1;
    ax.GridAlpha = 0.25; ax.MinorGridAlpha = 0.08;
    ax.XColor = "w"; ax.YColor = "w";
    title(ax, plotTitle, FontSize=13, FontWeight="bold", Color="w");
    xlabel(ax, "SNR [dB]", FontSize=12, FontWeight="bold", Color="w");
    ylabel(ax, "Bithiba-arány (BER)", FontSize=12, FontWeight="bold", Color="w");
    legend(ax, legendEntries, Location="northeastoutside", Interpreter="none", ...
        FontSize=9, Box="off", TextColor="w");

    % Mentés 300 DPI felbontással
    outFileName = sprintf("Grafikon_N%d_K%d.png", N_val, K_val);
    savePath    = fullfile(outDir, outFileName);
    exportgraphics(fig, savePath, Resolution=300);
    close(fig);

    fprintf("   -> Mentve: %s\n", savePath);
end

%% ========================================================================
%  ADATBEOLVASÓ SEGÉDFÜGGVÉNYEK
%% ========================================================================
function [snr, ber] = loadSnrAndBer(filePath)
    d = load(filePath);
    f = string(fieldnames(d));

    snrField = f(contains(lower(f), "snr"));
    errField = f(contains(lower(f), "err") | strcmpi(f, "ber"));

    if isempty(snrField) || isempty(errField)
        error("plotResultsByNK:missingVars", ...
            "Nem található SNR vagy BER változó a fájlban: %s", filePath);
    end

    snr = double(d.(snrField(1))(:)');
    ber = double(d.(errField(1))(:)');
end

function [vx, vy] = filterValidPoints(x, y)
    mask = ~isnan(y) & ~isinf(y) & (y > 0);
    vx = x(mask);
    vy = y(mask);
end