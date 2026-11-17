// ============================================================
//  TDK előadás – Átfedéses szimbólum moduláció és soros interferencia-kioltás
//  (1. rész: a moduláció és általánosításai, 2. rész: szimuláció és eredmények)
//  Fordítás:
//    diák:               typst compile eloadas.typ
//    diák + jegyzetek:   typst compile eloadas.typ --input notes=true eloadas-jegyzetekkel.pdf
//    pdfpc jegyzetfájl:  typst query --root . eloadas.typ --field value --one "<pdfpc-file>" > eloadas.pdfpc
// ============================================================

#import "@preview/touying:0.7.4": *
#import themes.metropolis: *
#import "@preview/cetz:0.4.2"

// --- jegyzetek a dia mellett (jobb oldali "második képernyő") ----------
#let notes = sys.inputs.at("notes", default: "false") == "true"

// --- színek -------------------------------------------------------------
#let fo = rgb("#1f4e79")        // fő szín (durva bitek)
#let kiemel = rgb("#c0504d")    // kiemelés (finom bitek)
#let zold = rgb("#4e9a52")      // tisztított / kész
#let paletta = (rgb("#4f81bd"), rgb("#f79646"), rgb("#9bbb59"), rgb("#8064a2"), rgb("#4bacc6"))
#let fszinek = (rgb("#e15759"), rgb("#f28e2b"), rgb("#76b7b2"), rgb("#af7aa1")) // finom címkék: 00, 01, 10, 11
// a 2. rész (szimuláció) folyamatábrájának színei
#let c-text     = rgb("#222222")
#let c-title-bg = fo

// ============================================================
//  Fejléc: szekciók + pöttyök (beamer „miniframes”)
// ============================================================

#let navigacio = context {
  let hs = query(heading.where(level: 1).or(heading.where(level: 2))).filter(h => h.outlined)
  let szekciok = ()
  let utolso = none
  for h in hs {
    if h.level == 1 {
      szekciok.push((h, ()))
    } else if szekciok.len() > 0 {
      // animált diáknál a cím több oldalon is megjelenik → csak egyszer számoljuk
      let kulcs = repr(h.body)
      if utolso != kulcs {
        szekciok.at(-1).at(1).push(h)
      }
      utolso = kulcs
    }
  }
  let oldal = here().page()
  let mind = szekciok.map(s => s.at(1)).flatten()
  let aktualis = mind.filter(h => h.location().page() <= oldal).len() - 1
  let idx = 0
  let oszlopok = ()
  for (sz, diak) in szekciok {
    let elso = idx
    let pottyok = ()
    for d in diak {
      let p = if idx == aktualis {
        circle(radius: 3.6pt, fill: white, stroke: none)
      } else if idx < aktualis {
        circle(radius: 2.6pt, fill: white.transparentize(55%), stroke: none)
      } else {
        circle(radius: 2.6pt, fill: none, stroke: 0.7pt + white.transparentize(45%))
      }
      pottyok.push(link(d.location(), box(p)))
      idx += 1
    }
    let itt = aktualis >= elso and aktualis < idx
    oszlopok.push(box(stack(
      spacing: 4pt,
      link(sz.location(), text(size: 11pt, fill: if itt { white } else { white.transparentize(45%) }, weight: if itt { "bold" } else { "regular" }, sz.body)),
      stack(dir: ltr, spacing: 4pt, ..pottyok),
    )))
  }
  // a szekciónevek nem tördelődnek: a dobozok közé egyenlő térköz kerül
  block(width: 100%, oszlopok.join(h(1fr)))
}

#let sajat-dia(
  title: auto,
  align: auto,
  config: (:),
  repeat: auto,
  setting: body => body,
  composer: auto,
  ..bodies,
) = touying-slide-wrapper(self => {
  if align != auto { self.store.align = align }
  let header(self) = {
    set std.align(top)
    set block(spacing: 0pt)
    block(width: 100%, fill: fo.darken(35%), inset: (x: 1.2em, top: 0.45em, bottom: 0.4em), navigacio)
    block(width: 100%, fill: fo, inset: (x: 1em, y: 0.5em),
      text(fill: white, weight: "medium", size: 1.15em,
        if title != auto { title } else { utils.display-current-heading(depth: self.slide-level) }))
  }
  let footer(self) = {
    set std.align(bottom)
    set text(size: 0.7em, fill: gray)
    pad(.5em, components.left-and-right(
      utils.call-or-display(self, self.store.footer),
      context utils.slide-counter.display() + " / " + utils.last-slide-number,
    ))
  }
  let self = utils.merge-dicts(self, config-page(fill: self.colors.neutral-lightest, header: header, footer: footer))
  let new-setting = body => {
    show: std.align.with(self.store.align)
    set text(fill: self.colors.neutral-darkest)
    show: setting
    body
  }
  touying-slide(self: self, config: config, repeat: repeat, setting: new-setting, composer: composer, ..bodies)
})

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  footer: self => self.info.institution,
  config-info(
    title: [Átfedéses szimbólum moduláció és soros interferencia-kioltás vizsgálata korszerű csatornakódok esetén],
    author: [Szabó Lajos, Kertész Levente, Érsek Ágoston, Gál Marcell],
    date: [2026],
    institution: [BME – TDK],
  ),
  config-colors(
    primary: kiemel,
    primary-light: kiemel.lighten(60%),
    secondary: fo,
    neutral-lightest: rgb("#fafafa"),
    neutral-dark: fo,
    neutral-darkest: rgb("#222222"),
  ),
  config-page(header-ascent: 0%, margin: (top: 4.4em, bottom: 1.5em, x: 2em)),
  config-common(
    slide-fn: sajat-dia,
    new-section-slide-fn: none,
    show-notes-on-second-screen: if notes { right } else { none },
  ),
)

