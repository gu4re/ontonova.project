= Estado del Arte <sec:stateofart>
Este capítulo detalla la evolución a la web semántica, @sec:semanticweb, la inferencia del conocimiento, @sec:inference, y la alucinación del @glossllm, @sec:determinism, concluyendo con la orquestación de agentes inteligentes, @sec:agents, en arquitecturas de eventos, @sec:eventdrivenarch.

== De la Web Sintáctica a la Semántica <sec:semanticweb>
A comienzos del siglo XXI, surge una crítica esencial @semanticwebbook a la @glosswww, señalando que la mayor parte de su contenido está diseñado para el consumo humano y no para ser procesado significativamente por programas informáticos. Aunque los ordenadores pueden analizar con suma eficacia el diseño o forma de una página web, carecen de métodos fiables para interpretar su semántica de forma aislada. En consecuencia, nace la Web Semántica o Web 3.0, como una extensión progresiva de la web existente. En este nuevo paradigma, la información toma estructura y un significado bien definido, lo que facilita y mejora sustancialmente la cooperación entre personas y máquinas. 

Para que esta visión se materialice y adquiera una estandarización global, los computadores necesitan acceder a colecciones estructuradas de datos y a conjuntos de reglas de inferencia que les permitan elaborar un razonamiento automatizado. La Web Semántica asume que la versatilidad requiere tolerar y aceptar que existen preguntas sin respuesta. Por lo tanto, el desafío radica en la creación de un lenguaje capaz de expresar simultáneamente tanto los datos como las reglas necesarias para razonar sobre ellos. Por un lado, @glossxml ofrece las características previas, permitiendo adicionalmente la creación de estructuras arbitrarias con etiquetas ocultas. Por otro lado, @glossrdf articula el significado previo mediante _tripletas_  que funcionan como afirmaciones compuestas por sujeto, verbo y objeto. Para evitar la ambigüedad del lenguaje natural, cada elemento lógico se identifica con un @glossuri, evitando confusiones semánticas.

No obstante, para que distintas bases de datos puedan interoperar correctamente, es preciso que reconozcan cuándo están utilizando identificadores diferentes para referirse a un mismo concepto. Esta necesidad queda resuelta con el concepto de *ontología*, que, queda definido como el campo que define las relaciones entre distintos términos. Las ontologías proporcionan *taxonomías* para clasificar objetos y reglas de inferencia que dotan a los sistemas de una potente capacidad deductiva. Además, actúan como mecanismo para establecer relaciones de equivalencia que resuelven discrepancias de vocabulario entre distintos dominios de información. El @glossowl @owldeclaration se apoya en el marco y lenguaje mencionado, pues proporciona una lógica de descripción matemáticamente precisa, permitiendo modelar clases, propiedades e individuos bajo un formalismo estricto.

Históricamente, la confección de las ontologías se produce en herramientas como Protégé. Representa el estándar de facto en la industria y en la academia, pues nace para combatir el cuello de botella de adquisición del conocimiento @knowledgebottleneck. Su interfaz rígida basada en jerarquías textuales y asunciones lógicas genera una barrera de entrada elevada que requiere la intervención de un ingeniero del conocimiento cualificado. Este hecho evidencia la necesidad de alternativas que presenten una capa de abstracción y acerquen el modelado semántico al verdadero experto del dominio, presentando un lienzo de partida al ingeniero.

== Inferencia de Conocimiento del Presente <sec:inference>
Mitigando el cuello de botella mencionado, la investigación en el @glossnlp evoluciona hacia la extracción automatizada de relaciones a partir de texto. La consolidación de los _transformers_ @transformers, ilustrado en la @fig:transformers[Figura], y la llegada del @glossllm, la inferencia de estructuras semánticas con información no estructurada crece exponencialmente.

#figure(
  image("../img/transformers.png", width: 38%),
  caption: [Modelo arquitectónico de un transformer @transformers.],
) <fig:transformers>

