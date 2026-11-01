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
késleltetés mellett megegyezik a szinkronéval @cover1981 @farkas2014capacity: az
aszinkronitás a kapacitáson nem változtat.

A két kiosztás között csak az információ megoszlásában van különbség (@tab:mi): a
saját kiosztás a finom (zavart) szerepben kevesebb, a durva (tisztított) szerepben
több információt hordoz, mint a Gray-kiosztás.

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

*A nyereség a hibaexponensben jelenik meg.* Az aszinkron szerkezet előnye nem a
kapacitásban, hanem a hibaexponensben (@eq:hibaexp) jelentkezik @csiszar2021.
Minden rendszer exponense a kapacitásnál nullára csökken, $E(C) = 0$ @gallager1965;
mivel a kapacitás a két rendszerben azonos, a vízesés-tartományban – ahol a kód
rátája közel van az adott jel-zaj viszonyhoz tartozó kapacitáshoz – lényeges
különbség nem várható. Rögzített kódrátánál a jel-zaj viszony növelésével a kapacitás
nő, a ráta egyre messzebb kerül alatta, és itt az exponensek már eltérhetnek. Nagy
jel-zaj viszony mellett a hibavalószínűséget a minimális távolság határozza meg, így
a nyereség konkrét formája a tisztított bitek nagyobb távolsága (@sec:llr-finom). A
nyereség tehát nem a kód küszöbének eltolódásában, hanem a küszöb feletti
tartományban, a bithibaarány gyorsabb csökkenésében jelentkezik. Csiszár, Farkas és
Kói eredménye együttes dekódolásra vonatkozik; hogy a szukcesszív vevővel mennyi
valósul meg belőle, azt szimulációval vizsgáljuk.
