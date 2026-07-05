#import "@preview/gantty:0.4.0": gantt

= Plan de Proyecto
Este capítulo presenta tanto la planificación, @sec:planning, como el presupuesto, @sec:money, del trabajo realizado, conociendo el marco regulatorio y su impacto en el desarrollo sostenible, @sec:law, en el entorno socioeconómico, @sec:socialcontext, en el que surge.

== Planificación <sec:planning>
Esta sección incluye detalles acerca de la planificación del proyecto. Se describen, a continuación, las metodologías aplicadas, @sec:methodology, detallando la duración de cada parte y normas asociadas, @sec:timeline.

=== Metodología <sec:methodology>
El proceso de desarrollo de la propuesta se lleva a cabo siguiendo, principalmente, una metodología en cascada, representada en la @fig:waterfall. Este modelo permite una estructuración clara y lógica del trabajo, siguiendo los siguientes pasos:
+ *Análisis de requisitos.* Se realizan reuniones y consultas con el experto para identificar y definir los requisitos necesarios para el correcto desarrollo del sistema. Clave para establecer unos objetivos de negocio y de aprendizaje.
+ *Diseño de la arquitectura.* Reunidos los requisitos y los objetivos, se desencadena una lluvia de ideas y múltiples bocetos con el objetivo de cumplir los principios de desarrollo de software @gangoffour @eda, detallados en el @sec:design.
+ *Proceso de aprendizaje.* Se investiga y selecciona la herramienta adecuada de orquestación de agentes, @sec:agents, en conjunto con la arquitectura idónea para el proyecto en la @sec:eventdrivenarch. Este proceso implica un tiempo considerable dedicado a familiarizarse con el _software_ elegido y comprender su funcionamiento @waterfall[Cap. 6], enlazando con el objetivo O1 descrito en la @sec:objetivos.

+ *Implementación y pruebas.* Se adopta un enfoque de prototipado, desarrollando los componentes de manera aislada y realizando iteraciones sobre ellos. Este planteamiento permite validar cada componente de forma independiente, así como realizar pruebas en un entorno controlado, tanto a nivel de componente como en el flujo completo de negocio. Este movimiento garantiza que se aborden los problemas de manera continua y se optimice el desarrollo según los resultados de las pruebas empíricas realizadas. 

#figure(
  image("../img/waterfall.png", width: 80%),
  caption: [Metodología en cascada aplicada @waterfall.],
) <fig:waterfall>

=== Estimación de Tiempo <sec:timeline>
La estimación de tiempo queda diseñada en la @fig:gantt, representando un diagrama de estimación de tiempo o Gantt @waterfall[Cap. 9]. El esquema muestra las tareas realizadas en cada fase de la metodología en cascada (véase @fig:waterfall), incluyendo una última etapa de reporte, donde están incluidas las horas invertidas en la confección de este reporte.

El proyecto fija una duración total de 11 meses, aproximadamente 32 horas por mes, cerca de 8 horas a la semana, sin contar fin de semana, vacaciones, días libres, baja por enfermedad y otras casuísticas. Por consiguiente, el tiempo total esperado del trabajo, excluyendo el trabajo del tutor, son 352 horas. En la @tab:timestamp se recoge la distribución del esfuerzo de cada una de las etapas a lo largo del proyecto, en función de la metodología aplicada (véase @sec:methodology), y que sirve como base cuantitativa para complementar la @fig:gantt presentada posteriormente.

#figure(
  table(
    columns: 3,
    align: (left + top, right + top, right + top),
    table.header(
      text(size: 10pt)[*Fase*],
      text(size: 10pt)[*Horas estimadas*],
      text(size: 10pt)[*% del total*],
    ),
    table.hline(),
    [Análisis de Requisitos], [66], [18,75],
    [Diseño de la Arquitectura], [35], [9,94],
    [Proceso de Aprendizaje], [67], [19,04],
    [Implementación y Pruebas], [96], [27,27],
    [Reporte], [88], [25,00],
    [*Total*], [*352*], [*100,00*]
  ),
  caption: [Desglose estimado de horas por fase del proyecto],
) <tab:timestamp>

#rotate(-90deg, reflow: true)[
  #scale(90%, origin: top)[
    #figure(
      gantt(yaml("gantt.yaml")),
      caption: [Diagrama de estimación de tiempo.],
    ) <fig:gantt>
  ]
]

