= Implementación <sec:implementation>

Este capítulo explora la implementación del proyecto, detallando la organización del código fuente y su correspondencia directa con los componentes del Modelo C4 @c4model[Cap. 6], @sec:dev. Adicionalmente, se presentan los hitos de implementación alcanzados, @sec:milestones, así como las dificultades y decisiones técnicas tomadas durante el desarrollo del mismo, @sec:challenges.

== Entorno y Organización del Código <sec:dev>
El desarrollo, la experimentación y la validación del sistema, sometida a juicio en el @sec:verification, se realizaron íntegramente sobre un equipo de consumo, con librerías visibles en la @tab:stack, dotado de una @glossgpu NVIDIA RTX 4090 con 24 GB de memoria y un núcleo Linux Ubuntu 24.04.1 LTS virtualizado en WSL 2.7.11, en coherencia con el despliegue diseñado en la @sec:deploymentdesign. El uso de _hardware_ doméstico#footnote[El @sec:cloud plantea un marco teórico con _hardware_ remoto.] refuerza la soberanía tecnológica perseguida, y demuestra que la barrera de entrada es alcanzable para cualquier individuo, @sec:odslaw.

#figure(
  table(
    columns: (auto, 1fr),
    align: (left + top, left + top),
    table.header(text(size: 10pt)[*Ámbito*], text(size: 10pt)[*Tecnologías*]),
    table.hline(),
    [Aplicación web], [React 19 #sym.bullet TypeScript 6 #sym.bullet Vite 8 #sym.bullet React Flow 12 #sym.bullet Zustand 5 #sym.bullet pdf.js 6],
    [Servicio de orquestación], [Python 3.12 #sym.bullet FastAPI 0.141 #sym.bullet LangGraph 1.0 #sym.bullet Pydantic 2 #sym.bullet rdflib 7],
    [Motor de inferencia], [vLLM 0.9.2 #sym.bullet Qwen3-14B con cuantización AWQ de 4 bits],
    [Infraestructura], [Docker Compose 2 #sym.bullet Nginx 1.27 #sym.bullet NVIDIA Container Toolkit],
  ),
  caption: [Conjunto tecnológico de la implementación],
) <tab:stack>

La organización del código honra el compromiso de la @sec:c4notation, que delega el cuarto nivel del Modelo C4 @c4model[Cap. 6] en el repositorio de GitHub @githubrepo. La @fig:repotree salda esa deuda recorriendo el árbol del proyecto y marcando la correspondencia, en sentido descendente, de cada componente de la @sec:c4components con el fichero que lo implementa, generando una navegación inmediata del diagrama al código, sin ambigüedad. Otras partes del repositorio ---pruebas, configuración y guías técnicas--- se omiten del árbol al no adoptar forma de componente, sin que ello reste protagonismo al papel que desempeñan en el @sec:verification.

#let trow(entry, label) = block(
  width: 100%, above: 4.5pt, below: 0pt,
  align(left,
    if label == none { raw(entry) } else {
      raw(entry) + box(width: 1fr, pad(x: 4pt, repeat(gap: 3pt, text(size: 8pt)[.]))) + emph(text(size: 10pt, label))
    },
  ),
)
#figure(
  kind: image,
  block(
    stroke: 0.5pt + black, inset: 10pt, radius: 2pt, width: 100%,
    {
      trow("ontonova-project/", none)
      trow("├── backend/api/", none)
      trow("│   ├── routers/ontology.py", [Router de Ontologías])
      trow("│   ├── core/", none)
      trow("│   │   ├── graph.py", [Grafo Multi-agente])
      trow("│   │   ├── validator.py", [Validador Determinista])
      trow("│   │   └── models.py", [Contrato de Datos])
      trow("│   ├── services/", none)
      trow("│   │   ├── vllm_client.py", [Cliente de Inferencia])
      trow("│   │   └── rdf_compiler.py", [Compilador RDF])
      trow("│   └── prompts/GUIDANCE.md", [Instrucciones de los agentes])
      trow("├── frontend/src/", none)
      trow("│   ├── components/", none)
      trow("│   │   ├── CreateOntologyPanel.tsx", [Panel de Creación])
      trow("│   │   ├── OntologyCanvas.tsx", [Lienzo Interactivo])
      trow("│   │   └── InspectorPanel.tsx", [Inspector])
      trow("│   ├── store/ontologyStore.ts", [Almacén de Estado])
      trow("│   ├── api/client.ts", [Capa de API])
      trow("│   └── utils/fileText.ts", [Extractor de Documentos])
      trow("└── docker-compose.yml", [Composición del despliegue])
    },
  ),
  caption: [Correspondencia entre el código y los componentes C4.],
) <fig:repotree>

== Hitos de Implementación <sec:milestones>
El desarrollo iterativo, enunciado en la @sec:methodology, produce tres hitos que expresan el valor técnico de la implementación, cada uno ligado a su evidencia, complementados por el desarrollo restante almacenado en el repositorio @githubrepo.

El primer logro salda el compromiso contraído en la @sec:determinism permitiendo convertir el contrato de datos en una gramática formal. Cada agente especializado ---taxonomista, relacional y poblador--- declara su salida como una porción del contrato de la @sec:datacontract utilizando modelos de _Pydantic_, cuya conversión a _@glossjson schema_ viaja en cada petición en el campo `guided_json` del protocolo _OpenAI_, transporte ilustrado en el fragmento de código de la @fig:guided. De esta manera, cada nodo del grafo trabaja para construir la porción de la fuente de verdad que le corresponde, persiguiendo un estado final del grafo que evite duplicidades en los tramos de información, recogidos entre la definición y el motor de inferencia.

#figure(
  kind: image,
  block(
    stroke: (top: 1pt + black, bottom: 1pt + black, left: 0pt, right: 0pt),
    fill: luma(245),
    inset: 12pt,
    radius: 0pt,
    width: 100%,
    align(left, [
      // Regla local con caja de ancho fijo alineada a la derecha
      #show raw.line: it => {
        text(fill: luma(120), size: 0.9em)[
          #box(width: 1.2em, align(right, str(it.number)))
        ]
        text(fill: luma(180))[ | ]
        it.body
      }
      #show raw: set text(size: 8pt)
      ```python
      # core/graph.py
      class TaxonomistOutput(BaseModel):
        classes: List[OntoClass] = Field(default_factory=list)
      async def taxonomist_node(state: OntologyGenerationState) -> Dict[str, Any]:
        result = await generate_structured(
          messages, 
          TaxonomistOutput.model_json_schema(),
          base_url=_base_url("taxonomist"),
        )
      # services/vllm_client.py
      payload = {
        "model": model, 
        "messages": messages,
        "temperature": 0.0, 
        "guided_json": json_schema
      }
      ```
    ])
  ),
  caption: [Del contrato a la gramática de decodificación guiada.],
) <fig:guided>

