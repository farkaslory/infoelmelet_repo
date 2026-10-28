
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
Hagyományos rendszerekben a csatornakódoló által előállított blokkokat egymástól függetlenül, diszjunkt szimbólumokká alakítva modulálják. Ezzel szemben az aszinkron vagy átfedéses modulációs struktúrákban az egymást követő kódszavak szimbólumai részben átfedik egymást a csatornán (például QPSK konstellációban közösen átvitt bitpárok révén). Míg a hagyományos eljárások blokkódokat hoznak létre, ez az eljárás Trellis-kódokat hoz létre, ami merőben új alapokra helyezi az ismert elméleti korlátokat @forney1974. A vevőoldalon a kódszavak szekvenciális dekódolása szükséges: az aktuális blokk sikeres dekódolása után annak interferenciáját rekonstruálni kell, majd kivonni a még detektálatlan jelekből (Successive/Decoding Interference Cancellation – SIC). Az eljárás kritikus pontja a hibaterjedés: ha a lánc elején téves dekódolás történik, a pontatlan interferencia-kivonás dominóeffektusként ronthatja a rákövetkező blokkok megbízhatóságát.

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
A csatornakódolás és a moduláció összekapcsolásának klasszikus módjait, a
   többszintű kódolást és a bitátszövéses kódolt modulációt a @sec:mlc
   foglalja össze.

A többszörös hozzáférésű csatornák (MAC) információelméleti vizsgálatában
természetes feltevés, hogy a felhasználók szinkronban, egymáshoz igazított
blokkokban adnak. Csiszár, Farkas és Kói azonban megmutatta, hogy ha a küldők
szándékosan, megválasztott késleltetéssel, azaz vezérelt aszinkronitással
adnak, a hibaexponens nagyobb lehet a szinkron átvitelre ismert legjobb
értéknél @csiszar2021. Az eredmény hátterét Farkas a trellis-kódok felől
vizsgálta, és megmutatta, hogy a vezérelt aszinkron kódolás a Trellis-kódoknak egy gyakorlati realizációja. @farkas2020.

Ezek az eredmények több felhasználóra és a kódszavak együttes dekódolására
vonatkoznak, ami a gyakorlatban nehezen valósítható meg. Munkánk alapötlete,
hogy a jelenséget egyetlen felhasználóra ültetjük át, mégpedig úgy, hogy ugyanazon adó egymást
követő kódszavait egymáshoz képest eltolva, átfedéssel moduláljuk, mintha egy
aszinkron MAC különböző felhasználói lennének. A vevőben a kódszavakat nem
együttesen, hanem egymás után dekódoljuk, és a már dekódolt kódszó hatását
kivonjuk a vett jelből (soros interferencia-kioltással, SIC). Ez teszi lehetővé
a gyakorlati megvalósítást.

== A dolgozat felépítése <sec:felepites>

A @ch:elmelet röviden összefoglalja a munkához szükséges elméleti hátteret: a
hírközlési lánc és az AWGN csatorna modelljét, a felhasznált modulációkat és a
bitenkénti LLR-számítást, a vizsgált hibajavító kódokat, a csatornakapacitás és
a hibaexponens fogalmát, valamint az aszinkron többszörös hozzáférésű csatorna
és a szukcesszív interferencia-kioltás alapjait végül a többszintű kódolást. A @ch:eljaras részletesen bemutatja az átfedéses
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
//CN komplex normál oda írni
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
  //redundáns szerkezetét át kell gondolni
A 16-QAM jel így két 4-QAM jel szuperpozíciója: egy nagy amplitúdójú durva
és egy kis amplitúdójú finom rész összege. A címkézés lényege, hogy a finom
rész hozzájárulása mindig $plus.minus 1\/sqrt(10)$, függetlenül a durva bittől.
Ha tehát a finom bitek ismertek, a hatásuk kivonható a vett jelből, és egy
tisztán durva 4-QAM jel marad, amelyben a durva bitek döntési távolsága
megkétszereződik. A QPSK is felírható két BPSK jel összegeként, ott azonban a két
bit egymásra merőleges tengelyen ül, így az egyik ismerete a másik döntési
távolságán nem változtat. A tisztítás ezért csak a 16-QAM-nál ad nyereséget, a
BPSK–QPSK változatnál nem (@sec:bpsk-qpsk). Erre a tulajdonságra épül az
átfedéses moduláció (@ch:eljaras).

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
maximuma a megengedett bemeneti eloszlások közül. AWGN-csatornán a bemenetet
átlagteljesítmény-korlát köti, enélkül ugyanis a jel felskálázásával $I(X; Y)$
tetszőlegesen nagy lehetne:
$ C = max_(p(x) : EE[|X|^2] <= E_s) I(X; Y). $ <eq:kapacitas_def>
Szemléletesen ez a csatornán egy szimbólummal megbízhatóan átvihető információ
maximuma. Az @eq:awgn komplex AWGN-csatornán a maximumot a körszimmetrikus
komplex Gauss-eloszlású bemenet, $X tilde cal(C N)(0, E_s)$ adja, értéke
@cover2006
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
ahol $E(R) > 0$ a hibaexponens @csiszar2021 @gallager1965. Nagyobb hibaexponens mellett
ugyanaz a hibavalószínűség rövidebb kódszavakkal is elérhető. Ezért van
gyakorlati jelentősége annak, ha egy átviteli struktúra a hibaexponenst
javítja.

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
kapacitástartomány  *A* és *B* sarokpontjai  (@fig:mac) egyfelhasználós dekódolókkal is
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
    előbb $X_1$-et dekódoljuk; a köztük lévő szakasz idő-osztással vagy sebesség-sztással @rimoldi1996.],
) <fig:mac>

