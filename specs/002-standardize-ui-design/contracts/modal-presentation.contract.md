# Component & Modal Presentation Contracts

**Feature**: `002-standardize-ui-design`
**Date**: 2026-09-11
**Status**: Complete

This contract defines the public function signatures, presentation contracts, and migration mapping for all modal interfaces in AOSA.

## 1. Floating Bottom Sheet Launcher

```dart
Future<T?> showSlideBottomSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext) builder,
  bool useSafeArea = true,
  bool isScrollControlled = false,
  bool isDismissible = true,
});
```

### Presentation Invariants
1. **Background**: `showModalBottomSheet` renders with `backgroundColor: Colors.transparent` and `elevation: 0`.
2. **Floating Margin**: Sheet card is wrapped with `Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16))` where `bottomInset` is `max(viewPadding.bottom, viewInsets.bottom)`.
3. **Corner Radius**: Content is wrapped in `Material` with `BorderRadius.circular(28)`.
4. **Max Width Constraint**: Layout enforces `maxWidth: 640dp`, centered horizontally on wide/foldable/desktop screens.

---

## 2. Confirmation Bottom Sheet Contract

```dart
Future<bool> showConfirmationBottomSheet(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
});
```

### Layout Specifications
- **Header**: Centered grabber indicator (36x4dp).
- **Badge**: 56x56dp rounded container with centered 28dp icon.
  - Destructive: `colorScheme.errorContainer` with `colorScheme.onErrorContainer`.
  - Non-destructive: `colorScheme.primaryContainer` with `colorScheme.primary`.
- **Title**: `fontSize: 20`, `fontWeight: FontWeight.w700`, text alignment centered.
- **Message**: `fontSize: 14`, `fontWeight: FontWeight.w400`, color `colorScheme.onSurfaceVariant`, line height 1.4.
- **Actions**: Two full-width or row-based buttons (48dp height):
  - Confirm: `FilledButton` (or destructive equivalent).
  - Cancel: `OutlinedButton` or tonal container.
- **Return Value**: Returns `true` if confirmed, `false` if cancelled or dismissed.

---

## 3. Option Picker Bottom Sheet Contract

```dart
Future<String?> showOptionPickerSheet(
  BuildContext context, {
  required String title,
  required List<(String label, String value)> options,
  required String selected,
});
```

### Layout Specifications
- Uses `StandardBottomSheet(title: title, ...)` with floating card styling.
- Each option item rendered as a 48dp+ tap target with leading check indicator and label.
- Label typography: `fontSize: 16`, `fontWeight: value == selected ? FontWeight.w600 : FontWeight.w400`.
- Selecting an item immediately pops the sheet and returns the selected string value.

---

## 4. Dialog Migration Mapping

All legacy `showDialog` calls are migrated to bottom sheet contracts according to this mapping:

| Existing Location | Legacy Call | New Bottom Sheet Replacement |
|---|---|---|
| `confirm_delete_dialog.dart` | `showDialog<bool>(... Dialog(...))` | `showConfirmationBottomSheet(..., isDestructive: true)` |
| `cloud_sync_section.dart` | `showDialog<bool>(... AlertDialog(...))` | `showConfirmationBottomSheet(..., isDestructive: false)` |
| `settings_helpers.dart` | `showDialog<void>(... OptionPicker(...))` | `showOptionPickerSheet(...)` |
| `appearance_section.dart` | `showDialog<void>(... AccentColorPicker())` | `showSlideBottomSheet(..., builder: (_) => AccentColorSheet())` |
| `repo_manager_sheet.dart` | `showDialog<void>(... AlertDialog(...))` | `showSlideBottomSheet(..., builder: (_) => CreateRepoSheet())` |
| `add_otp_bottom_sheet.dart` | `showDialog<void>(... AosaConfirmDialog())` | `showSlideBottomSheet(..., builder: (_) => PasteUriSheet())` |
