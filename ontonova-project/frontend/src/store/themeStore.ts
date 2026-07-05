import { create } from "zustand";

export type Theme = "dark" | "light";

const STORAGE_KEY = "ontonova-theme";

function initialTheme(): Theme {
  const stored = window.localStorage.getItem(STORAGE_KEY);
  if (stored === "dark" || stored === "light") return stored;
  // Default to light regardless of OS preference; the user can still
  // switch to dark via the toggle, which persists to localStorage above.
  return "light";
}

function applyTheme(theme: Theme) {
  document.documentElement.classList.toggle("light", theme === "light");
  document.documentElement.classList.toggle("dark", theme === "dark");
  window.localStorage.setItem(STORAGE_KEY, theme);
}

// Applied synchronously at module load — imported early in main.tsx, before
// the first render — so there's no flash of the wrong theme.
const initial = initialTheme();
applyTheme(initial);

interface ThemeState {
  theme: Theme;
  toggleTheme: () => void;
}

export const useThemeStore = create<ThemeState>((set, get) => ({
  theme: initial,
  toggleTheme: () => {
    const next: Theme = get().theme === "dark" ? "light" : "dark";
    applyTheme(next);
    set({ theme: next });
  },
}));
