# REQ-US-FC-10 — Entrada mediante ficheros (.txt, .md, PDF)

**Métrica:** acepta ficheros .txt, .md o PDF de hasta 5 MB, rechazando con mensaje informativo las entradas cuyo texto extraído supere los 15.000 caracteres; al menos dos idiomas.
**Método (ISO/IEC/IEEE 29148):** Prueba.

## Cobertura de pruebas (todas en verde, 2026-08-23)
| Nivel | Prueba | Qué verifica |
|---|---|---|
| Unitaria (vitest) | `accepts plain text, markdown and PDF` | Los tres formatos admitidos (R22: enumeración completa) |
| Unitaria (vitest) | `rejects a file over the 5 MB limit` | Frontera de tamaño de transporte |
| Unitaria (vitest) | `rejects a file whose extracted text exceeds the 15,000-character bound` | Frontera de texto extraído, independiente de la de tamaño |
| Unitaria (vitest) | `extracts and uses the text of an attached PDF` + 2 casos de PDF vacío | Extracción pdf.js en el navegador |
| E2E (Playwright) | `a file over 5 MB is rejected with an error message` | Rechazo real en navegador |
| E2E (Playwright) | `a file at exactly the 5 MB boundary passes the size check` | Las dos fronteras disparan de forma independiente |
| E2E (Playwright) | `attaching a text file/PDF generates an ontology` | Flujo completo con stub |
| Aceptación (scrum-4) | PDF real de Wikipedia (okapi) contra la pila completa | Formato PDF de extremo a extremo con GPU |

Resultados: vitest 20/20 (`vitest-panel-filetext.txt`), Playwright 12/12
(`e2e-create-canvas.txt`). Idiomas: ver REQ-US-FC-01 (evidencia compartida).
