# Feature Specification: shadcn Component Cleanup

**Feature Branch**: `007-shadcn-component-cleanup`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "I need to check again throughout the app. Remove any unnecessary custom component. Use default shadcn styled component with color, style"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent UI Component Library (Priority: P1)

As a developer maintaining the AOSA codebase, I want all UI components to use shadcn_ui defaults directly so that the codebase has fewer custom wrappers, less boilerplate, and consistent styling throughout.

**Why this priority**: Eliminating unnecessary wrappers reduces maintenance burden, decreases code complexity, and ensures the app benefits from shadcn_ui's built-in theming and styling consistency. This is the core purpose of the feature.

**Independent Test**: Can be fully tested by verifying that removed custom wrappers no longer exist in the codebase and all affected screens render correctly with identical visual appearance using shadcn_ui components directly.

**Acceptance Scenarios**:

1. **Given** the app uses `AosaSwitch` in multiple places, **When** all instances are replaced with `ShadSwitch`, **Then** all toggle interactions work identically and visual appearance matches the shadcn_ui default styling.
2. **Given** the app uses `AosaButton` with custom variant/size enums, **When** all instances are replaced with `ShadButton` named constructors (`.secondary()`, `.outline()`, `.destructive()`, `.ghost()`) with `leading:` for loading state, **Then** all button interactions and visual states work identically.
3. **Given** the app uses `aosaBackButton()` and `aosaIconButton()` convenience functions, **When** these are inlined as direct `ShadButton.outline(...)` calls at each call site, **Then** all icon buttons work identically.
4. **Given** the app uses `AosaCard` for tap-handling on cards, **When** replaced with `ShadCard` wrapped in `GestureDetector` at each call site, **Then** card tap/long-press interactions work identically.
5. **Given** the deprecated `AosaConfirmDialog` exists, **When** it is deleted, **Then** no compile errors occur (it is already unused).
6. **Given** `ThinDivider` duplicates `ShadSeparator`, **When** all instances are replaced with `ShadSeparator`, **Then** visual dividers render with consistent shadcn_ui styling.

---

### User Story 2 - Root-Level ShadTheme Provider (Priority: P1)

As a developer, I want the `ShadTheme` to be provided at the root of the widget tree so that the pervasive theme-fallback boilerplate pattern is eliminated from every custom widget and screen.

**Why this priority**: The `ShadTheme` fallback pattern currently appears in 10+ widgets and every screen, representing significant boilerplate. Fixing this at the root enables all other component cleanups to be simpler and removes the need for defensive theme resolution.

**Independent Test**: Can be fully tested by confirming the `ShadTheme` is available via `ShadTheme.of(context)` in any widget without the fallback pattern, and all widgets render correctly.

**Acceptance Scenarios**:

1. **Given** the app does not provide `ShadTheme` at the root, **When** a `ShadTheme` (or `ShadApp`) widget is added at the top of the widget tree wrapping all app content, **Then** `ShadTheme.of(context)` resolves successfully in every widget without fallback logic.
2. **Given** 10+ widgets contain the `ShadTheme.maybeOf(context)` fallback pattern, **When** the root-level provider is in place, **Then** all fallback boilerplate is removed from every widget and screen.

---

### User Story 3 - Replace SnackBar with ShadToast (Priority: P2)

As a user, I want notification messages to use the shadcn_ui toast system so that in-app notifications have a consistent look and feel aligned with the rest of the UI.

**Why this priority**: SnackBar is used in 20+ locations across 8+ files. Replacing them with `ShadToast`/`ShadSonner` ensures visual consistency, but is lower priority than eliminating wrapper components and the theme boilerplate since the SnackBars are functional.

**Independent Test**: Can be fully tested by triggering each notification scenario (copy OTP, save, delete, error) and verifying the toast appears with correct styling, message, and dismiss behavior.

**Acceptance Scenarios**:

