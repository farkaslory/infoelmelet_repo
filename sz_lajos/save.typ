*A demodulációhoz szükséges LLR-ek.* A tisztítás előtt a finom bit LLR-jét a
durva bitre marginalizálva kapjuk (saját kiosztás, log-sum-exp alakban számolva):
$ L(f | u) = ln (e^(-(u - 3\/sqrt(10))^2 \/ N_0) + e^(-(u + 1\/sqrt(10))^2 \/ N_0))
                / (e^(-(u - 1\/sqrt(10))^2 \/ N_0) + e^(-(u + 3\/sqrt(10))^2 \/ N_0)), $ <eq:llr-finom>
a tisztítás után pedig a durva bit LLR-je zárt alakú:
$ L(d | tilde(u)) = 8 / (sqrt(10) N_0) tilde(u), quad
  tilde(u) = u - beta(hat(f)) / sqrt(10). $ <eq:llr-durva>

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
                / (e^(-(u - 1\/sqrt(10))^2 \/ N_0) + e^(-(u + 3\/sqrt(10))^2 \/ N_0)). $ <eq:llr-finom2>
(A Gray-kiosztásnál a számlálóban a $plus.minus 3$, a nevezőben a $plus.minus 1$ szintek
állnak.) Numerikusan a log-sum-exp alakot használjuk.

*Kemény tisztítás, saját kiosztás.* A dekódolt kódszót újrakódoljuk, és a becsült
finom réteget kivonjuk:
$ tilde(u) = u - beta(hat(f)) / sqrt(10), quad
  L(d | tilde(u)) = 8 / (sqrt(10) N_0) tilde(u). $ <eq:llr-durva2>
Helyes $hat(f)$ esetén a durva bit egy kétszeres léptékű 4-QAM-ban jelenik meg, ez a
saját kiosztás távolságnyeresége (@sec:sajat-kiosztas). Hibás $hat(f)$ esetén
azonban a maradék $plus.minus 2 \/ sqrt(10)$, és a pont vagy a durva döntési határra
($tilde(u) approx 0$) kerül, vagy annak kétszeresére: egy hibás finom bit átlagosan
minden második esetben „törli” a következő kódszó megfelelő durva bitjét. Ez a
hibaterjedés forrása (@sec:hibaterjedes).

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
a nyeresége is kicsi (@tab:tavolsag).

*Lágy tisztítás.* A kemény tisztítás akkor is teljes súllyal vonja ki a becsült
finom réteget, ha a dekóder bizonytalan volt. A lágy tisztítás Wang1999 ehelyett
a dekóder kódbitekre adott a posteriori LLR-jéből ($Lambda_f$) a finom réteg
*várható értékét* vonja ki:
$ m = EE[beta(f) | Lambda_f] = tanh(Lambda_f \/ 2), quad
  tilde(u) = u - m / sqrt(10). $ <eq:lagy-kivonas>
Biztos döntésnél ($|Lambda_f| >> 1$) $m approx plus.minus 1$, és ez megegyezik a
kemény tisztítással; bizonytalan bitnél ($Lambda_f approx 0$) $m approx 0$, vagyis
nem vonunk ki semmit, és a durva bit a tisztítás előtti, gyengébb, de hibátlan
helyzetben marad – nem kerül a döntési határra. A maradék
$(beta(f) - m) \/ sqrt(10)$ szórását Gauss-zajként kezelve
$ sigma_"eff"^2 = N_0 / 2 + (1 - m^2) / 10, quad
  L(d | tilde(u)) = 4 / (sqrt(10) sigma_"eff"^2) tilde(u). $ <eq:lagy-llr>
$m = plus.minus 1$ esetén ez visszaadja az @eq:llr-durva képletét.
// TODO: ellenőrizd, hogy a megvalósítás a sigma_eff^2-et is számolja-e, vagy csak a
// várható értéket vonja ki (utóbbi esetben az LLR bizonytalan biteknél túl nagy).
A lágy tisztításhoz a dekódernek nemcsak az információs bitekre adott kemény
döntést, hanem a teljes kódszóra vonatkozó LLR-eket is ki kell adnia. Hátránya, hogy
a BP-dekóder sikertelen dekódolásnál magabiztosan hibás LLR-eket is adhat; ezeken a
bitek a lágy tisztítás sem segít.

*Gray és lágy tisztítás együtt.* Mivel a Gray-kiosztásnál a finom réteg nem
vonható ki, a lágy tisztítás itt a finom bit a priori valószínűségként való
felhasználását jelenti a durva bit demodulációjában:
$ L(d | u) = ln (sum_(f) P(f) thin p(u | d = 0, f)) / (sum_(f) P(f) thin p(u | d = 1, f)),
  quad P(f = 0) = 1 / (1 + e^(-Lambda_f)). $ <eq:lagy-prior>