#set text(font: ("Fira Sans", "Inter", "Noto Sans", "DejaVu Sans"), size: 20pt, lang: "hu")
#show math.equation: set text(font: ("New Computer Modern Math", "Latin Modern Math"))

// ============================================================
//  Konstelláció-segédek (a dolgozat jelölései: β(0) = +1, β(1) = −1)
// ============================================================

#let beta(b) = 1 - 2 * b
#let bitek = ((0, 0), (0, 1), (1, 0), (1, 1))
// SP-kiosztás: szint = 2β(d) + β(f) tengelyenként
#let pont(dR, dI, fR, fI) = (2 * beta(dR) + beta(fR), 2 * beta(dI) + beta(fI))
#let fszin(fR, fI) = fszinek.at(2 * fR + fI)

// determinisztikus „zaj” az ábrákhoz
#let gauss(i) = {
  let u1 = 0.0005 + 0.999 * calc.abs(calc.fract(calc.sin(i * 12.9898 + 1.3) * 43758.5453))
  let u2 = calc.abs(calc.fract(calc.sin(i * 78.233 + 2.7) * 43758.5453))
  let r = calc.sqrt(-2 * calc.ln(u1))
  (r * calc.cos(2 * calc.pi * u2), r * calc.sin(2 * calc.pi * u2))
}

#let tengely-dobozok(s, R: 4.2, dobozcimke: true) = {
  import cetz.draw: *
  line((-R * s, 0), (R * s, 0), stroke: gray + 0.5pt)
  line((0, -R * s), (0, R * s), stroke: gray + 0.5pt)
  for (dR, dI) in bitek {
    let (cx, cy) = (2 * beta(dR), 2 * beta(dI))
    rect(((cx - 1.8) * s, (cy - 1.8) * s), ((cx + 1.8) * s, (cy + 1.8) * s),
      stroke: (paint: fo.lighten(35%), dash: "dashed", thickness: 0.6pt), radius: 0.06)
    if dobozcimke {
      content(((cx + beta(dR) * 2.3) * s, (cy + beta(dI) * 2.3) * s), text(size: 12pt, fill: fo, weight: "bold")[#dR#dI])
    }
  }
}

// --- durva + finom felbontás egy kiemelt ponttal ---
#let felbontas-abra(s: 0.98) = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  tengely-dobozok(s)
  for (dR, dI) in bitek {
    for (fR, fI) in bitek {
      let (x, y) = pont(dR, dI, fR, fI)
      circle((x * s, y * s), radius: 0.1, fill: fszin(fR, fI), stroke: none)
      content((x * s, y * s - 0.33), text(size: 10pt, fill: fszin(fR, fI).darken(25%), weight: "bold")[#fR#fI])
    }
  }
  // kiemelt szimbólum: d = 00, f = 10
  let (x, y) = pont(0, 0, 1, 0)
  line((0, 0), (2 * s, 2 * s), stroke: fo + 2.2pt, mark: (end: ">", fill: fo, scale: 0.8))
  line((2 * s, 2 * s), (x * s, y * s), stroke: kiemel + 2pt, mark: (end: ">", fill: kiemel, scale: 0.7))
  circle((x * s, y * s), radius: 0.2, stroke: kiemel + 1.5pt)
})

// --- tisztítás: három panel ---
#let tisztitas-panel(mod, s: 0.7) = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  tengely-dobozok(s, dobozcimke: false)
  let sig = 0.3
  let n = 22
  let mag = 0
  if mod == "vett" {
    for (dR, dI) in bitek {
      for (fR, fI) in bitek {
        let (x, y) = pont(dR, dI, fR, fI)
        let c = fszin(fR, fI)
        for t in range(n) {
          let (gx, gy) = gauss(mag)
          mag += 1
          circle(((x + sig * gx) * s, (y + sig * gy) * s), radius: 0.045, fill: c.transparentize(25%), stroke: none)
        }
      }
    }
    line((1 * s, 4.1 * s), (3 * s, 4.1 * s), stroke: black + 0.8pt, mark: (start: "|", end: "|"))
    content((2 * s, 4.1 * s + 0.35), text(size: 13pt)[$d = 2$])
  } else if mod == "kivonas" {
    for (dR, dI) in bitek {
      let (cx, cy) = (2 * beta(dR), 2 * beta(dI))
      for (fR, fI) in bitek {
        let (x, y) = pont(dR, dI, fR, fI)
        let c = fszin(fR, fI)
        line((x * s, y * s), (cx * s * 1.0, cy * s), stroke: c + 1.1pt, mark: (end: ">", fill: c, scale: 0.45))
        circle((x * s, y * s), radius: 0.07, fill: c, stroke: none)
      }
      circle((cx * s, cy * s), radius: 0.11, fill: white, stroke: fo + 1.2pt)
    }
  } else {
    for (dR, dI) in bitek {
      let (cx, cy) = (2 * beta(dR), 2 * beta(dI))
      for t in range(4 * n) {
        let (gx, gy) = gauss(mag)
        mag += 1
        circle(((cx + sig * gx) * s, (cy + sig * gy) * s), radius: 0.045, fill: fo.transparentize(25%), stroke: none)
      }
      content(((cx + beta(dR) * 1.3) * s, (cy + beta(dI) * 1.3) * s), text(size: 11pt, fill: fo, weight: "bold")[#dR#dI])
    }
    line((-2 * s, 4.1 * s), (2 * s, 4.1 * s), stroke: black + 0.8pt, mark: (start: "|", end: "|"))
    content((0, 4.1 * s + 0.35), text(size: 13pt)[$d = 4$])
  }
})

// --- kemény vs. lágy tisztítás ---
#let puha-panel(mod, s: 0.72) = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  tengely-dobozok(s, dobozcimke: false)
  let P = (0.6, 0.2, 0.15, 0.05) // a priori P(f) a finom címkékre (00, 01, 10, 11)
  for (dR, dI) in bitek {
    for (fR, fI) in bitek {
      let (x, y) = pont(dR, dI, fR, fI)
      let k = 2 * fR + fI
      if mod == "kemeny" {
        if k == 0 {
          circle((x * s, y * s), radius: 0.2, fill: fszin(fR, fI), stroke: none)
        } else {
          circle((x * s, y * s), radius: 0.07, fill: gray.lighten(50%), stroke: none)
        }
      } else {
        circle((x * s, y * s), radius: 0.06 + 0.22 * calc.sqrt(P.at(k)), fill: fszin(fR, fI).transparentize(10%), stroke: none)
      }
    }
  }
})