A fenti eredmények, azt feltételezik, hogy a felhasználók szinkronban, azonos
blokkhatárokkal adnak. Aszinkron esetben a felhasználók kódszavai egymáshoz
képest el vannak tolva, így az egyik felhasználó egy kódszava a másik
felhasználó két egymást követő kódszavával fed át. Farkas és Kói általános
keretet adott az aszinkron MAC különböző késleltetési feltevéseinek
leírására, és több esetben meghatározta a kapacitástartományt @farkas2014.
Csiszár, Farkas és Kói a hibaexponenst vizsgálta, és megmutatta, hogy ha a
késleltetést a küldők szándékosan választják meg (vezérelt aszinkronitás),
a hibaexponens nagyobb lehet a szinkron átvitelre ismert legjobb értéknél
@csiszar2021. 
Ezek az eredmények a kódszavak együttes dekódolását feltételezik, ami a
láncolt szerkezet miatt a gyakorlatban nem valósítható meg. Munkánkban
ehelyett SIC-et alkalmazunk: a láncot az egyik végéről kezdve kódszavanként
dekódoljuk, és minden dekódolt kódszó hatását levonjuk a vett jelből. Ez
egyfelhasználós dekódolókkal megvalósítható, ára viszont a hibaterjedés: ha
egy kódszót tévesen dekódolunk, a hibás kivonás a lánc következő kódszavainak
dekódolását is rontja. Vizsgálatunk egyik központi kérdése, hogy a vezérelt
aszinkronitás előnye ilyen, gyakorlatban is megvalósítható vevő mellett
mennyiben marad meg.
//TODO átfogalmazás, hogy ne hasonlítson annyira a bevezetésre
== Többszintű kódolás és többlépcsős dekódolás <sec:mlc>

A kódolás és a moduláció összekapcsolásának egyik klasszikus módja a többszintű
kódolás (MLC) @imai1977. Egy $2^m$ pontú konstelláció címkéjének $m$ bitjét
(szintjét) külön bináris kódok védik: a $t$-edik szimbólum $i$-edik címkebitje az
$i$-edik szint kódszavának $t$-edik bitje. A vevő a szinteket egymás után
dekódolja, mindig a már dekódolt szintek ismeretében (többlépcsős dekódolás, MSD).
A kölcsönös információ láncszabálya szerint
$ I(X; Y) = sum_(i = 1)^m I(B_i; Y | B_1, dots, B_(i - 1)), $ <eq:kapacitasszabaly>
így ha az $i$-edik szint kódjának rátája a jobb oldal $i$-edik tagja, az MLC/MSD
egyenletes bemenet mellett eléri a konstelláció kölcsönös információját
(kapacitásszabály) @wachsmann1999. A címkézés az összeget nem, csak annak a
szintek közötti megoszlását befolyásolja.

MSD-hez a természetes címkézés a halmazparticionálás @ungerboeck1982: a már
dekódolt szintek a konstellációt olyan részhalmazokra bontják, amelyeken belül a
pontok távolsága nő, így a későbbi szintek megbízhatóbbak. A többszintű kód
minimális távolsága a szintek kódjainak és a részhalmazoknak a távolságából
számolható, a többlépcsős dekódolás pedig a teljes kód maximum-likelihood
dekódolásánál jóval kisebb bonyolultsággal jó teljesítményt ad @calderbank1989.
Az MSD ára a hibaterjedés: ha egy szint dekódolása hibás, a következő szintek
rossz feltétel mellett dekódolódnak @wachsmann1999.

Ha a szinteket nem egymás után, hanem egymástól függetlenül, a többi bitre
marginalizálva dekódoljuk, csak $sum_i I(B_i; Y) <= I(X; Y)$ érhető el; a
különbség Gray-címkézéssel kicsi @wachsmann1999. Erre épül a bitátszövéses kódolt
moduláció (BICM), amely egyetlen kódot használ minden bithez @caire1998. Abotabl és Nosratinia szerint a többszintű kódolás többszörös hozzáférésű
csatornaként is értelmezhető: mivel a szinteket egymástól függetlenül kódoljuk,
úgy viselkednek, mint egy MAC különálló felhasználói @abotabl2014. Ebben a
megközelítésben a többlépcsős dekódolás a MAC kapacitástartományának egyik
sarokpontját valósítja meg, vagyis éppen a SIC-nek felel meg (@sec:mac).
// = Az átfedéses modulációs eljárás <ch:eljaras>
// =====================================================================
//  3. FEJEZET – Az átfedéses modulációs eljárás

// =====================================================================


#let abrahely(szoveg) = rect(
  width: 100%, height: 5.5cm, radius: 3pt,
  stroke: (paint: luma(160), thickness: 0.6pt, dash: "dashed"),
  align(center + horizon, text(size: 9pt, fill: luma(110), szoveg)),
)

= Az átfedéses modulációs eljárás <ch:eljaras>

Ebben a fejezetben bemutatjuk a vizsgált átfedéses modulációs eljárást és a hozzá
tartozó szukcesszív vevőt. Először áttekintjük a rendszer felépítését és
jelöléseit, majd egy konkrét példán lépésről lépésre végigkövetjük az adó és a vevő
működését. Ezt követően indokoljuk azokat a tervezési döntéseket, amelyek a különböző
változatokhoz vezettek, végül megvizsgáljuk az eljárás korlátait: a hibaterjedést és
azt, hogy a nyereségért cserébe mit kell feláldozni.

== Áttekintés <sec:attekintes>

A rendszer felépítése a következő (@fig:blokkvazlat). Az adó $L$ darab, egyenként $2n$
bit hosszú kódszót ($bold(c)_1, dots, bold(c)_L$) állít elő ugyanazzal a
csatornakódolóval. Minden kódszót két, $n$ bites félre bontunk:
$bold(c)_k = (bold(c)_k^((1)), bold(c)_k^((2)))$.
Az átfedéses modulátor az egymást követő kódszavakat úgy képezi le, hogy a $k$-adik
kódszó második fele és a $(k+1)$-edik kódszó első fele *ugyanazokon* a szimbólumokon
osztozik. A vevő a láncot az egyik végéről kezdve kódszavanként dekódolja, és minden
dekódolt kódszó hozzájárulását eltávolítja a vett jelből.

