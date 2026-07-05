#import "uc3m-thesis-ieee-typst/lib.typ": conf
#import "config/glossary.typ": glossary-entries
#import "config/gen-ai.typ": genai-declaration
#import "config/bibliography.typ": bibliography

#show: conf.with(
  degree: "Máster Universitario en Ingeniería Informática",
  title: "Diseño e Implementación de un Sistema de Gestión del Conocimiento Multilingüe Basado en LLMs como Alternativa Abierta a otros sistemas existentes",
  short-title: "Sistema de Gestión del Conocimiento Multilingüe",
  author: "Diego Picazo García",
  advisors: ("Anabel Fraga Vázquez",),
  location: "Leganés, Madrid",
  thesis-type: "TFM",
  date: datetime(year: 2026, month: 9, day: 6),
  language: "es",
  style: "fancy",
  license: true,
  double-sided: true,
  flyleaf: false,
  bibliography-content: bibliography,
  epigraph: (
    quote: [If you don't make mistakes, you're not working on hard enough problems. And that's a big mistake.],
    author: "Frank Wilczek",
    // source: "",
  ),
  abstract: (
    body: [
      El presente documento propone el desarrollo de un sistema de gestión del conocimiento accesible y multilingüe, basado en @glossllm, con el objetivo de abstraer la complejidad inherente a herramientas tradicionales como _Protégé_, ampliamente utilizadas en el ámbito de la ingeniería del conocimiento pero caracterizadas por una elevada curva de aprendizaje.
      El sistema integra capacidades de análisis de texto, habilitando casos de uso como la interoperabilidad semántica entre plataformas, la *generación de conocimiento* a partir de datos no estructurados y la *automatización* de procesos de razonamiento, todo ello con el propósito de democratizar el acceso a la creación y gestión del conocimiento. Para ello, se contempla el despliegue local de soluciones de código abierto @opensourcellms, *garantizando* un estricto alineamiento con el *marco regulatorio europeo vigente* @edpb2025ai (e.g., @glossgdpr @gdpr y @glossaiact @aiactlaw), haciendo uso de validadores como _EU AI Act Compliance Checker_ @euaiactchecker.

      Cabe destacar que la gestión del ciclo de vida del software, el plan de proyecto y la monitorización de métricas se han regido por la aplicación de una *metodología en cascada* @waterfall. Este enfoque se ha sustentado en el aprendizaje continuo, asegurando así una preparación completa y el cumplimiento de los hitos del proyecto.

      A nivel arquitectónico, la solución se estructura mediante un motor de procesamiento lógico, _backend_, encargado de *interpretar* la *entrada* en lenguaje *natural*. Posteriormente, una interfaz gráfica, _frontend_, facilita la representación *visual* e interactiva del *grafo de conocimiento generado*. Este flujo de trabajo permite al usuario validar la ontología antes de proceder a su exportación en formatos estándar @glossw3c, tales como @glossrdf o Turtle, preservando así la compatibilidad retrospectiva con otros competidores semánticos del sector.

      Finalmente, desde una perspectiva de infraestructura tecnológica, el entorno de inferencia ha sido rigurosamente optimizado para exprimir el rendimiento de *hardware acelerado local*, mediante unidades de procesamiento gráfico de alto nivel. No obstante, la arquitectura del sistema *soporta* una migración a un paradigma escalable en la *nube* pública o privada (véase @sec:future-work) donde la capacidad de procesamiento queda acotada principalmente por el costo de aprovisionamiento de recursos.
    ],
    keywords: (
      "Inteligencia Artificial", 
      "Ingeniería del Conocimiento",
      "Modelo de Lenguaje de Gran Tamaño (LLM)",
      "Ontología", 
      "Arquitectura Orientada a Eventos"
    ),
  ),
  english-abstract: (
    body: [
      This document proposes the development of an accessible and multilingual knowledge management system, based on @glossllm, with the aim of abstracting the inherent complexity of traditional tools such as _Protégé_, widely used in the field of knowledge engineering but characterised by a steep learning curve.
      The system integrates text analysis capabilities, enabling use cases such as semantic interoperability between platforms, the *generation of knowledge* from unstructured data and the *automation* of reasoning processes, all with the purpose of democratizing access to the creation and management of knowledge. To this end, the local deployment of open-source solutions @opensourcellms is considered, *guaranteeing* strict alignment with the *current European regulatory framework* @edpb2025ai (e.g., @glossgdpr @gdpr and the @glossaiact @aiactlaw), making use of validators such as the EU AI Act Compliance Checker @euaiactchecker.

      It should be noted that the software development life cycle, the project plan, and the monitoring of metrics have been governed by the application of a *waterfall methodology* @waterfall. This approach has been supported by the continuous learning, thereby ensuring complete preparation and the fulfilment of the project milestones.

      At the architectural level, the solution is structured through a logical processing engine, the backend, responsible for *interpreting* the *natural* language *input*. Subsequently, a graphical user interface, the frontend, facilitates the *visual* and interactive representation of the *generated knowledge graph*. This workflow allows the user to validate the ontology prior to its export into standard formats @glossw3c, such as @glossrdf or Turtle, thus preserving backward compatibility with other semantic competitors in the sector.

      Finally, from a technological infrastructure perspective, the inference environment has been rigorously optimised to maximise the performance of *local accelerated hardware*, by means of high-end graphical processing units. Nevertheless, the system architecture *supports* a migration to a scalable, private or public, *cloud paradigm* (see @sec:future-work[Section]), where the processing capacity is bounded primarily by the cost of resource provisioning.
    ],
    keywords: (
      "Artificial Intelligence", 
      "Knowledge Engineering",
      "Large Language Model (LLM)",
      "Ontology",
      "Event Driven Architecture"
    ),
  ),
  acknowledgements: [
    Es una tradición, bien conocida, dar las gracias a aquellos seres queridos que me acompañan, inseparables como mi propia sombra, en cada paso del camino. Gracias, papá; gracias, mamá, por confiar una vez más en mi proyección, en mi ambición y ofrecerme toda clase de oportunidades. Conozco vuestros sacrificios, vuestros días aburridos y austeros, que me dan energía cada día para evolucionar, progresar y correr a casa, no con un diploma más, sino con la mochila cargada de nuevos conocimientos y experiencias que me permitan, en el futuro, daros la mano en la cima y mostraros el horizonte que se vislumbra. Tengo muy presentes a mis amigos cercanos ---Olmo, Alejandro y Jorge---, a mi hermano ---Mario--- y a mi querida alma gemela ---Emily---, que siempre han apoyado mis locuras, mi ansia de aprendizaje y han escuchado atentamente mis problemas entre videojuegos, viajes y partidos de pádel.

    Es imposible olvidar a mis maestros, que, durante mi paso breve y enriquecedor por sus aulas, han transmitido su conocimiento y enseñanza a la perfección. Agradezco a Anabel Fraga por su amabilidad, preciosas explicaciones y tutela en este proyecto. A Carlos Galán, el gran músico, por sus lecciones de la Constitución Española y a Sergio Pastrana por acercar la comunidad científica de cibercrímenes a las aulas. Sin olvidar a mis compañeros de clase, en particular a Francisco, Luis y Lucas. Han hecho del aprendizaje y de los proyectos colaborativos un pasaje interesante y ameno.

    Hago extensivo mi agradecimiento a Verisure ---Securitas Direct---, empresa que apuesta cada día por mi desarrollo y aprendizaje, facilitando económicamente mi presencia en el plan de formación impartido por la UC3M. Me enorgullece anunciar que mi travesía retorna con nuevo conocimiento listo para ser trasladado al mundo laboral.

    Finalmente, quiero dar las gracias a la comunidad de código abierto. Es magnífico observar que personas de distintas culturas, religiones y ámbitos sociales unen fuerzas para una misma causa. Espero que en el futuro tengan la reputación que merecen.
  ],
  outlines: (
    // contents is compulsory
    figures: true,
    tables: true,
    listings: false,
    // custom: (
    //   outline(
    //     title: [List of algorithms],
    //     target: figure.where(kind: "algorithm"),
    //   ),
    // ),
  ),
  // appendixes: [],
  glossary: glossary-entries, // comment this line if you don't want a glossary
  //abbreviations: (),
  genai-declaration: genai-declaration,
)


