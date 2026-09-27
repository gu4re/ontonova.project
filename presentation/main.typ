#import "template.typ": *
#import "@preview/gantty:0.4.0": gantt

#show: uc3m-slides.with(
  titulo-corto: "OntoNova",
  subtitulo: "Sistema de Gestión del Conocimiento Multilingüe",
  autor: "Diego Picazo García",
  numero: "100549459",
  fecha: "Octubre 2026",
)

// -------------------------------------------------- portada (espejo memoria)
#let slide-portada = portada(
  titulacion: [Máster Universitario en Ingeniería Informática],
  tipo: [Trabajo Fin de Máster],
  titulo: [Diseño e Implementación de un Sistema de Gestión del Conocimiento
    Multilingüe Basado en LLMs como Alternativa Abierta a otros sistemas existentes],
  autor: "Diego Picazo García",
  tutora: "Anabel Fraga Vázquez",
  lugar: "Leganés, Madrid",
  fecha: "2 de octubre de 2026",
)
#slide-portada

// -------------------------------------------------------------------- índice

#diapo(titulo: [Contenidos])[
  #set enum(numbering: n => text(fill: azuluc3m, weight: "bold")[#n.])
  + Introducción
  + Estado del Arte
  + Plan de Proyecto
  + Análisis
  + Diseño
  + Implementación
  + Verificación
  + Propuesta de Exposición Pública
  + Conclusiones
]

// --------------------------------------------------- ejemplos de componentes
// (diapositivas de muestra para validar la plantilla; sustituir por contenido)

#seccion[Introducción]

// ------------------------------------------------------ 1.1 motivación
// Tríptico dibujado con primitivas de Typst: necesidad → reto → solución.

// Pie de figura: única pieza de texto permitida en la diapositiva.
#let pie(clave, resto) = align(center, text(size: 13.5pt, fill: black)[
  #text(weight: "bold", fill: azuluc3m, smallcaps(clave)) \ #resto
])

// Necesidad: océano de datos desordenado que pide estructura (árbol).
#let icono-necesidad = box(width: 210pt, height: 170pt, {
  let puntos = (
    (14pt, 28pt), (44pt, 10pt), (66pt, 44pt), (22pt, 66pt), (52pt, 88pt),
    (6pt, 104pt), (68pt, 118pt), (36pt, 136pt), (62pt, 152pt), (10pt, 146pt),
  )
  for (x, y) in puntos {
    place(dx: x, dy: y, circle(radius: 4pt, fill: luma(80)))
  }
  place(dx: 84pt, dy: 68pt, text(size: 26pt, fill: azuluc3m, sym.arrow.r))
  // Árbol ordenado: raíz, dos hijos y cuatro hojas.
  for (a, b) in (
    ((160pt, 30pt), (138pt, 80pt)), ((160pt, 30pt), (184pt, 80pt)),
    ((138pt, 80pt), (126pt, 130pt)), ((138pt, 80pt), (150pt, 130pt)),
    ((184pt, 80pt), (176pt, 130pt)), ((184pt, 80pt), (198pt, 130pt)),
  ) {
    place(line(start: a, end: b, stroke: 1.4pt + azuluc3m))
  }
  place(dx: 155pt, dy: 25pt, circle(radius: 5pt, fill: azuluc3m))
  for x in (134pt, 180pt) {
    place(dx: x, dy: 76pt, circle(radius: 4pt, fill: azuluc3m))
  }
  for x in (123pt, 147pt, 173pt, 195pt) {
    place(dx: x, dy: 127pt, circle(radius: 3pt, stroke: 1.2pt + azuluc3m))
  }
})

// Reto: burbuja de habla fluida frente a formulario rígido, con fractura.
#let icono-reto = box(width: 210pt, height: 170pt, {
  place(dx: 0pt, dy: 40pt, rect(
    width: 84pt, height: 60pt, radius: 10pt, fill: azul-suave,
  ))
  place(polygon(
    fill: azul-suave, (18pt, 98pt), (36pt, 98pt), (14pt, 118pt),
  ))
  place(curve(
    stroke: 2.2pt + azuluc3m,
    curve.move((14pt, 70pt)),
    curve.cubic((24pt, 56pt), (34pt, 84pt), (44pt, 70pt)),
    curve.cubic((54pt, 56pt), (64pt, 84pt), (72pt, 70pt)),
  ))
  // Barra inclinada de confrontación entre ambos mundos.
  place(line(
    start: (114pt, 36pt), end: (94pt, 106pt),
    stroke: (paint: azuluc3m, thickness: 3pt, cap: "round"),
  ))
  place(dx: 122pt, dy: 40pt, rect(
    width: 84pt, height: 60pt, stroke: 2pt + luma(80),
  ))
  for x in (150pt, 178pt) {
    place(line(start: (x, 40pt), end: (x, 100pt), stroke: 1pt + luma(80)))
  }
  place(line(start: (122pt, 70pt), end: (206pt, 70pt), stroke: 1pt + luma(80)))
})

// Solución: la IA (chip) circula por una vía con guardarraíles hacia la
// ontología (grafo en el horizonte).
#let icono-solucion = box(width: 210pt, height: 170pt, {
  place(line(start: (48pt, 165pt), end: (88pt, 25pt), stroke: 3pt + azuluc3m))
  place(line(start: (168pt, 165pt), end: (128pt, 25pt), stroke: 3pt + azuluc3m))
  place(line(
    start: (108pt, 160pt), end: (108pt, 42pt),
    stroke: (paint: luma(80), thickness: 1.5pt, dash: "dashed"),
  ))
  // Tarjeta GPU de IA: carcasa apaisada, ventilador, soporte y conector.
  place(dx: 78pt, dy: 82pt, rect(width: 4pt, height: 26pt, fill: luma(80)))
  place(dx: 82pt, dy: 80pt, rect(
    width: 52pt, height: 30pt, radius: 4pt, fill: azuluc3m,
  ))
  place(dx: 88pt, dy: 86pt, circle(radius: 9pt, stroke: 2pt + white))
  place(dx: 94.5pt, dy: 92.5pt, circle(radius: 2.5pt, fill: white))
  place(dx: 106pt, dy: 80pt, box(
    width: 28pt, height: 30pt,
    align(center + horizon, text(
      size: 12pt, weight: "bold", fill: white,
      font: ("Liberation Sans", "DejaVu Sans"),
    )[IA]),
  ))
  for x in (88pt, 96pt, 104pt, 112pt, 120pt) {
    place(dx: x, dy: 110pt, rect(width: 4pt, height: 5pt, fill: luma(80)))
  }
  // Línea de meta a cuadros con la misma perspectiva que la vía: cada
  // celda es un trapecio interpolado entre los dos guardarraíles.
  {
    let borde(y) = {
      let ancho = (165 - y) / 140 * 40
      (48 + ancho, 168 - ancho)
    }
    let filas = (27, 31.5, 37)
    for f in range(2) {
      let (i0, d0) = borde(filas.at(f))
      let (i1, d1) = borde(filas.at(f + 1))
      for c in range(8) {
        if calc.even(f + c) {
          place(polygon(
            fill: azuluc3m,
            ((i0 + (d0 - i0) * c / 8) * 1pt, filas.at(f) * 1pt),
            ((i0 + (d0 - i0) * (c + 1) / 8) * 1pt, filas.at(f) * 1pt),
            ((i1 + (d1 - i1) * (c + 1) / 8) * 1pt, filas.at(f + 1) * 1pt),
            ((i1 + (d1 - i1) * c / 8) * 1pt, filas.at(f + 1) * 1pt),
          ))
        }
      }
    }
    let (i0, d0) = borde(filas.first())
    let (i1, d1) = borde(filas.last())
    place(polygon(
      stroke: 0.6pt + luma(80),
      (i0 * 1pt, filas.first() * 1pt), (d0 * 1pt, filas.first() * 1pt),
      (d1 * 1pt, filas.last() * 1pt), (i1 * 1pt, filas.last() * 1pt),
    ))
  }
  // …y OntoNova como destino del trayecto.
  place(dx: 95pt, dy: -1pt, image("img/ontonova.svg", width: 26pt))
})

#diapo(titulo: [Motivación])[
  // Rejilla a altura completa: los iconos se centran en el espacio libre y
  // la fila de pies queda anclada abajo, a la misma altura en todo el deck.
  #box(width: 100%, height: 100%, align(center, grid(
    columns: (auto, auto, auto, auto, auto),
    rows: (1fr, auto),
    column-gutter: 8pt, row-gutter: 14pt,
    align: (columna, fila) => center + if fila == 0 { horizon } else { top },
    icono-necesidad,
    text(size: 34pt, fill: azuluc3m, sym.arrow.r),
    icono-reto,
    text(size: 34pt, fill: azuluc3m, sym.arrow.r),
    icono-solucion,
    pie("Necesidad", [Estructurar el océano de datos]),
    [],
    pie("Reto", [Creatividad humana frente a semántica inflexible]),
    [],
    pie("Solución híbrida", [IA generativa con guardarraíles]),
  )))
]

// ------------------------------------------------------- 1.2 objetivos
// Diana con dardo: el objetivo principal como meta (banderín) y los seis
// secundarios O1–O6 orbitando con líneas guía.

