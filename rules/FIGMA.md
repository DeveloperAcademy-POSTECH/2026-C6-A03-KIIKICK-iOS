# FIGMA rules

This is not a design guide. These are rules for turning Figma UI into code **without filling gaps in the design file with guesses**.

## Principles

- Figma is the single source of truth. Do not modify the design or add elements.
- Do not eyeball screenshots. Read each node's layout properties through the Figma MCP.
- Do not fill in values that are not specified. Report them as Gaps.
- Do not approximate the design with absolute positioning (`.position()`, `.offset()`) or hard-coded raw values.
- Read Fonts / Color and Components from the following library references. See [DESIGN.md](DESIGN.md) for verification status; legacy mappings must not be treated as verified KIIKICK tokens.

[Design System for Color, Fonts](https://www.figma.com/design/Oc5LQED0S2UeVfXvdAjNwO/%E2%9A%BD%EF%B8%8F-KIIKICK-%EB%94%94%EC%9E%90%EC%9D%B8-%EB%9D%BC%EC%9D%B4%EB%B8%8C%EB%9F%AC%EB%A6%AC?node-id=1-239&t=vl5yYnI25mUIBsBJ-1)

[KIIKICK Components](https://www.figma.com/design/Oc5LQED0S2UeVfXvdAjNwO/?node-id=1-440)

## Pre-Implementation Check

- [ ] Does every frame use **Auto Layout**? (Plain Groups and absolute positioning are Gaps.)
- [ ] Are **sizing** (Fixed / Hug / Fill), **spacing**, **padding**, and **alignment** specified?
- [ ] Are colors and text defined with **Variables / Styles**? (Raw hex values and one-off font settings are Gaps.)
- [ ] Are the required **states** (empty, loading, error, disabled) and **long-text** behavior defined?

## Handling Gaps


| Level         | Criteria                                        | Action                                                              |
| ------------- | ----------------------------------------------- | ------------------------------------------------------------------- |
| 🔴 Blocker    | Layout structure cannot be determined           | Stop implementing and ask                                           |
| 🟡 Assumption | Can be reasonably inferred but is not specified | State the assumption, implement, and add a `// DESIGN-GAP:` comment |


When finished, always report in the format below. If there are none, write "Design Gaps: None".



```markdown
## Design Gaps — [Screen Name]
- 🔴 [Node Name] Placed in a Group without Auto Layout → cannot determine spacing or resizing behavior
- 🟡 [Node Name] Color is a raw hex (#3A3A3A) → assumed Color.textSecondary
```