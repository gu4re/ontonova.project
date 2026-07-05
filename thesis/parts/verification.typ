= Verificación <sec:verification>
Este capítulo detalla la estrategia de pruebas automáticas @testingpyramid en conjunto con el balance de las mismas, @sec:verifysummary. Finalmente, se realiza la verificación de los requisitos establecidos e incluidos @isoieee29148, @sec:verifyreqs, y la revisión del cumplimiento del objetivo O4, @sec:verifyregulation.

== Estrategia y Balance de Pruebas Automáticas <sec:verifysummary>
La táctica de pruebas automáticas plantea como eje principal la pirámide de automatización de pruebas a distintos niveles @testingpyramid[Cap. 16], que surge con las metodologías ágiles convirtiéndose en un estándar ágil en la industria. El modelo organiza las pruebas automáticas en tres niveles según su granularidad. La base concentra las pruebas unitarias, numerosas, rápidas y aisladas, que evalúan cada pieza por separado y localizan el defecto de código en el instante en que se introduce. El tramo intermedio agrupa las pruebas de servicio, de amplia cobertura aunque en menor número, entendiendo por servicio aquello que la aplicación hace en respuesta a una determinada entrada. Estos casos revisan la lógica de negocio separadamente de la interfaz, evitando el coste asociado a la capa de presentación. La cúspide reserva un espacio reducido a las pruebas de interfaz, fieles a la experiencia del usuario pero también lentas y costosas de mantener, motivo por el que su número es el más reducido en la pirámide. Un planteamiento alternativo consiste en invertir estas proporciones de pruebas, lo que produce un antipatrón, donde la capa dominante de pruebas es la de interfaz, encareciendo cada cambio y demorando la detección de errores. El proyecto no comparte dicha inversión, adoptando la táctica mencionada en contribución al enfoque de pruebas automáticas de desplazamiento a la izquierda @shiftlefttesting. La @fig:testpyramid ilustra el modelo con el inventario del proyecto, superando 117 pruebas sin excepción sobre el entorno descrito en la @sec:dev. La base reúne 72 pruebas unitarias repartidas entre ambos contenedores, con diecinueve pruebas del servicio de orquestación para el validador determinista, el cliente de inferencia y el compilador RDF, y, cincuenta y tres pruebas para los componentes de interfaz, el almacén de estado y las utilidades de extracción del contenedor de la aplicación web. El nivel de servicio declara 27 pruebas automáticas, siete que recorren la @glossapi y veinte con la cadena multi-agente completa utilizando inferencia simulada, aislando la lógica de orquestación del comportamiento probabilístico del @glossllm. La cúspide contiene 14 pruebas que conducen un navegador real con _Playwright_, validando los casos de uso sobre la aplicación servida. Por encima del vértice está la nube que el modelo reserva a pruebas manuales @testingpyramid[Cap. 16], ocupada aquí por 4 pruebas de aceptación automáticas. Por un lado, dos pruebas que interrogan la pila completa en ejecución, @glossgpu incluida, validando el uso del formato PDF como entrada y verificando la resiliencia de los resultados, destapando las dificultades declaradas en la @sec:challenges. Por otro lado, dos pruebas verifican la calidad del @glossllm frente a métricas clásicas de la extracción del conocimiento. Dado el carácter no determinista del motor de inferencia, cada prueba se repite en una campaña de 25 generaciones repartidas entre distintas sesiones de _vLLM_, cuya distribución se resume en la @tab:goldquality. El *dominio 1*, liviano y británico, tiene una puntuación perfecta en la totalidad de las generaciones, mientras que el *dominio 2*, denso e hispano, desciende a 0,41 de F1 con tres fallos, siendo la jerarquía y las aserciones entre individuos las categorías débiles, aflorando la varianza entre sesiones distintas de _vLLM_. Ambas lecturas delimitan el margen de mejora existente, tanto en el refinamiento de instrucciones como en la adopción de modelos más potentes, líneas delegadas en la @sec:future-work.

