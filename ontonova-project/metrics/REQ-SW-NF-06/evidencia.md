# REQ-SW-NF-06 — Extensibilidad (principio abierto-cerrado)

**Métrica:** las extensiones previstas se incorporan sin rediseñar los componentes existentes.
**Método (ISO/IEC/IEEE 29148):** Inspección.

## Puntos de extensión inspeccionados
| Extensión prevista | Mecanismo | Coste de incorporación | Fichero |
|---|---|---|---|
| Nuevo formato de exportación | Mapa `_EXPORT_FORMATS` (nombre → formato rdflib, tipo MIME, extensión) | Una entrada en el mapa | `backend/api/routers/ontology.py` |
| Nuevo idioma de interfaz | Recurso JSON de i18next por idioma | Un fichero de traducciones | `frontend/src/i18n/` |
| Nuevo modelo de lenguaje | Variables `LLM_MODEL_NAME` y `*_BASE_URL` | Solo configuración (ver REQ-SW-FC-02) | `docker-compose.yml` |
| Modelo distinto por agente | Una `BASE_URL` independiente por etapa | Solo configuración | `docker-compose.yml` |
| Nuevo código de error localizado | Convención `code` + `params` en los eventos de fallo, mapa de localización en el cliente | Una clave de traducción por idioma | `frontend/src/api/client.ts`, `i18n/` |
| Nuevo agente en la cadena | Nodo LangGraph con esquema de salida acotado propio, insertado en `build_graph()` | Un nodo + una arista; los existentes no cambian | `backend/api/core/graph.py` |
| Límites operativos | `MAX_INPUT_CHARS`, `LLM_REQUEST_TIMEOUT_SECONDS` vía entorno | Solo configuración | `backend/api/core/graph.py` |

## Evidencia empírica de la inspección
Dos extensiones reales incorporadas durante el desarrollo confirman el análisis:
la entrada PDF se añadió como un caso más del extractor de documentos sin tocar
el flujo de generación (REQ-US-FC-10), y la localización de errores del backend
se añadió con la convención `code`/`params` sin modificar el transporte SSE ni
los agentes. En ambos casos las suites existentes pasaron sin adaptación,
señal de que los componentes cerrados permanecieron cerrados.