/* Custom set/show rules */

// prevent floating elements from spilling into the next section
#show heading.where(level: 2): it => {
  place.flush()
  it
}

// "booktab" table style
#show table: block.with(stroke: (y: 0.7pt))
#set table(column-gutter: .2em, stroke: none)
#set table.hline(stroke: 0.4pt)



/* Thesis */

#include "parts/introduction.typ"
#include "parts/state_of_the_art.typ"
#include "parts/project_plan.typ"
#include "parts/analysis.typ"
#include "parts/design.typ"
#include "parts/implementation.typ"
#include "parts/verification.typ"
#include "parts/conclusions.typ"


/* Examples */
/*
#include "parts/graph_example.typ"

#figure(
  image("img/logo_gul_uc3m.svg", width: 70%),
  caption: [El mejor logo de la UC3M, con diferencia],
) <fig:logo>

@fig:logo.

#let yes = sym.checkmark
#figure(
  table(
    columns: 7,
    table.header(
      [*OS*],
      [*Silksong*],
      [*Ads*],
      [*Spyware*],
      [*Unix*],
      [*FOSS*],
      [*Penguins*],
    ),
    table.hline(),
    [Linux], [#yes], [], [], [#yes], [#yes], [#yes],
    [MacOS], [#yes], [], [#yes], [#yes], [], [],
    [Windows], [#yes], [#yes], [#yes], [], [], [],
  ),
  caption: [Comparison of desktop Operating Systems],
) <tab:os>
*/