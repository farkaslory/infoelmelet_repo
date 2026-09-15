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
  ## AAC_mod.m-nek a választható belső függvényei

  ### 

    






    
