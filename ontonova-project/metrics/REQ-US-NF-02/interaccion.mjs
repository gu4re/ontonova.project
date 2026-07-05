// Mide la latencia de interacción del lienzo (REQ-US-NF-02: <200 ms).
// Ejecutar desde ontonova-project/frontend:
//   node ../metrics/REQ-US-NF-02/interaccion.mjs
import { createRequire } from "node:module";
const require = createRequire("/home/ubu/tfm/ontonova-project/frontend/package.json");
const { chromium } = require("playwright");

const URL = process.env.E2E_BASE_URL ?? "http://localhost:5173";
const ROUNDS = 100;
const results = { "crear clase": [], "seleccionar clase": [], "eliminar clase": [] };

const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(URL);

for (let i = 0; i < ROUNDS; i++) {
  const name = `Clase${i}`;
  await page.getByPlaceholder("New class name…").fill(name);
  let t0 = performance.now();
  await page.getByRole("button", { name: "Add class" }).click();
  await page.getByText(name, { exact: true }).waitFor();
  results["crear clase"].push(performance.now() - t0);

  // El nodo recién creado se anima (ajuste de viewport); sin esta espera el
  // cronómetro de selección absorbe la espera de estabilidad previa al clic
  // de Playwright, que no es latencia de la interfaz.
  await page.waitForTimeout(900);

  t0 = performance.now();
  await page.getByText(name, { exact: true }).click();
  await page.getByRole("heading", { name }).waitFor();
  results["seleccionar clase"].push(performance.now() - t0);

  t0 = performance.now();
  await page.getByRole("button", { name: `Delete class ${name}` }).click();
  await page.getByText(name, { exact: true }).waitFor({ state: "detached" });
  results["eliminar clase"].push(performance.now() - t0);
}
await browser.close();

const stats = (xs) => {
  const s = [...xs].sort((a, b) => a - b);
  const pct = (p) => Math.round(s[Math.min(s.length - 1, Math.ceil(s.length * p) - 1)]);
  return {
    media: Math.round(xs.reduce((a, b) => a + b, 0) / xs.length),
    min: Math.round(s[0]),
    mediana: pct(0.5),
    p95: pct(0.95),
    p99: pct(0.99),
    max: Math.round(s[s.length - 1]),
  };
};
console.log(`# Latencia de interacción (${ROUNDS} rondas, ms; incluye sobrecoste del protocolo de automatización)`);
console.log(`${"operación".padEnd(20)} media  mín  mediana  p95  p99  máx`);
for (const [op, xs] of Object.entries(results)) {
  const { media, min, mediana, p95, p99, max } = stats(xs);
  console.log(`${op.padEnd(20)} ${String(media).padStart(5)} ${String(min).padStart(4)} ${String(mediana).padStart(8)} ${String(p95).padStart(4)} ${String(p99).padStart(4)} ${String(max).padStart(4)}`);
}
