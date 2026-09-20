# LDPC kódok vizsgálata – szinkron és aszinkron moduláció

Az én feladatom a LDPC kódok irányából megközelíteni a tanár úr ötletét, és ezt a következőképpen csináltam:

A tanár úrtól kapott AAC kódot átalakítottam úgy, hogy egy mappát kapjon bemenetként, amiben `.alist` formátumú H mátrixok vannak, ezekre lefusson egy kiválasztott (szinkron vagy aszinkron) modulációs LDPC-szimuláció, és visszaadjon egy hasonlóan elnevezett mappát, amiben az egyes H mátrixokra lefuttatott szimuláció eredménye el legyen mentve egy-egy `.mat` fájlba. Ezeket később külön scriptekkel lehet kirajzolni és összehasonlítani.

## A fő program

### AAC_mod.m

A program fő célja, hogy ne fájlról fájlra kelljen egyesével mátrixokat tesztelni a kiválasztott modulációs módszerrel, hanem egy `.alist` típusú fájlokkal teli mappát adjunk be neki, az alábbi elnevezési formátumban: **"fájlnév alist"** — a mappa neve tehát bármi lehet, de utána egy szóközzel elválasztva szerepeljen az "alist" megnevezés. Ez azért hasznos, mert így könnyen látszik, melyik mappa mire való, és a program ebből tudja levezetni a kimeneti mappa nevét is (a "alist" szót "mat"-ra cserélve).

A mappán belüli **egyes fájlok neve tetszőleges lehet** — a program `.txt` és `.alist` kiterjesztésű fájlokat is felismer, függetlenül attól, hogy az adott fájl neve tartalmazza-e az "alist" szót.

Miután a program lefutott, létrehoz egy "fájlnév mat" nevezetű mappát, amiben a kiválasztott .alist fájlokra, az általunk választott függvénnyel (pl. `Sync_Ldpc.m`, `Async_Ldpc.m`, `AM2_4.m` vagy `AM4_16.m`) lefuttatott szimuláció eredményei találhatók `.mat` formátumban. Ezeknek a `.mat` fájloknak megegyezik a nevük az eredeti `.alist` fájlokéval.

A ténylegesen futtatott függvényt a kód egy sorában (`AAC_mod.m` ~70. sora) lehet kiválasztani/cserélni — ez teszi lehetővé, hogy ugyanazt a fájl-beolvasó/mentő keretrendszert használjuk a `Sync_Ldpc`, `Async_Ldpc`, `AM2_4` és `AM4_16` közül bármelyikhez (illetve egy még hiányzó, AM4_16-hoz tartozó szinkron párhoz is, lásd lentebb az AM4_16 leírásánál).

Egy fontos robusztussági megoldás: a fájlonkénti feldolgozás `try`/`catch` blokkba van csomagolva, így ha egy fájl formátuma nem támogatott, vagy a rá épülő szimuláció bármilyen okból hibát dob, a program nem áll le — csak kiírja, hogy "Kihagyva: [fájlnév] - hiba: ...", és folytatja a mappa következő fájljával.

### AAC_mod.m segédfüggvényei

#### read_alist_2.m

Ez a függvény egyszerűen kinyeri a `.alist` fájlból a kellő információkat: magát a H mátrixot az eredeti formájában (N×M-es mátrix GF(2)-ben), valamint az N-et és az M-et. Az N az oszlopok száma, míg M a sorok száma. A függvény a következő módon néz ki a kódban:

```matlab
[H, N, M] = read_alist_2(fileName)
```

Megadjuk a függvénynek a `.alist` fájl nevét, és ebből kinyeri a H, N és M paramétereket. (Az `AAC_mod.m`-ben az M kimenetet gyakorlatilag nem használjuk — `~`-vel eldobjuk —, mert a `make_h_encodable` úgyis egy saját, esetlegesen ettől eltérő M_eff-et fog visszaadni, lásd alább.)

#### make_h_encodable.m

Előkészíti a nyers, alist-fájlból beolvasott paritásellenőrző mátrixot a MATLAB `ldpcEncoderConfig` számára. A `ldpcEncoderConfig` megköveteli, hogy H utolsó (N−K) oszlopa GF(2) felett invertálható legyen; ez az alist-fájlok eredeti oszlopsorrendjében nem mindig teljesül, és néhány kódnál (pl. a Tanner(155,64) kódnál) a "hivatalos" mátrix redundáns (lineárisan összefüggő) paritássorokat is tartalmaz. A függvény GF(2) Gauss-eliminációval kiszűri az esetleges redundáns sorokat, majd permutálja az oszlopokat úgy, hogy a végén invertálható részmátrix álljon — ez nem változtatja meg a kód hibajavító tulajdonságait, csak a kódolhatóság technikai feltételét teljesíti.

