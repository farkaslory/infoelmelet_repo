%% LTE Turbo Kódok Összehasonlító Főszkript (MATLAB R2019 Kompatibilis)
% 1. Ábra: Szinkron QPSK (Sync_LDPC.m) vs. Aszinkron AM2-4 (AM2_4.m)
% 2. Ábra: Szinkron 16-QAM (Sync_LDPC_16.m) vs. Aszinkron AM4-16 (AM4_16.m)
% Kimenet: 2 db PNG ábra és mátrixonként 4 db .mat adatfájl

clear; clc; close all;

%% 1. Párhuzamos környezet indítása
if isempty(gcp('nocreate'))
    c = parcluster('local');
    numWorkers = min(16, c.NumWorkers);
    if numWorkers > 0
        parpool(c, numWorkers);
    else
        parpool;
    end
end

%% 2. Konfiguráció és futási paraméterek
inputFolder  = 'bemeneti_matrixok';
outputFolder = 'osszehasonlito_eredmenyek';
if ~exist(outputFolder, 'dir'), mkdir(outputFolder); end

% SNR tartományok a két eljáráshoz
snrRange_AM24  = 1:0.5:6;    % QPSK tartomány (2 bit/szimbólum)
snrRange_AM416 = 10:1:20;    % 16-QAM tartomány (4 bit/szimbólum)

maxFrames = 1000;            % Keretszám SNR pontonként
K         = 20;              % Kódszavak száma az aszinkron láncban
maxFramesSync = K * maxFrames;

txtFiles = dir(fullfile(inputFolder, '*.txt'));
numFiles = length(txtFiles);

if numFiles == 0
    error('Nem található .txt mátrixfájl a megadott mappában: %s', inputFolder);
end

colors = lines(numFiles);

%% 3. Ábrák inicializálása
fig1 = figure('Name', 'Szinkron QPSK vs AM2-4', 'NumberTitle', 'off', ...
    'Color', 'black', 'Position', [100, 100, 950, 700]);
ax1 = axes(fig1); hold(ax1, 'on');

fig2 = figure('Name', 'Szinkron 16-QAM vs AM4-16', 'NumberTitle', 'off', ...
    'Color', 'black', 'Position', [150, 150, 950, 700]);
ax2 = axes(fig2); hold(ax2, 'on');

legend1 = {};
legend2 = {};

