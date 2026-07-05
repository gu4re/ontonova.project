= Cuestionario de Usabilidad <app:sus>
#block(
  stroke: 0.5pt + black, inset: 14pt, radius: 2pt, width: 100%,
)[
  #align(center)[*Evaluación de usabilidad --- OntoNova*]

  *Instrucciones.* Complete las tres tareas siguientes utilizando la aplicación, sin ayuda del evaluador. Al terminar, valore cada afirmación marcando una casilla de 1 (totalmente en desacuerdo) a 5 (totalmente de acuerdo).

  *Tareas.* Genere una ontología a partir de un texto propio de su ámbito. Edite el grafo resultante creando una clase nueva y renombrando una relación. Exporte el resultado al formato que desee.

  #table(
    columns: (1fr, auto, auto, auto, auto, auto),
    align: (left + top,) + (center + top,) * 5,
    table.header(
      text(size: 10pt)[*Afirmación*],
      text(size: 10pt)[*1*], text(size: 10pt)[*2*], text(size: 10pt)[*3*],
      text(size: 10pt)[*4*], text(size: 10pt)[*5*],
    ),
    table.hline(),
    ..(
      "Creo que me gustaría utilizar este sistema con frecuencia.",
      "Encuentro el sistema innecesariamente complejo.",
      "Creo que el sistema es fácil de usar.",
      "Creo que necesitaría el apoyo de un técnico para poder utilizar este sistema.",
      "Encuentro que las diversas funciones del sistema están bien integradas.",
      "Creo que hay demasiada inconsistencia en este sistema.",
      "Imagino que la mayoría de la gente aprendería a utilizar este sistema muy rápidamente.",
      "Encuentro el sistema muy engorroso de utilizar.",
      "Me siento muy seguro utilizando el sistema.",
      "Necesité aprender muchas cosas antes de poder empezar a utilizar este sistema.",
    ).enumerate().map(((index, item)) => (
      [#(index + 1). #item],
      sym.square.stroked, sym.square.stroked, sym.square.stroked,
      sym.square.stroked, sym.square.stroked,
    )).flatten()
  )

  #v(6pt)
  Edad: #box(width: 3em, repeat[.]) #h(0.5em) Profesión: #box(width: 8.2em, repeat[.]) #h(0.5em) ¿Conocía las ontologías? Sí #sym.square.stroked #h(0.5em) No #sym.square.stroked
]