// Diana de objetivos, reutilizada en Conclusiones con cumplido: true, que
// añade una insignia de check a cada nodo y al banderín del principal.
#let diapo-diana(titulo, etiquetas, cumplido: false) = {
  let cx = 375
  let cy = 170
  // Etiqueta secundaria: nodo con el identificador + texto a un lado.
  let nodo-obj(id, y, texto, lado) = {
    let dot-x = if lado == left { 240 } else { 510 }
    place(dx: (dot-x - 10) * 1pt, dy: (y - 10) * 1pt,
      circle(radius: 10pt, fill: azuluc3m))
    place(dx: (dot-x - 10) * 1pt, dy: (y - 10) * 1pt, box(
      width: 20pt, height: 20pt,
      align(center + horizon, text(
        size: 8pt, weight: "bold", fill: white,
        font: ("Liberation Sans", "DejaVu Sans"), id,
      )),
    ))
    if cumplido {
      // Insignia de check en la esquina superior exterior del nodo (lado
      // opuesto al texto, para no pisarlo).
      let bx = dot-x + if lado == left { 10 } else { -10 }
      place(dx: (bx - 7) * 1pt, dy: (y - 17) * 1pt,
        circle(radius: 7pt, fill: white, stroke: 1.5pt + azuluc3m))
      place(line(start: ((bx - 3.5) * 1pt, (y - 10) * 1pt),
        end: ((bx - 1) * 1pt, (y - 7.5) * 1pt),
        stroke: (paint: azuluc3m, thickness: 1.8pt, cap: "round")))
      place(line(start: ((bx - 1) * 1pt, (y - 7.5) * 1pt),
        end: ((bx + 3.5) * 1pt, (y - 13) * 1pt),
        stroke: (paint: azuluc3m, thickness: 1.8pt, cap: "round")))
    }
    let text-x = if lado == left { 55 } else { 525 }
    // El texto se pega al nodo: alineado a la derecha en el lado izquierdo
    // y a la izquierda en el derecho.
    let borde = if lado == left { right } else { left }
    place(dx: text-x * 1pt, dy: (y - 20) * 1pt, box(
      width: 170pt, height: 40pt,
      align(borde + horizon, text(size: 13.5pt, fill: black, texto)),
    ))
  }
  // Línea guía del nodo al borde de la diana.
  let guia(desde, hasta) = place(line(
    start: (desde.at(0) * 1pt, desde.at(1) * 1pt),
    end: (hasta.at(0) * 1pt, hasta.at(1) * 1pt),
    stroke: 0.8pt + luma(80),
  ))

  diapo(titulo: titulo, alineado: top)[
    // Toda la composición usa coordenadas absolutas; el move la sube en
    // bloque para equilibrar el aire entre cabecera y pie.
    #move(dy: -20pt, box(width: 100%, height: 100%, {
      // Diana en perspectiva: disco tumbado (elipses concéntricas) con
      // grosor en azul oscurecido sólido — sin sombras ni degradados.
      place(dx: (375 - 115) * 1pt, dy: (225 - 39 + 9) * 1pt,
        ellipse(width: 230pt, height: 78pt, fill: azuluc3m.darken(28%)))
      for (rx, ry, color) in (
        (115, 39, azuluc3m), (89, 30, white), (63, 21, azuluc3m),
        (37, 13, white), (15, 5, azuluc3m),
      ) {
        place(dx: (375 - rx) * 1pt, dy: (225 - ry) * 1pt,
          ellipse(width: rx * 2pt, height: ry * 2pt, fill: color))
      }
      // Dardo vertical con carcasa blanca: en Objetivos queda en vuelo,
      // a punto de caer, y en Consecución aparece clavado en el centro.
      let fin-asta = if cumplido { 200 } else { 148 }
      let apice = if cumplido { 223 } else { 170 }
      place(line(
        start: (375pt, 55pt), end: (375pt, fin-asta * 1pt),
        stroke: (paint: white, thickness: 6.5pt, cap: "round"),
      ))
      place(line(
        start: (375pt, 55pt), end: (375pt, fin-asta * 1pt),
        stroke: (paint: luma(80), thickness: 3pt, cap: "round"),
      ))
      place(polygon(
        fill: luma(80), stroke: 1.5pt + white,
        (375pt, apice * 1pt), (368pt, (apice - 22) * 1pt),
        (382pt, (apice - 22) * 1pt),
      ))
      place(polygon(fill: luma(80), stroke: 1pt + white,
        (374pt, 45pt), (364pt, 35pt), (364pt, 49pt), (374pt, 59pt)))
      place(polygon(fill: luma(80), stroke: 1pt + white,
        (376pt, 45pt), (386pt, 35pt), (386pt, 49pt), (376pt, 59pt)))
      // Objetivos secundarios: las seis guías convergen sobre el asta del
      // dardo, siempre por encima del disco para no cruzar los anillos.
      let anclas = if cumplido { (75, 130, 178) } else { (70, 108, 142) }
      guia((249, 45), (368, anclas.at(0)))
      guia((249, 115), (368, anclas.at(1)))
      guia((249, 185), (368, anclas.at(2)))
      guia((382, anclas.at(0)), (501, 45))
      guia((382, anclas.at(1)), (501, 115))
      guia((382, anclas.at(2)), (501, 185))
      nodo-obj("O1", 45, etiquetas.at(0), left)
      nodo-obj("O2", 115, etiquetas.at(1), left)
      nodo-obj("O3", 185, etiquetas.at(2), left)
      nodo-obj("O4", 45, etiquetas.at(3), right)
      nodo-obj("O5", 115, etiquetas.at(4), right)
      nodo-obj("O6", 185, etiquetas.at(5), right)
      // Objetivo principal: banderín de meta bajo la diana.
      place(dx: 0pt, dy: 292pt, box(width: 100%, align(center, grid(
        columns: (auto, auto), column-gutter: 10pt, align: horizon,
        box(width: 20pt, height: 30pt, {
          place(line(start: (3pt, 2pt), end: (3pt, 28pt),
            stroke: (paint: azuluc3m, thickness: 2pt, cap: "round")))
          place(polygon(fill: azuluc3m, (4pt, 3pt), (20pt, 8pt), (4pt, 13pt)))
        }),
        text(size: 15pt, weight: "bold", fill: azuluc3m)[Sistema de gestión del
          conocimiento multilingüe, abierto, accesible y basado en LLM#if cumplido [ #sym.checkmark]],
      ))))
    }))
  ]
}
#diapo-diana([Objetivos], (
  [Nuevos conocimientos en IA],
  [Menor barrera de entrada a la elaboración de ontologías],
  [Multilingüe: español e inglés],
  [Cumplimiento del marco regulatorio europeo],
  [Arquitectura _software_ con estándares],
  [Alineamiento con los ODS],
))

#seccion[Estado del Arte]

// --------------------------------------- 2.1a crítica a la web sintáctica
// La misma página vista por el humano (entiende), por la máquina (solo ve
// la forma) y en la Web 3.0 (grafo semántico compartido).

// Ventana de navegador en tres modos: humano, maquina o semantico.
#let navegador(modo) = box(width: 130pt, height: 110pt, {
  // La barra va debajo del marco para no tapar el grosor del borde superior.
  place(rect(width: 130pt, height: 16pt, radius: (top: 4pt), fill: azul-suave))
  place(rect(width: 130pt, height: 110pt, radius: 4pt, stroke: 1.5pt + azuluc3m))
  for i in range(3) {
    place(dx: (8 + i * 8) * 1pt, dy: 6pt, circle(radius: 2pt, fill: luma(80)))
  }
  if modo == "humano" or modo == "semantico" {
    place(dx: 10pt, dy: 26pt, rect(width: 80pt, height: 8pt, fill: azuluc3m))
    for (y, ancho) in ((44, 110), (54, 104), (64, 96), (74, 110), (84, 62)) {
      place(dx: 10pt, dy: y * 1pt,
        rect(width: ancho * 1pt, height: 3.5pt, fill: luma(80)))
    }
  }
  if modo == "maquina" {
    // La máquina delimita las cajas a la perfección, pero sin significado.
    for (x, y, an, al, tam) in (
      (10, 24, 80, 12, 9), (10, 44, 110, 36, 14), (10, 88, 70, 14, 9),
    ) {
      place(dx: x * 1pt, dy: y * 1pt, rect(
        width: an * 1pt, height: al * 1pt,
        stroke: (paint: luma(80), thickness: 1pt, dash: "dashed"),
      ))
      place(dx: x * 1pt, dy: y * 1pt, box(
        width: an * 1pt, height: al * 1pt,
        align(center + horizon, text(
          size: tam * 1pt, weight: "bold", fill: luma(80),
          font: ("Liberation Sans", "DejaVu Sans"), "?",
        )),
      ))
    }
  }
  if modo == "semantico" {
    // Grafo de conocimiento superpuesto al contenido.
    for (a, b) in (
      ((20pt, 32pt), (44pt, 64pt)), ((44pt, 64pt), (94pt, 56pt)),
      ((44pt, 64pt), (64pt, 92pt)), ((94pt, 56pt), (64pt, 92pt)),
    ) {
      place(line(start: a, end: b, stroke: 1.4pt + azuluc3m))
    }
    for (x, y) in ((16, 28), (40, 60), (90, 52), (60, 88)) {
      place(dx: x * 1pt, dy: y * 1pt, circle(
        radius: 4pt, fill: white, stroke: 1.6pt + azuluc3m))
    }
  }
})

