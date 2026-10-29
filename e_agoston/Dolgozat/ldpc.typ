// =============================================================================
// Az LDPC kódok rövid története, működése, használata a mindennapokban
// és eredményei az átfedéses szimbólummodulációban
//
// Fordítás:   typst compile ldpc.typ
// Szükséges:  refs.bib (ugyanabban a mappában, mint ez a fájl)
// =============================================================================


// -----------------------------------------------------------------------------
// Dokumentum- és oldalbeállítások
// -----------------------------------------------------------------------------
#set document(title: "Az LDPC kódok rövid története, működése, használata és eredményei")
#set page(paper: "a4", margin: 2.5cm, numbering: "1")
#set text(
  lang: "hu",
  font: "New Computer Modern",
  size: 11pt
)
#set par(justify: true, leading: 0.7em, spacing: 1.1em)

// Címsorok
#set heading(numbering: none)
#show heading: set block(above: 1.4em, below: 0.9em)
#show heading.where(level: 1): set align(center)
#show heading.where(level: 1): set text(size: 17pt)
#show heading.where(level: 2): set text(size: 13pt)

// Az irodalomjegyzék címe is második szintű cím legyen
#show bibliography: set heading(level: 2)


// -----------------------------------------------------------------------------
// Cím
// -----------------------------------------------------------------------------
= Az LDPC kódok rövid története, működése, használata a mindennapokban és eredményei az átfedéses szimbólummodulációban


// -----------------------------------------------------------------------------
// 1. Történelem
// -----------------------------------------------------------------------------
== Történelem

Az LDPC (azaz _Low Density Parity Check_, vagyis alacsony sűrűségű paritásellenőrzés) kódokat Robert G. Gallager 1960-ban írt doktori disszertációjából ismerhetjük @gallager1960 @gallager1962.
Bár Gallager kódjának forradalminak kellett volna lennie, az akkori számítógépek hardvere egyszerűen nem bírta volna el az LDPC kódokhoz Gallager által feltételezett iteratív dekódolást.
Az akkori lyukkártyás és vákuumcsöves számítógépek egyszerűen túlhevültek volna, vagy túl sok időbe telt volna a számításuk.
Helyette az akkoriban elterjedtebb konkatenált kódok (pl. Reed–Solomon) kerültek előtérbe , ugyanis a konkatenált kódolás két egyszerűbb kód (például egy külső Reed–Solomon és egy belső konvolúciós kód) egymás utáni összekapcsolásával alacsony számítási igényű, közvetlen dekódolást biztosított.
Ezzel szemben a hatvanas évek számítógépeiből még hiányzott az a feldolgozási sebesség és memória, amely az iteratív dekódolás többlépéses, teljes gráfon zajló valószínűségi üzenetváltásaihoz kellett.

Ezután húsz évig nem történt előrelépés az LDPC kódok használatában, csak néhány lelkes kutató hivatkozott Gallager munkájára.
Ez a csend akkor szakadt meg, amikor Michael Tanner az 1981-ben kiadott híres munkájában ("A recursive approach to low complexity codes") bemutatta a róla elnevezett Tanner-gráfokat @tanner1981.
Ezekkel a páros (bipartit) gráfokkal szemléletes, vizuális és matematikai struktúrát adott a paritásellenőrző mátrixok leírására, ami a későbbi években kulcsfontosságúvá vált az LDPC kódok iteratív, üzenetátadó (_message-passing_) dekódolásának megértésében és megvalósításában.

Az LDPC kódokat a kilencvenes évek közepén fedezték fel újra.
Ebben az időben az 1993-ban megjelent turbó kódok voltak elterjedtek @berrou1993, mivel a Shannon által kiszámolt kódsebességi határt @shannon1948 sokkal jobban megközelítették, mint a korábban használt kódok.
Az újrafelfedezést David J. C. MacKay és Radford M. Neal kezdeményezte, akik 1996-ban megmutatták, hogy a Gallager által a hatvanas években bemutatott kódok iteratív dekódolással (pl. _belief propagation_) megközelítik a Shannon-korlátot @mackay1996 @mackay1999.

A turbó kódok felfedezése és az LDPC kódok újrafelfedezése egy kutatási hullámot indított el, amelyből végül az LDPC kódok kerültek ki nyertesen.
Erre több ok is volt:

- *Teljesítmény.* Az LDPC kódok magasabb kódrátával és lényegesen alacsonyabb hibapadlóval (_error floor_) rendelkeztek, mint a turbó kódok, amelyeket végül inkább az alacsonyabb kódrátájú alkalmazásokban használtak.
- *Szabadalmak.* Bár az LDPC kódok is szabadalmaztatva voltak, ezek a szabadalmak már évtizedek óta lejártak, ami az iparnak vonzóbb volt a turbó kódokhoz képest, amelyeket még 2013-ig erős és drága szabadalmak védtek.


// -----------------------------------------------------------------------------
// 2. Működés
// -----------------------------------------------------------------------------
== Az LDPC kódok működése

Az LDPC kódok a lineáris blokkkódok (_linear block codes_) családjához tartoznak, amelyek az iparban a leggyakrabban használt kódok közé sorolhatók @lin2004.
Lényegük, hogy egy adott adathalmazt $k$ bites üzenetblokkokra osztanak fel, és mindegyikhez redundáns paritásbiteket csatolva egy hosszabb, $n$ bites kódszót képeznek.

A kódolást egy $k times n$ méretű generátormátrix ($G$) végzi ($c = m dot G$), a kapott üzenet érvényességét pedig egy paritásellenőrző mátrixszal ($H$) ellenőrzik ($H dot c^T = 0$).
A generátormátrix által előállított kódszót a vevő oldalán a paritásellenőrző $H$ mátrixszal szorozzák meg, és ha az átvitel során nem sérült, a szorzás nullvektort eredményez.
Természetesen ez általában nem teljesül, ilyenkor egy $n - k$ hosszúságú vektort, úgynevezett szindrómát kapunk, amelyből ki lehet számítani, hogy mely bitek károsodtak az üzenetből.

A kódokat az $(n, k, d)$ hármassal jellemzik, ahol $R = k/n$ a kódsebesség, a $d$ (minimális Hamming-távolság) pedig közvetlenül meghatározza, hogy hány bites átviteli hibát képes a kód észlelni vagy javítani.

Ami megkülönbözteti az LDPC kódokat a többi lineáris blokkkódtól, az a nevükből is érthető módon a ritkás (_sparse_) paritásellenőrző mátrix.
Ez ritkás Tanner-gráfot is jelent, aminek több előnye is van:

- *Közelítés a Shannon-limithez.* Az LDPC kódok nagy blokkméretek esetén megközelítik a Shannon-limitet.
  Sűrű mátrixok esetén a dekódolás számítási igénye a kódhossz négyzetével vagy akár exponenciálisan is nőhet.
  Ezzel szemben a ritkás mátrixokban a lokális számítások végig egyszerűek maradnak, így a számításigény a kódhosszal csupán lineárisan nő.
  Ez teszi lehetővé, hogy a gyakorlatban is megközelítsük a csatornakapacitás elméleti határát (Shannon-limit) @mackay1999 @richardson2001.
- *Párhuzamosíthatóság.* A párhuzamosíthatóság lehetséges más lineáris blokkkódoknál, vagy a konvolúciós építőelemekből álló turbó kódoknál is, az LDPC kódok ritkás mátrixai azonban tömeges párhuzamosíthatóságot tesznek lehetővé.
  Ez jelentősen felgyorsítja a teljes kommunikációs lánc lépéseit, de főleg a dekódolást, mivel az LDPC kódoknál használt _belief propagation_ sok iterációs lépésben frissíti a valószínűségi üzeneteket .

Az iparban az LDPC kódok legelterjedtebb formája a szabálytalan (_irreguláris_) LDPC kód.
Míg a szabályos LDPC kódoknál a paritásellenőrző mátrix soraiban és oszlopaiban az egyesek száma szigorúan állandó, a szabálytalan LDPC kódokban a sor- és oszlopösszegek (a csomópontok fokszámai) változóak, ami lehetővé teszi a fontosabb adatbitek erősebb védelmét és az iteratív dekódolás során a hatékonyabb üzenetátadást.
A hatékony hibapropagáció és a gyors konvergencia érdekében a szabálytalan LDPC kódoknál a paritásellenőrző csomópontoknak alacsonyabb, míg a kulcsfontosságú üzenetbiteknek magasabb az élszámuk (fokszámuk), így a több kapcsolattal rendelkező bitcsomópontok erősebb védelmet kapnak az üzenetfrissítések során.

Az iteratív dekódolás során a vevő lágy döntéses (_soft decision_) információval, úgynevezett _log-likelihood ratio_ (LLR) értékekkel dolgozik, amelyek a csatorna feszültségszintjei alapján megbecsülik, hogy mekkora eséllyel 0 vagy 1 az adott bit értéke.


