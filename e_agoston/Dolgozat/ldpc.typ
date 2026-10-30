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
Az átfedéses szimbólummodulálásban az LDPC kódok jó eredményeket produkáltak. Legtöbb esetben
jobb BER-el (_Bit Error Rate_) rendelkezetek, mint az iparban használt szinkron mondulációs módszer. Bár az eredmények nem mutattak meg egy egyértelműen legjobb kódot, a 39 db letesztelt mátrixból (ebbe nem csak az LDPC paritásellenőrző mátrixok-, hanem a turbókódok mátrixai is benne vannak.) csupán 2 esetben nem volt az 4QAM-16QAM átfedésesnek egy olyan változata, ami rosszabb lenne mint a szinkron eredményei, ez egy $tilde$95%-os előnyt jelent a szinkron szimbólummodulációval szemben.

Az átfedéses szimbólummodulácót 2 jelmoduláció típussal teszteltük le:
- *BPSK-QPSK*: 
  A BPSK-QPSK (Binary Phase Shift Keying - Quadrature Phase Shift Keying) módszerben - azaz AM2_4 - az üzenet
  kezdeti nem fedett felét a BPSK, míg a fedett részét QPSK moduláljuk. Ez azt jelenti, hogy a nem fedett
  részét 1 bit/szimbólum (BPSK), míg a fedett részét 2 bit/szimbólum (QPSK) logika szerint moduláljuk.
  Az ilyen modulációval elért eredmények kiemelkedőek lettek. Az LDPC mátrixokon lefuttatott szimulációk kis részében
  tapasztaltuk azt, hogy a szinkron szimbólummodulációval kapott eredményének BER értéke
  hamarabb érte el a 0-t mint az átfedéses eredményei.
  #grid(
  columns: (1fr, 1fr), // Két egyenlő szélességű oszlop
  gutter: 1.4em,       // Távolság a két kép között vízszintesen
  figure(
  image("Képek/Jobb az átfedéses/2-4/Osszehasonlitas_LDPC_4_R058--066.png", width: 100%),
  caption: text(size: 10pt)[3 db paritás ellenőrző mátrix eredményei a szinkron QPSK és átfedéses BPSK-QPSK szimbólum modulációkra.],
  ),
  figure(
  image("Képek/Grafikon_N672_K504.png", width: 96%),
  caption: text(size: 10pt)[Egy Wigig típusú LDPC paritás mátrixra lefutatottt szinkron QPSK és átfedéses BPSK-QPSK szimbólum moduláció eredményei.],
  ),
  )
  \ Látható az 1. ábrán, hogy mindegyik letesztelt mátrix esetében a 0 hibahatárt fél- vagy több dB-el hamarabb eléri az átfedéses szimbólum moduláció.
  \ A legszebb eredményünkben, amely a 2. ábrán látható, 4 dB-el korábban elérte a 0 hibahatárt az átfedéses szimbólummoduláció:
 
  \ Egyes esetekben a szinkron szibmólum moduláció jobb eredményeket ért el mint az átfedéses, de ez az esetek kis részét jelentette, a mátrixok túlnmyomó részében jobb volt az átfedéses.
  #figure(
  image("Képek/Rosszabb az átfedéses/2-4/Osszehasonlitas_LDPC_4_R05.png", width: 60%),
  caption: [Példa arra az esetre, melyben jobb a szinkron- az átfedéses szimbólummodulációnál.],
  ) <eredmeny3>
  A 3. ábrán is lehet látni, hogy a kék színű görbére jobb az átfedéses, de a másik kettő görbe azt a példát demonstrálja, hogy a szinkron szimbólummoduláció egyes mátrixokra jobb mint az átfedéses.

- *4QAM-16QAM*:
  A 4QAM-16QAM (Quadrature Amplitude Modulation) - azaz AM4_16 - jelmodulációs folyamatban az üzenet kezdeti nem átfedett részét 4QAM moduláljuk és a átfedett üzenet részeket 16QAM moduláljuk. Ez azt jelenti, hogy a nem átfedett üzenet félben 2bit/szimbólum (4QAM), míg az átfedett üzenet félben 4bit/szimbólum (16QAM) logikával kódolunk. A QAM annyiban külömbözik még a BPSK és a QPSK modulációtól, hogy nem csak fázisban-, hanem amplitúdó változással is modulálja a jelet.
  Az AM4_16 fajta jelmodulációnak 4 verziójával futtatunk le szimulációkat. Ezek egyenként nem érik el azt a
  kitűnő teljesítmény javulást, mint a AM2_4-nél láttunk. Diverz eredményeket kaptunk, mert egyik eljárás sem volt sokkal megbízhatóbb mint a többi. Hogy melyik a legjobb az jelenlegi tudomásunk szerint kód függő. A következő ábrákon bemutatjuk, hogy mindegyik jelmodulációs módszer képes jobb eredményt produkálni mint a szinkron szimbólum modulálás. A letesztelt 29 LDPC paritásellenörző mátrixból csupán 2-ben volt arra példa, hogy semelyik modulációs folyamatunk nem volt jobb a szinkron szimbólummodulációnál. Ez egy $tilde$93.1%-os arányt jelent, ami igen magas.
    #grid(
  columns: (1fr, 1fr), // Két egyenlő szélességű oszlop
  gutter: 1.2em,       // Távolság a két kép között vízszintesen
  figure(
    image("Képek/Grafikon_N100_K50.png", width: 100%),
    caption: text(size: 10pt)[Példa, melyben az *AM4_16* a legjobb],
  ),
  figure(
    image("Képek/Grafikon_N120_K60.png", width: 100%),
    caption: text(size: 10pt)[Példa, melyben a *Gray* a legjobb],
  ),
   figure(
    image("Képek/Grafikon_N336_K168.png", width: 100%),
    caption: text(size: 10pt)[Példa, melyben a *Soft* a legjobb],
  ),
   figure(
    image("Képek/Grafikon_N480_K240.png", width: 100%),
    caption: text(size: 10pt)[Példa, melyben a *Bidir* a legjobb],
  ),
)
A fenti ábrákon lehet látni példákat arra, hogy adott mátrixokra az általunk használt jelmodulációs típusok valamelyikével el lehet érni jobb- vagy lényegesebben jobb hibajavítást, mint a szinkron szimbólummodulációval.
\ Egy érdekes észrevételünk az volt, hogy abban a 2 mátrixban, amelyben az átfedéses szimbólummodulációs folyatamok egyike sem volt jobb a szinkronnál, csak $R approx 0.6$ sebességek esetén fordultak elő.
 #figure(
  image("Képek/Rosszabb az átfedéses/4-16/Osszehasonlitas_LDPC_R058--R066.png", width: 60%),
  caption: [Két példa amelyben jobb a szinkron szimbólummoduláció],
  ) <eredmeny4>
  \ Ezzel szemben a következő aggregált ábra azt szemlélteti, hogy $R = 0.5$ kódsebességnél valamennyi paritásellenőrző mátrixszal nagyobb mértékű javulás érhető el, mint a szinkron szimbólummoduláció alkalmazásával.
  #figure(
  image("Képek/Osszehasonlitas_LDPC_R05.png", width: 60%),
  caption: [$R=0.5$ sebességű mátrixokra kapott eredmények],
  ) <eredmeny5>
// -----------------------------------------------------------------------------
// Irodalomjegyzék
// -----------------------------------------------------------------------------
#bibliography("refs.bib", title: "Irodalomjegyzék", style: "ieee")