== Presupuesto <sec:money>
Se introduce el presupuesto, basado en la estimación de tiempo y metodología descritos en la @sec:planning. La siguiente @tab:project, resume la información del proyecto, incluyendo su presupuesto total.

#figure(
  table(
    columns: (auto, 1fr),
    align: (col, row) => if col == 0 { left + top } else { left + top },
    table.header(
      text(size: 10pt)[*Campo*],
      text(size: 10pt)[*Descripción*]
    ),
    table.hline(),
    text(size: 10pt)[*Título*], [Diseño e Implementación de un Sistema de Gestión del Conocimiento Multilingüe Basado en LLMs como Alternativa Abierta a otros sistemas existentes],
    text(size: 10pt)[*Autor*], [Diego Picazo García],
    text(size: 10pt)[*Departamento*], [Informática],
    text(size: 10pt)[*Inicio*], [03/10/2025],
    text(size: 10pt)[*Fin*], [03/09/2026],
    text(size: 10pt)[*Duración*], [11 meses],
    text(size: 10pt)[*Presupuesto*], [13.000,00#sym.euro],
    
    table.hline() // 2. LÍNEA INFERIOR (Equivale a la que cerraba la tabla abajo)
  ),
  caption: [Información del proyecto],
) <tab:project>

El balance disponible para el proyecto, se ha repartido en las distintas áreas siguiendo *la regla del 70/25*, destinando un 70% de los gastos a recursos humanos y un 25% a elementos materiales. Se ha reservado un 5% del total destinado a gastos improvistos, concretamente 650,00#sym.euro @waterfall[Cap. 12].

=== Costes Directos
Aquellos directamente relacionados con el desarrollo del proyecto @waterfall[Cap. 12]. Pueden distinguirse en dos grupos:
- *Costes personales.* Gastos relacionados con la experiencia, desarrollo personal y transporte de los trabajadores, entre otros. El coste es variable en función del rol del trabajador y su impacto en el proyecto, visible en la @tab:personalcost:
  - *Gerente de Proyecto.* Ofrece apoyo y gestión al proyecto, intermediando entre el nivel de dirección y el nivel de entrega dentro de la organización del proyecto.
  - *@glossqa.* Diseña y realiza pruebas de las características implementadas.
  - *Desarrollador.* Implementa las funcionalidades de negocio.
  - *Analista.* Evalúa los requisitos y diseña la arquitectura.

Es importante señalar que el rol de gerente de proyecto fue asumido por la figura de la tutora, mientras que los demás roles fueron desempeñados por el estudiante.

