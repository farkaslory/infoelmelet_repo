
#let cim = "Átfedéses szimbólum moduláció és soros interferencia-kioltás vizsgálata korszerű csatornakódok esetén"
#let szerzok = ("Szabó Lajos Dániel",)
#let konzulensek = ("Dr. Farkas Lóránt Ernő",)
#let egyetem = "Budapesti Műszaki és Gazdaságtudományi Egyetem"
#let kar = "Villamosmérnöki és Informatikai Kar" 
#let ev = "2026"

// ---------- Általános beállítások ----------
#set document(title: cim, author: szerzok)
#set page(paper: "a4", margin: (x: 2.5cm, y: 2.5cm))
#set text(lang: "hu", size: 12pt)
#set par(justify: true, leading: 0.8em, first-line-indent: 1.25em)
#set heading(numbering: "1.1.")
#set math.equation(numbering: "(1)")
#show heading: set block(above: 1.6em, below: 1em)
#set figure(numbering: "1.")
#show figure.caption: it => context [
  #it.counter.display(it.numbering) #lower(it.supplement): #it.body
]

// hivatkozási forma: @címke → „2. fejezet”, „1.2. alfejezet”, „3. ábra”, „(4)”
#show ref: it => {
  let el = it.element
  if el == none { return it }
  if el.func() == heading {
    context {
      let n = numbering(el.numbering, ..counter(heading).at(el.location()))
      link(el.location(), [#n #if el.level == 1 [fejezet] else [alfejezet]])
    }
  } else if el.func() == math.equation {
    context link(el.location(),
      numbering(el.numbering, ..counter(math.equation).at(el.location())))
  } else if el.func() == figure {
    context link(el.location(),
      [#numbering(el.numbering, ..el.counter.at(el.location())) #lower(el.supplement)])
  } else { it }
}

#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(2em)
  text(size: 20pt, it)
  v(1em)
}

// =====================================================================
//  CÍMLAP
// =====================================================================
#page(numbering: none)[
  #set align(center)
  #set par(first-line-indent: 0pt)
  #image("BME_logo_transparent_0.png", width: 40%)   
  #text(size: 14pt, weight: "bold", egyetem) \
  #text(size: 13pt, kar) \

  #v(1fr)
  #text(size: 14pt, smallcaps[Tudományos Diákköri Konferencia])
  #v(1em)
  #text(size: 22pt, weight: "bold", cim)
  #v(1fr)

  #grid(
    columns: (1fr, 1fr),
    align: (left, right),
    [*Készítették:* \ #szerzok.join(linebreak())],
    [*Konzulens:* \ #konzulensek.join(linebreak())],
  )
  #v(2em)
  Budapest, #ev
]

// =====================================================================
//  ÖSSZEFOGLALÓ
// =====================================================================
#set page(numbering: none)
#heading(numbering: none, outlined: false)[Absztrakt]

A digitális hírközlő rendszerek adatátviteli igénye az elmúlt évtizedben ugrásszerűen növekedett. A fizikai rétegben alkalmazott hibajavító csatornakódolási eljárások – mint az ipari szabványokban rögzített Turbo és LDPC kódok – mára megközelítették az elméleti Shannon-korlátot. A további teljesítménynövelés egyik lehetséges iránya olyan - a címben - átfedéses modulációs eljárás, amely a vevőoldali interferencia-kioltásra is támaszkodik.
Hagyományos rendszerekben a csatornakódoló által előállított blokkokat egymástól függetlenül, diszjunkt szimbólumokká alakítva modulálják. Ezzel szemben az aszinkron vagy átfedéses modulációs struktúrákban az egymást követő kódszavak szimbólumai részben átfedik egymást a csatornán (például QPSK konstellációban közösen átvitt bitpárok révén). Míg a hagyományos eljárások blokkódokat hoznak létre, ez az eljárás Trellis-kódokat hoz létre, ami merőben új alapokra helyezi az ismert elméleti korlátokat [Forney, 1975]. A vevőoldalon a kódszavak szekvenciális dekódolása szükséges: az aktuális blokk sikeres dekódolása után annak interferenciáját rekonstruálni kell, majd kivonni a még detektálatlan jelekből (Successive/Decoding Interference Cancellation – SIC). Az eljárás kritikus pontja a hibaterjedés: ha a lánc elején téves dekódolás történik, a pontatlan interferencia-kivonás dominóeffektusként ronthatja a rákövetkező blokkok megbízhatóságát.

Munkánkban ezen átfedéses modulációs és szekvenciális interferencia-kioltási architektúra működését és hibajavító képességét vizsgáljuk AWGN csatorna felett. Célunk annak feltárása, hogy a láncolt szimbólumstruktúra milyen feltételek és kódparaméterek mellett képes felülmúlni a hagyományos, független blokkátvitelt és ezek milyen hátrányokkal járnak.

Ennek vizsgálatához moduláris szimulációs környezetet fejlesztettünk MATLAB nyelven, amely képes tetszőleges paritásellenőrző mátrixok (alist formátumú LDPC és txt formátumú Turbo kódok) kötegelt, párhuzamosított vizsgálatára. Megvalósítottuk az átfedéses BPSK-QPSK modulációs láncot, és kiterjesztettük 4QAM, 16QAM modulációra, és a  szekvenciális interferencia-kioltó vevőalgoritmust is mindkét esetre. Kiterjedt szimulációkat végeztünk, összehasonlítva a hagyományos szinkron és az aszinkron átfedéses rendszerek bithibaarányát (BER).



// =====================================================================
//  TARTALOMJEGYZÉK
// =====================================================================
#outline(title: "Tartalomjegyzék", indent: auto)

// =====================================================================
//  FŐ SZÖVEG
// =====================================================================
#set page(numbering: "1")
#counter(page).update(1)

= Bevezetés <ch:bevezetes>

== Motiváció <sec:motivacio>

Egy digitális hírközlő rendszer tervezésekor alapvető kérdés, hogy adott sávszélesség
és adóteljesítmény mellett mekkora sebességgel lehet megbízhatóan információt
átvinni. Az elméleti választ Shannon csatornakódolási tétele adja meg @shannon1948: a
csatorna kapacitásánál kisebb sebességgel a blokkhossz növelésével tetszőlegesen kis
hibavalószínűség érhető el. A tétel azonban csak a megfelelő kódok létezését mondja
ki; olyan kódot, amely a korlátot gyakorlatban is megvalósítható bonyolultsággal
közelíti meg, évtizedekig nem ismertek.

/// Ide jöhetne az a rész, hogy turbo kódok meg ldpc kódok ezek hogyan állnak (források is), mi a tudomány jelenlegi állása úgymond ezekkel.

// Illetve sztem ide jöhetne meglévő modulációk pl (trellis-coded modulation,bit-interleaved coded modulation) összehasonlítás rövid bemutatása

// ÉS akkor IDE kéne az átkötés információelméletről A többszörös hozzáférésű csatornák vizsgálata, és ekkor az szinkron hozzáférés jó, mi lenne ha akkor egy csatornát mesterségesen alakítanánk "többcsatornás" aszinkronra

//Szabadalom rövid bemutatása

// Bennem felmerült kérdés, hogy a "valós" asszinkronban ott ugye nincs hiba terjedés mert független a dekóderek, ugye,

== Célkitűzés <sec:celkituzes>

Munkánk célja az átfedéses modulációs és soros interferencia-kioltó architektúra
működésének és hibajavító képességének vizsgálata additív fehér Gauss-zajos (AWGN)
csatorna felett. Ennek keretében:

- megvalósítjuk az átfedéses modulációs láncot és a hozzá tartozó SIC-vevőt
  BPSK–QPSK, valamint 4-QAM–16-QAM konstellációpárra;
-kölönböző eltérő modelációs és dekódoló eljárásokat tervezzünk és valósítunk meg
- összehasonlítjuk a hagyományos, független blokkátvitelt (szinkron rendszer) és az
  átfedéses (aszinkron) rendszer bithibaarányát korszerű csatornakódok – LDPC- és
  Turbo-kódok – esetén;
- feltárjuk, milyen feltételek és kódparaméterek mellett múlja felül az átfedéses
  struktúra a független blokkátvitelt, és milyen hátrányokkal jár;
- elkülönítjük a struktúrából eredő nyereséget a hibaterjedés okozta veszteségtől;
- mindehhez moduláris, tetszőleges paritásellenőrző mátrixokkal kötegelten és
  párhuzamosítva futtatható MATLAB szimulációs környezetet fejlesztünk.

== A dolgozat felépítése <sec:felepites>

A @ch:elmelet összefoglalja a munkához szükséges elméleti hátteret: a
hírközlési lánc és az AWGN csatorna modelljét, a csatornakapacitás és a hibaexponens
fogalmát, a felhasznált modulációkat és a vizsgált
hibajavító kódokat, valamint a többfelhasználós csatornák és a szukcesszív
interferencia-kioltás alapjait. A 3. fejezet részletesen bemutatja az átfedéses
modulációs eljárást és a SIC-vevőt. A 4. fejezet a kifejlesztett szimulációs
környezetet ismerteti, az 5. fejezet a szimulációs eredményeket mutatja be és
értékeli. Végül a 6. fejezet összefoglalja munkánkat, és kitér a további
fejlesztési lehetőségekre.

// =====================================================================
//  KÖVETKEZŐ FEJEZETEK – ide kerülnek a szövegrészek
// =====================================================================
= Elméleti háttér <ch:elmelet>
// ide jön a 2. fejezet

// = Az átfedéses modulációs eljárás <ch:eljaras>
// = A szimulációs környezet <ch:szimulacio>
// = Eredmények <ch:eredmenyek>
// = Összefoglalás és kitekintés <ch:osszefoglalas>

// =====================================================================
//  IRODALOMJEGYZÉK
// =====================================================================
#bibliography("refs.bib", title: "Irodalomjegyzék", style: "ieee")
