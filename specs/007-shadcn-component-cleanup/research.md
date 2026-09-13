# Research: shadcn Component Cleanup

**Branch**: `007-shadcn-component-cleanup` | **Phase**: 0 | **Date**: 2026-09-13

## Summary

All unknowns resolved. No NEEDS CLARIFICATION items remain. Key finding: `ShadApp.custom` is already
used at the root in `main.dart`, making all `ShadTheme.maybeOf` fallback patterns immediately
removable without any setup changes.

---

## Decision 1: ShadTheme Root Provider — Already in Place

**Decision**: `ShadApp.custom` + `ShadAppBuilder` is already the root widget in `main.dart`.

**Rationale**: `main.dart` uses `ShadApp.custom(theme:, darkTheme:, appBuilder: ...)` which wraps
content with `ShadTheme`. The inner `MaterialApp` uses `ShadAppBuilder` as its `builder:` parameter.
This provides `ShadTheme` to the entire tree. The `ShadTheme.maybeOf(context)` fallback pattern in
10+ widgets is therefore **already redundant** — it existed before `ShadApp.custom` was added and was
never cleaned up.

**Impact**: No structural changes needed to provide `ShadTheme`. Simply removing the fallback
boilerplate from each widget is sufficient.

**Alternatives considered**:
- Adding a standalone `ShadTheme` widget higher in tree — not needed, `ShadApp.custom` already does this.

---

## Decision 2: Toast System — ShadToaster / ShadSonner

**Decision**: Use `ShadSonner` (the shadcn_ui toaster widget) to replace all `SnackBar` calls.

