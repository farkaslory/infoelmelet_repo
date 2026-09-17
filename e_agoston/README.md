Az én feladatom a LDPC kódok irányábol megközelíteni a tanár úr ötletét, és ezt a következő képpen csináltam:

  A tanár úrtól kapott AAC kódot át módosította úgy, hogy egy folder bemenetre, amiben .alist formátumú H mátrixok vannak, lefusson a AAC aszinkron modulációs kód,
  és vissza adjon egy mások hasonlóan elnevezett foldert, amiben H mátrixra lefutattott kódnak a kért kimenete el legyen mentve egy .mat file-ba. Ezeket később 
  egy másik programmal le lehet plot-olni majd.

# A fő program

  ## AAC_mod.m
      A programnak az a fő célja, hogy egyszerűen, ne file-ról file-ra tudjunk mátrixokat az általunk 
    kiválasztott modulációs módszerrel tesztelni, hanem egy .alist típusú file-okkal teli foler-t adujunk 
    be neki az alábbi formátumban: "fileName alist", szóval a file neve az mindegy, de utána egy szóközzel 
    szeparálva egy alist megnevező legyen. Ez amúgy is hasznos lesz, mivel tudjuk melyik folder mire való. 
    Miután a program lefutott egy "fileName mat" nevezetű folder-t hoz létre. 
      Ebben a folder-ben találhatjuk meg a általunk kiválasztott .alist formátumban megadott H mátrixokra, 
    az általunk választott függvénnyel (pl. Sync_Ldpc.m, Async_Ldpc.m, AM4_16 vagy AM2_4) lefuttatott 
    szimulációnak az eredményeit .mat file-formátumban. 
      Ezeknek a .mat file-oknak megegyezik a nevük a .alist eredet file-aival.
  ## AAC_mod.m segéd függvényei

  ### read_alist_2.m
    Ez a függvény egyszerűen kinyeri a .alist file-ból a kellő információkat, mint maga a H mátrix az eredeti
    formájában (N*M-es mátrix GF(2)-ben), az N-et és az M-et. Az N az oszlopok száma, míg M a sorok száma.
    A függvény a következő módon néz ki a kódban: 
      [H, N, M] = read_alist_2(fileName)
    Lehet látni, hogy megadjuk a függvénynek .alist file nevét, és ebből kinyeri a H, N és M 
    paramétereket.
  ### make_H_encodable.m
    Előkészíti a nyers, alist-fájlból beolvasott paritásellenőrző mátrixot a MATLAB ldpcEncoderConfig számára. 
    A ldpcEncoderConfig megköveteli, hogy H utolsó (N−K) oszlopa GF(2) felett invertálható legyen, ez az 
    alist-fájlok eredeti oszlopsorrendjében nem mindig teljesül, és néhány kódnál (pl. a Tanner(155,64) kódnál) 
    a "hivatalos" mátrix redundáns (lineárisan összefüggő) paritássorokat is tartalmaz. A függvény GF(2) 
    Gauss-eliminációval kiszűri az esetleges redundáns sorokat, majd permutálja az oszlopokat úgy, hogy a végén 
    invertálható részmátrix álljon — ez nem változtatja meg a kód hibajavító tulajdonságait, csak a kódolhatóság 
    technikai feltételét teljesíti.
    A függvényt a következő képpen kell kódba belerakni:
      [H, M] = make_h_encodable(H)
    Mivel ez a kód ad egy M-et, ezért nem feltétlenül kell a read_alist_2-ből az M-et felhasználni (pl. az fő
    kódban a read_alist_2-nek a kimeneténél az M-et egy ~-vel helyettesítettem).
    Továbbá, ezt a függvényt a read_alist_2 után kell meghívni, hogy legyen már egy kész, .alist formátumból 
    kiolvasott H mátrixunk.
  ## AAC_mod.m-nek a választható belső függvényei (a kód 70. sora)

  ### Sync_Ldpc.m
    Ez egy általános szinkron modulációt szimuláló kód, amelyhez fogom hasonlítani majd az egyéb aszinkron 
    modulációt szimuláló fügvényeket. A függvényt a következő képpen kell meghívni:
      [BlockLengthHalf, n, LdpcErr_2] = Sync_Ldpc(H, snr_range, numTrials)
      
      Meg kell neki adni a már .alist-ből kiolvasott, és make_H_encodable-en átfuttatott H mátrixot, az 
    általunk kiválasztott snr_range-et (pl. 2:0.5:8), és azt hogy egy snr alatt milyen "finomsággal" fusson
    le a program, magasabb szám általában pontosabb számolást jelent, de megnöveli a program futtatási idejét.
    Hasonlóan az snr_range is befojásolja a program futtatási idejét, mivel többször fog lefutni a szimuláció
    (pl. 2:0.5:8-as snr legfeljebb 12 ponton fogja jelezni az eredményeit a programnak). A H mátrixon kívül 
    mindegyik bemeneti változónak van alap beállítása, pl. az snr_range az említett 2:0.5:8, 
    a numTrials meg 20000, ami szignifikánsan nagyobb mint az aszinkron függvényben, de mivel itt egymáson 
    vannak a kódbblockkok, ezért itt a pontosság miatt ez a standard.
      A kimenete meg a BlockLenghtHalf, ami csak a N/2, az n, ami a N-M és a LdpcErr_2, ami pedig a snr-enként
    mért hiba aránya a kódnak.

  ### Async_Ldpc.m
    Az eredeti, a tanár úr által írt aszinkron modulációt szimuláló kód egy függvénbe rakva. Ez a program a
    szinkronnal ellentétben a kód blockkokat nem egymásra rakja pontosan a block kódokat, míg az aszinkron eltolja 
    a block kódokat egymáshoz képest valamilyen arányban. Ez tesztelésben jobb hiba arányokhoz vezetett.
    A függvényt a következő képpen kell meghívni:
      [BlockLengthHalf, n, LdpcErr_2] = Async_Ldpc(H, snr_range, K, numTrials)
      
      Itt az adatok csak annyiban térnek el a szinkron verziójától, hogy itt meg lehet adni egy K változót, 
    amely a kódblock-oknak a számát határozza meg (ez alapból 20). A numTrials itt 1000, mivel magasabb 
    beállításon szignifikánsan hosszabb ideig futna a program, és itt nem szinkron módon vannak egymásra rakva
    a kódszavak, ezért itt hasonló pontosság eléréséért csak 1000-es numTrials-t kell használni.
      A kimenet megegyzik az összes többi függvénnyel.

  ### AM2_4
    Levente által készített kód, mely 2 bitet egy szimbólumba kódol. Ezt lehet összehasonlítani a Sync_Ldpc-vel.
    A függvényt a következő képpen hívjuk meg:
      [BlockLengthHalf, n, LdpcErr_2] = AM2_4(H, snr_range, K, numTrials)

      Itt a bemeneti és kimeneti változók megegyeznek az eddigi konvenciókkal.
  ### AM4_16
    Lajos által készített kód, mely 4 bitet egy szimbólumba kódol. Ezt még az eddigi Sync_Ldpc-vel nem lehet 
    össze hasonlítani, erre külön szinkron kódot kell írni, amely szintén 4 bitet egy szimbólumba kódol.
    A függvént A következő képpen hívjuk meg:
      [BlockLengthHalf, n, LdpcErr_2] = AM4_16(H, snr_range, K, numTrials)

      Itt hasonlóan, a bemeneti és kimeneti változók megegyeznek.
    






    