#figure(
  grid(
    columns: (auto, 1.2fr),
    gutter: 10pt,
    align: top,
    table(
      columns: 3,
      align: (left + top, right + top, right + top),
      table.header(
        text(size: 10pt)[*Métrica*],
        text(size: 10pt)[*Dominio 1*],
        text(size: 10pt)[*Dominio 2*],
      ),
      table.hline(),
      [Precisión #sym.plus.minus #sym.lambda#footnote[#sym.lambda = desviación típica.]], [1,00 #sym.plus.minus 0,00], [0,52 #sym.plus.minus 0,07],
      [Exhaustividad #sym.plus.minus #sym.lambda], [1,00 #sym.plus.minus 0,00], [0,45 #sym.plus.minus 0,05],
      [F1 #sym.plus.minus #sym.lambda], [1,00 #sym.plus.minus 0,00], [0,41 #sym.plus.minus 0,04],
    ),
    table(
      columns: 3,
      align: (left + top, right + top, right + top),
      table.header(
        text(size: 10pt)[*Ejecución*],
        text(size: 10pt)[*Dominio 1*],
        text(size: 10pt)[*Dominio 2*],
      ),
      table.hline(),
      [Éxitos / fallos], [25 / 0], [22 / 3],
      [Poda final], [0%], [100%],
      [Tiempo (u)], [0m 20s], [2m 19s]
    ),
  ),
  caption: [Pruebas de aceptación y variabilidad de la cadena de inferencia.],
) <tab:goldquality>

#figure(
  image("../img/testpyramid.png", width: 80%),
  caption: [Pirámide de pruebas automáticas de OntoNova.],
) <fig:testpyramid>

== Estándar IEEE para la Verificación de Requisitos <sec:verifyreqs>
La verificación recorre los trece requisitos con estado incluido de la @sec:designtraceability, aplicando a cada uno el método que su métrica solicita entre los posibles que define la norma ISO/IEC/IEEE 29148:2018 @isoieee29148, esto es, prueba, demostración, análisis e inspección. La @tab:reqresults anticipa el resultado global y las subsecciones siguientes, organizadas por método, presentan el procedimiento y la evidencia de cada requisito.

#figure(
  table(
    columns: (auto, 1fr, auto, auto),
    align: (left + top, left + top, left + top, left + top),
    table.header(
      text(size: 10pt)[*Requisito*], text(size: 10pt)[*Métrica*],
      text(size: 10pt)[*Método*], text(size: 10pt)[*Resultado*],
    ),
    table.hline(),
    [REQ-US-FC-01], [15.000 caracteres, al menos 2 idiomas], [Prueba], [Cumple],
    [REQ-US-FC-02], [Progreso por etapas, latencia #sym.lt.eq 1s], [Prueba], [Cumple],
    [REQ-US-FC-03], [Validación con ciclo de corrección], [Prueba], [Cumple],
    [REQ-US-FC-04], [Edición inferior o igual a 3 interacciones], [Demostración], [Cumple],
    [REQ-US-FC-05], [Exportación cumple con validador @glossw3c], [Prueba], [Cumple],
    [REQ-US-FC-10], [Ficheros de texto o PDF #sym.lt.eq 5MB], [Prueba], [Cumple],
    [REQ-US-NF-01], [SUS #sym.gt.eq 70 con al menos 5 usuarios], [Análisis], [Cumple],
    [REQ-US-NF-02], [Carga #sym.lt.eq 3s, interacción #sym.lt 200ms], [Prueba], [Cumple],
    [REQ-SW-FC-02], [Cambio de modelo por configuración], [Demostración], [Cumple],
    [REQ-SW-NF-02], [Ninguna vulnerabilidad de severidad alta], [Análisis], [Cumple],
    [REQ-SW-NF-05], [Despliegue autodidáctico por un tercero], [Demostración], [Cumple],
    [REQ-SW-NF-06], [Extensión sin rediseño], [Inspección], [Cumple],
    [REQ-SW-NF-08], [Despliegue contenerizado #sym.lt 5min], [Prueba], [Cumple],
  ),
  caption: [Resultado de la verificación de los requisitos incluidos.],
) <tab:reqresults>

=== Método de Prueba <sec:verifytest>
*REQ-US-FC-01.* La métrica compromete la aceptación de descripciones de hasta 15.000 caracteres en al menos español e inglés. El límite se verifica en los dos componentes que lo imponen. En la aplicación web, el área de texto acota la entrada en origen y el elemento que permite adjuntar ficheros rechaza con un mensaje localizado aquellos cuyo texto extraído excede el límite, comportamiento ilustrado en la @fig:toomuchcharacters y cubierto por pruebas de interfaz, @sec:verifysummary. En el servicio de orquestación, una validación previa del proceso multi-agente de la @sec:agentpipeline rechaza las entradas excedidas en menos de un segundo, emitiendo un evento terminal con su código de error localizable, cubierto por una prueba de servicio dedicada. El carácter multilingüe queda verificado por las campañas de la @tab:goldquality, pues la entrada liviana se procesa en inglés y la densa en español con detección automática de idioma, sumando cincuenta generaciones reales en ambos idiomas. El requisito se da por cumplido.

#figure(
  block(
    stroke: 0.5pt + black, inset: 1pt, radius: 2pt,
    image("../img/toomuchcharacters.png", width: 38%),
  ),
  caption: [Mensaje de error por exceso de caracteres.],
) <fig:toomuchcharacters>

*REQ-US-FC-02.* La métrica requiere un evento de progreso por cada etapa de la generación, con una latencia máxima de un segundo entre la detección del fin de etapa en el servicio de orquestación y su reflejo visual en la interfaz web. La verificación instrumenta el recorrido completo sobre la aplicación completa en ejecución, cronometrando por un lado la llegada de cada frame @glosssse al navegador y por otro el instante en que el indicador de progreso pinta, en verde, la etapa como completada. El tramo de transporte resulta despreciable, pues los frames sin cómputo pendiente llegan al cliente con diferencias inapreciables entre sí, y el tramo de presentación queda acotado entre 1,7 y 20,5 milisegundos según la etapa, correspondiendo a la @tab:sselatency. La latencia total queda dos órdenes de magnitud por debajo del segundo comprometido. Completan la cobertura una prueba de servicio que revisa los eventos por etapa en el orden del proceso y una prueba de componentes que verifica el avance del indicador con cada evento recibido. El requisito se da por cumplido.

#figure(
  table(
    columns: (10em, 10em),
    align: (left + top, right + top),
    table.header(text(size: 10pt)[*Etapa*], text(size: 10pt)[*Latencia*]),
    table.hline(),
    [Taxonomista], [2,1ms],
    [Relacional], [1,7ms],
    [Poblador], [20,5ms],
    [Validador], [19,1ms]
  ),
  caption: [Latencia de eventos de progreso],
) <tab:sselatency>

*REQ-US-FC-03.* La métrica anuncia que todo grafo creado supere la validación sintáctica del esquema de datos y que, ante un resultado inválido, el sistema lance un ciclo de corrección, establecido en cuatro intentos en la @sec:agentpipeline. La verificación recorre los tres niveles de la pirámide @testingpyramid. En la base, trece pruebas unitarias fijan el comportamiento del validador determinista sobre la estructura, las referencias cruzadas y la conformidad de cada aserción con el dominio y rango declarados. En el nivel de servicio, veinte pruebas ejercitan la cadena multi-agente con inferencia simulada, cubriendo el enrutado del reintento hacia la etapa culpable, las reparaciones sin pérdidas, la poda como último recurso y el fallo definitivo cuando la malformación es estructural, comportamientos diseñados en la @sec:agentpipeline. En aceptación, las campañas de la @tab:goldquality ejecutan el ciclo contra la aplicación real con especial elocuencia, pues la entrada liviana necesita un reintento de corrección, visible en la @fig:needattempt, en cada una de sus veinticinco generaciones y aun así mantiene la puntuación perfecta, mientras que la densa agota el presupuesto de reintentos y degrada con poda en la totalidad de sus éxitos, entregando en todos los casos un grafo que supera la validación. El requisito se da por cumplido.

#figure(
  block(
    stroke: 0.5pt + black, inset: 1pt, radius: 2pt,
    image("../img/needattempt.png", width: 38%),
  ),
  caption: [Mensaje de reintento de corrección.],
) <fig:needattempt>

*REQ-US-FC-05.* La métrica necesita que las ontologías exportadas superen un validador @glossrdf sin errores. La verificación exporta dos ontologías reales ---dominio liviano y dominio denso--- en los dos formatos estándar del @glossw3c que ofrece el sistema, _Turtle_ y @glossrdf/@glossxml @owldeclaration, y somete los ficheros resultantes a un analizador @glossrdf del W3C @w3cvalidator y _Turtle_ @turtlevalidator. Los documentos se analizan sin error alguno, disponible en la @fig:rdfsok. Completan la cobertura tres pruebas unitarias del compilador @glossrdf y una prueba de extremo a extremo que verifica la descarga de una exportación _Turtle_ desde el navegador. El requisito se da por cumplido.

#figure(
  block(
    stroke: 0.5pt + black, inset: 1pt, radius: 2pt,
    image("../img/rdfsok2.png", width: 80%),
  ),
  caption: [Validación sintáctica de exportaciones RDF y Turtle.],
) <fig:rdfsok>

*REQ-US-FC-10.* La métrica impone la entrada estándar de ficheros de texto, _markdown_ o PDF de hasta 5 MB, rechazando con un mensaje informativo aquellos de mayor tamaño, véase @fig:toolargepdf, o cuyo texto extraído supere los caracteres multilingües anunciados en el REQ-US-FC-01. La verificación cubre el requisito en el servicio de orquestación y en la aplicación web respectivamente, cubriendo los tres tipos de ficheros mencionados con pruebas de componente. Además, pruebas de extremo a extremo exploran dichos límites en un navegador real, y pruebas de aceptación someten a la aplicación completa a un PDF extenso, destapando problemas con el tipo _MIME_ encontrados en la @sec:challenges y que solo un navegador real puede cubrir. El requisito se da por cumplido.

#figure(
  block(
    stroke: 0.5pt + black, inset: 1pt, radius: 2pt,
    image("../img/toolargepdf.png", width: 38%),
  ),
  caption: [Mensaje de error por exceso de tamaño de archivo.],
) <fig:toolargepdf>

