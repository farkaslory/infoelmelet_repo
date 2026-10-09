%% run_AM4_16M_LTE.m
% Az LTE Turbo Kód fájlok AM4_16M szimulációjának futtató szkriptje.

clear; clc;

scriptFolder = fileparts(mfilename('fullpath'));
if isempty(scriptFolder), scriptFolder = pwd; end

resultsFile = fullfile(scriptFolder, 'AM4_16M_LTE_results.mat');

% Beállítások a feladat szerint
maxFrames = 1000;
K = 20;
noiseDbm = -80;      % -80 dBm
asyncSnrDb = 18;     % 18 dB SNR
oneBitPart = -1:0.1:1;

codeFiles = { ...
    'LTE_TC_N156_K48.txt', ...
    'LTE_TC_N180_K56.txt', ...
    'LTE_TC_N228_K72.txt'};

codeLabels = { ...
    'LTE TC (N=156, K=48)', ...
    'LTE TC (N=180, K=56)', ...
    'LTE TC (N=228, K=72)'};

results = struct();
results.functionName = 'AM4_16M_LTE';
results.noiseDbm = noiseDbm;
results.asyncSnrDb = asyncSnrDb;
results.oneBitPart = oneBitPart;
results.maxFrames = maxFrames;
results.K = K;
results.codes = repmat(struct( ...
    'fileName', '', 'label', '', 'n', [], 'blockLength', [], ...
    'oneBitPartLength', [], 'ber', []), 1, numel(codeFiles));

for codeIdx = 1:numel(codeFiles)
    fileName = codeFiles{codeIdx};
    filePath = fullfile(scriptFolder, fileName);
    
    % N és K kinyerése a fájlnévből
    tokens = regexp(fileName, 'N(\d+)_K(\d+)', 'tokens', 'once');
    if isempty(tokens)
        error('A fajlnev nem megfelelo formatumu: %s', fileName);
    end
    N = str2double(tokens{1});
    K_info = str2double(tokens{2});
    
    fprintf('Futtatas: %s (N=%d, K=%d)...\n', fileName, N, K_info);
    
    ber = zeros(1, numel(oneBitPart));
    partLengths = zeros(1, numel(oneBitPart));
    
    for partIdx = 1:numel(oneBitPart)
        fprintf('  oneBitPart = %+0.1f (%d/%d)\n', ...
            oneBitPart(partIdx), partIdx, numel(oneBitPart));
            
        [berNow, ~, partLengths(partIdx)] = AM4_16M_LTE_TC( ...
            N, K_info, maxFrames, K, noiseDbm, 0, oneBitPart(partIdx), asyncSnrDb);
            
        ber(partIdx) = berNow;
    end
    
    results.codes(codeIdx).fileName = fileName;
    results.codes(codeIdx).label = codeLabels{codeIdx};
    results.codes(codeIdx).n = K_info;
    results.codes(codeIdx).blockLength = N;
    results.codes(codeIdx).oneBitPartLength = partLengths;
    results.codes(codeIdx).ber = ber;
end

save(resultsFile, 'results', '-v7.3');
fprintf('Eredmenyek elmentve: %s\n', resultsFile);

% Ábrázoló meghívása
plot_AM4_16M_LTE_TC(resultsFile);