1. **Given** the app shows a SnackBar when the user copies an OTP code, **When** replaced with `ShadToast`, **Then** a styled toast notification appears with the success message and auto-dismisses.
2. **Given** the app shows error SnackBars on failed operations, **When** replaced with `ShadToast` (destructive variant), **Then** the error toast appears with appropriate destructive styling.
3. **Given** SnackBars are used in home, edit, lock, and QR scanner screens, **When** all are replaced, **Then** zero `ScaffoldMessenger.showSnackBar` calls remain in the codebase.

---

### User Story 4 - Simplify Form Input Pattern (Priority: P2)

As a developer, I want form inputs to use shadcn_ui's built-in form field components so that label and error rendering is handled by the framework rather than custom wrapper code.

**Why this priority**: `AosaInput` wraps `ShadInput` to add label/error display, which `ShadInputFormField` within a `ShadForm` already handles natively. Migrating reduces custom code, though standalone input usage may require a simpler wrapper.

**Independent Test**: Can be fully tested by interacting with all input fields (OTP form, settings inputs, search) and verifying labels display above inputs, validation errors display below, and all input behavior works correctly.

**Acceptance Scenarios**:

1. **Given** forms use `AosaInput` for label and error display, **When** form-based inputs are migrated to `ShadInputFormField` within `ShadForm`, **Then** label and error rendering uses shadcn_ui defaults.
2. **Given** `HomeSearchBar` wraps `ShadInput` with search icon and clear button, **When** inlined as a direct `ShadInput` with `leading:` and `trailing:` parameters, **Then** search functionality works identically.

---

### User Story 5 - Clean Up Dead Theme Configuration (Priority: P3)

As a developer, I want unused Material theme configurations removed from `app_theme.dart` so that the theme file only contains relevant styling and does not mislead future developers.

**Why this priority**: Dead configuration for Material widgets no longer in use (e.g., `InputDecorationTheme`, `DialogTheme`) adds confusion. Lower priority since it has no user-facing impact.

**Independent Test**: Can be fully tested by removing the unused Material theme configs, rebuilding the app, and verifying no visual regressions occur.

**Acceptance Scenarios**:

1. **Given** `app_theme.dart` defines `InputDecorationTheme` for Material `TextField` which is not used, **When** removed, **Then** app builds and runs with no visual change.
2. **Given** `app_theme.dart` defines `DialogTheme` for Material `AlertDialog` which is not used, **When** removed, **Then** app builds and runs with no visual change.

---

### Edge Cases

- What happens when a `ShadToast` is triggered while another toast is already visible? The toast system should queue or stack notifications.
- What happens when the `ShadTheme` at root uses a dynamic seed color and the user changes the accent color? All widgets must reflect the updated theme immediately without restart.
- What happens when `GestureDetector`-wrapped `ShadCard` receives tap events during scroll? Cards should not trigger tap on scroll gestures.
- What happens when `ShadInputFormField` is used outside a `ShadForm` context? Any standalone inputs must still function correctly.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide `ShadTheme` at the root of the widget tree so all descendant widgets can resolve theme data without fallback logic.
- **FR-002**: System MUST replace all `AosaSwitch` usages with direct `ShadSwitch` calls, preserving all existing switch behavior.
- **FR-003**: System MUST replace all `AosaButton` usages with direct `ShadButton` named constructors, using `leading:` parameter for loading state.
- **FR-004**: System MUST inline all `aosaBackButton()` and `aosaIconButton()` calls as direct `ShadButton.outline(...)` at each call site.
- **FR-005**: System MUST replace all `AosaCard` usages with `ShadCard` plus `GestureDetector` wrapping where tap/long-press handlers are needed.
- **FR-006**: System MUST delete the deprecated `AosaConfirmDialog` widget.
- **FR-007**: System MUST replace all `ThinDivider` usages with `ShadSeparator`.
- **FR-008**: System MUST replace all `ScaffoldMessenger.showSnackBar(SnackBar(...))` calls with `ShadToast` or `ShadSonner`.
- **FR-009**: System MUST evaluate and simplify `AosaInput` by migrating form-context usages to `ShadInputFormField` and inlining standalone usages.
- **FR-010**: System MUST inline `HomeSearchBar` as a direct `ShadInput` with `leading:` and `trailing:` parameters, or keep only if it provides substantial domain logic beyond styling.
- **FR-011**: System MUST remove unused Material theme configurations from `app_theme.dart` (e.g., `InputDecorationTheme`, `DialogTheme`, unused `ButtonThemes`).
- **FR-012**: System MUST remove the `ShadTheme.maybeOf(context)` fallback boilerplate from all widgets and screens after root-level theme provider is in place.
- **FR-013**: System MUST preserve all existing user-facing behavior — this is a refactor with zero functional changes.
- **FR-014**: System MUST delete all custom wrapper files that become empty after migration (e.g., `aosa_confirm_dialog.dart`).

