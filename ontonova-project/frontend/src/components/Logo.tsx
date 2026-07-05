import { useId } from "react";

interface LogoProps {
  /** "mark" renders just the graph icon; "full" adds the "OntoNova" wordmark. */
  variant?: "mark" | "full";
  className?: string;
}

/**
 * Hand-drawn mark: a hub-and-spoke knowledge graph (four outer nodes forming
 * an "O" silhouette, wired to a central hollow node) in the brand's
 * violet→cyan gradient — no image-generation tool was available, so this is
 * authored directly as SVG rather than a raster asset.
 */
export function Logo({ variant = "full", className = "" }: LogoProps) {
  const gradientId = useId();

  const mark = (
    <svg
      viewBox="0 0 40 40"
      role="img"
      aria-label="OntoNova"
      className={variant === "mark" ? className : "h-8 w-8 shrink-0"}
    >
      <defs>
        <linearGradient id={gradientId} x1="0" y1="0" x2="40" y2="40" gradientUnits="userSpaceOnUse">
          <stop offset="0" stopColor="#8b5cf6" />
          <stop offset="1" stopColor="#22d3ee" />
        </linearGradient>
      </defs>
      <g stroke={`url(#${gradientId})`} strokeWidth="1.6" strokeLinecap="round" fill="none" opacity="0.85">
        <line x1="20" y1="20" x2="20" y2="7" />
        <line x1="20" y1="20" x2="33" y2="20" />
        <line x1="20" y1="20" x2="20" y2="33" />
        <line x1="20" y1="20" x2="7" y2="20" />
        <line x1="20" y1="7" x2="33" y2="20" />
        <line x1="33" y1="20" x2="20" y2="33" />
        <line x1="20" y1="33" x2="7" y2="20" />
        <line x1="7" y1="20" x2="20" y2="7" />
      </g>
      <circle cx="20" cy="7" r="3.4" fill={`url(#${gradientId})`} />
      <circle cx="33" cy="20" r="3.4" fill={`url(#${gradientId})`} />
      <circle cx="20" cy="33" r="3.4" fill={`url(#${gradientId})`} />
      <circle cx="7" cy="20" r="3.4" fill={`url(#${gradientId})`} />
      <circle cx="20" cy="20" r="4.2" fill="var(--color-bg)" stroke={`url(#${gradientId})`} strokeWidth="1.8" />
    </svg>
  );

  if (variant === "mark") return mark;

  return (
    <span className={`inline-flex items-center gap-2.5 ${className}`}>
      {mark}
      <span className="bg-linear-to-r from-accent-from to-accent-to bg-clip-text text-xl font-semibold tracking-tight text-transparent">
        OntoNova
      </span>
    </span>
  );
}
