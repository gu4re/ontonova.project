# REQ-US-FC-02 — Progreso de generación en tiempo real

**Métrica:** el usuario recibe eventos de progreso por etapa; la latencia desde que
el backend detecta el fin de una etapa hasta que la interfaz la pinta como
completada es ≤1 s (extremo a extremo backend→frontend).
**Método (ISO/IEC/IEEE 29148):** Prueba.

## Medición extremo a extremo (2026-08-24, navegador real + pila completa)
Script `latencia-ui.mjs`: envuelve `fetch` para cronometrar la llegada de cada
frame SSE al navegador y sondea a 8 ms el stepper hasta verlo en verde
(`text-success`). Resultado (`latencia-ui-resultado.txt`):

| Etapa | Llegada del frame → pintado en verde |
|---|---|
| taxonomist | 2,1 ms |
| relational | 1,7 ms |
| populator | 20,5 ms |
| validator | 19,1 ms |

El tramo backend→navegador es despreciable (localhost; los frames sin cómputo
pendiente llegan con +0,00 s entre sí, ver medición inferior), por lo que la
latencia total queda acotada en ~21 ms ≪ 1 s. Los ~20 ms de populator/validator
corresponden a un único lote de renderizado de React que pinta ambos frames,
llegados con 2 ms de diferencia.

## Medición instrumentada (2026-08-23, pila real con GPU)
Generación de un texto corto registrando el instante de llegada de cada frame SSE:

| t (s) | Etapa | Δ desde el anterior |
|---|---|---|
| 3,25 | taxonomist | +3,25 s |
| 4,76 | relational | +1,51 s |
| 6,02 | populator | +1,26 s |
| 6,02 | validator | +0,00 s |
| 6,02 | done (success) | +0,00 s |

Dos lecturas satisfacen la métrica. Primera, la llegada es incremental (el primer
evento llega al 54 % del tiempo total, no agrupado al final), lo que demuestra
_streaming_ real sin almacenamiento intermedio. Segunda, las etapas sin cómputo
pendiente (validator, done) llegan con +0,00 s respecto a la anterior, acotando
la latencia de entrega del evento en centésimas de segundo, muy por debajo de 1 s
(el tiempo entre eventos de agentes es cómputo de inferencia, no latencia de
notificación).

## Cobertura adicional
- pytest: `test_pipeline_success_path_yields_every_stage_and_final_payload` (un evento por etapa).
- vitest: "walks the stage stepper and loads the ontology into the store on success" (el panel refleja cada evento).
- Invariante del evento terminal (REQ-SW-NF-03): todo flujo concluye con `done`, probado en 4 tests de fallo.

## Ficheros
- `medir-eventos.py` — script reproducible.
- `eventos-resultado.txt` — salida de la medición.
