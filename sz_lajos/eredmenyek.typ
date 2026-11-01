// =============================================================================
// Eredmények fejezet — a turbó kódos és az LDPC-s eredményrész összefésülése
// Beillesztés a fő dokumentumba:  #include "eredmenyek.typ"
// Jelölés (a dolgozat többi részével egyezően):
//   N = kódszóhossz, K = információs bitek száma, R = K/N, L = lánchossz (L = 20)
// A képek elérési útjai az eredeti két fájlból változatlanul átvéve — egységesíteni kell.
// =============================================================================

#import "@preview/cetz:0.5.2": canvas, draw
#import "@preview/cetz-plot:0.1.4": chart

= Szimulációs eredmények

A fejezetben az átfedéses (aszinkron) szimbólummoduláció bithibaarányát (BER) vetjük össze a szinkron referenciaátvitelével, két kódcsaládon: a 3GPP LTE turbó kódok paritásellenőrző mátrixos reprezentációin (23 mátrix) és különböző sebességű és hosszúságú LDPC kódokon (29 mátrix). Mindkét családnál ugyanazt a _belief propagation_ (BP) dekódert használtuk, a lánchossz $L = 20$ volt, a szinkron referencia pedig ugyanazt a modulációt használja, mint az átfedéses lánc átfedett része (QPSK, illetve 16-QAM).

Az átfedéses lánc $L$ kódszó átviteléhez a szinkron átvitelhez képest $(L+1)/L$-szer annyi szimbólumot használ, mivel a lánc két végén egy-egy félkódszót alacsonyabb rendű modulációval küldünk. Ez $L = 20$ mellett $10 log_10 (21 slash 20) approx$ 0,21 dB sebességveszteségnek felel meg. Mivel az ábrák vízszintes tengelyén a szimbólumonkénti jel-zaj viszony szerepel, ezt a különbséget az összehasonlításokban nem kompenzáltuk: legfeljebb ekkora eltolódás tudható be pusztán a sebességveszteségnek.

== BPSK/QPSK átfedéses moduláció (AM2_4)

Az AM2_4 eljárásban a kódszavak nem átfedett félkódszavát BPSK-val (1 bit/szimbólum), az átfedett részt QPSK-val (2 bit/szimbólum) moduláljuk. // TODO: hivatkozás a 3. fejezet levezetésére
A 3. fejezetben megmutattuk, hogy Gray-kódolású QPSK esetén a valós és a képzetes komponensen ülő bitek egymástól függetlenek, ezért a SIC-kivonás nem változtatja meg a következő kódszó LLR-jeit. Az átfedéses lánc bitjei így pontosan ugyanolyan csatornát látnak, mint a szinkron QPSK-ban, vagyis strukturális nyereség nem várható. Eltérést csak a lánc két végén lévő, BPSK-val modulált félkódszavak és a fenti sebességveszteség okozhat, ami $L = 20$ mellett legfeljebb néhány tized dB.

A mérések ezt igazolják. A 23 turbókód-mátrixon az AM2_4 és a szinkron QPSK görbéi a teljes vizsgált tartományban gyakorlatilag egybeesnek, az eltérés a legtöbb SNR-ponton a Monte Carlo szimuláció statisztikai ingadozásán belül marad. Az LDPC kódoknál a görbék többnyire szintén egybeesnek, néhány mátrixnál azonban mintegy 0,5 dB eltérés mutatkozik, mindkét irányban (@fig:am24-osszesitett).
// TODO: ellenőrizni, hogy az LDPC-s AM2_4/Sync futások a javított LLR-skálázással
// (NoiseVariance + a SIC utáni maradék 1/sqrt(2)-es amplitúdója) készültek-e.
// Helyes skálázással ~0,1 dB-en belüli egyezés várható; a régi kóddal mért
// eltérések (WiGig R=3/4: ~2,3 dB) skálázási műtermékek voltak.
A kódhossz növelésével mindkét eljárás vízesés-tartománya párhuzamosan meredekebbé válik, a két görbe közötti illeszkedés pedig a teljes mérettartományban megmarad.

#figure(
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1.2em,
    image("Plot_to_TDK/turbo2-4_doga/Osszesitett_Turbo_2_4.png", width: 100%),
    image("Képek/Osszesített_LDPC_2_4.png", width: 100%),
  ),
  caption: [Az AM2_4 és a szinkron QPSK összesített BER-görbéi: (bal) LTE turbó kódok, (jobb) LDPC kódok.],
) <fig:am24-osszesitett>

== 4-QAM/16-QAM átfedéses moduláció (AM4_16)

