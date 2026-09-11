# Implementation Plan: Modern & Friendly UI Redesign with Foldable Support

**Branch**: `003-redesign-app-ui` | **Date**: 2026-09-11 | **Spec**: [specs/003-redesign-app-ui/spec.md](specs/003-redesign-app-ui/spec.md)

**Input**: Feature specification from `specs/003-redesign-app-ui/spec.md`

---

## Summary

Redesign the entire AOSA Flutter application with a Modern Expressive & Friendly design system and first-class foldable smartphone support. The implementation introduces an ergonomic adaptive navigation shell (`AppNavigationShell`) featuring a persistent bottom `NavigationBar` on compact screens and an adaptive left-docked `NavigationRail` on unfolded foldables, tablets, and wide screens. The OTP accounts interface is reimagined with expressive, warm cards featuring 24dp rounded corners, colorful monogram brand avatars, jitter-free tabular typography, dynamic warning countdown rings, and instantaneous 1-tap copy with animated checkmark morphing. Wide-screen/foldable mode arranges cards into a balanced 2-column adaptive grid that respects physical hinge crease safe zones and constrains floating modals to a clean `maxWidth: 640dp`.

---

## Technical Context

**Language/Version**: Dart 3.4+ / Flutter 3.22+  
**Primary Dependencies**: Flutter Material 3 (`useMaterial3: true`), Flutter Riverpod / Provider for reactive state management, `flutter_svg`, `mobile_scanner`, `qr_flutter`, `intl`  
**Storage**: SQLite (`sqflite`) + `flutter_secure_storage` (existing encrypted offline database, vault groups, and preferences)  
**Testing**: `flutter test` (unit, widget, and contract tests), `flutter analyze`  
**Target Platform**: Android (standard smartphones, foldables e.g. Samsung Galaxy Z Fold & Pixel Fold, tablets), iOS, Desktop/Web compatible  
**Project Type**: Flutter Mobile & Multiplatform Application  
**Performance Goals**: 60–120 fps fluid animations; <50ms clipboard copy feedback; zero-stutter responsive rebuilds during device fold/unfold events  
**Constraints**: 
- Maintain 100% backward compatibility with existing encrypted database models, TOTP algorithm generation engine, and cloud sync providers.
- Maintain 100% pass rate on test suite (`flutter test`) and 0 static analyzer warnings (`flutter analyze`).
- Avoid heavyweight external UI widget suites that break Flutter's headless test rendering engine.
**Scale/Scope**: 3 core navigation tabs (Accounts, Vaults, Settings), ~25 adapted/enhanced presentation widgets, responsive layout handling for viewport widths from 320dp to 1200dp+.

---

## Constitution Check

*GATE: Evaluated against project architecture and design principles.*

- [x] **Test-First Integrity**: View models, layout posture resolvers, and presentation widgets will have unit/widget tests written and verified.
- [x] **Separation of Concerns**: Pure presentation layer refactor; domain models (`OtpAccount`, `TotpEngine`) and data layers (`AccountRepository`, `DatabaseHelper`) remain unchanged.
- [x] **Cross-Platform & Headless Compatibility**: Pure Flutter Material 3 Expressive primitives with no native shader dependencies that fail in CI/headless test environments.
- [x] **Accessibility & Ergonomics**: High-contrast typography (>4.5:1 ratio), minimum 48x48dp interactive touch targets, and single-tap copy ergonomics.

---

## Project Structure

### Documentation (this feature)

```text
specs/003-redesign-app-ui/
├── plan.md                                # This file (/speckit-plan command output)
├── research.md                            # Phase 0 output: Material 3 Expressive & Foldable ergonomics
├── data-model.md                          # Phase 1 output: DisplayPosture, NavigationDestination, OtpCardViewModel
├── quickstart.md                          # Phase 1 output: Validation and run scenarios
├── contracts/                             # Phase 1 output: Architectural interface contracts
│   ├── navigation-shell.contract.md       # Contract for bottom bar ↔ rail navigation
│   ├── otp-card-presentation.contract.md  # Contract for expressive card presentation & 1-tap copy
│   └── foldable-layout.contract.md        # Contract for adaptive multi-column grid & hinge handling
└── tasks.md                               # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root: `app/`)

```text
app/
├── lib/
│   ├── core/
│   │   └── theme/
│   │       ├── app_theme.dart             # Expressive theme definitions (Light & Dark)
│   │       └── app_tokens.dart            # Design tokens: radii, surface tints, timing constants
│   ├── domain/
│   │   ├── models/                        # Unaltered: otp_account.dart, vault.dart
│   │   └── services/                      # Unaltered: totp_engine.dart
│   ├── presentation/
│   │   ├── layout/
│   │   │   ├── display_posture.dart       # Device posture & breakpoint resolver (<600dp vs >=600dp)
│   │   │   └── adaptive_foldable_layout.dart # Adaptive 1-col list vs 2-col grid with hinge safety
│   │   ├── navigation/
│   │   │   ├── app_navigation_shell.dart  # Adaptive shell: Bottom NavigationBar ↔ NavigationRail
│   │   │   └── navigation_tab.dart        # Tab definitions (Accounts, Vaults, Settings)
│   │   ├── screens/
│   │   │   ├── home_screen.dart           # Accounts tab: Search, Filter chips, FAB, OTP Grid/List
│   │   │   ├── vaults_screen.dart         # Vaults tab: Folder management and vault categories
│   │   │   └── settings_screen.dart       # Settings tab: Appearance, Security, Sync, About
│   │   └── widgets/
│   │       ├── expressive_otp_card.dart   # Soft card, brand avatar, 1-tap copy & checkmark morph
│   │       ├── otp_countdown_timer.dart   # Circular progress timer with tabular countdown
│   │       ├── friendly_avatar.dart       # Deterministic pastel monogram brand avatar
│   │       ├── fab_menu.dart              # Pill-shaped speed dial FAB for Scan, Paste, Manual
│   │       └── standard_bottom_sheet.dart # Modals constrained to maxWidth: 640dp, intrinsic height
│   └── main.dart                          # Root app bootstrap configuring AppNavigationShell
└── test/
    ├── presentation/
    │   ├── layout/
    │   │   └── adaptive_foldable_layout_test.dart
    │   ├── navigation/
    │   │   └── app_navigation_shell_test.dart
    │   └── widgets/
    │       ├── expressive_otp_card_test.dart
    │       └── friendly_avatar_test.dart
```

**Structure Decision**: Standard Flutter Clean Presentation architecture. Core tokens and layout utilities are decoupled from presentation screens and widgets, enabling isolated widget testing and clean responsiveness.

---

## Complexity Tracking

| Aspect | Justification | Simpler Alternative Rejected Because |
|---|---|---|
| Adaptive Layout (`DisplayPosture`) | Necessary to support both folded cover screens (<400dp) and unfolded square screens (>700dp) on foldables like Galaxy Z Fold | A single fixed-width list leaves large awkward white margins or stretched unreadable cards on unfolded displays |
| Monogram Color Generator | Provides beautiful, predictable pastel avatars for accounts without custom uploaded icons | Generic gray fallback icons make account scanning slow and visually dull |
