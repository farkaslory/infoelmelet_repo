// ============================================================
//  Beamer-szerű diasablon – csak beépített Typst, csomag nélkül
//  Használat:  = Szekció neve      (felső sávban jelenik meg)
//              == Dia címe         (új dia + a kék címsávban jelenik meg)
// ============================================================
#import "@preview/cetz:0.3.4"
#let navy  = rgb("#163453")   // felső navigációs sáv
#let blue  = rgb("#20507c")   // diacím-sáv
#let paper = rgb("#fafafa")   // dia háttere
#let muted = rgb("#7f98b0")   // nem aktuális szekció színe
#let c-bg       = rgb("#fafafa") // Oldal háttérszín (luma(250))
#let c-text     = rgb("#222222") // Alap szövegszín (luma(34))
#let c-nav-bg   = rgb("#14334f") // Felső navigációs sáv
#let c-title-bg = rgb("#1f4e79") // Diacím sáv
#let c-accent   = rgb("#c0504d") // Kiemelő bordó-piros
#let c-footer   = rgb("#aaaaaa") // Lábléc szürke

#let slides(footer-text: [], body) = {
  set page(
    paper: "presentation-16-9",
    margin: (top: 3.3cm, bottom: 1.8cm, x: 1.8cm),
    fill: paper,
    background: context {
      let pn = counter(page).get().first()
      let hs = query(heading)

      // szekciók és diáik összegyűjtése
      let secs = ()
      for h in hs {
        if h.level == 1 {
          secs.push((name: h.body, slides: ()))
        } else if h.level == 2 {
          if secs.len() == 0 { secs.push((name: [], slides: ())) }
          let last = secs.pop()
          last.slides.push(h)
          secs.push(last)
        }
      }

      let cur = hs.find(h => h.level == 2 and h.location().page() == pn)
      if cur == none { return }

      let total = hs.filter(h => h.level == 2).len()
      let n = hs.filter(h => h.level == 2 and h.location().page() <= pn).len()

      // --- felső navigációs sáv ---
      let dot(filled, active) = {
        let c = if active { white } else { muted }
        box(circle(radius: 2.6pt, fill: if filled { c } else { none }, stroke: 0.7pt + c))
      }

      let cells = secs.enumerate().map(((i, s)) => {
        let active = s.slides.any(x => x.location().page() == pn)
        let idx = s.slides.position(x => x.location().page() == pn)
        let col = if active { white } else { muted }
        let dots = s.slides.enumerate().map(((j, _)) => dot(
          // aktív szekcióban csak az aktuális dia teli, máshol minden pont teli (halvány)
          if active { j == idx } else { true },
          active,
        ))
        let al = if i == 0 { left } else if i == secs.len() - 1 { right } else { center }
        align(al + horizon, stack(
          dir: ttb, spacing: 4pt,
          text(size: 13pt, fill: col, weight: if active { "bold" } else { "regular" })[#s.name],
          stack(dir: ltr, spacing: 3pt, ..dots),
        ))
      })

      place(top + left, stack(
        rect(width: 100%, height: 1.3cm, fill: navy, inset: (x: 1cm, y: 0pt),
          grid(columns: (1fr,) * secs.len(), ..cells)),
        rect(width: 100%, height: 1.15cm, fill: blue, inset: (x: 1cm, y: 0pt),
          align(left + horizon, text(size: 26pt, fill: white)[#cur.body])),
      ))

      // --- lábléc ---
      place(bottom + left, dx: 0.7cm, dy: -0.45cm,
        text(size: 12pt, fill: rgb("#888"))[#footer-text])
      place(bottom + right, dx: -0.7cm, dy: -0.45cm,
        text(size: 12pt, fill: rgb("#888"))[#n / #total])
    },
  )

  set text(font: "Libertinus Serif", size: 17pt, lang: "hu", fill: rgb("#222"))
  set par(leading: 0.6em, spacing: 1em)
  set list(marker: text(fill: blue)[•], spacing: 0.9em)
  set enum(spacing: 0.9em)

  // a címsorok nem jelennek meg a dia törzsében, csak a sávokban
  show heading.where(level: 1): none
  show heading.where(level: 2): it => { pagebreak(weak: true); none }

  body
}

#let title-slide(title, subtitle: none, author: none, date: none) = {
  align(center + horizon, stack(
    dir: ttb, spacing: 1.2cm,
    block(fill: blue, inset: (x: 1.5cm, y: 1cm), radius: 3pt, stack(
      dir: ttb, spacing: 0.6cm,
      text(size: 34pt, fill: white)[#title],
      if subtitle != none { text(size: 22pt, fill: rgb("#cfe0f0"))[#subtitle] },
    )),
    if author != none { text(size: 22pt)[#author] },
    if date != none { text(size: 16pt, fill: rgb("#666"))[#date] },
  ))
}

// ============================================================
//  PÉLDA – ezt a részt cserélheted a saját tartalmadra
// ============================================================

#show: slides.with(footer-text: [BME – TDK])

#title-slide(
  [A szimulációs környezet, folyamat és az eredmények],
  subtitle: [Aszinkron moduláció szukcesszív dekódolással],
  author: [Én te meg ő],
  date: [2026.11.18.],
)

= A szimulációs környezet és folyamat

== A környezet és a folyamat
//#grid(
//  columns: (1fr, 1fr), // Két egyenlő szélességű oszlop
//  gutter: 1.2em,       // Távolság a két kép között vízszintesen
//  image("assets/image.png", width: 60%),
//  
//  image("assets/image-1.png", width: 60%)
// );
#align(horizon, grid(
  columns: (1fr, 1fr),   // bal oszlop kicsit szélesebb
  gutter: 1cm,             // távolság az oszlopok között
  align: horizon,          // függőlegesen középre igazít (top = felülre)
  [
    - Matlab
    - Turbó és LDPC kód ellenőrző mátrix
    - rtpu.de
      - H mátrixok letöltése $arrow$ mappákba rendezés
    - alist/txt file-ban $H$-mx $arrow$ $dots$ $arrow$ mat file
      - mat file-ok felépítése:
  ],
  //image("assets/image-6.png", width: 100%),
))

== Folyamat ábra
// =====================================================================
// 2. FOLYAMATÁBRA RAJZOLÓ FÜGGVÉNY (NAGYÍTOTT, MIN. 12pt BETŰMÉRETTEL)
// =====================================================================

#let szimulacios-folyamatabra() = {
  let c-box-fill    = rgb("#eaf0f6")
  let c-header-fill = rgb("#d5e2ee")
  let c-accent-fill = rgb("#f9ebeb")
  let c-bme         = rgb("#8A2432")

  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    // Segédfüggvény a kettős vonalú tömbnyilakhoz (==>)
    let block-arrow(p1, p2, col: c-title-bg) = {
      let (x1, y1) = p1
      let (x2, y2) = p2
      let dx = x2 - x1
      let dy = y2 - y1
      let len = calc.sqrt(dx * dx + dy * dy)
      let ux = dx / len
      let uy = dy / len
      let nx = -uy
      let ny = ux
      let sw = 0.09 // szár félvastagsága
      let hw = 0.24 // nyílfej félszélessége
      let hl = 0.36 // nyílfej hossza
      let bx = x2 - hl * ux
      let by = y2 - hl * uy

      line(
        (x1 + sw * nx, y1 + sw * ny),
        (bx + sw * nx, by + sw * ny),
        (bx + hw * nx, by + hw * ny),
        (x2, y2),
        (bx - hw * nx, by - hw * ny),
        (bx - sw * nx, by - sw * ny),
        (x1 - sw * nx, y1 - sw * ny),
        close: true,
        fill: white,
        stroke: 1.2pt + col,
      )
    }

    // -----------------------------------------------------------------
    // A) FELSŐ ÁG (1. BEMENET: PARITÁSELLENŐRZŐ MÁTRIXOK)
    // -----------------------------------------------------------------

    // (1.) jelölő kör + nyíl
    circle((0.45, 11.25), radius: 0.45, fill: c-bme.lighten(80%), stroke: 1.4pt + c-bme)
    content((0.45, 11.25), text(size: 15pt, weight: "bold", fill: c-bme)[1.])
    line((0.90, 11.25), (1.30, 11.25), mark: (end: ">"), stroke: 1.3pt + c-title-bg)

    // 1. téglalap: Tömörített paritásellenőrző mátrixok
    rect((1.30, 9.85), (6.40, 12.65), fill: c-box-fill, stroke: 1.2pt + c-title-bg, radius: 3pt)
    content((3.85, 11.25), align(center)[
      #set par(leading: 0.52em)
      #text(size: 12pt, weight: "bold", fill: c-title-bg)[
        TÖMÖRÍTETT\
        PARITÁSELLENŐRZŐ\
        MÁTRIXOK\
      ]
      #text(size: 12pt, fill: c-text)[`[.TXT / .ALIST]`]
    ])

    // Nyíl -> readTurboCode.m / read_alist_2.m
    line((6.40, 11.25), (7.85, 11.25), mark: (end: ">"), stroke: 1.3pt + c-title-bg)

    // 1. ovális: beolvasó szkriptek
    circle((10.00, 11.25), radius: (2.15, 1.02), fill: white, stroke: 1.2pt + c-title-bg)
    content((10.00, 11.25), align(center)[
      #set par(leading: 0.55em)
      #text(size: 12.5pt, style: "italic", fill: c-text)[
        readTurboCode.m\
        read_alist_2.m
      ]
    ])

    // Nyíl -> H sparse logical mtx
    line((12.15, 11.25), (13.40, 11.25), mark: (end: ">"), stroke: 1.3pt + c-title-bg)

    // 2. téglalap: H sparse logical mtx
    rect((13.40, 10.25), (16.40, 12.25), fill: c-box-fill, stroke: 1.2pt + c-title-bg, radius: 3pt)
    content((14.90, 11.25), align(center)[
      #set par(leading: 0.55em)
      #text(size: 13pt, weight: "bold", fill: c-title-bg)[
        $H$ sparse\
        logical mtx
      ]
    ])

    // Derékszögű nyíl lefelé a fő szimulációs körbe
    line(
      (14.95, 10.25),
      (14.95, 9.05),
      mark: (end: ">"),
      stroke: 1.4pt + c-title-bg,
    )

    // -----------------------------------------------------------------
    // B) ALSÓ-BAL TÁBLÁZAT (2. BEMENET: SZIMULÁCIÓS MAGOK)
    // -----------------------------------------------------------------

    // Táblázat befoglaló kerete: x=[1.30, 10.90], y=[0.35, 8.70]
    rect((1.30, 0.35), (10.90, 8.70), fill: white, stroke: 1.3pt + c-title-bg)
    // Fejléc hátterek
    rect((1.30, 7.65), (10.90, 8.70), fill: c-title-bg, stroke: 1.3pt + c-title-bg)
    rect((2.80, 6.70), (10.90, 7.65), fill: c-header-fill, stroke: 1.2pt + c-title-bg)
    rect((1.30, 6.70), (2.80, 7.65), fill: luma(242), stroke: 1.2pt + c-title-bg)

    // Átlós sraffozás a bal felső üres cellában
    for i in range(1, 6) {
      let d = i * 0.28
      line(
        (1.30 + calc.max(0, d - 0.95), 6.70 + calc.min(0.95, d)),
        (1.30 + calc.min(1.50, d), 6.70 + calc.max(0, d - 1.50)),
        stroke: 0.65pt + gray,
      )
    }

    // Vízszintes elválasztó vonal a 2-4 és 4-16 sorok között
    line((1.30, 4.70), (10.90, 4.70), stroke: 1.2pt + c-title-bg)
    // Függőleges oszlopelválasztók
    line((2.80, 0.35), (2.80, 7.65), stroke: 1.2pt + c-title-bg)
    line((6.65, 0.35), (6.65, 7.65), stroke: 1.2pt + c-title-bg)

    // Táblázat szövegek
    content((6.10, 8.175), text(size: 14.5pt, weight: "bold", fill: white)[SZIMULÁCIÓS MAGOK])
    content((4.725, 7.175), text(size: 12.5pt, weight: "bold", fill: c-title-bg)[SZINKRON])
    content((8.775, 7.175), text(size: 12.5pt, weight: "bold", fill: c-title-bg)[ASZINKRON])

    // 1. adatsor (2-4)
    content((2.05, 5.70), text(size: 13pt, weight: "bold", fill: c-title-bg)[2–4])
    content((4.725, 5.70), text(size: 12.5pt, style: "italic")[Sync_LDPC.m])
    content((8.775, 5.70), text(size: 12.5pt, style: "italic")[AM2_4.m])

    // 2. adatsor (4-16)
    content((2.05, 2.525), text(size: 13pt, weight: "bold", fill: c-title-bg)[4–16])
    content((4.725, 2.525), text(size: 12.5pt, style: "italic")[Sync_LDPC_16.m])
    content((8.775, 2.525), align(center)[
      #set par(leading: 0.65em)
      #text(size: 12.5pt, style: "italic")[
        AM4_16.m\
        AM4_16_Gray.m\
        AM4_16_Soft.m\
        AM4_16_Bidir.m
      ]
    ])

    // (2.) jelölő kör + nyíl a 2-4 sorhoz
    circle((0.45, 5.70), radius: 0.45, fill: c-bme.lighten(80%), stroke: 1.4pt + c-bme)
    content((0.45, 5.70), text(size: 15pt, weight: "bold", fill: c-bme)[2.])
    line((0.90, 5.70), (1.30, 5.70), mark: (end: ">"), stroke: 1.3pt + c-title-bg)

    // -----------------------------------------------------------------
    // C) ALSÓ-KÖZÉPSŐ MODULÁCIÓS OVÁLIS (runMod.m)
    // -----------------------------------------------------------------

    line((10.90, 2.15), (13.00, 2.15), mark: (end: ">"), stroke: 1.3pt + c-title-bg)

    circle((14.95, 2.15), radius: (1.95, 0.88), fill: white, stroke: 1.2pt + c-title-bg)
    content((14.95, 2.15), text(size: 13.5pt, style: "italic", weight: "bold", fill: c-text)[runMod.m])

    // Nyíl felfelé a fő szimulációs körbe
    line((14.95, 3.03), (14.95, 4.25), mark: (end: ">"), stroke: 1.4pt + c-title-bg)

    // -----------------------------------------------------------------
    // D) KÖZPONTI KETTŐS KÖR (runSim.m / simuLDPC.m)
    // -----------------------------------------------------------------

    circle((14.95, 6.65), radius: 2.40, fill: c-title-bg.lighten(30%), stroke: 1.6pt + c-title-bg)
    circle((14.95, 6.65), radius: 2.15, fill: white, stroke: 1.2pt + c-title-bg)
    content((14.95, 6.65), align(center)[
      #set par(leading: 0.65em)
      #text(size: 15.5pt, style: "italic", weight: "bold", fill: c-title-bg)[
        runSim.m\
        simuLDPC.m
      ]
    ])

    // -----------------------------------------------------------------
    // E) JOBB OLDALI KIMENETI ÉS VIZUALIZÁCIÓS LÁNC
    // -----------------------------------------------------------------

    // Kettős tömbnyíl -> .MAT ADATTÁROLÓK
    block-arrow((17.35, 6.65), (18.20, 6.65), col: c-title-bg)

    rect((18.20, 5.75), (22.00, 7.55), fill: c-box-fill, stroke: 1.2pt + c-title-bg, radius: 3pt)
    content((20.10, 6.65), align(center)[
      #set par(leading: 0.55em)
      #text(size: 12.5pt, weight: "bold", fill: c-title-bg)[
        `.MAT`\
        ADATTÁROLÓK
      ]
    ])

    // Kettős tömbnyíl -> plotNK2.m
    block-arrow((22.00, 6.65), (22.80, 6.65), col: c-title-bg)

    circle((24.40, 6.65), radius: (1.60, 0.88), fill: white, stroke: 1.2pt + c-title-bg)
    content((24.40, 6.65), text(size: 13.5pt, style: "italic", weight: "bold", fill: c-text)[plotNK2.m])

    // Kettős tömbnyíl lefelé -> ÖSSZEHASONLÍTÓ GRAFIKONOK
    block-arrow((24.40, 5.77), (24.40, 3.65), col: c-title-bg)

    // Kettős keretű kimeneti téglalap
    rect((22.20, 1.45), (26.60, 3.65), fill: c-bme.lighten(80%), stroke: 1.3pt + c-bme, radius: 3pt)
    rect((22.33, 1.58), (26.47, 3.52), fill: none, stroke: 0.8pt + c-bme, radius: 2pt)
    content((24.40, 2.55), align(center)[
      #set par(leading: 0.55em)
      #text(size: 12pt, weight: "bold", fill: c-bme)[
        ÖSSZEHASONLÍTÓ\
        GRAFIKONOK
      ]
    ])
  })
}
#v(1fr)
#align(center, szimulacios-folyamatabra())
#v(1fr)
= Az eredmények

