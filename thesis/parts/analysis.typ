= Análisis
Esta sección incluye detalles acerca del análisis de requisitos. En páginas posteriores, se describe la gestión de requisitos con su origen y estándar a utilizar, @sec:requirementmanagement, así como la exposición de los requisitos de usuario, del sistema @requirementsanalysis y los casos de uso derivados de los mismos, en la @sec:requirementexposition.

== Gestión de Requisitos <sec:requirementmanagement>
En este apartado se menciona y destaca el origen de los requisitos, @sec:requirementorigin, y qué estándares reconocidos se han utilizado de cara a la declaración de requisitos, en la @sec:requirementstandard.

=== Origen de los Requisitos <sec:requirementorigin>
El proyecto está determinado mayoritariamente por requisitos y restricciones en el _software_ impuestos por la gerente de proyecto, actuando como tutora#footnote[La figura de la tutora asume funcionalmente el rol de _stakeholder_ y _product owner_.], con el objetivo de aportar innovación, investigación y modernidad a la implementación del sistema de gestión del conocimiento, en concordancia con las metas descritas en la @sec:objetivos y objetivos de desarrollo sostenible, delimitados en la @sec:odslaw.

Por otro lado, se consideran requisitos de usuario ---médicos, juristas, humanistas--- y del sistema derivados de la investigación y revisión documental llevada a cabo en el @sec:stateofart, sin olvidar las necesidades de los afectados mostradas en la @sec:socialcontext. En este sentido, se ha tenido en cuenta la experiencia de los usuarios finales y limitaciones arquitecturales, con el fin de garantizar que el producto final cumpla con las expectativas y requerimientos del proyecto, que influyen en el diseño e implementación de la aplicación @userstorysoftware.

=== Estándar IEEE para la Declaración de Requisitos <sec:requirementstandard>
La gestión y calidad de requisitos toma como referencia las características definidas por el @glossieee, n.º 830-1998 @isoieee, recomendado para el manejo, especificación de necesidades de usuario y buenas prácticas. Estas son:
- *Correcto.* Las especificaciones de _software_ deben ir acorde a las necesidades del usuario @isoieee[Cap. 4.3.1].
- *Sin ambigüedad.* Un requisito no debe dar lugar a más de una interpretación @isoieee[Cap. 4.3.2].
- *Completo.* El documento contenedor debe tener todos los requisitos de _software_ significativos @isoieee[Cap. 4.3.3].
- *Consistente.* Los requisitos no deben generar conflictos entre sí @isoieee[Cap. 4.3.4].
- *Orden de prioridad.* Es necesario establecer una prioridad y necesidad para cada uno de los requisitos @isoieee[Cap. 4.3.5].
- *Verificable.* Debe existir un proceso que permita comprobar el éxito de la especificación @isoieee[Cap. 4.3.6].
- *Modificable.* La estructura y estilo del documento de especificación deben permitir que los cambios se realicen de manera fácil, completa y consistente @isoieee[Cap. 4.3.7].
- *Trazable.* Cada requisito funcional debe tener un origen bien definido @isoieee[Cap. 4.3.8].

Posteriormente, la norma ISO/IEC/IEEE 29148:2018 @isoieee29148[Cap. 5.2] sustituye a @glossieee n.º 830-1998 @isoieee, manteniendo los principios fundamentales destacados y ampliándolos con nuevas características y atributos para los requisitos individuales y los conjuntos de requisitos, ofreciendo una clasificación más detallada y completa de los mismos.

== Exposición de Requisitos <sec:requirementexposition>
La @tab:requisitetemplate enmarca el contenido de un requisito de usuario o de _software_, funcional y no funcional, del desarrollo de la aplicación. La nomenclatura utilizada es `REQ-XX-YY-ZZ`, siendo `XX` el identificador del requisito, `YY` el ámbito o grupo al que pertenece, `US` para usuario y `SW` para _software_, y `ZZ` el tipo de requisito, con los valores `FC` o `NF` indicando, funcional o no funcional, respectivamente.