// --- SP vs. Gray a teljes 16-QAM-on (a dolgozat táblázata szerint) ---
// tengelyenként szint → (d, f):  SP: −3:11, −1:10, 1:01, 3:00   Gray: −3:10, −1:11, 1:01, 3:00
#let szint(d, f, gray) = if gray { beta(d) * (2 + beta(f)) } else { 2 * beta(d) + beta(f) }

#let kiosztas-2d(gray: false, csak: none, s: 0.72) = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let R = 4.2
  line((-R * s, 0), (R * s, 0), stroke: luma(170) + 0.5pt)
  line((0, -R * s), (0, R * s), stroke: luma(170) + 0.5pt)
  // azonos finom címkéjű pontok téglalapja = a tisztítás után megmaradó 4-QAM
  for (k, (fR, fI)) in bitek.enumerate() {
    if csak == none or csak == k {
      let xs = (0, 1).map(d => szint(d, fR, gray))
      let ys = (0, 1).map(d => szint(d, fI, gray))
      let c = fszin(fR, fI)
      // összes egyszerre: kis eltolás, hogy az egybeeső élek is látszódjanak
      let e = if csak == none { (k - 1.5) * 0.07 } else { 0 }
      let (x0, x1, y0, y1) = (calc.min(..xs), calc.max(..xs), calc.min(..ys), calc.max(..ys))
      rect(((x0 + e) * s, (y0 + e) * s), ((x1 + e) * s, (y1 + e) * s),
        stroke: c + (if csak == none { 1.2pt } else { 2pt }),
        fill: if csak == none { none } else { c.transparentize(82%) })
      if csak != none {
        content(((x0 + x1) / 2 * s, y1 * s + 0.48), text(size: 14pt, fill: c.darken(25%), weight: "bold")[#(x1 - x0)])
        content((x1 * s + 0.48, (y0 + y1) / 2 * s), text(size: 14pt, fill: c.darken(25%), weight: "bold")[#(y1 - y0)])
      }
    }
  }
  for (dR, dI) in bitek {
    for (k, (fR, fI)) in bitek.enumerate() {
      let (x, y) = (szint(dR, fR, gray), szint(dI, fI, gray))
      let aktiv = csak == none or csak == k
      circle((x * s, y * s), radius: if aktiv { 0.16 } else { 0.1 },
        fill: if aktiv { fszin(fR, fI) } else { luma(200) }, stroke: white + 0.8pt)
    }
  }
})

// --- kódszólánc, opcionálisan SIC-állapottal ---
// allapot = s: c_1..c_s már dekódolva, c_(s+1) a soron következő
#let lanc(L: 4, allapot: none, nyil: none, w: 3.5, h: 0.92) = cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let gap = 0.12
  let s = allapot
  for j in range(1, L + 1) {
    let y = -(j - 1) * (h + gap)
    let c = paletta.at(calc.rem(j - 1, paletta.len()))
    let kesz = s != none and j <= s
    let aktiv = s != none and j == s + 1
    let (fill1, fill2) = if kesz { (gray.lighten(80%), gray.lighten(70%)) } else { (c.lighten(60%), c.lighten(25%)) }
    let st = if aktiv { kiemel + 2pt } else if kesz { gray + 0.6pt } else { c.darken(15%) + 0.8pt }
    rect(((j - 1) * w, y), (j * w, y - h), fill: fill1, stroke: st)
    rect((j * w, y), ((j + 1) * w, y - h), fill: fill2, stroke: st)
    let tc = if kesz { gray } else { black }
    let szerep1 = if j == 1 { [] } else { text(size: 12pt, fill: fo.darken(10%))[ durva] }
    let szerep2 = if j == L { [] } else { text(size: 12pt, fill: kiemel.darken(10%))[ finom] }
    content(((j - 0.5) * w, y - h / 2), text(size: 16pt, fill: tc)[$c_#j^((1))$#szerep1])
    content(((j + 0.5) * w, y - h / 2), text(size: 16pt, fill: tc)[$c_#j^((2))$#szerep2])
    if kesz {
      content(((j + 1) * w - 0.3, y - h / 2), text(size: 16pt, fill: zold, weight: "bold")[✓])
    }
  }
  let yb = -L * (h + gap) - 0.3
  for m in range(0, L + 2) {
    line((m * w, 0.15), (m * w, yb - h), stroke: (paint: gray, dash: "dashed", thickness: 0.5pt))
  }
  for m in range(0, L + 1) {
    let szelso = m == 0 or m == L
    let tiszta = s != none and m == s and m > 0
    let elhasznalt = s != none and m < s
    let forras = s != none and (m == s or m == s + 1)
    let felirat = if tiszta { [4-QAM] } else if szelso { [4-QAM] } else { [16-QAM] }
    let fill = if elhasznalt { gray.lighten(85%) } else if tiszta { zold.lighten(70%) } else if szelso { gray.lighten(65%) } else { fo.lighten(75%) }
    rect((m * w, yb), ((m + 1) * w, yb - h), fill: fill, stroke: if forras { kiemel + 2pt } else { fo + 0.8pt })
    content(((m + 0.5) * w, yb - h / 2), text(size: 15pt, weight: "bold", fill: if elhasznalt { gray } else { fo })[$x_#m$: #felirat])
  }
  if nyil == "ketiranyu" {
    let ya = yb - h - 0.5
    let mid = (L + 1) * w / 2
    line((0, ya), (mid - 0.15, ya), stroke: kiemel + 1.8pt, mark: (end: ">", fill: kiemel))
    line(((L + 1) * w, ya), (mid + 0.15, ya), stroke: kiemel + 1.8pt, mark: (end: ">", fill: kiemel))
    content((mid / 2, ya - 0.5), text(size: 15pt, fill: kiemel)[előre: $c_1, c_2, dots$])
    content((mid * 1.5, ya - 0.5), text(size: 15pt, fill: kiemel)[hátra: $c_L, c_(L-1), dots$])
  }
})

#let jelmagyarazat = text(size: 13pt)[
  #for (i, (a, b)) in bitek.enumerate() {
    box(circle(radius: 4pt, fill: fszinek.at(i), stroke: none)); [ #a#b]; h(0.8em)
  }
]

// ============================================================
//  Diák
// ============================================================

#title-slide()

#speaker-note[
  Az én részem arról szól, hogyan általánosítottuk a szabadalomban leírt alapeljárást.
  Az eredményekről és a szimulációs környezetről a következő előadó beszél; én csak magát a modulációt és annak kiterjesztéseit mutatom be.
]

// ============================================================
= Alapötlet

== Átfedő kódszavak

#align(center, lanc(L: 4))
#v(0.4em)
#text(size: 17pt)[
  - Egy 16-QAM szimbólum *két szomszédos kódszó* bitjeiből áll
  - A lánc végein nincs szomszéd → ritkább *4-QAM*; $L$ kódszó → $L + 1$ blokk
]

#speaker-note[
  Az alapötlet: nem egy kódszót teszünk egy szimbólumba, hanem két egymást követőt, fél kódszóval eltolva.
  Minden kódszót két félre bontunk. A k-adik kódszó második fele és a (k+1)-edik első fele együtt adja a 16-QAM blokkot: az egyik a finom, a másik a durva bitekért felel.
  A lánc két végén nincs szomszéd, ott ritkább 4-QAM-et használunk. Így L kódszóhoz L+1 blokk tartozik.
]

== Durva és finom bitek

#grid(columns: (1fr, 1.1fr), column-gutter: 1em, align: horizon,
  align(center, felbontas-abra()),
  [
    #text(fill: fo, weight: "bold")[Durva bitek] → melyik *doboz* \
    #text(size: 16pt)[a következő kódszó eleje: $c_(k+1)^((1))$]

    #v(0.6em)
    #text(fill: kiemel, weight: "bold")[Finom bitek] → melyik *pont* a dobozon belül \
    #text(size: 16pt)[az aktuális kódszó vége: $c_k^((2))$]

    #v(0.6em)
    #text(size: 16pt)[Minden doboz *azonos* címkézésű (halmazparticionáló kiosztás)]
    #v(0.3em)
    #jelmagyarazat
  ],
)

#speaker-note[
  Egy 16-QAM pontot két lépésben érünk el: a kék nyíl a durva bitek alapján kiválasztja a negyedet, a dobozt; a piros nyíl a finom bitekkel a dobozon belüli pontot.
  A színek a finom címkéket jelölik: látszik, hogy minden dobozban ugyanaz a minta. Ez a halmazparticionáló kiosztás, erre még visszatérek.
]

