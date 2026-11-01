=== A tisztítás: kemény és lágy, Gray- és saját kiosztás <sec:llr-finom>

A szukcesszív vevő kulcslépése a tisztítás: a $k$-adik kódszó dekódolása után a finom
réteg hozzájárulását eltávolítjuk, hogy a $(k+1)$-edik kódszó durva bitjei
megbízhatóbbak legyenek. Két irányban módosíthatjuk az alapeljárást: a bitkiosztással
(Gray vagy saját, @tab:kiosztas) és a tisztítás módjával (kemény vagy lágy). Az
alábbiakban megmutatjuk, mit jelent a kettő, és milyen előnyökkel, hátrányokkal jár.

*A finom bitek LLR-je.* A tisztítás előtt a finom bitekről úgy kell lágy becslést
adni, hogy a durva réteg még ismeretlen. Tengelyenként
$u = (2 beta(d) + beta(f)) \/ sqrt(10) + w_u$, $w_u tilde.op cal(N)(0, N_0 \/ 2)$, és a
durva bitet a két lehetséges értékére marginalizálva a saját kiosztásnál
$ L(f | u) = ln (e^(-(u - 3\/sqrt(10))^2 \/ N_0) + e^(-(u + 1\/sqrt(10))^2 \/ N_0))
                / (e^(-(u - 1\/sqrt(10))^2 \/ N_0) + e^(-(u + 3\/sqrt(10))^2 \/ N_0)). $ <eq:llr-finom>
(A Gray-kiosztásnál a számlálóban a $plus.minus 3$, a nevezőben a $plus.minus 1$ szintek
állnak.) Numerikusan a log-sum-exp alakot használjuk.

*Kemény tisztítás, saját kiosztás.* A dekódolt kódszót újrakódoljuk, és a becsült
finom réteget kivonjuk:
$ tilde(u) = u - beta(hat(f)) / sqrt(10), quad
  L(d | tilde(u)) = 8 / (sqrt(10) N_0) tilde(u). $ <eq:llr-durva>
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
finom réteget, ha a dekóder bizonytalan volt. A lágy tisztítás @wang1999 ehelyett
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


=== A finom bitek LLR-je ismeretlen durva réteg mellett <sec:llr-finom>

A tisztítás előtt a $k$-adik kódszó finom bitjeiről úgy kell lágy becslést adni, hogy
a durva réteg (a következő kódszó bitjei) még ismeretlen. Tengelyenként
$u = (2 beta(d) + beta(f)) \/ sqrt(10) + w_u$, $w_u tilde.op cal(N)(0, N_0 \/ 2)$,
és a durva bitet a két lehetséges értékére marginalizálva
$ L(f | u) = ln (e^(-(u - 3\/sqrt(10))^2 \/ N_0) + e^(-(u + 1\/sqrt(10))^2 \/ N_0))
                / (e^(-(u - 1\/sqrt(10))^2 \/ N_0) + e^(-(u + 3\/sqrt(10))^2 \/ N_0)). $ <eq:llr-finom>
A számlálóban az $f = 0$, a nevezőben az $f = 1$ értékhez tartozó két szint áll
(@tab:kiosztas). A kifejezést numerikusan a log-sum-exp alakban számoljuk, mert az
exponenciális tagok nagy jel-zaj viszony mellett alulcsordulnak. A tisztítás után
a durva bit LLR-je zárt alakú:
$ L(d | tilde(u)) = 8 / (sqrt(10) N_0) tilde(u), quad
  tilde(u) = u - beta(hat(f)) / sqrt(10). $ <eq:llr-durva>
Mindkét képlet a valódi $N_0$ zajvarianciát használja. Ez lényeges: a BP-alapú LDPC-
dekóder az LLR-ek abszolút nagyságára is érzékeny, így hibás zajvariancia mellett
a különböző rendszerek összehasonlítása torzul.