**Rationale**: The `shadcn_ui` package (v0.56.x) provides `ShadSonner` as the toast container and
`ShadToast` as the toast model. The API is:
- Add `ShadSonner()` as an overlay in the widget tree (typically above `MaterialApp`'s child, or via
  the `builder:` param — but since `ShadApp.custom` is already used, the preferred approach is to
  wrap the `MaterialApp` home with an `Overlay` or use the `ShadApp`'s built-in sonner support).
- Show toasts via `ShadSonner.show(context, builder: (overlay) => ShadToast(...))` or the
  `ShadToaster.show` pattern.
- `ShadToast` accepts: `title`, `description`, `variant` (`ShadToastVariant.primary` /
  `ShadToastVariant.destructive`), `duration`.

**Key implementation note**: `ShadSonner` must be added as an overlay widget. The cleanest place is
inside the `ShadApp.custom` `appBuilder` callback, wrapping the `MaterialApp` in a `Stack` with
`ShadSonner` at the top-level, or using `ShadApp`'s `toaster:` parameter if available in v0.56.x.
A safe universal approach: add `ShadSonner()` to the `MaterialApp`'s `builder:` alongside
`ShadAppBuilder`.

**Alternatives considered**:
- Keeping `SnackBar` — works but inconsistent with shadcn_ui visual language.
- `ShadAlertDialog` — modal, not a toast; wrong UX pattern for transient notifications.

---

## Decision 3: AosaButton Removal Strategy

**Decision**: Replace all `AosaButton` usages with direct `ShadButton` named constructors. The
`isLoading` state maps to `leading: SizedBox(14×14, child: AosaLoadingIndicator(size: 14))`.

**Rationale**: `ShadButton` already has:
- `.primary()` / default constructor
- `.secondary()`
- `.outline()`
- `.destructive()`
- `.ghost()`
- `leading:` widget param (for loading spinner)
- `enabled:` bool param
- `width:`, `height:` params

`AosaButton`'s only value-add is the `isLoading` flag. This can be inlined at each call site by
computing `leading` from a local `isLoading` state variable.

**Alternatives considered**:
- Keeping `AosaButton` but removing the variant/size enums — still a wrapper, doesn't eliminate the problem.
- A simple `buildLoadingButton()` helper — unnecessary given the simplicity of the inline pattern.

---

## Decision 4: AosaSwitch Removal

**Decision**: Delete `AosaSwitch`; replace all usages with `ShadSwitch` directly.

**Rationale**: `AosaSwitch` is a pure pass-through wrapper with zero added logic. `ShadSwitch` has
identical API: `value: bool`, `onChanged: ValueChanged<bool>`. With `ShadTheme` at root, no theme
fallback is needed.

**Usage audit**: `AosaSwitch` is used in:
- `appearance_section.dart` (theme mode toggle)
- `security_section.dart` (PIN/biometric toggles)
- `cloud_sync_section.dart` (sync toggle)

---

## Decision 5: AosaCard Replacement Strategy

**Decision**: Replace `AosaCard` with `ShadCard` + `GestureDetector` inlined at each call site.

**Rationale**: `AosaCard` wraps `ShadCard` in a `GestureDetector` when `onTap`/`onLongPress` is
set, and adds `margin` via `Padding`. This is simple enough to inline at each call site:

```dart
// Before:
AosaCard(onTap: ..., margin: EdgeInsets.all(8), child: ...)

// After:
Padding(
  padding: EdgeInsets.all(8),
  child: GestureDetector(
    onTap: ...,
    behavior: HitTestBehavior.opaque,
    child: ShadCard(padding: ..., child: ...),
  ),
)
```

**Key `ShadCard` params**: `padding`, `backgroundColor`, `radius`, `border` (`ShadBorder.all(...)`).

---

## Decision 6: ThinDivider → ShadSeparator

**Decision**: Replace `ThinDivider` with `ShadSeparator` where exact visual match is achievable, or
keep as `Container(height: 1, margin: EdgeInsets.only(left: 66, right: 16), color: ...)` with
direct `ShadTheme.of(context).colorScheme.border` for color.

**Rationale**: `ShadSeparator` is a horizontal/vertical separator that uses the theme's border
color. However, `ThinDivider` has specific `indent`/`endIndent` margins (default left: 66, right: 16)
for the settings list indent pattern. `ShadSeparator` doesn't have built-in indent params.

**Resolution**: Use `Padding(padding: EdgeInsets.only(left: 66, right: 16), child: ShadSeparator())`
to replicate the indent effect, or keep a simplified `ThinDivider` that removes the theme-fallback
and uses `ShadTheme.of(context)` directly.

**Final choice**: Simplify `ThinDivider` to use `ShadTheme.of(context).colorScheme.border` directly
(removing the fallback), but keep the component for its indent behavior since `ShadSeparator` alone
doesn't support this pattern cleanly.

---

## Decision 7: AosaInput — Keep Simplified

**Decision**: Keep `AosaInput` as a simplified wrapper but remove the `ShadTheme` fallback boilerplate.

**Rationale**: `ShadInputFormField` requires a `ShadForm` ancestor and changes the data flow (form
validation vs. direct controller). The app uses `TextEditingController`-based inputs throughout, so
migrating to `ShadInputFormField` would require refactoring multiple screens' state management.
This is out of scope for a component cleanup refactor.

`AosaInput` provides genuine value: label text, error display with icon, and consolidated API.
The correct fix is to remove the `ShadTheme.maybeOf` fallback and use `ShadTheme.of(context)`
directly since root-level theme is confirmed.

---

## Decision 8: HomeSearchBar — Simplify In Place

**Decision**: Remove `HomeSearchBar` wrapper; inline as `ShadInput` with `leading:` and `trailing:`
directly in `home_screen.dart`.

**Rationale**: `HomeSearchBar` is only 40 lines and only used in one place. It contains no domain
logic beyond a `TextEditingController` clear button and search icon. Inlining reduces widget count.

---

## Decision 9: Dead Material Theme Configs in app_theme.dart

**Decision**: Remove `InputDecorationTheme`, `DialogTheme`, `FilledButtonTheme`,
`ElevatedButtonTheme`, `TextButtonTheme`, `OutlinedButtonTheme` blocks from `_buildTheme()`.

**Rationale**: The app uses no raw `TextField`, `AlertDialog`, `FilledButton`, `ElevatedButton`,
`TextButton`, or `OutlinedButton` widgets. These theme configs are dead configuration. Keep:
- `AppBarTheme` (used by `AppScaffold`)
- `textTheme` (used throughout for `Theme.of(context).textTheme`)
- `bottomSheetTheme` (used by `showModalBottomSheet`)
- `snackBarTheme` (can be removed once SnackBars are replaced)
- `progressIndicatorTheme` (may be used by platform widgets)
- `iconTheme` (used by various widgets)
- `scaffoldBackgroundColor`

---

## Decision 10: aosaBackButton / aosaIconButton — Inline

**Decision**: Inline both functions at their call sites as direct `ShadButton.outline(...)`.

**Rationale**: Both are used in `AosaHeader` as leading/action buttons. Inlining removes a function
call layer while keeping identical behavior. With root-level `ShadTheme`, the fallback wrapping
becomes unnecessary.

---

## Scope Confirmation: Files NOT Touched

The following are confirmed out of scope:
- `StandardBottomSheet` — custom layout, deliberate UX choice
- `ConfirmationBottomSheet` — custom mobile UX, keep bottom-sheet pattern
- `OptionPicker` — custom bottom-sheet selection, keep for mobile UX
- `AosaLoadingIndicator` — no shadcn_ui spinner equivalent
- `VibrantProgressBar` — domain logic wrapper, keep
- `AosaHeader` — no shadcn_ui app bar equivalent
- `SettingsRow`, `SectionHeader`, `IconBox` — no shadcn_ui equivalents
- All other complex widgets (OTP card, PIN widgets, QR scanner, etc.)

---

## Usage Audit Summary

| Component | Files Using It |
|---|---|
| `AosaSwitch` | 3 files |
| `AosaButton` / variants | 12 files |
| `aosaBackButton()` | ~5 files |
| `aosaIconButton()` | ~4 files |
| `AosaCard` | ~6 files |
| `AosaInput` | 4 files |
| `HomeSearchBar` | 1 file |
| `ThinDivider` | ~5 files |
| `AosaConfirmDialog` | 0 files (deprecated, unused) |
| `ShadTheme.maybeOf` fallback | 10+ files |
| `showSnackBar` | 19 calls across 8 files |
