function plotSpeedLoss(inputFolder, outputFolder, opts)
% PLOTSPEEDLOSS Kiszámítja és ábrázolja az átfedéses 4-QAM/16-QAM moduláció
% adatátviteli sebességveszteségét (spektrális hatékonyság csökkenését)
% a szinkron 16-QAM rendszerhez képest.
%
%   plotSpeedLoss()                  % mindkét ábra a szkript melletti "abra" mappába
%   plotSpeedLoss("bemeneti_matrixok", "", Sotet=false)   % világos téma nyomtatáshoz

    arguments
        inputFolder  (1,1) string = "bemeneti_matrixok"
        outputFolder (1,1) string = ""      % üres: a szkript mappájában lévő "abra"
        opts.Sotet   (1,1) logical = true
    end

    scriptDir = string(fileparts(mfilename("fullpath")));
    if outputFolder == ""
        outputFolder = fullfile(scriptDir, "abra");
    end
    if ~isfolder(outputFolder)
        mkdir(outputFolder);
    end
    % relatív bemeneti mappa: először a szkript mellett keressük, utána az aktuális mappában
    if ~isfolder(inputFolder) && isfolder(fullfile(scriptDir, inputFolder))
        inputFolder = fullfile(scriptDir, inputFolder);
    end

    % Színséma
    if opts.Sotet
        bg = "black"; fg = "w"; legBg = [0.1 0.1 0.1];
    else
        bg = "white"; fg = "k"; legBg = "white";
    end
    asyncName = "Aszinkron_ÁtfedésesM_4_16";

    %% ====================================================================
    %  1. ÁBRA: ELMÉLETI SEBESSÉGVESZTESÉG ÉS SPEKTRÁLIS HATÉKONYSÁG (L FÜGGVÉNYÉBEN)
    %% ====================================================================
    L_vec = 1:50;                                       % láncolt kódszavak száma
    rateLossPct = (1 ./ (L_vec + 1)) * 100;             % Relatív veszteség [%]

    % Tipikus LTE Turbo kódarány (R ≈ 1/3, pl. N=132, K_info=40 -> R = 40/132)
    R_nom = 40 / 132;
    eta_sync_16QAM  = 4 * R_nom * ones(size(L_vec));
    eta_async_AM416 = 4 * R_nom * (L_vec ./ (L_vec + 1));

    fig1 = figure(Name="Aszinkron Sebességveszteség Analízis", NumberTitle="off", ...
        Color=bg, Position=[100, 100, 1100, 520]);

    % --- Bal oldali részábra: Százalékos sebességveszteség ---
    ax1 = subplot(1, 2, 1, Parent=fig1); hold(ax1, "on");
    plot(ax1, L_vec, rateLossPct, LineStyle="-", LineWidth=2.2, Color=[0.0, 0.75, 1.0]);

    % L = 10 és L = 20 munkapontok kiemelése
    highlightL = [10, 20];
    highlightLoss = (1 ./ (highlightL + 1)) * 100;
    plot(ax1, highlightL, highlightLoss, LineStyle="none", Marker="o", ...
        MarkerSize=8, MarkerFaceColor=[1.0, 0.3, 0.3], Color=fg);

    for idx = 1:numel(highlightL)
        lVal = highlightL(idx);
        loss = highlightLoss(idx);
        text(ax1, lVal + 1.5, loss + 2.5, ...
            sprintf("L = %d: -%.2f%% (%.2f dB)", lVal, loss, 10*log10((lVal+1)/lVal)), ...
            Color=fg, FontSize=9.5, FontWeight="bold");
    end

    styleAxes(ax1, "Relatív sebességveszteség: 1 / (L + 1)", ...
        "Láncolt kódszavak száma (L)", "Sebességveszteség [%]", bg, fg);
    xlim(ax1, [1, 50]); ylim(ax1, [0, 55]);

    % --- Jobb oldali részábra: Spektrális hatékonyság konvergenciája ---
    ax2 = subplot(1, 2, 2, Parent=fig1); hold(ax2, "on");
    plot(ax2, L_vec, eta_sync_16QAM,  LineStyle=":", LineWidth=2.2, Color=[1.0, 0.5, 0.1]);
    plot(ax2, L_vec, eta_async_AM416, LineStyle="-", LineWidth=2.0, Color=[1.0, 0.5, 0.1]);

    styleAxes(ax2, "Spektrális hatékonyság konvergenciája (N=132, K_{info}=40)", ...
        "Láncolt kódszavak száma (L)", "Spektrális hatékonyság [info bit / szimbólum]", bg, fg);
    legend(ax2, ["Szinkron 16-QAM (határérték)", asyncName], ...
        Location="southeast", TextColor=fg, Color=legBg, EdgeColor=fg, Interpreter="none");
    xlim(ax2, [1, 50]); ylim(ax2, [0.5, 1.3]);

    savePath1 = fullfile(outputFolder, "Sebessegveszteseg_Elmeleti_L_fuggvenyeben.png");
    exportgraphics(fig1, savePath1, Resolution=300, BackgroundColor=bg);
    fprintf("-> Elméleti sebességveszteség ábra elmentve: %s\n", savePath1);

    %% ====================================================================
    %  2. ÁBRA: KONKRÉT MÁTRIXOK KIÉRTÉKELÉSE A MENTETT .MAT FÁJLOKBÓL
    %% ====================================================================
    if ~isfolder(inputFolder)
        warning("A 2. ábra nem készült el: nincs ilyen mappa: %s", inputFolder);
        return;
    end
    % bármilyen kiterjesztésű fájl jó (.mat, .txt, .alist), csak a név számít
    matFiles = dir(fullfile(inputFolder, "*"));
    matFiles = matFiles(~[matFiles.isdir]);
    if isempty(matFiles)
        warning("A 2. ábra nem készült el: nincs fájl itt: %s", inputFolder);
        return;
    end

    % Egyedi (N, K_info) mátrixok kigyűjtése a .mat fájlokból
    matrixTable = extractMatrixMetrics(inputFolder, matFiles);
    if isempty(matrixTable)
        warning("A 2. ábra nem készült el: egyik .mat fájl neve sem illeszkedik az ""n<N>_k<K>"" mintára (%s).", inputFolder);
        return;
    end

    % Konzolos összefoglaló táblázat kiírása
    fprintf("\n=================================================================\n");
    fprintf(" %-18s | %-6s | %-11s | %-11s | %-9s\n", ...
        "Mátrix (N, K_info)", "Lánc L", "Sync 16QAM", "Átf. 4_16", "Veszteség");
    fprintf("-----------------------------------------------------------------\n");
    for r = 1:height(matrixTable)
        fprintf(" %-18s | L=%-4d | %.4f b/s  | %.4f b/s  | -%.2f%%\n", ...
            matrixTable.Label(r), matrixTable.ChainL(r), ...
            matrixTable.EtaSync16QAM(r), matrixTable.EtaAM416(r), ...
            matrixTable.LossPct(r));
    end
    fprintf("=================================================================\n");

    % Csoportosított oszlopdiagram a konkrét mátrixokra
    fig2 = figure(Name="Mátrixonkénti Spektrális Hatékonyság", NumberTitle="off", ...
        Color=bg, Position=[150, 150, 1000, 620]);
    axBar = axes(fig2); hold(axBar, "on");

    barData = [matrixTable.EtaSync16QAM, matrixTable.EtaAM416];

    b = bar(axBar, barData, "grouped");
    b(1).FaceColor = [0.85, 0.35, 0.10]; % Szinkron 16-QAM
    b(2).FaceColor = [1.00, 0.65, 0.25]; % Átfedéses 4-QAM/16-QAM

    set(axBar, XTick=1:height(matrixTable), XTickLabel=matrixTable.Label);
    styleAxes(axBar, "Szinkron vs. átfedéses hasznos adatátviteli sebesség mátrixonként", ...
        "Vizsgált LTE Turbo mátrixok", "Információs sebesség [bit / szimbólum]", bg, fg);
    legend(axBar, ["Szinkron 16-QAM", asyncName], ...
        Location="northeastoutside", TextColor=fg, Box="off", Interpreter="none");

    savePath2 = fullfile(outputFolder, "Sebessegveszteseg_Matrixonkent_Bar.png");
    exportgraphics(fig2, savePath2, Resolution=300, BackgroundColor=bg);
    fprintf("-> Mátrixonkénti oszlopdiagram elmentve: %s\n", savePath2);