// ============================================================
= Dekódolás

== Szukcesszív dekódolás lépésenként

#align(center, alternatives(
  lanc(L: 4, allapot: 0),
  lanc(L: 4, allapot: 1),
  lanc(L: 4, allapot: 2),
))
#v(0.3em)
#align(center, text(size: 17pt, alternatives(
  [*1.* $c_1$ dekódolása: $x_0$ tiszta 4-QAM + $x_1$ finom bitjei],
  [*2.* $hat(c)_1$ kivonása után $x_1$ is tiszta 4-QAM → $c_2$ dekódolása],
  [*3.* és így tovább a lánc végéig: $c_3, dots, c_L$],
)))

#speaker-note[
  A vevő a lánc elejéről indul. Az első kódszó első fele egy tiszta 4-QAM blokkban van, a második fele az x1 finom bitjei között – ebből dekódoljuk c1-et.
  Ezután c1 finom részét újra előállítjuk és kivonjuk x1-ből. Ami marad, az már csak c2 durva bitjeit hordozza: x1 tiszta 4-QAM lett.
  Így c2 ugyanabba a helyzetbe kerül, mint c1, és az eljárás láncszerűen folytatódik.
  Hátránya: ha egy kódszót elrontunk, a hibás kivonás továbbterjed – erre lesz két általánosításunk.
]

