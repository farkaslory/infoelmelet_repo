function plotNK(inputFolder, outputFolder)
% PLOTNK Azonos N és K paraméterű .mat fájlok közös grafikonra rajzolása
% Kis- és nagybetű-független N/K, valamint "sync" / "am" felismeréssel.
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

    % 2. N és K paraméterek kinyerése kis- és nagybetű-függetlenül (pl. N132_K40, n132_k40)
    for i = 1:numAllFiles
        tokens = regexp(fileNames(i), "n(\d+)_k(\d+)", "tokens", "once", "ignorecase");
        if ~isempty(tokens)
            fileN(i) = str2double(tokens(1));
            fileK(i) = str2double(tokens(2));
        end
    end

    % Csak az érvényes N és K paraméterrel rendelkező fájlokat tartjuk meg
    validMask = ~isnan(fileN) & ~isnan(fileK);
    fileNames = fileNames(validMask);
    fileN     = fileN(validMask);
    fileK     = fileK(validMask);

    if isempty(fileNames)
        error("plotResultsByNK:noValidNK", "Egyetlen fájlnévben sem található 'N<szám>_K<szám>' minta!");
    end

    % 3. Egyedi (N, K) párok meghatározása és a számláló inicializálása
    uniqueNK = unique([fileN, fileK], "rows", "stable");
    osszesMatrixCsoport = size(uniqueNK, 1);
    hatralevoMatrixok   = osszesMatrixCsoport;

    % Színpaletta, hogy az egyes (N, K) mátrixok eltérő színt kapjanak
    globalColors = lines(osszesMatrixCsoport);

    fprintf("============================================================\n");
    fprintf(" Összesen %d db egyedi (N, K) mátrix-paraméter található.\n", osszesMatrixCsoport);
    fprintf("============================================================\n");

    % 4. Végighaladás az egyedi (N, K) párokon és levonogatás a számlálóból
    for idx = 1:osszesMatrixCsoport
        aktualisN = uniqueNK(idx, 1);
        aktualisK = uniqueNK(idx, 2);

        % Szűrés: N és K paraméternek egyszerre kell egyeznie
        matchingMask  = (fileN == aktualisN) & (fileK == aktualisK);
        matchingFiles = fileNames(matchingMask);

        fprintf("\n-> Feldolgozás: N = %d, K = %d (%d db .mat fájl)...\n", ...
            aktualisN, aktualisK, numel(matchingFiles));

        % Grafikon kirajzolása és mentése az adott (N, K) csoportra
        createNKPlot(inputFolder, outputFolder, aktualisN, aktualisK, matchingFiles, globalColors(idx, :));

        % Számláló csökkentése
        hatralevoMatrixok = hatralevoMatrixok - 1;
        fprintf("   [OK] Kész! Hátralévő (N, K) mátrixcsoportok száma: %d\n", hatralevoMatrixok);
    end

    fprintf("\n=== Minden (N, K) grafikon sikeresen elkészült! (Hátralévő: %d) ===\n", hatralevoMatrixok);
end

%% ========================================================================
%  EGYEDI (N, K) CSOPORT GRAFIKONRAJZOLÓ SEGÉDFÜGGVÉNY
%% ========================================================================
function createNKPlot(inDir, outDir, N_val, K_val, groupFiles, baseColor)
    plotTitle = sprintf("Bithiba-arány (BER) összehasonlítás: N = %d, K = %d", N_val, K_val);
    fig = figure(Name=plotTitle, NumberTitle="off", ...
        Color="black", Position=[100, 100, 1000, 720], Visible="off");
    ax = axes(fig); hold(ax, "on");

    % Mátrix előtagok azonosítása: levágjuk a "_sync..." vagy "_am..." részt (kis/nagybetű-függetlenül).
    % Ha egy N_K csoporton belül csak 1 mátrix van (1 Sync + 1 AM), mindkettő a baseColor színt kapja.
    % Ha több eltérő nevű mátrix van azonos N és K mellett (vagy nincs bennük sync/am), külön színt kapnak.
    groupKeys = lower(regexprep(erase(groupFiles, ".mat"), "_(sync|am).*$", "", "ignorecase"));
    uniqueFamilies = unique(groupKeys, "stable");

    if numel(uniqueFamilies) == 1
        palette = baseColor;
    else
        palette = lines(numel(uniqueFamilies));
    end

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

        % Szín hozzárendelése
        colorIdx = find(uniqueFamilies == groupKeys(i), 1);
        c = palette(colorIdx, :);

        % Egyszerűsített vonalstílus-választás ("sync" vs. "am" vagy bármi más)
        if contains(fName, "sync", IgnoreCase=true)
            % Szinkron eredmény -> szaggatott vonal
            lineStyle = ":";
            lineWidth = 2.4;
            marker    = "s";
        elseif contains(fName, "am", IgnoreCase=true)
            % Aszinkron (AM) eredmény -> folytonos vonal
            lineStyle = "-";
            lineWidth = 2.0;
            marker    = "o";
        else
            % Ha egyik sincs a névben -> alapértelmezett folytonos vonal
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
        fprintf("   [Figyelem] Nincs érvényes (pozitív) BER adat N=%d, K=%d esetén.\n", N_val, K_val);
        return;
    end

    % Maximális kinagyítás (Tight Auto-Scaling), hogy a görbék kitöltsék a teret
    xMin = min(allX);
    xMax = max(allX);
    xMargin = (xMax - xMin) * 0.03;
    if xMargin == 0, xMargin = 0.5; end
    xlim(ax, [xMin - xMargin, xMax + xMargin]);

    yMin = min(allY);
    yMax = max(allY);
    ylim(ax, [yMin * 0.70, min(1.0, yMax * 1.25)]);

    % Sötét tudományos stílus beállítása
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

    % Mentés .png fájlba
    outFileName = sprintf("Grafikon_N%d_K%d.png", N_val, K_val);
    savePath    = fullfile(outDir, outFileName);
    exportgraphics(fig, savePath, Resolution=300);
    close(fig);

    fprintf("   -> Mentve: %s\n", savePath);
end

%% ========================================================================
%  ADATBETÖLTŐ ÉS SZŰRŐ SEGÉDFÜGGVÉNYEK
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