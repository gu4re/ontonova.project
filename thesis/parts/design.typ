= Diseño <sec:design>
Este capítulo expone el diseño del sistema como respuesta a los requisitos recogidos en la @sec:requirementexposition. En primer lugar, se presentan la notación arquitectónica y los principios de diseño que gobiernan cada decisión, @sec:designprinciples. A continuación, se desarrolla la arquitectura estática del sistema en sus niveles de contexto, contenedores y componentes, @sec:architecture, completada por el diseño de detalle, @sec:detaildesign, que captura su comportamiento y sus acuerdos: el proceso multi-agente, @sec:agentpipeline, el contrato universal de datos, @sec:datacontract, la comunicación asíncrona, @sec:eventdesign, y las interfaces de programación y exportación a estándares, @sec:apidesign. Posteriormente, se describen las decisiones de seguridad, @sec:securitydesign, cubriendo los riesgos de OWASP @owasp identificados en la @sec:standards. El capítulo concluye con el diseño del despliegue, @sec:deploymentdesign, y la matriz de trazabilidad que vincula cada requisito con los elementos de diseño que lo satisfacen, @sec:designtraceability.

== Gestión del Diseño <sec:designprinciples>
Esta sección establece el marco empleado para documentar la arquitectura, @sec:c4notation, y los principios de diseño que actúan como criterio de decisión transversal, @sec:designtenets, en cumplimiento del objetivo O5 descrito en la @sec:objetivos.

=== Modelo C4 para la Notación Arquitectónica <sec:c4notation>
La arquitectura se ilustra, @sec:architecture, siguiendo el Modelo C4 @c4model, un estándar que organiza la descripción de un sistema en cuatro niveles de abstracción progresivos. Cada nivel actúa a distinta escala, comenzando por el *contexto* que sitúa el sistema frente a sus usuarios y sistemas externos, seguido de los *contenedores* que identifican las unidades ejecutables y desplegables de forma independiente. Los *componentes* revelan la estructura interna de cada contenedor, delegando en el *código* el detalle de la implementación, @sec:dev. Esta aproximación incremental permite que audiencias con distinto grado de conocimiento técnico compartan un mismo enfoque del sistema.

En el presente capítulo se desarrollan los tres primeros niveles, introducidos en la @sec:architecture. El cuarto nivel, correspondiente al detalle del código, se omite deliberadamente siguiendo la recomendación del propio modelo @c4model[Cap. 6], debido a su volatilidad y coste de mantenimiento. Cabe destacar que su contenido queda representado por el contrato de datos, expuesto en la @sec:datacontract, por el repositorio de GitHub @githubrepo y por el @sec:implementation.

=== Principios Rectores <sec:designtenets>
Toda decisión de diseño, recogida en esta parte, se evalúa contra un conjunto reducido de principios, seleccionados durante la fase de elaboración de bocetos descrita en la @sec:methodology:

- *Principio de responsabilidad única.* Cada elemento del sistema posee un único motivo de cambio @cleanarchitecture[Cap. 7]. Este principio gobierna la descomposición del proceso de generación en agentes especializados ---taxonomista, relacional y poblador--- donde cada agente recibe únicamente la porción del contrato de datos que le corresponde, imposibilitando por diseño que invada la responsabilidad de otro, observable en la @sec:agentpipeline.

- *Principio de abierto/cerrado.* El sistema queda abierto a la extensión y cerrado a la modificación @cleanarchitecture[Cap. 8], en respuesta directa al requisito REQ-SW-NF-06. La sustitución del modelo de lenguaje o del motor de inferencia que se utilizan requiere exclusivamente un cambio de configuración, satisfaciendo el REQ-SW-FC-02. Adicionalmente, los formatos de exportación se registran de forma declarativa y el contrato de datos reserva un campo de metadatos extensible para evoluciones futuras.

- *Arquitectura orientada a eventos.* La naturaleza asíncrona de la inferencia del @glossllm exige desacoplar la petición del usuario de la producción del resultado @eda[Cap. 11]. La selección de @glosssse como mecanismo de transporte, justificada en la @sec:eventdrivenarch, condiciona el diseño de la comunicación, desarrollado en la @sec:eventdesign, y cumple con el requisito REQ-US-FC-02.

- *Contrato primero.* Un esquema de datos común, presentado en la @sec:datacontract y anticipado en la @sec:determinism, actúa como fuente de verdad para la generación guiada del modelo de lenguaje, la validación y la compilación a formatos del @glossw3c. Cualquier evolución del sistema parte de la modificación del contrato, y nunca al contrario, eliminando por construcción la deriva entre productores y consumidores del dato.

