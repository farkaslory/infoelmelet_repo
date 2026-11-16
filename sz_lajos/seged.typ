#import "@preview/cetz:0.5.2": canvas, draw
#import "@preview/cetz-plot:0.1.4": chart
#let data-ldpc = (
  ([Soft], 11),
  ([Döntetlen], 5),
  ([Bidir], 4),
  ([Gray], 5),
  ([Szinkron], 2),
  ([SP], 2),
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
  caption: [A 29 LDPC mátrix megoszlása aszerint, hogy melyik eljárás érte el a legkisebb bithibaarányt.],
) <fig:eredmenyek-ldpc>
#let data = (
  ([SP], 7),
  ([Gray], 6),
  ([Soft], 4),
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
  })),