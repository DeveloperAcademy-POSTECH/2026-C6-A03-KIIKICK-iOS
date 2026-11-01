# DESIGN.md — Design System

Records Figma design references and their implementation status. **Figma is the source of truth for values.** Only verified mappings may be used as implementation guidance.

Source: [Design System for Color, Fonts](https://www.figma.com/design/Oc5LQED0S2UeVfXvdAjNwO/%E2%9A%BD%EF%B8%8F-KIIKICK-%EB%94%94%EC%9E%90%EC%9D%B8-%EB%9D%BC%EC%9D%B4%EB%B8%8C%EB%9F%AC%EB%A6%AC?node-id=1-239&t=vl5yYnI25mUIBsBJ-1)

## Verification status

- Verified via Figma MCP (`get_metadata` + `get_screenshot`) on node `1:239` ("System" page → "Typography : variables" + "Color: Primitive" frames) and node `1:440` ("Assets&Components" page). Values below are read directly from the file, not inferred from screenshots or guessed.
- **No semantic color layer exists in the source file.** The "System" page contains only "Typography : variables" and "Color: Primitive" — there is no separate semantic/alias color page or frame. Code must either define its own semantic layer on top of the primitives below, or apply primitives directly; either choice should be called out as a 🟡 Gap when non-obvious.
- **None of the tokens or components below have a SwiftUI implementation in this repo yet**, except the raw font files (see Typography). This repository uses `KIIKICK/KIIKICK/`; there is no `Earthu/DesignSystem/` directory, no `.textStyle(_:)` API, and no `Color Set` other than `AccentColor` in `Assets.xcassets`. Treat every token as "value verified, code not yet written."
- Earlier verification attempts (Aside, plain web fetch, Figma desktop UI automation) had all failed — see git history. The Figma MCP tools (`get_metadata`, `get_screenshot`) succeeded where those did not. `get_variable_defs` still fails here ("nothing selected" — it needs a layer selected in the Figma desktop app), so primitive values were read from the rendered documentation table via `get_screenshot`, not from live Figma Variables.

## Rules

- Use verified design tokens when available. Never hard-code raw colors, font sizes, spacing, or radius once a code token exists for them.
- Reuse existing components before creating new ones.
- If a Figma value has no matching token, do not create one. Use the closest token and report it as a 🟡 Gap (see [FIGMA.md](FIGMA.md)).
- Do not add or modify tokens without approval.

## Typography — verified (Figma node `1:239`)

Two font families are used:

- **Pretendard** — all UI text styles (`head`, `title`, `label`, `body`, `caption`).
- **Kanit** — `display` styles only, used for large numeric/stat displays.

**Font files are bundled** in `KIIKICK/KIIKICK Global/Fonts/` (shared by both the iOS and watchOS targets) and registered via `UIAppFonts` in both `KIIKICK/KIIKICK/Info.plist` (iOS) and `KIIKICK/KIIKICK Watch App Watch App/Info.plist` (watchOS) — verified on both: `CTFontManagerRegisterFontsForURL` + `CTFontCreateWithName` resolves each PostScript name below without falling back to a system font, and both targets' built `.app` bundles contain the font files. Only the weights actually used by the table below are bundled — not the full family:

| PostScript name       | File                       |
| ---------------------- | --------------------------- |
| `Pretendard-Regular`   | `KIIKICK Global/Fonts/Pretendard-Regular.otf` |
| `Pretendard-Medium`    | `KIIKICK Global/Fonts/Pretendard-Medium.otf`  |
| `Pretendard-SemiBold`  | `KIIKICK Global/Fonts/Pretendard-SemiBold.otf`|
| `Pretendard-Bold`      | `KIIKICK Global/Fonts/Pretendard-Bold.otf`    |
| `Kanit-SemiBold`       | `KIIKICK Global/Fonts/Kanit-SemiBold.ttf`     |

No `.textStyle(_:)`-style convenience API exists yet — `Font.custom("Pretendard-Bold", size: 28)` etc. works today on both platforms; implement the convenience wrapper on first use and update this section with the actual Swift API and file path. If a style needs a weight not listed above (e.g. Thin/Light/ExtraBold/Black), the matching file must be added to `KIIKICK Global/Fonts/` and registered in **both** Info.plist files first — the source downloads are in `~/Downloads/Pretendard-1.3.9/public/static/` and `~/Downloads/Kanit/`.

| Figma name    | Weight   | Size | Line height | Letter spacing |
| ------------- | -------- | ---- | ----------- | --------------- |
| `head1_b`     | Bold     | 28   | 125 %       | -1.5 %          |
| `head2_sb`    | SemiBold | 24   | 125 %       | -1.5 %          |
| `head3_b`     | Bold     | 20   | 125 %       | -1.5 %          |
| `title1_sb`   | SemiBold | 20   | 125 %       | -1.5 %          |
| `title2_sb`   | SemiBold | 18   | 125 %       | -1.5 %          |
| `title3_m`    | Medium   | 18   | 125 %       | -1.5 %          |
| `title4_sb`   | SemiBold | 16   | 125 %       | -1.5 %          |
| `label1_m`    | Medium   | 16   | 140 %       | -1.5 %          |
| `label2_sb`   | SemiBold | 14   | 140 %       | -1.5 %          |
| `label3_m`    | Medium   | 14   | 140 %       | -1.5 %          |
| `label4_sb`   | SemiBold | 12   | 140 %       | -0 %            |
| `body1_m`     | Medium   | 18   | 140 %       | -1.5 %          |
| `body2_r`     | Regular  | 18   | 140 %       | -1.5 %          |
| `body3_r`     | Regular  | 16   | 140 %       | -1.5 %          |
| `body4_r`     | Regular  | 14   | 140 %       | -1.5 %          |
| `caption1_m`  | Medium   | 12   | 140 %       | -0 %            |
| `caption2_sb` | SemiBold | 10   | 140 %       | -0 %            |

Kanit display styles:

| Figma name     | Weight   | Size | Line height | Letter spacing |
| -------------- | -------- | ---- | ----------- | --------------- |
| `display1_sb`  | SemiBold | 36   | 120 %       | 0 %             |
| `display2_sb`  | SemiBold | 32   | 120 %       | 0 %             |
| `display3_sb`  | SemiBold | 24   | 120 %       | 0 %             |

- `Size` is the design reference value. Text should scale with Dynamic Type (`Font.custom(_:size:relativeTo:)`) once implemented.
- A separate "Font Weight / Letter Spacing" summary table also exists on the same page (`26:524`–`26:552`), but its frame names (`letter-spacing/tight`, `letter-spacing/none`, …) don't match the weight values shown in its rows (`font-weight/bold = 700`, `font-weight/semibold = 600`, …) — this looks like a stale/mislabeled table in the source file itself. The per-style table above (read directly from each style's row) is the reliable source; the summary table was not used.

