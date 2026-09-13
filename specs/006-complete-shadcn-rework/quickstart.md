# Phase 1 Quickstart Validation Guide

**Feature**: `006-complete-shadcn-rework`  
**Date**: 2026-09-12  
**Status**: Completed  

---

## 1. Prerequisites & Environment

- **Flutter SDK**: `3.27.x` or later.
- **Dependencies**: `shadcn_ui: ^0.56.3`, `lucide_icons_flutter: ^0.56.3`.
- **Target Device**: Android Emulator (`emulator-5554`) or connected physical device.

---

## 2. Validation Scenarios

### Scenario 1: Automated Regression & Unit Verification
Verify that 100% of existing tests pass and static analysis is completely clean without warnings.

```bash
# Run static analysis
flutter analyze

# Run complete test suite
flutter test
```
**Expected Outcome**:
- `flutter analyze` reports `No issues found!`.
- `flutter test` reports `All tests passed!` (96 / 96 tests passing).

---

### Scenario 2: Light & Dark Mode Cohesion
Verify that both Light and Dark modes render with distinct, high-contrast surfaces, borders, and no washed-out elements.

1. Launch application:
   ```bash
   flutter run -d emulator-5554
   ```
2. Navigate to **Settings** > **Appearance**.
3. Toggle theme mode to **Light**:
   - Verify canvas is warm Zinc-100 (`#F4F4F5`).
   - Verify cards are pure white (`#FFFFFF`) with distinct 1px Zinc-200 (`#E4E4E7`) borders and ambient drop shadows.
   - Verify action buttons and icons are sharp and high-contrast (Zinc-900 with white icons).
4. Toggle theme mode to **Dark**:
   - Verify canvas is deep neutral Zinc-950 (`#09090B`).
   - Verify cards are elevated Zinc-900 (`#18181B`) with 1px Zinc-800 (`#27272A`) borders.
   - Verify text and icons are crisp pure white / zinc-400.

---

### Scenario 3: Direct `shadcn_ui` Component Behavior
Verify that form inputs, buttons, and switches follow authentic Shadcn behaviors:

1. Tap **+** (FAB) > **Manual entry**:
   - Verify sheet docks at the bottom with smooth grab handle and rounded top corners.
   - Verify `ShadInput` fields display static labels above fields, 1px borders, and glowing focus rings when selected.
   - Verify validation errors appear directly below fields in destructive rose text.
2. Tap the primary `ShadButton` at the bottom of the form:
   - Verify button tap exhibits subtle press feedback and submits the form.
3. In **Settings** > **Security**:
   - Verify `ShadSwitch` toggles smoothly with pill-shaped track and instant state persistence.

---

### Scenario 4: Glassmorphic Frosted Header & Vibrant Progress
Verify the custom visual enhancements:

1. Scroll the OTP card list on the **Home Screen**:
   - Verify that as cards scroll beneath the app header, the frosted header (`FrostedHeader`) blurs the background content smoothly (`ImageFilter.blur(sigmaX: 12, sigmaY: 12)`).
2. Observe active OTP countdown bar:
   - Verify smooth multi-stop gradient fill using the active accent color.
   - When timer reaches `<5 seconds`, verify bar transitions smoothly to a vibrant fiery rose gradient warning state.

---

### Scenario 5: Responsive Adaptive Layout
Verify layout adaptation between mobile and tablet/desktop viewports:

1. Run responsive layout test or resize window:
   ```bash
   flutter test test/home_screen_responsive_test.dart
   ```
2. On compact phone viewports (<600dp):
   - Modals render as full-width bottom drawers docked to the bottom.
3. On wide viewports (>=600dp):
   - Modals and content containers constrain to `maxWidth: 640dp` centered popovers, preventing horizontal stretching.
