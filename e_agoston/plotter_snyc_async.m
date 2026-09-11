close all; clc; clear;
% Ez az algoritmus két külön mappában lévő .mat fájlok tartalmát olvassa be
% és hasonlítja össze egy közös ábrán (pl. szinkron vs. aszinkron LDPC futtatások).
%
% Az első mappa eredményeit folytonos vonallal ('-'), a második mappa
% eredményeit pedig pontozott vonallal (':') rajzolja ki.
%
% Várt változók a .mat fájlokban:
% 'BlockLengthHalf', 'n', 'K', 'LdpcErr_2', 'snr_range'
%
% K - kódszavak száma
% n - az adott kódnak az infóbit hossza (N-M)
% LdpcErr_2 - a tényleges eredmény, egy vektor, ahol minden elem egy adott
%   SNR-értékhez tartozó átlagos bithiba-arány (BER)
% BlockLengthHalf - A H mátrix N hosszú kódjának a fele
% snr_range - a futtatás SNR pontjai (pl. 2:0.5:8)

%% Mappák megadása
folderSolid  = 'Random LDPCk async mat';    % 1. Mappa: folytonos vonallal ábrázolva
folderDotted = 'Random LDPCk sync mat';   % 2. Mappa: pontozott vonallal ábrázolva (általában ez az szinkron kód)

%% Mappák beolvasása és ellenőrzése
listSolid  = dir(fullfile(folderSolid, '*.mat'));
listDotted = dir(fullfile(folderDotted, '*.mat'));

nSolid  = length(listSolid);
nDotted = length(listDotted);

if nSolid == 0 && nDotted == 0
    error('Egyik megadott mappában sem találhatók .mat fájlok!');
end

%% Ábra létrehozása és a háttér beállítása
figure('Name', 'BER összehasonlítás', 'NumberTitle', 'off', ...
    'Color', 'black', 'Position', [100, 100, 950, 700]);
hold on;

% Színek kiosztása: az azonos indexű/nevű kódok ugyanazt a színt kapják
maxCurves = max(nSolid, nDotted);
colors = lines(maxCurves);

markerEvery = 1;   % Hány pontonként jelenjen meg a marker
legendEntries = {};

%% 1. Mappa kirajzolása (Folytonos vonal)
for i = 1:nSolid
    currentFileName = listSolid(i).name;
    data = load(fullfile(folderSolid, currentFileName));
    nPts = numel(data.snr_range);
    markIdx = 1:markerEvery:nPts;

    semilogy(data.snr_range, data.LdpcErr_2, ...
        'LineStyle', '-', ...
        'LineWidth', 1.8, ...
        'Color', colors(i, :), ...
        'Marker', 'o', ...
        'MarkerSize', 4, ...
        'MarkerFaceColor', colors(i, :), ...
        'MarkerIndices', markIdx);

    [~, baseName, ~] = fileparts(currentFileName);
    legendEntries{end+1} = [baseName, ' (Aszinkron)'];
end

%% 2. Mappa kirajzolása (Pontozott vonal)
for i = 1:nDotted
    currentFileName = listDotted(i).name;
    data = load(fullfile(folderDotted, currentFileName));
    nPts = numel(data.snr_range);
    markIdx = 1:markerEvery:nPts;

    semilogy(data.snr_range, data.LdpcErr_2, ...
        'LineStyle', ':', ...
        'LineWidth', 2.2, ...
        'Color', colors(i, :), ...
        'Marker', 's', ...
        'MarkerSize', 4, ...
        'MarkerFaceColor', colors(i, :), ...
        'MarkerIndices', markIdx);

    [~, baseName, ~] = fileparts(currentFileName);
    legendEntries{end+1} = [baseName, ' (Szinkron)']; 
end

hold off;

%% Tengelyek és rács formázása
set(gca, 'YScale', 'log');   % BER-nél logaritmikus skála
grid on;
grid minor;
box on;
ax = gca;
ax.FontSize = 11;
ax.LineWidth = 1;
ax.GridAlpha = 0.25;
ax.MinorGridAlpha = 0.08;

%% Feliratok, jelmagyarázat és tengelyhatárok
xlabel('SNR [dB]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Bithiba-arány (BER)', 'FontSize', 12, 'FontWeight', 'bold');
title('LDPC kódok bithiba-arányának összehasonlítása', 'FontSize', 13, 'FontWeight', 'bold');
legend(legendEntries, 'Location', 'northeastoutside', 'Interpreter', 'none', ...
    'FontSize', 9, 'Box', 'off');
ylim([1e-7, 1]);   % Rögzített y-tartomány