Sin embargo, un @glossllm es intrínsecamente estocástico y probabilístico. Queda advertido el riesgo de solicitar a un modelo generativo la escritura directa de sintaxis formal @llmhallucination, e.g, una ontología en código @glossowl. Una simple omisión de un carácter invalida por completo el documento resultante frente a los razonadores lógicos. En consecuencia, delegar la generación directa de una ontología a la @glossai resulta inviable en entornos productivos sin la existencia de mecanismos de contención, véase @sec:determinism, que garanticen el determinismo de las respuestas.

== De la Alucinación al Determinismo <sec:determinism>
Al comienzo, con la integración del @glossllm entre sistemas, para resolver la dicotomía entre la creatividad fluida de la @glossai y la rigidez formal de la web semántica (véase @sec:semanticweb), la obtención de respuestas estructuradas ha dependido de la ingeniería de instrucciones y de técnicas heurísticas de posprocesamiento. Peticiones imperativas en lenguaje natural —como «Responde únicamente en formato @glossjson»— se convirtieron en el estándar. Sin embargo, el @glossllm introduce, frecuentemente, preámbulos o epílogos que provocan el fallo de algoritmos clásicos de procesamiento de texto. 

Para mitigar esta falta de determinismo sintáctico, la industria presenta el denominado *modo @glossjson* (véase @fig:jsonmode). Al fijar el `text.format` a `{"type":"json_object"}`, el modelo es forzado a generar una cadena de caracteres que constituya un objeto @glossjson válido, suprimiendo texto auxiliar @structuredoutputs. No obstante, aunque este modo garantiza la validez sintáctica del formato, no asegura el cumplimiento de una estructura de datos predefinida. El modelo sigue omitiendo claves obligatorias, inventando nuevas propiedades @llmhallucination o alterando los tipos de datos esperados, lo que impide establecer un contrato de datos fiable al integrarse con otros sistemas, e.g, motores de inferencia lógica o aplicaciones web.

#figure(
  image("../img/jsonmode.png", width: 80%),
  caption: [Funcionamiento del modo JSON @structuredoutputs.],
) <fig:jsonmode>

En definitiva, la generación de salidas deterministas alcanza su climax con las *salidas estructuradas* @structuredoutputs respaldadas por esquemas @glossjson de validación, observable en la @fig:structuredoutputs. Se garantiza que la información extraída por la @glossai cumpla con los tipos de datos, cardinalidades y formatos requeridos antes de ser procesada por otros sistemas. 

Esta evolución interviene en el proceso de decodificación del modelo, _grammar-based sampling_ @structuredoutputs, donde el motor de inferencia traduce el esquema @glossjson a una gramática formal, enmascarando las probabilidades de caracteres, _logit filtering_ @structuredoutputs. En consecuencia, los _tokens_ resultantes cumplen estrictamente el contrato de datos, consolidando como fuente de verdad un esquema @glossjson común, presentado en el @sec:design, implementado en el @sec:implementation.

#figure(
  image("../img/structuredoutputs.png", width: 80%),
  caption: [Funcionamiento de las salidas estructuradas @structuredoutputs.],
) <fig:structuredoutputs>

== Orquestación de Agentes Inteligentes <sec:agents>
La complejidad inmanente al diseño y generación de una ontología completa hace ineficiente delegar toda la carga cognitiva a una única instrucción o modelo. La degradación del contexto en un @glossllm provoca una pérdida de información cuando se procesan dominios extensos @llmhallucination. Adicionalmente, el diseño propuesto genera un punto de fallo crítico en el sistema, eliminando el Principio de Responsabilidad Única @gangoffour.

Como solución, el modelo de negocio evoluciona hacia la orquestación de agentes. Esta estrategia permite dividir un problema complejo en tareas atómicas gestionadas por «un programa diseñado para percibir su entorno, razonar, tomar decisiones y ejecutar acciones de manera autónoma» @agentreasoning. En la @tab:llmcomparison se expone una evaluación de las principales alternativas del presente estado del arte, en función de los requisitos para la validación semántica.

