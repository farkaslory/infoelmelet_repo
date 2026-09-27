AM4_16M moduláció leírása
___________________________________________

AM4_16M.m

Szimulációs magfüggvény. Elvégzi a váltakozó 4-QAM/16-QAM modulációt, a fizikai AWGN csatorna modellezését, a szekvenciális demodulációt és az LDPC dekódolást. Bemenetei a paritásmátrix és a szimulációs paraméterek, kimenete a kiszámított BER érték.


run_AM4_16M.m

Futtató script. Beolvassa a két WRAN ALIST kódfájlt, párhuzamosított parfor ciklussal lefuttatja a méréseket a megadott oneBitPart tartományon, majd az eredményeket kimenti az AM4_16M_WRAN_results.mat fájlba.


plot_AM4_16M.m

Grafikus ábrázoló függvény. Egy átadott vagy fájlból betöltött eredménystruktúra alapján fél-logaritmikus skálán (semilogy) közös grafikonra rajzolja a két WRAN kód BER-görbéjét a oneBitPart paraméter függvényében.


plotresults_AM4_16M.m

Megjelenítő script. Ellenőrzi és betölti az elmentett AM4_16M_WRAN_results.mat eredményfájlt, majd automatikusan meghívja a plot_AM4_16M függvényt a grafikon kirajzolásához.


Használat

A szimulációhoz ezen 4 fájlon kívül szükséges a két bemeneti fájl (WRAN_N480_K320_P20_R066.txt, WRAN_N480_K360_P20_R075.txt). A run_AM4_16M.m script lefutása után futtassuk a plotresults_AM4_16M.m a grafikon és a görbék kirajzolásához. 

_______________________________________________
