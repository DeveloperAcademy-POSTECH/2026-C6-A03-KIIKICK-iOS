# DESIGN.md — Design System

Records Figma design references and their implementation status. **Figma is the source of truth for values.** Only verified mappings may be used as implementation guidance.

Source: [Design System for Color, Fonts](https://www.figma.com/design/Oc5LQED0S2UeVfXvdAjNwO/%E2%9A%BD%EF%B8%8F-KIIKICK-%EB%94%94%EC%9E%90%EC%9D%B8-%EB%9D%BC%EC%9D%B4%EB%B8%8C%EB%9F%AC%EB%A6%AC?node-id=1-239&t=vl5yYnI25mUIBsBJ-1)

## Verification status

- The links now point to the KIIKICK design library. Fonts and Color must be read from node `1:239`; Components must be read from node `1:440`.
- **The Typography and Colors tables below are legacy Earthu mappings, not verified KIIKICK specifications. Do not implement from these tables until they have been checked against the new library.**
- This repository uses `KIIKICK/KIIKICK/`. The referenced `Earthu/DesignSystem/` and `Earthu/Assets.xcassets/Colors/` paths do not exist here, and the documented `.textStyle(_:)` and semantic color APIs are not implemented here.
- Exact font styles, color variables/aliases, spacing, radii, component variants and layout properties remain unverified. Do not infer values from screenshots.

## Rules

- Use verified design tokens when available. Never treat the legacy tables below as existing KIIKICK APIs or hard-code unverified colors, font sizes, spacing, or radius.
- Reuse existing components before creating new ones.
- If a Figma value has no matching token, do not create one. Use the closest token and report it as a 🟡 Gap (see [FIGMA.md](FIGMA.md)).
- Do not add or modify tokens without approval.

## Typography — legacy, pending verification

13 Figma text styles plus the wordmark. Everything is Pretendard; only the wordmark uses Galano Grotesque.

`.textStyle(_:)` applies **line-height and letter-spacing along with the font**. `.font(...)` alone drops both, so always use `.textStyle(_:)` for text.

```swift
Text("2026 정기 고연전")
    .textStyle(.head1SB)
    .foregroundStyle(Color.textPrimary)
```

| Figma Text Style      | Code                      | Weight   | Size | Line height | Letter spacing |
| --------------------- | ------------------------- | -------- | ---- | ----------- | -------------- |
| `headline/head1_sb`   | `.textStyle(.head1SB)`    | SemiBold | 28   | 125 %       | -2.5 %         |
| `headline/head2_sb`   | `.textStyle(.head2SB)`    | SemiBold | 24   | 125 %       | -2.5 %         |
| `headline/head3_b`    | `.textStyle(.head3B)`     | Bold     | 20   | 125 %       | -2.5 %         |
| `title/title1_sb`     | `.textStyle(.title1SB)`   | SemiBold | 20   | 125 %       | -2.5 %         |
| `title/title2_sb`     | `.textStyle(.title2SB)`   | SemiBold | 18   | 125 %       | -2.5 %         |
| `label/label1_sb`     | `.textStyle(.label1SB)`   | SemiBold | 14   | 140 %       | -2.5 %         |
| `label/label2_m`      | `.textStyle(.label2M)`    | Medium   | 14   | 140 %       | -2.5 %         |
| `label/label3_sb`     | `.textStyle(.label3SB)`   | SemiBold | 12   | 140 %       | -1.5 %         |
| `body/body1_r`        | `.textStyle(.body1R)`     | Regular  | 18   | 140 %       | -2.5 %         |
| `body/body2_r`        | `.textStyle(.body2R)`     | Regular  | 16   | 140 %       | -2.5 %         |
| `body/body3_r`        | `.textStyle(.body3R)`     | Regular  | 14   | 140 %       | -2.5 %         |
| `caption/caption1_m`  | `.textStyle(.caption1M)`  | Medium   | 12   | 140 %       | -1.5 %         |
| `caption/caption2_sb` | `.textStyle(.caption2SB)` | SemiBold | 10   | 140 %       | -1.5 %         |
| `Brand / Wordmark`    | `.textStyle(.wordmark)`   | Medium   | 20   | 125 %       | -2.5 %         |

- `Size` is the design reference value. Text **scales with Dynamic Type** (`Font.custom(_:size:relativeTo:)`). Use padding instead of fixed heights so layouts survive larger text.
- `wordmark` is reserved for the EarthUU wordmark. Never use it for regular UI text.
- Defined in `Earthu/DesignSystem/Typography/`.

## Colors — legacy, pending verification

UI code uses **semantic tokens only**. `Color.Primitive.*` (the palette) exists solely to define semantic tokens.

```swift
Text("모집 중")
    .foregroundStyle(Color.textOnBrand)
    .background(Color.backgroundBrand)
```

| Figma Variable                          | Code                                                       | Primitive                |
| --------------------------------------- | ---------------------------------------------------------- | ------------------------ |
| `background/bg`                         | `Color.backgroundBg`                                       | `neutral/100`            |
| `background/surface`                    | `Color.backgroundSurface`                                  | `global/white`           |
| `background/brand`                      | `Color.backgroundBrand`                                    | `orange/500`             |
| `background/brand-subtle`               | `Color.backgroundBrandSubtle`                              | `orange/50`              |
| `background/inverse`                    | `Color.backgroundInverse`                                  | `neutral/950`            |
| `action/primary/default`                | `Color.actionPrimaryDefault`                               | `orange/500`             |
| `action/primary/default50`~`default900` | `Color.actionPrimaryDefault50` ~ `actionPrimaryDefault900` | `orange/50`~`orange/900` |
| `action/primary/disabled`               | `Color.actionPrimaryDisabled`                              | `neutral/200`            |
| `text/primary`                          | `Color.textPrimary`                                        | `neutral/950`            |
| `text/secondary`                        | `Color.textSecondary`                                      | `neutral/800`            |
| `text/tertiary`                         | `Color.textTertiary`                                       | `neutral/500`            |
| `text/disabled`                         | `Color.textDisabled`                                       | `neutral/500`            |
| `text/on-brand`                         | `Color.textOnBrand`                                        | `global/white`           |
| `text/accent`                           | `Color.textAccent`                                         | `orange/500`             |
| `text/sub`                              | `Color.textSub`                                            | `orange/300`             |
| `icon/default`                          | `Color.iconDefault`                                        | `neutral/950`            |
| `icon/disabled`                         | `Color.iconDisabled`                                       | `neutral/500`            |
| `icon/on-brand`                         | `Color.iconOnBrand`                                        | `global/white`           |
| `icon/accent`                           | `Color.iconAccent`                                         | `orange/500`             |
| `icon/sub`                              | `Color.iconSub`                                            | `neutral/900`            |
| `feedback/error`                        | `Color.feedbackError`                                      | `red/500`                |
| `feedback/success`                      | `Color.feedbackSuccess`                                    | `green/500`              |
| `status/positive`                       | `Color.statusPositive`                                     | `green/500`              |
| `status/neutral`                        | `Color.statusNeutral`                                      | `neutral/600`            |
| `status/negative`                       | `Color.statusNegative`                                     | `red/500`                |
| `border/default`                        | `Color.borderDefault`                                      | `neutral/200`            |
| `border/subtle`                         | `Color.borderSubtle`                                       | `neutral/100`            |
| `border/focus`                          | `Color.borderFocus`                                        | `orange/500`             |
| `border/sub`                            | `Color.borderSub`                                          | `orange/300`             |

- The 38-color primitive palette is registered as Color Sets in `Earthu/Assets.xcassets/Colors/`: `global/black·white`, `neutral/50`~`950`, `orange/50`~`900`, and `red·blue·green/100`~`900`.
- Defined in `Earthu/DesignSystem/Colors/`.
- Dark mode values are not defined in the design file. Every Color Set holds a single Universal value.

## Spacing

🚧 Not implemented as tokens yet. Figma defines `margin/margin-l` (24) and `margin/margin-xl` (40), but the full scale is not specified, so no code tokens were created. Handle this in a separate issue when it is needed.

## Radius

🚧 Not implemented as tokens yet.

## Components

Source: [KIIKICK Components](https://www.figma.com/design/Oc5LQED0S2UeVfXvdAjNwO/?node-id=1-440).

The design library now includes Components. Check the component definitions before implementing a screen, and reuse matching implementations when available.

| Figma reference | Code / Path | Verification status |
| --------------- | ----------- | ------------------- |
| Components (`1:440`) | No verified code mapping yet | Inventory, exact names, variants, states and layout properties must be read from the source |

For each component, record its node link, exact name, variant properties, states, text/color styles, Auto Layout direction, sizing (Fixed / Hug / Fill), spacing, padding and radius, followed by the actual Swift type and repository path once implemented. A Figma component existing does not mean its SwiftUI implementation exists.

### Design Gaps — library synchronization

- 🔴 Fonts / Color (`1:239`): current properties could not be retrieved; legacy mappings above are not validated.
- 🔴 Components (`1:440`): source link registered; detailed component specifications could not be retrieved.
- Verification attempt: Aside returned `402 Insufficient credits`; web access failed; the Figma desktop UI exposed no node properties and window interaction returned `noWindowsAvailable`.
