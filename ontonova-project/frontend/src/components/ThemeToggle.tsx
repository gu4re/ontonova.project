import { Moon, Sun } from "lucide-react";
import { useTranslation } from "react-i18next";
import { useThemeStore } from "../store/themeStore";
import { Tooltip } from "./ui/Tooltip";

export function ThemeToggle() {
  const { t } = useTranslation();
  const theme = useThemeStore((state) => state.theme);
  const toggleTheme = useThemeStore((state) => state.toggleTheme);
  const label = theme === "dark" ? t("theme.switchToLight") : t("theme.switchToDark");

  return (
    <Tooltip label={label}>
      <button
        type="button"
        aria-label={label}
        onClick={toggleTheme}
        className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-border bg-surface-raised text-text-muted transition hover:border-accent hover:text-accent"
      >
        {theme === "dark" ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
      </button>
    </Tooltip>
  );
}
