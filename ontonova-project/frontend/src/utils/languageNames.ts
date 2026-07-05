/**
 * Localizes language names via Intl.DisplayNames so labels read in the
 * current UI language (e.g. "French" vs "Francés" vs "Français") instead of
 * a fixed set of hardcoded endonyms. Some locales (e.g. es, fr) return
 * lowercase names — capitalized for visual consistency with the rest of the
 * UI, which title-cases labels regardless of locale.
 */
export function localizedLanguageNames(codes: readonly string[], uiLanguage: string): string[] {
  try {
    const displayNames = new Intl.DisplayNames([uiLanguage], { type: "language" });
    return codes.map((code) => {
      const name = displayNames.of(code) ?? code;
      return name.charAt(0).toLocaleUpperCase(uiLanguage) + name.slice(1);
    });
  } catch {
    return [...codes];
  }
}
