
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

A többszörös hozzáférésű csatornák (MAC) információelméleti vizsgálatában
természetes feltevés, hogy a felhasználók szinkronban, egymáshoz igazított
blokkokban adnak. Csiszár, Farkas és Kói azonban megmutatta, hogy ha a küldők
szándékosan, megválasztott késleltetéssel, azaz vezérelt aszinkronitással
adnak, a hibaexponens nagyobb lehet a szinkron átvitelre ismert legjobb
értéknél @csiszar2021. Az eredmény hátterét Farkas a trellis-kódok felől
vizsgálta, és az aszinkron MAC-ra kapott eredményekből trellis-kódok
hibaexponensét vezette le @farkas2020.

Ezek az eredmények több felhasználóra és a kódszavak együttes dekódolására
vonatkoznak, ami a gyakorlatban nehezen valósítható meg. Munkánk alapötlete,
hogy a jelenséget egyetlen felhasználóra ültetjük át, mégpedig úgy, hogy ugyanazon adó egymást
követő kódszavait egymáshoz képest eltolva, átfedéssel moduláljuk, mintha egy
aszinkron MAC különböző felhasználói lennének. A vevőben a kódszavakat nem
együttesen, hanem egymás után dekódoljuk, és a már dekódolt kódszó hatását
kivonjuk a vett jelből (soros interferencia-kioltás, SIC). Ez teszi lehetővé
a gyakorlati megvalósítást.

== A dolgozat felépítése <sec:felepites>

A @ch:elmelet röviden összefoglalja a munkához szükséges elméleti hátteret: a
hírközlési lánc és az AWGN csatorna modelljét, a felhasznált modulációkat és a
bitenkénti LLR-számítást, a vizsgált hibajavító kódokat, a csatornakapacitás és
a hibaexponens fogalmát, valamint az aszinkron többszörös hozzáférésű csatorna
és a szukcesszív interferencia-kioltás alapjait. A 3. fejezet részletesen bemutatja az átfedéses
modulációs eljárást és a SIC-vevőt. A 4. fejezet a kifejlesztett szimulációs
környezetet ismerteti, az 5. fejezet a szimulációs eredményeket mutatja be és
értékeli. Végül a 6. fejezet összefoglalja munkánkat, és kitér a további
fejlesztési lehetőségekre.

// =====================================================================
//  KÖVETKEZŐ FEJEZETEK – ide kerülnek a szövegrészek
// =====================================================================
= Elméleti háttér <ch:elmelet>

== Hírközlési lánc és AWGN csatorna <sec:awgn>

// TODO: blokkábra (kódoló -> moduláció -> AWGN -> demoduláció -> dekódoló)

A vizsgált hírközlési lánc a szokásos felépítést követi. A $k$ bites
üzenetet a csatornakódoló $n$ bites kódszóvá alakítja, a kódsebesség tehát
$R = k\/n$. A modulátor a kódszó bitjeit $m$ bites csoportokban egy
$cal(X) subset CC$ konstelláció pontjaira képezi le, $|cal(X)| = 2^m$. A
komplex alapsávi csatornát additív fehér Gauss-zajjal (AWGN) modellezzük
@cover2006:
$ y_i = x_i + z_i, quad z_i tilde cal(C N)(0, N_0), $ <eq:awgn>
ahol a $z_i$ zajminták függetlenek, a jel átlagos szimbólumenergiája pedig
$E_s = EE[|x_i|^2]$. A vevő a zajos $y_i$ mintákból bitenkénti
megbízhatósági értékeket (LLR) számol, ezekből becsli a dekódoló a küldött
üzenetet.

A jel-zaj viszonyt szimbólumonként ($E_s\/N_0$) vagy információs bitenként
($E_b\/N_0$) szokás megadni. A kettő kapcsolata
$ E_b / N_0 = 1 / (R m) dot E_s / N_0. $ <eq:ebn0>
Szimulációinkban a jelet egységnyi átlagteljesítményre normáljuk, és a zajt
$E_s\/N_0$ szerint állítjuk be. Eltérő bit/szimbólum értékű rendszerek (például
4-QAM és 16-QAM) tisztességes összevetéséhez ezért a @eq:ebn0 szerinti
átszámítás szükséges.

== Moduláció és bitenkénti LLR <sec:modulacio>

