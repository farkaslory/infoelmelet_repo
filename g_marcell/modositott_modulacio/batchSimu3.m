function batchSimu3(inputFolder, outputFolder,...
  snrRange, maxFrames, K, oneBitPart)
% BATCHSIMU - Egy mappa összes .txt AList fájlját feldolgozza

if nargin < 1, inputFolder = 'Matrixok'; end
if nargin < 2, outputFolder = 'Eredmenyek'; end
if nargin < 3, snrRange = 1:0.5:5; end
if nargin < 4, maxFrames = 100; end
if nargin < 5, K = 20; end
if nargin < 6, oneBitPart = 0.5; end

if ~isfolder(inputFolder)
  error('A bemeneti mappa nem létezik: %s', inputFolder);
end
if ~isfolder(outputFolder)
  mkdir(outputFolder);
end

txtFiles = dir(fullfile(inputFolder, '*.txt'));
numFiles = length(txtFiles);
if numFiles == 0
  fprintf('Nem találtam .txt fájlt a %s mappában.\n', inputFolder);
  return;
end

fprintf('--- Batch feldolgozás indítása: %d fájl ---\n', numFiles);

fig_all = figure('Name', 'Összesített Görbék', 'Visible', 'off');
ax_all = axes(fig_all);
hold(ax_all, 'on'); 
legend_labels = {}; 

for i = 1:numFiles
  baseFileName = txtFiles(i).name;
  [~, nameWithoutExt, ~] = fileparts(baseFileName);
  fullInputPath = fullfile(inputFolder, baseFileName);
  matOutputPath = fullfile(outputFolder, [nameWithoutExt, '_result.mat']);
  pngOutputPath = fullfile(outputFolder, [nameWithoutExt, '_plot.png']);
  
  fprintf('[%d/%d] Feldolgozás: %s ... ', i, numFiles, baseFileName);
  
  try
    % 1. Mátrix beolvasása
    H_sparse = readTurboCode(fullInputPath);
    
    % 2. Konverzió sparse logical típusra
    H_fixed = sparse(logical(H_sparse));
    
    % 3. Szimuláció futtatása A JAVÍTOTT H_fixed MÁTRIXSZAL
    [TurboErr, n, BlockLengthHalf, place] = AM2_4M(H_fixed, ...
      maxFrames, K, snrRange, 1, oneBitPart);
    
    % 4. Eredmények mentése
    save(matOutputPath, 'TurboErr', 'n', 'BlockLengthHalf', 'snrRange', 'place');
    
    % 5. Egyedi grafikon generálása
    fig_single = figure('Visible', 'off'); 
    semilogy(snrRange, TurboErr, 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
    grid on;
    title(sprintf('Waterfall Görbe: %s', nameWithoutExt), 'Interpreter', 'none');
    xlabel('Jel-Zaj viszony (SNR) [dB]');
    ylabel('Bithibaarány (BER)');
    exportgraphics(fig_single, pngOutputPath, 'Resolution', 300);
    close(fig_single); 
    
    % 6. Hozzáadás a közös ábrához
    semilogy(ax_all, snrRange, TurboErr, 'LineWidth', 2, 'Marker', 'x');
    legend_labels{end+1} = nameWithoutExt; 
    fprintf('KÉSZ.\n');
    
  catch ME
    fprintf('HIBA!\n  Ok: %s\n', ME.message);
  end
end

if ~isempty(legend_labels)
  grid(ax_all, 'on');
  title(ax_all, ...
    ['Összesített Waterfall Görbék - Kódmátrixok Összehasonlítása, OneBitPart: '...
    num2str(oneBitPart,'%3.2f')]);
  xlabel(ax_all, 'Jel-Zaj viszony (SNR) [dB]');
  ylabel(ax_all, 'Bithibaarány (BER)');
  legend(ax_all, legend_labels, 'Interpreter', 'none', 'Location', 'bestoutside');
  
  summaryPicPath = fullfile(outputFolder, ...
    ['Osszesitett_Eredmenyek_' num2str(oneBitPart,'%3.2f') '.png']);
  exportgraphics(fig_all, summaryPicPath, 'Resolution', 300);
  fprintf('--- Összes fájl feldolgozva! Közös grafikon: %s ---\n', summaryPicPath);
else
  fprintf('--- Befejezve, de egyetlen fájl sem volt sikeres. ---\n');
end
close(fig_all); 
end