// Chip de máquina reutilizable (mismo motivo que en Motivación).
#let chip(x, y, lado) = {
  place(dx: x * 1pt, dy: y * 1pt, rect(
    width: lado * 1pt, height: lado * 1pt, radius: 3pt, fill: azuluc3m))
  place(dx: x * 1pt, dy: y * 1pt, box(
    width: lado * 1pt, height: lado * 1pt,
    align(center + horizon, text(
      size: (lado * 0.3) * 1pt, weight: "bold", fill: white,
      font: ("Liberation Sans", "DejaVu Sans"), "CPU",
    )),
  ))
  for i in range(3) {
    let py = y + 4 + i * ((lado - 8) / 2)
    place(dx: (x - 6) * 1pt, dy: py * 1pt,
      rect(width: 6pt, height: 3pt, fill: luma(80)))
    place(dx: (x + lado) * 1pt, dy: py * 1pt,
      rect(width: 6pt, height: 3pt, fill: luma(80)))
  }
}

// Ojo humano reutilizable: párpados almendrados (dos arcos Bézier que se
// unen en los lagrimales), iris anular y pupila.
#let ojo(x, y, ancho) = {
  let c = y + ancho * 0.3
  place(curve(
    stroke: 2pt + azuluc3m,
    curve.move((x * 1pt, c * 1pt)),
    curve.cubic(
      ((x + 0.3 * ancho) * 1pt, (c - 0.4 * ancho) * 1pt),
      ((x + 0.7 * ancho) * 1pt, (c - 0.4 * ancho) * 1pt),
      ((x + ancho) * 1pt, c * 1pt),
    ),
    curve.cubic(
      ((x + 0.7 * ancho) * 1pt, (c + 0.4 * ancho) * 1pt),
      ((x + 0.3 * ancho) * 1pt, (c + 0.4 * ancho) * 1pt),
      (x * 1pt, c * 1pt),
    ),
  ))
  place(dx: (x + ancho / 2 - 0.16 * ancho) * 1pt,
    dy: (c - 0.16 * ancho) * 1pt,
    circle(radius: (0.16 * ancho) * 1pt, stroke: 2pt + azuluc3m))
  place(dx: (x + ancho / 2 - 0.08 * ancho) * 1pt,
    dy: (c - 0.08 * ancho) * 1pt,
    circle(radius: (0.08 * ancho) * 1pt, fill: azuluc3m))
}

// Columna de observadores compartida por los tres paneles: mismas ranuras
// (ojo arriba, chip en medio, veredicto abajo); lo ausente deja su hueco.
// El conjunto navegador + columna abarca x = 14..197, centrado en la caja
// de 210pt para que los pies inferiores queden alineados con los paneles.
#let columna-observador(con-ojo: false, con-chip: false, veredicto: "ok") = {
  if con-ojo { ojo(160, 36, 34) }
  if con-chip { chip(165, 68, 24) }
  if veredicto == "ok" {
    place(line(start: (163pt, 116pt), end: (172pt, 126pt),
      stroke: (paint: azuluc3m, thickness: 3pt, cap: "round")))
    place(line(start: (172pt, 126pt), end: (191pt, 104pt),
      stroke: (paint: azuluc3m, thickness: 3pt, cap: "round")))
  } else {
    place(line(start: (166pt, 104pt), end: (188pt, 126pt),
      stroke: (paint: luma(80), thickness: 3pt, cap: "round")))
    place(line(start: (188pt, 104pt), end: (166pt, 126pt),
      stroke: (paint: luma(80), thickness: 3pt, cap: "round")))
  }
}

#let icono-sintactica = box(width: 210pt, height: 170pt, {
  place(dx: 14pt, dy: 25pt, navegador("humano"))
  columna-observador(con-ojo: true, veredicto: "ok")
})

#let icono-critica = box(width: 210pt, height: 170pt, {
  place(dx: 14pt, dy: 25pt, navegador("maquina"))
  columna-observador(con-chip: true, veredicto: "ko")
})

#let icono-semantica = box(width: 210pt, height: 170pt, {
  place(dx: 14pt, dy: 25pt, navegador("semantico"))
  columna-observador(con-ojo: true, con-chip: true, veredicto: "ok")
})

#diapo(titulo: [De la Web Sintáctica a la Semántica])[
  #box(width: 100%, height: 100%, align(center, grid(
    columns: (auto, auto, auto, auto, auto),
    rows: (1fr, auto),
    column-gutter: 8pt, row-gutter: 14pt,
    align: (columna, fila) => center + if fila == 0 { horizon } else { top },
    icono-sintactica,
    text(size: 34pt, fill: azuluc3m, sym.arrow.r),
    icono-critica,
    text(size: 34pt, fill: azuluc3m, sym.arrow.r),
    icono-semantica,
    pie("Web sintáctica", [El humano entiende el contenido]),
    [],
    pie("Crítica", [Los ordenadores procesan la forma, no el significado]),
    [],
    pie("Web 3.0", [Estructura y significado para cooperar]),
  )))
]

// ------------------------------------------- 2.1b la pila de la web 3.0
// Niveles apilados al estilo de la «layer cake» de la web semántica, con
// URI como barra transversal de identificación.

#diapo(titulo: [Pila de la Web 3.0], alineado: top)[
  #box(width: 100%, height: 100%, {
    let cx = 355
    let niveles = (
      ("XML", "Sintaxis y estructura del formato", 460),
      ("RDF", "Significado en tripletas de sujeto, verbo y objeto", 410),
      ("Ontología", "Relaciones entre términos", 360),
      ("Taxonomía y reglas", "Clasificación y capacidad deductiva", 310),
      ("OWL", "Lenguaje formal de lógica estricta", 260),
    )
    for (i, nivel) in niveles.enumerate() {
      let (clave, desc, ancho) = nivel
      let y = 246 - i * 54
      let pleno = calc.even(i)
      place(dx: (cx - ancho / 2) * 1pt, dy: y * 1pt, box(
        width: ancho * 1pt, height: 46pt, radius: 4pt,
        fill: if pleno { azuluc3m } else { azul-suave },
        align(center + horizon, stack(spacing: 5pt,
          text(size: 15pt, weight: "bold",
            fill: if pleno { white } else { azuluc3m },
            font: ("Liberation Sans", "DejaVu Sans"), clave),
          text(size: 11pt,
            fill: if pleno { white } else { azuluc3m },
            font: ("Liberation Sans", "DejaVu Sans"), desc),
        )),
      ))
    }
    // Flecha ascendente: cada nivel se apoya en el anterior.
    place(line(start: (105pt, 292pt), end: (105pt, 46pt),
      stroke: 1.5pt + luma(80)))
    place(polygon(fill: luma(80), (105pt, 32pt), (99pt, 46pt), (111pt, 46pt)))
    // URI: identificación unívoca transversal a los niveles semánticos.
    place(dx: 610pt, dy: 30pt, box(
      width: 38pt, height: 208pt, radius: 4pt, stroke: 1.5pt + azuluc3m,
      align(center + horizon, rotate(-90deg, reflow: true, text(
        size: 13pt, fill: azuluc3m,
        font: ("Liberation Sans", "DejaVu Sans"),
      )[#text(weight: "bold")[URI] : Identificador de Recursos Uniforme])),
    ))
    for i in range(1, 5) {
      let ancho = niveles.at(i).at(2)
      let ymid = 246 - i * 54 + 23
      place(line(
        start: ((cx + ancho / 2) * 1pt, ymid * 1pt),
        end: (610pt, ymid * 1pt),
        stroke: 0.8pt + luma(80),
      ))
    }
  })
]

// ---------------------------------------- 2.2 inferencia del conocimiento
// Protégé (valorado, pero con barrera de entrada) frente a los transformers
// (el punto de inflexión que este trabajo adopta, marcado con el banderín).

// Protégé: ventana con jerarquía textual rígida y una valla de barrera.
#let icono-protege = box(width: 210pt, height: 230pt, {
  place(dx: 20pt, dy: 38pt, {
    place(rect(width: 170pt, height: 150pt, radius: 4pt, fill: white,
      stroke: 1.5pt + azuluc3m))
    place(rect(width: 170pt, height: 16pt, radius: (top: 4pt), fill: azul-suave))
    place(rect(width: 170pt, height: 150pt, radius: 4pt,
      stroke: 1.5pt + azuluc3m))
    for i in range(3) {
      place(dx: (8 + i * 8) * 1pt, dy: 6pt, circle(radius: 2pt, fill: luma(80)))
    }
    for (sangria, y, ancho) in (
      (10, 28, 70), (24, 48, 84), (38, 68, 62),
      (24, 88, 90), (38, 108, 70), (52, 128, 52),
    ) {
      place(dx: sangria * 1pt, dy: y * 1pt,
        rect(width: 7pt, height: 7pt, stroke: 1.4pt + azuluc3m))
      place(dx: (sangria + 13) * 1pt, dy: (y + 2) * 1pt,
        rect(width: ancho * 1pt, height: 3.5pt, fill: luma(80)))
    }
  })
  // Valla: la barrera de entrada que exige un ingeniero cualificado.
  // Los postes tocan el borde inferior (230) para alinear con el resto.
  for x in (55pt, 100pt, 145pt) {
    place(dx: x, dy: 194pt, rect(width: 5pt, height: 36pt, fill: luma(80)))
  }
  for y in (202pt, 216pt) {
    place(dx: 42pt, dy: y, rect(width: 121pt, height: 4pt, fill: luma(80)))
  }
})

