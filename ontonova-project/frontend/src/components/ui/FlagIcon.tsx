import { LANGUAGE_FLAGS } from "../../utils/languageFlags";

export function FlagIcon({ code }: { code: string }) {
  const src = LANGUAGE_FLAGS[code];
  if (!src) return null;
  return <img src={src} alt="" aria-hidden="true" className="h-4 w-4 shrink-0 rounded-[3px] object-cover" />;
}