#figure(
  {
    set text(size: 9pt)
    let doboz(t, szin: luma(245)) = box(
      inset: (x: 6pt, y: 5pt), radius: 3pt, fill: szin,
      stroke: luma(150) + 0.6pt, align(center, t))
    let nyil = text(size: 12pt, fill: luma(90), sym.arrow.r)
    grid(
      columns: 9, column-gutter: 4pt, row-gutter: 10pt, align: horizon,
      doboz[Adat-\ bitek], nyil, doboz[Csatorna-\ kódoló], nyil,
      doboz(szin: rgb("#dbe8f8"))[Átfedéses\ modulátor], nyil,
      doboz[AWGN-\ csatorna], nyil, doboz(szin: rgb("#dbe8f8"))[SIC-\ vevő],
    )
    v(4pt)
    grid(
      columns: 9, column-gutter: 4pt, align: horizon,
      doboz[Demoduláció\ (LLR)], nyil, doboz[Csatorna-\ dekóder], nyil,
      doboz[Újra-\ kódolás], nyil, doboz[Rekonstrukció,\ kivonás], nyil,
      doboz[következő\ kódszó],
    )
  },
  caption: [A rendszer blokkvázlata (felül) és a SIC-vevő egy lépése (alul).],
) <fig:blokkvazlat>

Az eljárás az aszinkron többszörös hozzáférésű csatorna (@sec:mac) egyfelhasználós
megfelelője. Ha a páratlan sorszámú kódszavakat az első, a
párosakat a második „felhasználónak” tekintjük, mindkét felhasználó egymás után,
 küldi a kódszavait, a második felhasználó kódszavai azonban valamennyi (jelemzően $n/2$)
 eltolással kezdődnek. Minden kódszó így a másik felhasználó két
egymást követő kódszavával fed át – pontosan úgy, mint az aszinkron MAC-modellben.
A lényeges különbség, hogy a vevő nem együttesen, hanem szukcesszíven dekódol.

== Az eljárás lépésről lépésre <sec:lepesrol>

Az eljárást a 4-QAM–16-QAM változaton, az általunk választott bitkiosztással mutatjuk
be; a kiosztás választásának okait később fejtjük ki (@sec:sajat-kiosztas).
// Eddigi esetekben (szinkron) a bitek ugyanaból a kódszóból jöttek, míg nálunk a két egymás követőből
//MLC-hez való különbség, hogy a kódszó egyik fele más szonten van mint a másik, és az egyik felét használjuk a másik kitalálásához
=== Az adó <sec:ado>

Jelölje $beta(c) = 1 - 2c$ a bit $plus.minus 1$ értékre képezését. A 16-QAM
konstellációt két 4-QAM réteg szuperpozíciójaként írjuk fel. Egy szimbólum valós
és képzetes tengelyén egy-egy *durva* ($d$) és egy-egy *finom* ($f$) bit ül:
$ x = 1 / sqrt(10) [(2 beta(d_R) + beta(f_R)) + j (2 beta(d_I) + beta(f_I))]. $ <eq:16qam-konst>
A durva bitek kiválasztják a konstelláció negyedét („dobozát”), a finom bitek a
dobozon belüli pontot.

#figure(
  table(
    columns: 5, align: center, stroke: none,
    table.hline(stroke: 0.6pt),
    table.header([szint (tengelyenként)], [$-3$], [$-1$], [$1$], [$3$]),
    table.hline(stroke: 0.4pt),
    [saját kiosztás $(d, f)$], [11], [10], [01], [00],
    [Gray-16-QAM $(d, f)$], [10], [11], [01], [00],
    table.hline(stroke: 0.6pt),
  ),
  caption: [A tengelyenkénti bitkiosztás. A saját kiosztásban minden dobozban azonos
    a finom bit mintája, a Gray-kiosztásban a szomszédos dobozok tükrözöttek.],
) <tab:kiosztas>

