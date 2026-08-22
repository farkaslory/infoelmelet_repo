clear;
folderName = 'WiMax mat with snr';
list = dir(fullfile(folderName, '*.mat'));
size = length(list);
if size == 0
    error('Nem találhatóak .mat fájlok a "%s" mappában! Ellenőrizd a mappa nevét.', matFolderName);
end

figure('Name', 'BER Összehasonlítás', 'NumberTitle', 'off', 'Position', [100,100,800,600]);
hold on;
grid on;
grid minor;

legendText = cell(size, 1);
for i = 1:size
    currentFileName = list(i).name;
    filePath = fullfile(folderName, currentFileName);
    data = load(filePath);
    semilogy(data.snr_range, data.LdpcErr_2, 'LineWidth', 1.5, 'Marker', '.');
    [~,baseName,~] = fileparts(currentFileName);
    legendText{i} = baseName;
end

xlabel('SNR');
ylabel('Bithiba arány')
title('Bithiba arány összehasonlítás')

legend(legendText, 'Location','northeast', 'Interpreter','none');

hold off;