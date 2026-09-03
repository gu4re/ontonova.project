= Propuesta de Exposición Pública <sec:cloud>
La propuesta de venta de la @sec:vending plantea la transferencia a un tercero. Este capítulo teoriza el escenario que explota el sistema como servicio público, de un usuario a una multitud, recorriendo las áreas impactadas desde la @sec:clouddesign de arquitectura y la @sec:cloudsecurity de seguridad hasta el planteamiento de un despliegue automático, @sec:clouddeploy, en unión al endurecimiento de la legislación aplicable, @sec:cloudlaw.

== Impacto en la Arquitectura del Sistema <sec:clouddesign>
La arquitectura existente recibe una afectación reducida gracias a la adopción directa del diseño propuesto, @sec:architecture. El método de inspección de la @sec:verifyinspection constata que ningún contenedor almacena estado de sesión, por lo que la transición de un usuario a una multitud se resuelve replicando los contenedores actuales tras un balanceador de carga, en concordancia con las modificaciones que anticipa la @sec:deploymentdesign. El estado de la ontología en edición permanece en el navegador de cada usuario, lo que resuelve condiciones de carrera y evita la necesidad de sincronización entre réplicas. En cuanto al motor de inferencia, este absorbe la demanda por dos vías complementarias, la escalabilidad horizontal habilitada por el protocolo _OpenAI_ y la adopción de un modelo de mayor capacidad, que a su vez aborda el margen de calidad sobre textos densos identificado en la @sec:challenges.

Las novedades arquitectónicas provienen de los requisitos que el despliegue local difiere y que la exposición pública torna indispensables. La @fig:c4contextcloud actualiza el contexto del sistema bajo exposición pública. Por un lado, la identidad en presencia del registro de usuarios, REQ-US-FC-09, y la autenticación y autorización, REQ-SW-NF-07, introducen la primera pieza con estado del sistema, delegada en un proveedor de identidad externo y de código libre, _Keycloak_, que aprovecha el protocolo _OpenID Connect_ para ofrecer lo que las métricas de dichos requisitos necesitan. Al introducir una nueva pieza, los contenedores existentes permanecen intactos en un nuevo ejercicio en favor del principio abierto/cerrado @cleanarchitecture[Cap. 8] verificado en REQ-SW-NF-06. Por otro lado, la trazabilidad de los casos de uso que anticipa el requisito REQ-SW-FC-01 en estado viable pero no incluido en la solución local toma fuerza al existir una multitud de ejecuciones que observar, sin embargo, su implantación resulta natural porque los eventos por etapa del diseño de la @sec:eventdesign ya existen, restando un servicio como _Grafana_ que los persista por usuario para alimentar la mejora continua y la auditoría.

Descendiendo un nivel de abstracción, la @fig:cloudarch esboza una propuesta operacional de los contenedores en la nube. El balanceador de carga concentra la entrada cifrada de los usuarios y la reparte entre las réplicas de la aplicación web, que junto a las del servicio de orquestación habitan un espacio de nombres de un clúster de _Kubernetes_. Por otra parte, el motor de inferencia se aísla en un espacio de nombres propio con un grupo de nodos con @glossgpu y autoescalado, cuya elección y operación desarrolla la @sec:clouddeploy, mientras que la identidad y el registro de trazabilidad se consumen como servicios gestionados, minimizando la superficie que el proveedor debe operar por sí mismo.

#figure(
  image("../img/c4contextcloud.png", width: 100%),
  caption: [Diagrama C4 del contexto del sistema bajo exposición pública.],
) <fig:c4contextcloud>

#figure(
  image("../img/cloudarch.png", width: 100%),
  caption: [Diagrama operacional del sistema bajo exposición pública.],
) <fig:cloudarch>

== Impacto en el Diseño de Seguridad <sec:cloudsecurity>
La exposición pública convierte en indispensables los requisitos de seguridad que el despliegue local no implementa. El registro de usuarios, REQ-US-FC-09, y la autenticación y autorización, REQ-SW-NF-07, recaen sobre el proveedor de identidad introducido en la @sec:clouddesign, de modo que cada petición atraviesa las puertas que ilustra la @fig:secgauntlet acompañada de un testigo verificable por el proveedor y emitido por _OpenID Connect_, por lo tanto, los contenedores, @sec:c4containers, conservan su ausencia de estado. El servicio de trazabilidad adquiere una segunda función, ya que la misma bitácora que alimenta la mejora continua, REQ-SW-FC-01, constituye el registro de auditoría que todo proceso operacional requiere para atribuir acciones a identidades.

