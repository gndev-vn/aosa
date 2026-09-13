# Data Model Specification: Full UI/UX Modernization with Shadcn Design System

**Feature**: Full UI/UX Modernization with Shadcn Design System
**Directory**: `specs/005-refactor-ui-shadcn`
**Status**: Completed (Phase 1)

---

## Entities

### 1. `ShadcnThemeConfig` (Presentation Entity)

Represents the complete design token set applied across `ShadApp` and `AppTheme`.

| Field | Type | Description |
|---|---|---|
| `brightness` | `Brightness` | `Brightness.dark` (default) or `Brightness.light` |
| `background` | `Color` | Dark: `#09090b` (Zinc-950), Light: `#ffffff` |
| `cardBackground` | `Color` | Dark: `#18181b` (Zinc-900), Light: `#ffffff` |
| `border` | `Color` | Dark: `#27272a` (Zinc-800), Light: `#e4e4e7` (Zinc-200) |
| `primaryAccent` | `Color` | Configurable accent (Emerald `#10b981`, Sky `#0ea5e9`, Violet `#8b5cf6`, Rose `#f43f5e`, Amber `#f59e0b`) |
| `mutedForeground` | `Color` | Dark: `#a1a1aa` (Zinc-400), Light: `#71717a` (Zinc-500) |
| `destructive` | `Color` | Error / delete highlight (`#ef4444`, Red-500) |
| `cardRadius` | `BorderRadius` | `BorderRadius.circular(12)` (0.75rem) |
| `pillRadius` | `BorderRadius` | `BorderRadius.circular(9999)` |

---

### 2. `OtpCardPresentationModel` (View Model)

Encapsulates the visual state of an individual token card.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Unique account identifier |
| `issuer` | `String` | Service or provider name |
| `accountLabel` | `String` | User account label or email |
| `formattedCode` | `String` | Code with tabular formatting and space grouping (e.g. `"491 823"`) |
| `timeLeft` | `int` | Remaining seconds (1 to period) |
| `progress` | `double` | Normalized countdown fraction (`0.0` to `1.0`) |
| `isExpiringSoon` | `bool` | `true` when `timeLeft <= 5` (triggers warning accent) |
| `isCopied` | `bool` | `true` during 1500ms post-tap feedback animation |

#### State Transitions
```text
[Normal Countdown] ──(timeLeft <= 5s)──> [Warning Accent State]
        │                                         │
        ├─────────────────(tap to copy)───────────┤
        ▼                                         ▼
[Copied: Morph to Checkmark] ──(1500ms timeout)──> [Restore Code / Countdown]
```

---

### 3. `ModalSheetPresentationModel` (Presentation Entity)

Represents floating modal dialogs and bottom sheets.

| Field | Type | Description |
|---|---|---|
| `title` | `String` | Prominent modal heading |
| `description` | `String?` | Instructional or context copy |
| `maxWidth` | `double` | Enforced width ceiling: `640.0` dp on desktop/foldables |
| `sideMargin` | `double` | Horizontal inset: `16.0` dp on mobile, auto-centered on desktop |
| `isFloating` | `bool` | Always `true` (detached card floating above navigation bar) |

---

### 4. `AndroidNdkConfig` (Build Configuration Entity)

Represents the Android NDK toolchain configuration.

| Field | Type | Value / Validation |
|---|---|---|
| `ndkVersion` | `String` | `"30.0.16248370"` (exact installed side-by-side version) |
| `compileSdk` | `int` | Matched from `flutter.compileSdkVersion` |
| `isCoreLibraryDesugaringEnabled` | `bool` | `true` |
| `javaVersion` | `JavaVersion` | `VERSION_17` |
