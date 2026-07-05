# REQ-SW-FC-02 — Sustitución del modelo por configuración

**Métrica:** el cambio de modelo de lenguaje se realiza únicamente mediante configuración, sin modificar código.
**Método (ISO/IEC/IEEE 29148):** Demostración.

## Puntos de configuración (sin tocar código)
| Variable | Ámbito | Valor por defecto |
|---|---|---|
| `LLM_MODEL_NAME` | Servicio de orquestación | `Qwen/Qwen3-14B-AWQ` |
| `TAXONOMIST_BASE_URL` | Agente taxonomista | `http://vllm:8000/v1` |
| `RELATIONAL_BASE_URL` | Agente relacional | `http://vllm:8000/v1` |
| `POPULATOR_BASE_URL` | Agente poblador | `http://vllm:8000/v1` |
| `--model` (servicio vllm) | Motor de inferencia | `Qwen/Qwen3-14B-AWQ` |

Fuentes: `docker-compose.yml` (servicios `vllm` y `backend`, valores sobreescribibles
vía `.env`) y `backend/api/services/vllm_client.py` (línea 7: el nombre del modelo
se lee de entorno con `os.getenv`).

## Demostración
1. El cliente de inferencia habla el protocolo OpenAI, por lo que cualquier motor
   compatible (vLLM con otro modelo, otro servidor de inferencia) es sustituible
   cambiando `LLM_MODEL_NAME` y la imagen/comando del servicio `vllm` en `.env` /
   `docker-compose.yml`, seguido de `docker compose up -d`.
2. La configuración es además **por agente**: cada etapa (taxonomista, relacional,
   poblador) declara su propia `*_BASE_URL`, lo que permite servir cada agente
   desde un modelo distinto sin cambio de código — extensión directa del
   principio abierto-cerrado (REQ-SW-NF-06).
3. Las pruebas unitarias del cliente de inferencia (3, pytest) fijan el contrato
   del protocolo con el motor, garantizando que la sustitución no depende de
   ningún detalle no configurable.