Az egyik legegyszerűbb moduláció a bináris fázisbillentyűzés (BPSK), ahol egy bitet a
$b |-> s = 1 - 2b in {plus.minus 1}$ leképezéssel viszünk át a valós tengelyen.
A QPSK (más néven 4-QAM) két egymásra merőleges BPSK jel összege:
$ x = 1 / sqrt(2) (s_I + j s_Q), $
ahol $s_I$ és $s_Q$ egy-egy bitből képzett $plus.minus 1$ érték, az
$1\/sqrt(2)$ tényező pedig az egységnyi átlagenergiát biztosítja.

A 16-QAM-ot tengelyenként két bit határozza meg. Munkánkban nem csak a szokásos
Gray-címkézést használjuk, hanem egy másik szimbólum kiosztást is. Ebben az esetben az amplitudószintet egy durva
($s_c$) és egy finom ($s_f$) bit összegeként írjuk fel:
$ l = 2 s_c + s_f in {plus.minus 1, plus.minus 3}, quad
  x = 1 / sqrt(10) (l_I + j l_Q). $ <eq:qam16>
A 16-QAM jel így két 4-QAM jel szuperpozíciója: egy nagy amplitúdójú durva
és egy kis amplitúdójú finom rész összege. A címkézés lényege, hogy a finom
rész hozzájárulása mindig $plus.minus 1\/sqrt(10)$, függetlenül a durva bittől.
Ha tehát a finom bitek ismertek, a hatásuk kivonható a vett jelből, és egy
tisztán durva 4-QAM jel marad. Ugyanez a viszony áll fenn a BPSK és a QPSK
között: a QPSK egyik tengelyét elhagyva BPSK jelet kapunk. Erre a
tulajdonságra épül a 3. fejezetben bemutatott átfedéses moduláció.

A dekódoló bemenete a kódszó bitjeire számolt log-likelihood arány (LLR).
Egyenletes a priori eloszlás mellett a szimbólum $i$-edik bitjére
$ L(b_i) = ln (P(b_i = 0 | y)) / (P(b_i = 1 | y))
  = ln (sum_(x in cal(X)_i^0) exp(-|y - x|^2 \/ N_0))
         / (sum_(x in cal(X)_i^1) exp(-|y - x|^2 \/ N_0)), $ <eq:llr>
ahol $cal(X)_i^b$ azon konstellációpontok halmaza, amelyekben az $i$-edik bit
értéke $b$. BPSK esetén ez az egyszerű $L(b) = 4 op("Re"){y} \/ N_0$ alakra
egyszerűsödik. Az LLR előjele a bit becsült értékét, abszolút értéke a
becslés megbízhatóságát adja meg.

// == Hibajavító kódok <sec:kodok>
// TODO: többiek írják – LDPC- és Turbo-kódok, BP-dekódolás

== Csatornakapacitás és hibaexponens <sec:kapacitas>

Shannon csatornakódolási tétele szerint minden csatornát jellemez egy $C$
kapacitás: $C$-nél kisebb sebességgel a blokkhossz növelésével tetszőlegesen
kis hibavalószínűség érhető el, nagyobb sebességgel viszont nem
@shannon1948. A kapacitás a bemenet és a kimenet közötti kölcsönös információ
maximuma az összes lehetséges bemeneti eloszlás közül:
$ C = max_(p(x)) I(X; Y). $ 
<eq:kapacitas_def>
Vagy másképpen a a csatornán egy szimbólummal átvihető információ
maximuma.
Az @eq:awgn komplex AWGN csatornán $E_s$ átlagos teljesítmény mellett ezt a
maximumot a Gauss-eloszlású bemenet adja, értéke @cover2006
$ C = log_2 (1 + E_s / N_0) quad "bit/szimbólum". $ <eq:kapacitas>
A gyakorlatban azonban egy véges, $2^m$ pontú konstellációból választjuk a
szimbólumokat, így egy szimbólum legfeljebb $m$ bitet hordozhat. 
A kapacitás csak azt mondja meg, milyen sebesség érhető el végtelen
blokkhossz mellett. A gyakorlatban viszont véges, néhány száz vagy ezer bites
kódszavakkal dolgozunk, ezért az is fontos, milyen gyorsan csökken a
hibavalószínűség a blokkhossz növelésével. Ezt a hibaexponens írja le: $R < C$
sebesség mellett a legjobb $n$ hosszú kódok hibavalószínűsége exponenciálisan
csökken,
$ P_e approx e^(-n E(R)), $ <eq:hibaexponens>
ahol $E(R) > 0$ a hibaexponens @csiszar2021. Nagyobb hibaexponens mellett
ugyanaz a hibavalószínűség rövidebb kódszavakkal is elérhető. Ezért van
gyakorlati jelentősége annak, ha egy átviteli struktúra a hibaexponenst
javítja.

