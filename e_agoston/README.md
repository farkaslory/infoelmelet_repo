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
  ### Segéd függvények
