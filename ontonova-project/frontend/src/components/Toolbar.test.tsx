import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";
import * as apiClient from "../api/client";
import { useOntologyStore } from "../store/ontologyStore";
import { render, screen } from "../test/render";
import { Toolbar } from "./Toolbar";

beforeEach(() => {
  useOntologyStore.getState().reset();
});

describe("Toolbar", () => {
  it("adds a class from the new-class form", async () => {
    const user = userEvent.setup();
    render(<Toolbar />);

    await user.type(screen.getByPlaceholderText("New class name…"), "Teacher");
    await user.click(screen.getByRole("button", { name: "Add class" }));

    expect(useOntologyStore.getState().classes).toEqual([
      { id: "Class_Teacher", name: "Teacher", subClassOf: null },
    ]);
  });

  it("disables export and reset while the ontology is empty", () => {
    render(<Toolbar />);
    expect(screen.getByRole("button", { name: "Export" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Reset" })).toBeDisabled();
  });

  it("only discards the ontology after confirming in the dialog", async () => {
    useOntologyStore.getState().addClass({ id: "Class_Teacher", name: "Teacher" });
    const user = userEvent.setup();
    render(<Toolbar />);

    await user.click(screen.getByRole("button", { name: "Reset" }));
    await user.click(await screen.findByRole("button", { name: "Cancel" }));
    expect(useOntologyStore.getState().classes).toHaveLength(1);

    await user.click(screen.getByRole("button", { name: "Reset" }));
    await user.click(await screen.findByRole("button", { name: "Discard" }));
    expect(useOntologyStore.getState().classes).toHaveLength(0);
  });

  it("shows an error message when export fails", async () => {
    useOntologyStore.getState().addClass({ id: "Class_Teacher", name: "Teacher" });
    vi.spyOn(apiClient, "exportOntology").mockRejectedValue(new Error("export exploded"));

    const user = userEvent.setup();
    render(<Toolbar />);
    await user.click(screen.getByRole("button", { name: "Export" }));
    await user.click(await screen.findByRole("menuitem", { name: "Turtle" }));

    expect(await screen.findByText("export exploded")).toBeInTheDocument();
  });
});
