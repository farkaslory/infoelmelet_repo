function H_sparse = readTurboCode(filename)
% READTURBOCODE Robusztus mátrixbeolvasó .txt fájlokhoz (MATLAB R2019+ kompatibilis)
% Automatikusan kezeli a fájlvégi üres sorokat, whitespace-eket és a NaN értékeket.

    % 1. Mátrix beolvasása a .txt fájlból
    if exist('readmatrix', 'file') == 2 || exist('readmatrix', 'builtin') == 5
        H_dense = readmatrix(filename);
    else
        H_dense = load(filename);
    end

    % 2. Felesleges, tisztán NaN sorok és oszlopok levágása (üres sorok a fájl végén)
    H_dense(all(isnan(H_dense), 2), :) = [];
    H_dense(:, all(isnan(H_dense), 1)) = [];

    % 3. Esetleges szórványos NaN értékek kinullázása
    H_dense(isnan(H_dense)) = 0;

    % 4. Átalakítás logikai és ritka (sparse) formátumba
    % A (H_dense == 1) közvetlenül logikai típust ad, hiba nélkül
    H_sparse = sparse(H_dense == 1);
end