- *Separación entre lo estocástico y lo determinista.* El componente probabilístico, el @glossllm, queda confinado a la generación de contenido, mientras que toda decisión de aceptación, reparación o rechazo recae en componentes deterministas y verificables. Este principio, consecuencia directa de la alucinación del @glossllm analizada en la @sec:inference, fundamenta el ciclo de validación y autocorrección de la @sec:agentpipeline y las mitigaciones de seguridad de la @sec:securitydesign.
#pagebreak()
== Arquitectura del Sistema <sec:architecture>
Esta sección recorre la estructura estática de OntoNova aplicando los niveles del Modelo C4 @c4model, notación establecida en la @sec:c4notation. El contexto delimita la frontera del sistema frente al usuario y los sistemas externos, @sec:c4context, los contenedores constituyen sus unidades ejecutables y desplegables, @sec:c4containers, y los componentes internos de cada uno de ellos, @sec:c4components.

=== Nivel de Contexto <sec:c4context>
En el primer nivel del Modelo C4 @c4model[Cap. 3], OntoNova se presenta como una caja negra cuyo interior no impacta a esta escala. El verdadero significado recae en la frontera que separa el sistema de las personas y los sistemas que lo rodean. La @fig:c4context recoge esta perspectiva, en la que el sistema se relaciona con un actor humano y una única dependencia externa, quedando ambas interacciones contenidas por la frontera de confianza del despliegue local.

#figure(
  image("../img/c4context.png", width: 100%),
  caption: [Diagrama C4 del contexto del sistema.],
) <fig:c4context>

El actor del sistema es el usuario experto ---médico, jurista, humanista--- que interactúa con OntoNova haciendo uso de la interfaz web para crear, editar, eliminar y exportar ontologías, materializando los casos de uso expuestos en la @sec:usecases. Cabe destacar que la interacción se produce en el idioma del propio usuario, bien describiendo el dominio o bien adjuntando un documento, en cumplimiento de los requisitos REQ-US-FC-01 y REQ-US-FC-10.

La única dependencia externa del sistema es el repositorio de modelos Hugging Face Hub#footnote[Disponible en https://huggingface.co.], consultado una sola vez en la fase del despliegue para la descarga de los pesos del modelo de lenguaje. Superada esa descarga inicial, OntoNova opera localmente, realizando todo el procesamiento, inferencia incluida, dentro de la frontera de confianza representada en la @fig:c4context, sin que los datos del usuario abandonen el entorno local. Esta propiedad, que a nivel de contexto se enuncia como decisión de alcance, fundamenta las garantías de privacidad desarrolladas en la @sec:securitydesign, en cumplimiento de la legislación vigente, @sec:applylaw. Quedan fuera de alcance la edición concurrente y la persistencia entre sesiones, requisitos listados bajo el estado #sym.quote.chevron.l.double;Requiere nuevo diseño#sym.quote.chevron.r.double en la @sec:userrequisites.

=== Nivel de Contenedores <sec:c4containers>
Descendiendo un nivel de abstracción @c4model[Cap. 4], la @fig:c4containers descompone el sistema en unidades ejecutables y desplegables de forma independiente denominadas contenedores#footnote[El término #sym.quote.chevron.l.double;contenedor#sym.quote.chevron.r.double se extrae del Modelo C4, sin relación con la #sym.quote.chevron.l.double;contenerización#sym.quote.chevron.r.double de la @sec:deploymentdesign, aunque en OntoNova los términos tienen correspondencia uno a uno.]. El sistema se compone de tres contenedores ---la aplicación web, el servicio de orquestación y el motor de inferencia--- conectados por dos protocolos que posibilitan los requisitos REQ-SW-FC-02 y REQ-US-FC-02. Cabe resaltar la ausencia de un contenedor de persistencia, cuya incorporación queda delegada al trabajo futuro, @sec:future-work, unida a los requisitos REQ-US-FC-06 y REQ-US-FC-07 que la motivan.

#figure(
  image("../img/c4containers.png", width: 100%),
  caption: [Diagrama C4 de los contenedores del sistema.],
) <fig:c4containers>

La aplicación web es una @glossspa desarrollada en _React_ y _TypeScript_, servida por _Nginx_, que concentra toda la interacción con el usuario. Entre sus responsabilidades destaca la entrada del texto del dominio, mecanografiada o extraída de ficheros en el propio navegador, REQ-US-FC-10, el seguimiento del progreso de generación, REQ-US-FC-02, y el lienzo interactivo de edición que responde directamente al REQ-US-FC-04. La elección de React como marco técnico en este ámbito, rivalizada en la @tab:reactcomparison, queda determinada por la madurez de su ecosistema de visualización de grafos, _React Flow_, sin equivalente en otras alternativas, decisiva para el lienzo interactivo.