// Punto de inflexión matemático: curva logística en S cuyo cambio de
// concavidad se marca con un punto hueco, como en las gráficas de f(x).
#let icono-inflexion = box(width: 130pt, height: 230pt, {
  // Ejes de la gráfica, con la base tocando el borde inferior (230).
  place(line(start: (12pt, 230pt), end: (122pt, 230pt),
    stroke: 1.5pt + luma(80)))
  place(line(start: (12pt, 230pt), end: (12pt, 73pt),
    stroke: 1.5pt + luma(80)))
  // Curva en S: cóncava hacia arriba hasta el punto medio, hacia abajo después.
  place(curve(
    stroke: (paint: azuluc3m, thickness: 2.5pt, cap: "round"),
    curve.move((16pt, 221pt)),
    curve.cubic((52pt, 219pt), (56pt, 189pt), (66pt, 155pt)),
    curve.cubic((76pt, 121pt), (80pt, 91pt), (116pt, 89pt)),
  ))
  // Tangente discontinua por el punto de inflexión, como en f(x).
  place(line(
    start: (44pt, 203pt), end: (88pt, 107pt),
    stroke: (paint: luma(80), thickness: 1.5pt, dash: "dashed"),
  ))
  // Punto de inflexión sin relleno en (66, 155).
  place(dx: 60.5pt, dy: 149.5pt,
    circle(radius: 5.5pt, fill: white, stroke: 2pt + azuluc3m))
})

// Transformers: figura de la memoria, con el banderín de la vía elegida.
#let icono-transformers = box(width: 190pt, height: 230pt, {
  place(box(width: 165pt, height: 230pt, align(center + horizon,
    image("img/transformers.png", fit: "contain", width: 100%, height: 100%))))
  place(dx: 168pt, dy: 4pt, {
    place(line(start: (3pt, 2pt), end: (3pt, 28pt),
      stroke: (paint: azuluc3m, thickness: 2pt, cap: "round")))
    place(polygon(fill: azuluc3m, (4pt, 3pt), (20pt, 8pt), (4pt, 13pt)))
  })
})

#diapo(titulo: [Inferencia de Conocimiento del Presente])[
  #box(width: 100%, height: 100%, align(center, grid(
    columns: (auto, auto, auto),
    rows: (1fr, auto),
    column-gutter: 26pt, row-gutter: 12pt,
    align: (columna, fila) => center + if fila == 0 { horizon } else { top },
    icono-protege,
    icono-inflexion,
    icono-transformers,
    pie("Protégé", [Estándar _de facto_ con barrera de entrada]),
    pie("IA generativa", [Punto de inflexión]),
    pie("Transformers", [Inferencia semántica sobre texto libre]),
  )))
]

// ------------------------------------------------- 2.3 modo json (fig. 2.2)

#diapo(titulo: [De la Alucinación al Determinismo], alineado: center + horizon)[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,),
    rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 88%, height: 100%,
      image("img/jsonmode.png", fit: "contain", width: 100%, height: 100%)),
    pie("Modo JSON", [Sintaxis válida sin contrato de datos fiable]),
  ))
]

// ---------------------------------- 2.3 salidas estructuradas (fig. 2.3)

#diapo(titulo: [De la Alucinación al Determinismo], alineado: center + horizon)[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,),
    rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 88%, height: 100%,
      image("img/structuredoutputs.png", fit: "contain", width: 100%, height: 100%)),
    pie("Salidas estructuradas", [El esquema JSON como contrato de datos estricto]),
  ))
]

// ------------------------------- 2.4/2.5/2.6 estudio de alternativas
// Las tres comparativas de la memoria, con la convención elegido-al-final:
// la última fila (la opción adoptada) va destacada en azul suave y negrita.

// eleccion: true destaca la última fila (azul suave + negrita); anchos y
// alinear permiten fijar columnas y alineaciones por columna.
#let tabla-comp(cabecera, eleccion: true, anchos: none, alinear: left + horizon, compacta: false, tamano: 13.5pt, ..filas) = {
  let filas = filas.pos()
  table(
    columns: if anchos != none { anchos } else { cabecera.len() },
    inset: if compacta { (x: 10pt, y: 6.5pt) } else { (x: 12pt, y: 10pt) },
    align: alinear,
    stroke: (x, y) => if y > 0 { (top: 0.6pt + luma(80)) },
    fill: (x, y) => if y == 0 { azuluc3m }
      else if eleccion and y == filas.len() { azul-suave },
    ..cabecera.map(c => text(
      size: 13.5pt, weight: "bold", fill: white,
      font: ("Liberation Sans", "DejaVu Sans"), c,
    )),
    ..filas.enumerate().map(((i, fila)) => fila.map(celda => {
      if eleccion and i == filas.len() - 1 { strong(text(size: tamano, celda)) }
      else { text(size: tamano, celda) }
    })).flatten(),
  )
}

#diapo(titulo: [Estudio de Alternativas], alineado: center + horizon)[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, tabla-comp(
      ([Herramienta], [Paradigma], [Control flujo], [Transparencia],
        [Memoria], [Multi-agente]),
      ([LangChain], [Secuencial], [Medio], [Media], [Básica], [Parcial]),
      ([AutoGPT], [Autónomo], [Bajo], [Baja], [Limitada], [Parcial]),
      ([CrewAI], [Colaborativo], [Medio], [Media], [Interna], [Nativo]),
      ([LangGraph], [Grafo], [Muy alto], [Alta], [Persistente], [Nativo]),
    )),
    pie("Orquestación", [LangGraph destaca persistencia y soporte multi-agente]),
  ))
]

#diapo(titulo: [Estudio de Alternativas], alineado: center + horizon)[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, tabla-comp(
      ([Paradigma], [Comunicación], [Estado], [Latencia], [Complejidad],
        [Streaming]),
      ([REST], [Cliente #sym.arrow.r Servidor], [Sin estado], [Alta],
        [Baja], [Limitado]),
      ([Polling], [Cliente #sym.arrow.l.r Servidor], [Sin estado], [Media],
        [Media], [Limitado]),
      ([WebSockets], [Cliente #sym.arrow.l.r Servidor], [Persistente],
        [Baja], [Alta], [Continuo]),
      ([SSE], [Servidor #sym.arrow.r Cliente], [Sin estado], [Baja],
        [Media], [Incremental]),
    )),
    pie("Comunicación", [SSE reúne los eventos asíncronos unidireccionales y sin estado necesario]),
  ))
]

#diapo(titulo: [Estudio de Alternativas], alineado: center + horizon)[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, tabla-comp(
      ([Herramienta], [Determinismo], [Gestión errores], [Multilingüe],
        [Usuario final]),
      ([Protégé], [Estricto], [Manual], [No], [Ingeniero]),
      ([ChatGPT], [Estocástico], [Manual], [Sí], [Universal]),
      ([OntoGPT], [Estricto], [Manual], [No], [Ingeniero]),
      ([OntoNova], [Estricto], [Autónoma], [Sí], [Experto]),
    )),
    pie("Modelado ontológico", [OntoNova reúne las métricas objetivo del
      sector]),
  ))
]

#seccion[Plan de Proyecto]

// ---------------------------------------------------- 3.1 metodología
// Figura 3.1 (cascada) junto a la tabla 3.1 (horas por fase).

#diapo(titulo: [Metodología])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, grid(
      columns: (auto, auto), column-gutter: 34pt, align: center + horizon,
      box(width: 360pt, image("img/waterfall.png", fit: "contain", width: 100%)),
      tabla-comp(
        eleccion: false,
        alinear: (left + horizon, right + horizon, right + horizon),
        ([Fase], [Horas], [% del total]),
        ([Análisis de Requisitos], [66], [18,75]),
        ([Diseño de la Arquitectura], [35], [9,94]),
        ([Proceso de Aprendizaje], [67], [19,04]),
        ([Implementación y Pruebas], [96], [27,27]),
        ([Informe], [88], [25,00]),
        ([*Total*], [*352*], [*100,00*]),
      ),
    )),
    pie("Metodología en cascada", [352 horas repartidas en cinco fases]),
  ))
]

// ------------------------------------------ 3.2 estimación de tiempo
// El Gantt de la memoria (gantty + gantt.yaml), nativo en apaisado.

#diapo(titulo: [Estimación de tiempo])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    // gantty dibuja a tamaño natural (pensado para A4): se reescala para
    // encajar el diagrama apaisado completo en el área útil.
    align(center + horizon, scale(48%, reflow: true, gantt(yaml("gantt.yaml")))),
    pie("Distribución de la carga de trabajo", [De los requisitos
      a la entrega]),
  ))
]

// ------------------------------------------------------ 3.3 presupuesto
// Tablas 3.2 (información del proyecto) y 3.6 (balance total).