*REQ-US-NF-02.* La métrica limita la carga inicial de la aplicación web a 3 segundos y la respuesta a la interacción a 200 milisegundos. La carga se verifica con _Google Lighthouse_ cronometrando la aplicación web en cien rondas de operaciones, resumidas en la @tab:interaction, sobre lienzo servida por _Nginx_ en el equipo de pruebas, @sec:dev, con el perfil objetivo de escritorio por su uso y naturaleza de despliegue, @sec:deploymentdesign. El primer trazo útil de contenido, así como el instante interactivo, se alcanzan en 0,9 segundos con un rendimiento de 98 sobre 100; con el perfil móvil 4G simulado, que estrangula la red y la CPU, la carga asciende a 5 segundos, dato que señala el peso del extractor de documentos como margen de optimización, ilustrado en la @fig:lighthouse. El requisito se da por cumplido.

#figure(
  table(
    columns: 7,
    align: (left + top,) + (right + top,) * 6,
    table.header(
      text(size: 10pt)[*Operación*], text(size: 10pt)[*Mínimo*],
      text(size: 10pt)[*Media*], text(size: 10pt)[*Mediana*],
      text(size: 10pt)[*p95*], text(size: 10pt)[*p99*], text(size: 10pt)[*Máximo*],
    ),
    table.hline(),
    [Crear clase], [49ms], [51ms], [51ms], [53ms], [64ms], [65ms],
    [Seleccionar clase], [10ms], [25ms], [26ms], [29ms], [30ms], [30ms],
    [Eliminar clase], [31ms], [34ms], [34ms], [36ms], [36ms], [48ms],
  ),
  caption: [Latencia de interacción del lienzo en cien rondas por operación.],
) <tab:interaction>