== Tisztítás a konstellációban

#grid(columns: (1fr, auto, 1fr, auto, 1fr), align: center + horizon, column-gutter: 0.4em,
  tisztitas-panel("vett"),
  text(size: 26pt, fill: gray)[→],
  tisztitas-panel("kivonas"),
  text(size: 26pt, fill: gray)[→],
  tisztitas-panel("tiszta"),
  text(size: 16pt)[*Vett 16-QAM blokk*\ szín = finom címke],
  [],
  text(size: 16pt)[*$hat(c)_k$ ismert:*\ finom rész kivonása],
  [],
  text(size: 16pt)[*Tisztított 4-QAM*\ csak a durva bitek],
)
#v(0.3em)
#align(center, text(size: 17pt)[Ugyanaz a zaj, de a döntési távolság *kétszeres* → a következő kódszó eleje megbízhatóbb])

#speaker-note[
  Ez a tisztítás a konstelláción. Bal oldalon a vett 16-QAM blokk: a pontfelhők színe a finom címke, a szomszédos pontok távolsága 2.
  Ha az előző kódszót dekódoltuk, a finom részt ismerjük: minden pontot a saját dobozának közepébe toljuk vissza – ez a középső ábra.
  Jobb oldalon a maradék: négy pontfelhő, egy 4-QAM, ahol már csak a következő kódszó durva bitjei vannak, és a távolság 4.
  A zaj ugyanaz maradt, a pontok viszont kétszer messzebb vannak egymástól – innen jön a módszer előnye.
  Normálás után ez egységnyi energiájú 4-QAM, a zajvariancia 5/4-szeresével.
]

// ============================================================
= Általánosítások

== Bitkiosztás: halmazparticionáló vs. Gray

// lépések: finom címke 00, 11, 01
#let kiosztas-lepesek = (0, 3, 1)

