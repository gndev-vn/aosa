# Data Model: shadcn Component Cleanup

**Branch**: `007-shadcn-component-cleanup` | **Date**: 2026-09-13

> This feature is a pure UI refactor with zero data model changes. No new entities are introduced,
> no database migrations are needed, and no backend changes are required.

## Widget Dependency Map

This section documents the current widget relationships and the planned post-refactor state.

---

### Widgets Being Removed

| Widget / Function | Location | Replaced By |
|---|---|---|
| `AosaSwitch` | `aosa_widgets.dart` | `ShadSwitch` (direct) |
| `AosaButton` + `AosaButtonVariant` + `AosaButtonSize` | `aosa_widgets.dart` | `ShadButton` named constructors |
| `aosaBackButton()` | `aosa_widgets.dart` | Inline `ShadButton.outline(...)` |
| `aosaIconButton()` | `aosa_widgets.dart` | Inline `ShadButton.outline(...)` |
| `AosaCard` | `aosa_widgets.dart` | `ShadCard` + `GestureDetector` |
| `AosaConfirmDialog` | `aosa_confirm_dialog.dart` | Delete file (deprecated, unused) |
| `HomeSearchBar` | `home_search_bar.dart` | Inline `ShadInput` in `home_screen.dart` |

### Widgets Being Simplified (boilerplate removed)

| Widget | Location | Change |
|---|---|---|
| `AosaInput` | `aosa_input.dart` | Remove `ShadTheme.maybeOf` fallback; use `ShadTheme.of` |
| `ThinDivider` | `settings_helpers.dart` | Remove `ShadTheme.maybeOf` fallback; use `ShadTheme.of` |
| `SectionHeader` | `settings_helpers.dart` | Remove `ShadTheme.maybeOf` fallback |
| `IconBox` | `settings_helpers.dart` | Remove `ShadTheme.maybeOf` fallback |
| `SettingsRow` | `settings_helpers.dart` | Remove `ShadTheme.maybeOf` fallback |
| `SettingsSelector` | `settings_helpers.dart` | Remove `ShadTheme.maybeOf` fallback |
| `AosaHeader` | `aosa_widgets.dart` | Remove `ShadTheme.maybeOf` fallback |
| `aosa_widgets.dart` private `_resolveShadTheme()` | `aosa_widgets.dart` | Delete function |

### App_theme.dart — Configs to Remove

| Config Block | Reason for Removal |
|---|---|
| `InputDecorationTheme` | No `TextField` / `InputDecoration` in app |
| `DialogTheme` | No `AlertDialog` in app |
| `FilledButtonTheme` | No `FilledButton` in app |
| `ElevatedButtonTheme` | No `ElevatedButton` in app |
| `TextButtonTheme` | No `TextButton` in app |
| `OutlinedButtonTheme` | No `OutlinedButton` in app |
| `snackBarTheme` | Remove after SnackBar → ShadToast migration |

### Configs to Keep in app_theme.dart

| Config Block | Reason to Keep |
|---|---|
| `AppBarTheme` | Used in some screens |
| `textTheme` | Used throughout |
| `bottomSheetTheme` | Used by `showModalBottomSheet` |
| `progressIndicatorTheme` | Platform spinner usage |
| `iconTheme` | Used by icon widgets |
| `scaffoldBackgroundColor` | Used by `Scaffold` |

---

## SnackBar → ShadToast Migration Map

All 19 `ScaffoldMessenger.showSnackBar` calls are replaced with `ShadSonner.show(...)`.

### ShadToast Pattern

```
// Before:
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Message'), duration: Duration(seconds: 2)),
);

// After:
ShadSonner.of(context).show(
  ShadToast(
    title: Text('Message'),
    duration: const Duration(seconds: 2),
  ),
);
```

### Files with SnackBar Calls (19 total)

| File | Call Count | Context |
|---|---|---|
| `home_screen.dart` | 4 | Copy OTP, sync errors, connection error |
| `add_otp_bottom_sheet.dart` | 3 | QR import success/error, manual add error |
| `edit_otp_screen.dart` | 2 | Save success, delete confirm |
| `lock_screen.dart` | 2 | Biometric error, wrong PIN |
| `qr_scanner_screen.dart` | 2 | Scan success, scan error |
| `repo_manager_sheet.dart` | 2 | Repo add/delete success |
| `security_section.dart` | 2 | PIN change success/error |
| `cloud_sync_section.dart` | 1 | Sync toggle |
| `otp_card.dart` | 1 | OTP copied to clipboard |

---

## ShadSonner Setup

`ShadSonner` widget must be accessible in the widget tree. It is placed in `main.dart` within
the `MaterialApp`'s `builder:` callback alongside `ShadAppBuilder`:

```
builder: (context, child) => ShadSonner(
  child: ShadAppBuilder(child: child),
),
```

This makes `ShadSonner.of(context)` available throughout the entire app.

---

## Theme Boilerplate Pattern — Before / After

### Before (in every widget, e.g., `AosaSwitch`):
```
final existingTheme = ShadTheme.maybeOf(context);
final theme = existingTheme ?? _resolveShadTheme(context);
// ... build widget using theme ...
if (existingTheme == null) {
  return ShadTheme(data: theme, child: result);
}
return result;
```

### After (with ShadApp.custom at root):
```
// Access theme directly — always available:
final theme = ShadTheme.of(context);
// No conditional wrapping needed
```
