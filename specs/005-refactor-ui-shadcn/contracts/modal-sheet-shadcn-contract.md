# Interface Contract: Shadcn Floating Modal & Sheet Presentation

**Contract Scope**: Layout, geometry, and responsive behavior of modal dialogs and bottom sheets.

---

## 1. Sheet Geometry & Presentation

- **Detached Floating Card**: Bottom sheets do not touch the screen edges; they float above the navigation safe area with `16.0dp` left, right, and bottom margins.
- **Corner Radii**: Rounded on all four corners (`16.0dp` radius).
- **Border**: 1px `#27272a` (dark mode) / `#e4e4e7` (light mode).
- **Max Width**: Constrained to `maxWidth: 640.0dp` on tablets, foldables, and wide desktop viewports.

---

## 2. Component Composition

- **Header**: Centered drag handle pill (36x4dp), clear modal title, and optional close icon button.
- **Action Tiles**: Distinct clickable cards with Lucide icons, titles, and descriptive subtitles (e.g. in Add Account: "Scan QR Code", "Paste URI", "Enter Manually").
- **Inputs**: `ShadInput` with 12dp radius, clear label, hint text, and focus ring.
- **Buttons**:
  - Primary: `ShadButton` (accent background, bold text).
  - Outline: `ShadButton.outline` (1px border, transparent background).
  - Destructive: `ShadButton.destructive` (red background or outline for delete operations).
