"""
REQ-US-FC-02: los eventos de progreso llegan al cliente de forma incremental
(streaming real), no agrupados al final. Registra el instante de llegada de
cada frame SSE relativo al inicio de la petición.

Ejecutar (pila viva): PYTHONPATH=. ./api/bin/python ../metrics/REQ-US-FC-02/medir-eventos.py
"""
import json
import time

import httpx

TEXT = (
    "Los profesores imparten cursos. Los estudiantes se matriculan en cursos. "
    "El profesor Juan imparte el curso de Historia."
)

t0 = time.monotonic()
rows = []
with httpx.Client(timeout=900) as client:
    with client.stream(
        "POST", "http://localhost:8001/api/ontologies/generate",
        json={"text": TEXT, "language": ""},
    ) as response:
        response.raise_for_status()
        for line in response.iter_lines():
            line = line.strip()
            if line.startswith("data:"):
                event = json.loads(line[len("data:"):].strip())
                rows.append((round(time.monotonic() - t0, 2), event.get("stage"), event.get("status")))

total = rows[-1][0]
print(f"{'t (s)':>8}  {'etapa':<12} estado")
prev = 0.0
for t, stage, status in rows:
    print(f"{t:>8.2f}  {stage:<12} {status}   (+{t - prev:.2f}s desde el anterior)")
    prev = t
print(f"\nTotal: {total}s, {len(rows)} eventos. Primer evento a los {rows[0][0]}s "
      f"({round(100 * rows[0][0] / total)}% del total) — llegada incremental, no agrupada al final.")