#figure(
  table(
    columns: 4,
    align: left + top,
    table.header(
      text(size: 10pt)[*Alternativa*],
      text(size: 10pt)[*Curva de aprendizaje*],
      text(size: 10pt)[*Ecosistema*],
      text(size: 10pt)[*Soporte a grafos interactivos*]
    ),
    table.hline(),
    [VanillaJS], [Alta], [Mínimo], [Deficiente],
    [React], [Media], [Amplio], [Nativo],
    [Angular], [Alta], [Rígido], [Limitado]
  ),
  caption: [Comparativa de alternativas del cliente],
) <tab:reactcomparison>

El _backend_ o servicio de orquestación es una @glossapi desarrollada con el marco de trabajo _FastAPI_, seleccionado por su escasa curva de aprendizaje, documentación enriquecida y retroalimentación rápida. Por otro lado, _LangGraph_ @langgraph, elección debatida en la @sec:agents, ejecuta el proceso multi-agente de generación, la validación determinista y la compilación a formatos @glossw3c, REQ-US-FC-05, concentrando toda la lógica de negocio del sistema. La naturaleza asíncrona de ambos marcos resulta idónea para un servicio cuyo trabajo consiste, esencialmente, en esperar a un modelo de lenguaje sin bloquear al resto de usuarios.

En tercer lugar, el motor de inferencia está compuesto por una instancia de _vLLM_. Como es observable en la comparativa de la @tab:vllmcomparison, la selección resulta crítica para sobrevivir a la latencia, tráfico, errores y saturación del sistema. _vLLM_ soporta una concurrencia elevada por su arquitectura _paged attention_ orientada a maximizar la tasa de procesamiento de la @glossgpu bajo demanda; sin embargo, _Ollama_ y _llama.cpp_ se centran en inferencia local optimizada para un individuo: bajo cargas concurrentes, _vLLM_ alcanza una tasa de procesamiento entre 20 y 29 veces superior y una latencia P95 entre 8 y 19 veces menor que Ollama, completando la totalidad de las peticiones @vllmbenchmark. En la decodificación guiada por gramática sobre la @glossgpu local, la técnica que garantiza salidas estructuralmente válidas, analizada en la @sec:determinism, _vLLM_ supera a sus alternativas debido a librerías optimizadas en creación de máquinas de estado, _XGrammar_, en contraparte con la @glossgbnf flexible pero de alto coste computacional de _Ollama_ y _llama.cpp_. Cabe resaltar que todas las alternativas de código abierto mencionadas disponen de compatibilidad con el protocolo _OpenAI_. En consecuencia, el contenedor queda colocado detrás de una @glossapi, lo que permite que el _backend_ desconozca qué modelo sirve, respetando la separación de responsabilidades @cleanarchitecture[Cap. 7] y cumpliendo con el requisito REQ-SW-FC-02, además de obedecer al principio de inversión de dependencias @cleanarchitecture[Cap. 11] y seguir el principio de abierto/cerrado establecido en la @sec:designtenets.

#figure(
  table(
    columns: 5,
    align: left + top,
    table.header(
      text(size: 10pt)[*Alternativa*],
      text(size: 10pt)[*Orientación*],
      text(size: 10pt)[*Tasa de \ procesamiento*],
      text(size: 10pt)[*Decodificación guiada*],
      text(size: 10pt)[*Protocolo OpenAI*]
    ),
    table.hline(),
    [vLLM], [Multiusuario], [Alta], [Optimizada \ (_XGrammar_)], [Compatible],
    [Ollama], [Monousuario], [Baja], [Costosa (@glossgbnf)], [Compatible],
    [llama.cpp], [Biblioteca \ embebida], [Baja], [Costosa (@glossgbnf)], [Compatible]
  ),
  caption: [Comparativa de alternativas del motor de inferencia],
) <tab:vllmcomparison>

En cuanto a los conectores, la aplicación web se comunica con el servicio de orquestación mediante peticiones @glossjson sobre @glosshttp, y recibe el progreso de la generación como un flujo de eventos @glosssse, acatando el requisito REQ-US-FC-02 y consumando la arquitectura orientada a eventos justificada en la @sec:eventdrivenarch. Dicho diseño no contempla un contenedor de persistencia. OntoNova opera sin estado, pues el conocimiento generado vive exclusivamente en la sesión del navegador del usuario hasta que este decide exportarlo o eliminarlo, sin dejar rastro en el servidor. Esta decisión borra por construcción toda una categoría de riesgos sobre los datos del usuario, facilita el cumplimiento de la legislación aplicable, @sec:applylaw, cuyas garantías se presentan en la @sec:securitydesign, y simplifica el despliegue descrito en la @sec:deploymentdesign.

