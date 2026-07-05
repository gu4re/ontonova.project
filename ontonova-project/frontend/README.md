# OntoNova frontend

Vite + React + TypeScript SPA. See the [project README](../README.md) for
architecture, use cases, and how to run the full stack.

## Scripts

- `npm run dev` — start the dev server (`.env` → `VITE_API_BASE_URL`, see `.env.example`)
- `npm run build` — type-check (`tsc -b`) and produce a production build in `dist/`
- `npm run lint` — oxlint
- `npm test` — Vitest unit/component tests
- `npm run test:e2e` — Playwright end-to-end tests (needs the backend + `npm run dev` running)
