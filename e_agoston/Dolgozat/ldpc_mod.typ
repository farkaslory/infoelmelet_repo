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
Helyette az akkoriban elterjedtebb konkatenált kódok (pl. Reed–Solomon) kerültek előtérbe, ugyanis a konkatenált kódolás két egyszerűbb kód (például egy külső Reed–Solomon és egy belső konvolúciós kód) egymás utáni összekapcsolásával alacsony számítási igényű, közvetlen dekódolást biztosított.
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
  Ez jelentősen felgyorsítja a teljes kommunikációs lánc lépéseit, de főleg a dekódolást, mivel az LDPC kódoknál használt _belief propagation_ sok iterációs lépésben frissíti a valószínűségi üzeneteket.

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


=== Eredmények az LDPC kódokkal
Az átfedéses szimbólummodulálásban az LDPC kódok jó eredményeket produkáltak. Legtöbb esetben
jobb BER-rel (_Bit Error Rate_) rendelkeztek, mint az iparban használt szinkron modulációs módszer. Bár az eredmények nem mutattak meg egy egyértelműen legjobb kódot, az 52 vizsgált mátrixból – amely az LDPC paritásellenőrző mátrixok mellett a turbókódok reprezentációit is tartalmazza – mindössze 3 esetben fordult elő, hogy az átfedéses eljárás alulmúlta a szinkron modulációt. A fennmaradó esetekben az átfedéses 4QAM-16QAM változatok legalább azonos vagy kedvezőbb BER-eredményt értek el, ami 94,2%-os sikerességi arányt jelent.

Az átfedéses szimbólummodulációt 2 jelmoduláció típussal teszteltük le:
- *BPSK-QPSK*: 
  A BPSK-QPSK (Binary Phase Shift Keying - Quadrature Phase Shift Keying) módszerben - azaz AM2_4 - az üzenet
  kezdeti nem fedett felét a BPSK, míg a fedett részét QPSK moduláljuk. Ez azt jelenti, hogy a nem fedett
  részét 1 bit/szimbólum (BPSK), míg a fedett részét 2 bit/szimbólum (QPSK) logika szerint moduláljuk.
  A bemutatott eljárás teljesítménye szorosan illeszkedik a szinkron szimbólummoduláció során tapasztaltakhoz. Néhány esetben megfigyelhető, hogy egy 0,5 dB-lel jobb, vagy rosszabb az egyik a másiknál. Ezen kívül sok esetben megegyeznek az eredményeik a hibajavításban.
  A következő ábrán lehet látni, ezeket a kimeneteleket:
   #figure(
  image("Képek/Osszesített_LDPC_2_4.png", width: 60%),
  caption: [Összesített ábra az LDPC kódok hibajavításáról az átfedéses- és szinkron szimbólummoduláció használatával],
  ) <eredmeny1>
  \ 
  A következő ábrákon lehet látni példákat olyan esetekre, melyekben az egyes mátrixokra az átfedéses szimbólummoduláció jobb, rosszabb vagy azonos hibajavításra volt képes.
#figure(
  grid(
    columns: (1fr, 1fr),
    row-gutter: 14pt,
    column-gutter: 12pt,
    align: center + horizon,
    
    // Felső bal kép
    [
      #image("Képek/új 2_4/Grafikon_N200_K100.png", width: 95%)
      #v(4pt)
      Ábra (a): Példa olyan mátrixra, amellyel rosszabbul teljesít az átfedéses szimbólummoduláció.
    ],
    
    // Felső jobb kép
    [
      #image("Képek/új 2_4/Grafikon_N336_K168.png", width: 95%)
      #v(4pt)
      Ábra (b): Példa olyan mátrixra, amellyel jobban teljesít az átfedéses szimbólummoduláció.
    ],
    
    // Alsó kép középen (mindkét oszlopot átívelve)
    grid.cell(
      colspan: 2,
      [
        #image("Képek/új 2_4/Grafikon_N384_K192.png", width: 48%)
        #v(4pt)
        Ábra (c): Példa az azonos hibajavításra.
      ],
    ),
  ),
  caption: text(size: 12pt)[A három mérési elrendezés összehasonlítása.],
) <abra-fo>
\ 
- *4QAM-16QAM*:
  A 4QAM-16QAM (Quadrature Amplitude Modulation) - azaz AM4_16 - jelmodulációs folyamatban az üzenet kezdeti nem átfedett részét 4QAM moduláljuk és az átfedett üzenetrészeket 16QAM moduláljuk. Ez azt jelenti, hogy a nem átfedett üzenetfélben 2 bit/szimbólum (4QAM), míg az átfedett üzenetfélben 4 bit/szimbólum (16QAM) logikával modulálunk. A QAM annyiban különbözik még a BPSK és a QPSK modulációtól, hogy nemcsak fázis-, hanem amplitúdóváltozással is modulálja a jelet.
  Az AM4_16 fajta jelmodulációnak 4 verziójával futtattunk le szimulációkat. Diverz eredményeket kaptunk, ugyanis egyik eljárás sem bizonyult általánosan dominánsnak. Hogy melyik a legjobb az jelenlegi tudomásunk szerint kódfüggő. A letesztelt 29 LDPC paritásellenőrző mátrixból csupán 2-ben volt arra példa, hogy az átfedéses eljárások egyike sem bizonyult jobbnak. Ez meggyőző, 93,1%-os sikerességi arányt jelent a szinkron eljáráshoz viszonyítva. A következő ábrákon bemutatjuk, hogy mindegyik jelmodulációs módszer képes jobb eredményt produkálni, mint a szinkron szimbólummodulálás.
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
A fenti ábrák olyan eseteket szemléltetnek, hogy adott mátrixokra az általunk használt jelmodulációs típusok valamelyikével el lehet érni jobb- vagy lényegesen jobb hibajavítást, mint a szinkron szimbólummodulációval.
\ Figyelemre méltó megfigyelés, hogy az a két eset, amikor az átfedéses eljárások egyike sem múlta felül a szinkron modulációt, kizárólag $R approx 0,6$ kódsebesség mellett fordult elő.
 #figure(
  image("Képek/Rosszabb az átfedéses/4-16/Osszehasonlitas_LDPC_R058--R066.png", width: 60%),
  caption: [Két példa amelyben jobb a szinkron szimbólummoduláció],
  ) <eredmeny9>
  \ Ezzel szemben a következő aggregált ábra azt szemlélteti, hogy $R = 0,5$ kódsebességnél valamennyi paritásellenőrző mátrixszal nagyobb mértékű javulás érhető el, mint a szinkron szimbólummoduláció alkalmazásával.
  #figure(
  image("Képek/Új dolgok/Aggregált.png", width: 60%),
  caption: [$R=0,5$ sebességű mátrixokra kapott eredmények],
  ) <eredmeny10>.

