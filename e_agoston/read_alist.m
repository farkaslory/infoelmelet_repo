function [H, N, M] = read_alist_2(filename)
% Ez a függvény beolvas egy .alist formátumú file-t és visszaad belőle egy
% H mátrixot, egy N-t és egy M-et. Az N-nek páros számnak kell lennie.
%   Amit a függvény nem tud beolvasni, azt a file-t egyszerűen átugorja.
%% Fájl megnyitása
fid = fopen(filename, 'r');
if fid == -1
    error('Nem sikerult megnyitni a fajlt: %s', filename);
end
cleaner = onCleanup(@() fclose(fid));   % fid-et automatikusan bezárja, ha a függvény véget ér (hiba esetén is)
%% Fejléc beolvasása: N, M, majd a max fokszámok
% 1. sor: N, M (esetleg egy 3. extra szám is lehet utána - azt eldobjuk)
line1 = str2num(fgetl(fid)); 
if numel(line1) < 2
    error('Az 1. sor nem tartalmaz legalabb 2 szamot: %s', filename);
end
N = line1(1);
M = line1(2);
% 2. sor: max oszlop- és sorsúly (itt is csak az első két értéket vesszük)
line2 = str2num(fgetl(fid)); % ez csak azért kell hogy előrelépjen a mutató.
% max_col_deg = line2(1); max_row_deg = line2(2);  % itt nincs ténylegesen használva
%% Fokszám-listák beolvasása és ellenőrzése
% 3. sor: N db oszlopsúly
col_deg = str2num(fgetl(fid)); 
if numel(col_deg) ~= N
    error('A col_deg sor hossza (%d) nem egyezik N-nel (%d) - %s', ...
        numel(col_deg), N, filename);
end
% 4. sor: M db sorsúly
row_deg = str2num(fgetl(fid)); 
if numel(row_deg) ~= M
    error('A row_deg sor hossza (%d) nem egyezik M-mel (%d) - %s', ...
        numel(row_deg), M, filename);
end
%% Oszloponkénti sorindexek beolvasása
% N db sor: az egyes oszlopok nemnulla elemeinek sorindexei.
% Soronként olvasunk, és csak a valós (1..M közötti) indexeket tartjuk meg -
% így nem számít, hogy az adott fájl paddel-e nullákkal vagy sem.
row_idx = zeros(sum(col_deg), 1);
col_idx = zeros(sum(col_deg), 1);
ptr = 0;
for j = 1:N
    ln = fgetl(fid);
    if ~ischar(ln)
        error('A fajl varatlanul veget ert a(z) %d. oszlopnal (osszesen %d oszlop kellene) - %s', ...
            j, N, filename);
    end
    vals = str2num(ln); 
    valid = (vals > 0) & (vals <= M);
    vals = vals(valid);
    if isempty(vals)
        error('A(z) %d. oszlophoz nem tartozik ervenyes sorindex (ures oszlop lenne) - %s', ...
            j, filename);
    end
    n_new = numel(vals);
    row_idx(ptr+1:ptr+n_new) = vals(:);
    col_idx(ptr+1:ptr+n_new) = j;
    ptr = ptr + n_new;
end
row_idx = row_idx(1:ptr);
col_idx = col_idx(1:ptr);
%% Ritka H mátrix összeállítása
H = sparse(row_idx, col_idx, true, M, N);
end