#diapo(titulo: [Presupuesto])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, grid(
      columns: (auto, auto), column-gutter: 34pt, align: center + horizon,
      tabla-comp(
        eleccion: false,
        anchos: (auto, 330pt),
        compacta: true,
        ([Campo], [Descripción]),
        ([*Título*], [Diseño e Implementación de un Sistema de Gestión del
          Conocimiento Multilingüe Basado en LLMs como Alternativa Abierta a
          otros sistemas existentes]),
        ([*Autor*], [Diego Picazo García]),
        ([*Departamento*], [Informática]),
        ([*Inicio*], [03/10/2025]),
        ([*Fin*], [03/09/2026]),
        ([*Duración*], [11 meses]),
        ([*Presupuesto*], [13.000,00#sym.euro]),
      ),
      grid(rows: (auto, auto), row-gutter: 10pt, align: left,
        tabla-comp(
          alinear: (left + horizon, right + horizon),
          ([Descripción], [Total]),
          ([Costes directos], [12.501,59#sym.euro]),
          ([Costes indirectos], [440,00#sym.euro]),
          ([*Costes totales*], [*12.941,59#sym.euro*]),
          ([Presupuesto inicial], [13.000,00#sym.euro]),
          ([Superávit], [#sym.plus 268,41#sym.euro#super[\*]]),
        ),
        text(size: 12pt)[#super[\*] Incluye el remanente de la reserva de \
          gastos imprevistos.],
      ),
    )),
    pie("Información del proyecto", [Un superávit positivo refuerza la viabilidad de la planificación]),
  ))
]

// -------------------------------------- 3.3.1/3.3.2 marco regulatorio
// Órbita de dos anillos alrededor de OntoNova: los reglamentos vinculantes
// orbitan cerca (azul pleno) y los estándares adoptados, lejos (azul suave).

#let pildora(x, y, primaria, sigla, desc) = place(
  dx: (x - 62) * 1pt, dy: (y - 21) * 1pt,
  box(
    width: 124pt, height: 42pt, radius: 6pt,
    fill: if primaria { azuluc3m } else { azul-suave },
    align(center + horizon, stack(spacing: 3pt,
      text(size: 12.5pt, weight: "bold",
        fill: if primaria { white } else { azuluc3m },
        font: ("Liberation Sans", "DejaVu Sans"), sigla),
      text(size: 9.5pt,
        fill: if primaria { white } else { azuluc3m },
        font: ("Liberation Sans", "DejaVu Sans"), desc),
    )),
  ),
)

// Leyenda con testigo de color, en la línea de pies del deck.
#let leyenda(color, clave, resto) = align(center, text(size: 13pt, fill: black)[
  #box(baseline: 1.5pt, circle(radius: 5pt, fill: color))
  #text(weight: "bold", fill: azuluc3m, smallcaps(clave)) \ #resto
])

#diapo(titulo: [Marco Regulatorio])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 100%, height: 100%, {
      // Anillos orbitales discontinuos.
      place(dx: 45pt, dy: 23pt, ellipse(width: 660pt, height: 244pt,
        stroke: (paint: luma(80), thickness: 1pt, dash: "dashed")))
      place(dx: 225pt, dy: 75pt, ellipse(width: 300pt, height: 140pt,
        stroke: (paint: luma(80), thickness: 1pt, dash: "dashed")))
      // OntoNova en el centro de gravedad.
      place(dx: 351pt, dy: 116pt, image("img/ontonova.svg", width: 48pt))
      place(dx: 320pt, dy: 168pt, box(width: 110pt, align(center, text(
        size: 14pt, weight: "bold", fill: azuluc3m,
        font: ("Liberation Sans", "DejaVu Sans"))[OntoNova])))
      // Anillo interior: reglamentos vinculantes.
      pildora(375, 80, true, "RGPD", "Protección de datos")
      pildora(245, 180, true, "LOPDGDD", "Protección de datos")
      pildora(505, 180, true, "EU AI Act", "Regulación de la IA")
      // Anillo exterior: estándares y marcos técnicos.
      pildora(375, 23, false, "OSD", "Iniciativa de código abierto")
      pildora(150, 60, false, "ISO/IEC 21778", "JSON")
      pildora(600, 60, false, "ISO/IEC 21838", "Ontologías de nivel superior")
      pildora(64, 165, false, "ISO/IEC 27001", "Seguridad en los datos")
      pildora(686, 165, false, "ISO/IEC 42001", "Gestión de IA")
      pildora(210, 250, false, "ISO/IEC 25002", "Sello de calidad")
      pildora(540, 250, false, "OWASP Top 10", "GenIA/LLM")
    }),
    grid(columns: (1fr, 1fr),
      leyenda(azuluc3m, "Reglamentos y Leyes", [Cumplimiento vinculante europeo y español]),
      leyenda(azul-suave, "Estándares y marcos", [Adopción técnica]),
    ),
  ))
]

// ------------------------------------------------------ 3.3.3 licencias
// Tarjeta de la EUPL 1.2 (FOSS, registro de PI en trámite) junto a la
// tabla 3.8 de licencias de complementos.

#let tarjeta-eupl = box(width: 300pt, {
  box(
    width: 100%, radius: 8pt, stroke: 1.5pt + azuluc3m, clip: true,
    stack(
      box(width: 100%, fill: azuluc3m, inset: (y: 12pt),
        align(center, text(size: 20pt, weight: "bold", fill: white,
          font: ("Liberation Sans", "DejaVu Sans"))[EUPL 1.2])),
      box(width: 100%, inset: 14pt, stack(spacing: 10pt,
        align(center, text(size: 13.5pt, fill: azuluc3m,
          smallcaps[Licencia Pública de la Unión Europea])),
        align(center, text(size: 13.5pt, fill: black)[
          #text(fill: azuluc3m, weight: "bold")[FOSS] #sym.dot.c _Copyleft_]),
        align(center, text(size: 13.5pt, fill: black)[
          #text(fill: azuluc3m)[#sym.checkmark] Uso
          #text(fill: azuluc3m)[#sym.checkmark] Copia
          #text(fill: azuluc3m)[#sym.checkmark] Modificación
          #text(fill: azuluc3m)[#sym.checkmark] Distribución]),
      )),
    ),
  )
  // Sello girado pisando el borde inferior de la tarjeta: registro de
  // propiedad intelectual en trámite.
  move(dx: 100pt, dy: -28pt, rotate(-7deg, box(
    radius: 6pt, inset: 8pt, fill: white,
    stroke: (paint: azuluc3m, thickness: 1.5pt, dash: "dashed"),
    text(size: 11pt, weight: "bold", fill: azuluc3m,
      font: ("Liberation Sans", "DejaVu Sans"),
      upper[Registro de Propiedad \ Intelectual en trámite]),
  )))
})

#diapo(titulo: [Licencias])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, grid(
      columns: (auto, auto), column-gutter: 44pt, align: center + horizon,
      tarjeta-eupl,
      tabla-comp(
        eleccion: false,
        anchos: (auto, 250pt),
        ([Licencia], [Complemento]),
        ([MIT], [FastAPI #sym.bullet LangGraph #sym.bullet Pydantic
          #sym.bullet React #sym.bullet Vite #sym.bullet Zustand]),
        ([BSD 3-Clause], [Uvicorn]),
        ([Apache License 2.0], [vLLM]),
      ),
    )),
    pie("Licencias", [Código abierto de extremo a extremo]),
  ))
]

// ------------------------------------------------------- 3.3.4 ods

#diapo(titulo: [Objetivos de Desarrollo Sostenible])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 88%, height: 100%,
      image("img/ods.png", fit: "contain", width: 100%, height: 100%)),
    pie("Agenda 2030", [Contribución a la educación,
      industria e igualdad]),
  ))
]

// ------------------------------------- 3.4 entorno socioeconómico
// Análisis PEST del contexto en el que nace OntoNova: cuatro cuadrantes
// de presión y el sistema en el centro como respuesta.

#let cuadrante(letra, titulo, lineas) = box(
  width: 350pt, height: 125pt, radius: 8pt, fill: azul-suave, inset: 14pt,
  align(left + top, stack(spacing: 10pt,
    grid(columns: (auto, auto), column-gutter: 8pt, align: horizon,
      box(width: 22pt, height: 22pt, radius: 11pt, fill: azuluc3m,
        align(center + horizon, text(size: 12pt, weight: "bold", fill: white,
          font: ("Liberation Sans", "DejaVu Sans"), letra))),
      text(size: 15pt, weight: "bold", fill: azuluc3m,
        font: ("Liberation Sans", "DejaVu Sans"), titulo),
    ),
    // Cuerpo a 14pt, el mismo tamaño que el cuerpo de las tablas del deck.
    ..lineas.map(l => text(size: 13.5pt, fill: black)[
      #text(fill: azuluc3m)[#sym.triangle.filled.small.r] #l]),
  )),
)

#diapo(titulo: [Entorno Socioeconómico])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, grid(
      columns: (auto, auto), column-gutter: 16pt, row-gutter: 14pt,
      cuadrante("P", [Político-legal], (
        [Entrada en vigor del AI Act y fin de periodos de adaptación],
        [Sistemas que aseguren la soberanía del dato],
      )),
      cuadrante("E", [Económico], (
        [Inasumibilidad del modelo _pay-per-use_ para PYMES],
        [Riesgo de fuga de capital intelectual a terceros],
        [Reducción de costes OPEX con soluciones FOSS]
      )),
      cuadrante("S", [Social], (
        [Infoxicación derivada del ruido digital no estructurado],
        [Escepticismo ante la falibilidad de la IA generativa],
        [Necesidad de soluciones multilingües y multimodales]
      )),
      cuadrante("T", [Tecnológico], (
        [Sistemas FOSS con soluciones locales de modelos],
        [Menor impacto ecológico y ambiental que la nube],
        [Necesidad de interoperabilidad hacia otros sistemas]
      )),
    )),
    pie("Análisis PEST", [OntoNova nace en la convergencia de las
      cuatro presiones]),
  ))
]

#seccion[Análisis de Requisitos]

// ------------------------------------ 4.1 gestión de requisitos (origen
// y estándares): del IEEE 830 a la 29148 + 15288 con criterios INCOSE.

#let tarjeta-norma(nombre, sub) = box(
  width: 190pt, radius: 6pt, fill: azuluc3m, inset: (x: 8pt, y: 9pt),
  align(center, stack(spacing: 4pt,
    text(size: 13pt, weight: "bold", fill: white,
      font: ("Liberation Sans", "DejaVu Sans"), nombre),
    text(size: 10pt, fill: white,
      font: ("Liberation Sans", "DejaVu Sans"), sub),
  )),
)

