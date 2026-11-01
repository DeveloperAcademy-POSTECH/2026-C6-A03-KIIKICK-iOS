# DESIGN.md — Design System

Records Figma design references and their implementation status. **Figma is the source of truth for values.** Only verified mappings may be used as implementation guidance.

Source: [Design System for Color, Fonts](https://www.figma.com/design/Oc5LQED0S2UeVfXvdAjNwO/%E2%9A%BD%EF%B8%8F-KIIKICK-%EB%94%94%EC%9E%90%EC%9D%B8-%EB%9D%BC%EC%9D%B4%EB%B8%8C%EB%9F%AC%EB%A6%AC?node-id=1-239&t=vl5yYnI25mUIBsBJ-1)

All of the above live in the **same Figma file** (key `Oc5LQED0S2UeVfXvdAjNwO`) — iOS and watchOS screens are separate pages/frames within it, not separate files:

- [iOS screens](https://www.figma.com/design/Oc5LQED0S2UeVfXvdAjNwO/%E2%9A%BD%EF%B8%8F-KIIKICK-%EB%94%94%EC%9E%90%EC%9D%B8-%EB%9D%BC%EC%9D%B4%EB%B8%8C%EB%9F%AC%EB%A6%AC?node-id=120-12) (node `120:12`)
- [watchOS screens](https://www.figma.com/design/Oc5LQED0S2UeVfXvdAjNwO/%E2%9A%BD%EF%B8%8F-KIIKICK-%EB%94%94%EC%9E%90%EC%9D%B8-%EB%9D%BC%EC%9D%B4%EB%B8%8C%EB%9F%AC%EB%A6%AC?node-id=241-3911) (node `241:3911`)

## Verification status

- Verified via Figma MCP (`get_metadata` + `get_screenshot`) on node `1:239` ("System" page → "Typography : variables" + "Color: Primitive" frames) and node `1:440` ("Assets&Components" page). Values below are read directly from the file, not inferred from screenshots or guessed.
- **A semantic color Variable collection exists and *is* documented as its own page** — node `313:2`, "Color · Semantic" (35 tokens, every value a Primitive alias). This was found later in the project; an earlier note here said it wasn't documented as its own page, which was wrong — it just hadn't been located yet. `get_variable_defs` on the "Color: Primitive" page's own swatches still returns empty (raw fills, no Variable binding), and still fails ("nothing selected") everywhere else in this file, so `313:2` was read via `get_screenshot` like everything else. See "Colors — Semantic" below.
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

## Colors — Semantic, verified (node `313:2`, "Color · Semantic" documentation page)

`313:2` is the authoritative semantic color page — "Dark가 기본인 단일 테마 · 35개 semantic 토큰 · 모든 색상은 primitive alias로 연결" (dated 2026.11.01 in the doc itself). It supersedes the earlier `get_variable_defs`-on-component-instance readings below; those were a workaround for not having found this page yet, and one of them (`color-surface-elevated` → `mint950`) turned out to actually be a *different*, separately-named token (`surface/darken`) — not the real `surface/elevated` (which is `gray800`). Read via `get_screenshot`, not `get_variable_defs` (still fails the same way as before).

| Figma name | Resolved value | Primitive | Swift (`Color+Semantic.swift`) |
| --- | --- | --- | --- |
| `background/primary` | `#121212` | `gray950` | — (not yet aliased) |
| `background/secondary` | `#1A1A1A` | `gray900` | `Color.colorBackgroundSecondary` |
| `surface/primary` | `#242424` | `gray850` | `Color.colorSurfacePrimary` |
| `surface/elevated` | `#303030` | `gray800` | — (not yet aliased; iOS components use `.gray800` primitive directly) |
| `surface/darken` | `#0B2522` | `mint950` | `Color.surfaceDarken` |
| `surface/recessed` | `#0A0A0A` | `gray1000` | — (not yet aliased) |
| `text/brand` | `#00DAC3` | `mint500` | `Color.textBrand` |
| `action/destructive` | `#FF3737` | `red500` | `Color.actionDestructive` |
| `brand/primary` | `#00DAC3` | `mint500` | — (not yet aliased; same value as `text/brand`) |
| `brand/pressed` | `#009989` | `mint700` | — (not yet aliased) |
| `brand/subtle` | `#004139` | `mint900` | — (not yet aliased) |
| `brand/gray` | `#737373` | `gray500` | `Color.brandGray` |

Only the rows actually used by a component so far are aliased in `Color+Semantic.swift`; the rest of the 35 tokens (Text/Icon/Border/Feedback/Data-visualization sections) haven't been transcribed yet — re-read node `313:2` when a new component needs one of them, rather than guessing from the Primitive table.

`StepperWatchView`'s decrement capsule uses `.brandGray` (formerly misnamed `colorBrandPrimary` — same value, `gray500`, just the name was wrong: it was derived from a WEB CSS var string that the Figma doc happens to reuse across all 4 `brand/*` rows, not from the actual distinct Variable name). `BtnSelectionView`'s `.selected` style uses `.surfaceDarken` (formerly misnamed `colorSurfaceElevated`).

The iOS atoms (`CtaView`, `KiikickTextField`, `SearchBarView`, `NotificationFriendView`, `ListFriendView`, `NotificationCommentView`, `DatePickerView`, `CardSummaryView`, `PerformanceTrendsView`) use the **Primitive** Color Sets directly (`.gray800`, `.gray850`, `.gray900`, `.gray950`, `.gray700`, `.mint500`, `.mint700`, `.red500`) rather than semantic aliases — this is now confirmed correct per the table above (`surface/elevated` really is `gray800`), just not yet wired through named semantic properties. Fine to switch to semantic names on next touch.

## Spacing — partially verified (`get_variable_defs` on node `241:4076`)

- `padding-12` = 12pt — vertical padding on `cta-watch`, `sub-watch`, `btn_selection`.
- `spacing-20` = 20pt — `HStack` gap in `Stepper`.
- Not yet checked on other screens/components — check the relevant frame's Auto Layout `spacing`/`padding` via `get_design_context`/`get_variable_defs` when implementing, and report as Gaps if unspecified.

## Radius — partially verified (`get_variable_defs` on node `241:4076`)

- `radius-full` = 999 — effectively a full capsule/pill; implement with SwiftUI `Capsule()` (already done for the 4 watchOS components), not a numeric `cornerRadius`.
- Not yet checked on other screens/components — same as Spacing above.

## Components — inventory, verified (Figma node `1:440`, "Assets&Components")

The design library includes a Components page. Check the component definitions before implementing a screen, and reuse matching implementations when available.

| Figma component | Variant axes / states | Approx. size | Code / Path |
| ---------------- | ---------------------- | ------------ | ------------ |
| `cta` (Button)   | `active` (on/off) × `Type` (primary/secondary/sub/destructive/Default) × `size` (L/s) | size L fills width (55/54 tall), size s hugs content (46 tall) | `CtaView` — `KIIKICK/Features/Components/CtaView.swift` |
| `cta-watch` (watchOS button) | `Type` (primary/destructive) | 147×49 | `CtaWatchView` — `KIIKICK Watch App Watch App/Features/Components/CtaWatchView.swift` |
| `navi_row`       | no variants seen        | 354×64       | not implemented |
| `searchbar`      | `State` (default/writing/completed) | 354×52 each | `SearchBarView` — `KIIKICK/Features/Components/SearchBarView.swift` |
| `textfield`      | `State` (default/writing/completed/error) | 354×77–78 each | `KiikickTextField` — `KIIKICK/Features/Components/KiikickTextField.swift` |
| `sub-watch`      | no variants seen        | 147×52       | `SubWatchView` — `KIIKICK Watch App Watch App/Features/Components/SubWatchView.swift` |
| `Stepper` (watchOS) | no variants seen     | 156×60       | `StepperWatchView` — `KIIKICK Watch App Watch App/Features/Components/StepperWatchView.swift` |
| `btn_selection` (watchOS) | no variants seen | 48×32        | `BtnSelectionView` — `KIIKICK Watch App Watch App/Features/Components/BtnSelectionView.swift` |
| `Performance Trends` chart | `Property 1` = "Quarter chart" (×3 shown) | 362×348 each | `PerformanceTrendsView` — `KIIKICK/Features/Components/PerformanceTrendsView.swift` (line rendering only — pinch/pan/tap-select from the Figma component description not implemented, see 🟡 Gaps below) |
| `notification_friend` | `property1` = Default (pending/accepted/rejected text) | 354×auto | `NotificationFriendView` — `KIIKICK/Features/Components/NotificationFriendView.swift` |
| `notification_comment` | no variants seen | 354×auto | `NotificationCommentView` — `KIIKICK/Features/Components/NotificationCommentView.swift` |
| `list_friend`    | `waiting` (bool)        | 354×auto     | `ListFriendView` — `KIIKICK/Features/Components/ListFriendView.swift` |
| `DatePicker`     | `down` (collapsed/expanded) | auto | `DatePickerView` — `KIIKICK/Features/Components/DatePickerView.swift` (expanded state uses native `.wheel` Picker, not a pixel copy of the static mockup — see 🟡 Gaps) |
| `card_summary`   | no variants seen        | 354×auto     | `CardSummaryView` — `KIIKICK/Features/Components/CardSummaryView.swift` |
| `logo`           | —                       | 400×200      | not implemented |
| Icon sizes       | `size` = 8/12/16/20/24/28(`size11`)/28/32/36/40/44 | — | not implemented |
| Icons            | `ic/pause`, `ic/play`, `ic/search`, `ic/mylocation`, `ic/delete`, `ic/success`, `ic/arrow`, `ic/arrow-down` | 24–28px | bundled in `KIIKICK Global/Assets.xcassets/Icon/` (added `ic_arrow`, `ic_chevron_down` for issue #10; `ic/arrow-right` reuses `ic_arrow` — identical SVG path) |

For each component, before implementing: read its exact variant properties, states, text/color styles, Auto Layout direction, sizing (Fixed / Hug / Fill), spacing, padding and radius via `get_design_context` on its specific node id — the table above is an inventory (names, variant axes, approximate sizes), not a full spec. Update the "Code / Path" column with the actual Swift type and repository path once implemented. A Figma component existing does not mean its SwiftUI implementation exists.
