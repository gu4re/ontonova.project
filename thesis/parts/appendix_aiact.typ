= Resultados del Cumplimiento de la Ley de IA de la UE <app:aiact>
#figure(
  table(
    columns: (1fr, 1fr),
    align: (left + top, left + top),
    table.header(
      text(size: 10pt)[*Sección del cuestionario*], text(size: 10pt)[*Respuesta marcada*],
    ),
    table.hline(),
    [Tipo de entidad], [Proveedor],
    [Modificaciones aguas abajo], [Ninguna],
    [Alto riesgo (Anexo I, secciones A y B)], [Ninguna],
    [Alto riesgo (Anexo III)], [Ninguna],
    [Alcance], [Puesta en servicio sistemas de IA en la UE],
    [Sistemas excluidos], [Actividad de I+D en IA 
    \ Componentes con licencias libres],
    [Sistemas prohibidos (Artículo 5)], [Ninguna],
    [Sistemas transparentes (Artículo 50)], [Ninguna],
  ),
  caption: [Respuestas registradas en el cuestionario de conformidad],
) <tab:aiactroute>

#let verdict(color, title, body) = block(
  width: 100%, inset: 7pt, radius: 2pt,
  above: 5pt, below: 5pt,
  fill: color.lighten(88%), stroke: (left: 2.5pt + color),
  [*#title* #h(0.2em) #body],
)
#verdict(orange.darken(20%), [Excluidos: Sistemas de código abierto.])[Hasta que el sistema se comercialice o se ponga en servicio como parte de un sistema de alto riesgo, prohibido, de uso general o sujeto a obligaciones de transparencia, queda excluido del ámbito de aplicación de la ley (Artículo 2, apartado 12).]
#verdict(orange.darken(20%), [Excluidos: Investigación y desarrollo.])[Las actividades de investigación y desarrollo quedan excluidas hasta la comercialización o puesta en servicio del sistema (Artículo 2, apartados 6 y 8).]
#verdict(green.darken(25%), [Obligaciones en materia de alfabetización en IA.])[Como proveedor, deben garantizarse conocimientos suficientes sobre IA en quienes operen el sistema, atendiendo a su formación y al contexto de uso (Artículo 4).]