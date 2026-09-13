# Interface Contract: Shadcn Theme & Design Tokens

**Contract Scope**: Specifications for `ShadApp` wrapper, `ShadThemeData`, color palettes, typography, and border tokens.

---

## 1. Color Palette Tokens (Modern Zinc)

| Token Name | Dark Mode (Default) | Light Mode | Purpose |
|---|---|---|---|
| `background` | `#09090b` (Zinc-950) | `#ffffff` | Scaffold and screen canvas |
| `card` | `#18181b` (Zinc-900) | `#ffffff` | Card, sheet, and popover surfaces |
| `border` | `#27272a` (Zinc-800) | `#e4e4e7` (Zinc-200) | Subtle 1px structural outlines |
| `foreground` | `#fafafa` (Zinc-50) | `#09090b` (Zinc-950) | Primary titles and high-contrast text |
| `mutedForeground` | `#a1a1aa` (Zinc-400) | `#71717a` (Zinc-500) | Subtitles, labels, helper descriptions |
| `primary` | User Accent (e.g. `#10b981`) | User Accent | Buttons, active progress rings, focus rings |
| `destructive` | `#ef4444` (Red-500) | `#dc2626` (Red-600) | Error badges, delete buttons |

---

## 2. Typography Contract

- **Headings & Body**: `GoogleFonts.inter` with weights `w400` (regular), `w500` (medium), `w600` (semi-bold), and `w700` (bold).
- **Security Codes**: `GoogleFonts.jetBrainsMono` with `FontFeature.tabularFigures()` enabled to prevent character width jitter during countdown ticks.
- **Code Spacing**: Verification codes formatted with a space between 3-digit clusters (e.g. `123 456` or `1234 5678`).

---

## 3. Geometry & Radii

- **Cards & Inputs**: `BorderRadius.circular(12)` (0.75rem).
- **Dialogs & Floating Sheets**: `BorderRadius.circular(16)` (1.0rem).
- **Pill Badges & Countdown Rings**: `BorderRadius.circular(9999)`.
- **Border Width**: Exactly `1.0dp` on cards, inputs, and dialog boundaries.