#figure(
  table(
    columns: (auto, 1fr),
    align: (col, row) => if col == 0 { left + top } else { left + top },
    table.header(
      text(size: 10pt)[*Campo*],
      text(size: 10pt)[*Descripción*]
    ),
    table.hline(),
    text(size: 10pt)[*ID*], [REQ-XX-YY-ZZ.],
    text(size: 10pt)[*Descripción*], [Descripción detallada del requisito.],
    text(size: 10pt)[*Carácter*], [Necesidad del usuario o del diseño #text(size: 10pt)[(Obligatorio, Conveniente u Opcional)].],
    text(size: 10pt)[*Prioridad*], [Importancia del requisito #text(size: 10pt)[(Alta, Media o Baja)].],
    text(size: 10pt)[*Estado*], [Situación durante el desarrollo #text(size: 10pt)[(Incluido, Viable o Requiere nuevo diseño)].#footnote[La clave entre viabilidad y complejidad reside en el grado de refactorización de la aplicación.]],
    text(size: 10pt)[*Verificabilidad*], [Indica cuánta es la posibilidad de probar dicho requisito #text(size: 10pt)[(Alta, Media o Baja)].],
    text(size: 10pt)[*Origen*], [Indica el origen del requisito #text(size: 10pt)[(Usuario, Gerente de Proyecto o REQ-XX-YY-ZZ)].],
  ),
  caption: [Contenido de un requisito],
) <tab:requisitetemplate>

=== Requisitos de Usuario <sec:userrequisites>
La @tab:funcuserrequisites representa los requisitos de usuario funcionales. Los requisitos no funcionales están organizados en la @tab:nofuncuserrequisites.

#[
  #show figure: set block(breakable: true)
  #figure(
    table(
      columns: (auto, 1.7fr, 2fr),
      align: (col, row) => left + top,
      table.header(
        text(size: 10pt)[*ID*], 
        text(size: 10pt)[*Atributos*], 
        text(size: 10pt)[*Descripción*]
      ),
      table.hline(),
      
      [REQ-US-FC-01],
      [
        Carácter: Obligatorio. \
        Prioridad: Alta. \
        Estado: Incluido. \
        Verificabilidad: Alta. \
        Origen: Usuario.
      ],
      [El sistema permite al usuario introducir texto en lenguaje multilingüe a través de la interfaz web para iniciar el proceso de elaboración de una ontología.],

      [REQ-US-FC-02],
      [
        Carácter: Obligatorio. \
        Prioridad: Alta. \
        Estado: Incluido. \
        Verificabilidad: Alta. \
        Origen: Gerente de Proyecto.
      ],
      [La interfaz web debe ser capaz de mostrar el progreso del proceso de elaboración de una ontología en tiempo real.],
      
      [REQ-US-FC-03],
      [
        Carácter: Obligatorio. \
        Prioridad: Alta. \
        Estado: Incluido. \
        Verificabilidad: Alta. \
        Origen: Gerente de Proyecto.
      ],
      [El _backend_ debe construir una ontología bien formada, disponiendo de un motor de degradación elegante y una gestión de errores críticos garantizando la resiliencia del proceso.],

      [REQ-US-FC-04],
      [
        Carácter: Obligatorio. \
        Prioridad: Alta. \
        Estado: Incluido. \
        Verificabilidad: Alta. \
        Origen: Usuario.
      ],
      [La interfaz web proporciona un lienzo interactivo que permite al usuario visualizar, modificar, añadir o eliminar las clases o nodos y aristas o relaciones del grafo generado.],

      [REQ-US-FC-05],
      [
        Carácter: Obligatorio. \
        Prioridad: Media. \
        Estado: Incluido. \
        Verificabilidad: Alta. \
        Origen: REQ-US-FC-04.
      ],
      [El usuario puede exportar la ontología final validada desde la interfaz web a un formato estándar @glossw3c para su uso en otras aplicaciones.],

      [REQ-US-FC-06],
      [
        Carácter: Opcional. \
        Prioridad: Media. \
        Estado: Requiere nuevo \ diseño. \
        Verificabilidad: Media. \
        Origen: REQ-US-FC-04.
      ],
      [El sistema permite el modelado y edición simultánea del grafo de conocimiento por parte de múltiples usuarios concurrentes.],

      table.cell(colspan: 3)[#colbreak()],
      table.cell(colspan: 3)[#colbreak()],
      table.cell(colspan: 3)[#colbreak()],
      table.cell(colspan: 3)[#colbreak()],
      [REQ-US-FC-07],
      [
        Carácter: Conveniente. \
        Prioridad: Media. \
        Estado: Viable. \
        Verificabilidad: Alta. \
        Origen: REQ-US-FC-04.
      ],
      [El sistema incluye un histórico de versiones que registra el historial completo de modificaciones del grafo, permitiendo al usuario revertir y auditar cambios si es necesario.],

      [REQ-US-FC-08],
      [
        Carácter: Conveniente. \
        Prioridad: Baja. \
        Estado: Requiere nuevo diseño. \
        Verificabilidad: Alta. \
        Origen: REQ-US-FC-05.
      ],
      [El sistema permite la importación de ontologías existentes en formatos estándar @glossw3c a través de un recorrido web.],

      [REQ-US-FC-09],
      [
        Carácter: Conveniente. \
        Prioridad: Baja. \
        Estado: Viable. \
        Verificabilidad: Alta. \
        Origen: REQ-US-FC-07.
      ],
      [Los usuarios deben poder registrarse en la plataforma proporcionando información válida.],

      [REQ-US-FC-10],
      [
        Carácter: Conveniente. \
        Prioridad: Baja. \
        Estado: Requiere nuevo diseño. \
        Verificabilidad: Alta. \
        Origen: REQ-US-FC-07/09.
      ],
      [El sistema permite al usuario visualizar el lienzo interactivo de las ontologías pasadas en conjunto con el historial de modificaciones.],
    ),
    caption: [Requisitos funcionales de usuario],
  ) <tab:funcuserrequisites>
]

#[
  #show figure: set block(breakable: true)
  #figure(
    table(
      columns: (auto, 1.5fr, 2fr),
      align: (col, row) => left + top,
      table.header(
        text(size: 10pt)[*ID*], 
        text(size: 10pt)[*Atributos*], 
        text(size: 10pt)[*Descripción*]
      ),
      table.hline(),
      
      [REQ-US-NF-01],
      [
        Carácter: Conveniente. \
        Prioridad: Alta. \
        Estado: Incluido. \
        Verificabilidad: Alta. \
        Origen: Usuario.
      ],
      [La interfaz de usuario debe ser intuitiva y fácil de usar, permitiendo a los usuarios encontrar rápidamente la información que necesitan.],

      [REQ-US-NF-02],
      [
        Carácter: Conveniente. \
        Prioridad: Media. \
        Estado: Incluido. \
        Verificabilidad: Baja. \
        Origen: Usuario.
      ],
      [La aplicación debe cargar en un tiempo considerablemente rápido como para no ralentizar las acciones del usuario.],
      
      [REQ-US-NF-03],
      [
        Carácter: Conveniente. \
        Prioridad: Alta. \
        Estado: Viable. \
        Verificabilidad: Alta. \
        Origen: Usuario.
      ],
      [Debe existir un sistema de soporte para ayudar a los usuarios con problemas técnicos y un plan de mantenimiento regular.],
    ),
    caption: [Requisitos no funcionales de usuario],
  ) <tab:nofuncuserrequisites>
]

=== Requisitos del Sistema <sec:systemrequisites>
Contemplando el contenido de requisitos de la @tab:requisitetemplate, a continuación se describen los requisitos de _software_ derivados de los requisitos establecidos por el usuario @requirementsanalysis[Cap. 5], ya sea un médico, jurista o humanista. La @tab:funcsystemrequisites recoge los requisitos funcionales y la @tab:nofuncsystemrequisites los no funcionales.

#[
  #show figure: set block(breakable: true)
  #figure(
    table(
      columns: (auto, 1.5fr, 2fr),
      align: (col, row) => left + top,
      table.header(
        text(size: 10pt)[*ID*], 
        text(size: 10pt)[*Atributos*], 
        text(size: 10pt)[*Descripción*]
      ),
      table.hline(),
      
      [REQ-SW-FC-01],
      [
        Carácter: Conveniente. \
        Prioridad: Media. \
        Estado: Viable. \
        Verificabilidad: Media. \
        Origen: REQ-US-NF-01/03.
      ],
      [Incluir trazabilidad y métricas de usuario que sirvan para contribuir a la mejora continua.],

      [REQ-SW-FC-02],
      [
        Carácter: Obligatorio. \
        Prioridad: Alta. \
        Estado: Incluido. \
        Verificabilidad: Alta. \
        Origen: Gerente de Proyecto.
      ],
      [El sistema debe comunicarse con el motor de inferencia local utilizando un protocolo estándar, garantizando la independencia y modularidad del modelo subyacente.]
    ),
    caption: [Requisitos funcionales del sistema],
  ) <tab:funcsystemrequisites>
]

#[
  #show figure: set block(breakable: true)
  #figure(
    table(
      columns: (auto, 1.5fr, 2fr),
      align: (col, row) => left + top,
      table.header(
        text(size: 10pt)[*ID*], 
        text(size: 10pt)[*Atributos*], 
        text(size: 10pt)[*Descripción*]
      ),
      table.hline(),
      
      [REQ-SW-NF-01],
      [
        Carácter: Obligatorio. \
        Prioridad: Baja. \
        Estado: Viable. \
        Verificabilidad: Alta. \
        Origen: REQ-US-NF-01/03.
      ],
      [Asegurar que la aplicación sea accesible para personas con discapacidad, cumpliendo con las @glosswcag @wcag2.],

      [REQ-SW-NF-02],
      [
        Carácter: Obligatorio. \
        Prioridad: Alta. \
        Estado: Incluido. \
        Verificabilidad: Media. \
        Origen: Gerente de Proyecto.
      ],
      [El _software_ debe ser desarrollado siguiendo los estándares de seguridad, escalabilidad y patrones de diseño de software @cleanarchitecture[Cap. 6], en concordancia con el objetivo O5 de la @sec:objetivos.],
      
      [REQ-SW-NF-03],
      [
        Carácter: Conveniente. \
        Prioridad: Media. \
        Estado: Viable. \
        Verificabilidad: Alta. \
        Origen: REQ-US-FC-01/03.
      ],
      [La aplicación debe ser resiliente, lo que implica que debe poder manejar errores y recuperarse de fallos sin afectar la experiencia del usuario.],

      table.cell(colspan: 3)[#colbreak()],
      table.cell(colspan: 3)[#colbreak()],
      table.cell(colspan: 3)[#colbreak()],
      table.cell(colspan: 3)[#colbreak()],
      [REQ-SW-NF-04],
      [
        Carácter: Conveniente. \
        Prioridad: Media. \
        Estado: Viable. \
        Verificabilidad: Alta. \
        Origen: Gerente de Proyecto.
      ],
      [Incluir un marco de pruebas automatizadas para garantizar que el _software_ funcione correctamente.],

      [REQ-SW-NF-05],
      [
        Carácter: Conveniente. \
        Prioridad: Alta. \
        Estado: Incluido. \
        Verificabilidad: Alta. \
        Origen: Gerente de Proyecto.
      ],
      [La aplicación debe estar acompañada de una documentación técnica, que incluya guías de instalación, uso y mantenimiento del _software_.],

      [REQ-SW-NF-06],
      [
        Carácter: Conveniente. \
        Prioridad: Media. \
        Estado: Incluido. \
        Verificabilidad: Alta. \
        Origen: Gerente de Proyecto.
      ],
      [La arquitectura del sistema debe permitir la adición de nuevas funcionalidades y la gestión de un aumento en el número de usuarios sin necesidad de rediseño completo @cleanarchitecture[Cap. 10].],
      [REQ-SW-NF-07],
      [
        Carácter: Obligatorio. \
        Prioridad: Alta. \
        Estado: Viable. \
        Verificabilidad: Alta. \
        Origen: REQ-US-FC-09.
      ],
      [Implementar medidas de seguridad robustas, como la autenticación y autorización, para proteger los datos de los usuarios y prevenir accesos no autorizados.],
      [REQ-SW-NF-08],
      [
        Carácter: Conveniente. \
        Prioridad: Alta. \
        Estado: Incluido. \
        Verificabilidad: Alta. \
        Origen: Gerente de Proyecto.
      ],
      [El sistema debe estar contenerizado para asegurar un despliegue ágil, predecible y agnóstico respecto a la infraestructura de _hardware_ local.]
    ),
    caption: [Requisitos no funcionales del sistema],
  ) <tab:nofuncsystemrequisites>
]

=== Casos de Uso <sec:usecases>
En esta sección, los principales casos de uso están ligados a los requisitos incluidos de los usuarios. Se ofrece una descripción del caso, actores principales, flujos principales y alternativos, según aplique, además de ligarlos a su requisito de usuario correspondiente @umlfowler[Cap. 6]. La información quedará expuesta en un diagrama de @glossuml.

#heading(level: 4, numbering: none)[
  Creación de una ontología
]
- *Descripción.* El usuario introduce un texto explicativo en un lenguaje de preferencia a través de la interfaz web para que el sistema procese, valide y genere de forma asíncrona el primer borrador de la ontología.
- *Actores involucrados.* Usuario y sistema.
- *Flujo principal.* El usuario accede al formulario, introduce el texto descriptivo del dominio y solicita la creación de la ontología. El sistema provee de la semántica, en una conexión asíncrona, validada y lista para ser renderizada sobre el lienzo interactivo.
- *Flujo secundario.* En caso de error o de generación de una estructura inválida, el sistema activa el motor de degradación elegante y ejecuta un ciclo de corrección alertando al usuario.
- *Requisitos de usuario asociados.* REQ-US-FC-01, REQ-US-FC-02, REQ-US-FC-03.

#heading(level: 4, numbering: none)[
  Edición de una ontología
]
- *Descripción.* El usuario manipula de forma directa los elementos visuales del grafo semántico generado, permitiéndole refinar el conocimiento añadiendo, modificando o eliminando clases y relaciones.
- *Actores involucrados.* Usuario y sistema.
- *Flujo principal.* El usuario interactúa con el lienzo visual, selecciona un componente, ejecuta una acción que es actualizada y validada de forma reactiva y en caliente por el sistema.
- *Flujo secundario.* En caso de error o de generación de una estructura inválida, el sistema activa el motor de degradación elegante y ejecuta un ciclo de corrección alertando al usuario.
- *Requisitos de usuario asociados.* REQ-US-FC-04.

#heading(level: 4, numbering: none)[
  Eliminación de una ontología
]
- *Descripción.* El usuario purga el lienzo de trabajo actual para descartar el modelo en pantalla y liberar los recursos de la interfaz de cara a un nuevo análisis.
- *Actores involucrados.* Usuario y sistema.
- *Flujo principal.* El usuario, situado en la pantalla del lienzo interactivo, solicita la eliminación de la ontología actual mediante el icono de borrado o reinicio. El sistema solicita confirmación debido a la criticidad de la acción y, en caso afirmativo, limpia el lienzo devolviendo el visual a su estado inicial.
- *Flujo secundario.* Si el usuario cancela la operación en el paso de confirmación, el sistema cierra la ventana de confirmación y el lienzo se mantiene intacto.
- *Requisitos de usuario asociados.* REQ-US-FC-04.

#heading(level: 4, numbering: none)[
  Exportación de una ontología
]
- *Descripción.* El usuario descarga la ontología validada sobre el lienzo hacia un archivo local en un formato estándar @glossw3c compatible con otras soluciones semánticas del sector.
- *Actores involucrados.* Usuario y sistema.
- *Flujo principal.* El usuario solicita la exportación a través del icono de descarga seleccionando el formato de destino de preferencia. El sistema compila el estado actual y lo empaqueta en el formato seleccionado, generando un flujo de descarga hacia el almacenamiento local del usuario.
- *Flujo secundario.* No aplica al tratarse de una operación de descarga local.
- *Requisitos de usuario asociados.* REQ-US-FC-05.

#pagebreak()
#heading(level: 4, numbering: none)[
  Diagrama de Casos de Uso
]
Queda disponible la @fig:umlcases en la siguiente página, la cuál contiene el diagrama @glossuml de los casos de uso mencionados en la @sec:usecases.

#figure(
  image("../img/uml.png", width: 90%),
  caption: [Diagrama de casos de uso en lenguaje UML.],
) <fig:umlcases>