## Colors — Primitive, verified (Figma node `1:239`, "Color: Primitive")

Exact hex values read from the rendered color swatches. No semantic/alias layer exists in the source (see Verification status above) — there is no `background/bg`, `text/primary`, etc. in the Figma file. Code should define a semantic layer on top of these if/when needed, rather than inventing Figma names that don't exist.

| Group        | Steps                                                                                           |
| ------------ | ------------------------------------------------------------------------------------------------ |
| `global/`    | `black` #000000, `white` #FFFFFF                                                                 |
| `grayscale/` | `gray50` #FAFAFA, `gray100` #F5F5F5, `gray200` #E5E5E5, `gray300` #D4D4D4, `gray400` #A3A3A3, `gray500` #737373, `gray600` #525252, `gray700` #404040, `gray800` #303030, `gray850` #242424, `gray900` #1A1A1A, `gray950` #121212, `gray1000` #0A0A0A |
| `mint/`      | `mint100` #CCF8F3, `mint300` #66E9DB, `mint500` #00DAC3, `mint700` #009989, `mint900` #004139, `mint950` #0B2522 |
| `blue/`      | `blue100` #9CFFFD, `blue300` #0EEFFF, `blue500` #21A3FF, `blue700` #0E64B3, `blue900` #00417D    |
| `red/`       | `red300` #FB9696, `red500` #FF3737, `red700` #AE0000                                             |
| `lime/`      | `lime300` #EFFCB0, `lime500` #DFFF3F, `lime700` #C4E90B                                          |
| `orange/`    | `orange100` #FFA68B, `orange500` #FF6131, `orange700` #C94219                                    |