#grid(columns: (1fr, 1fr), column-gutter: 1em, align: center + horizon, row-gutter: 0.5em,
  [*Halmazparticionáló (SP)* \ #text(size: 14pt, fill: gray)[minden doboz azonos címkézésű]],
  [*Gray* \ #text(size: 14pt, fill: gray)[tükrözött dobozok]],
  alternatives(..kiosztas-lepesek.map(k => kiosztas-2d(gray: false, csak: k))),
  alternatives(..kiosztas-lepesek.map(k => kiosztas-2d(gray: true, csak: k))),
  text(size: 17pt)[$display(P_d^"SP" = Q(2 / (sqrt(10) sigma)))$],
  text(size: 17pt)[$display(P_d^"Gray" = 1/2 [Q(1 / (sqrt(10) sigma)) + Q(3 / (sqrt(10) sigma))] gt.eq P_d^"SP")$],
)
#v(0.2em)
#align(center, text(size: 16pt)[
  #alternatives(
    ..kiosztas-lepesek.map(k => [
      Ismert finom címke: #box(circle(radius: 5pt, fill: fszinek.at(k), stroke: none)) #bitek.at(k).at(0)#bitek.at(k).at(1)
      → a megmaradó 4-QAM (tisztítás előtt $d = 2$) #h(0.8em) $sigma = 1 \/ sqrt(2 E_s \/ N_0)$]),
  )
])

#speaker-note[
  Az első általánosítás a bitkiosztás. Kattintásonként egy finom címkét veszünk ismertnek: a kiemelt téglalap az a 4-QAM, ami a tisztítás után megmarad; az oldalhossza a döntési távolság.
  A halmazparticionáló kiosztásnál – ez Ungerboeck ötlete – minden doboz ugyanúgy van címkézve, ezért mind a négy téglalap egyforma, 4-es oldalú négyzet: a tisztítás mindig megduplázza a távolságot.
  Gray-kiosztásnál a dobozok tükrözve vannak: a négyzetek egymásba ágyazódnak. Az egyik 6-os, a másik csak 2-es oldalú – ott a tisztítás semmit nem javít –, a maradék kettő 6×2-es téglalap.
  Alul a durva bit hibavalószínűsége tisztítás után, tengelyenként, ahol σ = 1/√(2·Es/N0), egységnyi szimbólumenergia mellett; a √10 az egységnyi átlagenergiára normálásból jön. Például 12 dB-en SP-nél kb. 2·10⁻⁴, Gray-nél kb. 2·10⁻², százszoros a különbség. SP-nél Q(2/(√10σ)), Gray-nél a két eset átlaga, ½[Q(1/(√10σ)) + Q(3/(√10σ))].
  Mivel a Q-függvény konvex, az SP-é mindig kisebb – a rossz, 2-es eset sokkal többet ront, mint amennyit a 6-os javít.
  Ezért a láncban a halmazparticionáló kiosztást használjuk.
]

== Kétirányú dekódolás

#align(center, lanc(L: 4, nyil: "ketiranyu", w: 3.4, h: 0.85))
#v(0.2em)
#text(size: 17pt)[
  - A lánc *mindkét végén* 4-QAM van → mindkét végről indítható tisztítás
  - Hátrafelé a durva és finom szerep megcserélődik (tükrözött adó)
  - Egy hiba legfeljebb a lánc *feléig* terjed; a két ág párhuzamosan fut
]

#speaker-note[
  A második általánosítás: a lánc mindkét végén tiszta 4-QAM blokk van, így a dekódolást a végéről is lehet kezdeni, sőt mindkét végéről egyszerre.
  Ehhez a lánc második felében megcseréljük a durva és finom szerepet, így a jobb végről indított dekódoló ugyanazt látja, mint a bal végről indított.
  A két ág középen találkozik: egy hiba legfeljebb a lánc feléig terjed, és a két irány párhuzamosan számolható.
]

== Lágy tisztítás

#grid(columns: (1fr, 1fr), column-gutter: 2em, align: center + horizon,
  puha-panel("kemeny"),
  puha-panel("lagy"),
  text(size: 16pt)[*Kemény:* dobozonként 1 jelölt, kivonás],
  text(size: 16pt)[*Lágy:* minden jelölt marad, súlyozva],
)
#v(0.2em)
#align(center, text(size: 17pt)[
  $ L(d | u) = ln (sum_(f) P(f) thin p(u | d = 0, f)) / (sum_(f) P(f) thin p(u | d = 1, f)), quad
    P(f = 0) = 1 / (1 + e^(-Lambda_f^"e")) $
  #v(-0.2em)
  $Lambda_f^"e" = Lambda_f - L_"cs" (f)$ #h(0.6em) (a dekóder kimeneti LLR-je − a csatorna-LLR)
])

#speaker-note[
  A harmadik általánosítás a kemény tisztítás lágy változata.
  Bal oldalon a kemény eset: a dekóder döntése után dobozonként egyetlen pont marad, ezt kivonjuk. Ha a döntés rossz, a hiba továbbmegy.
  Jobb oldalon a lágy eset: nem döntünk, hanem a dekóder extrinsic LLR-jeiből valószínűséget számolunk a finom bitekre; a pontok mérete ezt mutatja.
  A következő kódszó durva bitjeit ezekkel a súlyokkal, a tisztítatlan 16-QAM blokkból becsüljük.
  A képlet: a durva bit LLR-jét úgy számoljuk, hogy a finom bit két lehetséges értékét a priori valószínűségükkel súlyozzuk. Ezt a dekóder extrinsic LLR-jéből kapjuk – csak az extrinsic részt adjuk át, különben a vett jelet kétszer vennénk figyelembe.
  Ha a dekóder biztos, ez pontosan a kemény tisztítást adja vissza; ha bizonytalan (extrinsic LLR ≈ 0), a tisztítás nélküli LLR-re esik vissza, így nem égetünk be rossz döntést.
]

