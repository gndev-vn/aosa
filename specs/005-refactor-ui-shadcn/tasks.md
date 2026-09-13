# Tasks: Full UI/UX Modernization with Shadcn Design System & NDK Fix

**Branch**: `005-refactor-ui-shadcn` | **Date**: 2026-09-12 | **Spec**: [spec.md](file:///d:/Projects/aosa/specs/005-refactor-ui-shadcn/spec.md) | **Plan**: [plan.md](file:///d:/Projects/aosa/specs/005-refactor-ui-shadcn/plan.md)

---

## Phase 1: Setup (Shared Infrastructure & NDK Configuration)

**Purpose**: Fix Android NDK build toolchain and install `shadcn_ui` framework package

- [x] T001 Configure explicit side-by-side NDK `30.0.16248370` in `app/android/app/build.gradle.kts`
- [x] T002 [P] Add `shadcn_ui: ^0.56.3` package dependency in `app/pubspec.yaml`
- [x] T003 Run dependency resolution and update lockfile via `flutter pub get` in `app/pubspec.lock`
- [x] T004 [P] Verify clean Android NDK Gradle evaluation via `flutter build apk --config-only` in `app/android/`

---

## Phase 2: Foundational (Theme & Design Token Infrastructure)

**Purpose**: Establish Shadcn Zinc theme tokens, border radii, and root application wrapper

**⚠️ CRITICAL**: Must complete before any individual view refactor can begin

- [x] T005 Implement Shadcn Modern Zinc theme tokens, border radii, and color palettes in `app/lib/core/theme/app_theme.dart`
- [x] T006 Wrap root application in `ShadApp.material` with `ShadThemeData` in `app/lib/main.dart`
- [x] T007 [P] Add tabular typography helper and monospace styles in `app/lib/core/theme/app_theme.dart`

**Checkpoint**: Foundation ready — `ShadApp` is active and theme tokens are accessible across all widgets.

---

## Phase 3: User Story 1 - Stunning Shadcn Theme & Visual Identity Foundation (Priority: P1) 🎯 MVP

**Goal**: Establish the app-wide scaffold canvas, modern header with Lucide icons, and accent color switching.

**Independent Test**: Launch the application, toggle Light and Dark modes, and select custom accent colors; confirm deep zinc dark backgrounds, 1px subtle borders, and harmonious accent propagation.

### Implementation for User Story 1

- [x] T008 [US1] Create unified Shadcn app scaffold and background canvas in `app/lib/presentation/widgets/app_scaffold.dart`
- [x] T009 [P] [US1] Redesign navigation bar and header with Lucide icons in `app/lib/presentation/widgets/home_header.dart`
- [x] T010 [P] [US1] Update accent color picker with Shadcn pill badge tokens in `app/lib/presentation/widgets/accent_color_picker.dart`
- [x] T011 [US1] Verify Light/Dark mode dynamic theme switching in `app/lib/presentation/providers/settings_provider.dart`

**Checkpoint**: User Story 1 is functional: app scaffold, header, and dynamic accent switching render with a stunning Shadcn aesthetic (MVP Foundation).

---

## Phase 4: User Story 2 - Premium OTP Account Cards & Real-Time Interaction (Priority: P2)

**Goal**: Rebuild the OTP account card with `ShadCard`, monogram avatars, tabular grouped numerals, smooth countdown rings, and 1-tap copy checkmark feedback.

**Independent Test**: View account cards in the home vault; verify jitter-free countdown ticks, tap to copy with instant animated checkmark morphing and haptic pulse, and urgent warning color transitions when timeLeft <= 5s.

### Implementation for User Story 2

- [x] T012 [US2] Rebuild `OtpCard` using `ShadCard` with 12dp radius and 1px border in `app/lib/presentation/widgets/otp_card.dart`
- [x] T013 [P] [US2] Implement tabular spaced verification code formatting (`123 456`) in `app/lib/presentation/widgets/otp_card.dart`
- [x] T014 [P] [US2] Implement smooth circular countdown ring with warning color transition in `app/lib/presentation/widgets/otp_card.dart`
- [x] T015 [US2] Implement 1-tap copy interaction with animated checkmark morphing and haptic pulse in `app/lib/presentation/widgets/otp_card.dart`
- [x] T016 [P] [US2] Update home search filtering bar and empty state with Shadcn styling in `app/lib/presentation/widgets/home_search_bar.dart` and `app/lib/presentation/widgets/home_empty_state.dart`

**Checkpoint**: User Story 2 is functional: OTP card experience is completely elevated with high-clarity tabular codes and 1-tap copy confirmation.

---

## Phase 5: User Story 3 - Sleek Modern Forms, Bottom Sheets, & Action Modals (Priority: P3)

**Goal**: Refactor bottom sheets, input forms, and confirmation dialogs into floating Shadcn cards with rounded corners, `ShadInput`, and `ShadButton`.

**Independent Test**: Open Add Account, paste URI, edit an account, and trigger confirmation sheets; verify 16dp floating margins, smooth focus rings, and clear validation feedback.

### Implementation for User Story 3

- [x] T017 [US3] Refactor `StandardBottomSheet` into a floating Shadcn sheet (`maxWidth: 640dp`, 16dp margins) in `app/lib/presentation/widgets/standard_bottom_sheet.dart`
- [x] T018 [P] [US3] Redesign `AddOtpBottomSheet` with Lucide action tiles (QR scan, URI paste, manual entry) in `app/lib/presentation/widgets/add_otp_bottom_sheet.dart`
- [x] T019 [P] [US3] Refactor `OtpForm` with `ShadInput` fields and focus rings in `app/lib/presentation/widgets/otp_form.dart`
- [x] T020 [US3] Redesign `EditOtpScreen` with Shadcn form layout and action buttons in `app/lib/presentation/screens/edit_otp_screen.dart`
- [x] T021 [P] [US3] Redesign confirmation prompts using `ShadDialog` / `ConfirmationBottomSheet` in `app/lib/presentation/widgets/confirmation_bottom_sheet.dart`

**Checkpoint**: User Story 3 is functional: all input forms, modals, and sheets follow the floating Shadcn card design.

---

## Phase 6: User Story 4 - Cohesive Settings, Security Flow, & Adaptive Navigation (Priority: P4)

**Goal**: Modernize settings sections with grouped `ShadCard` containers, refactor the PIN lock keypad, and provide responsive multi-column layouts on wide displays.

**Independent Test**: Navigate through Appearance, Cloud Sync, and Security settings; lock the app and unlock via the Shadcn PIN keypad; resize window to verify 2-column card reflow.

### Implementation for User Story 4

- [x] T022 [US4] Refactor settings rows and sections (`appearance`, `cloud_sync`, `security`) with grouped `ShadCard` containers in `app/lib/presentation/screens/settings_sections/`
- [x] T023 [P] [US4] Refactor `PinSetupDialog` and `LockScreen` with Shadcn keypad styling in `app/lib/presentation/widgets/pin_setup_dialog.dart` and `app/lib/presentation/screens/lock_screen.dart`
- [x] T024 [US4] Implement adaptive 2-column card grid on wide screens in `app/lib/presentation/screens/home_screen.dart`

**Checkpoint**: User Story 4 is functional: the entire application is completely modernized with zero legacy unstyled screens.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Automated verification, test pass parity, and repository hygiene

- [x] T025 Run `flutter analyze` and resolve all linter warnings under `flutter_lints ^6.0.0` in `app/`
- [x] T026 Run `flutter test` and ensure 100% passing tests (96 / 96) in `app/test/`
- [x] T027 [P] Validate quickstart scenarios and verify clean git status in `specs/005-refactor-ui-shadcn/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Fixes NDK and installs `shadcn_ui` — BLOCKS all downstream tasks.
- **Foundational (Phase 2)**: Establishes `ShadApp` and Zinc tokens — BLOCKS user story implementation.
- **User Story 1 (Phase 3)**: Implements base scaffold, header, and dynamic theming.
- **User Story 2 (Phase 4)**: Rebuilds OTP cards and real-time interaction (depends on US1).
- **User Story 3 (Phase 5)**: Rebuilds floating sheets and forms (depends on US1).
- **User Story 4 (Phase 6)**: Rebuilds settings sections, PIN lock, and responsive grid (depends on US2 & US3).
- **Polish (Phase 7)**: Depends on all user story implementations being complete.

### Parallel Opportunities

- **Setup**: T001 (NDK config) and T002 (pubspec dependency) can run in parallel.
- **Foundational**: T007 (tabular typography) can run in parallel with T006 (ShadApp wrapping).
- **User Story 1**: T009 (home header) and T010 (accent picker) can execute in parallel.
- **User Story 2**: T013 (tabular code formatting), T014 (countdown ring), and T016 (search bar / empty state) can execute in parallel.
- **User Story 3**: T018 (Add sheet), T019 (OtpForm), and T021 (Confirmation dialog) can execute in parallel.
- **User Story 4**: T023 (Pin keypad) can execute in parallel with T022 (Settings sections).

---

## Implementation Strategy

### MVP First (Phases 1, 2, and 3)
1. Fix Android NDK and install `shadcn_ui`.
2. Configure `ShadApp.material` and Zinc theme tokens.
3. Validate basic scaffold and header rendering.

### Incremental Delivery
1. Refactor `OtpCard` (User Story 2) for immediate high-impact daily visual upgrade.
2. Refactor modal sheets and forms (User Story 3) for clean account creation and editing.
3. Refactor settings and lock screen (User Story 4) for 100% complete app-wide consistency.
4. Run static analysis and automated regression tests (Phase 7) to guarantee zero regression.