end

%% ========================================================================
%  SEGÉDFÜGGVÉNYEK
%% ========================================================================
function T = extractMatrixMetrics(inDir, matFiles)
    fileNames = string({matFiles.name});
    N_list = nan(numel(fileNames), 1);
    K_list = nan(numel(fileNames), 1);

    for i = 1:numel(fileNames)
        tok = regexp(fileNames(i), "n(\d+)_k(\d+)", "tokens", "once", "ignorecase");
        if ~isempty(tok)
            N_list(i) = str2double(tok(1));
            K_list(i) = str2double(tok(2));
        end
    end

    valid = ~isnan(N_list) & ~isnan(K_list);
    fileNames = fileNames(valid);
    N_list    = N_list(valid);
    K_list    = K_list(valid);

    uniqueNK = unique([N_list, K_list], "rows", "stable");
    numM = size(uniqueNK, 1);

    Label        = strings(numM, 1);
    ChainL       = zeros(numM, 1);
    EtaSync16QAM = zeros(numM, 1);
    EtaAM416     = zeros(numM, 1);
    LossPct      = zeros(numM, 1);

    for idx = 1:numM
        N_val = uniqueNK(idx, 1);
        K_inf = uniqueNK(idx, 2);
        Label(idx) = sprintf("N=%d, K=%d", N_val, K_inf);

        % Az adott (N,K)-hoz tartozó első fájl, amiben van lánchossz (a .mat-ban "K" néven)
        matchFiles = fileNames(N_list == N_val & K_list == K_inf);
        L_chain = 20; % alapértelmezett, ha csak Sync fájl lenne
        for m = 1:numel(matchFiles)
            [~, ~, ext] = fileparts(matchFiles(m));
            if lower(ext) ~= ".mat"
                continue;   % lánchossz csak .mat fájlban lehet
            end
            d = load(fullfile(inDir, matchFiles(m)));
            if isfield(d, "K") && ~isempty(d.K)
                L_chain = double(d.K(1));
                break;
            end
        end

        Rc = K_inf / N_val;
        ChainL(idx)       = L_chain;
        EtaSync16QAM(idx) = 4 * Rc;
        EtaAM416(idx)     = 4 * Rc * (L_chain / (L_chain + 1));
        LossPct(idx)      = (1 / (L_chain + 1)) * 100;
    end

    T = table(Label, ChainL, EtaSync16QAM, EtaAM416, LossPct);
end

function styleAxes(ax, plotTitle, xLab, yLab, bg, fg)
    grid(ax, "on"); grid(ax, "minor"); box(ax, "on");
    ax.Color = bg;
    ax.FontSize = 10.5; ax.LineWidth = 1;
    ax.GridColor = fg; ax.MinorGridColor = fg;
    ax.GridAlpha = 0.22; ax.MinorGridAlpha = 0.08;
    ax.XColor = fg; ax.YColor = fg;
    title(ax, plotTitle, FontSize=12, FontWeight="bold", Color=fg);
    xlabel(ax, xLab, FontSize=11, FontWeight="bold", Color=fg);
    ylabel(ax, yLab, FontSize=11, FontWeight="bold", Color=fg);
end