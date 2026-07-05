# REQ-US-FC-03 — Validación y ciclo de autocorrección

**Métrica:** el grafo entregado supera la validación sintáctica del contrato; ante un fallo, el sistema ejecuta un ciclo de corrección antes de rendirse (degradación elegante).
**Método (ISO/IEC/IEEE 29148):** Prueba.

## Evidencia en tres niveles
1. **Unitarias del validador (13, pytest):** estructura, referencias cruzadas y
   conformidad dominio/rango de cada aserción (subclase-consciente).
2. **Servicio de la cadena completa (20, pytest):** con inferencia simulada se
   prueban el camino feliz, la autocorrección tras error de validación, el
   enrutado del reintento a la etapa culpable, las reparaciones sin pérdidas
   (deduplicación de identificadores, remapeo difuso, aserciones invertidas),
   la poda de último recurso y el fallo honesto cuando la malformación es
   estructural. Salida en `pytest-validador-pipeline.txt` (33/33).
3. **Aceptación contra la pila real (scrum-3):** el texto universitario alcanza
   macro F1 1,00 con 1 reintento de autocorrección observado — el ciclo no solo
   evita el fallo, recupera la puntuación perfecta. Informe completo en
   `graph-quality-report.json` (precisión/exhaustividad/F1 por categoría).

## Resultado
| Nivel | Pruebas | Resultado |
|---|---|---|
| Validador (unitarias) | 13 | 13/13 ✓ |
| Cadena multi-agente (servicio) | 20 | 20/20 ✓ |
| Patrón oro (aceptación, pila real) | 1 | macro F1 1,00 con autocorrección ✓ |