=== Nivel de Componentes <sec:c4components>
A una mayor granularidad, concretamente hacia el interior de los contenedores, se revelan sus componentes @c4model[Cap. 5], que quedan asignados a abstracciones reales en función de su código. Es decir, se agrupan funcionalidades relacionadas tras una interfaz bien definida.

La aplicación web, cuya estructura interna recoge la @fig:c4frontend, ofrece al usuario dos puntos de entrada que se corresponden con los casos de uso de la @sec:usecases. Estos son el panel de creación, donde describe el dominio y sigue el progreso de la generación por etapas, REQ-US-FC-02, y el lienzo interactivo, donde refina y exporta el grafo resultante. El inspector completa la tríada de vistas, habilitando la edición de los atributos e individuos de la clase seleccionada. Los tres componentes de interfaz se articulan en torno al almacén de estado, fuente de verdad de la ontología en edición; leen y mutan dicho almacén sin comunicarse jamás entre sí, un patrón unidireccional que elimina por diseño las inconsistencias entre vistas. Cabe destacar que el almacén replica la estructura del contrato de datos, @sec:datacontract, de modo que el estado del lienzo resulta exportable en cualquier instante, REQ-US-FC-05. Por otro lado, el panel de creación delega en el extractor de documentos la obtención del texto en el propio navegador, REQ-US-FC-10, reforzando la frontera de privacidad establecida en la @sec:c4context. Por último, la capa de @glossapi concentra toda la comunicación con el servicio de orquestación a través de la generación asíncrona y la revalidación de cada mutación del grafo, que mantiene el cumplimiento del REQ-US-FC-04 en caliente.

#figure(
  image("../img/c4frontend.png", width: 100%),
  caption: [Diagrama C4 de los componentes de la aplicación web.],
) <fig:c4frontend>

Por su parte, el servicio de orquestación o _backend_ se organiza en tres capas #footnote[El motor de inferencia no se desgrana al tratarse de un producto de terceros.], visibles en la @fig:c4backend. Se establece una separación clara de responsabilidades, posibilitando su mantenimiento, escalado e independencia entre ellas @cleanarchitecture[Cap. 22]. 

En la capa de transporte, el _router_ de ontologías expone los tres recursos del sistema ---generación, validación y exportación--- detallados en la @sec:apidesign. La capa de dominio concentra el conocimiento de negocio en el contrato de datos, la fuente de verdad que gobierna el sistema, @sec:datacontract. La inteligencia queda contenida en el grafo multi-agente, que orquesta a los agentes especializados junto a su ciclo de ejecución y autocorrección, @sec:agentpipeline, en tanto que el validador determinista ejecuta las comprobaciones de integridad estructural y referencial que exige el REQ-US-FC-05, cumpliendo con la separación entre lo estocástico y lo determinista comprometida en la @sec:designtenets. Finalmente, los adaptadores sirven de capa de salida hacia el exterior, disponiendo de un cliente de inferencia que encapsula el protocolo _OpenAI_ y un compilador @glossrdf que serializa el conocimiento a formatos estándar del @glossw3c.

#figure(
  image("../img/c4backend.png", width: 100%),
  caption: [Diagrama C4 de los componentes del servicio de orquestación.],
) <fig:c4backend>

== Diseño de Detalle <sec:detaildesign>
Definida la estructura, esta sección desciende al comportamiento y a los acuerdos que la gobiernan. Se abre con la vista dinámica del sistema ---el diagrama suplementario que el Modelo C4 @c4model reserva para la colaboración en tiempo de ejecución--- aplicada al proceso multi-agente de generación, @sec:agentpipeline. En divisiones posteriores, el contrato universal de datos se erige como fuente de verdad del sistema, @sec:datacontract, seguido del diseño de la comunicación asíncrona, @sec:eventdesign, y las interfaces de programación junto a la exportación a formatos estándar del @glossw3c, @sec:apidesign.

=== Proceso Multi-agente de Generación <sec:agentpipeline>
El Modelo C4 reserva un espacio para la vista dinámica del sistema @c4model[Cap. 7]. Esta sección aprovecha dicho espacio para para ilustrar, en el diagrama de actividad de la @fig:agentpipeline @umlfowler[Cap. 11], el recorrido de una petición de generación desde el texto del dominio hasta su evento terminal, acatando el requisito REQ-US-FC-03, que exige una ontología que supere la validación con degradación elegante ante el fallo.

