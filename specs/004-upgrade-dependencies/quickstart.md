# Quickstart Validation Guide: Dependency Modernization

**Feature**: Dependency Modernization & Package Upgrade
**Directory**: `specs/004-upgrade-dependencies`
**Status**: Completed (Phase 1)

This guide documents the step-by-step validation procedures to verify dependency upgrades, build hygiene, and regression test suites.

---

## 1. Prerequisites & Environment Setup

- Flutter SDK `^3.27.0` (active: `3.47.4`) and Dart SDK `^3.5.0` (active: `3.13.3`).
- Host build environment configured for desktop targets.

Verify toolchain:
```bash
cd app
flutter --version
```

---

## 2. Automated Test & Static Analysis Verification

### Scenario 1: Clean Dependency Resolution
Validate that dependencies resolve cleanly without version conflict errors:
```bash
cd app
flutter pub get
```
**Expected Outcome**: Resolves all dependencies and generates `pubspec.lock` with zero constraint collisions.

### Scenario 2: Static Analysis & Zero Warnings
Validate that upgraded libraries introduce no compilation errors or linter warnings:
```bash
cd app
flutter analyze
```
**Expected Outcome**: `No issues found!` (0 errors, 0 warnings).

### Scenario 3: Regression Test Suite Pass
Validate that all 96 unit, widget, and platform tests pass with 100% green coverage:
```bash
cd app
flutter test
```
**Expected Outcome**: `All tests passed!` (96 / 96 passed).

---

## 3. Multi-Platform Verification

### Scenario 4: Desktop Verification (Windows)
Validate that native C++ desktop plugin bindings compile cleanly:
```bash
cd app
flutter build windows
```
**Expected Outcome**: Build succeeds with zero C++ linker or plugin registration errors.

### Scenario 5: Mobile Configuration Validation (Android / iOS)
Validate Android Gradle setup and plugin registrants:
```bash
cd app
flutter build apk --config-only
```
**Expected Outcome**: Gradle configuration evaluates successfully without dependency tree deadlocks.

---

## 4. Supply Chain Audit & Outdated Metric Verification

### Scenario 6: Verify Outdated Package Reduction
Run `flutter pub outdated` to verify that outdated dependencies have been reduced:
```bash
cd app
flutter pub outdated
```
**Expected Outcome**: Direct dependencies reflect up-to-date status; all upgradable locked packages are refreshed to their target releases.
