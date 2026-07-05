import cn from "flag-icons/flags/4x3/cn.svg";
import de from "flag-icons/flags/4x3/de.svg";
import es from "flag-icons/flags/4x3/es.svg";
import fr from "flag-icons/flags/4x3/fr.svg";
import gb from "flag-icons/flags/4x3/gb.svg";
import it from "flag-icons/flags/4x3/it.svg";
import jp from "flag-icons/flags/4x3/jp.svg";
import pt from "flag-icons/flags/4x3/pt.svg";
import sa from "flag-icons/flags/4x3/sa.svg";

// A language isn't a country, but a representative flag is the widely-used
// shorthand in language pickers. Keyed by ISO 639-1 language code, not the
// ISO 3166-1 country code the underlying SVG asset is named after.
export const LANGUAGE_FLAGS: Record<string, string> = {
  en: gb,
  es,
  fr,
  de,
  it,
  pt,
  zh: cn,
  ja: jp,
  ar: sa,
};
