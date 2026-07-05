import { render as rtlRender, type RenderOptions } from "@testing-library/react";
import type { ReactElement } from "react";
import { TooltipProvider } from "../components/ui/Tooltip";

/** Wraps every render in TooltipProvider — several components use Tooltip and Radix throws without it. */
export function render(ui: ReactElement, options?: RenderOptions) {
  return rtlRender(<TooltipProvider>{ui}</TooltipProvider>, options);
}

export * from "@testing-library/react";
