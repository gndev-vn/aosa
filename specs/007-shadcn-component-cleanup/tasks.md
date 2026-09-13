# Tasks: shadcn Component Cleanup

**Feature**: `007-shadcn-component-cleanup`
**Branch**: `007-shadcn-component-cleanup`
**Spec**: [spec.md](file:///D:/Projects/aosa/specs/007-shadcn-component-cleanup/spec.md)
**Plan**: [plan.md](file:///D:/Projects/aosa/specs/007-shadcn-component-cleanup/plan.md)
**Total Tasks**: 47

<!--
  IMPLEMENTATION NOTE: This is a pure refactor — zero functional changes.
  App must compile and behave identically after every task group.
  Run `flutter analyze` after every phase to catch regressions early.
-->

---

## Phase 1: Setup (Foundation)

**Purpose**: Wire up ShadSonner so toast notifications are available app-wide before any SnackBar
replacements. This is the only structural change needed — `ShadApp.custom` already provides
`ShadTheme` at root.

- [ ] T001 Add `ShadSonner` wrapper around `ShadAppBuilder` in the `MaterialApp.builder:` callback in `app/lib/main.dart`
- [ ] T002 Verify app compiles and runs after T001 — `flutter run` in `app/` shows no errors

**Checkpoint**: `ShadSonner.of(context)` is now accessible from every widget in the app.

---

## Phase 2: Foundational (Theme Boilerplate Removal)

**Purpose**: Remove the pervasive `ShadTheme.maybeOf` fallback pattern from all widget files.
This unblocks all subsequent widget removals since widgets can now use `ShadTheme.of(context)`
directly. Must complete before any wrapper component removal tasks.

**⚠️ CRITICAL**: Complete this phase before Phase 3. All widget changes depend on confirmed
root-level `ShadTheme` availability.

- [ ] T003 [P] In `app/lib/presentation/widgets/aosa_widgets.dart`: delete the private `_resolveShadTheme()` function and remove all `ShadTheme.maybeOf` / conditional `ShadTheme(...)` wrapping from `AosaHeader`, `aosaBackButton`, `aosaIconButton`, `AosaCard`, `AosaSwitch`, and `AosaButton` — replace with `ShadTheme.of(context)` where theme color values are needed
- [ ] T004 [P] In `app/lib/presentation/widgets/aosa_input.dart`: remove the `ShadTheme.maybeOf` fallback pattern — replace `shadTheme ?? (isDark ? AppTheme.shadThemeDark(...) : AppTheme.shadThemeLight(...))` with `ShadTheme.of(context)` and remove the conditional `ShadTheme(...)` wrapper at the bottom of `build()`
- [ ] T005 [P] In `app/lib/presentation/widgets/settings_helpers.dart`: remove all `ShadTheme.maybeOf` fallback patterns from `SectionHeader`, `IconBox`, `SettingsRow`, `ThinDivider`, and `SettingsSelector` — replace with `ShadTheme.of(context).colorScheme.*` directly
- [ ] T006 Run `flutter analyze` in `app/` — fix any errors from T003–T005 before proceeding

**Checkpoint**: `rg "ShadTheme.maybeOf" app/lib --type dart` returns zero results. All widgets
use `ShadTheme.of(context)` directly.

---

## Phase 3: User Story 1 — Consistent UI Component Library (P1)

**Goal**: Remove all unnecessary custom wrapper components and replace with direct `shadcn_ui`
usage throughout the app.

**Independent Test**: After this phase, `flutter analyze` passes, app builds, and no references to
`AosaSwitch`, `AosaButton`, `AosaCard`, `AosaConfirmDialog`, or `HomeSearchBar` remain in any
consumer file.

### Implementation for User Story 1

#### Group A: Delete AosaSwitch — replace with ShadSwitch (3 consumer files)

- [ ] T007 [P] [US1] In `app/lib/presentation/screens/settings_sections/appearance_section.dart`: replace all `AosaSwitch(value: v, onChanged: fn)` with `ShadSwitch(value: v, onChanged: fn)` and remove `AosaSwitch` import
- [ ] T008 [P] [US1] In `app/lib/presentation/screens/settings_sections/security_section.dart`: replace all `AosaSwitch(...)` with `ShadSwitch(...)` and remove `AosaSwitch` import
- [ ] T009 [P] [US1] In `app/lib/presentation/screens/settings_sections/cloud_sync_section.dart`: replace all `AosaSwitch(...)` with `ShadSwitch(...)` and remove `AosaSwitch` import
- [ ] T010 [US1] In `app/lib/presentation/widgets/aosa_widgets.dart`: delete the entire `AosaSwitch` class

#### Group B: Delete AosaButton + enums — replace with ShadButton named constructors

- [ ] T011 [P] [US1] In `app/lib/presentation/screens/edit_otp_screen.dart`: replace all `AosaButton(...)`, `AosaButton.outline(...)`, `AosaButton.destructive(...)` with the corresponding `ShadButton(...)` / `ShadButton.outline(...)` / `ShadButton.destructive(...)` — map `isLoading: true` to `leading: const SizedBox(width: 14, height: 14, child: AosaLoadingIndicator(size: 14))` and `enabled: !_loading`; map size enums to explicit `height:` values (sm→36, md→44, lg→48)
- [ ] T012 [P] [US1] In `app/lib/presentation/widgets/otp_form.dart`: replace all `AosaButton` usages with `ShadButton` equivalents using the same variant/size/loading mapping as T011
- [ ] T013 [P] [US1] In `app/lib/presentation/widgets/add_otp_bottom_sheet.dart`: replace all `AosaButton` usages with `ShadButton` equivalents
- [ ] T014 [P] [US1] In `app/lib/presentation/screens/settings_sheets/cloud_config_sheet.dart`: replace all `AosaButton` usages with `ShadButton` equivalents
- [ ] T015 [P] [US1] In `app/lib/presentation/screens/settings_sheets/repo_manager_sheet.dart`: replace all `AosaButton` usages with `ShadButton` equivalents
- [ ] T016 [P] [US1] In `app/lib/presentation/widgets/pin_setup_dialog.dart`: replace all `AosaButton` usages with `ShadButton` equivalents
- [ ] T017 [P] [US1] In `app/lib/presentation/widgets/confirmation_bottom_sheet.dart`: replace all `AosaButton` usages with `ShadButton` equivalents
- [ ] T018 [P] [US1] In `app/lib/presentation/widgets/standard_bottom_sheet.dart`: replace all `AosaButton` usages with `ShadButton` equivalents
- [ ] T019 [P] [US1] In `app/lib/presentation/screens/home_screen.dart`: replace all `AosaButton` usages with `ShadButton` equivalents
- [ ] T020 [P] [US1] Search remaining files for any missed `AosaButton` references — run `rg "AosaButton" app/lib --type dart -l` and fix each remaining consumer
- [ ] T021 [US1] In `app/lib/presentation/widgets/aosa_widgets.dart`: delete the `AosaButton` class, `AosaButtonVariant` enum, and `AosaButtonSize` enum (depends on T011–T020 all complete)

#### Group C: Inline aosaBackButton / aosaIconButton

- [ ] T022 [P] [US1] Search for all call sites of `aosaBackButton(context, ...)` — run `rg "aosaBackButton" app/lib --type dart` — and in each file replace the call with an inline `ShadButton.outline(width: 36, height: 36, padding: EdgeInsets.zero, onPressed: ..., child: Icon(LucideIcons.arrowLeft, size: 16))`
- [ ] T023 [P] [US1] Search for all call sites of `aosaIconButton(icon: ..., onPressed: ...)` — run `rg "aosaIconButton" app/lib --type dart` — and in each file replace the call with an inline `ShadButton.outline(width: 36, height: 36, padding: EdgeInsets.zero, onPressed: ..., child: Icon(icon, size: 16, color: ShadTheme.of(context).colorScheme.foreground))`
- [ ] T024 [US1] In `app/lib/presentation/widgets/aosa_widgets.dart`: delete the `aosaBackButton()` function and `aosaIconButton()` function (depends on T022–T023 complete)

#### Group D: Remove AosaCard — replace with ShadCard + GestureDetector

- [ ] T025 [P] [US1] In `app/lib/presentation/screens/home_screen.dart`: replace all `AosaCard(onTap: ..., onLongPress: ..., margin: ..., child: ...)` with `GestureDetector(behavior: HitTestBehavior.opaque, onTap: ..., onLongPress: ..., child: Padding(padding: margin, child: ShadCard(padding: ..., child: ...)))`; cards without tap/longPress use `Padding + ShadCard` directly
- [ ] T026 [P] [US1] Search remaining files for `AosaCard` — run `rg "AosaCard" app/lib --type dart -l` — and apply the same `ShadCard + GestureDetector` pattern in each consumer file
- [ ] T027 [US1] In `app/lib/presentation/widgets/aosa_widgets.dart`: delete the `AosaCard` class (depends on T025–T026 complete)

#### Group E: Delete deprecated / single-use wrappers

- [ ] T028 [P] [US1] Delete the file `app/lib/presentation/widgets/aosa_confirm_dialog.dart` (already `@Deprecated` with zero usages) and remove any lingering import of it in other files (`rg "aosa_confirm_dialog" app/lib --type dart`)
- [ ] T029 [US1] In `app/lib/presentation/screens/home_screen.dart`: inline the `HomeSearchBar` widget — replace `HomeSearchBar(controller: _searchController, onChanged: ...)` with a direct `ShadInput(controller: _searchController, placeholder: Text('Search accounts...'), leading: Icon(LucideIcons.search, size: 16), trailing: ValueListenableBuilder(...clear button...), onChanged: ...)` — mirror the exact behavior of the existing `HomeSearchBar`
- [ ] T030 [US1] Delete the file `app/lib/presentation/widgets/home_search_bar.dart` and remove its import from `home_screen.dart` (depends on T029)

#### Group F: Compile & validate

- [ ] T031 [US1] Run `flutter analyze` in `app/` — fix ALL errors and warnings introduced by T007–T030
- [ ] T032 [US1] Run `flutter test` in `app/` — ensure all existing tests pass

**Checkpoint**: `rg "AosaSwitch|AosaButton|AosaCard|AosaConfirmDialog|HomeSearchBar|aosaBackButton|aosaIconButton" app/lib --type dart` returns zero results outside of `aosa_widgets.dart` definition sites (which are now empty/deleted).

---

## Phase 4: User Story 2 — Root-Level ShadTheme Provider Validated (P1)

**Goal**: Confirm the root-level `ShadTheme` (via `ShadApp.custom`) is correctly providing theme
to all widgets now that boilerplate has been removed.

**Independent Test**: App runs in both light and dark mode with theme switching — all shadcn_ui
components render correctly with no theme-related exceptions.

### Implementation for User Story 2

- [ ] T033 [P] [US2] Run the app in debug mode (`flutter run`) — navigate to every screen and verify all shadcn_ui components (switches, buttons, cards, inputs) render with correct theme colors in light mode
- [ ] T034 [P] [US2] In Settings → Appearance, toggle to dark mode — verify all screens re-render with correct dark-mode shadcn_ui colors
- [ ] T035 [US2] Change accent color in Settings → Appearance — verify `ShadButton` primary, `ShadCard` borders, and `ShadSwitch` active state all update to the new seed color without restart

**Checkpoint**: Theme switching works correctly. No `ShadTheme.maybeOf` fallback patterns remain.
`rg "ShadTheme.maybeOf|_resolveShadTheme" app/lib --type dart` returns zero results.

---

## Phase 5: User Story 3 — Replace SnackBar with ShadToast (P2)

**Goal**: Replace all 19 `ScaffoldMessenger.showSnackBar` calls with `ShadSonner.of(context).show(ShadToast(...))`.

**Independent Test**: Trigger every notification in the app — all show as shadcn-styled toasts,
none as Material SnackBars. `rg "showSnackBar" app/lib --type dart` returns zero results.

### Implementation for User Story 3

- [ ] T036 [P] [US3] In `app/lib/presentation/widgets/otp_card.dart` (1 call): replace `ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied!')))` with `ShadSonner.of(context).show(ShadToast(title: const Text('Copied to clipboard')))` — use destructive variant for error toasts
- [ ] T037 [P] [US3] In `app/lib/presentation/screens/home_screen.dart` (4 calls): replace all `showSnackBar` calls with `ShadSonner.of(context).show(ShadToast(...))` — success toasts use default variant, error/connection-error toasts use `ShadToast.destructive(...)`
- [ ] T038 [P] [US3] In `app/lib/presentation/widgets/add_otp_bottom_sheet.dart` (3 calls): replace all `showSnackBar` calls with `ShadSonner.of(context).show(ShadToast(...))` — success=default, error=destructive
- [ ] T039 [P] [US3] In `app/lib/presentation/screens/edit_otp_screen.dart` (2 calls): replace both `showSnackBar` calls with `ShadSonner.of(context).show(ShadToast(...))`
- [ ] T040 [P] [US3] In `app/lib/presentation/screens/lock_screen.dart` (2 calls): replace both `showSnackBar` calls with `ShadSonner.of(context).show(ShadToast.destructive(...))` — biometric errors use destructive variant
- [ ] T041 [P] [US3] In `app/lib/presentation/screens/qr_scanner_screen.dart` (2 calls): replace both `showSnackBar` calls with `ShadSonner.of(context).show(ShadToast(...))` — scan error=destructive, scan success=default
- [ ] T042 [P] [US3] In `app/lib/presentation/screens/settings_sheets/repo_manager_sheet.dart` (2 calls): replace both `showSnackBar` calls with `ShadSonner.of(context).show(ShadToast(...))`
- [ ] T043 [P] [US3] In `app/lib/presentation/screens/settings_sections/security_section.dart` (2 calls): replace both `showSnackBar` calls with `ShadSonner.of(context).show(ShadToast(...))`
- [ ] T044 [P] [US3] In `app/lib/presentation/screens/settings_sections/cloud_sync_section.dart` (1 call): replace `showSnackBar` with `ShadSonner.of(context).show(ShadToast(...))`
- [ ] T045 [US3] Run `flutter analyze` in `app/` — fix any errors; verify `rg "showSnackBar" app/lib --type dart` returns zero results

**Checkpoint**: All 19 SnackBar calls replaced. Toast notifications appear with shadcn_ui styling
for all user-facing actions across all screens.

---

## Phase 6: User Story 4 — Simplify Form Inputs (P2)

**Goal**: Remove `ShadTheme` fallback from `AosaInput`; confirm it works correctly using
`ShadTheme.of(context)` directly (already done in Phase 2). Evaluate `HomeSearchBar` already
handled in Phase 3.

**Independent Test**: All input fields render label, placeholder, and error text correctly with
shadcn_ui theme in both light and dark modes.

### Implementation for User Story 4

- [ ] T046 [P] [US4] Visually verify all `AosaInput` usages — navigate to Edit OTP screen, Cloud Config sheet, Repo Manager sheet — confirm labels render above inputs, error messages appear below with the alert icon when validation fails, and placeholder text shows in muted color

**Checkpoint**: `AosaInput` works correctly with root-level `ShadTheme.of(context)`.

---

## Phase 7: User Story 5 & Polish — Dead Theme Config Removal (P3)

**Purpose**: Remove dead Material theme configuration from `app_theme.dart`, do final cleanup
of unused imports, and run the full validation suite.

- [ ] T047 [P] In `app/lib/core/theme/app_theme.dart`: remove the following dead config blocks from `_buildTheme()`: `inputDecorationTheme:` (lines 229–262), `dialogTheme:` (lines 264–270), `filledButtonTheme:` (lines 302–306), `elevatedButtonTheme:` (lines 307–311), `textButtonTheme:` (lines 312–316), `outlinedButtonTheme:` (lines 317–321), and `snackBarTheme:` (lines 283–295, only after T045 confirms SnackBar migration complete)
- [ ] T048 Scan all Dart files for unused imports introduced by the refactor — run `flutter analyze` and resolve any "unused import" warnings in: `aosa_widgets.dart`, `home_screen.dart`, `edit_otp_screen.dart`, all `settings_sections/*.dart`, all `settings_sheets/*.dart`, and any other modified files
- [ ] T049 Run full validation suite per `quickstart.md`: `flutter analyze` (zero errors), `flutter test` (all pass), manual smoke test of all screens in light + dark mode
- [ ] T050 Verify net code reduction: count lines in `app/lib/presentation/widgets/` and `app/lib/core/theme/` — target ≥ 200 fewer lines than before refactor
- [ ] T051 [P] Update `docs/04-ui-spec.md` (if it references `AosaButton`, `AosaSwitch`, `AosaCard` custom components) to reflect that these are now direct `ShadButton`, `ShadSwitch`, `ShadCard` usages

**Checkpoint**: All phases complete. App compiles cleanly with zero analyzer errors. All screens
function correctly. No custom wrapper components remain for shadcn_ui-equivalent functionality.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 (T001–T002) — **BLOCKS all Phase 3+ work**
- **Phase 3 (US1)**: Depends on Phase 2 — all Group A/B/C/D/E tasks can run in parallel within the group
- **Phase 4 (US2)**: Depends on Phase 2 complete — runs after Phase 3 validate step (T031–T032)
- **Phase 5 (US3)**: Depends on Phase 1 (ShadSonner in place, T001) — can run in parallel with Phase 3 once T001 is done
- **Phase 6 (US4)**: Depends on Phase 2 (T003–T005) — can overlap with Phase 3
- **Phase 7 (Polish)**: Depends on Phases 3–6 all complete

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 (boilerplate removal) — no dependency on other US
- **US2 (P1)**: Depends on Phase 2 — validates US1 result; run after T031–T032
- **US3 (P2)**: Depends only on T001 (ShadSonner setup) — can start as early as Phase 1 complete
- **US4 (P2)**: Depends on Phase 2 — can run in parallel with US1
- **US5 (P3)**: Depends on US3 complete (to remove `snackBarTheme` config)

### Within Each Group (Phase 3)

- Group A tasks (T007–T009): All [P] — run in parallel
- Group B tasks (T011–T019): All [P] — run in parallel; T020 confirms stragglers; T021 depends on all
- Group C tasks (T022–T023): Both [P] — run in parallel; T024 depends on both
- Group D tasks (T025–T026): Both [P] — run in parallel; T027 depends on both
- Group E tasks (T028–T030): T028 independent; T029 before T030
- T031–T032: Sequential, after all groups complete

### Parallel Opportunities

- T003, T004, T005 (Phase 2): All touch different files — fully parallel
- T007, T008, T009 (Group A): Different files — fully parallel
- T011–T019 (Group B): Different files — fully parallel
- T022, T023 (Group C): Different files — fully parallel
- T036–T044 (US3): All touch different files — fully parallel (after T001)

---

## Parallel Example: User Story 1

```text
# All of these can run simultaneously (different files):
T007: appearance_section.dart — AosaSwitch → ShadSwitch
T008: security_section.dart   — AosaSwitch → ShadSwitch
T009: cloud_sync_section.dart — AosaSwitch → ShadSwitch

T011: edit_otp_screen.dart    — AosaButton → ShadButton
T012: otp_form.dart           — AosaButton → ShadButton
T013: add_otp_bottom_sheet.dart — AosaButton → ShadButton
T014: cloud_config_sheet.dart — AosaButton → ShadButton
T015: repo_manager_sheet.dart — AosaButton → ShadButton
T016: pin_setup_dialog.dart   — AosaButton → ShadButton
T017: confirmation_bottom_sheet.dart — AosaButton → ShadButton
T018: standard_bottom_sheet.dart — AosaButton → ShadButton
T019: home_screen.dart        — AosaButton → ShadButton

T022: all aosaBackButton sites — inline ShadButton.outline
T023: all aosaIconButton sites — inline ShadButton.outline

T025: home_screen.dart        — AosaCard → ShadCard + GestureDetector
T026: other AosaCard consumers — ShadCard + GestureDetector

T028: delete aosa_confirm_dialog.dart (independent)
T029: home_screen.dart        — inline HomeSearchBar content
```

---

## Implementation Strategy

### MVP Scope (User Stories 1 + 2)

1. Complete Phase 1: Add ShadSonner (T001–T002)
2. Complete Phase 2: Remove boilerplate (T003–T006)
3. Complete Phase 3: Remove all wrapper components (T007–T032)
4. Complete Phase 4: Validate theme switching (T033–T035)
5. **STOP and VALIDATE** — core refactor is done, app is cleaner

### Full Delivery

6. Complete Phase 5: Replace SnackBar with ShadToast (T036–T045)
7. Complete Phase 6: Verify AosaInput (T046)
8. Complete Phase 7: Clean up dead theme config + final polish (T047–T051)

### Incremental Safety

After each task group, run `flutter analyze` before moving on. The refactor touches many files — 
catching compile errors early prevents cascading issues. The order above ensures each step is
independently verifiable.

---

## Notes

- [P] tasks = different files, no dependencies on each other — safe to run in parallel
- [USn] label maps task to specific user story for traceability
- **No functional changes** — every replacement must preserve identical behavior
- **Key invariant**: `AosaLoadingIndicator` is kept — no shadcn_ui spinner equivalent exists
- **Key invariant**: `AosaHeader`, `StandardBottomSheet`, `ConfirmationBottomSheet`, `OptionPicker`,
  `SettingsRow`, `SectionHeader`, `IconBox`, `VibrantProgressBar` are all kept — legitimate custom widgets
- Commit after each logical group (Phase 2, each Group in Phase 3, Phase 5, Phase 7)
- Run `quickstart.md` validation scenarios after Phase 7 is complete
