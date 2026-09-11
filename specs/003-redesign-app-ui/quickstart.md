# Quickstart Validation Guide: Modern & Friendly UI Redesign with Foldable Support

**Feature**: `003-redesign-app-ui`  
**Date**: 2026-09-11  
**Status**: Completed  

---

## 1. Prerequisites

- Flutter SDK >= 3.22 (Dart >= 3.4)
- Android Emulator or physical device (Foldable profile such as Samsung Galaxy Z Fold or Pixel Fold recommended for posture testing)
- Active workspace: `/Users/gndev/Projects/dotnet/aosa/app`

---

## 2. Setup & Execution Commands

### Run Automated Static Analysis & Unit Tests
```bash
cd /Users/gndev/Projects/dotnet/aosa/app
flutter analyze
flutter test
```

### Launch on Emulator / Connected Device
```bash
cd /Users/gndev/Projects/dotnet/aosa/app
flutter run -d emulator-5554
```

---

## 3. End-to-End Validation Scenarios

### Scenario A: Compact Mobile Navigation & Friendly Theming
- **Target Posture**: Compact screen (< 600dp width)
- **Validation Steps**:
  1. Launch the app on a standard phone or compact screen.
  2. Verify base canvas presents warm, friendly background (`surfacePrimary`).
  3. Verify bottom `NavigationBar` is visible with 3 tabs: **Accounts**, **Vaults**, and **Settings**.
  4. Tap between tabs and verify smooth animated transitions between screens.
  5. Inspect the FAB (+) button: confirm rounded pill shape and bottom-right alignment above the navigation bar.

### Scenario B: Expressive OTP Card Presentation & 1-Tap Copy
- **Target Flow**: OTP Card display and interaction
- **Validation Steps**:
  1. View the Accounts list containing active OTP accounts.
  2. Verify card styling matches [OtpCardPresentationContract](contracts/otp-card-presentation.contract.md):
     - Soft rounded corners (24dp radius), warm subtle borders.
     - Colorful pastel monogram avatar matching the issuer name.
     - Clear, large OTP digits using `FontFeature.tabularFigures()` formatted with middle dot (e.g. `123 · 456`).
     - Animated countdown circular progress indicator.
  3. Wait until remaining seconds $\le 5$:
     - Confirm timer changes to warm warning amber/orange and code gently pulses.
  4. Tap anywhere on the card:
     - Verify instant haptic feedback.
     - Verify code is copied to clipboard.
     - Verify inline feedback badge morphs from copy icon to checkmark ("Copied!").

### Scenario C: Foldable Unfolded & Tablet Multi-Column Adaptive Layout
- **Target Posture**: Medium/Expanded viewport ($\ge 600dp$ width, e.g. unfolded Galaxy Z Fold or Pixel Fold)
- **Validation Steps**:
  1. On emulator or resizable desktop window, expand width past 600dp.
  2. Verify bottom `NavigationBar` transitions seamlessly to a left-docked `NavigationRail`.
  3. Verify OTP account cards adapt from a 1-column list to a balanced 2-column card grid.
  4. If a physical hinge or fold crease is present (via `MediaQuery.displayFeaturesOf(context)`), verify cards avoid overlapping the center crease.
  5. Tap (+) to open the Add Account modal:
     - Verify modal is presented as a floating card dialog centered on the active screen half with `maxWidth: 640dp`.
     - Verify modal hugs intrinsic content height without large empty vertical voids.

### Scenario D: Light & Dark Theme Contrast
- **Target Flow**: Appearance settings
- **Validation Steps**:
  1. Navigate to Settings and toggle Theme Mode between Light, Dark, and System.
  2. Verify both modes maintain friendly, high-contrast readable typography (minimum 4.5:1 contrast ratio for OTP codes).
  3. Verify dark mode uses warm obsidian/slate background surfaces rather than harsh pure-black voids.