#figure(
  table(
    columns: 4,
    align: (left + top, right + top, right + top, right + top),
    table.header(
      text(size: 10pt)[*Rol*],
      text(size: 10pt)[*Horas*],
      text(size: 10pt)[*Tarifa*],
      text(size: 10pt)[*Total*],
    ),
    table.hline(),
    [Gerente de Proyecto], [80], [41,20#sym.euro/h], [3.296,00#sym.euro],
    [QA], [72], [25,21#sym.euro/h], [1.815,12#sym.euro],
    [Desarrollador], [150], [23,57#sym.euro/h], [3535,50#sym.euro],
    [Analista], [50], [35,20#sym.euro/h], [1.760,00#sym.euro],
    [*Total*], [*352*], [], [*10.406,62#sym.euro*]
  ),
  caption: [Costes personales],
) <tab:personalcost>

- *Costes materiales.* Principalmente hardware, como servidores, portátiles, teclados, ratones#sym.dots.h De cara al software, todo lo utilizado es @glossfoss. El balance queda recogido en la @tab:materialcost, teniendo en cuenta el coste unitario y aplicando un porcentaje de depreciación debido al uso intensivo durante la duración de once meses del proyecto.

#figure(
  table(
    columns: (1.3fr, 1.2fr, 0.8fr, 0.9fr, 0.8fr),
    align: (left + top, left + top, right + top, right + top, right + top),
    table.header(
      text(size: 10pt)[*Elemento*],
      text(size: 10pt)[*Uso*],
      text(size: 10pt)[*Coste de compra*],
      text(size: 10pt)[*Depreciación*],
      text(size: 10pt)[*Coste final*]
    ),
    table.hline(),
    [Servidor], [Almacenamiento y procesamiento], [900,00#sym.euro], [20%], [720,00#sym.euro],
    [Teclado], [Herramienta de desarrollo], [50,00#sym.euro], [10%], [45,00#sym.euro],
    [Ratón ergonómico], [Herramienta de desarrollo], [35,00#sym.euro], [10%], [31,50#sym.euro],
    [Pantalla], [Monitor para trabajar], [200,00#sym.euro], [15%], [170,00#sym.euro],
    [Software], [Desarrollo de Software], [0,00#sym.euro], [0%], [0,00#sym.euro],
    [NAS], [Copia de seguridad], [194,97#sym.euro], [20%], [155,97#sym.euro],
    [UPS], [Sistema de alimentación ininterrumpida], [150,00#sym.euro], [10%], [135,00#sym.euro],
    [Silla ergonómica], [Mejora el confort durante el trabajo], [180,00#sym.euro], [15%], [153,00#sym.euro],
    [Cables y accesorios], [Soporte técnico], [40,00#sym.euro], [10%], [36,00#sym.euro],
    [Auriculares], [Comunicación y reuniones virtuales], [45,00#sym.euro], [10%], [40,50#sym.euro],
    [*Total*], [], [*2.094,97#sym.euro*], [], [*1.486,97#sym.euro*]
  ),
  caption: [Costes materiales],
) <tab:materialcost>

=== Costes Indirectos
Aquellos que no se pueden categorizar o incluir bajo ningún grupo elegible por la dirección del proyecto @waterfall[Cap. 12].

Para el coste energético, se ha asumido que todos los equipos informáticos son idénticos y no presentaron fallas durante su utilización durante 11 meses. De media cada hora, se ha hecho uso de 500W, por lo tanto, 500W #sym.times 352h #sym.eq 176kWh, lo que supone un gasto total de 44#sym.euro#footnote[Se ha asumido un coste de luz constante de 0,25#sym.euro/kWh.]<footnote:watts>. El plan de internet se reduce a 26#sym.euro al mes, gracias a una oferta por tiempo limitado de una gran empresa de telefonía. En cuanto al transporte, el estudiante hace uso del bono transporte ofrecido por la Comunidad de Madrid, por lo que 10#sym.euro al mes eran más que suficientes para sufragar los gastos de movilidad. 

A continuación, se muestra el balance, en la @tab:indirectcost, de internet, luz y transporte, cubierto por el 5% de reserva mencionado en la @sec:money.

#figure(
  table(
    columns: 4,
    align: (left + top, right + top, right + top, right + top),
    table.header(
      text(size: 10pt)[*Recurso*],
      text(size: 10pt)[*Coste unitario*],
      text(size: 10pt)[*Cantidad*],
      text(size: 10pt)[*Total*],
    ),
    table.hline(),
    [Electricidad], [0,25#sym.euro/kWh@footnote:watts], [176kWh], [44,00#sym.euro],
    [Internet], [26#sym.euro/mes], [11 meses], [286,00#sym.euro],
    [Transporte], [10#sym.euro/mes], [11 meses], [110,00#sym.euro],
    [*Total*], [], [], [*440,00#sym.euro*]
  ),
  caption: [Costes indirectos],
) <tab:indirectcost>

=== Balance Total
La @tab:totalcost incluye un sumario exhaustivo de todos los costes asociados a la ejecución del presente proyecto. Resulta pertinente destacar que el coste definitivo se ha mantenido por debajo de la asignación inicial prevista, lo que arroja como resultado un superávit favorable. Este margen positivo no solo refleja la viabilidad de la planificación, sino que también evidencia un control financiero riguroso y una gestión eficiente de los recursos económicos dispuestos para este fin.

#figure(
  table(
    columns: 2,
    align: (left + top, right + top),
    table.header(
      text(size: 10pt)[*Descripción*],
      text(size: 10pt)[*Total*]
    ),
    table.hline(),
    [Costes directos], [12.501,59#sym.euro],
    [Costes indirectos], [440,00#sym.euro],
    [*Costes totales*], [*12.941,59#sym.euro*],
    [Presupuesto inicial], [13.000,00#sym.euro],
    table.hline(),
    [*Superávit*], [*#sym.plus 268,41#sym.euro*#footnote[Incluye el remanente de la reserva de gastos imprevistos.]]
  ),
  caption: [Balance total],
) <tab:totalcost>

=== Propuesta de Venta <sec:vending>
La @tab:vending ofrece una propuesta de venta del proyecto a una empresa de terceros, por un total de 25.624,33#sym.euro. Se han contemplado impuestos, beneficios y riesgos esperados, el costo total del trabajo (véase @tab:totalcost) y regalías. De manera adicional, se otorga la posibilidad de contratar personal mantenedor de la aplicación.

#figure(
  table(
    columns: 4,
    align: (left + top, right + top, right + top, right + top),
    table.header(
      text(size: 10pt)[*Concepto*],
      text(size: 10pt)[*Afectación*],
      text(size: 10pt)[*Coste parcial*],
      text(size: 10pt)[*Coste agregado*],
    ),
    table.hline(),
    [Coste del proyecto], [], [12.941,59#sym.euro], [12.941,59#sym.euro],
    [Riesgo], [19%], [2.458,90#sym.euro], [15.400,49#sym.euro],
    [Beneficio esperado], [8%], [1.035,32#sym.euro], [16.435,81#sym.euro],
    [Impuestos], [21%], [2.717,73#sym.euro], [19.153,54#sym.euro],
    [Regalías], [5%/año #footnote[Las regalías se dividen en 3% tutor y 2% estudiante.]], [647,07#sym.euro], [19.153,54#sym.euro #sym.plus 647,07#sym.euro #sym.times #sym.lambda#footnote[#sym.lambda #sym.eq número de años.]],
    [*Total a 10 años*], [], [], [*25.624,33#sym.euro*]
  ),
  caption: [Propuesta de venta],
) <tab:vending>

== Marco Regulatorio <sec:law>
A continuación, se discute la legislación que afecta al desarrollo, implementación y día a día del sistema, en la @sec:applylaw, incluyendo los estándares, la @sec:standards, adjuntado las licencias @glossfoss implicadas, @sec:license, y objetivos de desarrollo sostenible a los que contribuye, disponibles en la @sec:odslaw.

=== Legislación Aplicable <sec:applylaw>
Durante el @sec:implementation de implementación, el _software_ y su desarrollo ha sido lanzado en múltiples ocasiones en un entorno @glossfoss controlado @opensourcellms. Posteriormente, en el transcurso del estudio de alternativas de orquestadores de agentes, @sec:agents, y la elección de arquitectura en la @sec:eventdrivenarch, tampoco ha recibido ni el sistema ni el modelo una comunicación con el exterior. 

Cabe destacar que, si la propuesta de venta sale adelante, @sec:vending, y la aplicación acaba siendo expuesta al público, será necesario incluir una declaración de política de privacidad, así como solicitar permiso al usuario del tratamiento de sus datos en el proceso de registro y del tratamiendo de sus _cookies_ durante su navegación, en concordancia con el objetivo O4. Regulación presente en el @glossgdpr:long @gdpr y @glosslopdgdd:long @lopdgddlaw. Asimismo, el programa se alinea con el @glossaiact:long @aiactlaw garantizando la transparencia, la mitigación de sesgos, la supervisión humana y el despliegue de modelos de lenguaje bajo un enfoque basado en el riesgo.

=== Estándares y Marcos Técnicos <sec:standards>
El _software_ desarrollado persigue los siguientes estándares y marcos regulatorios:
- *Definición de Código Abierto, 2007.* Marco técnico y filosófico establecido por la Iniciativa para el Código Abierto, que determina los criterios para que un _software_ sea considerado de código abierto. El proyecto se rige por estos principios para garantizar la libre distribución, el acceso al código fuente y la interoperabilidad, apoyándose en licencias permisivas estandarizadas, presentes en la @sec:license, que fomentan la soberanía tecnológica frente a soluciones propietarias @osiosd.
- *ISO/IEC 21778, 2017.* Formato @glossjson, utilizado en la transmisión de información @isojson.
- *ISO/IEC 21838, 2021.* Establece los requisitos para las ontologías de nivel superior @isoontology[Parte 1] y define la @glossbfo con dichos criterios @isoontology[Parte 2].
- *ISO/IEC 27001, 2022.* Establece directrices sobre cómo implementar y gestionar controles de seguridad para proteger los datos relativos a la @sec:applylaw @isosecurity.
- *ISO/IEC 42001, 2023.* Norma internacional pionera que especifica los requisitos para establecer, implementar, mantener y mejorar continuamente un sistema de gestión de inteligencia artificial @isoaimanagement.
- *ISO/IEC 25002, 2024.* Define las características que debe cumplir un sistema para garantizar la calidad. Evalúa factores como usabilidad, eficiencia, seguridad, mantenibilidad y portabilidad, contemplados durante todo el desarrollo del _software_ @isoquality.
- *OWASP Top 10 GenIA/LLM, 2025.* Extiende las directrices de seguridad tradicionales para abordar de manera específica las vulnerabilidades emergentes del uso de @glossai generativa. Se contempla en el @sec:design de diseño para mitigar riesgos críticos como inyecciones de _prompts_ @owasp[LLM01], divulgación de información sensible @owasp[LLM02] y la desinformación o alucinaciones del modelo @owasp[LLM09]. Especialmente relevante es la mitigación del manejo inadecuado de salidas @owasp[LLM05], abordado mediante el uso de salidas estructuradas, disponible su definición en la @sec:determinism, que validan y sanean la información antes de su integración en el sistema.

=== Licencias <sec:license>
El desarrollo y distribución del presente sistema se fundamenta en los estándares mencionados en la @sec:standards, garantizando la transferencia de conocimiento, la transparencia y la soberanía tecnológica del usuario. Para la liberación del código fuente, se adopta la *licencia MIT*, que permite el uso, copia, modificación o distribución del código fuente sin restricciones o limitaciones. El código completo se encuentra disponible en un repositorio de GitHub @githubrepo. Adicionalmente, se adopta un marco de trabajo @glossfoss en lo que a librerías se refiere, visible en la @tab:libraries, decisión que garantiza que la plataforma no dependa de intermediarios propietarios, alineada con el objetivo principal mencionado en la @sec:objetivos. 

En consonancia, se emplea la *licencia CC BY 4.0*#footnote[Creative Commons Attribution 4.0 International.] para la documentación, que permite compartir, copiar y redistribuir el material en cualquier medio o formato, así como adaptarlo para cualquier propósito, incluso comercial, siempre que se otorgue el crédito correspondiente al autor original.

#figure(
  table(
    columns: 2,
    align: (left + top, left + top),
    table.header(
      text(size: 10pt)[*Licencia*],
      text(size: 10pt)[*Complemento*]
    ),
    table.hline(),
    [MIT], [FastAPI #sym.bullet LangGraph #sym.bullet Pydantic #sym.bullet React #sym.bullet Vite #sym.bullet Zustand], 
    [BSD 3-Clause], [Uvicorn],
    [Apache License 2.0], [vLLM]

  ),
  caption: [Licencias de complementos],
) <tab:libraries>

=== Objetivos de Desarrollo Sostenible <sec:odslaw>
Se concibe un firme compromiso con la Agenda 2030 de las Naciones Unidas @ods. Para dar cumplimiento al objetivo O6, descrito en la @sec:objetivos, se ha establecido un @glosswow que trasciende la mera implementación técnica, orientando la arquitectura y el propósito de la herramienta hacia la generación de un impacto social y tecnológico medible. La *educación de calidad* @ods[ODS 4], abarca un aprendizaje continuo y la adquisición de competencias técnicas avanzadas por parte de la estudiantes y profesionales del sector. Tradicionalmente, la ingeniería del conocimiento queda restringida a perfiles con una alta especialización técnica, debido a la complejidad sintáctica de herramientas tradicionales como _Protégé_. OntoNova democratiza este acceso al abstraer dicha complejidad con el uso de interfaces visuales y @glossnlp. De este modo, se permite que expertos de diversos sectores ---médicos, juristas, humanistas--- estructuren y asimilen dominios de conocimiento complejos, impulsando la alfabetización digital y facilitando la transferencia de conocimiento interdisciplinar sin requerir una curva de aprendizaje elevada.

Persiguiendo la necesidad actual de construir *infraestructuras* tecnológicas resilientes, promover la *industrialización* inclusiva y fomentar la *innovación* @ods[ODS 9], se apuesta por un ecosistema fundamentado íntegramente en software de código abierto, @glossfoss. Queda optimizada la ejecución de @glossllm en _hardware_ local, exponiendo una innovación disruptiva en el procesamiento de datos no estructurados. Esta aproximación reduce drásticamente la dependencia de infraestructuras propietarias en la nube y de servicios prestados por terceros, dotando a las organizaciones e instituciones de una infraestructura de datos soberana, independiente y altamente interoperable bajo los estándares de la Web Semántica del @glossw3c, disponibles en la @sec:semanticweb.

La brecha digital contemporánea no solo se manifiesta en la falta de acceso a la red, sino en la incapacidad de participar activamente en la creación de las tecnologías subyacentes. El propósito central es romper las barreras técnicas e idiomáticas que segregan a los beneficiarios de la Web 3.0, alineado con el objetivo O2, generando una *reducción de las desigualdades* @ods[ODS 10]. Al ofrecer un entorno accesible y multilingüe, marcado en el objetivo O3, se garantiza que las limitaciones de idioma o la falta de destrezas en programación no impidan a los expertos del dominio diseñar y controlar los modelos de conocimiento, contribuyendo activamente a una distribución más equitativa del control sobre la información en el ecosistema digital.

== Entorno Socioeconómico <sec:socialcontext>
El *proyecto OntoNova* surge en un contexto socioeconómico caracterizado por la adopción de la @glossai generativa como herramienta productiva, tanto en España como en el resto de países miembros de la Unión Europea. Tras una fase inicial de revelación masiva, impulsada por la sobreabundancia de información no estructurada y la experimentación a través de @glossllm de uso comercial, en el estudiantado y el ámbito empresarial se genera una nueva necesidad. Estructurar, verificar y dotar de sentido lógico a grandes volúmenes de texto, combatiendo la desinformación y el ruido digital bajo el estricto marco regulatorio europeo @edpb2025ai (e.g., @glossgdpr @gdpr y @glossaiact @aiactlaw).

Este nuevo paradigma trae consigo una gran sobrecarga cognitiva y una crisis de confianza en la información. Profesionales de todos los sectores se enfrentan diariamente a la tarea de extraer conocimiento útil de repositorios documentales masivos. La proliferación de modelos de lenguaje estocásticos, propensos a las alucinaciones @llmhallucination y a la generación de contenido no verificable, ha evidenciado que la simple generación de texto no es suficiente. La sociedad actual requiere sistemas que garanticen la veracidad, la trazabilidad y la estructuración del conocimiento, elementos indispensables para la toma de decisiones críticas en ámbitos como la salud, la justicia o la investigación científica.

Desde una perspectiva económica, la estructura del mercado español, compuesto mayoritariamente por @glosspymes, instituciones académicas y entidades públicas, se enfrenta a una fuerte dependencia frente a grandes proveedores tecnológicos multinacionales. El uso continuado de servicios de @glossai basados en la nube a través de recursos de pago por uso supone costes recurrentes y escalables que resultan inasumibles para entidades de menor envergadura. Cabe destacar que externalizar la extracción y estructuración del conocimiento corporativo interno hacia servidores de terceros suscita riesgos significativos de fuga de capital intelectual corporativo.

La creciente preocupación por la privacidad y la entrada en vigor del @glossaiact:long, impactan en cómo las organizaciones gestionan sus datos. Con el fin de los periodos de adaptación regulatoria, existe una presión institucional por adoptar tecnologías que aseguren la soberanía del dato y eviten la fuga de capital intelectual hacia servidores externos. A esto se suma el intenso debate en torno a la sostenibilidad de los grandes centros de datos, que impulsa la búsqueda de alternativas de menor impacto ambiental. En este escenario, la comunidad @glossfoss @osiosd proporciona soluciones, permitiendo que la ejecución local de modelos avanzados y enérgicamente eficientes no sea una utopía técnica.

La consolidación de un conocimiento interno de calidad, en combinación con la optimización de recursos y la evolución de entornos ágiles, se convierte en un deber con la evolución drástica de componentes inteligentes. En este sentido, una aplicación web de código abierto que permita procesar, extraer y estructurar el conocimiento de forma asíncrona mediante @glossai local, exportable a formatos estándar y consumible por ingenieros de conocimiento, representa una solución socioeconómica clave para que profesionales de cualquier sector puedan integrarse de forma segura en el nuevo paradigma de la @glossai.