// -----------------------------------------------------------------------------
// 3. Használat a mindennapokban
// -----------------------------------------------------------------------------
== Használatuk a mindennapokban

Manapság az LDPC kódokat szinte minden korszerű adatátviteli eljárásban megtalálhatjuk, mivel sok olyan tulajdonsággal rendelkeznek, amelyek alkalmassá teszik őket az adatátvitel széles körű használatára.

Nagy áteresztőképességük és kiváló hibajavításuk miatt használják őket például az 5G vagy a modern Wi-Fi (pl. Wi-Fi 6/7) szabványaiban.
Műholdas kommunikációban is használják, ahol alacsony kódsebességgel ($R = 1/4$ vagy $1/2$) magas hibajavíthatóság érhető el, ami elengedhetetlen a hosszú és zajos csatornákon átküldött üzeneteknél.
A mai, rézkábeles 10 Gb/s-os Ethernet (10GBASE-T) hálózatok is az LDPC kódoknak köszönhetik stabilitásukat és gyorsaságukat.

Az LDPC kódok legérdekesebb mindennapi felhasználása a flash memóriákban van.
Az SSD-k NAND flash memóriája az idővel és a használattal folyamatosan degradálódik, és ezzel a rajta tárolt információ is károsodna.
Az LDPC kódok a háttértárakban és egyéb memóriákban fellépő bithibákat a már jól ismert iteratív eljárásokkal (pl. _belief propagation_) javítják ki.
Ezekkel matematikailag visszakövetkeztethető, hogy milyen adat lehetett az adott helyen, így az eredetileg eltárolt adat még évekkel a mentése után is megmarad.


// -----------------------------------------------------------------------------
// 4. Eredmények az átfedéses szimbólummodulációban
// -----------------------------------------------------------------------------
== Eredmények az átfedéses szimbólummodulációban


=== Eredmények az LDPC kódokkal.
Az átfedéses szimbólummodulálásban az LDPC kódok jó eredményeket produkáltak. Legtöbbször
jobb BER-el (_Bit Error Rate_) rendelkezett, mint az iparban használt szinkron mondulációs módszer. Bár az eredmények nem mutattak meg egy egyértelműen legjobb kódot (pl. Bidir, Soft, Gray stb.), a 38 db letesztelt mátrixból csupán 2 esetben nem volt az átfedésesnek egy olyan változata, ami rosszabb lenne mint a szinkron eredményei.

Az átfedéses szimbólummodulácót 2 jelmoduláció típussal teszteltük le:
- *BPSK-QPSK*: 
  A BPSK-QPSK (Binary Phase Shift Keying - Quadrature Phase Shift Keying) módszerben - azaz 2_4AM - az üzenet
  kezdeti nem fedett felét a BPSK, míg a fedett részét QPSK moduláljuk. Ez azt jelenti, hogy a nem fedett
  részét 1 bit/szimbólum (BPSK), míg a fedett részét 2 bit/szimbólum (QPSK) logika szerint moduláljuk.
  Az ilyen modulációval elért eredmények igen jók lettek. Az LDPC mátrixokon lefuttatott szimulációk kis részében
  tapasztaltuk azt, hogy a szinkron szimbólummodulációval kapott eredményének BER értéke
  hamarabb érte el a 0-t mint az átfedéses eredményei.
  #figure(
  image("Képek/Jobb az átfedéses/2-4/Osszehasonlitas_LDPC_4_R058--066.png", width: 65%),
  caption: [4 db paritás ellenőrző mátrix eredményei a szinkron QPSK és átfedéses BPSK-QPSK szimbólum modulációkra.],
  ) <eredmeny1>
  \Látható az 1. ábrán, hogy mindegyik letesztelt mátrix esetében a 0 hibahatárt fél- vagy több dB-el hamarabb eléri az átfedéses szimbólum moduláció.
  \ \ A legszebb eredményünkben 4 dB-el korábban elérte a 0 hibahatárt az átfedéses szimbólummoduláció:
  #figure(
  image("Képek/Jobb az átfedéses/2-4/Grafikon_N672_K504.png", width: 65%),
  caption: [Egy Wigig típusú LDPC paritás mátrixra lefutatottt szinkron QPSK és átfedéses BPSK-QPSK szimbólum moduláció eredményei.],
  ) <eredmeny2>
  \ Volt pár eset, ahol a szinkron jobb volt mint az átfedéses, de ez az esetek kisebb részét jelentette, a mátrixok túlnmyomó részében jobb volta az átfedéses.
  #figure(
  image("Képek/Rosszabb az átfedéses/2-4/Osszehasonlitas_LDPC_4_R05.png", width: 65%),
  caption: [Példa arra az esetre, melyben jobb a szinkron- az átfedéses szimbólummodulációnál.],
  ) <eredmeny3>
  \ A 3. ábrán is lehet látni, hogy a kék színű görbére jobb az átfedéses, de a másik kettő görbe azt a példát demonstrálja, hogy a szinkron szimbólummoduláció egyes mátrixokra jobb mint az átfedéses.