#figure(
  table(
    columns: 6,
    table.header(
      text(size: 10pt)[*Herramienta*],
      text(size: 10pt)[*Paradigma*],
      text(size: 10pt)[*Control flujo*],
      text(size: 10pt)[*Transparencia*],
      text(size: 10pt)[*Memoria*],
      text(size: 10pt)[*Multi-agente*],
    ),
    table.hline(),
    [LangChain], [Secuencial], [Medio], [Media], [Básica], [Parcial],
    [AutoGPT], [Autónomo], [Bajo], [Baja], [Limitada], [Parcial],
    [CrewAI], [Colaborativo], [Medio], [Media], [Interna], [Nativo],
    [LangGraph], [Grafo], [Muy alto], [Alta], [Persistente], [Nativo],
  ),
  caption: [Comparativa de herramientas de orquestación],
) <tab:llmcomparison>

Ante este análisis, se escoge la herramienta de código abierto @opensourcellms de orquestación basados en grafos, _LangGraph_ @langgraph como la solución óptima. A pesar de la base que presentan sus competidores en ciclos de razonamiento y acción @agentreasoning, contienen limitaciones para sistemas productivos debido a la falta de control explícito del estado y del flujo. _LangGraph_ @langgraph representa una evolución donde agentes, herramientas y decisiones pueden modelarse como estados y transiciones verificables.

Sin embargo, el despliegue de modelos y orquestadores de @glossai introduce un desafío crítico, especialmente en la comunicación, pues si bien una petición tradicional se resuelve en milisegundos, la generación de texto de un @glossllm requiere operaciones síncronas intensivas de cómputo. La @sec:eventdrivenarch, presenta una alternativa al patrón de diseño mencionado @gangoffour, ofreciendo retroalimentación al usuario del sistema de gestión del conocimiento.

== Arquitectura Orientada a Eventos <sec:eventdrivenarch>
La literatura en ingeniería de software establece que las arquitecturas síncronas tradicionales, fundamentadas en arquitecturas cliente-servidor, presentan problemas al hacer frente a procesos intensos de cómputo @eda[Cap. 4]. Cuando se integra un @glossllm en el lado del servidor, el tiempo de inferencia del procesamiento semántico puede extenderse en gran medida, generando bloqueos en el hilo de ejecución del cliente y provocando un riesgo inminente de desconexión por tiempo de espera o _timeout_. Ante esta problemática, se propone la adopción de una arquitectura orientada a eventos, respetando los patrones de diseño @gangoffour, donde los componentes se desacoplan y reaccionan de manera asíncrona a la disponibilidad paulatina de la información.

En la @tab:eda se exponen los diversos paradigmas de comunicación aplicables a la entrega de datos diferidos, comparando enfoques tradicionales con tecnologías nativas de eventos.

#let doublearrow = sym.arrow.l.r
#let arrow = sym.arrow.r