El análisis de riesgos de la @sec:securitydesign se mantiene vigente pero la superficie de impacto se ensancha. Las mitigaciones estructurales contra la inyección de _prompts_ @owasp[LLM01] y la manipulación de la salida @owasp[LLM05] ---la decodificación guiada y el contrato validado de forma determinista--- escalan sin cambios, dado que no dependen del número de usuarios sino de la salida. Sin embargo, un público anónimo y potencialmente hostil puede multiplicar los intentos, por lo que la limitación de tasa y las cuotas por identidad pasan de un estado conveniente a ser una nueva mitigación indispensable. Esta medida previene un consumo desbocado @owasp[LLM10], un riesgo potencial en la nube e inaplicable en local, pues si cada petición consume tiempo de una @glossgpu con un coste asociado y se produce un escenario de ataque, el abuso se traduce tanto en un daño económico al proveedor como en la pérdida de disponibilidad del servicio. La divulgación de información sensible @owasp[LLM02] también se reevalúa, porque el motor de inferencia pasa a atender peticiones entrelazadas de usuarios distintos con el procesamiento por lotes continuo, obligando a garantizar el aislamiento entre peticiones y la ausencia de persistencia de los textos en _vLLM_.

Completa el impacto el endurecimiento del perímetro. El cifrado de transporte @glosshttp se extiende de extremo a extremo desde el balanceador que la @sec:clouddesign expone, seguido de la configuración sensible que abandona los ficheros de entorno `.env` en favor de un gestor de secretos de código abierto como _CyberArk Conjur_, y el punto de entrada incorpora protección perimetral frente al tráfico malicioso. El desplazamiento profundo es no obstante el de la privacidad, pues el texto del dominio abandona el equipo del experto para entrar en la frontera de confianza de la @sec:clouddesign del proveedor, giro que desactiva el argumento central de privacidad del diseño original, @sec:securitydesign, y traslada la protección del dato del plano arquitectónico al plano normativo que examina la @sec:cloudlaw.

#figure(
  image("../img/secgauntlet.png", width: 100%),
  caption: [Puertas de seguridad que atraviesa cada petición en la exposición pública.],
) <fig:secgauntlet>

== Impacto en el Diseño del Despliegue <sec:clouddeploy>
El despliegue es el área donde la propuesta introduce más piezas nuevas, aunque ninguna altera los artefactos existentes. La composición local de la @sec:deploymentdesign se traslada a _Kubernetes_ con una correspondencia directa, pues cada contenedor deviene un despliegue replicable con su servicio, el volumen de pesos del modelo se convierte en un volumen persistente del clúster y la vista de despliegue actualizada la anticipa la @sec:clouddesign, donde los nodos pasan del equipo doméstico a un clúster gestionado. La elección de _Google Kubernetes Engine_ responde a tres motivos, la condición de estándar libre _de facto_ de _Kubernetes_ para orquestar contenedores, el soporte nativo de grupos de nodos con @glossgpu dotados de autoescalado#footnote[_Google Kubernetes Engine_ permite el escalado a cero réplicas, optimizando el coste de aprovisionamiento que acota la propuesta.] y el encaje natural en el marco universitario del proyecto, beneficiario del ecosistema académico de _Google_.

El plantillado con _Helm_ reduce la complejidad operativa y fomenta la reutilización comprometida por el requisito REQ-SW-NF-08. Un _chart_ agrupa tres _subcharts_ ---aplicación web, servicio de orquestación y motor de inferencia--- cuyos valores por entorno separan lo que cambia entre escenarios de lo que permanece, por lo que el mismo empaquetado sirve al clúster público y a un despliegue local mínimo, preservando la soberanía tecnológica del usuario doméstico que defiende la @sec:odslaw como un caso particular del mismo artefacto, @fig:chart.

#figure(
  kind: image,
  grid(
    columns: 2,
    gutter: 10pt,
    align: top,
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
        ```yaml
        # values-local.yaml
        web:
          replicas: 1
        orquestacion:
          replicas: 1
        inferencia:
          replicas: 1
          modelo: Qwen3-14B-AWQ
          gpu: rtx-4090
        identidad:
          habilitada: false
        ```
      ])
    ),
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
        ```yaml
        # values-gke.yaml
        web:
          replicas: 3
        orquestacion:
          replicas: 3
        inferencia:
          replicas: 4
          modelo: Qwen3-235B-AWQ
          nodePool: gpu-h100
        identidad:
          habilitada: true
        ```
      ])
    )
  ),
  caption: [Valores del _chart_ por escenario, con el empaquetado común.],
) <fig:chart>

