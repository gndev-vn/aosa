# Phase 1 Data Model: Standardize UI Design & Modal Presentation

**Feature**: `002-standardize-ui-design`
**Date**: 2026-09-11
**Status**: Completed

This feature standardizes UI presentation components and styling tokens. The entities defined below represent the structural configurations and component interfaces across the application presentation layer.

## Entities & Component Models

### 1. `FloatingSheetConfig`
Defines layout and geometry constraints for floating modal bottom sheets.

| Field | Type | Description | Constraints |
|---|---|---|---|
| `horizontalMargin` | `double` | Margin from viewport left and right edges | Default: `16.0`, minimum `12.0` on narrow screens |
| `bottomMargin` | `double` | Baseline margin above navigation bar / safe area | Default: `16.0` |
| `borderRadius` | `double` | Corner radius applied to all 4 corners of floating card | Default: `28.0` |
| `maxWidth` | `double` | Maximum width clamp on tablet/foldable/desktop viewports | Default: `640.0` |

---

### 2. `StandardBottomSheetProps`
Properties for the generalized slide-up form and multi-step sheet container.

| Field | Type | Description |
|---|---|---|
| `title` | `String` | Header title displayed in top bar |
| `child` | `Widget` | Scrollable content body |
| `confirmLabel` | `String?` | Optional primary action button text (e.g. "Save", "Add") |
| `onConfirm` | `VoidCallback?` | Callback triggered when primary action button is tapped |
| `onBack` | `VoidCallback?` | Callback for back navigation button |
| `useSafeArea` | `bool` | Whether to apply safe area insets (default: `true`) |
| `isScrollControlled` | `bool` | Whether sheet adapts to keyboard view insets (default: `false`) |
| `padding` | `EdgeInsetsGeometry?` | Custom inner content padding |

---

### 3. `ConfirmationBottomSheetProps`
Properties for binary confirmation prompts (e.g. Delete Account, Turn Off Cloud Sync).

| Field | Type | Description |
|---|---|---|
| `icon` | `IconData` | Prominent status/warning icon |
| `iconColor` | `Color?` | Foreground icon color (defaults to `cs.onErrorContainer` if destructive) |
| `iconBackgroundColor` | `Color?` | Background badge color (defaults to `cs.errorContainer` if destructive) |
| `title` | `String` | Main confirmation title (e.g. "Delete Account") |
| `message` | `String` | Detailed explanation of action consequences |
| `confirmLabel` | `String` | Primary action button label (default: "Confirm") |
| `cancelLabel` | `String` | Dismissive button label (default: "Cancel") |
| `isDestructive` | `bool` | Whether action is destructive (styles button in error container) |
| `onConfirm` | `VoidCallback` | Callback executed on confirmation |
| `onCancel` | `VoidCallback?` | Optional callback on cancellation (defaults to `Navigator.pop(false)`) |

---

### 4. `OptionPickerProps`
Properties for option selector bottom sheets.

| Field | Type | Description |
|---|---|---|
| `title` | `String` | Header title for selection sheet (e.g. "Select Theme") |
| `options` | `List<(String label, String value)>` | Available options with display label and machine value |
| `selected` | `String` | Currently active value |
| `onSelected` | `ValueChanged<String>` | Callback triggered on item selection |

---

### 5. `SettingsRowProps`
Properties for individual settings rows inside settings cards.

| Field | Type | Description | Styling Rules |
|---|---|---|---|
| `leading` | `Widget` | Leading icon box or badge | Fixed 36x36 container |
| `title` | `String` | Main setting title | `fontSize: 16`, `FontWeight.w600` (semi-bold) |
| `subtitle` | `String?` | Optional explanatory text | `fontSize: 13`, `FontWeight.w400` (regular), full opacity |
| `trailing` | `Widget?` | Switch, selector, or action chevron | Horizontally aligned, minimum 48dp tap target |
| `onTap` | `VoidCallback?` | Optional tap handler for entire row | Triggers ripple/gesture feedback |
| `horizontalPadding` | `double` | Inset from card boundary | Fixed at `16.0` (up from `4.0`) |
