import { describe, expect, it } from "vitest";
import { slugify, uniqueId } from "./slug";

describe("slugify", () => {
  it("converts a plain name to PascalCase", () => {
    expect(slugify("teacher")).toBe("Teacher");
  });

  it("strips separators and capitalizes each word", () => {
    expect(slugify("has spouse")).toBe("HasSpouse");
    expect(slugify("date-of-birth")).toBe("DateOfBirth");
  });

  it("applies a prefix", () => {
    expect(slugify("Person", "Class_")).toBe("Class_Person");
  });

  it("falls back to a placeholder for empty input", () => {
    expect(slugify("   ")).toBe("Unnamed");
  });

  it("lower-cases the leading letter when capitalizeFirst is false", () => {
    expect(slugify("age", "attr_", { capitalizeFirst: false })).toBe("attr_age");
    expect(slugify("date of birth", "attr_", { capitalizeFirst: false })).toBe("attr_dateOfBirth");
  });
});

describe("uniqueId", () => {
  it("returns the base id when there is no collision", () => {
    expect(uniqueId([], "Class_Person")).toBe("Class_Person");
    expect(uniqueId(["Class_Other"], "Class_Person")).toBe("Class_Person");
  });

  it("appends an incrementing numeric suffix on collision", () => {
    expect(uniqueId(["Class_Person"], "Class_Person")).toBe("Class_Person2");
    expect(uniqueId(["Class_Person", "Class_Person2"], "Class_Person")).toBe("Class_Person3");
  });
});