La automatización se materializa en un flujo de integración y entrega continuas sobre _GitHub Actions_, ilustrado en la @fig:cipipeline, cuyas etapas institucionalizan la pirámide de la @sec:verifysummary, convirtiendo cada nivel en una etapa de calidad. Con cada contribución al código fuente, se ejecutan el análisis estático y las pruebas unitarias y de servicio, se construyen las imágenes con el escaneo de dependencias que verifica REQ-SW-NF-02 extendido a las imágenes, y se validan los casos de uso con las pruebas de navegador sobre una composición efímera. Las pruebas de aceptación exigen una @glossgpu dedicada y minutos por generación, por lo que se ejecutan de forma nocturna y como requisito previo a toda entrega, trasladando al proceso automatizado las campañas estadísticas del @sec:verification. 

Superadas las fases, la entrega lanza `helm upgrade` sobre el entorno de preproducción y promociona a producción con aprobación manual mediante un despliegue progresivo, viable sin riesgo de incoherencia de estado de la @sec:verifyinspection porque las réplicas son intercambiables. Cierra la operación la observabilidad, dado que los eventos por etapa de la @sec:eventdesign y su identidad se plasman en el registro de trazabilidad de la @sec:clouddesign, que sin instrumentación adicional ofrece las métricas de latencia y uso que el autoescalado de _Kubernetes_ y la mejora continua consumen.

#figure(
  image("../img/cipipeline.png", width: 100%),
  caption: [Ciclo de integración continua y despliegue continuo.],
) <fig:cipipeline>

== Impacto en la Legislación Aplicable <sec:cloudlaw>
El marco legislativo de la @sec:applylaw permanece vigente pero sufre un endurecimiento en dos frentes. El primero es la protección de datos, ya que el argumento que sostiene el cumplimiento del @glossgdpr @gdpr en la solución local ---el texto del dominio nunca abandona el equipo del experto--- queda desactivado por el desplazamiento de la frontera de confianza descrito en la @sec:cloudsecurity, asumiendo el proveedor de OntoNova la condición de responsable del tratamiento sobre los textos, grafos y datos de cuenta de sus usuarios. Por ende, el proveedor de infraestructura se instrumenta contractualmente como mero encargado en su adenda de tratamiento de datos @gclouddpa, sin asumir responsabilidad alguna sobre los fines. De esa condición se derivan las obligaciones plenas del responsable, desde la base jurídica del @glossgdpr @gdpr y la política de retención hasta la selección de regiones europeas de despliegue que evite transferencias internacionales de datos. El segundo impacto queda recogido en el @glossaiact @aiactlaw, dado que la verificación del mismo, en cumplimiento del objetivo O4, @sec:verifyregulation, recoge exclusiones como la investigación y desarrollo, y código abierto que se extinguen con la publicación, restaurando las obligaciones ordinarias de proveedor. El cuestionario de conformidad del @app:aiact plantea una reevaluación bajo el nuevo supuesto, representando el primer entregable de esta propuesta futura, tal y como anticipa la @sec:verifyregulation, con especial atención a las obligaciones de transparencia del Artículo 50. 

En términos de licenciamiento, la elección de la @sec:license se reexamina ante el cambio de escenario de servicio. La incertidumbre radica en si la licencia del código fuente @glosseupl @eupl debe ceder ante una licencia orientada a la nube como la @glossagpl, cuyo rasgo distintivo es extender el _copyleft_ a quien presta el _software_ como servicio sin obligar a distribuirlo. La @glosseupl, en compatibilidad declarada con @glossagpl, también incorpora ese alcance, definiendo la distribución o comunicación como la puesta a disposición en línea de funcionalidades esenciales a otra persona física o jurídica. Cabe resaltar el compromiso del licenciatario de facilitar al público la información mínima reclamada por la legislación aplicable, siendo indispensable en un trabajo futuro, @sec:future-work, un aviso legal y una declaración de política de privacidad dentro de OntoNova. En consecuencia, se mantiene la @glosseupl:long.
