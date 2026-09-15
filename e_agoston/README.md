Az én feladatom a LDPC kódok irányábol megközelíteni a tanár úr ötletét, és ezt a következő képpen csináltam:

  A tanár úrtól kapott AAC kódot át módosította úgy, hogy egy folder bemenetre, amiben .alist formátumú H mátrixok vannak, lefusson a AAC aszinkron modulációs kód,
  és vissza adjon egy mások hasonlóan elnevezett foldert, amiben H mátrixra lefutattott kódnak a kért kimenete el legyen mentve egy .mat file-ba. Ezeket később 
  egy másik programmal le lehet plot-olni majd.

# A fő program

  ## AAC_mod.m
    A programnak az a fő célja, hogy egyszerűen, ne file-ról file-ra tudjunk kódokat az általunk kiválasztott modulációs módszerrel,
    hanem egy .alist típusú foler-t adujunk be neki az alábbi formátumban: "fileName alist", szóval a file neve az mindegy, 
    de utána egy szóközzel szeparálva egy alist megnevező legyen. Ez amúgy is hasznos lesz, mivel tudjuk melyik folder mire való. 
    Miután a program lefutott egy "fileName mat" nevezetű folder-t hoz létre. Ebben a folder-ben találhatjuk meg a általunk kiválasztott 
  
