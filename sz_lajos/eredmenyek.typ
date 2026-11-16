// =============================================================================
// =============================================================================

#import "@preview/cetz:0.5.2": canvas, draw
#import "@preview/cetz-plot:0.1.4": chart
= Szimulációs eredmények

A fejezetben az átfedéses (aszinkron) szimbólummoduláció bithibaarányát (BER) vetjük össze a szinkron referenciaátvitelével, két kódcsaládon: a 3GPP LTE turbó kódok paritásellenőrző mátrixos reprezentációin (23 mátrix) és különböző sebességű és hosszúságú LDPC kódokon (35 mátrix). Mindkét családnál ugyanazt a _belief propagation_ (BP) dekódert használtuk, a lánchossz $L = 20$ volt, a szinkron referencia pedig ugyanazt a modulációt használja, mint az átfedéses lánc átfedett része (QPSK, illetve 16-QAM).

Az átfedéses lánc $L$ kódszó átviteléhez a szinkron átvitelhez képest $(L+1)/L$-szer annyi szimbólumot használ, mivel a lánc két végén egy-egy félkódszót alacsonyabb rendű modulációval küldünk. Ez $L = 20$ mellett $10 log_10 (21 slash 20) approx$ 0,21 dB sebességveszteségnek felel meg. Mivel az ábrák vízszintes tengelyén a szimbólumonkénti jel-zaj viszony szerepel, ezt a különbséget az összehasonlításokban nem kompenzáltuk: legfeljebb ekkora eltolódás tudható be pusztán a sebességveszteségnek.Az SNR-pontonkénti 1000 futás mellett $10^(-6)$ alatti bithibaaránynál már csak elvétve jelentkezik hiba, ezért az ennél kisebb értékek csak tájékoztató jellegűek.

== BPSK/QPSK átfedéses moduláció (AM2_4)

Az AM2_4 eljárásban a kódszavak nem átfedett félkódszavát BPSK-val (1 bit/szimbólum), az átfedett részt QPSK-val (2 bit/szimbólum) moduláljuk. // TODO: hivatkozás a 3. fejezet levezetésére
A 3. fejezetben megmutattuk, hogy Gray-kódolású QPSK esetén a valós és a képzetes komponensen ülő bitek egymástól függetlenek, ezért a SIC-kivonás nem változtatja meg a következő kódszó LLR-jeit. Az átfedéses lánc bitjei így pontosan ugyanolyan csatornát látnak, mint a szinkron QPSK-ban, vagyis strukturális nyereség nem várható. Eltérést csak a lánc két végén lévő, BPSK-val modulált félkódszavak és a fenti sebességveszteség okozhat, ami $L = 20$ mellett legfeljebb néhány tized dB.

A mérések ezt igazolják. A mátrixon az AM2_4 és a szinkron QPSK görbéi a teljes vizsgált tartományban gyakorlatilag egybeesnek, az eltérés a legtöbb SNR-ponton a szimuláció statisztikai ingadozásán belül marad. (@fig:am24-osszesitett).
A kódhossz növelésével mindkét eljárás vízesés-tartománya párhuzamosan meredekebbé válik.

#figure(
  grid(
    columns: (1fr, 1fr),
    column-gutter: 1.2em,
    image("Plot_to_TDK/Osszesített_Turbo_2_4.png", width: 100%),
    image("Plot_to_TDK/Osszesített_LDPC_2_4.png", width: 100%),
  ),
  caption: [Az AM2_4 és a szinkron QPSK összesített BER-görbéi: (bal) LTE turbó kódok, (jobb) LDPC kódok.],
) <fig:am24-osszesitett>

== 4-QAM/16-QAM átfedéses moduláció (AM4_16)