A következő ábrán lehet látni, a egyes LDPC moduláckiós variációknak a teljesítményét. Az ábramegadja, hogy a 29 paritásellenőrző mátrixra hányszor volt a megnevezett modulációnak a legjobb hibajavítása. 

#let ldpc-sav-diagram-letisztult(
  adatok,
  max-érték: 10,
  lépés: 2,
  sáv-szélesség: 220pt,
  sáv-magasság: 14pt,
) = {
  let x-osztások = range(0, int(max-érték / lépés) + 1).map(i => i * lépés)

  align(center)[
    #block(inset: 4pt)[
      #grid(
        columns: (auto, auto),
        column-gutter: 10pt,
        row-gutter: 6pt,
        align: (right + horizon, left + horizon),

        // 1. Sávok és kategórianevek
        ..adatok.map(((cím, érték, szín)) => (
          // Bal oldali megnevezés
          text(size: 8.5pt, weight: "medium", hyphenate: false)[#cím],
          
          // Sáv és háttérbeli rácsvonalak
          box(width: sáv-szélesség + 25pt, height: sáv-magasság)[
            // Háttérbeli szaggatott rácsvonalak
            #for val in x-osztások {
              let pos = (val / max-érték) * sáv-szélesség
              place(top + left, dx: pos)[
                #line(
                  angle: 90deg,
                  length: sáv-magasság,
                  stroke: (dash: "dotted", paint: luma(225), thickness: 0.5pt)
                )
              ]
            }
            
            // Színes sáv
            #place(top + left)[
              #rect(
                width: calc.max((érték / max-érték) * sáv-szélesség, 2pt),
                height: sáv-magasság,
                fill: szín,
                radius: (right: 3pt, left: 0pt),
              )
            ]
            
            // Érték kiírása a sáv végére
            #let val-pos = (érték / max-érték) * sáv-szélesség + 5pt
            #place(top + left, dx: val-pos, dy: 1pt)[
              #text(size: 8.5pt, weight: "bold")[#érték]
            ]
          ]
        )).flatten(),

        // 2. Alsó X-tengely, szorosan illesztett notch-ok és középre zárt felirat
        [],
        box(width: sáv-szélesség)[
          #v(2pt)
          // Tengelyvonal
          #line(length: sáv-szélesség, stroke: 1pt + luma(120))
          
          // Ticks és számok közvetlenül a tengely alatt
          #box(width: sáv-szélesség, height: 13pt)[
            #for val in x-osztások {
              let pos = (val / max-érték) * sáv-szélesség
              place(top + left, dx: pos - 10pt)[
                #box(width: 20pt)[
                  #align(center)[
                    #box(width: 1pt, height: 3pt, fill: luma(120))
                    #v(0pt)
                    #text(size: 7.5pt, fill: luma(100))[#val]
                  ]
                ]
              ]
            }
          ]
          
          #v(1pt)
          // "Darabszám" felirat pontosan a 0..10 tengelyközépre zárva
          #align(center)[
            #text(size: 8.5pt, weight: "bold", fill: luma(80))[Darabszám]
          ]
        ]
      )
    ]
  ]
}

// Használat az LDPC mérési adatokkal:
#figure(
  ldpc-sav-diagram-letisztult((
    ("Soft", 9, rgb("#2b5c8f")),
    ("Döntetlen", 6, rgb("#8d99ae")),
    ("Bidir", 4, rgb("#e07a5f")),
    ("Gray", 3, rgb("#3a86c8")),
    ("AM4_16", 2, rgb("#52a3a5")),
    ("Szinkron", 2, rgb("#d62828")),
    ("AM4_16/bidir", 1, rgb("#f4a261")),
  )),
  caption: [Az egyes modulációs eljárások legjobb teljesítményének gyakorisága LDPC kódok esetén.],
) <abra-ldpc-darabszam>
Az *AM4_16/Bidir* megnevezés azt takarja, hogy azokban az esetekben az AM4_16 és a Bidir modulálás azonosan jobb volt mint a szinkron szimbólummodulálás.
// -----------------------------------------------------------------------------
// Irodalomjegyzék
// -----------------------------------------------------------------------------
#bibliography("refs.bib", title: "Irodalomjegyzék", style: "ieee")