Ez a forma bármely kiosztásra érvényes (a saját kiosztásnál az @eq:lagy-kivonas
ennek Gauss-közelítése), tehát a két irány kombinálható. Nagy javulás azonban nem
várható tőle, mert a Gray-kiosztás döntési határa eleve független a finom bittől –
a lágy tisztítás csak az LLR-ek nagyságát pontosítja.

#figure(
  table(
    columns: 3, align: (left, left, left), stroke: none,
    table.hline(stroke: 0.6pt),
    table.header([], [kemény tisztítás], [lágy tisztítás]),
    table.hline(stroke: 0.4pt),
    [saját kiosztás],
    [nagy távolságnyereség ($delta^2$: $1 -> 4$); hibás finom bit a döntési határra
      tolja a pontot – erős hibaterjedés],
    [helyes dekódolásnál ugyanaz a nyereség; bizonytalan biteket nem von ki – gyengébb
      hibaterjedés; dekóder-LLR kell],
    [Gray-kiosztás],
    [kis nyereség (a legrosszabb távolság nem nő); a döntési határ nem mozdul –
      gyenge hibaterjedés],
    [megvalósítható (a priori valószínűséggel), de kevés többletet ad],
    table.hline(stroke: 0.6pt),
  ),
  caption: [A kiosztás és a tisztítás módjának hatása.],
) <tab:tisztitas>

Összefoglalva: a saját kiosztás nagyobb nyereséget ígér, de kemény tisztítással
érzékeny a hibaterjedésre; a lágy tisztítás pontosan ezt a gyengeségét kezeli. A
Gray-kiosztás robusztus, de kevés nyereséggel. A gyakorlatban ezért a saját kiosztás
és a lágy tisztítás együttese a legígéretesebb.
// TODO: a szimulációs eredményekkel (5. fejezet) összevetni.

*A kapacitás szintjén nincs különbség.* A láncszabály szerint
$ I(D, F; Y) = I(F; Y) + I(D; Y | F), $ <eq:lanc-16qam>
és a bal oldal a 16-QAM konstelláció kölcsönös információja, amely nem függ a
címkézéstől. A SIC-lánc minden kódszava egyik felével a „zavart” ($I(F; Y)$), másik
felével a „tisztított” ($I(D; Y | F)$) szerepben vesz részt, így ideális kódokkal
mindkét kiosztás ugyanazt az összeget éri el. A kiosztás csak azt dönti el, hogyan
oszlik meg ez az összeg a két szerep között (@tab:mi). A szinkron Gray-16-QAM
bitenkénti dekódolással ennél alig kevesebbet ér el, ezért a kapacitáshoz közeli
tartományban egyik kiosztástól sem várható számottevő nyereség.

#figure(
  table(
    columns: 4, align: (left, center, center, center), stroke: none,
    table.hline(stroke: 0.6pt),
    table.header([], [$E_s \/ N_0 = 6$ dB], [$9$ dB], [$12$ dB]),
    table.hline(stroke: 0.4pt),
    [saját: $I(F;Y) + I(D;Y|F)$], [0,24 + 0,86], [0,49 + 0,98], [0,79 + 1,00],
    [Gray: $I(F;Y) + I(D;Y|F)$], [0,40 + 0,70], [0,64 + 0,82], [0,86 + 0,93],
    [összeg (mindkettő)], [1,10], [1,46], [1,79],
    [szinkron Gray, bitenként], [1,09], [1,46], [1,79],
    table.hline(stroke: 0.6pt),
  ),
  caption: [Tengelyenkénti kölcsönös információ (bit/dimenzió) a két szerepben.
    Monte Carlo-becslés; az összeg a kiosztástól független.],
) <tab:mi>
// A táblázat értékei a labeling.py Monte Carlo-szkriptből (4·10^5 minta) származnak.

*Nagy jel-zaj viszony mellett a döntési távolságok számítanak.* Ebben a
tartományban a kódolt bithibaarányt a legrosszabb pontok távolsága határozza meg:
milyen messze van egy pont a legközelebbi olyan ponttól, amelyben az adott bit
eltér. Jelölje $delta^2$ ezt a távolságnégyzetet a 16-QAM minimális
távolságnégyzetének ($4 \/ 10$) egységében. A két szerepre (@tab:tavolsag):

- *Tisztítás előtt (finom bit, ismeretlen durva réteg):* mindkét kiosztásban
  $delta^2 = 1$; a saját kiosztásban minden belső pontnak két ilyen szomszédja van,
  a Gray-kiosztásban csak egy. A saját kiosztás finom bitjei tehát valamivel
  gyengébbek – ezt mutatja az $I(F; Y)$ kisebb értéke is (@tab:mi).
- *Tisztítás után (durva bit, ismert finom réteg):* a saját kiosztásban minden
  pont távolsága a kétszeresére nő ($delta^2 = 4$), mert a megmaradó négy pont egy
  kétszeres léptékű 4-QAM-ot alkot. A Gray-kiosztásban ez csak a külső pontokra
  igaz ($delta^2 = 9$); a belső pontoké változatlan ($delta^2 = 1$).