== Aszinkron többszörös hozzáférésű csatorna és SIC <sec:mac>

== Aszinkron többszörös hozzáférésű csatorna és SIC <sec:mac>

A többszörös hozzáférésű csatornán (MAC) több adó ad egyszerre egyetlen vevőnek. Két
felhasználó esetén, $X_1$ és $X_2$ bemenettel, valamint $Y$ kimenettel, az
$(R_1, R_2)$ sebességpár akkor érhető el, ha valamely független
$p(x_1) p(x_2)$ bemeneti eloszlás mellett @cover2006
$ R_1 <= I(X_1; Y mid(|) X_2), quad
  R_2 <= I(X_2; Y mid(|) X_1), quad
  R_1 + R_2 <= I(X_1, X_2; Y). $ <eq:mac>
A teljes kapacitástartomány az így kapott tartományok uniójának konvex burka.

A kölcsönös információ láncszabálya szerint
$ I(X_1, X_2; Y) = I(X_2; Y) + I(X_1; Y mid(|) X_2). $ <eq:lancszabaly>
Ez közvetlenül egy dekódolási eljárást ad. A vevő először a második felhasználó
üzenetét dekódolja az elsőt zajnak tekintve, ami $I(X_2; Y)$ sebességig lehetséges.
Ezután a dekódolt üzenetből rekonstruált jelet levonja a vett jelből, és az első
felhasználót már interferencia nélkül, $I(X_1; Y mid(|) X_2)$ sebességgel
dekódolja. Ez a soros (szukcesszív) interferencia-kioltás (SIC), amellyel a
kapacitástartomány sarokpontjai (@fig:mac) egyfelhasználós dekódolókkal is
elérhetők @cover2006.

