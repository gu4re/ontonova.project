// REQ-US-FC-02: latencia extremo a extremo por etapa — desde que el frame SSE
// llega al navegador hasta que el stepper pinta la etapa como completada
// (clase text-success). El transporte backend→navegador es localhost y se
// evidencia aparte (medir-eventos.py); aquí se cierra el tramo restante.
// Ejecutar: node metrics/REQ-US-FC-02/latencia-ui.mjs  (pila completa arriba)
import { createRequire } from "node:module";
const require = createRequire("/home/ubu/tfm/ontonova-project/frontend/package.json");
const { chromium } = require("playwright");

const URL = process.env.E2E_BASE_URL ?? "http://localhost:5173";
const TEXT =
  "At Cambridge University, which was founded in 1209, the Department of " +
  "Computer Science offers several courses. Professors and students are " +
  "both persons affiliated with the university. Professor Alan Turing, " +
  "who is 41 years old, works for the Department of Computer Science and " +
  "teaches the course Computability Theory, which is worth 6 credits. The " +
  "student Ada Lovelace is enrolled in Computability Theory.";

const browser = await chromium.launch();
const page = await browser.newPage();

await page.addInitScript(() => {
  window.__sseChunks = [];
  window.__paints = [];
  const origFetch = window.fetch.bind(window);
  window.fetch = async (...args) => {
    const url = String(args[0]?.url ?? args[0]);
    const res = await origFetch(...args);
    if (!url.includes("/generate") || !res.body) return res;
    const [app, tap] = res.body.tee();
    (async () => {
      const reader = tap.getReader();
      const decoder = new TextDecoder();
      for (;;) {
        const { done, value } = await reader.read();
        if (done) break;
        window.__sseChunks.push({ t: performance.now(), text: decoder.decode(value, { stream: true }) });
      }
    })();
    return new Response(app, { status: res.status, headers: res.headers });
  };
  // Sondeo a alta frecuencia del stepper: primer instante en que cada <li>
  // luce text-success. Resolución ±8 ms, suficiente para una cota de 1 s.
  window.__liSeen = 0;
  const seen = new Set();
  setInterval(() => {
    const t = performance.now();
    const items = document.querySelectorAll("ol li");
    window.__liSeen = Math.max(window.__liSeen, items.length);
    items.forEach((li, i) => {
      if (String(li.className).includes("text-success") && !seen.has(i)) {
        seen.add(i);
        window.__paints.push({ t, label: li.textContent.trim() });
      }
    });
  }, 8);
});

await page.goto(URL);
await page.getByLabel("Describe the domain").fill(TEXT);
await page.getByRole("button", { name: "Generate ontology" }).click();
await page.waitForFunction(
  () => window.__sseChunks.some((c) => c.text.includes('"done"')),
  null,
  { timeout: 600000 },
);
await page.waitForTimeout(500); // margen para el último repintado

const { chunks, paints, liSeen } = await page.evaluate(() => ({
  chunks: window.__sseChunks,
  paints: window.__paints,
  liSeen: window.__liSeen,
}));
await browser.close();

// Reconstruye los eventos SSE con el instante de llegada de su chunk.
const events = [];
let buffer = "";
for (const { t, text } of chunks) {
  buffer += text;
  const frames = buffer.split("\n\n");
  buffer = frames.pop();
  for (const frame of frames) {
    const line = frame.trim();
    if (!line.startsWith("data:")) continue;
    const event = JSON.parse(line.slice(5));
    events.push({ t, stage: event.stage, status: event.status });
  }
}

const completions = events.filter((e) => e.status === "completed" || e.status === "success");
console.log("etapa           llegada-frame   pintado-UI   latencia");
completions.forEach((event, i) => {
  const paint = paints[i];
  if (!paint) return;
  const latency = (paint.t - event.t).toFixed(1);
  console.log(
    `${event.stage.padEnd(14)} ${event.t.toFixed(0).padStart(10)} ms ${paint.t.toFixed(0).padStart(9)} ms ${latency.padStart(8)} ms  (${paint.label})`,
  );
});
if (!paints.length) {
  console.log("sin repintados observados — diagnóstico:");
  console.log("eventos:", JSON.stringify(events.map((e) => [e.stage, e.status])));
  console.log("máximo de <li> visibles durante el sondeo:", liSeen);
}