Como guardarraíl previo, toda petición atraviesa una comprobación determinista de longitud derivada de los límites de los requisitos REQ-US-FC-01 y REQ-US-FC-10, rechazando con un mensaje accionable las entradas que excedan la ventana de contexto del modelo en funcionamiento. Superada esta fase, la cadena de generación encadena tres agentes construidos con _LangGraph_ @langgraph: el taxonomista extrae las clases y su jerarquía, el relacional declara las propiedades de objeto y de datos sobre las clases ya existentes, y el poblador identifica los individuos y sus aserciones. Cada agente opera bajo un esquema de salida acotado a la porción del contrato que le corresponde, tal y como anticipó la @sec:designtenets, de modo que la decodificación guiada de la @sec:determinism imposibilita estructuralmente que un agente invada el terreno de otro.

El validador determinista cierra el ciclo evaluando la estructura, las referencias cruzadas y la conformidad de cada aserción con el dominio y rango declarados. Ante un resultado inválido, el sistema aplica un procedimiento de tres pasos que reserva el coste de la inferencia para los errores genuinamente semánticos. En primer lugar, una reparación sin pérdidas corrige de forma determinista los errores triviales como identificadores duplicados, referencias con grafía inconsistente y aserciones de dirección invertida, sin consumir reintento alguno. Si el error persiste, el validador identifica la etapa responsable a partir del propio mensaje de error y relanza la cadena desde ella, adjuntando al agente su salida previa junto a la instrucción de corregirla sin regenerarla, evitando que el modelo descarte contenido válido @llmhallucination para esquivar el error. 

Agotado el presupuesto de cuatro reintentos, el último paso poda las aserciones inválidas y entrega un grafo válido aunque empobrecido, reservando el fallo total a los defectos que ninguna poda puede resolver. Toda ruta, incluida la de fallo, concluye con un evento terminal que es la invariante sobre la que descansa la comunicación asíncrona disponible en la @sec:eventdesign.

#figure(
  image("../img/agentpipeline.png", width: 100%),
  caption: [Diagrama de actividad del proceso multi-agente de generación#context if not state("in-outline", false).get() [#footnote[La figura asume que el agente culpable es el taxonomista; el destino real es la etapa que el error señala.]].],
) <fig:agentpipeline>

=== Contrato Universal de Datos <sec:datacontract>
Todo el sistema pivota sobre un esquema de datos, _OntoNovaSchema_, que implanta el principio de contrato primero establecido en la @sec:designtenets. El contrato actúa como gramática de la decodificación guiada, apoyando a que cada agente reciba la porción del esquema que le corresponde, @sec:agentpipeline. A su vez, fundamenta las fases de validación determinista y de compilación a los formatos del @glossw3c, @sec:apidesign. Cabe resaltar que cualquier evolución del sistema parte del contrato extensible @githubrepo, nunca al contrario, evitando incoherencias entre productores y consumidores. La @tab:datacontract descompone su estructura en las cuatro entidades que lo forman, alineadas con los pilares de la representación del conocimiento expuestos en la @sec:semanticweb.

#figure(
  table(
    columns: 3,
    align: (left + top, left + top, left + top),
    table.header(
      text(size: 10pt)[*Entidad*],
      text(size: 10pt)[*Campos principales*],
      text(size: 10pt)[*Papel semántico*]
    ),
    table.hline(),
    [Clase], [`id`, `name`, `subClassOf`], [Concepto del dominio y su jerarquía taxonómica],
    [Propiedad de objeto], [`id`, `name`, `domain`, `range`, `characteristics`], [Relación binaria entre clases],
    [Propiedad de datos], [`id`, `name`, `domain`, `range`], [Atributo literal con tipo primitivo @glossxml],
    [Individuo], [`id`, `name`, `typeClass`, aserciones], [Instancia concreta y sus hechos]
  ),
  caption: [Entidades del contrato universal de datos],
) <tab:datacontract>

Los identificadores obedecen un patrón alfanumérico porque se utilizan directamente como nombres de recurso @glossrdf en el caso de uso de exportar una ontología, restricción que neutraliza por construcción la inyección de contenido malicioso en la frontera del esquema, mitigación expandida en la @sec:securitydesign. Otra característica del contrato es la prohibición de todo campo no declarado, de modo que alucinaciones del @glossllm @llmhallucination provocan un fallo de validación, con su consiguiente autocorrección, en lugar de propagarse silenciosamente. Por último, cada entidad reserva un campo de metadatos extensible, la vía de evolución prevista por el principio de abierto/cerrado de la @sec:designtenets.

