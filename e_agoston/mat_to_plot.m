close all; clc; clear;
% Ez az algoritmus kirajzolja egy adott mat fájlokkal teli foldernek a
% tartalmát és egymásnak veti őket.
%
%    A programnak meg kell adni a folder nevét, és abból a folderből kiveszi
% az összes '.mat' végződésű fájlt, amiben el vannak mentve a következő változók:
% 'BlockLengthHalf', 'n', 'K', 'LdpcErr_2', 'snr_range'
%
% K - kódszavak száma
% n - az adott kódnak az infóbit hossza (N-M)
% LdpcErr_2 -  a tényleges eredmény, egy vektor, ahol minden elem egy adott
%   SNR-értékhez tartozó átlagos bithiba-arány (BER)
% BlockLengthHalf - A H mátrix N hosszú kódjának a fele
% snr_range - ez azt adja meg, hogy milyen pontossággal futtattuk le a
%   kódot, ez pl. egy olyan dolog, hogy 2:0,5:8 (2-től 8-ig 0,5-ösével a számok)
%
%   Kis extra megjegyzés, érdemes nem több mint 7 file-t beolvastatni vele,
% mert 7 külömböző file után már újra használja ugyan azokat a színeket,
% és ilyenkor nem lehet megkülömbüttetni egymástól a kódokat.
%% Mappa beolvasása
folderName = 'Random LDPCk mat';
list = dir(fullfile(folderName, '*.mat'));
nFiles = length(list);   % 'size'-t szándékosan nem használjuk változónévként,
% mert az felülírná a beépített size() függvényt
if nFiles == 0
    error('Nem talalhatoak .mat fajlok a "%s" mappaban! Ellenorizd a mappa nevet.', folderName);
end
%% Ábra létrehozása és a háttér beállítása
figure('Name', 'BER osszehasonlitas', 'NumberTitle', 'off', ...
    'Color', 'black', 'Position', [100, 100, 900, 650]);
hold on;
% Egyedi szín minden görbének, még akkor is, ha 7-nél több fájl van
colors = lines(nFiles);
% Marker csak minden n-edik ponton, hogy ne törje meg a görbe simaságát
markerEvery = 1;   % ha durvább SNR-lépésközöd van (pl. 2:0.5:8), hagyd 1-en
% finomabb lépésköznél (pl. 1:0.1:10) érdemes 5-10-re állítani
legendText = cell(nFiles, 1);
%% Görbék kirajzolása fájlonként
for i = 1:nFiles
    currentFileName = list(i).name;
    filePath = fullfile(folderName, currentFileName);
    data = load(filePath);
    nPts = numel(data.snr_range);
    markIdx = 1:markerEvery:nPts;   % hány pontonként jelenjen meg a marker
    semilogy(data.snr_range, data.LdpcErr_2, ...
        'LineWidth', 1.7, ...
        'Color', colors(i, :), ...
        'Marker', 'o', ...
        'MarkerSize', 4, ...
        'MarkerFaceColor', colors(i, :), ...
        'MarkerIndices', markIdx);
    [~, baseName, ~] = fileparts(currentFileName);
    legendText{i} = baseName;
end
hold off;
%% Tengelyek és rács formázása
set(gca, 'YScale', 'log');   % BER-nél a logaritmikus y-tengely a szokásos
grid on;
grid minor;
box on;
ax = gca;
ax.FontSize = 11;
ax.LineWidth = 1;
ax.GridAlpha = 0.25;
ax.MinorGridAlpha = 0.08;
%% Feliratok, legenda és y-tartomány
xlabel('SNR [dB]', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Bithiba arany (BER)', 'FontSize', 12, 'FontWeight', 'bold');
title('LDPC kodok bithiba aranyanak osszehasonlitasa', 'FontSize', 13, 'FontWeight', 'bold');
legend(legendText, 'Location', 'northeastoutside', 'Interpreter', 'none', ...
    'FontSize', 10, 'Box', 'off');
ylim([1e-7, 1]);   % rögzített y-tartomány, hogy a különböző futtatások ábrái összehasonlíthatóak legyenek