En segundo lugar se implementa el flujo reactivo de extremo a extremo. Para eventos @glosssse, una limitación destacable de la interfaz nativa del navegador es la imposibilidad de enviar peticiones con cuerpo; por ello, la capa @glossapi del frontal tiene un consumidor propio de _Fetch API_, que procesa los eventos de la @sec:eventdesign de manera incremental. La @fig:appgeneration evidencia el resultado durante una generación real, con la primera etapa completada.

#figure(
  block(
    stroke: 0.5pt + black, inset: 1pt, radius: 2pt, width: 100%,
    image("../img/appgeneration.png", width: 100%),
  ),
  caption: [Generación de una ontología en curso con progreso por etapas.],
) <fig:appgeneration>

El tercer hito reside en el ciclo de refinamiento o validación sobre el lienzo. El grafo generado se compone de nodos y aristas modificables, y cada cambio vuelve a verificar el estado contra el servicio de orquestación, asegurando que una futura exportación no genere inconsistencias o errores. La extracción de documentos se ejecuta en un hilo de trabajo del propio navegador y la exportación se resuelve en el servicio de orquestación local, sin que el fichero ni la ontología abandonen el equipo, en consonancia con la legislación aplicable, @sec:applylaw. La @fig:appcanvas muestra la ontología resultante del mismo dominio de la @fig:appgeneration, lista para su edición y exportación.

#figure(
  block(
    stroke: 0.5pt + black, inset: 1pt, radius: 2pt, width: 100%,
    image("../img/appcanvas.png", width: 100%),
  ),
  caption: [Ontología del dominio de la investigación sobre el lienzo interactivo.],
) <fig:appcanvas>

== Dificultades y Decisiones Técnicas <sec:challenges>
Las dificultades encontradas y decisiones técnicas evaluadas en el transcurso de la elaboración de la aplicación OntoNova giran en torno al desafío de acercar un elemento probabilístico y no determinista, como un @glossllm, al plano determinista, reto presentado en la @sec:determinism y trabajado en las fases de diseño, @sec:design, e implementación. En una etapa temprana, las primeras iteraciones de prueba revelan que, ante un error de validación, reintentar una etapa desde cero empeora el resultado, pues el modelo intenta satisfacer al validador por la vía barata, es decir, omitiendo todo el contenido implicado en el error. Ante esta tesitura, se decide que cada reintento en un nodo agente reciba su salida anterior junto al error concreto, con una instrucción explícita de reparar el problema en lugar de regenerar la construcción desde cero, @fig:errorinstruction, activando la reparación sin pérdidas del validador, @sec:agentpipeline, antes de consumir _tokens_ adicionales#footnote[En el ámbito de la @glossai, la reducción de _tokens_ es una optimización de coste habitual.] de inferencia. 