// ============================================================
= Ár és háttér

== Az eljárás ára: sebességveszteség

#align(center, box(radius: 6pt, clip: true, image("abra/Sebessegveszteseg_Elmeleti_L_fuggvenyeben.png", height: 9.6cm)))
#v(0.2em)
#align(center, text(size: 17pt)[$L$ kódszó → $L + 1$ blokk: relatív veszteség $1 \/ (L + 1)$ #h(1em) $L = 20$: 4,8 % (0,21 dB)])

#speaker-note[
  Az eljárásnak ára is van. A lánc két végén ritkább, 4-QAM modulációt használunk, így L kódszó L+1 blokkot foglal el; a relatív sebességveszteség 1/(L+1).
  A bal oldali ábrán ez látszik: L = 10-nél kb. 9 %, ami 0,41 dB, L = 20-nál 4,8 %, ami 0,21 dB.
  A jobb oldalon a spektrális hatékonyság: a lánc hosszával a szinkron 16-QAM határértékéhez tart. Hosszabb lánc tehát kisebb veszteség, de hosszabb hibaterjedési lánc – ezért fontos a kétirányú és a lágy tisztítás.
]

== Kapcsolat az irodalommal

#grid(columns: (1fr, 1fr), column-gutter: 1.2em,
  block(width: 100%, height: 8.2cm, fill: luma(238), inset: 0.8em, radius: 6pt)[
    *Csúszóablakos szuperpozíció (SWSC)* \
    #text(size: 14pt, fill: gray)[Wang et al. (2014, 2020); Kim et al. (2016)]
    #v(0.2em)
    #text(size: 16pt)[
      - *kétfelhasználós interferenciacsatorna*
      - cél: a zavaró jel kezelése egyszerű, pont-pont kódokkal
      - egyfelhasználós csatornán inkább a szerkezet *hátrányait* emelik ki
    ]
  ],
  block(width: 100%, height: 8.2cm, fill: fo.lighten(85%), inset: 0.8em, radius: 6pt)[
    *A mi munkánk* \
    #text(size: 14pt, fill: gray)[a szabadalom eljárása alapján]
    #v(0.2em)
    #text(size: 16pt)[
      - *egy felhasználó*, AWGN-csatorna, interferencia nélkül
      - kérdés: az átfedés *önmagában* növelheti-e a megbízhatóságot?
      - általánosítások: SP-kiosztás, kétirányú és lágy tisztítás
    ]
  ],
)
#v(0.4em)
#align(center, text(size: 16pt)[*Közös:* lépcsőzetesen eltolt, szuperponált kódszavak + szukcesszív, csúszóablakos dekódolás])

#speaker-note[
  Fontos megemlíteni, hogy ugyanez a lépcsőzetes szerkezet az irodalomban már megjelent: Wang és társai csúszóablakos szuperpozíciós kódolása, illetve ennek gyakorlati, modulációs változata Kim és társaitól.
  Ők azonban a kétfelhasználós interferenciacsatornát vizsgálták: ott az átfedés abban segít, hogy a zavaró felhasználó jelét egyszerű, pont-pont kódokkal kezelni lehessen. Egyfelhasználós csatornán inkább a szerkezet hátrányait emelik ki.
  Mi ezzel szemben egyetlen felhasználót nézünk, interferencia nélkül, és azt kérdezzük, hogy maga az átfedés javíthatja-e a megbízhatóságot – ehhez dolgoztuk ki a bemutatott általánosításokat.
]

// ############################################################
//  2. RÉSZ – szimulációs környezet és eredmények
// ############################################################

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
    - Turbó és LDPC kód paritásellenőrző mátrix
    - RPTU Kaiserslautern-Landau
      - H mátrixok letöltése $arrow$ mappákba rendezés
    - alist/txt file-ban $H$-mx $arrow$ $dots$ $arrow$ mat file
      - mat file-ok felépítése:
  ],
  image("assets/image-6.png", width: 100%),
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

  #align(horizon, grid(
  columns: (1fr, 1fr), // Két egyenlő szélességű oszlop
  gutter: 1.2em,
  align: horizon, [
    - Hasonló eredmények a szinkron és az aszinkron modulációkra
    - Nagyobb mátrix $arrow$ meredekebb görbe
  ],
    figure(
      image("Plot_to_TDK/Osszesített_Turbo_2_4.png", width: 88%),
      caption: text(size: 14pt)[Turbó kódok aggregált ábrája],
    )
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
  image("assets/Grafikon_N132_K40.png", width: 100%),
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
  image("assets/Grafikon_N156_K48.png", width: 100%),
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
  image("assets/Grafikon_N276_K88.png", width: 100%),
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
  image("assets/Grafikon_N372_K120.png", width: 100%),
))
== 4QAM-16QAM (AM4_16)
- Érdekesebb eredmények
- 4 fajta szimbólum modulációs módszer
- Kódfüggő
#grid(
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