#diapo(titulo: [Gestión de Requisitos])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, {
      // Etiqueta de grupo para presentar cada banda de la diapositiva.
      let etiqueta(nombre) = box(radius: 10pt, fill: azuluc3m,
        inset: (x: 14pt, y: 5pt),
        text(size: 11pt, weight: "bold", fill: white,
          font: ("Liberation Sans", "DejaVu Sans"), upper(nombre)))
      stack(spacing: 10pt,
        // Origen de los requisitos (4.1.1).
        etiqueta("Origen"),
        grid(columns: (auto, auto, auto), column-gutter: 14pt,
          ..(
            ("Gerente de Proyecto", "Stakeholder y product owner"),
            ("Usuarios", "Médicos, juristas, humanistas"),
            ("Estado del arte", "Revisión documental"),
          ).map(((clave, desc)) => box(
            width: 220pt, radius: 6pt, fill: azul-suave, inset: (x: 10pt, y: 8pt),
            align(center, stack(spacing: 8pt,
              text(size: 13pt, weight: "bold", fill: azuluc3m,
                font: ("Liberation Sans", "DejaVu Sans"), clave),
              text(size: 10pt, fill: azuluc3m,
                font: ("Liberation Sans", "DejaVu Sans"), desc),
            )),
          )),
        ),
        v(20pt),
        // Evolución del estándar (4.1.2).
        etiqueta("Estándar"),
        grid(
          columns: (auto, auto, auto, auto, auto),
          column-gutter: 10pt, align: center + horizon,
          // IEEE 830 con sus ocho características.
          box(width: 225pt, radius: 8pt, stroke: 1.5pt + azuluc3m, clip: true,
            stack(
              box(width: 100%, fill: azuluc3m, inset: (y: 8pt),
                align(center, text(size: 13pt, weight: "bold", fill: white,
                  font: ("Liberation Sans", "DejaVu Sans"))[IEEE 830:1998])),
              box(width: 100%, inset: 8pt, grid(
                columns: (1fr, 1fr), gutter: 5pt,
                ..(
                  "Correcto", "Sin ambigüedad", "Completo", "Consistente",
                  "Priorizado", "Verificable", "Modificable", "Trazable",
                ).map(c => box(
                  width: 100%, radius: 4pt, fill: azul-suave, inset: 5pt,
                  align(center, text(size: 10pt, fill: azuluc3m,
                    font: ("Liberation Sans", "DejaVu Sans"), c)),
                )),
              )),
            )),
          stack(spacing: 6pt,
            text(size: 11pt, fill: black)[sustituida por],
            text(size: 26pt, fill: azuluc3m, sym.arrow.r),
          ),
          stack(spacing: 8pt,
            tarjeta-norma("ISO/IEC/IEEE 29148:2018", "Ingeniería de requisitos"),
            text(size: 18pt, weight: "bold", fill: azuluc3m, sym.plus),
            tarjeta-norma("ISO/IEC/IEEE 15288:2023", "Ciclo de vida del sistema"),
          ),
          text(size: 26pt, fill: azuluc3m, sym.arrow.r),
          box(width: 165pt, radius: 8pt, fill: azul-suave, inset: 10pt,
            align(center, stack(spacing: 6pt,
              text(size: 13pt, weight: "bold", fill: azuluc3m,
                font: ("Liberation Sans", "DejaVu Sans"))[Criterios de
                aceptación cuantificables],
              text(size: 11pt, fill: azuluc3m, smallcaps[Guía INCOSE v4]),
            ))),
        ),
      )
    }),
    pie("Normativa de requisitos", [Especificación conforme a la norma
      vigente, verificable y cuantificable]),
  ))
]

// ---------------------------- 4.2 requisitos destacados y casos de uso

// Chip de estado de un requisito, con la misma semántica que la memoria.
#let chip-estado(estado) = {
  let (relleno, tinta, borde) = if estado == "Incluido" {
    (azuluc3m, white, none)
  } else if estado == "Viable" {
    (azul-suave, azuluc3m, none)
  } else {
    (white, azuluc3m, (paint: azuluc3m, thickness: 1pt, dash: "dashed"))
  }
  box(fill: relleno, stroke: borde, radius: 10pt, inset: (x: 10pt, y: 4pt),
    text(size: 11pt, weight: "bold", fill: tinta,
      font: ("Liberation Sans", "DejaVu Sans"), estado))
}

#diapo(titulo: [Exposición de Requisitos])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, tabla-comp(
      eleccion: false, compacta: true,
      alinear: (left + horizon, left + horizon, center + horizon),
      ([ID], [Descripción], [Estado]),
      ([*REQ-US-FC-01*], [Texto de hasta 15.000 caracteres, en español e
        inglés], chip-estado("Incluido")),
      ([*REQ-US-FC-03*], [Validación sintáctica con motor de degradación
        elegante], chip-estado("Incluido")),
      ([*REQ-US-FC-05*], [Lienzo interactivo que opera la ontología en 3
        interacciones], chip-estado("Incluido")),
      ([*REQ-US-FC-07*], [Histórico de versiones del grafo, reversible y
        auditable], chip-estado("Viable")),
      ([*REQ-US-FC-10*], [Entrada de archivos planos o PDF de hasta 5 MB],
        chip-estado("Incluido")),
      ([*REQ-US-NF-01*], [Usabilidad: SUS mínimo de 70 con 5 usuarios],
        chip-estado("Incluido")),
      ([*REQ-US-NF-02*], [Carga en 3 segundos y respuesta en 200
        milisegundos], chip-estado("Incluido")),
    )),
    pie("Requisitos de usuario", [Presentes los destacados; en total, 10 funcionales y 3 no funcionales]),
  ))
]

#diapo(titulo: [Exposición de Requisitos])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, tabla-comp(
      eleccion: false, compacta: true,
      alinear: (left + horizon, left + horizon, center + horizon),
      ([ID], [Descripción], [Estado]),
      ([*REQ-SW-FC-01*], [Trazabilidad y métricas de usuario que contribuyan a la mejora continua], chip-estado("Viable")),
      ([*REQ-SW-FC-02*], [Motor de inferencia local tras un protocolo
        estándar], chip-estado("Incluido")),
      ([*REQ-SW-NF-01*], [Nivel AA de Accesibilidad de las WCAG sin errores críticos],
        chip-estado("Viable")),
      ([*REQ-SW-NF-02*], [Sin vulnerabilidades altas en las dependencias],
        chip-estado("Incluido")),
      ([*REQ-SW-NF-03*], [Respuesta controlada ante errores, sin pérdida del lienzo], chip-estado("Incluido")),
    )),
    pie("Requisitos del sistema", [Presentes los destacados; en total, 2 funcionales y 8 no funcionales]),
  ))
]

#diapo(titulo: [Casos de Uso])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 88%, height: 100%,
      image("img/uml.png", fit: "contain", width: 100%, height: 100%)),
    pie("Casos de uso", [Derivados de los requisitos incluidos]),
  ))
]

#seccion[Diseño del Sistema]

// ------------------------------------ 5.2 arquitectura (modelo C4)

#diapo(titulo: [Nivel de Contexto])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 92%, height: 100%,
      image("img/c4context.png", fit: "contain", width: 100%, height: 100%)),
    pie("C4: contexto", [La frontera de confianza local garantiza la
      privacidad]),
  ))
]

#diapo(titulo: [Nivel de Contenedores])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 100%, height: 100%,
      image("img/c4containers.png", fit: "contain", width: 100%, height: 100%)),
    pie("C4: contenedores", [Sistema local y sin estado. El motor de inferencia queda
      aislado tras un protocolo estándar]),
  ))
]

// --------------------------- 5.3.1 proceso multi-agente de generación

#diapo(titulo: [Nivel de Detalle])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 100%, height: 100%,
      image("img/agentpipeline.png", fit: "contain", width: 100%, height: 100%)),
    pie("Proceso multi-agente de generación", [Taxonomista, relacional y poblador, con
      validación, autocorrección y degradación elegante]),
  ))
]

// ------------------------------------ 5.3.2 contrato universal de datos
// Las cuatro entidades del OntoNovaSchema como fichas, en lugar de tabla.

#let ficha-entidad(nombre, campos, papel) = box(
  width: 176pt, height: 120pt, radius: 8pt, stroke: 1.5pt + azuluc3m,
  clip: true,
  align(center + top, stack(
    box(width: 100%, fill: azuluc3m, inset: (y: 8pt),
      align(center, text(size: 13.5pt, weight: "bold", fill: white,
        font: ("Liberation Sans", "DejaVu Sans"), nombre))),
    box(width: 100%, inset: 9pt, align(left + top, stack(spacing: 8pt,
      // Campos principales como chips monoespaciados.
      box(width: 100%, {
        for campo in campos {
          box(radius: 4pt, fill: azul-suave, inset: (x: 5pt, y: 3pt),
            text(size: 12.5pt, fill: azuluc3m, raw(campo)))
          h(4pt)
        }
      }),
      text(size: 13.5pt, fill: black, papel),
    ))),
  )),
)

