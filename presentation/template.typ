// Plantilla de presentación (conversión a Typst del Beamer tema Madrid, 16:9)
// adaptada a la identidad de la memoria: azul UC3M, Libertinus Serif y logo
// institucional como marca de agua en portada.

#let azuluc3m = rgb("#000e78")
#let margen = (x: 46pt, y: 32pt)
#let azul-suave = azuluc3m.lighten(88%)
#let gris = luma(96)

#let _titulo-corto = state("titulo-corto", "")
#let _subtitulo = state("subtitulo", "")
#let _autor = state("autor", "")
#let _numero = state("numero", "")
#let _fecha = state("fecha", "")
#let _secciones = counter("secciones")

// ---------------------------------------------------------------- utilidades

// Pie de página al estilo Madrid: tres segmentos + numeración.
#let _footer = context {
  set text(size: 10pt, fill: white, font: ("Liberation Sans", "DejaVu Sans"))
  grid(
    columns: (1fr, 1.4fr, 1fr),
    ..(
      (azuluc3m, grid(
        columns: (auto, 1fr), align: (left, right),
        _autor.get(), _numero.get(),
      )),
      (azuluc3m.lighten(18%), grid(
        columns: (auto, 1fr), align: (left, right),
        _titulo-corto.get(), _subtitulo.get(),
      )),
      (
        azuluc3m.lighten(32%),
        [#_fecha.get() #h(1fr) #counter(page).display("1 / 1", both: true)],
      ),
    ).map(((color, contenido)) => box(
      fill: color, width: 100%, height: 100%,
      inset: (x: 10pt), align(horizon, contenido),
    ))
  )
}

// Bolitas de progreso de la cabecera: diapositivas dentro del capítulo
// actual (el progreso entre capítulos ya lo muestra la banda de sección).
#let _progreso = context {
  let pagina = here().page()
  let secs = query(<sec-marca>).map(m => m.location().page())
  let inicios = secs.filter(p => p <= pagina)
  if inicios.len() > 0 {
    let siguientes = secs.filter(p => p > pagina)
    let diapos = query(<diapo-marca>)
      .map(m => m.location().page())
      .filter(p => p > inicios.last() and (
        siguientes.len() == 0 or p < siguientes.first()
      ))
    let actual = diapos.filter(p => p <= pagina).len()
    let total = diapos.len()
    if total > 1 {
      stack(dir: ltr, spacing: 5pt, ..range(1, total + 1).map(i => circle(
        radius: 3pt,
        fill: if i <= actual { white } else { none },
        stroke: 0.7pt + white,
      )))
    }
  }
}

// ------------------------------------------------------------------- montaje

#let uc3m-slides(
  titulo-corto: "",
  subtitulo: "",
  autor: "",
  numero: "",
  fecha: "",
  body,
) = {
  _titulo-corto.update(titulo-corto)
  _subtitulo.update(subtitulo)
  _autor.update(autor)
  _numero.update(numero)
  _fecha.update(fecha)

  set page(paper: "presentation-16-9", margin: 0pt, footer: none, header: none)
  // Cuerpo en la misma familia que la memoria; rótulos y barras en sans.
  set text(font: "Libertinus Serif", size: 18pt, lang: "es")
  set list(marker: ([#text(fill: azuluc3m)[▸]], [#text(fill: gris)[–]]))
  show raw.where(block: true): it => block(
    fill: luma(245), stroke: (left: 2.5pt + azuluc3m),
    inset: 10pt, radius: 2pt, width: 100%,
    text(size: 12pt, it),
  )
  show link: set text(fill: azuluc3m)

  body
}

// ------------------------------------------------------------------- portada

// Espejo minimalista de la portada de la memoria; también sirve de cierre.
#let portada(
  titulacion: [],
  tipo: [Trabajo Fin de Máster],
  titulo: [],
  autor: "",
  tutora: none,
  lugar: "",
  fecha: "",
) = page(
  margin: 0pt,
  background: {
    // Logo UC3M centrado con opacidad baja: logo + velo blanco translúcido.
    place(center + horizon, image("img/old_uc3m_logo.svg", width: 44%))
    place(rect(width: 100%, height: 100%, fill: rgb(255, 255, 255, 228)))
  },
)[
  #set align(center + horizon)
  #block(width: 64%)[
    #text(size: 14pt, fill: luma(40), smallcaps(titulacion))
    #v(1pt)
    #text(size: 13pt, fill: luma(40), tipo)
    #v(10pt)
    #text(size: 24pt, weight: "bold", fill: azuluc3m, titulo)
    #v(10pt)
    #line(length: 26%, stroke: 0.8pt + azuluc3m)
    #v(9pt)
    #text(size: 13pt, fill: luma(40))[Autor] \
    #text(size: 16pt, weight: "bold", autor)
    #if tutora != none {
      v(6pt)
      [#text(size: 13pt, fill: luma(40))[Tutora] \
       #text(size: 16pt, weight: "bold", tutora)]
    }
    #v(6pt)
    #text(size: 12pt, fill: luma(40))[#lugar #sym.dot.c #fecha]
  ]
  // Licencia de la obra (CC BY-NC-ND 4.0), solo el sello.
  #place(bottom + left, dx: margen.x, dy: -margen.y, image("img/creativecommons.png", width: 72pt))
]

// --------------------------------------------------------------- diapositiva

#let diapo(titulo: none, alineado: top, contenido) = page(margin: 0pt)[
  #metadata("diapo") <diapo-marca>
  #if titulo != none {
    block(
      width: 100%, fill: azuluc3m, inset: (x: 18pt, y: 10pt),
      grid(
        columns: (1fr, auto),
        align(horizon, text(
          size: 20pt, weight: "bold", fill: white,
          font: ("Liberation Sans", "DejaVu Sans"), titulo,
        )),
        align(horizon, _progreso),
      ),
    )
  }
  #block(
    width: 100%, height: 1fr,
    inset: margen,
    align(alineado, contenido),
  )
  #block(width: 100%, height: 22pt, _footer)
]

// Diapositiva de sección: avanza el progreso y muestra la banda separadora.
#let seccion(titulo) = {
  _secciones.step()
  page(margin: 0pt)[
    #metadata("seccion") <sec-marca>
    #align(center + horizon)[
      #block(
        width: 100%, fill: azul-suave, inset: (y: 24pt),
        align(center, grid(
          columns: 1, gutter: 12pt,
          text(size: 24pt, weight: "bold", fill: azuluc3m,
            font: ("Liberation Sans", "DejaVu Sans"), titulo),
          context {
            let actual = _secciones.get().first()
            let total = _secciones.final().first()
            stack(dir: ltr, spacing: 6pt, ..range(1, total + 1).map(i => circle(
              radius: 3.5pt,
              fill: if i <= actual { azuluc3m } else { none },
              stroke: 0.8pt + azuluc3m,
            )))
          },
        )),
      )
    ]
    #place(bottom, block(width: 100%, height: 22pt, _footer))
  ]
}

// Dos columnas al estilo beamer.
#let columnas(izquierda, derecha, proporcion: (1fr, 1fr)) = grid(
  columns: proporcion, gutter: 18pt, izquierda, derecha,
)
