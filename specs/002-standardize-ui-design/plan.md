# Implementation Plan: Standardize UI Design & Modal Presentation

**Branch**: `002-standardize-ui-design` | **Date**: 2026-09-11 | **Spec**: [specs/002-standardize-ui-design/spec.md](spec.md)

**Input**: Feature specification from `specs/002-standardize-ui-design/spec.md`

## Summary

Standardize the application UI presentation layer to achieve cohesive mobile ergonomics and modern design consistency:
1. Transform all modal interactions (`showDialog` / `AlertDialog`) into slide-up bottom sheets.
2. Implement floating card bottom sheets with uniform left, right, and bottom margins (16dp) and all-around rounded corners (28dp).
3. Increase `SettingsRow` horizontal padding from 4dp to 16dp to prevent content from crowding card borders.
4. Establish clear typography hierarchy in settings with semi-bold (`w600`) titles and regular (`w400`) subtitles.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: Flutter Material 3, `flutter_riverpod: ^2.4.9`, `google_fonts: ^6.1.0`
**Storage**: N/A (UI presentation and layout standardization)
**Testing**: `flutter_test` (Widget tests, responsive viewport simulation)
**Target Platform**: Mobile (Android, iOS, Foldable), Tablet, Desktop, Web
**Project Type**: Mobile / Multi-platform Flutter Client (`app/`)
**Performance Goals**: 60 fps transitions, 0ms layout jank during bottom sheet presentation
**Constraints**: Responsive across viewports (360dp to 1440dp), `maxWidth: 640dp` modal clamp, floating card margins (16dp), full software keyboard avoidance (`viewInsets`)
**Scale/Scope**: Reusable components in `app/lib/presentation/widgets/`, screens in `app/lib/presentation/screens/`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|---|:---:|---|
| Architecture Boundaries | Passed | Changes are strictly confined to the presentation layer (`lib/presentation/`). Domain entities, usecases, and repositories remain untouched. |
| Test-First Compliance | Passed | Responsive tests and widget verification cover margins, dialog migrations, and typography. |
| Clean Code & Linting | Passed | 0 analyzer warnings, strict Material 3 design tokens and theme adherence. |
| Mobile-First Ergonomics | Passed | Bottom sheet presentation prioritizes one-handed reachability over centered dialogs. |

## Project Structure

### Documentation (this feature)

```text
specs/002-standardize-ui-design/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── modal-presentation.contract.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks command - NOT created by /speckit-plan)
```

### Source Code (repository layout)

```text
app/
├── lib/
│   ├── core/
│   │   └── theme/
│   │       └── app_theme.dart               # Typography & surface tokens
│   └── presentation/
│       ├── widgets/
│       │   ├── standard_bottom_sheet.dart   # Floating card margin & geometry
│       │   ├── confirmation_bottom_sheet.dart # New: Reusable confirmation bottom sheet
│       │   ├── option_picker.dart           # Refactored: Bottom sheet option selector
│       │   ├── settings_helpers.dart        # Updated: SettingsRow (16dp pad, w600/w400)
│       │   ├── confirm_delete_dialog.dart   # Migrated to ConfirmationBottomSheet
│       │   └── add_otp_bottom_sheet.dart    # Migrated paste URI dialog to bottom sheet
│       └── screens/
│           ├── settings_sections/
│           │   ├── appearance_section.dart  # Migrated color picker to bottom sheet
│           │   └── cloud_sync_section.dart  # Migrated disconnect prompt to bottom sheet
│           └── settings_sheets/
│               └── repo_manager_sheet.dart  # Migrated create repo dialog to bottom sheet
└── test/
    └── home_screen_responsive_test.dart     # Responsive & floating margin tests
```

**Structure Decision**: Modular presentation layer enhancement. The reusable floating card container in `standard_bottom_sheet.dart` and `confirmation_bottom_sheet.dart` provides consistent styling for all dialog migrations across settings and home workflows.

## Complexity Tracking

> **No constitution violations. Implementation strictly follows Flutter Material 3 best practices and Clean Architecture.**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| None | N/A | N/A |