#diapo(titulo: [Nivel de Detalle])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, stack(spacing: 16pt,
      box(radius: 10pt, fill: azuluc3m, inset: (x: 14pt, y: 5pt),
        text(size: 12pt, weight: "bold", fill: white,
          font: ("Liberation Sans", "DejaVu Sans"))[
          #raw("OntoNovaSchema") #sym.dot.c CONTRATO PRIMERO]),
      grid(columns: (auto, auto, auto, auto), column-gutter: 12pt,
        ficha-entidad("Clase",
          ("id", "name", "subClassOf"),
          [Concepto del dominio y su jerarquía taxonómica]),
        ficha-entidad("Prop. de objeto",
          ("id", "name", "domain", "range", "characteristics"),
          [Relación binaria entre clases]),
        ficha-entidad("Prop. de datos",
          ("id", "name", "domain", "range"),
          [Atributo literal con tipo primitivo]),
        ficha-entidad("Individuo",
          ("id", "name", "typeClass", "aserciones"),
          [Instancia concreta y sus hechos]),
      ),
    )),
    pie("Fuente de verdad", [Los campos desconocidos están prohibidos; la alucinación
      no se propaga]),
  ))
]

// ----------------------------------------- 5.5 diseño de despliegue

#diapo(titulo: [Diseño de Despliegue])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 100%, height: 100%,
      image("img/c4deployment.png", fit: "contain", width: 100%, height: 100%)),
    pie("C4: despliegue", [Un solo nodo, el equipo del experto, orquestado
      con Docker]),
  ))
]

#seccion[Implementación]

// ---------------------------------------- recorrido de la aplicación
// Marcador de posición del vídeo: sustituir cuando esté grabado.

#diapo(titulo: [Recorrido de la Aplicación])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    // Fotograma real del vídeo como marco clicable: el enlace relativo
    // abre img/mvp.mp4 en el reproductor del sistema (el PDF debe viajar
    // junto a la carpeta img).
    align(center + horizon, link("img/mvp.mp4", box(
      width: 480pt, height: 270pt, radius: 10pt, clip: true,
      stroke: 1.5pt + azuluc3m,
      {
        place(image("img/mvp-frame.png", width: 100%, height: 100%,
          fit: "cover"))
        // Botón de reproducción sobre el fotograma.
        place(dx: 200pt, dy: 95pt,
          circle(radius: 40pt, fill: white.transparentize(18%)))
        place(polygon(fill: azuluc3m,
          (227pt, 114.5pt), (227pt, 155.5pt), (262pt, 135pt)))
        // Pista de interacción, dentro del marco.
        place(dx: 332pt, dy: 240pt, box(
          radius: 9pt, fill: white.transparentize(10%), inset: (x: 9pt, y: 4pt),
          text(size: 10pt, weight: "bold", fill: azuluc3m,
            font: ("Liberation Sans", "DejaVu Sans"))[Clic para reproducir],
        ))
      },
    ))),
    pie("Recorrido de la aplicación", [Del texto del dominio al grafo
      validado y exportado]),
  ))
]

// --------------------------- 6.3 dificultades y decisiones técnicas

#diapo(titulo: [Dificultades y Decisiones Técnicas])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, [
      #show raw.where(block: true): bloque => block(
        stroke: (top: 1pt + black, bottom: 1pt + black),
        fill: luma(245), inset: 12pt, width: 100%, radius: 0pt,
        align(left, {
          set text(size: 9.5pt)
          set par(leading: 0.55em)
          show raw.line: it => {
            text(fill: luma(120), size: 0.9em)[
              #box(width: 1.2em, align(right, str(it.number)))
            ]
            text(fill: luma(180))[ | ]
            it.body
          }
          bloque.lines.join(linebreak())
        }),
      )
      ```python
      # core/graph.py
      def _correction_note(state: OntologyGenerationState, stage: str) -> str:
        retry_stage = state.get("retry_stage")
        if not retry_stage or not state.get("last_error"):
            return ""
        if STAGE_ORDER.index(stage) < STAGE_ORDER.index(retry_stage):
            return ""  # this stage already succeeded and won't re-run this pass
        previous_output = {key: state.get(key, []) for key in _STAGE_STATE_KEYS[stage]}
        return (
            "\n\nA previous attempt failed schema validation with this error:\n"
            f"{state['last_error']}\n\n"
            f"Your previous output for this stage was:\n{previous_output}\n\n"
            "Produce a corrected version of that output: keep every entry that is "
            "not implicated in the error and fix only what the error requires. Do "
            "NOT drop previously produced valid content (classes, properties, "
            "individuals or their assertions) just to make the error disappear. "
            "If the error says an assertion uses an undeclared property or "
            "individual id, the relationship itself is usually correct: declare "
            "the missing item if this stage owns it, or re-express the assertion "
            "with a declared id — removing the relationship is the last resort."
        )
      ```
    ]),
    pie("Decisión", [El agente culpable debe corregir sin regenerar; la salida previa viaja junto
      al error]),
  ))
]

#diapo(titulo: [Dificultades y Decisiones Técnicas])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 100%, height: 100%,
      image("img/appcanvasbad.png", fit: "contain", width: 100%, height: 100%)),
    pie("Dificultad", [El lote continuo del motor rompe el determinismo
      entre ejecuciones produciendo una conectividad degradada]),
  ))
]

#seccion[Verificación]

// -------------------- 7.1 estrategia de pruebas (fig. 7.1 + tabla 7.1)

#diapo(titulo: [Estrategia y Balance de Pruebas])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, grid(
      columns: (auto, auto), column-gutter: 30pt, align: center + horizon,
      box(width: 360pt, height: 290pt,
        image("img/testpyramid.png", fit: "contain", width: 100%, height: 100%)),
      grid(rows: (auto, auto, auto), row-gutter: 12pt, align: left,
        tabla-comp(
          eleccion: false, compacta: true,
          alinear: (left + horizon, right + horizon, right + horizon),
          ([Métrica], [Dominio 1], [Dominio 2]),
          ([Precisión #sym.plus.minus #sym.lambda],
            [1,00 #sym.plus.minus 0,00], [0,52 #sym.plus.minus 0,07]),
          ([Exhaustividad #sym.plus.minus #sym.lambda],
            [1,00 #sym.plus.minus 0,00], [0,45 #sym.plus.minus 0,05]),
          ([F1 #sym.plus.minus #sym.lambda],
            [1,00 #sym.plus.minus 0,00], [0,41 #sym.plus.minus 0,04]),
        ),
        tabla-comp(
          eleccion: false, compacta: true,
          alinear: (left + horizon, right + horizon, right + horizon),
          ([Ejecución], [Dominio 1], [Dominio 2]),
          ([Éxitos / fallos], [25 / 0], [22 / 3]),
          ([Poda final], [0%], [100%]),
          ([Tiempo (u)], [0m 20s], [2m 19s]),
        ),
        text(size: 12pt)[#sym.lambda = desviación típica.],
      ),
    )),
    pie("Estrategia de pruebas", [117 pruebas automáticas y campañas de
      25 generaciones por dominio]),
  ))
]

// ------------------- 7.2 verificación de requisitos (ISO/IEC/IEEE 29148)

#let ficha-metodo(nombre, numero, desc) = box(
  width: 168pt, height: 130pt, radius: 8pt, stroke: 1.5pt + azuluc3m,
  clip: true,
  align(center + top, stack(
    box(width: 100%, fill: azuluc3m, inset: (y: 8pt),
      align(center, text(size: 13pt, weight: "bold", fill: white,
        font: ("Liberation Sans", "DejaVu Sans"), nombre))),
    box(width: 100%, inset: 10pt, stack(spacing: 7pt,
      text(size: 34pt, weight: "bold", fill: azuluc3m,
        font: ("Liberation Sans", "DejaVu Sans"), numero),
      text(size: 13.5pt, fill: black,
        if numero == "1" { "requisito" } else { "requisitos" }),
      text(size: 13.5pt, fill: black, desc),
    )),
  )),
)

#diapo(titulo: [Verificación de Requisitos])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, stack(spacing: 16pt,
      box(radius: 10pt, fill: azuluc3m, inset: (x: 14pt, y: 5pt),
        text(size: 12pt, weight: "bold", fill: white,
          font: ("Liberation Sans", "DejaVu Sans"))[MÉTODOS DE VERIFICACIÓN]),
      grid(columns: (auto, auto, auto, auto), column-gutter: 14pt,
        ficha-metodo("Prueba", "8", [Ejecución instrumentada del sistema]),
        ficha-metodo("Demostración", "3", [Uso observado de la funcionalidad]),
        ficha-metodo("Análisis", "2", [Datos, métricas y auditorías]),
        ficha-metodo("Inspección", "1", [Revisión del artefacto de diseño]),
      ),
      // Veredicto global de la tabla 7.2.
      box(radius: 10pt, fill: azul-suave, inset: (x: 16pt, y: 8pt),
        text(size: 15pt, weight: "bold", fill: azuluc3m,
          font: ("Liberation Sans", "DejaVu Sans"))[14 / 14 #sym.dot.c
          Cumple #sym.checkmark]),
    )),
    pie("ISO/IEC/IEEE 29148:2018", [Cada requisito incluido, verificado
      por el método que su métrica solicita]),
  ))
]

// ------------------- 7.3 verificación del cumplimiento normativo (ap. B)

#let veredicto(color, titulo, cuerpo) = block(
  width: 330pt, inset: 9pt, radius: 2pt,
  fill: color.lighten(88%), stroke: (left: 2.5pt + color),
  align(left, text(size: 13.5pt, fill: black)[*#titulo* #h(0.2em) #cuerpo]),
)

#diapo(titulo: [Verificación del Cumplimiento Normativo])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, grid(
      columns: (auto, auto), column-gutter: 28pt, align: center + horizon,
      tabla-comp(
        eleccion: false, compacta: true, tamano: 13.5pt,
        anchos: (200pt, 210pt),
        ([Sección del cuestionario], [Respuesta marcada]),
        ([Tipo de entidad], [Proveedor]),
        ([Modificaciones aguas abajo], [Ninguna]),
        ([Alto riesgo (Anexo I, A y B)], [Ninguna]),
        ([Alto riesgo (Anexo III)], [Ninguna]),
        ([Alcance], [Puesta en servicio de sistemas IA en la UE]),
        ([Sistemas excluidos], [Actividad de I+D en IA \ Componentes con
          licencias libres]),
        ([Sistemas prohibidos (Art. 5)], [Ninguna]),
        ([Sistemas transparentes (Art. 50)], [Ninguna]),
      ),
      stack(spacing: 10pt,
        veredicto(luma(90), [Excluidos: Sistemas de código abierto.])[Hasta
          su comercialización o puesta en servicio, queda excluido del
          ámbito de aplicación de la ley (Artículo 2, apartado 12).],
        veredicto(luma(90), [Excluidos: Investigación y desarrollo.])[Las
          actividades de I+D quedan excluidas hasta la comercialización o
          puesta en servicio del sistema (Artículo 2, apartados 6 y 8).],
        veredicto(azuluc3m, [Obligaciones de alfabetización en IA.])[Como
          proveedor, deben garantizarse conocimientos suficientes sobre IA
          en quienes operen el sistema (Artículo 4).],
      ),
    )),
    pie("EU AI Act Compliance Checker", [Fuera del ámbito de la ley hasta su exposición pública; la alfabetización, única obligación]),
  ))
]