#figure(
  block(
    stroke: 0.5pt + black, inset: 1pt, radius: 2pt,
    image("../img/lighthouse.png", width: 80%),
  ),
  caption: [Reporte de _Google Lighthouse_ sobre OntoNova.],
) <fig:lighthouse>

*REQ-SW-NF-08.* La métrica delimita a cinco minutos el despliegue completo del sistema. La verificación parte de un equipo de pruebas sin despliegue previo ---eliminando contenedores y red--- que cronometra la orden de arranque `docker compose up -d --wait` hasta que los tres servicios responden y superan sus comprobaciones de salud. La ejecución completa dura 2 minutos y 6 segundos, un 58% por debajo del umbral comprometido, siendo la carga del modelo en la memoria de la @glossgpu por parte del motor de inferencia el proceso rezagado. Como condición de contorno, los pesos del modelo residen ya en el volumen persistente de la @sec:deploymentdesign, descartando como evidencia la primera instalación absoluta por su dependencia del ancho de banda del equipo de pruebas. El requisito se da por cumplido.

=== Método de Demostración <sec:verifydemonstration>
*REQ-US-FC-04.* La métrica exige que cada operación de edición del lienzo se complete en tres interacciones como máximo. La demostración enumera las operaciones disponibles y cuenta las interacciones de la secuencia más corta que las completa, recogidas en la @tab:interactions, con el máximo alcanzado por el renombrado de una relación con tres interacciones y resolviendo el resto en una o dos. La demostración es reproducible, pues cada operación está cubierta por una prueba de extremo a extremo que lanza sobre un navegador la secuencia contada, y el estado de cada cambio resultante es comprobado contra el servicio de orquestación manteniendo el grafo exportable en todo momento, @sec:apidesign. El requisito se da por cumplido.