- *4QAM-16QAM*:
  A 4QAM-16QAM (Quadrature Amplitude Modulation) - azaz 4_16AM - jelmodulációs folyamatban az üzenet kezdeti nem átfedett részét 4QAM moduláljuk és a átfedett üzenet részeket 16QAM moduláljuk. Ez azt jelenti, hogy hogy a nem átfedett üzenet félben 2bit/szimbólum (4QAM), míg az átfedett üzenet félben 4bit/szimbólum (16QAM) logikával kódolunk. A QAM annyiban külömbözik még a BPSK és a QPSK modulációtól, hogy nem csak fázisban-, hanem amplitúdó változással is modulálja a jelet.
  Az 4_16AM fajta jelmodulációnak 4 verziójával futtatunk le szimulációkat. Ezek egyenként nem érik el azt a
  kitűnő teljesítményt, mint a 2_4AM önmagában, de ha össze vonjuk az eredményeiket, akkor rikán van olyan 
  eset, ahol egyik se jobb mint a szinkron szimbólum modulálás. A következő bekezdésekben bemutatjuk, hogy mindegyik jelmodulációs módszer képes jobb eredményt produkálni mint a szinkron szimbólum modulálás.
  - *4_16AM*:
    Az általános 4_16AM az első változata az általunk bemutatott 4QAM-16QAM modulációnak. Következő ábrán lehet látni, hogy ennek a 
    mátrixnak az esetében jobban teljesít, mint az általános szinkron szimbólum modulálás:
    #figure(
    image("Képek/Jobb az átfedéses/4-16/Grafikon_N100_K50.png", width: 65%),
    caption: [Példa arra az esetre, amelyben a 4_16AM jobb eredményt ér el, mint a 4 bit/szimbólum logikával kódolt szinkron szimbólum modulálás],
    ) <eredmeny4> \
  - *4_16AM Bidir*:
    (A Bidir működéséről egy két mondat). A következő ábrán lehet látni, hogy a 4_16AM Bidir jobban tud teljesíteni, mint a szinkron szimbólum moduláció:
    #figure(
    image("Képek/Jobb az átfedéses/4-16/Grafikon_N480_K240.png", width: 65%),
    caption: [Példa arra az esetre, amelyben a 4_16AM Bidir jobb eredményt ér el, mint a 4 bit/szimbólum logikával kódolt szinkron szimbólum modulálás],
    ) <eredmeny5> \
  - *4_16AM Gray*:
    (A Gray működéséről egy két mondat). A következő ábrán lehet látni, hogy a 4_16AM Gray jobban tud teljesíteni, mint a szinkron szimbólum moduláció:
    #figure(
    image("Képek/Jobb az átfedéses/4-16/Grafikon_N120_K60.png", width: 65%),
    caption: [Példa arra az esetre, amelyben a 4_16AM Gray jobb eredményt ér el, mint a 4 bit/szimbólum logikával kódolt szinkron szimbólum modulálás],
    ) <eredmeny6> \
  - *4_16AM Soft*:
    (A Soft működéséről egy két mondat). A következő ábrán lehet látni, hogy a 4_16AM Soft jobban tud teljesíteni, mint a szinkron szimbólum moduláció:
    #figure(
    image("Képek/Jobb az átfedéses/4-16/Grafikon_N336_K168.png", width: 65%),
    caption: [Példa arra az esetre, amelyben a 4_16AM Soft jobb eredményt ér el, mint a 4 bit/szimbólum logikával kódolt szinkron szimbólum modulálás],
    ) <eredmeny6> \
// -----------------------------------------------------------------------------
// Irodalomjegyzék
// -----------------------------------------------------------------------------
#bibliography("refs.bib", title: "Irodalomjegyzék", style: "ieee")
