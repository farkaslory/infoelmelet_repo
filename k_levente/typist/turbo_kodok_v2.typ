#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
  numbering: "1 / 1",
)
#set text(
  font: "New Computer Modern",
  size: 11pt,
  lang: "hu",
)
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1.")

// Címoldali fejléc
#align(center)[
  #text(18pt, weight: "bold")[3GPP LTE Turbo Kódok Szinkron és Aszinkron Átviteli Rendszereinek Szimulációs Keretrendszere]
  #v(0.5em)
  #text(12pt, fill: gray.darken(40%))[Turbo kódok és architektúra-leírás]
  #v(1.5em)
]

= Az LTE Turbo kódok elméleti háttere és története

== Történeti áttekintés
A digitális hírközléselmélet alapjait Claude Shannon fektette le 1948-ban, meghatározva a zajos csatornán elérhető maximális hibamentes információátviteli sebességet @shannon1948mathematical. Évtizedeken keresztül a gyakorlati kódolási eljárások több decibellel elmaradtak ettől az elméleti korláttól. A hibajavító kódolás történetében az 1993-as év jelentette a legnagyobb fordulópontot, amikor Claude Berrou, Alain Glavieux és Punya Thitimajshima bemutatták a *Turbo kódokat* @berrou1993near. A konstrukció elsőként közelítette meg a Shannon-féle csatornakapacitási határt $0,5 "dB"$-en belülre megvalósítható számítási komplexitás mellett. A 3GPP a 4G *Long Term Evolution* (LTE, TS 36.212) szabványban a Turbo kódokat választotta a fizikai megosztott adatcsatornák (PDSCH, PUSCH) hibajavító sémájának @tanno2007evolved.

== Felépítés és működési elv
Az LTE Turbo kódoló egy párhuzamosan konkatenált konvolúciós kód (PCCC), amelynek alapvető kódaránya $R = 1/3$. Két darab 8-állapotú rekurzív szisztematikus konvolúciós (RSC) rész-kódolóból és egy belső bitátrendezőből (interleaver) áll. Az RSC kódolók generátormátrixa:

$ G(D) = mat(1, (1 + D + D^3) / (1 + D^2 + D^3)) $

Az LTE szabvány a klasszikus pszeudo-véletlen átrendező helyett a *Kvadratikus Permutációs Polinom* (QPP) interleavert vezette be @sun2005interleavers. Egy $K_"info"$ hosszúságú információs blokk esetén az $i$-edik kimeneti bit eredeti pozícióját az alábbi kongruencia határozza meg:

$ Pi(i) = (f_1 dot i + f_2 dot i^2) mod K_"info" $

ahol $f_1$ és $f_2$ a blokkhossztól függő szabványos állandók. A kódolási folyamat végén mindkét RSC kódoló regisztereit 3-3 farokbittel (összesen 12 tail bittel) nullázzák, így a teljes kódszóhossz $N = 3 K_"info" + 12$ bitre adódik (például $K_"info" = 40$ esetén $N = 132$).

== Előnyök, hátrányok és Tanner-gráfos dekódolás
A Turbo kódok legfőbb előnye a rendkívül meredek bithibaarány (BER) letörés a *vízesés-tartományban* (waterfall region), valamint a QPP átrendező ütközésmentes (contention-free) párhuzamosíthatósága. Hátrányuk a magasabb SNR tartományban ($"BER" < 10^(-5)$) jelentkező *hibaküszöb* (error floor), amelyet a viszonylag alacsony szabad távolság ($d_"free"$) okoz.

A hagyományos Turbo dekódolók összetevőnként a szimbólumonkénti optimális BCJR/MAP algoritmust alkalmazzák @bahl2002optimal. Mi viszont a kutatásunkban a kódokat ritka paritásellenőrző mátrixukkal ($H in {0,1}^(M times N)$) reprezentáljuk, és a vevőoldalon iteratív *Belief Propagation* (BP / LDPC) dekódolást alkalmazunk. Ennek sajátossága, hogy a rövid blokkhosszú Turbo kódok Tanner-gráfjában előforduló rövid (4-es és 6-os) hurkok alacsony jel-zaj viszonynál korlátozhatják a BP algoritmus konvergenciáját @mceliece1998turbo.