A függvényt a következőképpen kell a kódba illeszteni:

```matlab
[H, M] = make_h_encodable(H)
```

Mivel ez a függvény is ad egy M-et (a ténylegesen független paritássorok számát), ezért nem feltétlenül kell a `read_alist_2` kimenetéből az M-et felhasználni — a fő kódban a `read_alist_2` kimeneténél az M-et egy `~`-vel helyettesítettem. Ezt a függvényt a `read_alist_2` **után** kell meghívni, hogy már legyen egy kész, `.alist` formátumból kiolvasott H mátrixunk, amit át tud alakítani.

## AAC_mod.m-nek a választható belső függvényei (a kód ~70. sora)

### Sync_Ldpc.m

Ez egy általános, szinkron modulációt szimuláló kód, amelyhez a többi (aszinkron) modulációt szimuláló függvényt fogom majd hasonlítani. Minden próbában pontosan **egy** kódszót kódolunk, egyszerű QPSK-modulációval visszük át a csatornán, és dekódolunk — nincs több, egymásra szuperponált felhasználó, nincs interferencia. A függvényt a következőképpen kell meghívni:

```matlab
[BlockLengthHalf, n, LdpcErr_2] = Sync_Ldpc(H, snr_range, numTrials)
```

Meg kell adni neki a már `.alist`-ből kiolvasott és `make_h_encodable`-ön átfuttatott H mátrixot, a kiválasztott `snr_range`-et (pl. 2:0.5:8), és azt, hogy egy adott SNR-értéken belül hány próbával fusson le a szimuláció (`numTrials`) — magasabb szám pontosabb BER-becslést ad, de megnöveli a futási időt. Az `snr_range` szintén befolyásolja a futási időt, mivel minden egyes SNR-értékre külön lefut a szimuláció (pl. a 2:0.5:8-as tartomány 13 ponton méri az eredményt).

A H mátrixon kívül minden bemeneti változónak van alapértelmezett értéke: az `snr_range` alapból 2:0.5:8, a `numTrials` pedig **20000**, ami jelentősen nagyobb, mint az aszinkron függvényeknél. Ennek oka: az Async_Ldpc egy próbában egyszerre `K`(=20) db kódszót dolgoz fel a láncban, tehát 1000 próba alatt ténylegesen 1000×20 = 20000 db kódszó-szintű mintát gyűjt. A Sync_Ldpc viszont próbánként csak 1 kódszót dolgoz fel — ezért kell neki kb. 20-szor annyi próba (20000), hogy hasonló méretű, összehasonlítható statisztikai mintán alapuljon a BER-becslése.

Ezt a magas próbaszámot az teszi kezelhető futási idejűvé, hogy a **`Sync_Ldpc` `parfor`/`parpool`-lal párhuzamosítva fut** (SNR-értékenként egy worker dolgozza fel a hozzá tartozó teljes próbasorozatot) — ez az egyetlen a négy függvény közül, amelyik ezt csinálja; a másik három (`Async_Ldpc`, `AM2_4`, `AM4_16`) teljesen soros.

A kimenete a `BlockLengthHalf` (ami az N/2), az `n` (ami az N−M), és a `LdpcErr_2`, ami az SNR-enként mért hibaarány.

### Async_Ldpc.m

Az eredeti, a tanár úr által írt aszinkron modulációt szimuláló kód egy függvénybe rakva. A szinkron verzióval szemben itt **K db kódszó van egyszerre, egymáshoz képest fél szimbólummal eltolva, QPSK-szuperpozícióval egymásba fésülve** egyetlen jelfolyamba, majd soros interferencia-kioltással (successive interference cancellation) dekódolva: a már dekódolt kódszavakat újrakódoljuk, és a hozzájuk tartozó jelet levonjuk a maradék jelből, mielőtt a következő kódszót dekódolnánk. Ez tesztelésben jobb hibaarányokhoz vezetett.

A függvényt a következőképpen kell meghívni:

```matlab
[BlockLengthHalf, n, LdpcErr_2] = Async_Ldpc(H, snr_range, K, numTrials)
```

Itt a bemenetek csak annyiban térnek el a szinkron verzióétól, hogy meg lehet adni egy `K` változót, ami a láncban egyszerre szuperponált kódszavak (felhasználók) számát határozza meg (alapból 20). A `numTrials` itt alapból csak 1000, mert — mint fentebb írtam — egy próba itt K=20 kódszót dolgoz fel egyszerre, tehát 1000 próba is már 20000 kódszó-szintű mintát ad; ráadásul egy próba itt jóval költségesebb is (K-szoros kódolás/dekódolás a láncban), így a magasabb `numTrials` itt aránytalanul megnövelné a futási időt. A kimenet megegyezik a többi függvényével.

### AM2_4.m

Levente által készített kód, mely (a `Sync_Ldpc`-hez és `Async_Ldpc`-hez hasonlóan) 2 bitet kódol egy szimbólumba QPSK-val. Funkcionálisan nagyon közel áll az `Async_Ldpc`-hez (ugyanaz a K-szuperponált, láncolt SIC-elv), csak kicsit más argumentumsorrenddel és egy opcionális `calcPlace` bemenettel/kimenettel, amivel bekapcsolható a hibaeloszlás (`place`) számítása. Ezt lehet összehasonlítani a `Sync_Ldpc`-vel. A függvényt a következőképpen hívjuk meg:

```matlab
[LdpcErr_2, n, BlockLengthHalf] = AM2_4(H, numTrials, K, snr_range)
```

Itt a bemeneti és kimeneti változók megegyeznek az eddigi konvenciókkal, de figyelj a **sorrendre**: itt `numTrials` és `K` a 2. és 3. paraméter, nem a 2. és 4. mint `Async_Ldpc`-nél, és a kimeneti sorrend is más (`LdpcErr_2` van elöl).

### AM4_16.m

Lajos által készített kód, mely 4 bitet kódol egy szimbólumba (16-QAM), a lánc többi része ugyanazt az elvet követi, mint az AM2_4. Ezt egyelőre **nem** lehet közvetlenül összehasonlítani a `Sync_Ldpc`-vel, mert az csak QPSK-t (2 bit/szimbólum) tud — ehhez egy külön, szintén 4 bit/szimbólumos szinkron kódot kell írni (erre utal az `AAC_mod.m`-ben jelenleg is szereplő, még meg nem valósított `Sync_LDPC_16` hívás). A függvényt a következőképpen hívjuk meg:

```matlab
[LdpcErr_2, n, BlockLengthHalf] = AM4_16(H, numTrials, K, snr_range)
```

Itt hasonlóan, a bemeneti és kimeneti változók (és sorrendjük) megegyeznek az AM2_4-ével. **Fontos**: mivel az AM4_16 azonos SNR mellett kétszer annyi bitet visz át szimbólumonként, mint az AM2_4/Sync_Ldpc, a két görbe nyers SNR-tengelyen **nem** hasonlítható össze közvetlenül — ehhez Eb/N0 = Es/N0 − 10·log10(bit/szimbólum) átszámítás szükséges.

## Az eredmények kirajzolása

A fenti függvények által mentett `.mat` fájlokat (mindegyikben `BlockLengthHalf`, `n`, `K`, `LdpcErr_2`, `snr_range`) két külön script tudja kirajzolni és összehasonlítani:

### mat_to_plot_2.m

Egyetlen mappa összes `.mat` fájlját olvassa be, és egy közös ábrán, `semilogy`-val rajzolja ki mindegyik BER-görbéjét (feketés hátterű, rácsozott ábra, rögzített y-tengely-tartománnyal az összehasonlíthatóság kedvéért). Sok (20-30+) görbe esetén is jól elkülöníthető színeket használ (kevert HSV-paletta), így akár egy egész mappányi kód eredménye egyszerre áttekinthető.

### plotter_snyc_async.m

Két külön mappa (tipikusan egy szinkron és egy aszinkron futtatás eredményei) tartalmát olvassa be, és **ugyanazon az ábrán**, de eltérő vonalstílussal (folytonos vs. pontozott vonal, kör vs. négyzet marker) jeleníti meg — így egy adott kódnak a szinkron és aszinkron BER-görbéje közvetlenül összevethető. A két mappát a script elején kell megadni (`folderSolid`, `folderDotted`).
