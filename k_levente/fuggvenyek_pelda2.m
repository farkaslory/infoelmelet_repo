%% Központi Vezérlő Szkript 2
% Ez a szkript összefogja és sorban meghívja az összes korábbi modulunkat.

clear; clc;

% 1. Kipróbáljuk a mátrix beolvasót egyetlen fájlon
disp('--- 1. Lépés: Egy mátrix beolvasása teszt jelleggel ---');
% Itt meghívjuk a readTurboCode.m fájlt! Bemenet a fájlnév, kimenet a H mátrix.
H = readTurboCode('LTE_TC_N132_K40.txt'); 
disp('A mátrix sikeresen beolvasva!');

% 2. Kötegelt (Batch) szimuláció indítása
disp('--- 2. Lépés: Kötegelt szimuláció ---');
% Meghívjuk a batchSimu.m fájlt.
% Feltételezzük, hogy van egy 'bemeneti_matrixok' mappád a .txt fájlokkal.
% Az eredményeket egy 'nyers_eredmenyek4' nevű mappába kérjük.
bemenet = 'bemeneti_matrixok';
kimenet = 'nyers_eredmenyek4';
snrTarto = 1:0.5:5;
keretSzam = 200;
K = 20;

batchSimu(bemenet, kimenet, snrTarto, keretSzam, K);

% 3. Eredmények szűrése és összesítése
disp('--- 3. Lépés: Eredmények szűrése ---');
% Meghívjuk a filterAndAggregateResults.m fájlt.
% Kiszűrjük a nyers_eredmenyek4 mappából azokat a .mat fájlokat, ahol n > 10.
% A végeredményt a 'szurt_vegeredmeny4' mappába mentjük.
feltetel = 'n > 10';
filterAndAggregateResults(kimenet, 'szurt_vegeredmeny4', feltetel);

disp('--- MINDEN FOLYAMAT SIKERESEN BEFEJEZŐDÖTT! ---');