#figure(
  {
    // Méretezés: s = 1 bit hossza; az értékek a P1 = P2 = N = 1 Gauss-példából
    let s = 5cm
    let ox = 2.8cm          // origó x
    let oy = 7.3cm          // origó y (lefelé nő)
    let a = 0.585           // I(X1;Y) = I(X2;Y)
    let c = 1.0             // I(X1;Y|X2) = I(X2;Y|X1)
    let m = 1.35            // tengelyhossz
    let P(x, y) = (ox + x * s, oy - y * s)
    let vonal(p, q, st) = place(top + left, line(start: p, end: q, stroke: st))
    let cimke(p, body, al: center, dx: 0pt, dy: 0pt) = place(
      top + left,
      dx: p.at(0) - 3cm + dx, dy: p.at(1) + dy,
      box(width: 6cm, align(al, text(size: 9pt, body))),
    )
    let pont(p) = place(top + left, dx: p.at(0) - 2pt, dy: p.at(1) - 2pt,
      circle(radius: 2pt, fill: black))
    let nyil(p, irany) = {
      let (x, y) = p
      let pts = if irany == "x" {
        ((x, y - 3pt), (x + 7pt, y), (x, y + 3pt))
      } else {
        ((x - 3pt, y), (x, y - 7pt), (x + 3pt, y))
      }
      place(top + left, polygon(fill: black, ..pts))
    }
    let szagg = (paint: gray.darken(30%), thickness: 0.5pt, dash: "dashed")

    box(width: 12cm, height: 8.0cm, {
      // kapacitástartomány (ötszög)
      place(top + left, polygon(
        fill: rgb("#4a90d9").lighten(75%),
        stroke: rgb("#2a6fb5") + 1pt,
        P(0, 0), P(c, 0), P(c, a), P(a, c), P(0, c),
      ))
      // összegsebesség-egyenes: R1 + R2 = c + a
      vonal(P(c + a - 1.25, 1.25), P(1.25, c + a - 1.25),
        (paint: rgb("#2a6fb5"), thickness: 0.6pt, dash: "dashed"))
      // vetítővonalak
      vonal(P(a, 0), P(a, c), szagg)
      vonal(P(0, a), P(c, a), szagg)
      // tengelyek
      vonal(P(0, 0), P(m, 0), 0.8pt)
      vonal(P(0, 0), P(0, m), 0.8pt)
      nyil(P(m, 0), "x")
      nyil(P(0, m), "y")
      cimke(P(m, 0), $R_1$, dx: 0.5cm, dy: -0.25cm)
      cimke(P(0, m), $R_2$, dy: -0.75cm)
      // tengelyfeliratok
      cimke(P(a, 0), $I(X_1; Y)$, dy: 0.15cm)
      cimke(P(c, 0), $I(X_1; Y mid(|) X_2)$, dy: 0.15cm)
      cimke(P(0, a), $I(X_2; Y)$, al: right, dx: -3.15cm, dy: -0.22cm)
      cimke(P(0, c), $I(X_2; Y mid(|) X_1)$, al: right, dx: -3.15cm, dy: -0.22cm)
      // sarokpontok
      pont(P(c, a))
      pont(P(a, c))
      cimke(P(c, a), [*A*], dx: 0.3cm, dy: -0.2cm)
      cimke(P(a, c), [*B*], dx: 0.25cm, dy: -0.5cm)
      // összegkorlát felirata
      cimke(P(1.0, 0.82), $R_1 + R_2 = I(X_1, X_2; Y)$, al: left, dx: 3.1cm)
    })
  },
  caption: [Kétfelhasználós MAC kapacitástartománya (rögzített bemeneti eloszlás
    mellett). Az *A* sarokpont SIC-kel érhető el, ha előbb $X_2$-t, a *B*, ha
    előbb $X_1$-et dekódoljuk; a köztük lévő szakasz idő-megosztással.],
) <fig:mac>

A hibaexponensre vonatkozó fenti eredmények, azt feltételezik, hogy a felhasználók szinkronban, azonos
blokkhatárokkal adnak. Aszinkron esetben a felhasználók kódszavai egymáshoz
képest el vannak tolva, így az egyik felhasználó egy kódszava a másik
felhasználó két egymást követő kódszavával fed át. Farkas és Kói általános
keretet adott az aszinkron MAC különböző késleltetési feltevéseinek
leírására, és több esetben meghatározta a kapacitástartományt @farkas2014.
Csiszár, Farkas és Kói a hibaexponenst vizsgálta, és megmutatta, hogy ha a
késleltetést a küldők szándékosan választják meg (vezérelt aszinkronitás),
a hibaexponens nagyobb lehet a szinkron átvitelre ismert legjobb értéknél
@csiszar2021. Az eltolt kódszavak láncot alkotnak, ami a trellis-kódok
szerkezetével rokon. Farkas ezt a kapcsolatot kihasználva az aszinkron MAC-ra
kapott eredményekből trellis-kódok hibaexponensét vezette le @farkas2020.

Ezek az eredmények a kódszavak együttes dekódolását feltételezik, ami a
láncolt szerkezet miatt a gyakorlatban nem valósítható meg. Munkánkban
ehelyett SIC-et alkalmazunk: a láncot az egyik végéről kezdve kódszavanként
dekódoljuk, és minden dekódolt kódszó hatását levonjuk a vett jelből. Ez
egyfelhasználós dekódolókkal megvalósítható, ára viszont a hibaterjedés: ha
egy kódszót tévesen dekódolunk, a hibás kivonás a lánc következő kódszavainak
dekódolását is rontja. Vizsgálatunk egyik központi kérdése, hogy a vezérelt
aszinkronitás előnye ilyen, gyakorlatban is megvalósítható vevő mellett
mennyiben marad meg.

// = Az átfedéses modulációs eljárás <ch:eljaras>
// = A szimulációs környezet <ch:szimulacio>
// = Eredmények <ch:eredmenyek>
// = Összefoglalás és kitekintés <ch:osszefoglalas>

// =====================================================================
//  IRODALOMJEGYZÉK
// =====================================================================
#bibliography("refs.bib", title: "Irodalomjegyzék", style: "ieee")
