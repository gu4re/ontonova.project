import i18next from "i18next";
import { initReactI18next } from "react-i18next";
import de from "./locales/de.json";
import en from "./locales/en.json";
import fr from "./locales/fr.json";
import es from "./locales/es.json";

export const SUPPORTED_LANGUAGES = ["en", "es", "fr", "de"] as const;
export type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number];

const STORAGE_KEY = "ontonova-language";

function initialLanguage(): SupportedLanguage {
  const stored = typeof window !== "undefined" ? window.localStorage.getItem(STORAGE_KEY) : null;
  return (SUPPORTED_LANGUAGES as readonly string[]).includes(stored ?? "")
    ? (stored as SupportedLanguage)
    : "en";
}

// Resources are bundled at build time (no HTTP backend), so init can run
// synchronously before the first render — no i18next-http-backend/Suspense
// dance needed for a UI this size.
void i18next.use(initReactI18next).init({
  resources: {
    en: { translation: en },
    es: { translation: es },
    fr: { translation: fr },
    de: { translation: de },
  },
  lng: initialLanguage(),
  fallbackLng: "en",
  interpolation: { escapeValue: false },
});

i18next.on("languageChanged", (language) => {
  window.localStorage.setItem(STORAGE_KEY, language);
});

export default i18next;
