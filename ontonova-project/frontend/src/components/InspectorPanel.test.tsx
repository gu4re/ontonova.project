import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it } from "vitest";
import { useOntologyStore } from "../store/ontologyStore";
import { render, screen, within } from "../test/render";
import { InspectorPanel } from "./InspectorPanel";

beforeEach(() => {
  useOntologyStore.getState().reset();
});

describe("InspectorPanel", () => {
  it("shows a placeholder when no class is selected", () => {
    render(<InspectorPanel />);
    expect(screen.getByText(/select a class/i)).toBeInTheDocument();
  });

  it("lists and adds a data property for the selected class", async () => {
    useOntologyStore.getState().addClass({ id: "Class_Person", name: "Person" });
    useOntologyStore.getState().selectClass("Class_Person");

    const user = userEvent.setup();
    render(<InspectorPanel />);

    expect(screen.getByRole("heading", { name: "Person" })).toBeInTheDocument();
    expect(screen.getAllByText("None yet")).toHaveLength(2);

    const attributeInput = screen.getByPlaceholderText("Attribute name");
    const propertyForm = attributeInput.closest("form") as HTMLFormElement;
    await user.type(attributeInput, "age");
    await user.click(within(propertyForm).getByRole("button", { name: "Add" }));

    expect(useOntologyStore.getState().dataProperties).toEqual([
      { id: "attr_age", name: "age", domain: "Class_Person", range: "xsd:string" },
    ]);
  });

  it("adds an individual for the selected class", async () => {
    useOntologyStore.getState().addClass({ id: "Class_Person", name: "Person" });
    useOntologyStore.getState().selectClass("Class_Person");

    const user = userEvent.setup();
    render(<InspectorPanel />);

    const nameInput = screen.getByPlaceholderText("Individual name");
    const individualForm = nameInput.closest("form") as HTMLFormElement;
    await user.type(nameInput, "Juan");
    await user.click(within(individualForm).getByRole("button", { name: "Add" }));

    expect(useOntologyStore.getState().individuals).toEqual([
      {
        id: "inst_juan",
        name: "Juan",
        typeClass: "Class_Person",
        objectPropertyAssertions: {},
        dataPropertyAssertions: {},
      },
    ]);
  });
});