En términos de expresividad, el contrato define un perfil reducido de @glossowl compuesto por jerarquías mediante `subClassOf`, propiedades con dominio y rango, las siete características de propiedad del estándar ---funcional, inversa funcional, transitiva, simétrica, asimétrica, reflexiva e irreflexiva---, cinco tipos primitivos#footnote[Los tipos primitivos soportados son: `string`, `integer`, `float`, `boolean`, `dateTime`.] y las aserciones de individuos. Quedan fuera las restricciones de cardinalidad, las clases anónimas y los axiomas de equivalencia; elementos que herramientas exhaustivas como _Protégé_ ofrecen a cambio, precisamente, de la complejidad que este trabajo pretende abstraer, tal y como recoge la @sec:sbcaialternatives. Su incorporación gradual se anota en la @sec:future-work, sin coste estructural gracias al campo de metadatos.

=== Comunicación Asíncrona de Eventos <sec:eventdesign>
Justificada la elección de @glosssse como mecanismo de transporte en la @sec:eventdrivenarch, esta sección diseña el vocabulario del canal de comunicación, catalogado en la @tab:events, declarando los eventos que el servicio de orquestación emite hacia la aplicación web durante la generación. Cada transición del proceso descrito en la @sec:agentpipeline produce un evento, permitiendo que la interfaz refleje el estado real de la generación con la latencia máxima de un segundo que impone el requisito REQ-US-FC-02.

