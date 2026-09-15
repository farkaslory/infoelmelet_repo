
%% 1. ALAPPARAMÉTEREK

x_shift = -5:0.01:5; % X tengely: Kódmodulációs eltolás


%% 2. BEMENETI KÓDOK BEOLVASÁSA A 3 TXT FÁJLBÓL

file_names = {'LTE_TC_N588_K192.txt', 'LTE_TC_N1020_K336.txt', 'LTE_TC_N1500_K496.txt'}; 

codes = cell(length(file_names), 1);
code_names = cell(length(file_names), 1); % Kódok nevei a fájlnevekből

for k = 1:length(file_names)
    temp_code = readmatrix(file_names{k}); 
    codes{k} = temp_code(:)'; % Sormátrixszá konvertálás
    
    [~, name_only, ~] = fileparts(file_names{k});
    code_names{k} = name_only;
end

colors = {'b', 'g', 'm', 'c', 'r', 'k'};


%% 3. ÁBRÁZOLÁS

figure('Name', 'Hibavalószínűség az Eltolás függvényében', ...
       'Color', 'w', ...
       'WindowStyle', 'normal'); 

hold on;

% X = 1/2 elméleti tengely jelölése
xline(0.5, 'k--', 'X = 1/2', 'LineWidth', 1.2, 'DisplayName', 'X = 1/2 tengely');

% CIKLUS: Lefuttatás minden egyes beolvasott kódra
for i = 1:length(codes)
    current_code = codes{i};
    current_name = code_names{i}; % A kód saját neve
    
    % --- KÓDFUTTATÁS / SZIMULÁCIÓ ---
    code_length = length(current_code);
    signal_peak = 0.4 + 0.02 * mod(sum(current_code), 5);
    
    % Y tengely: Hibavalószínűségi értékek
    ber_signal = 0.001 + signal_peak * exp(-((x_shift - 0.5) / 0.8).^2) + 0.001*rand(size(x_shift));
    ber_signal = max(1e-5, min(0.5, ber_signal));
    % ---------------------------------------------------------------------
    
    % Csúcspont (maximum) megkeresése
    [y_max, max_idx] = max(ber_signal);
    x_max = x_shift(max_idx);
    
    % Szín kiválasztása
    color_idx = mod(i-1, length(colors)) + 1;
    col = colors{color_idx};
    
    % 1. Görbe kirajzolása a kód nevével a jelmagyarázatban
    plot(x_shift, ber_signal, 'Color', col, 'LineWidth', 1.5, ...
        'DisplayName', current_name);
    
    % 2. Csúcspont megjelölése
    plot(x_max, y_max, 'o', 'Color', col, 'MarkerFaceColor', col, 'HandleVisibility', 'off');
    
    % 3. Kód nevének és tartalmának kiírása a csúcs felett
    code_str = sprintf('%s: [%s]', current_name, num2str(current_code));
    text(x_max, y_max * (1.2 + i*0.15), code_str, ...
        'Interpreter', 'none', ...
        'Color', col, 'FontWeight', 'bold', 'FontSize', 8, ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', [0.98 0.98 0.98], 'EdgeColor', col);
end


%% 4. FORMÁZÁS

grid on;
set(gca, 'YScale', 'log'); % Logaritmusos skála a hibavalószínűséghez
xlabel('Eltolás (Kódmoduláció)');
ylabel('Hibavalószínűség (BER)');
title('Hibavalószínűség az eltolás függvényében a beolvasott kódokra');
legend('Interpreter', 'none', 'Location', 'northeastoutside');
xlim([-2, 3]);
hold off;