#seccion[Propuesta de Exposición Pública]

// ------------------------------------------ 8.1 impacto en la arquitectura

#diapo(titulo: [Impacto en la Arquitectura])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 96%, height: 100%,
      image("img/c4contextcloud.png", fit: "contain", width: 100%, height: 100%)),
    pie("C4: contexto público", [Identidad y trazabilidad como servicios;
      los contenedores permanecen intactos]),
  ))
]

#diapo(titulo: [Impacto en la Arquitectura])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 96%, height: 100%,
      image("img/cloudarch.png", fit: "contain", width: 100%, height: 100%)),
    pie("Marco operacional", [Réplicas sin estado tras el balanceador; el motor de
      inferencia, aislado con GPU y autoescalado]),
  ))
]

// -------------------------------------------- 8.2 impacto en la seguridad

#diapo(titulo: [Impacto en la Seguridad])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 100%, height: 100%,
      image("img/secgauntlet.png", fit: "contain", width: 100%, height: 100%)),
    pie("Puertas de seguridad", [Cada petición viaja con un testigo
      verificable; tasa y cuotas por identidad, indispensables]),
  ))
]

// -------------------------------------------- 8.3 impacto en el despliegue

#diapo(titulo: [Impacto en el Despliegue])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    box(width: 100%, height: 100%,
      image("img/cipipeline.png", fit: "contain", width: 100%, height: 100%)),
    pie("CI/CD", [De la integración a producción: pruebas, imágenes, E2E,
      aceptación con GPU y entrega]),
  ))
]

// ------------------------------------------ 8.4 impacto en la legislación

#let impacto-legal(sigla, titulo, lineas, decision: false) = box(
  width: 660pt, radius: 8pt,
  fill: if decision { azuluc3m } else { azul-suave },
  inset: 12pt,
  align(left, grid(
    columns: (92pt, auto), column-gutter: 13pt, align: left + horizon,
    text(size: 16pt, weight: "bold",
      fill: if decision { white } else { azuluc3m },
      font: ("Liberation Sans", "DejaVu Sans"), sigla),
    stack(spacing: 7pt,
      text(size: 13.5pt, weight: "bold",
        fill: if decision { white } else { azuluc3m },
        font: ("Liberation Sans", "DejaVu Sans"), titulo),
      ..lineas.map(l => text(size: 14pt,
        fill: if decision { white } else { black })[
        #text(fill: if decision { white } else { azuluc3m })[#sym.triangle.filled.small.r] #l]),
    ),
  )),
)

#diapo(titulo: [Impacto en la Legislación])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, stack(spacing: 14pt,
      impacto-legal("RGPD", [El proveedor pasa a responsable del tratamiento], (
        [La infraestructura queda como mero encargado, por adenda de
          tratamiento de datos],
        [Regiones europeas de despliegue: sin transferencias internacionales],
      )),
      impacto-legal("EU AI Act", [Reevaluación del cuestionario de conformidad], (
        [La exclusión de I+D se extingue con la
          publicación],
        [Vuelven las obligaciones de proveedor, con foco en la transparencia
          (Art. 50)],
      )),
      impacto-legal("EUPL 1.2", [La licencia se mantiene frente a la AGPL-3],
        decision: true, (
        [Su _copyleft_ ya alcanza el servicio en línea: la comunicación es
          distribución],
        [Pendientes como entregables: aviso legal y política de privacidad],
      )),
    )),
    pie("Legislación", [Mismo marco, obligaciones endurecidas; la EUPL 1.2
      se queda]),
  ))
]

#seccion[Conclusiones]

// -------------------------------- 9.1 consecución de objetivos (diana)

#diapo-diana([Consecución de Objetivos], cumplido: true, (
  [Nivel 3 de Bloom: cadena multi-agente razonada],
  [SUS de 76,50 con usuarios reales],
  [50 generaciones reales en español e inglés],
  [Cuestionario de conformidad superado],
  [C4, patrones y cero vulnerabilidades altas],
  [Contribución a los ODS 4, 9 y 10],
))

// ----------------------------------------------- 9.3 trabajos futuros

// En la tarjeta destacada (fondo oscuro) se conserva el contraste entre
// título y cuerpo: título en blanco y cuerpo en azul muy claro.
#let futuro(titulo, cuerpo, destacada: false, ancho: 225pt) = box(
  width: ancho, radius: 8pt, inset: 12pt,
  fill: if destacada { azuluc3m } else { azul-suave },
  align(left, stack(spacing: 8pt,
    text(size: 14pt, weight: "bold",
      fill: if destacada { white } else { azuluc3m },
      font: ("Liberation Sans", "DejaVu Sans"), titulo),
    text(size: 13.5pt,
      fill: if destacada { white } else { black }, cuerpo),
  )),
)

#diapo(titulo: [Trabajos Futuros])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    align(center + horizon, grid(
      columns: (auto, auto, auto), column-gutter: 22pt, align: center + top,
      ..(
        ("Plano funcional", (
          futuro([Importación de ontologías], [Ficheros W3C de hasta 5 MB
            sin pérdida de tripletas]),
        )),
        ("Plano de calidad", (
          futuro([Refinamiento de instrucciones], [Las categorías débiles del dominio denso señalan el refinamiento necesario con las métricas clásicas como vara de medir],
            destacada: true, ancho: 265pt),
        )),
        ("Plano normativo-operativo", (
          futuro([Información pública obligatoria], [Aviso legal y política
            de privacidad dentro de OntoNova]),
          futuro([Reevaluación de conformidad], [El cuestionario del EU AI Act
            bajo el supuesto de exposición pública]),
        )),
      ).map(((plano, tarjetas)) => stack(spacing: 12pt,
        box(radius: 10pt, fill: azuluc3m, inset: (x: 12pt, y: 4pt),
          text(size: 12pt, weight: "bold", fill: white,
            font: ("Liberation Sans", "DejaVu Sans"), upper(plano))),
        ..tarjetas,
      )),
    )),
    pie("Planos de mejora", [El más maduro ya
      tiene propuesta: la exposición pública]),
  ))
]

/*
#diapo(titulo: [Diapositiva de figura])[
  #align(center, image("img/testpyramid.png", height: 78%))
]

#diapo(titulo: [Diapositiva de código])[
  ```python
  payload = {
      "model": model,
      "messages": messages,
      "temperature": 0.0,
      "guided_json": json_schema,
  }
  ```
  - La decodificación guiada garantiza salidas estructuralmente válidas
]

#seccion[Verificación]

#diapo(titulo: [Dos columnas])[
  #columnas(
    [
      *Columna izquierda*
      - Afirmación
      - Explicación
      - Ejemplo
    ],
    [
      *Columna derecha* \
      Texto corrido de apoyo que acompaña a la enumeración de la izquierda,
      al estilo de la plantilla original.
    ],
  )
]

#diapo(titulo: [Preguntas], alineado: center + horizon)[
  #text(size: 30pt, weight: "bold", fill: azuluc3m)[¿Preguntas?]
]*/

// ------------------------------------------------------- bibliografía

#diapo(titulo: [Bibliografía])[
  #box(width: 100%, height: 100%, grid(
    columns: (100%,), rows: (1fr, auto), row-gutter: 14pt, align: center,
    // Cita editorial: solo el filete izquierdo, sin fondo, para que ancle
    // sin pesar.
    align(center + horizon, block(
      width: 620pt,
      stroke: (left: 3pt + azuluc3m), inset: (left: 20pt, y: 6pt),
      align(left, par(hanging-indent: 22pt, text(size: 16pt, fill: black)[
        Picazo García, D. (2026). _Diseño e implementación de un sistema de
        gestión del conocimiento multilingüe basado en LLMs como alternativa
        abierta a otros sistemas existentes_ #box[[Trabajo de Fin de
        Máster]]. Universidad Carlos III de Madrid.
      ])),
    )),
  ))
]

// La portada, de nuevo, como cierre de la presentación.
#slide-portada
