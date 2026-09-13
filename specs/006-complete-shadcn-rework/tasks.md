# Tasks: Unified Shadcn Component Rework & Customizations

**Feature**: `006-complete-shadcn-rework`  
**Input**: Design artifacts from `specs/006-complete-shadcn-rework/` (`spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/ui-contracts.md`, `quickstart.md`)  
**Status**: Ready for Implementation  

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Theme foundation verification and shared design token alignment

- [x] T001 Verify theme tokens, Zinc light/dark palettes, glassmorphism blur tokens, and radius constants in `app/lib/core/theme/app_theme.dart`
- [x] T002 [P] Verify `shadcn_ui` and `lucide_icons_flutter` exports and theme wiring in `app/lib/main.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core primitives and visual enhancement widgets that all user stories depend on

**⚠️ CRITICAL**: Must complete before user story component migrations begin

- [x] T003 [P] Implement frosted glassmorphic header widget `FrostedHeader` with `BackdropFilter` Gaussian blur in `app/lib/presentation/widgets/home_header.dart`
- [x] T004 [P] Implement vibrant multi-stop gradient countdown progress bar `VibrantProgressBar` in `app/lib/presentation/widgets/loading_indicator.dart`
- [x] T005 [P] Update `AosaInput` in `app/lib/presentation/widgets/aosa_input.dart` to directly utilize `ShadInput` with 1px border, focus rings, and inline errors
- [x] T006 [P] Update `AosaButton` and `AosaSwitch` in `app/lib/presentation/widgets/aosa_widgets.dart` to directly expose `ShadButton` variants (primary, outline, secondary, destructive, ghost) and `ShadSwitch`
- [x] T007 Implement adaptive responsive modal container `StandardBottomSheet` in `app/lib/presentation/widgets/standard_bottom_sheet.dart` with docked grab handle on mobile and `maxWidth: 640` constraint on desktop

**Checkpoint**: Core Shadcn primitives and visual enhancers ready for story rollout

---

## Phase 3: User Story 1 - Universal Shadcn Component Architecture (Priority: P1) 🎯 MVP

**Goal**: Replace all bespoke container wrappers with direct `shadcn_ui` primitives across primary components

**Independent Test**: Launch Home, Settings, and Forms; verify that all buttons, inputs, switches, and cards display authentic Shadcn styling with 0 unstyled Material artifacts

- [x] T008 [P] [US1] Refactor `HomeSearchBar` in `app/lib/presentation/widgets/home_search_bar.dart` to use `ShadInput` with leading search icon and trailing clear button
- [x] T009 [P] [US1] Refactor `HomeEmptyState` in `app/lib/presentation/widgets/home_empty_state.dart` using Shadcn typography, Lucide icons, and `ShadButton`
- [x] T010 [P] [US1] Refactor `FabMenu` in `app/lib/presentation/widgets/fab_menu.dart` using high-contrast `ShadButton` actions with white icons and 1px bordered chip labels
- [x] T011 [US1] Refactor `OtpCard` in `app/lib/presentation/widgets/otp_card.dart` to directly use `ShadCard` with 1px Zinc border and subtle drop shadow
- [x] T012 [US1] Refactor `HomeScreen` in `app/lib/presentation/screens/home_screen.dart` to integrate the direct Shadcn primitives and responsive multi-column layout

**Checkpoint**: User Story 1 fully functional and testable as MVP

---

## Phase 4: User Story 2 - Elevated Mobile Customizations & Tactile Feedback (Priority: P2)

**Goal**: Integrate glassmorphic headers, vibrant gradient countdowns, recessed tabular mono OTP badges, and tactile feedback

**Independent Test**: Observe active OTP cards; verify tabular mono alignment, vibrant countdown progress bar with urgent fiery rose shift under 5s, and 1-tap copy haptic badge

- [x] T013 [P] [US2] Implement recessed tabular mono OTP badge with `ShadBadge.secondary` and `FontFeature.tabularFigures()` in `app/lib/presentation/widgets/otp_card.dart`
- [x] T014 [P] [US2] Integrate `VibrantProgressBar` with accent gradient and <5s urgent color state in `app/lib/presentation/widgets/otp_card.dart`
- [x] T015 [US2] Integrate `FrostedHeader` with `BackdropFilter` Gaussian blur on `HomeScreen` in `app/lib/presentation/screens/home_screen.dart`

**Checkpoint**: User Story 2 delivers rich mobile micro-aesthetics on top of the Shadcn base

---

## Phase 5: User Story 3 - Cohesive Sheets, Modals, & Form Controls (Priority: P3)

**Goal**: Refactor all modal sheets, dialogs, and form fields into authentic Shadcn presentation with adaptive responsive behavior

**Independent Test**: Open Add OTP, Edit OTP, and Delete confirmation dialogs; verify adaptive docked bottom drawer with grab handle, `ShadInput` fields, and `ShadButton` actions

- [x] T016 [P] [US3] Refactor `OtpForm` in `app/lib/presentation/widgets/otp_form.dart` using `ShadInput` fields and clean inline validation
- [x] T017 [P] [US3] Refactor `AddOtpBottomSheet` in `app/lib/presentation/widgets/add_otp_bottom_sheet.dart` using `StandardBottomSheet`, action tiles, and primary `ShadButton`
- [x] T018 [P] [US3] Refactor `EditOtpScreen` in `app/lib/presentation/screens/edit_otp_screen.dart` using `ShadInput` fields, `ShadButton` Save/Cancel/Delete actions, and `FrostedHeader`
- [x] T019 [P] [US3] Refactor `ConfirmationBottomSheet` in `app/lib/presentation/widgets/confirmation_bottom_sheet.dart` and `ConfirmDeleteDialog` in `app/lib/presentation/widgets/confirm_delete_dialog.dart` using `ShadDialog` / `ShadCard` surfaces and `ShadButton.destructive`

**Checkpoint**: All modal interactions and forms adhere to authentic Shadcn design

---

## Phase 6: User Story 4 - Unified Settings, Navigation, & Multi-Column Layouts (Priority: P4)

**Goal**: Refactor all settings sections, option pickers, and security screens into grouped `ShadCard` containers

**Independent Test**: Navigate through Settings sections, switch themes and accent colors, and test lock screen; verify grouped card sections, `ShadSwitch` toggles, and responsive wide screen constraints

- [x] T020 [P] [US4] Refactor `SettingsRow`, `SettingsSelector`, and `OptionPicker` in `app/lib/presentation/widgets/settings_helpers.dart` and `app/lib/presentation/widgets/option_picker.dart` to use `ShadCard` grouped rows and `LucideIcons`
- [x] T021 [P] [US4] Refactor `AppearanceSection` in `app/lib/presentation/screens/settings_sections/appearance_section.dart` and `AccentColorPicker` in `app/lib/presentation/widgets/accent_color_picker.dart` to use `ShadCard` surfaces and vibrant accent indicators
- [x] T022 [P] [US4] Refactor `SecuritySection` in `app/lib/presentation/screens/settings_sections/security_section.dart`, `PinSetupDialog` in `app/lib/presentation/widgets/pin_setup_dialog.dart`, and `LockScreen` in `app/lib/presentation/screens/lock_screen.dart` with `ShadSwitch` toggles and Shadcn PIN keypad
- [x] T023 [P] [US4] Refactor `CloudSyncSection`, `CloudConfigSheet`, `RepoManagerSheet`, and `AboutSection` in `app/lib/presentation/screens/settings_sections/` and `app/lib/presentation/screens/settings_sheets/` with `ShadCard` grouped tiles and `ShadButton` actions

**Checkpoint**: End-to-end presentation layer completely unified under Shadcn

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates, static analysis, regression test suite, and live validation

- [x] T024 Run complete test suite `flutter test` and fix any regression issues to achieve 96/96 passing tests
- [x] T025 Run static analysis `flutter analyze` and resolve all linter warnings (0 errors, 0 warnings)
- [x] T026 Validate runnable scenarios on Android emulator (`emulator-5554`) per `specs/006-complete-shadcn-rework/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup (Phase 1)**: No dependencies - starts immediately.
- **Foundational (Phase 2)**: Depends on Phase 1 - **BLOCKS** all user stories.
- **User Story 1 (Phase 3)**: Depends on Phase 2 - MVP milestone.
- **User Story 2 (Phase 4)**: Enhances User Story 1 components with micro-animations & glassmorphism.
- **User Story 3 (Phase 5)**: Depends on Phase 2 - Can run in parallel with US2.
- **User Story 4 (Phase 6)**: Depends on Phase 2 - Can run in parallel with US2/US3.
- **Polish (Phase 7)**: Depends on completion of all desired user stories.

### Parallel Opportunities
- Foundational tasks `T003`, `T004`, `T005`, `T006` can be implemented in parallel.
- Story 1 tasks `T008`, `T009`, `T010` can run in parallel before `T011` / `T012`.
- Story 3 tasks `T016`, `T017`, `T018`, `T019` can run in parallel across separate files.
- Story 4 tasks `T020`, `T021`, `T022`, `T023` can run in parallel across separate settings files.

---

## Implementation Strategy

### MVP First (User Story 1 Only)
1. Complete Setup (Phase 1) & Foundational (Phase 2).
2. Complete User Story 1 (Phase 3).
3. **Validate MVP**: Ensure Home Screen, Search, FAB, and OTP Cards operate with pure Shadcn primitives.

### Incremental Delivery
1. Add User Story 2 (Glassmorphic Header & Vibrant Progress).
2. Add User Story 3 (Adaptive Modal Sheets & Form Fields).
3. Add User Story 4 (Settings Sections & Security Keypad).
4. Run Phase 7 quality gates (`flutter analyze`, `flutter test`, emulator validation).
