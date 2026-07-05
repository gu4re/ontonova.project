import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import { SUPPORTED_LANGUAGES, type SupportedLanguage } from "../i18n";
import { localizedLanguageNames } from "../utils/languageNames";
import { DropdownContent, DropdownItem, DropdownMenu, DropdownTrigger } from "./ui/DropdownMenu";
import { FlagIcon } from "./ui/FlagIcon";

export function LanguageSwitcher() {
  const { t, i18n } = useTranslation();
  const current = (SUPPORTED_LANGUAGES as readonly string[]).includes(i18n.language)
    ? (i18n.language as SupportedLanguage)
    : "en";
  const names = useMemo(() => {
    const labels = localizedLanguageNames(SUPPORTED_LANGUAGES, i18n.language);
    return Object.fromEntries(SUPPORTED_LANGUAGES.map((code, index) => [code, labels[index]])) as Record<
      SupportedLanguage,
      string
    >;
  }, [i18n.language]);

  return (
    <DropdownMenu>
      <DropdownTrigger aria-label={t("language.interfaceLabel")}>
        <FlagIcon code={current} />
        {names[current]}
      </DropdownTrigger>
      <DropdownContent>
        {SUPPORTED_LANGUAGES.map((code) => (
          <DropdownItem key={code} onSelect={() => void i18n.changeLanguage(code)}>
            <FlagIcon code={code} />
            {names[code]}
          </DropdownItem>
        ))}
      </DropdownContent>
    </DropdownMenu>
  );
}
