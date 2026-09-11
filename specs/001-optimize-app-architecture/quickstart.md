# Quickstart Validation Guide: Application Optimization

**Feature**: Application Optimization & Architecture Modernization
**Directory**: `specs/001-optimize-app-architecture`
**Status**: Completed (Phase 1)

This guide documents the end-to-end validation scenarios and commands used to verify the performance, architecture, and correctness optimizations.

---

## 1. Prerequisites & Environment Setup

- Flutter SDK `^3.27.0` and Dart SDK `^3.5.0` installed.
- SQLite libraries installed on host system.

Verify toolchain from the repository root:
```bash
cd app
flutter --version
flutter doctor
```

---

## 2. Automated Test & Static Analysis Verification

### Scenario 1: Zero Static Analysis Warnings
Validate that legacy `print` statements and lint issues are eliminated:
```bash
cd app
flutter analyze
```
**Expected Outcome**: `No issues found!` (0 errors, 0 warnings, 0 infos).

### Scenario 2: Comprehensive Test Suite Pass
Validate that all unit, cryptographic, database, and widget tests pass:
```bash
cd app
flutter test
```
**Expected Outcome**: All test suites pass (100% green), specifically:
- `crypto_service_test.dart`: PBKDF2 key derivation and AES-GCM encryption pass.
- `database_test.dart`: `AppDatabase sync queue operations` and account CRUD pass without `repo_id` constraint errors.
- `totp_engine_test.dart`: RFC 4226 HOTP 6-digit/8-digit and RFC 4648 Base32 tests pass.
- `otpauth_parser_test.dart`: URI parsing and normalization pass.
- `widget_test.dart`: App initializes and renders dashboard without hanging or failing to find components.

---

## 3. Interactive Performance & Visual Validation

### Scenario 3: Real-Time Timer & Countdown Smoothness (60fps)
1. Launch the app in profile or release mode:
   ```bash
   cd app
   flutter run --profile
   ```
2. Open Flutter DevTools Performance view:
   ```bash
   flutter run --observatory-port=8888
   ```
3. Add 10+ TOTP accounts to the vault.
4. Observe the dashboard for 60 seconds:
   - Verify countdown progress rings update continuously and smoothly.
   - Verify **zero card re-entry animations** (no flashing or jumping) during 1-second ticks.
   - Verify the UI thread frame time remains under 16ms per frame (solid 60fps).

### Scenario 4: Fast Keystroke Search
1. In the search bar on the home screen, type account names and clear queries.
2. Verify results update immediately with zero lag (<50ms response).
3. Verify proper empty state rendering when no matches exist.

### Scenario 5: Cross-Platform Window Resizing
1. Run the application on macOS, Linux, or Windows desktop:
   ```bash
   cd app
   flutter run -d macos # or linux / windows
   ```
2. Resize the window from compact (400px width) to full desktop width (1400px+).
3. Verify cards stay nicely constrained in an adaptive centered container without text clipping or layout overflow warnings.