= A moduláris szimulációs és kiértékelő keretrendszer felépítése

A szimulációs keretrendszert úgy alakítottuk ki, hogy képes legyen mind az LTE szabványos Turbo kódjait, mind az általános ritka paritásellenőrző (LDPC) mátrixokat egységes pipeline-ban kezelni. A folyamat a bemeneti fájlok beolvasásától a tömeges párhuzamosított szimuláción és a `.mat` fájlok generálásán át a `.png` ábrák automatikus kirajzolásáig terjed.

#figure(
  block(
    fill: rgb("#f8fafc"),
    stroke: 0.5pt + rgb("#cbd5e1"),
    inset: 8pt,
    radius: 6pt,
    width: 100%,
    align(center)[
      #show raw: set text(size: 7.2pt)
      #raw(
        block: true,
"┌────────────────────────────────┐         ┌────────────────────────────────┐
│ LTE Turbo mátrixok (.txt)      │         │     LDPC mátrixok (.alist)     │
└───────────────┬────────────────┘         └───────────────┬────────────────┘
                │                                          │
                ▼                                          ▼
┌────────────────────────────────┐         ┌────────────────────────────────┐
│       readTurboCode.m          │         │        read_alist_2.m          │
└───────────────┬────────────────┘         └───────────────┬────────────────┘
                └────────────────────┬─────────────────────┘
                                     ▼
                  ┌─────────────────────────────────────┐
                  │ H (sparse logical) paritásmátrix    │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                    TÖMEGES VEZÉRLÉS: runSim.m / runMod.m                  │
│       (Párhuzamos parfor szálkezelés és Worker-Chunking memóriavédelem)   │
└────────────────────────────────────┬──────────────────────────────────────┘
                                     │
     ┌───────────────────────────────┴───────────────────────────────┐
     ▼                                                               ▼
┌─────────────────────────────────┐   ┌─────────────────────────────────────┐
│    SZINKRON REFERENCIA MAGOK    │   │      ASZINKRON SIC LÁNCOLT MAGOK    │
│  • Sync_LDPC.m    (QPSK, 2 b/s) │   │  • AM2_4.m        (BPSK/QPSK lánc)  │
│  • Sync_LDPC_16.m (16-QAM, 4 b/s│   │  • AM4_16_Gray.m  (Gray konstelláció│
│                                 │   │  • AM4_16_Soft.m  (Lágy LLR SIC)    │
│                                 │   │  • AM4_16_Bidir.m (Kétirányú lánc)  │
└────────────────┬────────────────┘   └──────────────────┬──────────────────┘
                 └───────────────────┬───────────────────┘
                                     ▼
                  ┌─────────────────────────────────────┐
                  │ Standardizált .mat adatkonténerek   │
                  │   (ber, snrRange, n, K, place...)   │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │        plotNK.m / plotMat.m         │
                  │ (N, K csoportosítás, tight scaling) │
                  └──────────────────┬──────────────────┘
                                     │
                                     ▼
                  ┌─────────────────────────────────────┐
                  │     Szemléltető .png grafikonok     │
                  └─────────────────────────────────────┘"
      )
    ]
  ),
  caption: [A korszerűsített, kétirányú bemenetet és kibővített modulációs magokat támogató szimulációs adatfolyam.]
)

== A szimulációs pipeline moduljai és feladatköreik

A rendszer moduláris felépítésű, így új modulációs eljárások vagy bemeneti formátumok a vezérlő logika módosítása nélkül illeszthetők be:

#figure(
  table(
    columns: (1.4fr, 1.3fr, 2.3fr),
    inset: 6.5pt,
    align: (left, left, left),
    fill: (x, y) => if y == 0 { rgb("#e2e8f0") } else { none },
    [*Modul neve*], [*Bemenet*], [*Szerepkör és működés*],
    [`readTurboCode.m`], [Szöveges `.txt` útvonal], [LTE Turbo kódok ritka paritásmátrixának beolvasása, `NaN` sorok szűrése és logikai formátumra hozása.],
    [`read_alist_2.m`], [Szabványos `.alist` útvonal], [LDPC kódok David MacKay-féle alist formátumának beolvasása és sparse paritásmátrixszá konvertálása.],
    [`Sync_LDPC.m`], [`H, maxFrames, snrRange`], [Szinkron QPSK referencia átvitel egzakt távolságnégyzet-alapú LLR számítással (2 bit/szimbólum).],
    [`Sync_LDPC_16.m`], [`H, maxFrames, snrRange`], [Szinkron 16-QAM referencia mérés analitikus négyszintű LLR demodulációval (4 bit/szimbólum).],
    [`AM2_4.m`], [`H, maxFrames, K, snrRange`], [Aszinkron BPSK/QPSK lánc szekvenciális interferencia-kioltással (SIC) és hibapozíció-naplózással.],
    [`AM4_16_Gray.m`], [`H, maxFrames, K, snrRange`], [Aszinkron 4-QAM/16-QAM átvitel hagyományos Gray-kódolt szimbólumtérképezéssel a szuperpozíciós rétegeken.],
    [`AM4_16_Soft.m`], [`H, maxFrames, K, snrRange`], [Aszinkron 4-QAM/16-QAM SIC, ahol a kioltás nem kemény döntésű visszakódoláson, hanem lágy LLR megbízhatósági súlyozáson alapul.],
    [`AM4_16_Bidir.m`], [`H, maxFrames, K, snrRange`], [Kétirányú (oda-vissza) SIC lánc, amely a blokksorozat mindkét végéről indítva csökkenti a peremhatásból eredő hibaterjedést.],
    [`runMod.m`], [`funcName, H, opts...`], [Univerzális diszpécser: string paraméter alapján meghívja a kívánt magot, és egységes struct-ba zárja az eredményeket.],
    [`runSim.m`], [`funcName, inDir, outDir`], [Kötegelt motor: a megadott bemeneti mappa összes mátrixára lefut, és kimenti a szabványos `.mat` fájlokat.],
    [`plotNK.m`], [`inputFolder, outputFolder`], [Kiolvassa a `.mat` fájlokból az $N$ és $K$ értékeket, kategóriák szerint színez (sync, bidir, gray, soft), és szoros skálázású `.png`-t ment.]
  ),
  caption: [A keretrendszerben implementált modulok funkcionális összefoglalása.]
)

= A szimulációs `.mat` adatkonténerek felépítése

A hosszú lefutású szimulációk eredményeit a MATLAB bináris `.mat` fájljaiban tároljuk. Ez biztosítja, hogy a vizualizáció és a statisztikai kiértékelés teljesen független legyen a számítási folyamattól: ha a grafikonok stílusát, tengelyhatárait vagy kategóriáit módosítani kell, a többórás szimulációkat nem kell megismételni. Emellett a szerveroldali megszakadások ellen töréspont-védelmet (checkpointing) nyújt, és lebegőpontos pontossággal őrzi meg az alacsony, $"BER" < 10^(-5)$ értékeket is.

A kimeneti fájlok elnevezése szigorú sémát követ:
#align(center)[
  `[MátrixAlapnév]_[ModulációTípus].mat` \
  #text(9pt, fill: gray.darken(30%))[(Például: `LTE_TC_N132_K40_AM4_16_Gray.mat`, `LDPC_N1000_K500_Sync_QPSK.mat`)]
]

A szimulációs magok kimenetei egy egységes változóstruktúrába rendezve kerülnek elmentésre:

#figure(
  table(
    columns: (1.5fr, 1.2fr, 1fr, 2.5fr),
    inset: 7pt,
    fill: (x, y) => if y == 0 { rgb("#e2e8f0") } else { none },
    [*Változónév*], [*Típus*], [*Jelenlét*], [*Leírás és jelentés*],
    [`ber`], [`1 x M double`], [Minden fájlban], [A mért bithiba-arány az SNR pontok függvényében (korábbi elnevezések: `am24Err`, `syncErr_QPSK` stb.).],
    [`snrRange`], [`1 x M double`], [Minden fájlban], [A szimulált jel-zaj viszony vektor dB-ben (pl. $1 : 0.5 : 6$ vagy $10 : 1 : 20$).],
    [`n`], [`1 x 1 double`], [Minden fájlban], [Az információs bitek száma blokkonként ($K_"info"$).],
    [`BlockLengthHalf`], [`1 x 1 double`], [Minden fájlban], [A fél kódszóhossz szimbólumokban ($N/2$).],
    [`maxFrames`], [`1 x 1 double`], [Minden fájlban], [Az egyetlen SNR ponton szimulált keretek száma.],
    [`K`], [`1 x 1 double`], [Csak aszinkron], [A szuperponált láncban összekapcsolt kódszavak száma (pl. $K = 10$ vagy $K = 20$).],
    [`place`], [`1 x K double`], [Csak aszinkron], [Hibapozíció-hisztogram: megmutatja, hogy a lánc melyik blokkjában fordult elő a legtöbb bithiba (SIC hibaterjedés vizsgálata).]
  ),
  caption: [A mentett `.mat` adatkonténerek egységesített belső változószerkezete.]
)

== Memóriakezelés és Worker-Chunking architektúra
A nagy méretű mátrixok ($N >= 1000$) és magas keretszámok ($20\,000$ keret SNR-pontonként) futtatásakor a `parfor` cikluson belüli keretenkénti objektumklónozás (`clone(hEnc)`) memóriatöredezettséghez és a munkaszálak összeomlásához (OOM) vezethet. Ennek kiküszöbölésére *Worker-Chunking* architektúrát vezettünk be: a külső `parfor` ciklus a fizikai munkaszálak (`w = 1:numWorkers`) felett iterál, így a kódoló és dekódoló objektumok szálanként mindössze egyetlen egyszer jönnek létre.

= A `.mat` adatkonténerek szerepe és felépítése

A szimulációs eredmények MATLAB bináris `.mat` (MAT-file v5.0) formátumban kerülnek perzisztens tárolásra. Ennek három fő előnye van:
1. *A számítás és a megjelenítés szétválasztása:* A többórás futások eredményei másodpercek alatt újrarajzolhatók és átformázhatók a `plotSavedMatResults.m` segítségével.
2. *Töréspont-biztonság (Checkpointing):* Mivel minden modulációs lépés után azonnal megtörténik a mentés, egy szerveroldali megszakadás esetén a korábbi mátrixok eredményei nem vesznek el.
3. *Veszteségmentes IEEE 754 tárolás:* A $10^{-5}$ alatti BER értékek és a `place` hibaeloszlási vektorok kerekítési hiba nélkül, tömörítve tárolódnak.

Minden bemeneti mátrixhoz (pl. `LTE_TC_N132_K40.txt`) négy különálló `.mat` fájl keletkezik:

#figure(
  table(
    columns: (1.4fr, 1.8fr, 2fr),
    inset: 7pt,
    fill: (x, y) => if y == 0 { rgb("#e2e8f0") } else { none },
    [*Fájlnév sablon*], [*Tárolt változók*], [*Tartalom és szerep*],
    [`*_Sync_QPSK.mat`], [`syncErr_QPSK`, `n_sync_qpsk`, `BlockLengthHalf_sync_qpsk`, `snrRange_AM24`, `maxFrames`], [A 2 bit/szimbólumos szinkron QPSK referencia mérés BER görbéje és méretparaméterei.],
    [`*_AM2_4.mat`], [`am24Err`, `n_am24`, `BlockLengthHalf_am24`, `place_am24`, `K`, `snrRange_AM24`, `maxFrames`], [Az aszinkron BPSK/QPSK lánc BER vektora és a `place` ($1 times K$) hibahely-eloszlás.],
    [`*_Sync_16QAM.mat`], [`syncErr_16QAM`, `n_sync_16qam`, `BlockLengthHalf_sync_16qam`, `snrRange_AM416`, `maxFrames`], [A 4 bit/szimbólumos szinkron 16-QAM referencia mérés BER adatai.],
    [`*_AM4_16.mat`], [`am416Err`, `n_am416`, `BlockLengthHalf_am416`, `place_am416`, `K`, `snrRange_AM416`, `maxFrames`], [Az aszinkron 4-QAM/16-QAM lánc BER görbéje és a láncon belüli SIC hibaprofil.]
  ),
  caption: [A mátrixonként előállított négy `.mat` adatfájl belső sémája.]
)

