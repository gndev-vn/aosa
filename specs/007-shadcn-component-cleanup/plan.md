# Implementation Plan: shadcn Component Cleanup

**Branch**: `007-shadcn-component-cleanup` | **Date**: 2026-09-13 | **Spec**: [spec.md](file:///D:/Projects/aosa/specs/007-shadcn-component-cleanup/spec.md)

**Input**: Feature specification from `specs/007-shadcn-component-cleanup/spec.md`

## Summary

Audit the entire Flutter app and remove all unnecessary custom UI wrapper components that duplicate
or thin-wrap shadcn_ui equivalents. Replace them with direct `shadcn_ui` component usage. Additionally,
eliminate pervasive `ShadTheme.maybeOf` fallback boilerplate (already redundant since `ShadApp.custom`
is at the root), replace all 19 `SnackBar` calls with `ShadToast`/`ShadSonner`, and remove dead
Material theme configuration from `app_theme.dart`. No new features. No data model changes. Pure
code quality and consistency refactor.

## Technical Context

**Language/Version**: Dart 3.5 / Flutter 3.27

**Primary Dependencies**: `shadcn_ui: ^0.56.3`, `flutter_riverpod: ^2.6.1`, `flutter_animate: ^4.5.0`

**Storage**: N/A — no data layer changes

**Testing**: `flutter test` (widget tests in `app/test/`), `flutter analyze`

**Target Platform**: Android 13+, iOS 18+, iPadOS 18+, Linux, macOS 18+

**Project Type**: Cross-platform mobile + desktop app (Flutter)

**Performance Goals**: No regressions vs. current — same 60fps rendering

**Constraints**: Zero functional changes; all existing behavior preserved; app must compile and pass
all tests after each change group

**Scale/Scope**: 24 widget files, 7 screen files, 19 SnackBar call sites across 8 files

## Constitution Check

*Constitution file contains only template placeholders — no project-specific principles defined.*

**Gate check**: No constitution violations. This is a pure refactor:
- ✅ No new dependencies introduced
- ✅ No data model changes
- ✅ No breaking API changes
- ✅ Reduces complexity (removes wrappers, removes boilerplate)
- ✅ No security implications

## Project Structure

### Documentation (this feature)

```text
specs/007-shadcn-component-cleanup/
├── plan.md              ← this file
├── research.md          ← Phase 0 (complete)
├── data-model.md        ← Phase 1 (complete)
├── quickstart.md        ← Phase 1 (complete)
└── tasks.md             ← Phase 2 (pending /speckit-tasks)
```

### Source Code Layout

```text
app/
├── lib/
│   ├── main.dart                          ← ShadSonner added here
│   ├── core/
│   │   └── theme/
│   │       └── app_theme.dart             ← Dead Material theme configs removed
│   └── presentation/
│       ├── screens/
│       │   ├── home_screen.dart           ← AosaCard→ShadCard, SnackBar→ShadToast, HomeSearchBar inlined
│       │   ├── edit_otp_screen.dart       ← AosaButton→ShadButton, SnackBar→ShadToast
│       │   ├── lock_screen.dart           ← SnackBar→ShadToast
│       │   ├── qr_scanner_screen.dart     ← SnackBar→ShadToast
│       │   ├── settings_screen.dart       ← (minimal changes)
│       │   ├── settings_sections/
│       │   │   ├── appearance_section.dart  ← AosaSwitch→ShadSwitch
│       │   │   ├── security_section.dart    ← AosaSwitch→ShadSwitch, SnackBar→ShadToast
│       │   │   └── cloud_sync_section.dart  ← AosaSwitch→ShadSwitch, SnackBar→ShadToast
│       │   └── settings_sheets/
│       │       ├── repo_manager_sheet.dart  ← SnackBar→ShadToast
│       │       └── cloud_config_sheet.dart  ← AosaButton cleanup
│       └── widgets/
│           ├── aosa_widgets.dart          ← Remove AosaSwitch, AosaButton, AosaCard, aosaBackButton, aosaIconButton
│           ├── aosa_input.dart            ← Remove ShadTheme fallback boilerplate
│           ├── aosa_confirm_dialog.dart   ← DELETE FILE
│           ├── home_search_bar.dart       ← DELETE FILE (inlined in home_screen.dart)
│           ├── settings_helpers.dart      ← Remove ShadTheme fallback from all widgets
│           └── add_otp_bottom_sheet.dart  ← SnackBar→ShadToast
```

**Structure Decision**: Single Flutter app project under `app/`. Backend (`backend/`) is unchanged.
All changes are in `app/lib/presentation/` and `app/lib/core/theme/`.

## Complexity Tracking

No constitution violations to justify.

---

## Implementation Approach

### Change Group 1 — Foundation: ShadSonner Setup

**Files**: `app/lib/main.dart`

Add `ShadSonner` to the `MaterialApp.builder` so toasts are available app-wide:

```dart
builder: (context, child) => ShadSonner(
  child: ShadAppBuilder(child: child),
),
```

**Risk**: Low. Additive only. No existing code changes.
**Validation**: App builds. `ShadSonner.of(context)` accessible from any screen.

---

### Change Group 2 — Remove ShadTheme Fallback Boilerplate

**Files**: `aosa_widgets.dart`, `aosa_input.dart`, `settings_helpers.dart`, and all other widgets
containing `ShadTheme.maybeOf` + conditional `ShadTheme(...)` wrapping.

Pattern to remove in each widget:
- Delete `_resolveShadTheme()` private function (in `aosa_widgets.dart`)
- Replace `ShadTheme.maybeOf(context) ?? _resolveShadTheme(context)` with `ShadTheme.of(context)`
- Remove all `if (existingTheme == null) { return ShadTheme(data: theme, child: result); }` guards
- Remove all `return result;` / `return ShadTheme(...)` conditional branches

**Risk**: Low. `ShadApp.custom` confirms `ShadTheme` is always available. If theme is absent (e.g.,
in tests), `ShadTheme.of` throws — write tests with `ShadApp` wrapper if needed.
**Validation**: `rg "ShadTheme.maybeOf" app/lib --type dart` returns zero results.

---

### Change Group 3 — Remove AosaSwitch

**Files**: `aosa_widgets.dart` (delete class), all 3 consumer files

Delete `AosaSwitch` class from `aosa_widgets.dart`. In each consumer:
- Replace `AosaSwitch(value: v, onChanged: fn)` → `ShadSwitch(value: v, onChanged: fn)`
- Remove `AosaSwitch` import where no longer needed

**Consumer files**: `appearance_section.dart`, `security_section.dart`, `cloud_sync_section.dart`

**Risk**: None. `ShadSwitch` has identical API surface.

---

### Change Group 4 — Remove AosaButton

**Files**: `aosa_widgets.dart` (delete class + enums), all 12 consumer files

Delete `AosaButton`, `AosaButtonVariant`, `AosaButtonSize` from `aosa_widgets.dart`.

For each consumer, map variants:
- `AosaButton(...)` → `ShadButton(...)`
- `AosaButton.secondary(...)` → `ShadButton.secondary(...)`
- `AosaButton.outline(...)` → `ShadButton.outline(...)`
- `AosaButton.destructive(...)` → `ShadButton.destructive(...)`
- `AosaButton.ghost(...)` → `ShadButton.ghost(...)`

Map size enum to explicit height:
- `AosaButtonSize.sm` → `height: 36`
- `AosaButtonSize.md` → `height: 44` (or omit — shadcn default)
- `AosaButtonSize.lg` → `height: 48`

Map `isLoading: true` → `leading: const SizedBox(width: 14, height: 14, child: AosaLoadingIndicator(size: 14))`

**Consumer files**: `edit_otp_screen.dart`, `otp_form.dart`, `add_otp_bottom_sheet.dart`,
`cloud_config_sheet.dart`, `repo_manager_sheet.dart`, `pin_setup_dialog.dart`,
`confirmation_bottom_sheet.dart`, `standard_bottom_sheet.dart`, `home_screen.dart`,
`settings_sections/*.dart`, and others as discovered.

**Risk**: Medium (many files). Do file-by-file with compile check between each.

---

### Change Group 5 — Inline aosaBackButton / aosaIconButton

**Files**: `aosa_widgets.dart` (delete functions), all consumer files

Delete both functions. At each call site, inline as:
```dart
ShadButton.outline(
  width: 36,
  height: 36,
  padding: EdgeInsets.zero,
  onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
  child: Icon(LucideIcons.arrowLeft, size: 16),
)
```

**Risk**: Low. Direct substitution.

---

### Change Group 6 — Remove AosaCard

**Files**: `aosa_widgets.dart` (delete class), all consumer files (~6 files)

Replace at each call site:
```dart
// With tap:
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: onTap,
  onLongPress: onLongPress,
  child: Padding(
    padding: margin ?? EdgeInsets.zero,
    child: ShadCard(padding: padding ?? const EdgeInsets.all(16), child: child),
  ),
)

// Without tap:
Padding(
  padding: margin ?? EdgeInsets.zero,
  child: ShadCard(padding: padding ?? const EdgeInsets.all(16), child: child),
)
```

**Risk**: Low-medium. Verify tap behaviors in home screen OTP cards.

---

### Change Group 7 — Delete AosaConfirmDialog

**Files**: `aosa_confirm_dialog.dart` (delete file)

File is already `@Deprecated` and has zero usages. Simply delete the file and remove any import of it.

**Risk**: None.

---

### Change Group 8 — Inline HomeSearchBar

**Files**: `home_search_bar.dart` (delete file), `home_screen.dart` (inline code)

In `home_screen.dart`, replace `HomeSearchBar(controller: _searchController, ...)` with:
```dart
ShadInput(
  controller: _searchController,
  placeholder: const Text('Search accounts...'),
  leading: Icon(LucideIcons.search, size: 16),
  trailing: ValueListenableBuilder(
    valueListenable: _searchController,
    builder: (context, value, _) => value.text.isEmpty
        ? const SizedBox.shrink()
        : ShadButton.ghost(
            width: 24, height: 24, padding: EdgeInsets.zero,
            onPressed: () => _searchController.clear(),
            child: Icon(LucideIcons.x, size: 14),
          ),
  ),
  onChanged: (v) => setState(() => _searchQuery = v),
)
```

Delete `home_search_bar.dart` and remove its import.

**Risk**: Low. Single usage site.

---

### Change Group 9 — Simplify settings_helpers.dart Widgets

**Files**: `settings_helpers.dart`

For all widgets (`SectionHeader`, `IconBox`, `SettingsRow`, `ThinDivider`, `SettingsSelector`):
- Replace `ShadTheme.maybeOf(context) ?? fallback` with `ShadTheme.of(context)`
- Remove fallback construction and conditional wrapping
- `ThinDivider` uses `ShadTheme.of(context).colorScheme.border` directly

**Risk**: None after Change Group 2 confirms root theme.

---

### Change Group 10 — Replace All SnackBar with ShadToast (19 calls, 8 files)

For each of the 19 `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` calls:

```dart
// Before:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Copied!'), duration: Duration(seconds: 2)),
);

// After:
ShadSonner.of(context).show(
  ShadToast(title: const Text('Copied!'), duration: const Duration(seconds: 2)),
);

// Destructive (errors):
ShadSonner.of(context).show(
  ShadToast.destructive(title: const Text('Error message')),
);
```

**Files** (19 calls): `home_screen.dart` (4), `add_otp_bottom_sheet.dart` (3),
`edit_otp_screen.dart` (2), `lock_screen.dart` (2), `qr_scanner_screen.dart` (2),
`repo_manager_sheet.dart` (2), `security_section.dart` (2), `cloud_sync_section.dart` (1),
`otp_card.dart` (1).

**Risk**: Low-medium. Verify toast appears at correct times. Check that `ShadSonner.of(context)`
doesn't throw in deeply nested widgets (it should propagate through `MaterialApp.builder`).

---

### Change Group 11 — Clean Up app_theme.dart

**Files**: `app/lib/core/theme/app_theme.dart`

Remove from `_buildTheme()`:
- `inputDecorationTheme:` block (lines 229–262)
- `dialogTheme:` block (lines 264–270)
- `filledButtonTheme:` block (lines 302–306)
- `elevatedButtonTheme:` block (lines 307–311)
- `textButtonTheme:` block (lines 312–316)
- `outlinedButtonTheme:` block (lines 317–321)
- `snackBarTheme:` block (lines 283–295) — after SnackBar migration complete

**Risk**: None. Dead configuration — no widgets consume these themes.
**Validation**: App compiles. Visual test of all screens confirms no regressions.

---

### Change Group 12 — Final Cleanup

- Remove all imports no longer used after the above changes (e.g., `import 'aosa_widgets.dart'`
  where only `AosaSwitch` was imported and is now removed)
- Run `flutter analyze` and fix any remaining issues
- Delete empty or single-export files if `aosa_widgets.dart` becomes significantly reduced
  (evaluate — `AosaHeader` and `AosaLoadingIndicator` may stay in the file)

---

## Post-Implementation Validation

Run the full validation suite from [quickstart.md](file:///D:/Projects/aosa/specs/007-shadcn-component-cleanup/quickstart.md):

1. `flutter analyze` — zero errors
2. `flutter test` — all tests pass
3. Manual visual check of all screens in light + dark mode
4. Verify toast notifications appear for all 19 replaced call sites
5. Verify no `ShadTheme.maybeOf` calls remain
6. Verify no `AosaSwitch`, `AosaButton`, `AosaCard`, `HomeSearchBar` references remain
7. Confirm net line reduction ≥ 200 lines
