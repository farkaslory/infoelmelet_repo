function [Hp, M_eff] = make_h_encodable(H)
%% EZ KELL A AAX_mod.m-NEK A FUTTATÁSÁHOZ!!!
% Bemenet:  H     - az eredeti (esetleg redundáns sorú és/vagy nem
%                    "encoder-ready") parity-check mátrix
% Kimenet:  Hp    - módosított parity-check mátrix, aminek már az utolsó
%                    M_eff oszlopa GF(2) felett invertálható -> ez kell
%                    az ldpcEncoderConfig-nak
%           M_eff - a ténylegesen független (nem redundáns) sorok száma
Hd = full(logical(H));
[M, N] = size(Hd);
%% 1. lépés: redundáns sorok kiszűrése GF(2) Gauss-eliminációval
% Ha egy sor már a korábbi sorok lineáris kombinációja, azt kiszűrjük -
% így M_eff <= M lesz, és garantáltan teljes rangú marad a mátrix.
A = Hd;
rowOrderKept = [];
usedCols = false(1, N);
for r = 1:M
    c = find(A(r, :) & ~usedCols, 1);
    if isempty(c)
        continue   % ez a sor már a korábbi sorok lineáris kombinációja
    end
    usedCols(c) = true;
    rowOrderKept(end+1) = r;
    rowsWithOne = find(A(:, c));
    rowsWithOne(rowsWithOne == r) = [];
    A(rowsWithOne, :) = xor(A(rowsWithOne, :), A(r, :));
end
if numel(rowOrderKept) < M
    warning('make_h_encodable:redundantRows', ...
        '%d redundans (linearisan fuggo) sor volt a H matrixban - eltavolitva.', ...
        M - numel(rowOrderKept));
end
Hd = Hd(rowOrderKept, :);
M_eff = numel(rowOrderKept);
%% 2. lépés: oszlopok permutálása, hogy az utolsó M_eff oszlop
%              GF(2) felett invertálható legyen
% Ugyanazzal a Gauss-eliminációs logikával, de most oszloponként
% keresünk pivotot - a talált pivot-oszlopok kerülnek majd a végére.
A = Hd;
rowUsed = false(1, M_eff);
pivotCols = [];
for c = 1:N
    r = find(A(:, c) & ~rowUsed', 1);
    if isempty(r)
        continue;
    end
    rowUsed(r) = true;
    pivotCols(end+1) = c;
    rowsWithOne = find(A(:, c));
    rowsWithOne(rowsWithOne == r) = [];
    A(rowsWithOne, :) = xor(A(rowsWithOne, :), A(r, :));
    if numel(pivotCols) == M_eff
        break;
    end
end
if numel(pivotCols) < M_eff
    error('make_h_encodable:notFullRank', ...
        'Vartalan hiba: a szurt H matrix sem teljes rangu.');
end
%% Végeredmény: az oszlopok átrendezése (pivot-oszlopok a végére)
otherCols = setdiff(1:N, pivotCols, 'stable');
perm = [otherCols, pivotCols];
Hp = sparse(Hd(:, perm));
end