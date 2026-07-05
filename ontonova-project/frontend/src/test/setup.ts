import { cleanup } from "@testing-library/react";
import { afterEach } from "vitest";
import "@testing-library/jest-dom/vitest";
import "../i18n";

// Without vitest's `globals: true`, @testing-library/react can't
// auto-register its cleanup hook, so unmount rendered trees explicitly.
afterEach(() => {
  cleanup();
});

// jsdom doesn't implement ResizeObserver or pointer-capture, which Radix's
// Dialog/DropdownMenu/Tooltip primitives reference internally.
if (!window.ResizeObserver) {
  window.ResizeObserver = class ResizeObserver {
    observe() {}
    unobserve() {}
    disconnect() {}
  };
}

if (!Element.prototype.hasPointerCapture) {
  Element.prototype.hasPointerCapture = () => false;
}
if (!Element.prototype.setPointerCapture) {
  Element.prototype.setPointerCapture = () => {};
}
if (!Element.prototype.releasePointerCapture) {
  Element.prototype.releasePointerCapture = () => {};
}
if (!Element.prototype.scrollIntoView) {
  Element.prototype.scrollIntoView = () => {};
}