Az AM4_16 eljárásban a lánc két végén lévő, nem átfedett félkódszavakat 4-QAM-mal (2 bit/szimbólum), az átfedett részeket 16-QAM-mal (4 bit/szimbólum) moduláljuk. Az eljárás négy változatát hasonlítottuk össze a szinkron 16-QAM referenciával:
+ `AM4_16`: halmazparticionáló (SP-) kiosztás, kemény döntésű visszakódolással és kivonással;
+ `AM4_16_Gray`: teljes Gray-kódolású 16-QAM, ahol a durva bitek az MSB-k, a finom bitek az LSB-k;
+ `AM4_16_Soft`: a priori demappelés: kivonás helyett az előző kódszó finom bitjeinek extrinsic LLR-jei szolgálnak a következő kódszó durva bitjeinek a priori információjaként;
+ `AM4_16_Bidir`: kétirányú dekódolás, amely a lánc mindkét végéről indul, itt is  halmazparticionáló (SP-) kiosztás, kemény döntésű visszakódolással és kivonással .

A BPSK/QPSK esettel szemben itt az eredmények mátrixonként jelentősen eltérnek, és nincs olyan változat, amely minden kódra a legjobb lenne. Hogy melyik változat adja a legkisebb bithibaarányt, az a vizsgált kódtól függ (kódsebesség, kódhossz, a paritásellenőrző mátrix szerkezete); ennek pontos okait nem vizsgáltuk. Ugyanakkor a vizsgált mátrixok döntő többségénél legalább az egyik átfedéses változat felülmúlta a szinkron 16-QAM referenciát.

=== LTE turbó kódok

A 23 turbókód-mátrixból 20 esetben valamelyik átfedéses változat volt a legjobb, csak 2 esetben teljesített jobban a szinkron 16-QAM referencia és egy esetben volt döntetlne (@fig:am416-turbo, @fig:eredmenyek). Az átfedéses és a szinkron demoduláció között egy adott SNR-ponton mért legnagyobb javulás a szinkron érték egy tizenketede volt. Illetve voltak olyan kódok ahol a hibapadlót, ez mi esetünkben a "0 BER-t" jelentette ( ez természetesen csak a szimuláció korlátjai miatt 0 nálunk, ahogy fent említettük ez kódoktól függően valahol $10^-6$-on van a jelenlegi környezetben) 2 egész SNR-el hamarabb elértük 

#figure(
  image("Plot_to_TDK/Osszehasonlitas_Turbo_16.png", width: 84%),
  caption: [Az AM4_16 változatok és a szinkron 16-QAM összesített BER-görbéi LTE turbó kódokra.],
) <fig:am416-turbo>

#let data = (
  ([SP], 7),
  ([Gray], 7),
  ([Soft], 3),
  ([Szinkron], 2),
  ([Bidir], 3),
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

Az egyes változatok mind előfordulnak győztesként. Az SP-kiosztású alapváltozat és a Gray-kiosztás került a mezőny élére, egyaránt 7 mátrixnál bizonyúltak a legjobbbnak. Néhány jellemző példát mutat a @fig:am416-turbo-peldak.