### Components to Preserve

The following custom components are **not duplicative** and should be retained:

- **`AosaHeader`** — Custom app bar layout; no shadcn_ui equivalent exists.
- **`AosaLoadingIndicator`** — Spinning loader icon; no shadcn_ui spinner component exists.
- **`VibrantProgressBar`** — Domain-logic wrapper over `ShadProgress` with urgency-based coloring.
- **`SectionHeader`** — Settings section label; no shadcn_ui equivalent.
- **`IconBox`** — Sized icon container; no shadcn_ui equivalent.
- **`SettingsRow`** — Settings list item layout; no shadcn_ui ListTile equivalent.
- **`AppScaffold`** — App shell using Material `Scaffold`; expected usage.
- **`StandardBottomSheet`** — Custom bottom sheet with grabber/header; app-specific UX pattern.
- **`ConfirmationBottomSheet`** — Confirmation dialog via bottom sheet; deliberate mobile UX choice (evaluate if `ShadAlertDialog` is preferred).
- **`OptionPicker`** — Bottom-sheet-based selection; deliberate mobile UX choice (evaluate if `ShadSelect` is preferred).
- **`corner_bracket_painter.dart`** — Custom painter for QR scanner overlay.
- **`overlay_painter.dart`** — Custom painter for QR scanner overlay.
- **`accent_color_picker.dart`** — Domain-specific color picker for theme seed.
- **`fab_menu.dart`** — Floating action button menu.
- **`home_empty_state.dart`** — Empty state illustration.
- **`otp_card.dart`** — Complex OTP display card with countdown animation.
- **`otp_form.dart`** — OTP account creation/edit form.
- **`pin_setup_dialog.dart`** — PIN setup flow.
- **`pin_widgets.dart`** — PIN input UI components.
- **`qr_action.dart`** — QR scan action button.
- **`repo_picker_sheet.dart`** — Repository picker for sync.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero custom wrapper components remain for widgets that have direct shadcn_ui equivalents (target: remove at least 6 wrapper components/functions).
- **SC-002**: Zero instances of the `ShadTheme.maybeOf(context)` fallback boilerplate remain in the codebase after root-level theme provider is added.
- **SC-003**: Zero `ScaffoldMessenger.showSnackBar` calls remain — all notifications use the shadcn_ui toast system.
- **SC-004**: All existing user-facing functionality works identically after the cleanup — zero functional regressions.
- **SC-005**: Net reduction in lines of code across presentation layer (target: 200+ fewer lines from removed wrappers and boilerplate).
- **SC-006**: App builds and all existing tests pass after all changes.
- **SC-007**: Unused Material theme configurations removed from theme file without visual impact.

## Assumptions

- The `shadcn_ui` package (v0.56.3 or compatible) provides all referenced components: `ShadSwitch`, `ShadButton`, `ShadCard`, `ShadSeparator`, `ShadToast`/`ShadSonner`, `ShadInputFormField`, `ShadForm`, `ShadSheet`, `ShadApp`/`ShadTheme`.
- The bottom-sheet UX pattern (for confirmations, option picking) is an intentional design choice and will be preserved rather than replaced with centered dialogs unless explicitly decided otherwise.
- `OptionPicker` and `ConfirmationBottomSheet` are kept as custom components because they serve a deliberate mobile UX pattern, not because they lack shadcn_ui equivalents.
- Existing tests adequately cover the UI interactions being refactored, or manual visual verification is acceptable for this refactor.
- No new features or behavioral changes are introduced — this is purely a code quality and consistency refactor.
