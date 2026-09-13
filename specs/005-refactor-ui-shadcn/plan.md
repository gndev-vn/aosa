# Implementation Plan: Full UI/UX Modernization with Shadcn Design System & NDK Fix

**Branch**: `005-refactor-ui-shadcn` | **Date**: 2026-09-12 | **Spec**: [spec.md](file:///d:/Projects/aosa/specs/005-refactor-ui-shadcn/spec.md)

**Input**: Feature specification from `specs/005-refactor-ui-shadcn/spec.md`

## Summary

Execute a comprehensive UI/UX modernization of the AOSA Flutter authenticator using the `shadcn_ui` design framework with custom styling, and fix the Android NDK build configuration by binding to the installed side-by-side NDK.

Key pillars of this plan:
1. **Android NDK Configuration Fix**: Update `app/android/app/build.gradle.kts` to specify `ndkVersion = "30.0.16248370"` matching the locally installed NDK, resolving build failures without invoking deprecated `sdkmanager` CLI.
2. **Framework Integration**: Add `shadcn_ui: ^0.56.3` and wrap the application root in `ShadApp.material`, pairing `ShadThemeData` with custom Zinc dark/light palettes, subtle 1px border outlines (`#27272a`), 12dp card radii, and Lucide icons.
3. **Core Journey Redesign**:
   - **OTP Account Cards**: Build a custom `ShadCard` with brand avatars, tabular monospace numerals (`fontFeatures: [FontFeature.tabularFigures()]`), smooth progress ring, and 1-tap copy with animated checkmark feedback.
   - **Navbar & Search**: Streamlined header with search input, sync status badge, and repository switcher.
   - **Forms & Sheets**: Floating bottom sheets (`maxWidth: 640dp`, side margins) for Add Account, URI paste, manual entry, and edit screen using `ShadInput` and `ShadButton`.
   - **Settings & Modals**: Grouped card sections with `ShadSwitch`, badge chips, and dedicated confirmation dialogs.
4. **Zero-Regression Quality Gate**: Retain 100% passing automated test suite (96 tests) and zero static analysis warnings under `flutter_lints ^6.0.0`.

## Technical Context

**Language/Version**: Dart 3.5+ (active: 3.13.3), Flutter 3.27+ (active: 3.47.4)

**Primary Dependencies**: `shadcn_ui: ^0.56.3`, `lucide_icons_flutter`, `flutter_riverpod: ^2.6.1`, `flutter_animate: ^4.5.0`, `google_fonts: ^8.2.1`, `sqlite3: ^3.5.2`, `flutter_secure_storage: ^11.1.1`

**Build Toolchain**: Android NDK `30.0.16248370`, Gradle Kotlin DSL (`build.gradle.kts`), Java 17

**Storage**: Local encrypted SQLite database (`app_database.dart`), `flutter_secure_storage`

**Testing**: `flutter_test`, `flutter analyze`

**Target Platform**: Android, iOS, macOS, Linux, Windows

**Project Type**: Cross-platform Client Application (TOTP Authenticator)

**Performance Goals**: 60–120 fps fluid animations; <50ms clipboard copy confirmation; zero frame drops during countdown ticker updates

**Constraints**: 0 compilation errors; 0 linter warnings; 100% test pass rate (96/96); 100% functional parity with existing crypto, vault, and sync services

**Scale/Scope**: ~15 modified presentation widgets, 1 updated build configuration, ~6 redesigned screens and sheets

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Project constitution template contains no unratified blocking rules.
- Design strictly preserves Clean Architecture: pure presentation layer refactoring with zero modification to domain models (`OtpAccount`, `TotpEngine`) or data layer (`AppDatabase`, `CryptoService`).
- Security, biometric encryption, and offline-first guarantees remain unaffected.
- Gate status: **PASSED**.

## Project Structure

### Documentation (this feature)

```text
specs/005-refactor-ui-shadcn/
├── plan.md              # This implementation plan
├── research.md          # Technical research & architectural decisions (Phase 0)
├── data-model.md        # Entities, view models, and configuration schemas (Phase 1)
├── quickstart.md        # Runnable verification and validation scenarios (Phase 1)
├── contracts/           # Interface contracts (Phase 1)
│   ├── shadcn-theme-contract.md
│   ├── otp-card-shadcn-contract.md
│   ├── modal-sheet-shadcn-contract.md
│   └── android-ndk-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code Layout (`app/`)

```text
app/
├── android/
│   └── app/
│       └── build.gradle.kts             # Explicit ndkVersion = "30.0.16248370"
├── pubspec.yaml                         # Add shadcn_ui: ^0.56.3
├── lib/
│   ├── main.dart                        # Wrap root in ShadApp.material
│   ├── core/
│   │   └── theme/
│   │       ├── app_theme.dart           # ShadThemeData tokens (Zinc dark/light)
│   │       └── color_picker.dart
│   └── presentation/
│       ├── screens/
│       │   ├── home_screen.dart         # Redesigned Shadcn home layout
│       │   ├── edit_otp_screen.dart     # Shadcn form layout
│       │   ├── lock_screen.dart         # Shadcn keypad & security surface
│       │   └── settings_sections/       # Grouped Shadcn card rows
│       └── widgets/
│           ├── otp_card.dart            # Redesigned OtpCard with ShadCard & copy morph
│           ├── home_header.dart         # Shadcn search & action bar
│           ├── add_otp_bottom_sheet.dart# Floating ShadSheet with Lucide tiles
│           ├── confirmation_bottom_sheet.dart # ShadDialog confirmation
│           └── standard_bottom_sheet.dart # Floating modal container (maxWidth 640dp)
└── test/                                # Automated unit & widget tests
```

**Structure Decision**: Preserves clean presentation layer modularity, replacing generic Material containers with customized `shadcn_ui` primitives and Lucide icons.

## Complexity Tracking

| Item | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Explicit `ndkVersion = "30.0.16248370"` in `build.gradle.kts` | Flutter 3.47 defaults to requesting uninstalled NDK 28.x, causing Gradle `sdkmanager` crash | Leaving it dynamic fails builds on Windows when `sdkmanager` CLI encounters non-zero exit |
| `ShadApp.material` root wrapper | Enables native Shadcn components alongside Flutter Material scaffolding and Riverpod routing | Building all Shadcn widgets from scratch is redundant when `shadcn_ui` provides robust tested primitives |
