import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it } from "vitest";
import i18n from "../i18n";
import { render, screen } from "../test/render";
import { LanguageSwitcher } from "./LanguageSwitcher";

afterEach(async () => {
  await i18n.changeLanguage("en");
});

describe("LanguageSwitcher", () => {
  it("shows the current interface language on the trigger", () => {
    render(<LanguageSwitcher />);
    expect(screen.getByRole("button", { name: /Interface language/i })).toHaveTextContent("English");
  });

  it("switches the interface language when a menu item is selected", async () => {
    const user = userEvent.setup();
    render(<LanguageSwitcher />);

    await user.click(screen.getByRole("button", { name: /Interface language/i }));
    // Menu items are localized to the current UI language (English here),
    // so Spanish reads "Spanish" rather than the endonym "Español".
    await user.click(await screen.findByRole("menuitem", { name: "Spanish" }));

    expect(i18n.language).toBe("es");
  });

  it("re-localizes the trigger and menu items once the interface language changes", async () => {
    const user = userEvent.setup();
    render(<LanguageSwitcher />);

    await user.click(screen.getByRole("button", { name: /Interface language/i }));
    await user.click(await screen.findByRole("menuitem", { name: "Spanish" }));

    expect(screen.getByRole("button", { name: /Idioma de la interfaz/i })).toHaveTextContent("Español");
    await user.click(screen.getByRole("button", { name: /Idioma de la interfaz/i }));
    expect(await screen.findByRole("menuitem", { name: "Inglés" })).toBeInTheDocument();
  });
});