== BPSK-QPSK (AM2_4)
- Hasonló eredmények a szinkron és az aszinkron modulációkra
- Nagyobb mátrix $arrow$ meredekebb görbe

  //#grid(
  columns: (1fr, 1fr), // Két egyenlő szélességű oszlop
  gutter: 1.2em,
    figure(
      image("assets/Osszehasonlitas_LDPC_R05.png", width: 99%),
      caption: text(size: 14pt)[LDPC kódok aggregált ábrája],
    ),
    figure(
      image("Osszesített_Turbo_2_4.png", width: 88%),
      caption: text(size: 14pt)[Turbó kódok aggregált ábrája],
    ),
  )
== Eredménydiverzitás (AM4_16)
#align(horizon, grid(
  columns: (1fr, 1fr),
  gutter: 1cm,
  align: horizon,
  [
    - 23 Tudbó kód, 29 LDPC kód
    - SNR-BER koordinátarendszerben ábrázolás
    - Ha a görbe korábbi SNR-nél, vagy ugyanazon SNR-en, de kisebb BER-rel tűnik el, \ annak a kódnak jobb a hibajavítási képessége
  ],
  image("infokom_tdk_sajat/Plot_to_TDK2/turbo4-16_doga/Grafikon_N300_K96.png", width: 100%),
))
== Eredménydiverzitás (AM4_16)
#align(horizon, grid(
  columns: (1fr, 1fr),
  gutter: 1cm,
  align: horizon,
  [
    - 23 Tudbó kód, 29 LDPC kód
    - SNR-BER koordinátarendszerben ábrázolás
    - Ha a görbe korábbi SNR-nél, vagy ugyanazon SNR-en, de kisebb BER-rel tűnik el, \ annak a kódnak jobb a hibajavítási képessége
  ],
  image("infokom_tdk_sajat/Plot_to_TDK2/turbo4-16_doga/Grafikon_N228_K72.png", width: 100%),
))
== Eredménydiverzitás (AM4_16)
#align(horizon, grid(
  columns: (1fr, 1fr),
  gutter: 1cm,
  align: horizon,
  [
    - 23 Tudbó kód, 29 LDPC kód
    - SNR-BER koordinátarendszerben ábrázolás
    - Ha a görbe korábbi SNR-nél, vagy ugyanazon SNR-en, de kisebb BER-rel tűnik el, \ annak a kódnak jobb a hibajavítási képessége
  ],
  image("infokom_tdk_sajat/Plot_to_TDK2/turbo4-16_doga/Grafikon_N180_K56.png", width: 100%),
))
== Eredménydiverzitás (AM4_16)
#align(horizon, grid(
  columns: (1fr, 1fr),
  gutter: 1cm,
  align: horizon,
  [
    - 23 Tudbó kód, 29 LDPC kód
    - SNR-BER koordinátarendszerben ábrázolás
    - Ha a görbe korábbi SNR-nél, vagy ugyanazon SNR-en, de kisebb BER-rel tűnik el, \ annak a kódnak jobb a hibajavítási képessége
  ],
  image("infokom_tdk_sajat/Plot_to_TDK2/turbo4-16_doga/Grafikon_N132_K40.png", width: 100%),
))

== 4QAM-16QAM eredmény-eloszlás (AM4_16)
- Érdekesebb eredmények
- 4 fajta szimbólum modulációs módszer
- Kódfüggő
//#grid(
  columns: (1fr, 1fr), // Két egyenlő szélességű oszlop
  gutter: 1.2em,
    //ldpc EZEK CSAK PLACEHOLDEREK!!!
    figure(
      image("assets/image-4.png", width: 80%),
      caption: text(size: 16pt)[LDPC kódok statisztikája],
    ),
    //turbo
    figure(
      image("assets/image-3.png", width: 80%),
      caption: text(size: 16pt)[Turbó kódok statisztikája],
    ),
  )

