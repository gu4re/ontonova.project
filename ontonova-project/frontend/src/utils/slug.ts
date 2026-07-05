/**
 * Turns a free-text name into an identifier matching the
 * `^[A-Za-z0-9_]+$` convention enforced server-side (see prompts/GUIDANCE.md
 * and core/models.py). Classes use `ID_CamelCase` (capitalized first
 * letter); attr_/prop_/inst_-prefixed ids use `camelCase` after the prefix
 * — pass `capitalizeFirst: false` for those.
 */
export function slugify(label: string, prefix = "", options: { capitalizeFirst?: boolean } = {}): string {
  const { capitalizeFirst = true } = options;
  const cleaned = label
    .trim()
    .replace(/[^A-Za-z0-9]+(.)/g, (_, chr: string) => chr.toUpperCase())
    .replace(/[^A-Za-z0-9]/g, "");

  if (!cleaned) return `${prefix}Unnamed`;

  const cased = capitalizeFirst
    ? cleaned[0].toUpperCase() + cleaned.slice(1)
    : cleaned[0].toLowerCase() + cleaned.slice(1);
  return `${prefix}${cased}`;
}

/** Appends a numeric suffix until `base` no longer collides with `existingIds`. */
export function uniqueId(existingIds: string[], base: string): string {
  if (!existingIds.includes(base)) return base;
  let suffix = 2;
  while (existingIds.includes(`${base}${suffix}`)) suffix += 1;
  return `${base}${suffix}`;
}
