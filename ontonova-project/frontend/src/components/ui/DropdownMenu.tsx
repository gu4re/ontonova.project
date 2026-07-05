import * as DropdownMenuPrimitive from "@radix-ui/react-dropdown-menu";
import { ChevronDown } from "lucide-react";
import type { ReactNode } from "react";

// Shared floating-card look for every dropdown menu in the app (export
// format, language pickers, …) so they all read as one consistent control
// instead of a mix of native <select>/<datalist> and custom menus.

export const DropdownMenu = DropdownMenuPrimitive.Root;

interface DropdownTriggerProps {
  children: ReactNode;
  disabled?: boolean;
  "aria-label"?: string;
  /** Text+chevron pill (default, e.g. "Export ▾") vs a square icon-only button. */
  variant?: "pill" | "icon";
}

export function DropdownTrigger({
  children,
  disabled,
  variant = "pill",
  "aria-label": ariaLabel,
}: DropdownTriggerProps) {
  return (
    <DropdownMenuPrimitive.Trigger asChild disabled={disabled}>
      <button
        type="button"
        disabled={disabled}
        aria-label={ariaLabel}
        className={
          variant === "icon"
            ? "flex h-8 w-8 shrink-0 items-center justify-center rounded-lg border border-border bg-surface-raised text-text-muted transition hover:border-accent hover:text-accent disabled:pointer-events-none disabled:opacity-40"
            : "flex items-center gap-1.5 rounded-lg border border-border bg-surface-raised px-3 py-1.5 text-sm text-text-muted transition hover:border-accent hover:text-accent disabled:pointer-events-none disabled:opacity-40"
        }
      >
        {children}
        <ChevronDown className={variant === "icon" ? "h-3.5 w-3.5" : "h-3.5 w-3.5 shrink-0"} />
      </button>
    </DropdownMenuPrimitive.Trigger>
  );
}

export function DropdownContent({
  children,
  align = "end",
}: {
  children: ReactNode;
  align?: "start" | "end";
}) {
  return (
    <DropdownMenuPrimitive.Portal>
      <DropdownMenuPrimitive.Content
        sideOffset={6}
        align={align}
        className="z-50 max-h-64 min-w-40 overflow-y-auto rounded-lg border border-border bg-surface-raised p-1 shadow-2xl"
      >
        {children}
      </DropdownMenuPrimitive.Content>
    </DropdownMenuPrimitive.Portal>
  );
}

export function DropdownItem({
  children,
  onSelect,
}: {
  children: ReactNode;
  onSelect: () => void;
}) {
  return (
    <DropdownMenuPrimitive.Item
      onSelect={onSelect}
      className="flex cursor-pointer items-center gap-2 rounded-md px-2.5 py-1.5 text-sm text-text outline-none data-[highlighted]:bg-accent-soft data-[highlighted]:text-accent"
    >
      {children}
    </DropdownMenuPrimitive.Item>
  );
}