Esta decisión eleva la calidad del sistema, pasando de un fallo irrecuperable hasta una puntuación casi perfecta, evidenciando, en el @sec:verification, que la fiabilidad del sistema proviene mayoritariamente de su ingeniería determinista con un complemento leve del refinamiento de instrucciones de sistema, delegado en la @sec:future-work.

#figure(
  kind: image,
  block(
    stroke: (top: 1pt + black, bottom: 1pt + black, left: 0pt, right: 0pt),
    fill: luma(245),
    inset: 12pt,
    radius: 0pt,
    width: 100%,
    align(left, [
      // Regla local con caja de ancho fijo alineada a la derecha
      #show raw.line: it => {
        text(fill: luma(120), size: 0.9em)[
          #box(width: 1.2em, align(right, str(it.number)))
        ]
        text(fill: luma(180))[ | ]
        it.body
      }
      #show raw: set text(size: 8pt)
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
    ])
  ),
  caption: [Entrada guiada de un nodo agente en fase de reintento.],
) <fig:errorinstruction>

Los textos densos en entidades traen consigo una segunda familia de problemas. En ocasiones, la decodificación guiada degenera en un bucle de espacios en blanco que consume el presupuesto de 8.192#footnote[Presupuesto calculado en base a la @glossgpu disponible.] _tokens_ reservados durante la generación, produciendo un @glossjson truncado y un error de análisis sintáctico#footnote[_Malformed response from http://vllm:8000/v1: Expecting ',' delimiter: line 20709 column 1 (char 39087)._] notificado tras minutos de espera. Para mitigar la situación, se incorpora al proceso de generación una secuencia de parada junto a una detección explícita del truncamiento, asegurando la manejabilidad del mensaje.

Una verdad instructiva, asumida desde el @sec:stateofart, surge al constatar que una misma entrada produce salidas distintas entre ejecuciones, incluso generando resultados con temperatura nula. El procesamiento por lotes continuo del motor de inferencia _vLLM_ altera el orden de las reducciones en coma flotante según las peticiones concurrentes y, al no tener propiedad asociativa este tipo de operaciones, _tokens_ empatados se resuelven de forma distinta en cada ejecución, divergencia e impacto que el ciclo de reintentos amplifica después. En determinadas ejecuciones, los grafos presentan carencias de conectividad o número de clases, @fig:appcanvasbad. Por consiguiente, se documenta un efímero intento de solución con un suelo de calidad determinista, consistente en medir la proporción de clases aisladas y conceder un reintento extra, por encima de los cuatro establecidos en el proceso de reparación de la @sec:agentpipeline, dirigido al agente relacional con la lista nominal de clases huérfanas. La verificación sobre un texto organizativo de 3.000 caracteres demuestra que el reintento adicional no reduce el aislamiento, acusando a la capacidad del modelo desplegado, @sec:dev, para anclar dominios y rangos, y descartando la hipótesis inicial de una falta de oportunidades de corrección, siendo necesaria una nueva teoría en un reto a futuro, @sec:future-work.

#figure(
  block(
    stroke: 0.5pt + black, inset: 1pt, radius: 2pt, width: 100%,
    image("../img/appcanvasbad.png", width: 100%),
  ),
  caption: [Ontología del dominio de la investigación con conectividad degradada.],
) <fig:appcanvasbad>

Por último, el entorno local disponible impone sus propias decisiones. La versión del motor de inferencia queda fijada en la recogida por la @tab:stack, al ser la última compatible con la virtualización WSL empleada. Una anécdota adicional, un error en tiempo de ejecución con módulos _ECMAScript_ con un tipo _MIME_ incorrecto deriva en la imposibilidad de utilizar ficheros como entrada, impuesto por el requisito REQ-US-FC-10. Las pruebas unitarias de la funcionalidad no se percatan de este tipo de problemas, que aflora con una prueba de extremo a extremo sobre un navegador real. Como primera lección, se orienta la estrategia de verificación del @sec:verification contra un despliegue completo, sin perder de vista pruebas automáticas reducidas. Como segunda lección, ante la hipótesis de que determinadas acusaciones descritas pueden resolverse en un entorno con un modelo más potente, se delega en el trabajo futuro propuesto en el @sec:cloud la posibilidad de cambio de entorno, con los posibles efectos colaterales que esto pueda generar.