# Technical Research & Architectural Decisions

**Feature**: Full UI/UX Modernization with Shadcn Design System
**Directory**: `specs/005-refactor-ui-shadcn`
**Status**: Completed (Phase 0)

---

## 1. UI Framework: `shadcn_ui` Architecture & Integration

### Context & Problem
The application currently uses standard Flutter Material 3 widgets with custom styling in `AppTheme`. The user requested a complete UI/UX modernization using an implementation of Shadcn, customized so the application looks stunning, modern, and sleek.

### Research Findings: `shadcn_ui` Package (`^0.56.3`)
1. **Package Availability & Compatibility**:
   - `shadcn_ui` (version `0.56.3`) on pub.dev is a pure Flutter port of the Shadcn design system.
   - It depends on `lucide_icons_flutter` (providing 1,000+ sleek icons), `flutter_svg`, and `two_dimensional_scrollables`.
   - Dry-run dependency resolution confirms full compatibility with existing dependencies (`flutter_riverpod 2.6.1`, `sqlite3 3.5.2`, `flutter_secure_storage 11.1.1`, etc.) with zero version collisions.
2. **App Root Wrapping**:
   - `ShadApp.material(...)` acts as a drop-in replacement/enhancer for `MaterialApp`, allowing both Shadcn primitives (`ShadCard`, `ShadButton`, `ShadInput`, `ShadSheet`, `ShadDialog`) and Material widgets (`Scaffold`, `Navigator`) to coexist seamlessly.
   - Preserves existing Riverpod provider scopes and route configurations.
3. **Theme Customization (`ShadThemeData`)**:
   - Palette choice: **Modern Zinc & Sleek Dark Mode**:
     - Background: `#09090b` (deep zinc dark) / `#ffffff` (light)
     - Card background: `#18181b` (subtle elevated zinc) / `#ffffff` (light)
     - Border outline: 1px `#27272a` (zinc-800) / `#e4e4e7` (zinc-200)
     - Primary accent: User-customizable dynamic accent (Emerald `#10b981`, Violet `#8b5cf6`, Sky `#0ea5e9`, Rose `#f43f5e`, or Amber `#f59e0b`).
     - Radius: `0.75rem` (12dp) for cards and inputs, `9999px` for pill badges.
     - Typography: `GoogleFonts.inter` for UI copy; `GoogleFonts.jetBrainsMono` with tabular numerals (`fontFeatures: [FontFeature.tabularFigures()]`) for verification codes.

### Decision
Integrate `shadcn_ui: ^0.56.3` via `ShadApp.material` in `app/lib/main.dart`, define custom `ShadThemeData` tokens in `app/lib/core/theme/app_theme.dart`, and refactor all core views to use native Shadcn components.

---

## 2. Component Mapping & Redesign Strategy

### Context & Problem
The current UI components in `lib/presentation/` use generic containers, basic ink wells, and standard dialogs. To achieve a stunning visual aesthetic, each component needs to be reimagined:

| Current Component | Redesigned Shadcn Component | Visual & Interactive Enhancement |
|---|---|---|
| `OtpCard` | Custom `ShadCard` with subtle 1px border | Monogram/brand avatar, tabular spaced codes (`123 456`), circular/linear countdown progress ring, 1-tap copy with animated checkmark morphing |
| `HomeHeader` | Sleek Shadcn Navbar | Search input with Lucide search/clear icons, quick sync badge button, and repository picker |
| `AddOtpBottomSheet` | Floating `ShadSheet` | Clean option cards (QR scan, paste URI, manual entry) with Lucide icons |
| `OtpForm` / `EditOtpScreen` | `ShadCard` with `ShadInput` | Soft pill borders, focus rings, clear labels, and grouped action buttons (`ShadButton`, `ShadButton.destructive`) |
| `ConfirmationBottomSheet` | `ShadDialog` / `ShadSheet` | Warning badge icon, bold title, muted description, and prominent Confirm/Cancel actions |
| `SettingsSections` | Grouped `ShadCard` lists | Refined disclosure rows, `ShadSwitch` toggles, badge chips, and consistent chevron icons |
| `PinLockScreen` | Shadcn Keypad | Elegant circular keypad with subtle border hover/tap effects and secure dot indicators |

---

## 3. Android NDK Side-by-Side Configuration

### Context & Problem
Running `flutter run` on Android failed with:
```text
Package ndk not found.
Package 28.2.13676358 not found.
Process 'command '...sdkmanager.bat'' finished with non-zero exit value -1073740791
```
`app/android/app/build.gradle.kts` currently specifies:
```kotlin
android {
    ndkVersion = flutter.ndkVersion
}
```
`flutter.ndkVersion` defaults to `28.2.13676358` on Flutter 3.47. Gradle attempted to invoke `sdkmanager` to auto-install it, which failed on Windows.
System inspection revealed that NDK `30.0.16248370` is already installed side-by-side at `C:\Users\khanh\AppData\Local\Android\Sdk\ndk\30.0.16248370`.

### Decision
Update `app/android/app/build.gradle.kts` to explicitly specify:
```kotlin
android {
    ndkVersion = "30.0.16248370"
}
```
This forces Gradle to immediately use the locally installed NDK without calling `sdkmanager` to download missing packages.

---

## 4. Performance & Test Parity

### Context & Problem
Introducing a UI framework must not degrade list performance or break the 96 automated tests.

### Decision
- Maintain decoupled state management (`totpTickerProvider` updating only the countdown widget inside `OtpCard`, preserving O(1) list rebuilds).
- Run `flutter analyze` to ensure zero linter warnings under `flutter_lints ^6.0.0`.
- Verify all 96 unit, cryptographic, database, and widget tests pass.
