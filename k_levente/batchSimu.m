function batchSimu(inputFolder, outputFolder, snrRange, maxFrames, K)
    % BATCHSIMU - Egy mappa összes .txt AList fájlját feldolgozza

    % Ha nincsenek megadva paraméterek, alapértelmezetteket használunk
    if nargin < 1, inputFolder = 'Matrixok'; end
    if nargin < 2, outputFolder = 'Eredmenyek'; end
    if nargin < 3, snrRange = 1:0.5:5; end
    if nargin < 4, maxFrames = 100; end
    if nargin < 5, K = 20; end

    % Ellenőrizzük, létezik-e a bemeneti mappa
    if ~isfolder(inputFolder)
        error('A bemeneti mappa nem létezik: %s', inputFolder);
    end

    % Ha a kimeneti mappa nem létezik, létrehozzuk
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end

    % Kikeressük az összes .txt fájlt a bemeneti mappából
    txtFiles = dir(fullfile(inputFolder, '*.txt'));
    numFiles = length(txtFiles);

    if numFiles == 0
        fprintf('Nem találtam .txt fájlt a %s mappában.\n', inputFolder);
        return;
    end

    fprintf('--- Batch feldolgozás indítása: %d fájl ---\n', numFiles);
    
    % FŐ (ÖSSZESÍTŐ) GRAFIKON LÉTREHOZÁSA A CIKLUS ELŐTT
    % Ezt a memóriában tartjuk ('Visible', 'off'), és mindent rápakolunk
    fig_all = figure('Name', 'Összesített Görbék', 'Visible', 'off');
    ax_all = axes(fig_all);
    hold(ax_all, 'on'); % A hold on miatt az új görbék nem törlik a régieket!
    legend_labels = {}; % Üres cellatömb a mátrixok neveinek tárolására a jelmagyarázathoz

    for i = 1:numFiles
        % Fájlnevek összeállítása
        baseFileName = txtFiles(i).name;
        [~, nameWithoutExt, ~] = fileparts(baseFileName);
        
        fullInputPath = fullfile(inputFolder, baseFileName);
        matOutputPath = fullfile(outputFolder, [nameWithoutExt, '_result.mat']);
        pngOutputPath = fullfile(outputFolder, [nameWithoutExt, '_plot.png']);
        
        fprintf('[%d/%d] Feldolgozás: %s ... ', i, numFiles, baseFileName);
        
        try
            % 1. Mátrix beolvasása a korábbi függvénnyel
            H_sparse = readTurboCode(fullInputPath);
        
            % 2. Szimuláció futtatása a magfüggvénnyel
            % Paraméterek: H, maxFrames, K, snrRange, calcPlace (0 vagy 1)
            [TurboErr, n, BlockLengthHalf, place] = AM2_4(H_sparse, maxFrames, K, snrRange, 1);
        
            % 3. Eredmények kimentése a .mat fájlba
            save(matOutputPath, 'TurboErr', 'n', 'BlockLengthHalf', 'snrRange', 'place');
            
            % 4. EGYEDI grafikon generálása és mentése (ahogy kérted, minden .mat mellé)
            fig_single = figure('Visible', 'off'); % Ne ugorjon fel az ablak
            semilogy(snrRange, TurboErr, 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
            grid on;
            title(sprintf('Waterfall Görbe: %s', nameWithoutExt), 'Interpreter', 'none');
            xlabel('Jel-Zaj viszony (SNR) [dB]');
            ylabel('Bithibaarány (BER)');
            
            exportgraphics(fig_single, pngOutputPath, 'Resolution', 300);
            close(fig_single); % Memória felszabadítása
            
            % 5. HOZZÁADÁS A KÖZÖS GRAFIKONHOZ!
            % A görbét felrajzoljuk a korábban létrehozott ax_all tengelyre
            semilogy(ax_all, snrRange, TurboErr, 'LineWidth', 2, 'Marker', 'x');
            legend_labels{end+1} = nameWithoutExt; % Elmentjük a nevét a legendhez
            
            fprintf('KÉSZ.\n');
            
        catch ME
            % Ha hiba van (pl. nem teljes rangú mátrix), átugorjuk
            fprintf('HIBA!\n  Ok: %s\n', ME.message);
        end
    end
    
    % CIKLUS VÉGE: A KÖZÖS GRAFIKON FORMÁZÁSA ÉS MENTÉSE
    if ~isempty(legend_labels)
        % Tengelyek és feliratok beállítása a közös ábrán
        grid(ax_all, 'on');
        title(ax_all, 'Összesített Waterfall Görbék - Kódmátrixok Összehasonlítása');
        xlabel(ax_all, 'Jel-Zaj viszony (SNR) [dB]');
        ylabel(ax_all, 'Bithibaarány (BER)');
        
        % Jelmagyarázat (Legend) hozzáadása a nevekkel. 
        % Interpreter none azért kell, hogy a fájlnevekben lévő "_" jelet ne indexnek nézze.
        % Location bestoutside: a dobozt a grafikonon kívülre teszi, hogy ne takarja a görbéket!
        legend(ax_all, legend_labels, 'Interpreter', 'none', 'Location', 'bestoutside');
        
        % Közös kép kimentése a kimeneti mappába
        summaryPicPath = fullfile(outputFolder, 'Osszesitett_Eredmenyek.png');
        exportgraphics(fig_all, summaryPicPath, 'Resolution', 300);
        
        fprintf('--- Összes fájl feldolgozva! Közös grafikon: %s ---\n', summaryPicPath);
    else
        fprintf('--- Befejezve, de egyetlen fájl sem volt sikeres. ---\n');
    end
    
    close(fig_all); % Memória felszabadítása a legvégén
end