%% 4. Fő futtató és mentő ciklus mátrixonként
for i = 1:numFiles
    currentFileName = txtFiles(i).name;
    [~, baseName, ~] = fileparts(currentFileName);
    matrixPath = fullfile(inputFolder, currentFileName);
    currentColor = colors(i, :);

    fprintf('\n==================================================\n');
    fprintf('[%d/%d] Mátrix feldolgozása: %s\n', i, numFiles, baseName);
    fprintf('==================================================\n');
    
    % Beolvasás és R2019-es enkódolhatóvá alakítás
    H_raw = readTurboCode(matrixPath);
    [H, ~] = make_h_encodable_internal(H_raw);

    %% --- 1. RÉSZ: AM2-4 és Szinkron QPSK (2 bit/szimbólum) ---
    fprintf('  -> [1/4] Sync_LDPC futtatása (QPSK)...\n');
    [syncErr_QPSK, n_sync_qpsk, BlockLengthHalf_sync_qpsk] = Sync_LDPC(H, maxFramesSync, snrRange_AM24);
    
    matPath_sync_qpsk = fullfile(outputFolder, sprintf('%s_Sync_QPSK.mat', baseName));
    save(matPath_sync_qpsk, 'syncErr_QPSK', 'n_sync_qpsk', 'BlockLengthHalf_sync_qpsk', ...
         'snrRange_AM24', 'maxFrames');
    fprintf('     Mentve: %s\n', matPath_sync_qpsk);

    fprintf('  -> [2/4] AM2_4 futtatása (BPSK/QPSK aszinkron)...\n');
    [am24Err, n_am24, BlockLengthHalf_am24, place_am24] = AM2_4(H, maxFrames, K, snrRange_AM24, 1);
    
    matPath_am24 = fullfile(outputFolder, sprintf('%s_AM2_4.mat', baseName));
    save(matPath_am24, 'am24Err', 'n_am24', 'BlockLengthHalf_am24', 'place_am24', ...
         'K', 'snrRange_AM24', 'maxFrames');
    fprintf('     Mentve: %s\n', matPath_am24);

    semilogy(ax1, snrRange_AM24, cleanZeros(am24Err), ...
        'LineStyle', '-', 'LineWidth', 1.8, 'Color', currentColor, ...
        'Marker', 'o', 'MarkerSize', 4, 'MarkerFaceColor', currentColor);
    legend1{end+1} = [baseName, ' (Aszinkron AM2-4)'];

    semilogy(ax1, snrRange_AM24, cleanZeros(syncErr_QPSK), ...
        'LineStyle', ':', 'LineWidth', 2.2, 'Color', currentColor, ...
        'Marker', 's', 'MarkerSize', 4, 'MarkerFaceColor', currentColor);
    legend1{end+1} = [baseName, ' (Szinkron QPSK)'];

    %% --- 2. RÉSZ: AM4-16 és Szinkron 16-QAM (4 bit/szimbólum) ---
    fprintf('  -> [3/4] Sync_LDPC_16 futtatása (16-QAM)...\n');
    [syncErr_16QAM, n_sync_16qam, BlockLengthHalf_sync_16qam] = Sync_LDPC_16(H, maxFramesSync, snrRange_AM416);
    
    matPath_sync_16qam = fullfile(outputFolder, sprintf('%s_Sync_16QAM.mat', baseName));
    save(matPath_sync_16qam, 'syncErr_16QAM', 'n_sync_16qam', 'BlockLengthHalf_sync_16qam', ...
         'snrRange_AM416', 'maxFrames');
    fprintf('     Mentve: %s\n', matPath_sync_16qam);

    fprintf('  -> [4/4] AM4_16 futtatása (4-QAM/16-QAM aszinkron)...\n');
    try
        [am416Err, n_am416, BlockLengthHalf_am416, place_am416] = AM4_16(H, maxFrames, K, snrRange_AM416, 1);
        
        matPath_am416 = fullfile(outputFolder, sprintf('%s_AM4_16.mat', baseName));
        save(matPath_am416, 'am416Err', 'n_am416', 'BlockLengthHalf_am416', 'place_am416', ...
             'K', 'snrRange_AM416', 'maxFrames');
        fprintf('     Mentve: %s\n', matPath_am416);

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
set(fig1, 'InvertHardcopy', 'off');
print(fig1, fullfile(outputFolder, 'Osszehasonlitas_AM2_4.png'), '-dpng', '-r300');
close(fig1);

setupDarkPlot(ax2, 'Bithiba-arány: Szinkron 16-QAM vs. Aszinkron AM4-16', legend2, [10 20]);
set(fig2, 'InvertHardcopy', 'off');
print(fig2, fullfile(outputFolder, 'Osszehasonlitas_AM4_16.png'), '-dpng', '-r300');
close(fig2);

fprintf('\n=== Kész! Mind a 4 .mat fájl és a PNG diagramok elmentve az %s mappába. ===\n', outputFolder);


%% ########################################################################
%  HELYI SEGÉDFÜGGVÉNYEK
%% ########################################################################

function [Hp, M_eff] = make_h_encodable_internal(H)
% Robusztus GF(2) Gauss-Jordan elimináció Turbo kódok paritásmátrixához.
% Kiszűri a redundáns sorokat, és az utolsó M_eff oszlopba invertálható
% pivot-oszlopokat permutál, kielégítve a comm.LDPCEncoder feltételeit.
    Hd = full(logical(H));
    [M, N] = size(Hd);

    A = Hd;
    pivotCols = [];
    currentRow = 1;

    for c = 1:N
        r = find(A(currentRow:end, c), 1);
        if ~isempty(r)
            actualRow = currentRow + r - 1;
            if actualRow ~= currentRow
                A([currentRow, actualRow], :) = A([actualRow, currentRow], :);
                Hd([currentRow, actualRow], :) = Hd([actualRow, currentRow], :);
            end

            otherRows = find(A(:, c));
            otherRows(otherRows == currentRow) = [];
            if ~isempty(otherRows)
                A(otherRows, :) = xor(A(otherRows, :), A(currentRow, :));
            end

            pivotCols(end+1) = c; %#ok<AGROW>
            currentRow = currentRow + 1;
            if currentRow > M
                break;
            end
        end
    end

    M_eff = numel(pivotCols);
    Hd = Hd(1:M_eff, :);

    otherCols = setdiff(1:N, pivotCols, 'stable');
    perm = [otherCols, pivotCols];
    Hp = sparse(Hd(:, perm));
end

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