#figure(
  grid(
    columns: (1fr, 1fr),
    gutter: 1.2em,
    [#image("Plot_to_TDK/Turbo_Plot_16_TDK/Grafikon_N300_K96.png", width: 100%)
     #text(size: 10pt)[(a) $N = 300, K = 96$]],
    [#image("Plot_to_TDK/Turbo_Plot_16_TDK/Grafikon_N228_K72.png", width: 100%)
     #text(size: 10pt)[(b) $N = 228, K = 72$]],
    [#image("Plot_to_TDK/Turbo_Plot_16_TDK/Grafikon_N180_K56.png", width: 100%)
     #text(size: 10pt)[(c) $N = 180, K = 56$]],
    [#image("Plot_to_TDK/Turbo_Plot_16_TDK/Grafikon_N132_K40.png", width: 100%)
     #text(size: 10pt)[(d) $N = 156, K = 48$]],
  ),
  caption: [Példák turbókód-mátrixokra, amelyeknél más-más AM4_16 változat a legjobb.],
) <fig:am416-turbo-peldak>

// Kihagyva (külön ábra volt egyetlen mátrixra): Plot_to_TDK/Turbo_Plot_16_All/Grafikon_N492_K160.png

=== LDPC kódok

A 35 vizsgált LDPC mátrixból 33 esetben legalább az egyik átfedéses változat elérte vagy felülmúlta a szinkron 16-QAM referenciát, és mind a négy változatra van példa, amelyben ő a legjobb. Az átfedéses és a szinkron demoduláció között egy adott SNR-ponton mért legnagyobb javulás a szinkron érték egy nyolcada volt. Illetve voltak olyan kódok ahol a hibapadlót SNR-el hamarabb elértük  (@fig:am416-ldpc-peldak).

#figure(
  grid(
    columns: (1fr, 1fr),
    gutter: 1.2em,
    [#image("Plot_to_TDK/LDPC_Plot_16_TDK/Grafikon_N100_K50.png", width: 100%)
     #text(size: 10pt)[(a) SP-kiosztás (`AM4_16`) a legjobb]],
    [#image("Plot_to_TDK/LDPC_Plot_16_TDK/Grafikon_N120_K60.png", width: 100%)
     #text(size: 10pt)[(b) Gray-kiosztás a legjobb]],
    [#image("Plot_to_TDK/LDPC_Plot_16_TDK/Grafikon_N336_K168.png", width: 100%)
     #text(size: 10pt)[(c) a priori demappelés (Soft) a legjobb]],
    [#image("Plot_to_TDK/LDPC_Plot_16_TDK/Grafikon_N480_K240.png", width: 100%)
     #text(size: 10pt)[(d) kétirányú dekódolás (Bidir) a legjobb]],
  ),
  caption: [Példák LDPC mátrixokra, amelyeknél más-más AM4_16 változat a legjobb.],
) <fig:am416-ldpc-peldak>

Figyelemre méltó, hogy a két eset, amelyben egyik átfedéses változat sem múlta felül a szinkron modulációt, kizárólag $R approx$ 0,6 kódsebesség mellett fordult elő (@fig:ldpc-r06). Ezzel szemben $R =$ 0,5 kódsebességnél valamennyi vizsgált mátrixra javulást értünk el a szinkron átvitelhez képest (@fig:ldpc-r05).

#grid(
  columns: (1fr, 1fr),
  gutter: 1.2em,
  [#figure(
    image("Plot_to_TDK/Osszehasonlitas_LDPC_R058--R066.png", width: 100%),
    caption: [A két $R approx$ 0,6 sebességű mátrix, amelyeknél a szinkron 16-QAM a jobb.],
  ) <fig:ldpc-r06>],
  [#figure(
    image("Plot_to_TDK/Osszehasonlitas_LDPC_R05.png", width: 100%),
    caption: [Az $R =$ 0,5 sebességű LDPC mátrixokra kapott eredmények.],
  ) <fig:ldpc-r05>],
)
#let data-ldpc = (
  ([Soft], 14),
  ([Döntetlen], 7),
  ([Bidir], 7),
  ([Gray], 4),
  ([Szinkron], 2),
  ([SP], 1),
)

#figure(
  canvas({
    draw.set-style(barchart: (bar-width: .2))
    chart.barchart(
      size: (5, 5),
      label-key: 0,
      value-key: 1,
      x-tick-step: 2,
      data-ldpc,
      x-label: [Mátrixok száma],
      y-label: [Legjobb eljárás],
    )
  }),
  caption: [A 35 LDPC mátrix megoszlása aszerint, hogy melyik eljárás érte el a legkisebb bithibaarányt.],
) <fig:eredmenyek-ldpc>
== Összegzés

A BPSK/QPSK átfedéses moduláció a várakozásoknak megfelelően a szinkron QPSK-val azonos teljesítményt nyújt: Gray-kódolású QPSK mellett a SIC-nek nincs mit kioltania, így az átfedés sem nyereséget, sem érdemi veszteséget nem okoz. A 4-QAM/16-QAM esetben viszont a vizsgált 58 mátrix döntő többségénél legalább az egyik átfedéses változat elérte vagy felülmúlta a szinkron 16-QAM referenciát-
Megjegyezzük, hogy mátrixonként négy változat közül nincs egyértelműen domináns változat, magasabb modulációs rendeknél a kódhoz illesztett eljárásválasztás tűnik célravezetőnek.
