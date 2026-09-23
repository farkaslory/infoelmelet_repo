%% LTE Turbo Kódok Összehasonlító Főszkript
% 1. Ábra: Szinkron QPSK (Sync_LDPC.m) vs. Aszinkron AM2-4 (AM2_4.m)
% 2. Ábra: Szinkron 16-QAM (Sync_LDPC_16.m) vs. Aszinkron AM4-16 (AM4_16.m)

clear; clc; close all;

%% 1. Párhuzamos környezet indítása
if isempty(gcp('nocreate'))
    parpool("Processes", 4);
end

%% 2. Konfiguráció és futási paraméterek
inputFolder  = 'bemeneti_matrixok';
outputFolder = 'osszehasonlito_eredmenyek';
if ~isfolder(outputFolder), mkdir(outputFolder); end

% SNR tartományok a két modulációs mélységhez
snrRange_AM24  = 1:0.5:6;   % QPSK tartomány (2 bit/szimbólum)
snrRange_AM416 = 15:1:30;    % 16-QAM tartomány (4 bit/szimbólum)

maxFrames = 1000;            % Keretszám SNR pontonként
K = 20;             % Kódszavak száma az aszinkron láncban
maxFramesSync = K*maxFrames;


txtFiles = dir(fullfile(inputFolder, '*.txt'));
numFiles = length(txtFiles);

if numFiles == 0
    error('Nem található .txt mátrixfájl a megadott mappában: %s', inputFolder);
end

colors = lines(numFiles);

%% 3. Ábrák inicializálása
% 1. Ábra: QPSK összehasonlítás
fig1 = figure('Name', 'Szinkron QPSK vs AM2-4', 'NumberTitle', 'off', ...
    'Color', 'black', 'Position', [100, 100, 950, 700]);
ax1 = axes(fig1); hold(ax1, 'on');

% 2. Ábra: 16-QAM összehasonlítás
fig2 = figure('Name', 'Szinkron 16-QAM vs AM4-16', 'NumberTitle', 'off', ...
    'Color', 'black', 'Position', [150, 150, 950, 700]);
ax2 = axes(fig2); hold(ax2, 'on');

legend1 = {};
legend2 = {};

%% 4. Fő futtató ciklus mátrixonként
for i = 1:numFiles
    currentFileName = txtFiles(i).name;
    [~, baseName, ~] = fileparts(currentFileName);
    matrixPath = fullfile(inputFolder, currentFileName);
    currentColor = colors(i, :);

    fprintf('\n[%d/%d] Mátrix feldolgozása: %s\n', i, numFiles, baseName);
    H = readTurboCode(matrixPath);

    %% --- 1. RÉSZ: AM2-4 vs. Szinkron QPSK (Sync_LDPC.m) ---
    % fprintf('  -> [1/2] AM2-4 és Sync_LDPC futtatása (QPSK, 2 bit/szimbólum)...\n');
    % syncErr_QPSK = Sync_LDPC(H, maxFrames, snrRange_AM24);
    % [am24Err, ~, ~, ~] = AM2_4(H, maxFrames, K, snrRange_AM24, 0);
    % 
    % semilogy(ax1, snrRange_AM24, cleanZeros(am24Err), ...
    %     'LineStyle', '-', 'LineWidth', 1.8, 'Color', currentColor, ...
    %     'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', currentColor);
    % legend1{end+1} = [baseName, ' (Aszinkron AM2-4)'];
    % 
    % semilogy(ax1, snrRange_AM24, cleanZeros(syncErr_QPSK), ...
    %     'LineStyle', ':', 'LineWidth', 2.2, 'Color', currentColor, ...
    %     'Marker', 's', 'MarkerSize', 4, 'MarkerFaceColor', currentColor);
    % legend1{end+1} = [baseName, ' (Szinkron QPSK)'];

    %% --- 2. RÉSZ: AM4-16 vs. Szinkron 16-QAM (Sync_LDPC_16.m) ---
    fprintf('  -> [2/2] AM4-16 és Sync_LDPC_16 futtatása (16-QAM, 4 bit/szimbólum)...\n');
    syncErr_16QAM = Sync_LDPC_16(H, maxFramesSync, snrRange_AM416);
    try
        [am416Err, ~, ~, ~] = AM4_16(H, maxFrames, K, snrRange_AM416, 0);

        semilogy(ax2, snrRange_AM416, cleanZeros(am416Err), ...
            'LineStyle', '-', 'LineWidth', 1.8, 'Color', currentColor, ...
            'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', currentColor);
        legend2{end+1} = [baseName, ' (Aszinkron AM4-16)'];

        semilogy(ax2, snrRange_AM416, cleanZeros(syncErr_16QAM), ...
            'LineStyle', ':', 'LineWidth', 2.2, 'Color', currentColor, ...
            'Marker', 's', 'MarkerSize', 4, 'MarkerFaceColor', currentColor);
        legend2{end+1} = [baseName, ' (Szinkron 16-QAM)'];
    catch ME
        warning('AM4_16 futási hiba a(z) %s mátrixnál: %s', baseName, ME.message);
    end
end

%% 5. Grafikonok mentése
setupDarkPlot(ax1, 'Bithiba-arány: Szinkron QPSK vs. Aszinkron AM2-4', legend1, [1 6]);
exportgraphics(fig1, fullfile(outputFolder, 'Osszehasonlitas_AM2_4.png'), 'Resolution', 300);
close(fig1);

setupDarkPlot(ax2, 'Bithiba-arány: Szinkron 16-QAM vs. Aszinkron AM4-16', legend2, [15 30]);
exportgraphics(fig2, fullfile(outputFolder, 'Osszehasonlitas_AM4_16.png'), 'Resolution', 300);
close(fig2);

fprintf('\n=== Kész! Mindkét összehasonlító grafikon elmentve az %s mappába. ===\n', outputFolder);

%% Segédfüggvények
function cleanData = cleanZeros(data)
    cleanData = data;
    cleanData(cleanData == 0) = NaN;
end

function setupDarkPlot(ax, plotTitle, legendText, xLim)
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
    xlim(ax, xLim);
    ylim(ax, [1e-5 1]);
end
