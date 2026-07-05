# REQ-US-FC-04 — Edición del lienzo en pocas interacciones

**Métrica:** cada operación de edición del lienzo se completa en ≤3 interacciones.
**Método (ISO/IEC/IEEE 29148):** Demostración.

## Recuento de interacciones por operación
| Operación | Secuencia | Interacciones |
|---|---|---|
| Crear clase | Escribir nombre + botón "Add class" | 2 |
| Seleccionar/inspeccionar clase | Clic sobre el nodo | 1 |
| Editar atributos de la clase | Clic en el nodo + edición en el inspector | 2 |
| Eliminar clase | Botón de papelera del nodo | 1 |
| Crear relación | Arrastre de manejador a manejador | 1 |
| Renombrar relación | Doble clic + escribir + Intro | 3 |
| Reconectar relación (cambiar origen/destino) | Arrastre del extremo de la arista | 1 |
| Recolocar etiqueta de relación | Arrastre de la etiqueta | 1 |
| Eliminar relación | Botón ✕ de la etiqueta | 1 |
| Exportar | Botón "Export" + elección de formato | 2 |
| Reiniciar lienzo | Botón "Reset" + confirmación | 2 |

Máximo observado: 3 (renombrado de relación). Todas las operaciones cumplen la métrica.

## Soporte ejecutable
Cada fila está cubierta por una prueba e2e de Playwright sobre navegador real
(`canvas.spec.ts`, 8/8 en verde — salida en
`../REQ-US-FC-10/e2e-create-canvas.txt`), de modo que la demostración es
reproducible: la propia prueba realiza exactamente las interacciones contadas.
Adicionalmente, cada mutación revalida el estado contra el servicio de
orquestación (cobertura vitest del almacén, 9 pruebas).
