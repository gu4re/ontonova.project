# REQ-US-FC-05 — Exportación a formatos estándar W3C

**Métrica:** la exportación supera un validador RDF sin errores.
**Método (ISO/IEC/IEEE 29148):** Prueba.

## Procedimiento
1. Se exportan dos ontologías reales a través del endpoint `/api/ontologies/export`
   en los dos formatos soportados (Turtle y RDF/XML): la ontología del patrón
   oro universitario (scrum-3) y una generación real del texto denso nexolabs
   (scrum-6, run 02).
2. Cada fichero exportado se analiza con `rdflib` 7, cuyo analizador implementa
   las especificaciones RDF 1.1 del W3C; cualquier error sintáctico aborta el
   análisis.

## Resultado (2026-08-23)
| Ontología | Formato | Tamaño | Tripletas | Errores |
|---|---|---|---|---|
| universidad (scrum-3) | Turtle | 3.716 B | 103 | 0 |
| universidad (scrum-3) | RDF/XML | 9.748 B | 103 | 0 |
| nexolabs (scrum-6) | Turtle | 8.449 B | 213 | 0 |
| nexolabs (scrum-6) | RDF/XML | 21.272 B | 213 | 0 |

El recuento de tripletas coincide entre ambos formatos de cada ontología,
evidenciando que la serialización es consistente además de válida. Cobertura
adicional: 3 pruebas unitarias del compilador RDF (pytest) y la prueba e2e de
descarga de Turtle (Playwright).

## Validación con el servicio oficial del W3C (2026-08-24)
Ambos ficheros RDF/XML superan el **W3C RDF Validation Service**
(https://www.w3.org/RDF/Validator/) con el veredicto literal
"Your RDF document validated successfully.":
- `universidad.rdf` ✓
- `nexolabs.rdf` ✓

Nota de alcance: ese servicio solo acepta RDF/XML (es anterior a la
estandarización de Turtle y no existe validador oficial del W3C en línea para
ese formato); la validez de los `.ttl` queda cubierta por el analizador
conforme a RDF 1.1 más la coincidencia exacta de tripletas con su gemelo
RDF/XML ya validado por el W3C. Ojo: https://validator.w3.org (sin ruta) es el
validador de HTML y rechaza o malinterpreta estos ficheros.

## Ficheros
- `universidad.ttl`, `universidad.rdf`, `nexolabs.ttl`, `nexolabs.rdf` — exportaciones.
- `validacion.txt` — salida del análisis rdflib.
