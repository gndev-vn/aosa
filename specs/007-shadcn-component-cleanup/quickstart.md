# Quickstart Validation Guide: shadcn Component Cleanup

**Branch**: `007-shadcn-component-cleanup` | **Date**: 2026-09-13

## Prerequisites

- Flutter SDK ^3.27 installed and on PATH
- All dependencies installed: `flutter pub get` in `app/`
- App can build and run before starting: `flutter run` from `app/`

## Validation Scenarios

After completing the implementation, validate each scenario below.

---

### Scenario 1: ShadTheme Boilerplate Removal Verified

**Verify by code inspection**:

```bash
# Should return 0 results after cleanup
rg "ShadTheme.maybeOf" app/lib --type dart
rg "_resolveShadTheme" app/lib --type dart
```

**Expected**: No matches in any file.

---

### Scenario 2: AosaSwitch Removed

**Verify by code inspection**:

```bash
rg "AosaSwitch" app/lib --type dart
```

**Expected**: Only definition site should be gone — zero results.

**Visual validation**: Run app, navigate to Settings → Security. Toggle PIN enable switch. Verify
toggle animates correctly and state saves.

---

### Scenario 3: AosaButton Removed

**Verify by code inspection**:

```bash
rg "AosaButton\|AosaButtonVariant\|AosaButtonSize" app/lib --type dart
```

**Expected**: Zero results.

**Visual validation**:
1. Home screen — FAB menu opens correctly (ghost/outline buttons)
2. Edit OTP screen — Save button shows loading spinner when tapped
3. QR scanner — action buttons respond to taps
4. Settings sheets — destructive delete buttons are red

---

### Scenario 4: AosaCard Removed

**Verify by code inspection**:

```bash
rg "AosaCard" app/lib --type dart
```

**Expected**: Zero results.

**Visual validation**:
1. Home screen OTP list — cards display correctly with rounded corners
2. Tapping a card copies OTP (tap handler works)
3. Long-pressing a card triggers the edit menu (long-press handler works)

---

### Scenario 5: AosaConfirmDialog Deleted

**Verify**:

```bash
# File should not exist
ls app/lib/presentation/widgets/aosa_confirm_dialog.dart
```

**Expected**: File not found.

---

### Scenario 6: ThinDivider Simplified

**Verify**: `ThinDivider.build()` uses `ShadTheme.of(context).colorScheme.border` with no fallback.

**Visual validation**: Navigate to Settings. Dividers between rows should be visible and
theme-consistent (lighter in light mode, darker in dark mode).

---

### Scenario 7: HomeSearchBar Inlined

**Verify**:

```bash
rg "HomeSearchBar" app/lib --type dart
```

**Expected**: Zero results. `home_search_bar.dart` file deleted.

**Visual validation**: Home screen search bar appears, search icon shows on left, clear button
appears when text is entered.

---

### Scenario 8: SnackBar Replaced with ShadToast

**Verify by code inspection**:

```bash
rg "showSnackBar\|SnackBar(" app/lib --type dart
```

**Expected**: Zero results (or only in `app_theme.dart`'s now-removed `snackBarTheme` block).

**Visual validation**:
1. Home screen → tap an OTP card → toast appears "Copied to clipboard"
2. QR scanner → scan an invalid QR → error toast appears in destructive (red) style
3. Settings → change PIN → success toast appears
4. Lock screen → enter wrong PIN → error toast appears

---

### Scenario 9: Dead Material Theme Configs Removed

**Verify by code inspection in `app_theme.dart`**:
- `InputDecorationTheme` block — removed
- `DialogTheme` block — removed
- `FilledButtonTheme` block — removed
- `ElevatedButtonTheme` block — removed
- `TextButtonTheme` block — removed
- `OutlinedButtonTheme` block — removed
- `snackBarTheme` block — removed (after SnackBar migration)

**Build validation**: App compiles cleanly after removals.

---

### Scenario 10: Full App Build & Run

```bash
cd app
flutter analyze
flutter test
flutter run
```

**Expected**:
- `flutter analyze` — zero errors, zero warnings (or same pre-existing ones)
- `flutter test` — all tests pass
- `flutter run` — app launches without crash, all screens load

---

### Scenario 11: Theme Switching Works

With app running:
1. Go to Settings → Appearance
2. Toggle Light / Dark / System theme
3. **Expected**: All screens switch theme correctly, including all shadcn_ui components
4. Change accent color
5. **Expected**: All ShadButton, ShadCard, ShadSwitch, and ShadInput components update color

---

### Scenario 12: Net Code Reduction

```bash
# Count lines before and after (run before starting implementation to capture baseline)
find app/lib/presentation/widgets -name "*.dart" | xargs wc -l | tail -1
find app/lib/core/theme -name "*.dart" | xargs wc -l | tail -1
```

**Expected**: Net reduction of 200+ lines across `presentation/widgets/` and `core/theme/`.

---

## Quick Reference — Replacement Patterns

See [data-model.md](file:///D:/Projects/aosa/specs/007-shadcn-component-cleanup/data-model.md)
for full before/after code patterns.

### AosaButton → ShadButton

```dart
// Before:
AosaButton(onPressed: ..., isLoading: _loading, child: Text('Save'))
AosaButton.destructive(onPressed: ..., child: Text('Delete'))

// After:
ShadButton(
  onPressed: _loading ? null : ...,
  enabled: !_loading,
  leading: _loading ? const SizedBox(14, 14, child: AosaLoadingIndicator(size: 14)) : null,
  child: const Text('Save'),
)
ShadButton.destructive(onPressed: ..., child: const Text('Delete'))
```

### AosaSwitch → ShadSwitch

```dart
// Before:
AosaSwitch(value: _val, onChanged: (v) => setState(() => _val = v))

// After:
ShadSwitch(value: _val, onChanged: (v) => setState(() => _val = v))
```

### SnackBar → ShadToast

```dart
// Before:
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied!')));

// After:
ShadSonner.of(context).show(ShadToast(title: const Text('Copied!')));
```