#show figure.where(kind: image): set figure(supplement: [grafikon])

= Szimulációs eredmények és a mérési adatok kiértékelése

A kifejlesztett automatizált mérési keretrendszerrel elvégzett kiterjedt szimulációk célja az volt, hogy valós LTE Turbo kód paritásmátrixokon igazoljuk vagy cáfoljuk az aszinkron szuperpozíciós eljárások elméleti korlátait. A mérési adatok feldolgozása során két merőben eltérő, rendkívül tanulságos viselkedési mintázat rajzolódott ki a BPSK/QPSK alapú (AM2-4) és a magasabb rendű 4-QAM/16-QAM (AM4-16) rendszerekben.

== Szinkron QPSK és Aszinkron AM2-4 rendszerek összehasonlítása

 Az elméleti levezetések alapján az aszinkron szuperponált lánc a két peremi félblokk miatt $1 / (K + 1)$ mértékű spektrális sebességveszteséget szenved, ami a szimulációkban alkalmazott $K = 20$ lánchossz mellett mintegy $0,21 "dB"$-es elméleti SNR-eltolódásnak felel meg. A javított és hitelesített szimulációs mérések azt mutatják, hogy *az aszinkron AM2-4 eljárás hibajavítási teljesítménye szorosan követi, és gyakorlatilag megegyezik a szinkron QPSK referenciaátvitelével*.

Összesen *23 különböző méretű LTE Turbo mátrix* részletes vizsgálata alapján az alábbi fő következtetések vonhatók le:
- Az aszinkron AM2-4 BER görbéi a teljes mérettartományban szinte tökéletesen rásimulnak a szinkron QPSK görbékre; a két eljárás közötti eltérés a legtöbb SNR ponton a Monte Carlo szimuláció statisztikai ingadozásán belül marad.
- Ez az eredmény kísérletileg igazolja a vevőoldali szekvenciális interferencia-kioltás (SIC) robusztusságát: a BPSK/QPSK modulációs szinteknél a visszakódolt és kivont jelkomponensek nem visznek be maradék interferenciát a láncba, így elkerülhető a hibák lavinaszerű továbbterjedése.
- A szuperpozíciós aszinkron átvitel tehát anélkül valósítható meg, hogy a rendszer érdemi hibavédelmi vagy teljesítménybeli büntetést szenvedne a hagyományos, szigorúan szinkronizált keretátvitelhez képest.

A kódméret növelésének hatása a szinkron és aszinkron esetben párhuzamosan jelentkezik: a kisebb kódoknál ($N < 500$) tapasztalható lankásabb lefutást a nagyobb blokkhosszak ($N > 1000$) felé haladva egyre meredekebb vízesés-karakterisztika váltja fel, miközben az AM2-4 és a szinkron referencia közötti szoros illeszkedés végig megmarad.

== Szinkron 16-QAM és az Aszinkron AM4-16 eljárások diverzitás-analízise

A 4-QAM és 16-QAM konstellációkat ötvöző AM4-16 rendszerek kiértékelése során a szimulációkat szintén *23 különböző reprezentatív mátrixra* futtattuk le, összevetve a szinkron 16-QAM referenciát az aszinkron lánc normál demodulációján kívüli három továbbfejlesztett változatával is:
1. `AM4_16_Gray`: hagyományos Gray-kódolású kvadratúra szimbólumtérképezés,
2. `AM4_16_Soft`: lágy LLR megbízhatósági súlyozású interferencia-kioltás,
3. `AM4_16_Bidir`: kétirányú (oda-vissza) SIC hullám a peremhatások csökkentésére.