#figure(
  table(
    columns: (1.1fr, 1.8fr, 3.6fr),
    align: (left + top, left + top, left + top),
    table.header(
      text(size: 10pt)[*Estado*],
      text(size: 10pt)[*Carga útil*],
      text(size: 10pt)[*Etapa*]
    ),
    table.hline(),
    [Completado], [], [Taxonomista #sym.bullet Relacional #sym.bullet Poblador #sym.bullet Validador],
    [En reintento], [Motivo del error], [Validador],
    [Fallo], [Motivo y, si procede, código con parámetros], [Validador #sym.bullet Generación #sym.bullet Fin],
    [Éxito], [Grafo completo], [Fin]
  ),
  caption: [Catálogo de eventos del flujo de generación],
) <tab:events>

Toda petición, con independencia de su desenlace ---éxito o fallo---, concluye con un evento de cierre que transporta el grafo, con o sin poda, o el motivo del error. La aplicación web libera la interfaz al recibirlo y trata como error cualquier flujo que se cierre sin él, de esta manera ningún fallo del servicio, del @glossllm o de la red puede dejar al usuario esperando indefinidamente, logrando la resiliencia comprometida en el requisito REQ-SW-NF-03. Adicionalmente, los eventos de fallo transportan, junto a un texto descriptivo, un código de error acompañado de sus parámetros, permitiendo a la aplicación web presentar el error localizado en el idioma del usuario, en coherencia con el carácter multilingüe del sistema, REQ-US-FC-01, sin privar de contexto a los consumidores directos de la @glossapi, cuyos recursos se detallan en la @sec:apidesign.

=== Interfaces de Programación y Exportación <sec:apidesign>
El servicio de orquestación publica tres recursos de @glossapi consumidos por la aplicación web. Primeramente, la *generación* se modela en _streaming_, alejado del clásico esquema petición-respuesta. El cliente formula una solicitud y recibe el canal de eventos de la @sec:eventdesign, asumiendo la asimetría entre lo inmediato de preguntar y lo costoso de inferir. Segundamente, la *validación*, a diferencia de la convención habitual de una @glossapi @eda[Cap. 4], un grafo inválido no constituye un error en la petición, sino una respuesta aceptada que transporta los defectos de forma estructurada. El motivo es cuestión de diseño, porque a lo largo de la edición sobre el lienzo, el estado intermedio inválido es lo esperado porque, por ejemplo, el usuario aún no ha conectado dos clases o está renombrando un atributo. Tratarlo como excepción convertiría el ciclo de revalidación del requisito REQ-US-FC-04 en un flujo permanente de errores. Por último, la *exportación* se alinea con REQ-US-FC-05 y solo compila a un formato del @glossw3c aquello que supera la validación determinista, evitando la fuga de archivos inválidos, bien por incumplimiento del estándar o bien por incompatibilidad con el contrato de la @sec:datacontract.

== Diseño de Seguridad <sec:securitydesign>
La seguridad de OntoNova no constituye un módulo adicional, sino una evaluación a las decisiones tomadas bajo la lente del riesgo, pues cada mitigación que se expone a continuación es una decisión de diseño presentada en el transcurso del capítulo, ahora justificada frente a los cuatro riesgos del OWASP Top 10 GenIA/LLM identificados en la @sec:standards. Se establece una defensa en profundidad, descendiendo por los niveles que estructuran la @sec:architecture, estrechando la protección a medida que el dato se acerca al modelo de lenguaje.

La protección comienza en el nivel de contexto, donde la frontera de confianza enunciada en la @sec:c4context se convierte en la garantía de privacidad allí prometida. Al operar el sistema en local y sin estado, @sec:c4containers, el conocimiento del dominio, potencialmente confidencial en manos de un médico o un jurista, ni atraviesa la frontera ni persiste tras la sesión, y el único contacto con el exterior, la descarga inicial de los pesos del modelo, no transporta dato alguno del usuario. Esta doble ausencia neutraliza por construcción la divulgación de información sensible @owasp[LLM02] y facilita el cumplimiento de la legislación aplicable, @sec:applylaw, pues no puede filtrarse lo que nunca sale ni almacenarse lo que nunca se guarda.

Un nivel por debajo, los contenedores acotan las vías de entrada y salida. El motor de inferencia permanece aislado tras el protocolo estándar de la @sec:c4containers, la aplicación web solamente acepta orígenes cruzados autorizados y el suministro de dependencias se produce sin vulnerabilidades de severidad alta, verificado en el @sec:verification en conformidad con el requisito REQ-SW-NF-02. La contención más fina ocurre, sin embargo, en el nivel de componentes, donde gobierna la separación entre lo estocástico y lo determinista comprometida en la @sec:designtenets. La decodificación guiada acota la salida del modelo a la gramática del contrato, por lo que una inyección de _prompts_ @owasp[LLM01] puede sesgar el contenido generado, pero nunca escapar de la estructura ni desencadenar acción alguna debido a que el modelo está capacitado exclusivamente para rellenar un esquema, careciendo de herramientas invocables o privilegios del sistema. Cuanto rellena tampoco se integra a ciegas, porque el contrato de la @sec:datacontract prohíbe los campos desconocidos y restringe los identificadores de recurso @glossrdf, saneando las salidas del @glossllm antes de que alcancen el lienzo interactivo o la exportación @owasp[LLM05].

Existe, no obstante, un riesgo que escapa a la gramática, producido por una alucinación estructuralmente válida que supone una desinformación @owasp[LLM09] indetectable para el esquema. Su contención recae en el validador determinista y el ciclo de autocorrección de la @sec:agentpipeline, que eliminan las inconsistencias referenciales, y su arbitraje final, en el experto que revisa y refina el grafo sobre el lienzo, en consonancia con la supervisión humana que demanda el marco regulatorio, @sec:applylaw. 

// Si acudes aqui porque has quitado la propuesta de exposición publica y falla la referencia a la seccion, coloca @sec:vending y asegurate de cambiar el articulo, en vez de "el" pon "la"
Otros riesgos ligados a requisitos no incluidos como la autenticación y autorización, REQ-SW-NF-07, o el registro de usuarios reclamado por el requisito REQ-US-FC-09, retrasan su examen al escenario de exposición pública contemplado en el @sec:cloud, puesto que un despliegue local y monousuario no las requiere.

== Diseño de Despliegue <sec:deploymentdesign>
El despliegue se documenta mediante el diagrama suplementario con el que el Modelo C4 completa la vista estática @c4model[Cap. 8], respondiendo a la cuestión de dónde vive cada contenedor. La @fig:c4deployment sitúa el sistema completo en un nodo, el equipo del experto, donde la correspondencia anticipada en la @sec:c4containers se hace realidad, debido a que cada contenedor arquitectónico se materializa en un contenedor de _Docker_ orquestado por `docker compose`. La aplicación web es la pieza que escapa parcialmente a dicha correspondencia, ya que se distribuye desde el servidor estático _nginx_ pero se ejecuta en el navegador del propio computador, consumiendo el servicio de orquestación bajo los orígenes autorizados, @sec:securitydesign.

#figure(
  image("../img/c4deployment.png", width: 100%),
  caption: [Diagrama C4 de despliegue del sistema.],
) <fig:c4deployment>

La composición de contenedores adopta un comando de lanzamiento, configurable con variables de entorno. A su vez, dado que los contenedores dependen entre sí, los _health checks_ gobiernan el orden de arranque, por ejemplo, el servicio de orquestación no acepta trabajo hasta que el motor de inferencia supera su comprobación de despliegue. Se emplea un volumen persistente a modo de caché que conserva los pesos del modelo, logrando, una vez poblado el volumen, un arranque por debajo de cinco minutos, REQ-SW-NF-08, verificable en el @sec:verification. Asimismo, se reduce la descarga desde Hugging Face Hub#footnote[Disponible en https://huggingface.co.] a un solo evento en la vida del despliegue, tal y como enuncia la @sec:c4context.

