= Introducción
Este capítulo presenta la motivación del trabajo, @sec:motivacion, exponiendo qué caso de uso se persigue y qué objetivos principales y secundarios, @sec:objetivos, contempla.

== Motivación <sec:motivacion>
El ser humano siente desde sus orígenes la *necesidad intrínseca de estructurar y nombrar el mundo* que le rodea para poder comprenderlo. Con la llegada de la era digital y la expansión desorbitada de internet, esa necesidad se ha trasladado a un océano de datos casi inabarcable. Hoy en día, se interactúa con sistemas de información complejos con una naturalidad pasmosa, dando por sentada la _magia tecnológica_ que permite a las máquinas procesar y conectar el conocimiento de forma transparente. En este contexto, *el reto* no consiste únicamente en almacenar grandes volúmenes de información, sino en *dotarlos de un significado profundo, universal y estructurado*.

Históricamente, la traducción del pensamiento humano a la lógica de un computador ha requerido de intérpretes altamente especializados. La Web 3.0 (véase @sec:semanticweb) nace con la promesa de crear un lenguaje universal, utilizando estándares matemáticamente precisos para modelar la realidad. Sin embargo, este proceso ha dependido tradicionalmente de herramientas abstractas y lenguajes crípticos, un camino tumultuoso que ha alejado a los verdaderos expertos del dominio ---médicos, abogados, educadores--- de la creación directa de sus propios modelos de conocimiento.

*Con* la irrupción contemporánea de la *@glossai generativa*, surge la tentación lógica de intentar atajar el problema. *Solicitar* directamente a un modelo de lenguaje *que escuche* al usuario *y escriba* la semántica que necesita parece una *solución atractiva*. *Pero* aquí radica una incompatibilidad fundamental. El lenguaje *humano* es fluido, *creativo* y orgánico; por el *contrario*, los lenguajes formales de las *máquinas* son *inflexibles*. Una sola asunción ambigua por parte de la @glossai puede destruir por completo el significado del conjunto, provocando fallos irreversibles que la máquina rechaza categóricamente. 

En consecuencia, *nace* la necesidad de un *enfoque híbrido*, que actúa como guardarraíl para la @glossai, e interconecta la creatividad humana y la precisión formal de los sistemas. En apartados posteriores *se exponen* los requisitos, el diseño e implementación de un *sistema*, de código libre @opensourcellms, de *gestión del conocimiento* accesible, multilingüe y basado en @glossllm, abordando el enfoque mencionado y enfrentando las debilidades de competidores semánticos de gran escala, como Protégé, que han demostrado poseer una curva de aprendizaje elevada. *OntoNova* integra capacidades de análisis de lenguaje natural, que habilita casos de uso como la *interoperabilidad* de sistemas de información, la *generación de conocimiento* a partir de datos no estructurados y la *automatización* de procesos de razonamiento, todo ello con el propósito de democratizar el acceso a la creación y gestión del conocimiento. Adicionalmente, resuelve el problema del lienzo en blanco para los ingenieros de conocimiento, pues los verdaderos expertos les proporcionan de partida la semántica que necesitan en un formato @glossw3c.

== Objetivos <sec:objetivos>
El propósito principal consiste en diseñar y desarrollar un sistema del conocimiento multilingüe basado en @glossllm, que actúe como alternativa accesible y de código abierto a herramientas tradicionales, estableciendo un alcance apropiado al marco de este trabajo.

#par(first-line-indent: 0pt)[
A continuación, se listan los objetivos secundarios que complementan el objetivo principal:
]
- *O1:*<O1> Obtener nuevos conocimientos en @glossai, indagando en @glossllm, arquitectura, capacidades y limitaciones, hasta adquirir, al menos, el nivel tres en la taxonomía de Bloom @bloomstaxonomy.
- *O2:*<O2> Disminuir la barrera de entrada a la elaboración de ontologías, ofreciendo una alternativa más accesible y cercana al usuario.
- *O3:*<O3> Proporcionar un sistema multilingüe que soporte, como mínimo, español e inglés.
- *O4:*<O4> Cumplir con el marco regulatorio europeo vigente @edpb2025ai (e.g., @glossgdpr @gdpr y @glossaiact @aiactlaw), haciendo uso de validadores como _EU AI Act Compliance Checker_ @euaiactchecker.
- *O5:*<O5> Diseñar una arquitectura siguiendo los estándares de seguridad, escalabilidad y patrones de diseño de software @gangoffour.
- *O6:*<O6> Alinear el proyecto con los Objetivos de Desarrollo Sostenible @ods, representados en la @fig:ods[Figura].
  #figure(
    image("../img/ods.png", width: 80%),
    caption: [Objetivos de desarrollo sostenible.],
  ) <fig:ods>