// ############################################################
//  ZÁRÁS
// ############################################################

= Összegzés

== További irányok

#grid(columns: (1fr, 1fr), column-gutter: 2em,
  [
    #text(fill: fo, weight: "bold")[Dekódolás]
    #v(0.2em)
    - Más csatornakódolók
    - Belenyúlás a BP (_belief propagation_) dekóderbe
    - Kétirányú + lágy tisztítás együtt
  ],
  [
    #text(fill: fo, weight: "bold")[Moduláció]
    #v(0.2em)
    - Aszimmetrikus felosztás ($k + m$)
    - Más párok: 4/64-QAM
    - Több réteg: 3 kódszó egy szimbólumban
  ],
)

#speaker-note[
  Végül néhány továbbfejlesztési irány.
  Dekódolás oldalon: érdemes más csatornakódolókat is kipróbálni – rövid LDPC-kódokat, BCJR-rel dekódolt konvolúciós kódokat, térben csatolt kódokat –, mert hosszú, kapacitást közelítő kódoknál az átfedés nem nyerhet, a nyereség rövid kódoknál és nagy jel-zaj viszonynál várható.
  A második irány a belief propagation dekóderbe való belenyúlás: ha a szomszédos kódszavak dekóderei mindkét irányban lágy információt cserélnének, a lánc térben csatolt rendszerként működne.
  A kétirányú és a lágy tisztítás a hibaterjedés két különböző okát kezeli, ezért érdemes együtt is kipróbálni.
  Moduláció oldalon a szabadalom további általánosításai: a kódszó nem csak felezhető, hanem k és m hosszú részekre is bontható; a durva és finom moduláció más párosítású is lehet, például 4/64-QAM; és egy szimbólum akár három kódszóból is állhat.
]

== Összefoglalás

#let kartya(cim, szin, tartalom) = grid.cell(fill: szin.lighten(88%),
  stroke: (top: 3pt + szin), inset: (x: 0.7em, y: 0.5em))[
  #text(fill: szin, weight: "bold", size: 18pt)[#cim]
  #set text(size: 14pt)
  #set list(spacing: 0.5em)
  #tartalom
]

#grid(columns: (1fr, 1fr), column-gutter: 0.8em, row-gutter: 0.6em,
  kartya([Alapötlet], fo)[
    - két kódszó egy 16-QAM szimbólumban: *durva* + *finom*
    - tisztítás: $d = 2 arrow.r 4$
  ],
  kartya([Általánosításaink], kiemel)[
    - *SP-kiosztás:* mindig $d = 4$
    - *kétirányú:* rövidebb hibaterjedés
    - *lágy:* valószínűség döntés helyett
  ],
  kartya([Eredmények], zold)[
    - BPSK–QPSK: a szinkron és az aszinkron megegyező
    - 4/16-QAM: kódfüggő eredmények
    - Az eljárás egy vevő és egy adó esetén is növelheti a megbízhatóságot
  ],
  kartya([Ár és háttér], luma(110))[
    - ráta: $L \/ (L + 1)$
    - SWSC: interferencia­csatorna – *mi: egy felhasználó*
  ],
)
#v(0.4em)
#align(center, block(fill: fo, inset: (x: 1em, y: 0.55em), radius: 6pt, text(fill: white, size: 17pt)[
  A tisztítás akkor nyer, ha a finom bitek ismerete #text(weight: "bold", fill: rgb("#ffd966"))[széthúzza] a durva jelölteket
]))

#speaker-note[
  Összefoglalva három dolgot mutattam be.
  Az alapötlet: két szomszédos kódszó osztozik egy 16-QAM szimbólumon, durva és finom bitek szintjén, és a dekódolt kódszó kivonása 2-ről 4-re növeli a következő kódszó döntési távolságát.
  A mi általánosításaink: a halmazparticionáló kiosztás, amellyel ez a nyereség minden szimbólumnál megvan; a kétirányú dekódolás, amely a hibaterjedést a lánc felére korlátozza; és a lágy tisztítás, amely kemény döntés helyett valószínűségeket ad tovább.
  Az eredmények: BPSK–QPSK-nál a szinkron és az aszinkron moduláció hasonlóan teljesít, 4/16-QAM-nál az eredmény kódfüggő. [TODO: a fő számszerű eredmény]
  Az ára egy L/(L+1)-es rátaveszteség, a szerkezet pedig az irodalomban interferenciacsatornára már ismert – mi egyfelhasználós csatornán vizsgáltuk.
  A fő üzenet: a tisztítás csak akkor ér valamit, ha a finom bitek ismerete széthúzza a durva bitek jelöltjeit.
]
#focus-slide[
  #text(size: 40pt, weight: "bold")[Köszönjük a figyelmet!]
]
