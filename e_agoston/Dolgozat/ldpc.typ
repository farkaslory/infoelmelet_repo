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
#set text(lang: "hu", font: ("Libertinus Serif", "Liberation Serif"), size: 11pt)
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
Helyette az akkoriban elterjedtebb konkatenált kódok (pl. Reed–Solomon) kerültek előtérbe @forney1966 @reed1960, ugyanis a konkatenált kódolás két egyszerűbb kód (például egy külső Reed–Solomon és egy belső konvolúciós kód) egymás utáni összekapcsolásával alacsony számítási igényű, közvetlen dekódolást biztosított.
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
  Ez jelentősen felgyorsítja a teljes kommunikációs lánc lépéseit, de főleg a dekódolást, mivel az LDPC kódoknál használt _belief propagation_ sok iterációs lépésben frissíti a valószínűségi üzeneteket @kschischang2001.

Az iparban az LDPC kódok legelterjedtebb formája a szabálytalan (_irreguláris_) LDPC kód.
Míg a szabályos LDPC kódoknál a paritásellenőrző mátrix soraiban és oszlopaiban az egyesek száma szigorúan állandó, a szabálytalan LDPC kódokban a sor- és oszlopösszegek (a csomópontok fokszámai) változóak, ami lehetővé teszi a fontosabb adatbitek erősebb védelmét és az iteratív dekódolás során a hatékonyabb üzenetátadást @luby2001 @richardson2001design.
A hatékony hibapropagáció és a gyors konvergencia érdekében a szabálytalan LDPC kódoknál a paritásellenőrző csomópontoknak alacsonyabb, míg a kulcsfontosságú üzenetbiteknek magasabb az élszámuk (fokszámuk), így a több kapcsolattal rendelkező bitcsomópontok erősebb védelmet kapnak az üzenetfrissítések során.

Az iteratív dekódolás során a vevő lágy döntéses (_soft decision_) információval, úgynevezett _log-likelihood ratio_ (LLR) értékekkel dolgozik, amelyek a csatorna feszültségszintjei alapján megbecsülik, hogy mekkora eséllyel 0 vagy 1 az adott bit értéke @mackay2003.


// -----------------------------------------------------------------------------
// 3. Használat a mindennapokban
// -----------------------------------------------------------------------------
== Használatuk a mindennapokban

Manapság az LDPC kódokat szinte minden korszerű adatátviteli eljárásban megtalálhatjuk, mivel sok olyan tulajdonsággal rendelkeznek, amelyek alkalmassá teszik őket az adatátvitel széles körű használatára.

Nagy áteresztőképességük és kiváló hibajavításuk miatt használják őket például az 5G @ts38212 @richardson2018 vagy a modern Wi-Fi (pl. Wi-Fi 6/7) @ieee80211ax szabványaiban.
Műholdas kommunikációban is használják, ahol alacsony kódsebességgel ($R = 1/4$ vagy $1/2$) magas hibajavíthatóság érhető el, ami elengedhetetlen a hosszú és zajos csatornákon átküldött üzeneteknél @etsi302307.
A mai, rézkábeles 10 Gb/s-os Ethernet (10GBASE-T) hálózatok is az LDPC kódoknak köszönhetik stabilitásukat és gyorsaságukat @ieee8023an.

Az LDPC kódok legérdekesebb mindennapi felhasználása a flash memóriákban van.
Az SSD-k NAND flash memóriája az idővel és a használattal folyamatosan degradálódik, és ezzel a rajta tárolt információ is károsodna.
Az LDPC kódok a háttértárakban és egyéb memóriákban fellépő bithibákat a már jól ismert iteratív eljárásokkal (pl. _belief propagation_) javítják ki @zhao2013.
Ezekkel matematikailag visszakövetkeztethető, hogy milyen adat lehetett az adott helyen, így az eredetileg eltárolt adat még évekkel a mentése után is megmarad.


// -----------------------------------------------------------------------------
// 4. Eredmények az átfedéses szimbólummodulációban
// -----------------------------------------------------------------------------
== Eredmények az átfedéses szimbólummodulációban

Az átfedéses szimbólumdemodulálásban az LDPC kódok kifejezetten jól teljesítettek.
Az iparban megismert szinkron modulációhoz képest a BER (_Bit Error Rate_) jelentősen jobb volt.
A szinkron QPSK demodulációval működő kódok területén egyenesen minden letesztelt kód jobb eredményt ért el átfedéses (aszinkron) demodulálással.
A korszerűbb QAM típusú demodulálásnál is voltak kódok, amelyekre jobb megoldás volt az átfedéses demodulálás használata.
(T. B. C.)
// TODO: kiegészíteni az eredményeket, és hivatkozást adni rájuk


// -----------------------------------------------------------------------------
// Irodalomjegyzék
// -----------------------------------------------------------------------------
#bibliography("refs.bib", title: "Irodalomjegyzék", style: "ieee")