Az AM4_16 eljárásban a lánc két végén lévő, nem átfedett félkódszavakat 4-QAM-mal (2 bit/szimbólum), az átfedett részeket 16-QAM-mal (4 bit/szimbólum) moduláljuk. Az eljárás négy változatát hasonlítottuk össze a szinkron 16-QAM referenciával:
+ `AM4_16`: halmazparticionáló (SP-) kiosztás, kemény döntésű visszakódolással és kivonással;
+ `AM4_16_Gray`: teljes Gray-kódolású 16-QAM, ahol a durva bitek az MSB-k, a finom bitek az LSB-k;
+ `AM4_16_Soft`: a priori demappelés: kivonás helyett az előző kódszó finom bitjeinek extrinsic LLR-jei szolgálnak a következő kódszó durva bitjeinek a priori információjaként;
+ `AM4_16_Bidir`: kétirányú dekódolás, amely a lánc mindkét végéről indul.

A BPSK/QPSK esettel szemben itt az eredmények mátrixonként jelentősen eltérnek, és nincs olyan változat, amely minden kódra a legjobb lenne. Hogy melyik változat adja a legkisebb bithibaarányt, az a vizsgált kódtól függ (kódsebesség, kódhossz, a paritásellenőrző mátrix szerkezete); ennek pontos okait nem vizsgáltuk. Ugyanakkor a vizsgált mátrixok döntő többségénél legalább az egyik átfedéses változat elérte vagy felülmúlta a szinkron 16-QAM referenciát.

=== LTE turbó kódok

A 23 turbókód-mátrixból 21 esetben valamelyik átfedéses változat volt a legjobb (vagy döntetlen), és csak 2 esetben teljesített jobban a szinkron 16-QAM referencia (@fig:am416-turbo, @fig:eredmenyek). Az átfedéses és a szinkron demoduláció között egy adott SNR-ponton mért legnagyobb javulás 2 dB volt.

#figure(
  image("Plot_to_TDK/turbo4-16_doga/Osszehasonlitas_Turbo_16.png", width: 84%),
  caption: [Az AM4_16 változatok és a szinkron 16-QAM összesített BER-görbéi LTE turbó kódokra.],
) <fig:am416-turbo>

#let data = (
  ([SP], 6),
  ([Gray], 6),
  ([Soft], 5),
  ([SP/Bidir], 2),
  ([Szinkron], 2),
  ([Bidir], 1),
  ([Döntetlen], 1),
)

#figure(
  canvas({
    draw.set-style(barchart: (bar-width: .2))
    chart.barchart(
      size: (5, 5),
      label-key: 0,
      value-key: 1,
      x-tick-step: 1,
      data,
      x-label: [Mátrixok száma],
      y-label: [Legjobb eljárás],
    )
  }),
  caption: [A 23 turbókód-mátrix megoszlása aszerint, hogy melyik eljárás érte el a legkisebb bithibaarányt.],
) <fig:eredmenyek>

Az egyes változatok mind előfordulnak legjobbként. Az SP-kiosztású alapváltozat és a Gray-kiosztás egyaránt 6 mátrixnál, az a priori demappelés 5 mátrixnál volt a legjobb; a kétirányú dekódolás egy esetben önállóan, két esetben az SP-változattal holtversenyben nyert. Néhány jellemző példát mutat a @fig:am416-turbo-peldak.