El nodo de trabajo necesita un anfitrión con _Docker_, una @glossgpu compatible con la @glosscuda y sus respectivas librerías, _NVIDIA Container Toolkit_. Aunque carece de dependencia de servicios externos, sí necesita un núcleo Linux ---nativo o virtualizado---, la única plataforma soportada por _vLLM_. Aun así, consuma el carácter agnóstico del _hardware_ que requiere el requisito REQ-SW-NF-08 y preserva la frontera de confianza en cualquier anfitrión. Esa neutralidad habilita el camino inverso, es decir, la composición que se despliega en el equipo del experto es la que un proveedor de exposición pública puede ejecutar con leves modificaciones, escenario propuesto en el @sec:cloud.

== Trazabilidad de Requisitos <sec:designtraceability>
La propiedad de trazabilidad solicitada por los estándares de la @sec:requirementstandard se refleja en la @tab:designtraceability, para los requisitos de usuario, y en la @tab:designtraceabilitysw, para los del sistema, que vinculan cada requisito de la @sec:requirementexposition con los elementos de diseño que lo satisfacen. Los requisitos diferidos no quedan huérfanos, sino trazados a la decisión de alcance que los pospone; los de naturaleza operativa ---soporte, pruebas y documentación--- se remiten al proceso que los gobierna porque no adoptan forma de diseño. La comprobación de que cada elemento cumple su métrica no corresponde al diseño, sino al @sec:verification, cuya matriz de verificación toma la @tab:designtraceability y la @tab:designtraceabilitysw[] como punto de partida.

#figure(
  table(
    columns: (auto, 1fr),
    align: (left + top, left + top),
    table.header(
      text(size: 10pt)[*Requisito*],
      text(size: 10pt)[*Elementos de diseño*]
    ),
    table.hline(),
    [REQ-US-FC-01], [Panel de creación, @sec:c4components, y comprobación de longitud, @sec:agentpipeline.],
    [REQ-US-FC-02], [Conector @glosssse, @sec:c4containers, y catálogo de eventos, @sec:eventdesign.],
    [REQ-US-FC-03], [Proceso multi-agente con degradación elegante, @sec:agentpipeline.],
    [REQ-US-FC-04], [Lienzo y almacén de estado, @sec:c4components, y validación reactiva, @sec:apidesign.],
    [REQ-US-FC-05], [Exportación como guardián, @sec:apidesign, y compilador @glossrdf, @sec:c4components.],
    [REQ-US-FC-06], [Diferido junto a la persistencia, @sec:c4containers, a la @sec:future-work.],
    [REQ-US-FC-07], [Diferido junto a la persistencia, @sec:c4containers, a la @sec:future-work.],
    [REQ-US-FC-08], [Diferido a la @sec:future-work.],
    [REQ-US-FC-09], [Diferido, @sec:securitydesign, al @sec:cloud.],
    [REQ-US-FC-10], [Extracción de documentos, @sec:c4components, y comprobación de longitud, @sec:agentpipeline.],
    [REQ-US-NF-01], [Componentes de interfaz y patrón unidireccional, @sec:c4components.],
    [REQ-US-NF-02], [@glossspa servida en local, @sec:c4containers y @sec:deploymentdesign.],
    [REQ-US-NF-03], [Proceso operativo, sin forma de diseño.]
  ),
  caption: [Matriz de trazabilidad de requisitos de usuario a elementos de diseño],
) <tab:designtraceability>

#figure(
  table(
    columns: (auto, 1fr),
    align: (left + top, left + top),
    table.header(
      text(size: 10pt)[*Requisito*],
      text(size: 10pt)[*Elementos de diseño*]
    ),
    table.hline(),
    [REQ-SW-FC-01], [Diferido a la @sec:future-work.],
    [REQ-SW-FC-02], [Conector _OpenAI_, @sec:c4containers, cliente de inferencia, @sec:c4components, y variables de entorno, @sec:deploymentdesign.],
    [REQ-SW-NF-01], [Diferido a la @sec:future-work.],
    [REQ-SW-NF-02], [Cadena de suministro auditada, @sec:securitydesign.],
    [REQ-SW-NF-03], [Invariante del evento terminal, @sec:eventdesign, y escalera de degradación, @sec:agentpipeline.],
    [REQ-SW-NF-04], [Proceso de pruebas, delegado al @sec:verification.],
    [REQ-SW-NF-05], [Proceso documental del proyecto, sin forma de diseño.],
    [REQ-SW-NF-06], [Principio de abierto/cerrado, @sec:designtenets, y metadatos extensibles, @sec:datacontract.],
    [REQ-SW-NF-07], [Diferido, @sec:securitydesign, al @sec:cloud.],
    [REQ-SW-NF-08], [Composición y arranque de contenedores, @sec:deploymentdesign.]
  ),
  caption: [Matriz de trazabilidad de requisitos del sistema a elementos de diseño],
) <tab:designtraceabilitysw>