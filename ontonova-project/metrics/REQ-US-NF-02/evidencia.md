# REQ-US-NF-02 — Rendimiento de la aplicación web

**Métrica:** carga inicial ≤3 s; respuesta a la interacción <200 ms.
**Método (ISO/IEC/IEEE 29148):** Prueba (Lighthouse + medición instrumentada).

## Carga inicial — Lighthouse 12 (2026-08-23, build de producción servido por Nginx)
| Configuración | Puntuación | FCP | LCP | Interactivo | TBT | CLS |
|---|---|---|---|---|---|---|
| Escritorio (representativa del despliegue local) | 0,98 | 0,9 s | 0,9 s | 0,9 s | 0 ms | 0 |
| Móvil simulado (slow 4G + CPU×4, contexto) | 0,68 | 5,0 s | 5,1 s | 5,2 s | 20 ms | 0,001 |

La configuración de escritorio es la representativa: OntoNova se despliega en el
propio equipo del usuario (localhost, @sec:deploymentdesign), sin red móvil de
por medio. Resultado: 0,9 s ≤ 3 s ✓. El perfil móvil se conserva como contexto
y señala el peso del bundle (pdf.js) como margen de optimización.

## Interacción — medición instrumentada (Playwright, navegador real, 10 rondas)
| Operación | Mediana | p95 | Máximo |
|---|---|---|---|
| Crear clase | 52 ms | 62 ms | 62 ms |
| Seleccionar clase (inspector) | 25 ms | 29 ms | 29 ms |
| Eliminar clase | 35 ms | 49 ms | 49 ms |

Todas las operaciones quedan por debajo de 200 ms incluso en el máximo, y las
cifras incluyen el sobrecoste del protocolo de automatización (cota superior).

## Ficheros
- `lighthouse-desktop.json`, `lighthouse.json` (móvil) — informes íntegros.
- `lighthouse-desktop.html` + `lighthouse-desktop.png` — informe navegable y captura
  (puntuación 98, FCP/LCP/SI 0,9 s, TBT 0 ms, CLS 0, con miniatura de la aplicación).
- `interaccion.mjs` + `interaccion-resultado.txt` — script reproducible y salida.