#figure(
  image("Plot_to_TDK/turbo4-16_doga/Osszehasonlitas_Turbo_16.png", width: 84%),
  caption: [A variációk szórása és a szinkron viszonya: aszinkron minden mátrixra optimálisabb],
)

A mérési sorozat legfontosabb globális konklúziója: *22 vizsgált mátrix esetén mindig valamelyik AM4-16 eljárás bizonyult a legjobbnak, és a szinkron 16-QAM referencia csak 1 esetben bizonyult jobbnak*. 

Ugyanakkor az AM4-16 architektúra *rendkívül magas diverzitást és kifejezett mátrixfüggőséget mutat*. Míg az AM2-4 esetén a működés egyértelmű volt, addig a 16-QAM demodulációnál nincs egyeduralkodó „legjobb” algoritmus: feltételezhetően a paritásmátrix belső struktúrájától, a QPP interleaver paramétereitől és a kódhossztól függ, hogy éppen melyik variáció adja a minimális bithibát.

#grid(
  columns: (1fr, 1fr), // Két egyenlő szélességű oszlop
  gutter: 1.2em,       // Távolság a két kép között vízszintesen
  figure(
    image("feher_hatter/turbo_16_plot/Grafikon_N300_K96.png", width: 100%),
    caption: text(size: 10pt)[$N = 300, K_"info" = 96$],
  ),
  figure(
    image("feher_hatter/turbo_16_plot/Grafikon_N228_K72.png", width: 100%),
    caption: text(size: 10pt)[$N = 228, K_"info" = 72$],
  ),
  figure(
    image("feher_hatter/turbo_16_plot/Grafikon_N180_K56.png", width: 100%),
    caption: text(size: 10pt)[$N = 180, K_"info" = 56$],
  ),
  figure(
    image("feher_hatter/turbo_16_plot/Grafikon_N156_K48.png", width: 100%),
    caption: text(size: 10pt)[$N = 156, K_"info" = 48$],
  ),
)

Kezdetben még kizárólag a normál aszinkron  demodulációval (`AM4_16`) dolgoztunk. Van olyan mátrixelrendezés, ahol továbbra is ez lett a leghatékonyabb.

Bizonyos mátrixoknál a szigorú Gray-kódolású szuperpozíció (`AM4_16_Gray`) éri el a legkorábbi letörést. Ezeknél a kódoknál a szomszédos konstellációpontok közötti 1 bites Hamming-távolság elegendő védelmet nyújt a durva bitek számára, így a kemény döntésű SIC pontosan működik.

Más mátrixstruktúrák esetén a lágy döntésű kioltás (`AM4_16_Soft`) bizonyul a leghatékonyabbnak. Amikor a paritásmátrix Tanner-gráfjában jelen lévő hurkok bizonytalanabb LLR értékeket eredményeznek, a kemény visszakódolás hibás szimbólumot vonna ki. A Soft algoritmus megbízhatósági faktorral skálázza a kivonandó jelet, ami megvédi a lánc következő tagjait a hibalavinától.

Egy további mátrixcsoportnál a kétirányú feldolgozás (`AM4_16_Bidir`) hozza a legjobb eredményt. Mivel a lánc mindkét peremén tiszta 4-QAM horgony található, a visszafelé futó dekódolási hullám képes feloldani azokat a hibacsomókat, amelyekben az egyirányú SIC elakadt volna.

A vizsgálatok rávilágítottak arra is, hogy az eljárások érzékenysége nagy: előfordul olyan mátrix, ahol egy kevésbé illeszkedő aszinkron változat gyengébben teljesít, mint a szinkron 16-QAM referencia, miközben az optimális aszinkron variáció ugyanazon a mátrixon magabiztosan megveri a szinkront. Ez bizonyítja, hogy magasabb modulációs rendeknél adaptív vagy mátrix-specifikus algoritmusválasztásra van szükség a maximális teljesítmény eléréséhez.

// =====================================================================
//  IRODALOMJEGYZÉK
// =====================================================================
#bibliography("refs.bib", title: "Irodalomjegyzék", style: "ieee")