#figure(
  table(
    columns: 2,
    align: (left + top, right + top),
    table.header(text(size: 10pt)[*Operación*], text(size: 10pt)[*Interacciones*]),
    table.hline(),
    [Crear clase (nombre y botón)], [2],
    [Seleccionar e inspeccionar clase], [1],
    [Editar atributos desde el inspector], [2],
    [Eliminar clase], [1],
    [Crear relación (arrastre entre extremos)], [1],
    [Renombrar relación (doble clic, texto, intro)], [3],
    [Reconectar relación (arrastre del extremo)], [1],
    [Recolocar etiqueta de relación], [1],
    [Eliminar relación], [1],
    [Exportar (botón y formato)], [2],
    [Reiniciar lienzo (botón y confirmación)], [2],
  ),
  caption: [Interacciones necesarias por operación de edición del lienzo],
) <tab:interactions>

*REQ-SW-FC-02.* La métrica asegura escalabilidad y mantenibilidad, comprometiendo al sistema a que la sustitución del modelo de lenguaje se realice únicamente con un cambio de configuración, sin modificar código. La demostración inspecciona los puntos de configuración y ejecuta el cambio. El nombre del modelo se declara en una variable de entorno, `LLM_MODEL_NAME`, consumida por el cliente de inferencia, y _vLLM_ lo recibe como argumento de arranque en la composición. La demostración amplia horizontes respecto al requisito, pues cada nodo del proceso multi-agente declara su propio recurso dentro del motor de inferencia, ofreciendo la posibilidad a futuro de adoptar un @glossllm distinto por agente, posibilidad heredada del protocolo _OpenAI_ adoptado en la @sec:c4containers que hace sustituible cualquier motor compatible. En complemento, tres pruebas unitarias fijan el contrato del cliente con el protocolo. El requisito se da por cumplido.