#figure(
  grid(
    columns: (1fr, 1fr),
    gutter: 1.2em,
    [#image("feher_hatter/turbo_16_plot/Grafikon_N300_K96.png", width: 100%)
     #text(size: 10pt)[(a) $N = 300, K = 96$]],
    [#image("feher_hatter/turbo_16_plot/Grafikon_N228_K72.png", width: 100%)
     #text(size: 10pt)[(b) $N = 228, K = 72$]],
    [#image("feher_hatter/turbo_16_plot/Grafikon_N180_K56.png", width: 100%)
     #text(size: 10pt)[(c) $N = 180, K = 56$]],
    [#image("feher_hatter/turbo_16_plot/Grafikon_N156_K48.png", width: 100%)
     #text(size: 10pt)[(d) $N = 156, K = 48$]],
  ),
  caption: [Példák turbókód-mátrixokra, amelyeknél más-más AM4_16 változat a legjobb.],
) <fig:am416-turbo-peldak>

// Kihagyva (külön ábra volt egyetlen mátrixra): Plot_to_TDK/Turbo_Plot_16_All/Grafikon_N492_K160.png

=== LDPC kódok

A 29 vizsgált LDPC mátrixból 27 esetben legalább az egyik átfedéses változat elérte vagy felülmúlta a szinkron 16-QAM referenciát (93,1%), és mind a négy változatra van példa, amelyben ő a legjobb (@fig:am416-ldpc-peldak).

#figure(
  grid(
    columns: (1fr, 1fr),
    gutter: 1.2em,
    [#image("Képek/Grafikon_N100_K50.png", width: 100%)
     #text(size: 10pt)[(a) SP-kiosztás (`AM4_16`) a legjobb]],
    [#image("Képek/Grafikon_N120_K60.png", width: 100%)
     #text(size: 10pt)[(b) Gray-kiosztás a legjobb]],
    [#image("Képek/Grafikon_N336_K168.png", width: 100%)
     #text(size: 10pt)[(c) a priori demappelés (Soft) a legjobb]],
    [#image("Képek/Grafikon_N480_K240.png", width: 100%)
     #text(size: 10pt)[(d) kétirányú dekódolás (Bidir) a legjobb]],
  ),
  caption: [Példák LDPC mátrixokra, amelyeknél más-más AM4_16 változat a legjobb.],
) <fig:am416-ldpc-peldak>

Figyelemre méltó, hogy a két eset, amelyben egyik átfedéses változat sem múlta felül a szinkron modulációt, kizárólag $R approx$ 0,6 kódsebesség mellett fordult elő (@fig:ldpc-r06). Ezzel szemben $R =$ 0,5 kódsebességnél valamennyi vizsgált mátrixra javulást értünk el a szinkron átvitelhez képest (@fig:ldpc-r05).

#grid(
  columns: (1fr, 1fr),
  gutter: 1.2em,
  [#figure(
    image("Képek/Rosszabb az átfedéses/4-16/Osszehasonlitas_LDPC_R058--R066.png", width: 100%),
    caption: [A két $R approx$ 0,6 sebességű mátrix, amelyeknél a szinkron 16-QAM a jobb.],
  ) <fig:ldpc-r06>],
  [#figure(
    image("Képek/Új dolgok/Aggregált.png", width: 100%),
    caption: [Az $R =$ 0,5 sebességű LDPC mátrixokra kapott eredmények.],
  ) <fig:ldpc-r05>],
)

Az egyes változatok gyakoriságát a @fig:eredmenyek-ldpc mutatja. A turbó kódokkal ellentétben az LDPC kódoknál az a priori demappelés (Soft) bizonyult a leggyakrabban a legjobbnak (9 mátrix), ezt a kétirányú dekódolás (4), a Gray-kiosztás (3) és az SP-kiosztású alapváltozat (2) követi; egy mátrixnál az SP-változat és a kétirányú dekódolás azonos eredményt adott, 6 esetben pedig döntetlen született.
// TODO: a diagram összege 27, a szöveg 29 mátrixot említ — egyeztetni.
// TODO: tisztázni, mit jelent a „Döntetlen” (átfedéses = szinkron, vagy változatok közötti holtverseny).

#let data-ldpc = (
  ([Soft], 9),
  ([Döntetlen], 6),
  ([Bidir], 4),
  ([Gray], 3),
  ([SP], 2),
  ([Szinkron], 2),
  ([SP/Bidir], 1),
)

#figure(
  canvas({
    draw.set-style(barchart: (bar-width: .2))
    chart.barchart(
      size: (5, 5),
      label-key: 0,
      value-key: 1,
      x-tick-step: 1,
      data-ldpc,
      x-label: [Mátrixok száma],
      y-label: [Legjobb eljárás],
    )
  }),
  caption: [Az LDPC mátrixok megoszlása aszerint, hogy melyik eljárás érte el a legkisebb bithibaarányt.],
) <fig:eredmenyek-ldpc>

== Összegzés

#figure(
  table(
    columns: (1.4fr, 1fr, 1.8fr, 2fr),
    inset: 6pt,
    align: (left, center, left, left),
    fill: (x, y) => if y == 0 { rgb("#e2e8f0") } else { none },
    [*Kódcsalád*], [*Mátrixok*], [*AM2_4 vs. szinkron QPSK*], [*AM4_16: legjobb átfedéses ≥ szinkron*],
    [LTE turbó], [23], [egyezik], [21 (91,3%)],
    [LDPC], [29], [többnyire egyezik], [27 (93,1%)],
    [Összesen], [52], [—], [48 (92,3%)],
  ),
  caption: [Az eredmények összefoglalása kódcsaládonként.],
) <tab:osszegzes>
// TODO: az LDPC-s rész eredetileg 52 mátrixból 3 sikertelen esetet (94,2%) írt;
// a két részeredmény (2 + 2 sikertelen) alapján 4 adódik — egyeztetni.

A BPSK/QPSK átfedéses moduláció a várakozásoknak megfelelően a szinkron QPSK-val azonos teljesítményt nyújt: Gray-kódolású QPSK mellett a SIC-nek nincs mit kioltania, így az átfedés sem nyereséget, sem érdemi veszteséget nem okoz. A 4-QAM/16-QAM esetben viszont a vizsgált 52 mátrix döntő többségénél legalább az egyik átfedéses változat elérte vagy felülmúlta a szinkron 16-QAM referenciát, egyes esetekben egy adott SNR-ponton akár 2 dB javulással.

Megjegyezzük, hogy mátrixonként négy változat közül a legjobbat kiválasztva a Monte Carlo szimuláció szórása kissé optimista képet adhat, ezért a néhány tized dB-es különbségeket nem tekintjük szignifikánsnak. Mivel nincs egyértelműen domináns változat, magasabb modulációs rendeknél a kódhoz illesztett eljárásválasztás tűnik célravezetőnek.
