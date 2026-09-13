# Quickstart Validation Guide: Shadcn UI Modernization & NDK Fix

**Feature**: Full UI/UX Modernization with Shadcn Design System
**Directory**: `specs/005-refactor-ui-shadcn`
**Status**: Completed (Phase 1)

This guide documents validation scenarios to verify the Android NDK build fix, Shadcn UI refactoring, static analysis, and interactive UX flows.

---

## 1. Prerequisites & Environment Setup

- Flutter SDK `^3.27.0` (active: `3.47.4`).
- Android NDK `30.0.16248370` installed side-by-side at `C:\Users\khanh\AppData\Local\Android\Sdk\ndk\30.0.16248370`.

Verify toolchain:
```bash
cd app
flutter --version
```

---

## 2. Android NDK Build Verification

### Scenario 1: Verify Clean NDK Resolution
Validate that Gradle resolves the installed NDK side-by-side without downloading or failing:
```bash
cd app
flutter build apk --config-only
```
**Expected Outcome**: Gradle configuration finishes successfully with zero `Package ndk not found` or `sdkmanager` exit errors.

---

## 3. Automated Test & Static Analysis Verification

### Scenario 2: Zero Static Analysis Warnings
Validate that `shadcn_ui` components and refactored views produce 0 lint warnings:
```bash
cd app
flutter analyze
```
**Expected Outcome**: `No issues found!` (0 errors, 0 warnings).

### Scenario 3: Full Test Suite Pass
Validate that all unit, widget, and responsive integration tests pass:
```bash
cd app
flutter test
```
**Expected Outcome**: All 96 tests pass (100% green).

---

## 4. Interactive UI/UX Verification Scenarios

### Scenario 4: Shadcn Theme & Dark Mode Aesthetics
1. Launch the application:
   ```bash
   cd app
   flutter run
   ```
2. Observe the interface:
   - Deep neutral/zinc dark background (`#09090b`), elevated card surfaces (`#18181b`), and crisp 1px borders (`#27272a`).
   - Clean, refined typography using `GoogleFonts.inter` and `GoogleFonts.jetBrainsMono`.
3. In Settings > Appearance, toggle Light/Dark mode and change accent colors (Emerald, Sky, Violet, Rose, Amber):
   - All cards, borders, buttons, and progress rings update dynamically.

### Scenario 5: OTP Card 1-Tap Copy & Countdown Rings
1. View active OTP cards in the vault.
2. Verify countdown progress rings smoothly animate without card re-rendering flicker.
3. Tap on a verification code:
   - Verify immediate clipboard copy within 50ms.
   - Verify animated checkmark morphing feedback and tactile haptic pulse.
   - Verify restoration to code display after 1.5 seconds.
4. When remaining time is under 5 seconds:
   - Verify progress ring and countdown badge smoothly transition to an urgent warning accent.

### Scenario 6: Floating Bottom Sheets & Form Inputs
1. Tap the "Add Account" button:
   - Verify sheet floats with 16dp margins on all four sides.
   - Verify action tiles (QR scan, paste URI, manual entry) feature Lucide icons and Shadcn styling.
2. Open the manual entry or Edit OTP form:
   - Verify `ShadInput` fields display smooth focus rings, clear labels, and inline error validation.

### Scenario 7: Responsive Multi-Column Layout
1. Resize the window or run on a tablet/wide screen (>600dp width):
   - Verify cards reflow into a clean 2-column grid.
   - Verify modal dialogs remain constrained to a centered `maxWidth: 640dp`.
