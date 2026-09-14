%% LTE Turbo Kódok Vizsgálata: Szinkron LDPC vs. Eredeti AM2-4 és AM4-16
clear; clc; close all;

%% 1. Párhuzamos környezet indítása
if isempty(gcp('nocreate'))
    parpool(4);
end

%% 2. Beállítások
inputFolder  = 'bemeneti_matrixok';
outputFolder = 'osszehasonlito_eredmenyek';
if ~isfolder(outputFolder), mkdir(outputFolder); end

% A barátod kódjaiban használt paraméterekhez igazítva:
snrRange  = 2:0.5:8;  % SNR tartomány [dB]
maxFrames = 1000;     % Keretszám SNR pontonként (mélyebb statisztika)
K         = 20;       % Kódszavak száma az aszinkron láncban

txtFiles = dir(fullfile(inputFolder, '*.txt'));
numFiles = length(txtFiles);

if numFiles == 0
    error('Nem található .txt mátrixfájl a megadott mappában: %s', inputFolder);
end

fprintf('=== Szimuláció indítása (%d LTE Turbo mátrix) ===\n', numFiles);

%% 3. Ábrák előkészítése (A plotter_snyc_async sötét stílusában)
colors = lines(numFiles);

% 1. Ábra: Szinkron vs AM2-4
fig1 = figure('Name', 'Szinkron vs AM2-4', 'NumberTitle', 'off', ...
    'Color', 'black', 'Position', [100, 100, 950, 700]);
ax1 = axes(fig1); hold(ax1, 'on');

% 2. Ábra: Szinkron vs AM4-16
fig2 = figure('Name', 'Szinkron vs AM4-16', 'NumberTitle', 'off', ...
    'Color', 'black', 'Position', [150, 150, 950, 700]);
ax2 = axes(fig2); hold(ax2, 'on');

legendEntries1 = {};
legendEntries2 = {};

%% 4. Fő futtató ciklus mátrixonként
for i = 1:numFiles
    currentFileName = txtFiles(i).name;
    [~, baseName, ~] = fileparts(currentFileName);
    matrixPath = fullfile(inputFolder, currentFileName);
    currentColor = colors(i, :);

    fprintf('\n[%d/%d] Mátrix betöltése: %s\n', i, numFiles, baseName);
    H = readTurboCode(matrixPath);

    % --- 1. Lépés: Szinkron referencia futtatása ---
    fprintf('  -> Szinkron referencia futtatása (Sync_LDPC)...\n');
    syncErr = Sync_LDPC(H, maxFrames, snrRange);

    % --- 2. Lépés: Eredeti AM2-4 futtatása ---
    fprintf('  -> Aszinkron AM2-4 futtatása...\n');
    [am24Err, ~, ~, ~] = AM2_4(H, maxFrames, K, snrRange, 0);

    % Rajzolás az 1. ábrára (Aszinkron: folytonos körrel, Szinkron: pontozott négyzettel)
    semilogy(ax1, snrRange, cleanZeros(am24Err), ...
        'LineStyle', '-', 'LineWidth', 1.8, 'Color', currentColor, ...
        'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', currentColor);
    legendEntries1{end+1} = [baseName, ' (Aszinkron AM2-4)'];

    semilogy(ax1, snrRange, cleanZeros(syncErr), ...
        'LineStyle', ':', 'LineWidth', 2.2, 'Color', currentColor, ...
        'Marker', 's', 'MarkerSize', 4, 'MarkerFaceColor', currentColor);
    legendEntries1{end+1} = [baseName, ' (Szinkron)'];

    % --- 3. Lépés: Eredeti AM4-16 futtatása ---
    fprintf('  -> Aszinkron AM4-16 futtatása...\n');
    try
        [am416Err, ~, ~, ~] = AM4_16(H, maxFrames, K, snrRange, 0);

        % Rajzolás a 2. ábrára
        semilogy(ax2, snrRange, cleanZeros(am416Err), ...
            'LineStyle', '-', 'LineWidth', 1.8, 'Color', currentColor, ...
            'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', currentColor);
        legendEntries2{end+1} = [baseName, ' (Aszinkron AM4-16)'];

        semilogy(ax2, snrRange, cleanZeros(syncErr), ...
            'LineStyle', ':', 'LineWidth', 2.2, 'Color', currentColor, ...
            'Marker', 's', 'MarkerSize', 4, 'MarkerFaceColor', currentColor);
        legendEntries2{end+1} = [baseName, ' (Szinkron)'];
    catch ME_AM416
        warning('AM4_16 nem futtatható a(z) %s kódra: %s', baseName, ME_AM416.message);
    end
end

%% 5. Ábrák formázása és mentése
setupDarkPlot(ax1, 'LDPC kódok bithiba-arányának összehasonlítása (AM2-4)', legendEntries1);
pngPath1 = fullfile(outputFolder, 'Osszehasonlitas_AM2_4.png');
exportgraphics(fig1, pngPath1, 'Resolution', 300);
close(fig1);
fprintf('\n[KÉSZ] 1. Ábra mentve: %s\n', pngPath1);

setupDarkPlot(ax2, 'LDPC kódok bithiba-arányának összehasonlítása (AM4-16)', legendEntries2);
pngPath2 = fullfile(outputFolder, 'Osszehasonlitas_AM4_16.png');
exportgraphics(fig2, pngPath2, 'Resolution', 300);
close(fig2);
fprintf('[KÉSZ] 2. Ábra mentve: %s\n', pngPath2);

%% --- Helyi segédfüggvények ---
function cleanData = cleanZeros(data)
    cleanData = data;
    cleanData(cleanData == 0) = NaN;
end

function setupDarkPlot(ax, plotTitle, legendText)
    set(ax, 'YScale', 'log');
    grid(ax, 'on'); grid(ax, 'minor'); box(ax, 'on');
    ax.FontSize = 11; ax.LineWidth = 1;
    ax.GridAlpha = 0.25; ax.MinorGridAlpha = 0.08;
    ax.XColor = 'w'; ax.YColor = 'w';
    title(ax, plotTitle, 'FontSize', 13, 'FontWeight', 'bold', 'Color', 'w');
    xlabel(ax, 'SNR [dB]', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'w');
    ylabel(ax, 'Bithiba-arány (BER)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'w');
    legend(ax, legendText, 'Location', 'northeastoutside', 'Interpreter', 'none', ...
        'FontSize', 9, 'Box', 'off', 'TextColor', 'w');
    xlim(ax, [2 8]);
    ylim(ax, [1e-7 1]);
end