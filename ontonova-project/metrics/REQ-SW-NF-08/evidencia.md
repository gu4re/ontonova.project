# REQ-SW-NF-08 — Despliegue contenerizado

**Métrica:** el despliegue completo del sistema contenerizado se completa en <5 minutos.
**Método (ISO/IEC/IEEE 29148):** Prueba.

## Procedimiento (2026-08-23)
1. Parada y eliminación completa del despliegue previo (`docker compose down`,
   red incluida).
2. Cronometraje de `docker compose up -d --wait` hasta que los tres servicios
   responden (healthcheck de vLLM y frontend, más verificación explícita de
   los endpoints `/health` del backend, `/health` de vLLM y la raíz del frontend).

## Resultado
| Medición | Valor |
|---|---|
| Tiempo total hasta pila operativa | **126 s (2 min 6 s)** |
| Umbral de la métrica | 300 s (5 min) |
| Margen | 58 % |

Condición de contorno: los pesos del modelo (Qwen3-14B-AWQ, ~10 GB) ya residen
en el volumen de Hugging Face; la primera instalación absoluta añade su descarga,
dependiente del ancho de banda y por ello excluida de la métrica de despliegue.
El componente dominante del tiempo medido es la carga del modelo en la GPU por
parte del motor de inferencia.
