# REQ-SW-NF-02 — Seguridad de dependencias

**Métrica:** 0 vulnerabilidades de severidad alta en las dependencias.
**Método (ISO/IEC/IEEE 29148):** Análisis, mediante herramientas de análisis estático de dependencias.

## Procedimiento
1. Backend: `pip-audit -r api/requirements.txt` sobre el entorno del servicio de orquestación.
2. Frontend: `npm audit` sobre el árbol de dependencias de la aplicación web (ejecutado en contenedor `node:22-slim`).

## Resultado (2026-08-23)
| Ecosistema | Herramienta | Vulnerabilidades altas | Resultado |
|---|---|---|---|
| Python (backend) | pip-audit | 0 | `No known vulnerabilities found` |
| npm (frontend) | npm audit | 0 | `found 0 vulnerabilities` |

## Nota de proceso
La auditoría del 2026-08-23 detectó inicialmente 2 avisos altos en dependencias
transitivas publicados con posterioridad a la auditoría anterior (nanoid
GHSA-2v37-7h3g-55p8; undici GHSA-8xcm-r25x-g524 y relacionados). Se corrigieron
con `npm audit fix` (actualización no disruptiva del lockfile) y se verificó la
no regresión: vitest 53/53 y `tsc --noEmit` limpio. Este ciclo
detección→corrección→re-verificación es el comportamiento esperado del método
de análisis: la evidencia no es solo el cero final, sino que la herramienta
detecta y el proceso corrige.

## Ficheros
- `pip-audit.txt` — salida íntegra fechada.
- `npm-audit.txt` — salida íntegra fechada (tras la corrección).