- All 33 non-black/white values above are registered as `Color Set`s in `KIIKICK Global/Assets.xcassets` (shared by iOS + watchOS), named PascalCase exactly as the Figma step name (e.g. `mint500` → `Mint500` → `Color(.mint500)` / `UIColor(resource: .mint500)`). Pure black/white use `Color.black`/`Color.white` directly instead of a Color Set.
- `mint500` (#00DAC3) is the most saturated/brand-like color in the palette; confirm with design before assuming it's the primary brand color — this file does not label any color as "brand."
- Dark mode values are not visible in this page (single Universal swatch per step); check the `watchOS`/`iOS` screen pages directly if dark-mode-specific values are needed for a given screen.

## Spacing

🚧 Not read from Figma yet. Check the relevant screen frame's Auto Layout `spacing`/`padding` properties via `get_design_context` when implementing, and report as Gaps if unspecified.

## Radius

🚧 Not read from Figma yet. Same as Spacing above.

## Components — inventory, verified (Figma node `1:440`, "Assets&Components")

The design library includes a Components page. Check the component definitions before implementing a screen, and reuse matching implementations when available. None of the below have a SwiftUI implementation in this repo yet.

| Figma component | Variant axes / states | Approx. size | Code / Path |
| ---------------- | ---------------------- | ------------ | ------------ |
| `cta` (Button)   | `active` (on/off) × `Type` (primary/secondary/sub/destructive/Default) × `size` (L/s) | size L ≈ 352×55(54), size s ≈ 116×46 | not implemented |
| `cta-watch` (watchOS button) | `Type` (primary/destructive) | 147×49 | `CtaWatchView` — `KIIKICK Watch App Watch App/Features/Components/CtaWatchView.swift` |
| `navi_row`       | no variants seen        | 354×64       | not implemented |
| `searchbar`      | `State` (default/writing/completed) | 354×52 each | not implemented |
| `textfield`      | `State` (default/writing/completed/error) | 354×77–78 each | not implemented |
| `sub-watch`      | no variants seen        | 147×52       | `SubWatchView` — `KIIKICK Watch App Watch App/Features/Components/SubWatchView.swift` |
| `Stepper` (watchOS) | no variants seen     | 156×60       | `StepperWatchView` — `KIIKICK Watch App Watch App/Features/Components/StepperWatchView.swift` |
| `btn_selection` (watchOS) | no variants seen | 48×32        | `BtnSelectionView` — `KIIKICK Watch App Watch App/Features/Components/BtnSelectionView.swift` |
| `Performance Trends` chart | `Property 1` = "Quarter chart" (×3 shown) | 362×348 each | not implemented |
| `logo`           | —                       | 400×200      | not implemented |
| Icon sizes       | `size` = 8/12/16/20/24/28(`size11`)/28/32/36/40/44 | — | not implemented |
| Icons            | `ic/pause`, `ic/play`, `ic/search`, `ic/mylocation`, `ic/delete`, `ic/success` | 24–28px | not implemented |

For each component, before implementing: read its exact variant properties, states, text/color styles, Auto Layout direction, sizing (Fixed / Hug / Fill), spacing, padding and radius via `get_design_context` on its specific node id — the table above is an inventory (names, variant axes, approximate sizes), not a full spec. Update the "Code / Path" column with the actual Swift type and repository path once implemented. A Figma component existing does not mean its SwiftUI implementation exists.