#figure(
  table(
    columns: 4, align: (left, center, center, center), stroke: none,
    table.hline(stroke: 0.6pt),
    table.header([], [szinkron Gray], [AAC, Gray], [AAC, saját]),
    table.hline(stroke: 0.4pt),
    [tisztítás előtti (finom) bit], [$1$], [$1$], [$1$ (kétszeres multiplicitás)],
    [tisztított (durva) bit], [$1$ ill. $4$], [$1$ ill. $9$], [$4$ minden pontra],
    [legrosszabb eset átlaga], [$1$], [$1$], [(1 + 4)/2 = 2,5],
    table.hline(stroke: 0.6pt),
  ),
  caption: [Bitenkénti távolságnégyzet ($delta^2$) a 16-QAM minimális
    távolságnégyzetének egységében. A „szinkron” oszlopban a két sor az LSB-re ill.
    az MSB-re vonatkozik.],
) <tab:tavolsag>

Ha egy kódszó hibaeseményeinek bitjei egyenletesen oszlanak meg a két fele között,
a hibaesemény euklideszi távolságnégyzete a bitenkénti értékek összege. A saját
kiosztás így a legrosszabb esetben is a szinkron rendszer távolságnégyzetének
2,5-szeresét éri el, ami aszimptotikusan
$ G_infinity = 10 log_10 (delta_f^2 + delta_d^2) / (2 delta_"ref"^2)
  = 10 log_10 (1 + 4) / 2 approx 4 "dB" $ <eq:aszimptotikus>
nyereségnek felel meg. A Gray-kiosztásnál a legrosszabb (belső) pontok távolsága
nem javul, így aszimptotikusan nem várható nyereség. A becslés felső korlát: nem
veszi figyelembe a szomszédok számát, a kódszavak tényleges súlyeloszlását és a
hibaterjedést.
// TODO: a korábban mért ~4 dB nagy SNR-es nyereség ezzel összhangban van – a helyes
// LLR-ekkel (NoiseVariance) újramért eredményekkel érdemes itt összevetni.

A két hatás együtt magyarázza a mért viselkedést. Alacsony jel-zaj viszonynál a
saját kiosztás gyengébb finom bitjei miatt gyakrabban hibázik a lánc egy-egy
dekódolása, és a hibaterjedés (@sec:hibaterjedes) felemészti a nyereséget. Nagy
jel-zaj viszonynál a tisztított bitek kétszeres távolsága dominál, és a saját
kiosztás egyértelműen jobb. A saját kiosztás valójában az Ungerboeck-féle
halmazparticionálás ungerboeck1982 elvét követi: minden ismert bit után a
megmaradó pontok a lehető legtávolabb vannak egymástól. Az eljárás így egy
többszintű kódolásnak felel meg többlépcsős dekódolással wachsmann1999, azzal a
különbséggel, hogy az eltolás miatt egyetlen kód szolgálja ki mindkét szintet.

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
Ahol $hat(f) = f$, a tisztítás helyes. Ahol $hat(f) != f$, a maradék
$plus.minus 2 \/ sqrt(10)$, és a durva bit szintje vagy a döntési határra ($0$-ra)
kerül, vagy annak kétszeresére ($plus.minus 4 \/ sqrt(10)$). Egy hibásan becsült
finom bit tehát átlagosan minden második esetben „törli” a következő kódszó
megfelelő durva bitjét. Mivel egy sikertelen LDPC-dekódolás nem néhány, hanem a
kódszó jelentős részét érintő bithibát okoz, a következő kódszó első fele nagyrészt
törlődik, annak dekódolása is nagy valószínűséggel sikertelen lesz, és a hiba
dominóként végigfuthat a láncon. (A BPSK–QPSK változatban ilyen hibaterjedés nincs,
mert ott a tisztítás nem befolyásolja az LLR-t; @sec:bpsk-qpsk.)

A hibaterjedés hatását *genie-aided* vevővel választjuk le. Ez a vevő a tisztításhoz
a valóban elküldött biteket használja, a dekódolás minden más lépése változatlan.
A genie-aided és a valódi SIC-vevő bithibaarányának különbsége így pontosan a
hibaterjedés okozta veszteség, a genie-aided vevő és a szinkron rendszer
különbsége pedig a struktúrából eredő nyereség.

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
//  refs.bib-be:
//  @article{wachsmann1999,
//    author  = {Wachsmann, Udo and Fischer, Robert F. H. and Huber, Johannes B.},
//    title   = {Multilevel Codes: Theoretical Concepts and Practical Design Rules},
//    journal = {IEEE Transactions on Information Theory},
//    volume  = {45}, number = {5}, pages = {1361--1391}, year = {1999}
//  }
// 