#par(first-line-indent: 0pt)[
  *REQ-SW-NF-05.* La métrica demanda que un tercero pueda desplegar el sistema siguiendo la documentación del repositorio. La demostración reproduce el camino del tercero literalmente, pues la prueba del requisito REQ-SW-NF-08 parte de un equipo sin despliegue previo y ejecuta el procedimiento documentado en la raíz del repositorio @githubrepo, que se reduce a los requisitos declarados en la @sec:deploymentdesign y una orden de arranque `docker compose up`. La aplicación queda operativa sin intervención adicional en el tiempo objetivo del requisito REQ-SW-NF-08, dado que toda la configuración variable ofrece valores por defecto funcionales, REQ-SW-FC-02. Adicionalmente, la prueba de aceptación del formato PDF se ejecuta contra un despliegue levantado exactamente con ese procedimiento, por lo que cada lanzamiento de pruebas demuestra el requisito. El requisito se da por cumplido.
]
#pagebreak()
=== Método de Análisis <sec:verifyanalysis>
*REQ-US-NF-01.* La métrica requiere una puntuación igual o superior a 70 en la @glosssus:long con cinco usuarios. El análisis administra el cuestionario, disponible en el @app:sus, a participantes ajenos al desarrollo y de perfiles diversos, recogidos en la @tab:susresults, con edades comprendidas entre los 18 y los 53 años y ninguno con conocimiento previo de las ontologías, quienes completan sin asistencia las tres tareas guía de la encuesta antes de valorar las diez afirmaciones. La corrección sigue el procedimiento del instrumento @susbrooke, una puntuación acotada entre 0 y 100 por participante formalizada en la @eq:sus, donde $r_i$ denota la respuesta a la afirmación $i$-ésima. Las puntuaciones individuales, declaradas en la @tab:susresults, generan una media de 76,5 con una desviación típica de 11,9, dispersión coherente con la variabilidad individual característica del instrumento, por encima del umbral comprometido y del promedio de referencia del instrumento, situado en 68. Resulta revelador que las puntuaciones altas, mayoritariamente, provienen de los perfiles sin formación técnica, alcanzando el máximo en la estudiante de artes en contraposición a la exigencia del ingeniero de software, en coherencia con el objetivo O2. El requisito se da por cumplido.

$ "SUS" = 2","5 dot (sum_(i in {1,3,5,7,9}) (r_i - 1) + sum_(i in {2,4,6,8,10}) (5 - r_i)) $ <eq:sus>

#figure(
  table(
    columns: 4,
    align: (left + top, left + top, right + top, right + top),
    table.header(
      text(size: 10pt)[*Participante*], text(size: 10pt)[*Perfil*],
      text(size: 10pt)[*Edad*], text(size: 10pt)[*Puntuación SUS*],
    ),
    table.hline(),
    [U1], [Ingeniería de software], [38], [67,50],
    [U2], [Jefatura de almacén], [53], [80,00],
    [U3], [Gerencia de grandes cuentas], [52], [75,00],
    [U4], [Estudios de artes], [22], [95,00],
    [U5], [Entrenamiento personal], [20], [65,00],
    [], [*Media #sym.plus.minus #sym.lambda#footnote[#sym.lambda = desviación típica.]*], [], [*76,50 #sym.plus.minus 11,90*],
  ),
  caption: [Resultados del cuestionario SUS por participante],
) <tab:susresults>

