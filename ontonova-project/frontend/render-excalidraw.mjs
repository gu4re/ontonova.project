// Headless Excalidraw scene -> PNG renderer (thesis figure pipeline).
// Usage: node render-excalidraw.mjs <scene.excalidraw> <out.png> [scale]
// Must run from ontonova-project/frontend so playwright resolves.
import { readFileSync, writeFileSync } from "node:fs";
import { chromium } from "playwright";

const [scenePath, outPath, scaleArg] = process.argv.slice(2);
const scale = Number(scaleArg ?? 2);
const scene = JSON.parse(readFileSync(scenePath, "utf8"));

const browser = await chromium.launch();
const page = await browser.newPage();
await page.setContent("<!doctype html><html><body></body></html>");

const dataUrl = await page.evaluate(
  async ({ scene, scale }) => {
    window.EXCALIDRAW_ASSET_PATH = "https://esm.sh/@excalidraw/excalidraw@0.17.6/dist/";
    const M = await import("https://esm.sh/@excalidraw/excalidraw@0.17.6");
    const X = M.default ?? M;
    const doExport = () =>
      X.exportToBlob({
        elements: scene.elements,
        appState: {
          ...scene.appState,
          exportBackground: true,
          viewBackgroundColor: "#ffffff",
          exportWithDarkMode: false,
        },
        files: scene.files ?? {},
        mimeType: "image/png",
        getDimensions: (w, h) => ({ width: w * scale, height: h * scale, scale }),
      });
    await doExport(); // warmup: triggers Virgil font fetch
    await document.fonts.ready;
    const blob = await doExport();
    return await new Promise((resolve, reject) => {
      const r = new FileReader();
      r.onload = () => resolve(r.result);
      r.onerror = reject;
      r.readAsDataURL(blob);
    });
  },
  { scene, scale },
);

writeFileSync(outPath, Buffer.from(dataUrl.split(",")[1], "base64"));
await browser.close();
console.log("rendered", outPath);