#figure(
  table(
    columns: 6,
    table.header(
      text(size: 10pt)[*Paradigma*],
      text(size: 10pt)[*Comunicación*],
      text(size: 10pt)[*Estado*],
      text(size: 10pt)[*Latencia*],
      text(size: 10pt)[*Complejidad*],
      text(size: 10pt)[*Streaming*],
    ),
    table.hline(),
    [REST], [Cliente #arrow Servidor], [Sin estado], [Alta], [Baja], [Limitado],
    [Polling], [Cliente #doublearrow Servidor], [Sin estado], [Media], [Media], [Limitado],
    [WebSockets], [Cliente #doublearrow Servidor], [Persistente], [Baja], [Alta], [Continuo],
    [SSE], [Servidor #arrow Cliente], [Sin estado], [Baja], [Media], [Incremental],
  ),
  caption: [Comparativa de paradigmas de comunicación cliente-servidor],
) <tab:eda>

Por un lado, exigir a la aplicación web que consulte repetidamente al servidor, _polling_, satura la red, mientras que esperar a la conclusión total del modelo, _ @glossrest _, degrada drásticamente la interactividad. Por otro lado, aunque protocolos como _Web Sockets_ habilitan la comunicación fluida en tiempo real, su naturaleza persistente y bidireccional introduce una sobrecarga innecesaria y un consumo de recursos excesivo para un flujo donde el cliente actúa como receptor una vez emitida la petición inicial. 

En consecuencia, la tecnología _@glosssse _emerge como el estándar técnico idóneo para la transmisión asíncrona en plataformas semánticas @eda[Cap. 11]. Operando de forma nativa sobre el @glosshttp, @glosssse permite al servidor unidireccionalmente empujar, _push_, los eventos y estados de _LangGraph_ hacia el cliente a medida que se generan.

== OntoNova <sec:sbcaialternatives>
Resulta imperativo evaluar el panorama de herramientas destinadas a la construcción y gestión de ontologías, con el fin de justificar OntoNova, el sistema de gestión del conocimiento multilingüe. El ecosistema de extracción y modelado de conocimiento describe distintas alternativas que, si bien resuelven problemas específicos, manifiestan carencias significativas en entornos productivos modernos.

Los editores semánticos tradicionales, tales como Protégé o TopBraid Composer, anuncian el cumplimiento estricto de los estándares semánticos, anticipados en la @sec:semanticweb. No obstante, su diseño asume que el operador es un ingeniero del conocimiento altamente cualificado, ralentizando la digitalización de los procesos empresariales @knowledgebottleneck. En adición, el ámbito del aprendizaje ontológico solventa el modelado de conocimiento con herramientas clásicas como `Text2Onto` @text2onto. Sin embargo, la generación de estructuras taxonómicas superficiales utilizando análisis estadístico y @glossnlp, no alcanza el nivel de expresividad y consistencia requerido por el estándar @glossowl soberanamente, requiriendo una participación humana. 

Seguido de la democratización de la @glossai, el uso de interfaces conversacionales genéricas impulsadas por un @glossllm, como ChatGPT, emerge como una alternativa accesible para la lluvia de ideas y la conceptualización de dominios. No obstante, estas herramientas ofrecen una caja negra de propósito general, anticipada en la @sec:inference. En consecuencia, al carecer de integraciones arquitectónicas que aseguren el determinismo sintáctico, @sec:determinism, la construcción de una ontología sufre invariablemente de alucinaciones, omisiones estructurales o sintaxis inválida, requiriendo de una participación humana. En el ámbito de la ingeniería bioinformática nace OntoGPT @ontogpt, que analiza texto y extrae conceptos para poblar una ontología preexistente con la ayuda de la @glossai generativa. Entre sus características destacan su enfoque iterativo, orientación a linea de comandos y su arraigo al sector de la biociencia. 

Como alternativa abierta a estos sistemas existentes se crea OntoNova, reuniendo métricas objetivo clave, recogidas en la comparativa de la @tab:ontotools, para impulsar al sector del conocimiento de vuelta al protagonismo.

#figure(
  table(
    columns: 5,
    table.header(
      text(size: 10pt)[*Herramienta*],
      text(size: 10pt)[*Determinismo*],
      text(size: 10pt)[*Gestión errores*],
      text(size: 10pt)[*Multilingüe*],
      text(size: 10pt)[*Usuario final*]
    ),
    table.hline(),
    [Protégé], [Estricto], [Manual], [No], [Ingeniero],
    [ChatGPT], [Estocástico], [Manual], [Sí], [Universal],
    [OntoGPT], [Estricto], [Manual], [No], [Ingeniero],
    [OntoNova], [Estricto], [Autónoma], [Sí], [Experto],
  ),
  caption: [Comparativa de herramientas para la gestión y modelado ontológico.],
) <tab:ontotools>
