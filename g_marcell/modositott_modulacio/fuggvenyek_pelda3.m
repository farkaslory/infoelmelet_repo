%% Központi Vezérlő Szkript 3
% Ez a szkript összefogja és sorban meghívja az összes korábbi modulunkat
% és a módosított AM2_4modified.m scriptet

clear; clc; clear functions

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
%kimenet = 'nyers_eredmenyek4';
snrTarto = 1:0.5:5;
keretSzam = 200;
K = 20;

for i_oneBitPart = 1:4  %oneBitPart = [0.2 0.4 0.6 0.8] 

  disp(i_oneBitPart)
  oneBitPart = i_oneBitPart*0.2;
  kimenet = ['nyers_eredmenyek4_' num2str(oneBitPart,'%3.2f')];

  batchSimu3(bemenet, kimenet, snrTarto, keretSzam, K, oneBitPart);

  % 3. Eredmények szűrése és összesítése
  disp('--- 3. Lépés: Eredmények szűrése ---');
  % Meghívjuk a filterAndAggregateResults.m fájlt.
  % Kiszűrjük a nyers_eredmenyek4 mappából azokat a .mat fájlokat, ahol n > 10.
  % A végeredményt a 'szurt_vegeredmeny4' mappába mentjük.
  feltetel = 'n > 10';
  filterAndAggregateResults(kimenet, 'szurt_vegeredmeny4', feltetel);

  disp('--- MINDEN FOLYAMAT SIKERESEN BEFEJEZŐDÖTT! ---');

end
