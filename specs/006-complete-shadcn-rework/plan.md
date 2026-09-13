# Implementation Plan: Unified Shadcn Component Rework & Customizations

**Branch**: `006-complete-shadcn-rework` | **Date**: 2026-09-12 | **Spec**: [spec.md](file:///d:/Projects/aosa/specs/006-complete-shadcn-rework/spec.md)

**Input**: Feature specification from `specs/006-complete-shadcn-rework/spec.md`

## Summary

Refactor every UI component, control, and modal in the application to use direct `shadcn_ui` primitives (`ShadButton`, `ShadInput`, `ShadCard`, `ShadSwitch`, `ShadBadge`, `ShadProgress`, `ShadDialog`, `ShadSheet`), permanently eliminating all bespoke container wrappers and mixed Material design artifacts. Enhance the experience with glassmorphic frosted headers, vibrant gradient countdown progress bars, glowing accent focus rings, and an adaptive responsive modal model (docked bottom drawer on mobile, centered popover on wide screens).

## Technical Context

**Language/Version**: Dart 3.6+ / Flutter 3.27+  
**Primary Dependencies**: `shadcn_ui: ^0.56.3`, `lucide_icons_flutter: ^0.56.3`, `flutter_riverpod: ^2.6.1`  
**Storage**: `flutter_secure_storage`, `sqflite` (untouched, preserved)  
**Testing**: `flutter test` (96 unit, widget, and responsive layout tests), `flutter analyze`  
**Target Platform**: Android (primary target `emulator-5554`), iOS, Desktop  
**Project Type**: Mobile Authenticator App  
**Performance Goals**: 60fps continuous countdown animations without card redraw jitter; <50ms copy-to-clipboard response  
**Constraints**: Zero regression on existing 96 automated tests; 100% clean static analysis (`flutter analyze`); pure Shadcn component architecture with zero leftover unstyled Material widgets  
**Scale/Scope**: Entire presentation layer: 26 widgets across `app/lib/presentation/widgets/` and all screens (`home_screen.dart`, `edit_otp_screen.dart`, `lock_screen.dart`, settings sections & sheets)  

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate / Principle | Status | Notes |
| :--- | :--- | :--- |
| **I. Library-First & Modularity** | **PASS** | Reusable Shadcn primitives replace ad-hoc widget wrappers, centralized in clean UI module hierarchy. |
| **II. Test-First & Zero Regression** | **PASS** | All 96 existing unit, encryption, widget, and responsive layout tests must remain green. |
| **III. Simplicity & No Mixed Paradigms** | **PASS** | Eliminates dual-paradigm hybrid widgets; standardizes on authentic `shadcn_ui` primitives. |
| **IV. Observability & Feedback** | **PASS** | Instant tactile haptic feedback, animated copy states, and urgent countdown warning transitions. |

## Project Structure

### Documentation (this feature)

```text
specs/006-complete-shadcn-rework/
├── spec.md              # Feature specification with clarifications
├── plan.md              # This implementation plan
├── research.md          # Phase 0 decisions & technical evaluations
├── data-model.md        # Phase 1 component entities & states
├── contracts/
│   └── ui-contracts.md  # Component interface contracts
├── quickstart.md        # Runnable validation scenarios
└── checklists/
    └── requirements.md  # Quality validation checklist
```

### Source Code (`app/lib/`)

```text
app/lib/
├── core/
│   └── theme/
│       └── app_theme.dart               # Modern Zinc light/dark palette, glassmorphism tokens, typography
├── presentation/
│   ├── screens/
│   │   ├── home_screen.dart             # FrostedHeader, adaptive grid layout, ShadCard list
│   │   ├── edit_otp_screen.dart         # ShadInput form fields, ShadButton actions
│   │   ├── lock_screen.dart             # Shadcn PIN pad, biometric unlock trigger
│   │   ├── settings_sections/
│   │   │   ├── appearance_section.dart  # Theme & accent color picker using ShadCard
│   │   │   ├── security_section.dart    # ShadSwitch toggles, PIN setup triggers
│   │   │   ├── cloud_sync_section.dart  # Cloud sync configuration tiles
│   │   │   └── about_section.dart       # Version & diagnostics badges
│   │   └── settings_sheets/
│   │       ├── cloud_config_sheet.dart  # ShadInput fields, ShadButton triggers
│   │       └── repo_manager_sheet.dart  # Repository management list & inputs
│   └── widgets/
│       ├── home_header.dart             # Frosted glassmorphic app bar with BackdropFilter
│       ├── home_search_bar.dart         # ShadInput search field with clear action
│       ├── home_empty_state.dart        # Shadcn empty vault graphic & CTA
│       ├── otp_card.dart                # Direct ShadCard, recessed tabular mono badge, VibrantProgressBar
│       ├── fab_menu.dart                # High-contrast ShadButton speed dial actions
│       ├── standard_bottom_sheet.dart   # Adaptive modal drawer with grab handle & maxWidth constraint
│       ├── confirmation_bottom_sheet.dart # ShadDialog & ShadSheet confirmation prompts
│       ├── aosa_input.dart              # Standardized ShadInput adapter preserving existing form bindings
│       ├── aosa_widgets.dart            # Unified ShadButton & ShadSwitch primitives
│       ├── accent_color_picker.dart     # Curated accent palette picker with active ring
│       └── settings_helpers.dart        # Grouped ShadCard settings rows & select badges
```

**Structure Decision**: Retain existing file boundaries to minimize test breakage and import churn, while refactoring the internal implementation of each widget to directly use `shadcn_ui` primitives and the approved glassmorphic/vibrant customizations.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
| :--- | :--- | :--- |
| *None* | All changes directly simplify the architecture by replacing bespoke custom containers with unified `shadcn_ui` primitives. | Bespoke containers resulted in visual inconsistencies and mixed design paradigms. |