#figure(
  {
    // Saját kiosztás tengelyenként: szint = 2 s(d) + s(f), s(b) = 1 - 2b
    let u = 0.82cm                     // 1 egység = 1/sqrt(10)
    let ox = 4.4cm
    let oy = 4.3cm
    let P(x, y) = (ox + x * u, oy - y * u)
    let s(b) = 1 - 2 * b
    let vonal(p, q, st) = place(top + left, line(start: p, end: q, stroke: st))
    let cimke(p, body, dx: 0pt, dy: 0pt, meret: 8pt) = place(top + left,
      dx: p.at(0) - 1.5cm + dx, dy: p.at(1) + dy,
      box(width: 3cm, align(center, text(size: meret, body))))
    let nyil(p, irany) = {
      let (x, y) = p
      let pts = if irany == "x" { ((x, y - 3pt), (x + 7pt, y), (x, y + 3pt)) }
                else { ((x - 3pt, y), (x, y - 7pt), (x + 3pt, y)) }
      place(top + left, polygon(fill: luma(60), ..pts))
    }
    box(width: 8.8cm, height: 8.7cm, {
      // dobozok (durva bitek)
      for (dR, dI) in ((0, 0), (1, 0), (0, 1), (1, 1)) {
        let (sx, sy) = (s(dR), s(dI))
        let x0 = calc.min(sx * 0.4, sx * 3.6)
        let y1 = calc.max(sy * 0.4, sy * 3.6)
        let p = P(x0, y1)
        place(top + left, dx: p.at(0), dy: p.at(1),
          rect(width: 3.2 * u, height: 3.2 * u, radius: 4pt,
            fill: rgb("#d6e6f9"), stroke: rgb("#2a78d6") + 0.6pt))
        cimke(P(sx * 2, sy * 3.6), [$d = #dR#dI$],
          dy: if sy > 0 { -0.48cm } else { 0.08cm }, meret: 8.5pt)
      }
      // tengelyek = a durva bitek döntési határai
      vonal(P(-4.3, 0), P(4.3, 0), luma(60) + 0.7pt)
      vonal(P(0, -4.3), P(0, 4.3), luma(60) + 0.7pt)
      nyil(P(4.3, 0), "x"); nyil(P(0, 4.3), "y")
      cimke(P(4.3, 0), [Re], dx: 0.45cm, dy: -0.22cm, meret: 9pt)
      cimke(P(0, 4.3), [Im], dy: -0.62cm, meret: 9pt)
      for v in (-3, -1, 1, 3) {
        vonal(P(v, -0.12), P(v, 0.12), luma(60) + 0.6pt)
      }
      // pontok + finom bitek
      for dR in (0, 1) { for fR in (0, 1) { for dI in (0, 1) { for fI in (0, 1) {
        let p = P(2 * s(dR) + s(fR), 2 * s(dI) + s(fI))
        place(top + left, dx: p.at(0) - 2.6pt, dy: p.at(1) - 2.6pt,
          circle(radius: 2.6pt, fill: luma(25)))
        cimke(p, text(fill: luma(40))[#fR#fI], dy: 0.1cm, meret: 7.5pt)
      }}}}
    })
  },
  caption: [A saját kiosztású 16-QAM konstelláció. A durva bitek a negyedet, a finom
    bitek a negyeden belüli pontot választják ki.],
) <fig:konstellacio>

A kódszavakat úgy rendeljük a rétegekhez, hogy a $k$-adik kódszó második fele a
finom, a $(k+1)$-edik kódszó első fele a durva bitekbe kerüljön.
Egy átfedő blokk $n/2$ szimbólumból áll: mindkét kódszófél $n$ bitje szimbólumonként kettesével kerül átvitelre (a $k$-adik kódszóé a finom, a $(k+1)$-ediké a durva rétegben).
. A lánc két végén nincs átfedő kódszó; itt a ritkább, egységnyi
energiájú 4-QAM modulációt használjuk. A teljes adott sorozat tehát $L + 1$ blokkból áll
(@fig:idovonal):
$ bold(x)_0 = q(bold(c)_1^((1))), quad
  bold(x)_k = cal(M)(bold(c)_(k+1)^((1)), bold(c)_k^((2))) space (1 <= k <= L - 1), quad
  bold(x)_L = q(bold(c)_L^((2))), $ <eq:lanc>
ahol $q(dot)$ a 4-QAM leképezés, $cal(M)(d, f)$ pedig a @eq:16qam-konst szerinti
16-QAM leképezés az első argumentum durva, a második finom bitjeivel.

#figure(
  {
    set text(size: 8.5pt)
    let L = 4
    let durva = rgb("#d6e6f9")
    let finom = rgb("#fbdccc")
    let ritka = luma(232)
    let cella(t, szin) = box(width: 100%, inset: 4pt, radius: 2pt, fill: szin,
      stroke: luma(160) + 0.5pt, align(center, t))
    let sorok = ()
    sorok.push([])
    for b in range(L + 1) { sorok.push(align(center)[#b. blokk]) }
    for k in range(1, L + 1) {
      sorok.push(align(right)[$bold(c)_#k$])
      for b in range(L + 1) {
        if b == k - 1 {
          sorok.push(if k == 1 { cella([4-QAM], ritka) } else { cella([durva], durva) })
        } else if b == k {
          sorok.push(if k == L { cella([4-QAM], ritka) } else { cella([finom], finom) })
        } else { sorok.push([]) }
      }
    }
    sorok.push(align(right)[_adott_])
    for b in range(L + 1) {
      sorok.push(align(center, if b == 0 or b == L [4-QAM] else [16-QAM]))
    }
    grid(columns: (auto,) + (1fr,) * (L + 1), column-gutter: 3pt, row-gutter: 4pt,
      align: horizon, ..sorok)
  },
  caption: [Az átfedéses lánc felépítése $L = 4$ kódszóra. Minden kódszó két blokkon
    halad át: az elsőben a durva, a másodikban a finom réteget adja; a lánc két végén
    ritkább (4-QAM) modulációt használunk.],
) <fig:idovonal>
/// ne legyen rés a dobozok között
=== A vevő <sec:vevo>

A vett blokk $bold(y)_k = bold(x)_k + bold(w)_k$, $bold(w)_k tilde.op cal(C N)(0, N_0)$
(@fig:szoras). A vevő a lánc elejéről indul; a lépéseket algoritmusba foglaltuk (@alg:sic).
Az algoritmusban szereplő LLR-képletek levezetése később következik
// TODO(@sec:llr-finom).

#figure(
  image("abrak/vett_szoras.png", width: 60%),
  caption: [A vett szimbólumok. A lánc két végének 4-QAM blokkjai és a belső
    16-QAM blokkok együtt jelennek meg.],
) <fig:szoras>
#figure(
  kind: "algoritmus", supplement: [algoritmus],
  block(width: 100%, inset: 10pt, radius: 3pt, stroke: luma(150) + 0.6pt, {
    set align(left)
    set text(size: 10pt)
    set enum(numbering: "1.")
    [*Bemenet:* $bold(y)_0, dots, bold(y)_L$, $N_0$. #h(1fr) *Kimenet:* $hat(bold(c))_1, dots, hat(bold(c))_L$]
    v(2pt)
    enum(
      [$k = 1$: az első fél LLR-jei a $bold(y)_0$ 4-QAM blokkból.],
      [A $k$-adik kódszó második felének LLR-jei @eq:llr-finom a $bold(y)_k$ blokk *finom*
        bitjeiből, ismeretlen durva réteg mellett,  szerint;
        $k = L$ esetén a $bold(y)_L$ 4-QAM blokkból.],
      //@eq:llr-finom ezeket majd később használom csak az arész még nincs kész 
      [Dekódolás: $hat(bold(c))_k$; ha $k = L$, vége.],
      [Újrakódolás és rekonstrukció: a finom réteg becsült hozzájárulása
        $hat(bold(x))_k^"finom" = (beta(hat(f)_R) + j beta(hat(f)_I)) \/ sqrt(10)$.],
      [Tisztítás: $tilde(bold(y))_k = bold(y)_k - hat(bold(x))_k^"finom"$.
        Helyes becslés esetén $tilde(bold(y))_k$ egy $2 \/ sqrt(10)$ amplitúdójú
        4-QAM jel.],
      [A $(k+1)$-edik kódszó első felének LLR-jei  @eq:llr-durva a tisztított blokkból
        a  szerint; $k <- k + 1$, vissza a 2. lépésre.],
        //
    )
    v(2pt)
    text(size: 9pt, fill: luma(70))[A megvalósításban a tisztított blokkot
      $sqrt(5) \/ 2$-vel egységnyi energiájú 4-QAM-má skálázzuk; ekkor a zajvariancia
      $5 N_0 \/ 4$-re nő, az LLR változatlan.]
  }),
  caption: [Szukcesszív dekódolás az átfedéses láncon.],
) <alg:sic>

#figure(
  grid(columns: 3, image("abrak/sic_vett.png"), image("abrak/sic_rekonstr.png"), image("abrak/sic_tisztitott.png")),
  caption:[Egy SIC-lépés a konstellációs síkon: a vett 16-QAM blokk (balra), a
  rekonstruált finom réteg kivonása, amely minden pontot a doboza középpontjába tol
  (középen), és a tisztított blokk, amelyben a durva bitek egy ritkább, 4-QAM jellegű
  konstellációban jelennek meg (jobbra).],
) <fig:sic-lepes>

== Tervezési döntések és indoklásuk <sec:dontesek>

=== A BPSK–QPSK változat korlátja <sec:bpsk-qpsk>

A BPSK–QPSK átfedéses modulációban a két egymást követő kódszó bitjei a
QPSK-szimbólum két egymásra merőleges tengelyére kerülnek. Mivel az AWGN-zaj valós
és képzetes része független, a vett jel valós része csak az egyik, képzetes része
csak a másik kódszó bitjéről hordoz információt. A két kódszó tehát valójában két
egymástól független csatornán halad. Ebből következik, hogy az egyik kódszó
ismerete – vagyis a SIC tisztító lépése – nem javít a másik kódszó bitjeinek
megbízhatóságán, és hibás tisztítás esetén sem ront rajta. A belső kódszavak így
pontosan ugyanolyan feltételek mellett dekódolódnak, mint a szinkron QPSK-átvitelben.
A mért előny kizárólag a lánc két végének ritkább, nagyobb bitenergiájú
modulációjából ered.

A 4-QAM–16-QAM változatban ezzel szemben a durva és a finom bit ugyanazon a
tengelyen osztozik (ld. @eq:16qam-konst), így a tisztítás valódi információt ad.
Hogy ebből mekkora nyereség lesz, az a bitkiosztáson múlik (@sec:sajat-kiosztas).

/// sebességet lehet ezzel állítani anékül, hogy a konstellációt vagy a kódolót dekódolót változtatnánk
=== A saját bitkiosztás <sec:sajat-kiosztas>  

A 16-QAM konstelláción a négy bitet sokféleképpen oszthatjuk el a két kódszó között.
Két kiosztást hasonlítunk össze (@tab:kiosztas): a Gray-16-QAM-ot, amelyben a durva
bit az MSB, a finom bit az LSB, és a saját kiosztásunkat, amelyben minden doboz
azonos címkézésű. 
A két kiosztás (@tab:kiosztas) tengelyenként egyetlen helyen tér el: a szint a
saját kiosztásnál $2 beta(d) + beta(f)$, a Gray-kiosztásnál
$beta(d) (2 + beta(f))$ . Mindkettőnek van
előnye, de a lánc két különböző pontján.

*A Gray-kiosztás előnye: egy szimbólumhiba egy bithiba.* A Gray-kiosztásban a
szomszédos szintek ($-3 <-> -1 <-> 1 <-> 3$) címkéi pontosan egy bitben térnek el.
Nagy jel-zaj viszony esetében, a szimbólumhibák szinte mindig a legközelebbi
szomszédba esnek, így egy szimbólumhiba egyetlen bithibát okoz. A saját kiosztásnál
a $-1 <-> 1$ átmenet (a durva döntési határ) a $10 <-> 01$ címkék között vezet, vagyis
*két* bithibát okoz; tengelyenként átlagosan $(1 + 2 + 1) \/ 3 = 4 \/ 3$ bithiba esik
egy szomszédos szimbólumhibára. A Gray-kiosztás ezért ott jobb, ahol a teljes
16-QAM szimbólumról kell dönteni – a SIC-láncban a tisztítás előtti, „zavart”
félben.

*A saját kiosztás előnye: a tisztítás után állandó a távolság.* A finom réteg
ismeretében a durva bitről két pont között kell dönteni. A saját kiosztásnál ez
mindig a $plus.minus 2$ szintpár, a Gray-kiosztásnál viszont a finom bittől
függően a $plus.minus 1$ (belső) vagy a $plus.minus 3$ (külső) pár. A döntési határtól
mért távolság tehát
$ "saját:" quad 2, quad quad "Gray:" quad 1 "vagy" 3 quad (1 \/ sqrt(10) "egységben"). $ <eq:tavolsag-tisztitas>
Az átlag mindkét esetben $2$, a hibavalószínűség azonban nem a távolság, hanem a
konvex $Q(dot)$ függvény átlaga. $sigma^2 = N_0 \/ 2$ zajvariancia mellett
$ P_d^"saját" = Q(2 / (sqrt(10) sigma)), quad
  P_d^"Gray" = 1 / 2 [Q(1 / (sqrt(10) sigma)) + Q(3 / (sqrt(10) sigma))]
  >= P_d^"saját", $ <eq:jensen-q>
ahol az egyenlőtlenség a Jensen-egyenlőtlenségből következik. Nagy jel-zaj viszony
mellett a Gray-kiosztás hibáját a belső pontok tagja uralja, saját kiosztás tehát a tisztított félben jobb.

=== A tisztítás: kemény és lágy <sec:tisztitas>

A szukcesszív vevő kulcslépése a tisztítás: a $k$-adik kódszó dekódolása után a finom
réteg hozzájárulását eltávolítjuk, hogy a $(k+1)$-edik kódszó durva bitjei
megbízhatóbbak legyenek. Két irányban módosíthatjuk az alapeljárást: a bitkiosztással
(Gray vagy saját, @tab:kiosztas) és a tisztítás módjával (kemény vagy lágy). Az
alábbiakban megmutatjuk, mit jelent a kettő, és milyen előnyökkel, hátrányokkal jár.

*A finom bitek LLR-je.* <sec:llr-finom> A tisztítás előtt a finom bitekről úgy kell lágy becslést
adni, hogy a durva réteg még ismeretlen. Tengelyenként
$u = (2 beta(d) + beta(f)) \/ sqrt(10) + w_u$, $w_u tilde.op cal(N)(0, N_0 \/ 2)$, és a
durva bitet a két lehetséges értékére marginalizálva a saját kiosztásnál
$ L(f | u) = ln (e^(-(u - 3\/sqrt(10))^2 \/ N_0) + e^(-(u + 1\/sqrt(10))^2 \/ N_0))
                / (e^(-(u - 1\/sqrt(10))^2 \/ N_0) + e^(-(u + 3\/sqrt(10))^2 \/ N_0)). $ <eq:llr-finom>
(A Gray-kiosztásnál a számlálóban a $plus.minus 3$, a nevezőben a $plus.minus 1$ szintek
állnak.)
*Kemény tisztítás, saját kiosztás.* A dekódolt kódszót újrakódoljuk, és a becsült
finom réteget kivonjuk:
$ tilde(u) = u - beta(hat(f)) / sqrt(10), quad
  L(d | tilde(u)) = 8 / (sqrt(10) N_0) tilde(u). $ <eq:llr-durva>
Helyes $hat(f)$ esetén a durva bit egy kétszeres léptékű 4-QAM-ban jelenik meg, ez a
saját kiosztás távolságnyeresége (@sec:tisztitas). Hibás $hat(f)$ esetén viszont a
pont a durva döntési határra kerülhet, és a durva bitről nem marad információ, ez a
hibaterjedés forrása, amelyet a @sec:hibaterjedes részletez.

*Kemény tisztítás, Gray-kiosztás.* A Gray-kiosztásnál a szint
$beta(d) (2 + beta(f)) \/ sqrt(10)$, vagyis a finom réteg hozzájárulása a durva
bittől is függ; kivonni ezért nem lehet. A finom bit ismerete viszont megmondja a
durva bithez tartozó pont *távolságát* a döntési határtól, így a tisztítás itt
feltételes demodulációt jelent:
$ L(d | u, hat(f)) = (4 (2 + beta(hat(f)))) / (sqrt(10) N_0) u. $ <eq:llr-gray>
Mivel $2 + beta(hat(f)) > 0$, az LLR előjele mindig $u$ előjele: *a durva bit
döntési határa nem függ a finom bittől*. Egy hibás $hat(f)$ így csak az LLR
nagyságát rontja el (a belső pontokat háromszor túl biztosnak, a külsőket háromszor
túl bizonytalannak mondja), a döntést nem. A Gray-kiosztás tehát eleve robusztus a
hibaterjedéssel szemben – cserébe a legrosszabb (belső) pontok távolsága sem nő, így
a nyeresége is kicsi.

*Lágy tisztítás.* A kemény tisztítás akkor is teljes súllyal vonja ki a becsült
finom réteget, ha a dekóder bizonytalan volt. A lágy tisztítás @wang1999 ehelyett
nem módosítja a vett jelet: a dekóder finom bitekre adott információját a priori
valószínűségként használja fel a következő kódszó durva bitjeinek demodulációjában.
Tengelyenként
$ L(d | u) = ln (sum_(f) P(f) thin p(u | d = 0, f)) / (sum_(f) P(f) thin p(u | d = 1, f)), $ <eq:lagy-prior>
ahol $P(f)$ a finom bit a priori valószínűsége, amelyet a dekóder *extrinsic*
LLR-jéből ($Lambda_f^"e"$) kapunk.

A dekóder egy finom bitre a csatorna-LLR-t ($L_"cs" (f)$, @eq:llr-finom) kapja
bemenetként, kimenetként pedig az a posteriori LLR-t ($Lambda_f$) adja. Jelölje $u$
a finom bit saját megfigyelését, $r$ pedig a dekóder által felhasznált összes többi
megfigyelést. Rögzített $f$ mellett $u$ független $r$-től, így a Bayes-tétel szerint
$P(f | u, r) prop p(u | f) thin P(f | r)$, és az a posteriori LLR két tagra bomlik:
$ Lambda_f = ln P(f = 0 | u, r) / P(f = 1 | u, r)
  = underbrace(ln p(u | f = 0) / p(u | f = 1), L_"cs" (f))
  + underbrace(ln P(f = 0 | r) / P(f = 1 | r), Lambda_f^"e"). $ <eq:extrinsic>
Az extrinsic LLR tehát a finom bitről a saját megfigyelése nélkül rendelkezésre álló
információ; BP-dekódolásnál ez a paritásellenőrzésekből érkező üzenetek összege.
A következő kódszó demodulátora ugyanazt a vett blokkot használja fel újra, így ha a
teljes $Lambda_f$-et adnánk át priorként, a vett jel finom bitre vonatkozó
információját kétszer vennénk figyelembe, és a kapott LLR túl magabiztos lenne.
Ezért csak az extrinsic részt, $Lambda_f^"e" = Lambda_f - L_"cs" (f)$-et használjuk.
A priori valószínűséggé az LLR definíciójából alakítjuk:
$Lambda_f^"e" = ln P(f = 0) \/ P(f = 1)$ és $P(f = 0) + P(f = 1) = 1$ miatt
$ P(f = 0) = e^(Lambda_f^"e") / (1 + e^(Lambda_f^"e")) = 1 / (1 + e^(-Lambda_f^"e")),
  quad P(f = 1) = 1 / (1 + e^(Lambda_f^"e")). $ <eq:prior-valoszinuseg>

Biztos döntésnél ($|Lambda_f^"e"| >> 1$) az @eq:lagy-prior a kemény tisztítással
egyezik, bizonytalan bitnél ($Lambda_f^"e" approx 0$) pedig a tisztítás nélküli,
marginalizált LLR-re esik vissza – így egy bizonytalan finom bit nem tolja a döntési
határra a durva bitet. A vevőben nincs szükség újrakódolásra, a dekódernek viszont a
teljes kódszóra lágy kimenetet kell adnia. Hibaterjedés továbbra is előfordulhat, ha
a BP-dekóder sikertelen dekódolásnál magabiztosan hibás LLR-eket ad.

*Gray és lágy tisztítás együtt.* Az @eq:lagy-prior bármely kiosztásra érvényes,
így a Gray-kiosztással is használható. Nagy javulás azonban nem várható tőle, mert a
Gray-kiosztás döntési határa eleve független a finom bittől – a lágy tisztítás ott
csak az LLR-ek nagyságát pontosítja.

*Összefoglalva:* a saját kiosztás nagyobb nyereséget ígér, de kemény tisztítással
érzékeny a hibaterjedésre; a lágy tisztítás pontosan ezt a gyengeségét kezeli. A
Gray-kiosztás robusztus, de kevés nyereséggel. A gyakorlatban ezért a saját kiosztás
és a lágy tisztítás együttese a legígéretesebb.
// TODO: a szimulációs eredményekkel (5. fejezet) összevetni.

*A kapacitás szintjén nincs különbség.* A kölcsönös információ láncszabálya bármely
valószínűségi változókra érvényes, így egy tengely durva és finom bitjére is:
$ I(X; Y) = I(D, F; Y) = I(F; Y) + I(D; Y | F). $ <eq:lanc-16qam>
A bal oldal a konstelláció kölcsönös információja, amely nem függ a címkézéstől, és
minden olyan rendszer számára elvi felső korlát, amely ezt a konstellációt
használja – szinkron és aszinkron rendszerre egyaránt. A különbség abban van, hogy
melyik rendszer tudja ezt a határt elérni. Az átfedéses láncban a két réteg
különböző kódszavakhoz tartozik, és a szukcesszív vevő sorrendben dekódolja őket,
így a második tag valóban feltételes alakban, az első réteg ismeretében valósul meg:
ideális kódokkal a lánc a kiosztástól függetlenül eléri $I(X; Y)$-t. A szinkron
rendszer bitenkénti dekódolással csak a bitek feltétel nélküli kölcsönös
információinak összegét, $sum_i I(B_i; Y) <= I(X; Y)$-t éri el; Gray-kiosztással ez a
határt szinte eléri (@tab:mi; 2 bit/szimbólum rátánál a különbség 0,16 dB). Mindez összhangban van azzal,
hogy az aszinkron többszörös hozzáférésű csatorna kapacitástartománya korlátos
késleltetés mellett megegyezik a szinkronéval @cover1981 @farkas2014: az
aszinkronitás a kapacitáson nem változtat.

A két kiosztás között csak az információ megoszlásában van különbség (@tab:mi): a
saját kiosztás a finom (zavart) szerepben kevesebb, a durva (tisztított) szerepben
több információt hordoz, mint a Gray-kiosztás.
*Különbség a többszintű kódolástól.* A többszintű kódolásban (MLC) @imai1977 egy
szimbólum két szintje két különböző komponenskódhoz tartozik, ezért a rátákat
szintenként külön kell megválasztani @wachsmann1999; a @tab:mi szerint 9 dB-en a
saját kiosztásnál a finom szint $0,98$, a durva $1,96$ bit/szimbólum rátát enged.
Az átfedéses láncban ezzel szemben minden kódszó első fele a durva, második fele a
finom szinten halad át, így minden kódszó egyenlő arányban látja mindkét szintet.
Ideális kódra a feltétel ekkor egyetlen közös kódsebességre vonatkozik:
$ R <= (I(F; Y) + I(D; Y | F)) / 4 = I(X; Y) / 4, $ <eq:kozos-rata>
ahol $F$ és $D$ egy szimbólum két finom, illetve két durva bitje, a kölcsönös
információk pedig bit/szimbólumban értendők. Az átfedéses lánc tehát egyetlen
kóddal, szintenkénti rátatervezés nélkül valósítja meg a többlépcsős dekódolást.
#figure(
  table(
    columns: 4, align: (left, center, center, center), stroke: none,
    table.hline(stroke: 0.6pt),
    table.header([], [$E_s \/ N_0 = 6$ dB], [$9$ dB], [$12$ dB]),
    table.hline(stroke: 0.4pt),
    [saját: $I(F;Y) + I(D;Y|F)$], [0,48 + 1,72], [0,97 + 1,95], [1,58 + 2,00],
    [Gray: $I(F;Y) + I(D;Y|F)$], [0,80 + 1,40], [1,28 + 1,64], [1,72 + 1,86],
    [összeg, $I(X;Y)$ (mindkettő)], [2,20], [2,93], [3,58],
    [szinkron Gray, bitenként], [2,18], [2,93], [3,58],
    table.hline(stroke: 0.6pt),
  ),
  caption: [Szimbólumonkénti kölcsönös információ (bit/szimbólum) a két szerepben,
    16-QAM, egyenletes bemenet. Monte Carlo-becslés ($2 dot 10^6$ minta); az összeg
    a kiosztástól független, a kerekítés miatt a tagok összege legfeljebb
    $0,01$-gyel eltérhet.],
) <tab:mi>

*A nyereség a hibaexponensben jelenik meg.* Az aszinkron szerkezet előnye nem a
kapacitásban, hanem a hibaexponensben (@eq:hibaexponens) jelentkezik @csiszar2021.
Minden rendszer exponense a kapacitásnál nullára csökken, $E(C) = 0$ @gallager1965;
mivel a kapacitás a két rendszerben azonos, a vízesés-tartományban – ahol a kód
rátája közel van az adott jel-zaj viszonyhoz tartozó kapacitáshoz – lényeges
különbség nem várható. Rögzített kódrátánál a jel-zaj viszony növelésével a kapacitás
nő, a ráta egyre messzebb kerül alatta, és itt az exponensek már eltérhetnek. Nagy
jel-zaj viszony mellett a hibavalószínűséget a minimális távolság határozza meg, így
a nyereség konkrét formája a tisztított bitek nagyobb távolsága (@sec:tisztitas). A
nyereség tehát nem a kód küszöbének eltolódásában, hanem a küszöb feletti
tartományban, a bithibaarány gyorsabb csökkenésében jelentkezik. Csiszár, Farkas és
Kói eredménye együttes dekódolásra vonatkozik; hogy a szukcesszív vevővel mennyi
valósul meg belőle, azt szimulációval vizsgáljuk.

=== Kétirányú dekódolás <sec:ketiranyu>

A szabadalom szerint a dekódolás a lánc végéről is indítható. Hátulról haladva
azonban a szerepek felcserélődnek: az utolsó kódszó dekódolása után a *durva* réteg
válik ismertté, és a tisztítás a finom bitek távolságát nem növeli. Ezért a
kétirányú változatban az adó a lánc második felét tükrözve állítja elő – ott a
következő kódszó adja a finom, az aktuális a durva réteget –, így a lánc mindkét
végéről ugyanolyan feltételekkel indulhat a szukcesszív dekódolás, és a két irány a
lánc közepén találkozik.
// TODO: pontosítsd a találkozási pontot a megvalósítás szerint (melyik blokkban
// fut össze a két irány, és ott melyik kódszót dekódoljátok előbb).

A kétirányú dekódolás két előnnyel jár. A leghosszabb dekódolási lánc $L$-ről
körülbelül $L \/ 2$-re rövidül, így egy hiba legfeljebb feleannyi kódszón tud
továbbterjedni, és a két irány párhuzamosan futtatható, ami a dekódolási késleltetést
is felezi. A rátaveszteség nem változik, mert továbbra is két ritkább modulációjú
láncvég van.

== Hibaterjedés és az eljárás ára <sec:korlatok>

=== Hibaterjedés <sec:hibaterjedes>

A szukcesszív vevő azt feltételezi, hogy a tisztításhoz felhasznált kódszó helyes.
Ha a $k$-adik kódszó dekódolása hibás, a tisztított jel tengelyenként
$ tilde(u) = (2 beta(d) + beta(f) - beta(hat(f))) / sqrt(10) + w_u. $ <eq:hibas-tisztitas>
Ahol $hat(f) = f$, a tisztítás helyes. Ahol $hat(f) != f$, a kivont érték előjele
ellentétes, azaz $beta(f) - beta(hat(f)) = 2 beta(f)$, és
$ tilde(u) = (2 beta(d) + 2 beta(f)) / sqrt(10) + w_u. $ <eq:hibas-tisztitas2>
Ha a finom bit előjele megegyezik a durváéval, a pont a döntési határtól távolabb
kerül ($plus.minus 4 \/ sqrt(10)$), és a döntés helyes marad; ha ellentétes, a pont
pontosan a döntési határra ($0$-ra) esik, és a durva bitről nem marad információ.
Mivel a két eset egyformán valószínű, egy hibásan becsült finom bit átlagosan minden
második esetben „törli” a következő kódszó megfelelő durva bitjét (kemény döntésnél
ez átlagosan 25% bithibának felel meg). Egy sikertelen LDPC-dekódolás nem néhány,
hanem a kódszó jelentős részét érintő bithibát okoz, így a következő kódszó első fele
nagyrészt törlődik, annak dekódolása is nagy valószínűséggel sikertelen lesz, és a
hiba dominóként végigfuthat a láncon.

A hibaterjedést a lágy tisztítás mérsékli (@sec:tisztitas): a bizonytalan finom
biteket nem vonja ki, így ezek nem okoznak törlést; magabiztosan hibás
dekóderkimenet esetén azonban a hiba így is továbbterjedhet. A BPSK–QPSK változatban
ilyen hibaterjedés nincs, mert ott a tisztítás nem befolyásolja az LLR-t
(@sec:bpsk-qpsk).

=== Az eljárás ára <sec:ar>

// --- egyelőre csak vázlat ---
// * Rátaveszteség: L kódszóhoz L+1 blokk tartozik, így a spektrális hatékonyság
//   a szinkron 16-QAM 4R bit/szimbólumához képest 4R·L/(L+1)
//   (azonos Es/N0 mellett Eb/N0-ban 10·log10((L+1)/L) dB többlet; L = 20: 0,21 dB).
//   Képlet: $ eta_"AAC" = 4 R L / (L + 1) $
// * Késleltetés: a kódszavak csak sorban dekódolhatók, a k-adikhoz meg kell várni
//   az előző k-1 dekódolását (kétirányúval ~ felezhető).
// * Bonyolultság: minden kódszót a dekódolás után újra kell kódolni és modulálni.
// * Hibaterjedés: hosszabb lánc -> kisebb rátaveszteség, de nagyobb kockázat;
//   a lánchossz megválasztása kompromisszum (a szabadalom is említi).

// =====================================================================


// = A szimulációs környezet <ch:szimulacio>
// = Eredmények <ch:eredmenyek>

// = Összefoglalás és kitekintés <ch:osszefoglalas>


// =====================================================================
//  IRODALOMJEGYZÉK
// =====================================================================
#bibliography("refs.bib", title: "Irodalomjegyzék", style: "ieee")
