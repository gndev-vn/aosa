# Quickstart & Verification Guide: Standardize UI Design & Modal Presentation

**Feature**: `002-standardize-ui-design`
**Date**: 2026-09-11
**Status**: Ready

This guide details the runnable validation scenarios to verify the standardized UI presentation, floating bottom sheet margins, dialog migrations, and settings typography.

---

## Prerequisites

- Flutter 3.x / Dart 3.x installed
- Working directory: `app/`
- Dependencies fetched (`flutter pub get`)

---

## Validation Scenarios

### Scenario 1: Floating Bottom Sheet Margins & Corner Geometry
1. Launch app or pump `StandardBottomSheet` in a widget test with a standard phone viewport (375x812dp).
2. Trigger any bottom sheet (e.g. Add Account or Select Repo).
3. **Verify**:
   - The sheet is surrounded by visible horizontal margins (`16dp` from screen edges).
   - The sheet sits above the bottom safe area/navigation bar with a `16dp` bottom margin.
   - The sheet card renders with rounded corners on all four corners (`radius: 28dp`).
   - Tapping outside the card on the barrier dismisses the sheet cleanly.

### Scenario 2: Dialog-to-BottomSheet Migrations
1. **Delete Account**:
   - In Home screen, tap an account card to view actions, then tap "Delete".
   - **Verify**: A floating confirmation bottom sheet appears (with warning badge, "Delete Account" title, warning text, and red Delete / Cancel buttons). No centered alert dialog appears.
2. **Turn Off Cloud Sync**:
   - Navigate to Settings > Cloud sync, toggle sync off.
   - **Verify**: A floating confirmation bottom sheet appears asking to confirm disconnect.
3. **Create Repo**:
   - Navigate to Settings > Repos, tap "Add".
   - **Verify**: A floating bottom sheet opens with a text field for the repo name.
4. **Theme & Auto-lock Option Pickers**:
   - Navigate to Settings > Appearance > Theme (or Security > Auto-lock).
   - **Verify**: An option picker bottom sheet slides up with options list; selecting an option updates the setting and dismisses the sheet.
5. **Accent Color Picker**:
   - In Settings > Appearance, tap Accent color.
   - **Verify**: A bottom sheet opens displaying the color choices.

### Scenario 3: Settings Row Padding & Typography
1. Open Settings in both Light and Dark themes.
2. Inspect any card (`Appearance`, `Security`, `Cloud sync`, `About`).
3. **Verify**:
   - Leading icons have `16dp` left padding from the card edge.
   - Trailing controls (switches, selector arrows) have `16dp` right padding.
   - Row titles render in semi-bold (`FontWeight.w600`, 16sp).
   - Subtitles render in regular (`FontWeight.w400`, 13sp) with distinct contrast.
   - Thin dividers align precisely with the text baseline (`indent: 66`, `endIndent: 16`).

### Scenario 4: Wide & Foldable Viewport Verification (Galaxy Z Fold, Desktop)
1. Set viewport to `800x800dp` or `1200x800dp`.
2. Open any bottom sheet (`showSlideBottomSheet`, `ConfirmationBottomSheet`).
3. **Verify**:
   - Sheet width is capped at `maxWidth: 640dp`.
   - Sheet is centered horizontally with margins to viewport edges.
   - Sheet hugs intrinsic content height docked towards the bottom with safe area padding.
   - No vertical stretching or empty void on top of the sheet.

---

## Automated Test Commands

Run the comprehensive test suites from `app/`:

```bash
cd app
# 1. Run all widget and responsive tests
flutter test test/home_screen_responsive_test.dart

# 2. Run the full test suite
flutter test

# 3. Verify static analysis has zero warnings
flutter analyze
```