*REQ-SW-NF-02.* La métrica reclama ausencia de vulnerabilidades de severidad alta en las dependencias del sistema. El análisis emplea herramientas de revisión estática de dependencias sobre ambos mundos, con `pip-audit` para el servicio de orquestación y `npm audit` para la aplicación web, contrastando el árbol de dependencias contra las bases de datos públicas de avisos de seguridad. La ejecución de ambos comandos afirma cero vulnerabilidades a día 23 de agosto de 2026. Cabe destacar que el método demuestra su valor durante la propia verificación, pues ejecuciones periódicas son requeridas ante la constante evolución de las amenazas, siempre lanzando la batería de pruebas automáticas de la @sec:verifysummary con el fin de evitar un cambio disruptivo en los procesos de negocio, definiendo dicho análisis como un proceso capaz de detectar y corregir. El requisito se da por cumplido.

=== Método de Inspección <sec:verifyinspection>
*REQ-SW-NF-06.* La métrica establece que las nuevas funcionalidades o extensiones de las actuales se incorporen sin requerir una nueva fase de diseño de los componentes existentes, en aplicación del principio abierto/cerrado @cleanarchitecture[Cap. 8]. La inspección examina los puntos de extensión del diseño y el coste de ejercitarlos. Añadir un formato de exportación se reduce a una entrada en el mapa de formatos del router de ontologías; un nuevo idioma de interfaz, a un fichero de recursos de localización; un nuevo código de error localizado, a una clave de traducción sobre la convención de eventos de la @sec:eventdesign; la sustitución del modelo, e incluso un modelo distinto por agente, a pura configuración, como demuestra REQ-SW-FC-02; y un agente adicional en la cadena, a un nodo con su esquema de salida acotado insertado en el grafo de la @sec:agentpipeline, sin alterar los existentes. La inspección se contrasta también con dos requisitos tardíos analizados e incorporados durante el desarrollo, la entrada por fichero ---un caso adicional del extractor de documentos, sin impactar al flujo de entrada estándar--- y la localización de errores del servicio ---una convención de código y parámetros sobre el transporte intacto---, en las que las pruebas automáticas de la @sec:verifysummary pasaron sin adaptación alguna, señal de que los componentes cerrados permanecieron cerrados. En cuanto al aumento de usuarios concurrentes @cleanarchitecture[Cap. 16], la inspección constata que ningún contenedor acumula estado de sesión, porque la aplicación web es contenido estático, en consecuencia, el estado de la ontología en edición reside en el propio navegador del usuario, el servicio de orquestación resuelve cada petición de forma autocontenida y el motor de inferencia atiende peticiones independientes mediante procesamiento por lotes continuo, @sec:determinism. El escalado se reduce a la replicación de contenedores, sin necesidad de una nueva fase de diseño, camino teorizado en la propuesta de exposición pública del @sec:cloud. El requisito se da por cumplido.

== Verificación del Cumplimiento Normativo <sec:verifyregulation>
El objetivo O4 enfrenta a la aplicación a la verificación de conformidad @euaiactchecker del @glossaiact:long @aiactlaw. Este cumplimiento que comienza su definición en la @sec:applylaw con la legislación aplicable, sometida a una fase de diseño en la @sec:securitydesign desvelando las mitigaciones a seguir en la implementación, @sec:implementation. El veredicto, recogido en la @tab:aiactroute del @app:aiact, declara al benefactor como un proveedor de un sistema de @glossai, OntoNova, puesto en servicio en la Unión Europea, ajeno a las prácticas prohibidas del Artículo 5 y a las categorías de alto riesgo de los Anexos I y III. Las obligaciones de transparencia del Artículo 50 no aplican porque el sistema no emula interacción humana y el grafo generado constituye un artefacto técnico para el usuario. Adicionalmente, se reconocen dos exclusiones de ámbito, por actividad de investigación y desarrollo y por publicarse bajo licencia de código abierto, @sec:license, restando como obligación la alfabetización en @glossai, Artículo 4, satisfecha en el contexto del proyecto por la formación que este mismo trabajo acredita. Cabe subrayar que ambas exclusiones están condicionadas a la ausencia de comercialización, por lo que una eventual exposición pública, @sec:cloud, demanda una nueva verificación bajo ese nuevo supuesto, delegada en un trabajo futuro, @sec:future-work. El objetivo O4 se da por verificado.