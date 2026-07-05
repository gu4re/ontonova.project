# REQ-US-FC-01 — Entrada de texto libre multilingüe con límite

**Métrica:** acepta descripciones de hasta 15.000 caracteres en al menos dos idiomas (es/en).
**Método (ISO/IEC/IEEE 29148):** Prueba.

## Límite de 15.000 caracteres (defensa en dos capas)
| Capa | Mecanismo | Prueba |
|---|---|---|
| Aplicación web | `maxLength` en el área de texto y rechazo al adjuntar con mensaje localizado (`MAX_TEXT_LENGTH = 15000`) | vitest: "rejects a file whose extracted text exceeds the 15,000-character bound" ✓ |
| Servicio de orquestación | Guardarraíl previo `MAX_INPUT_CHARS = 15000` que rechaza en <1 s con evento terminal y código de error localizable | pytest: `test_pipeline_rejects_over_length_input_fast_with_terminal_event` ✓ |

## Dos idiomas
| Idioma | Evidencia |
|---|---|
| Inglés | Prueba de aceptación scrum-3 (texto universitario en inglés): macro F1 1,00 con `language="English"` y con autodetección (`language=""`). |
| Español | Pruebas de aceptación scrum-5/scrum-6 (texto nexolabs en español, autodetección): 20/20 generaciones satisfactorias en la campaña estadística. |

## Ficheros
- `pytest-limites.txt` — salida del guardarraíl backend.
- La evidencia vitest completa está en `../REQ-US-FC-10/vitest-panel-filetext.txt` (comparte panel de creación).
