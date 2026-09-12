# Tasks: Dependency Modernization & Package Upgrade

**Branch**: `004-upgrade-dependencies` | **Date**: 2026-09-12 | **Spec**: [spec.md](file:///d:/Projects/aosa/specs/004-upgrade-dependencies/spec.md) | **Plan**: [plan.md](file:///d:/Projects/aosa/specs/004-upgrade-dependencies/plan.md)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, dependency baseline verification, and configuration inspection

- [X] T001 Inspect baseline dependencies and package constraints in `app/pubspec.yaml`
- [X] T002 [P] Capture baseline dependency state and outdated inventory via `flutter pub outdated` in `specs/004-upgrade-dependencies/research.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core manifest constraint updates and lockfile resolution that MUST complete before user stories can proceed

**⚠️ CRITICAL**: No user story work can begin until dependency resolution completes cleanly

- [X] T003 Update major dependency constraints (`flutter_secure_storage: ^11.1.1`, `google_fonts: ^8.2.1`, `shimmer: ^4.0.0`) in `app/pubspec.yaml`
- [X] T004 Update minor and patch direct dependency constraints (`connectivity_plus: ^7.3.1`, `dio: ^5.11.1`, `flutter_local_notifications: ^22.3.0`, `local_auth: ^3.0.2`, `mobile_scanner: ^7.4.1`, `path_provider: ^2.1.6`, `sqlite3: ^3.5.2`, `window_manager: ^0.5.2`, `logger: ^2.8.0`, `intl: ^0.20.3`, `image_picker: ^1.2.3`) in `app/pubspec.yaml`
- [X] T005 Run dependency resolution and lock file update via `flutter pub get` in `app/pubspec.lock`

**Checkpoint**: Dependencies resolved and locked cleanly without version collisions. User story verification can now begin.

---

## Phase 3: User Story 1 - Safe Dependency Modernization Without Functional Regression (Priority: P1) 🎯 MVP

**Goal**: Ensure all application capabilities (secure storage, theme, HTTP client, SQLite database, QR scanning, token generation) operate flawlessly with upgraded libraries.

**Independent Test**: Verify that the application compiles, initializes, securely loads and saves PIN/vault keys, renders typography via GoogleFonts, connects to SQLite, and parses OTP URLs identically to baseline.

### Implementation for User Story 1

- [X] T006 [US1] Verify `FlutterSecureStorage` v11 API compatibility and platform options in `app/lib/data/services/auth_service.dart`
- [X] T007 [P] [US1] Verify `FlutterSecureStorage` v11 PIN storage and master key retrieval in `app/lib/data/encryption/crypto_service.dart`
- [X] T008 [P] [US1] Verify `GoogleFonts` v8 font loader methods and fallback typography in `app/lib/core/theme/app_theme.dart`
- [X] T009 [P] [US1] Verify `Dio` v5.11 HTTP client configuration and interceptors in `app/lib/data/api/api_client.dart`
- [X] T010 [P] [US1] Verify `Sqlite3` v3.5 database connection and statement execution in `app/lib/data/database/app_database.dart`
- [X] T011 [P] [US1] Verify `MobileScanner` v7.4 camera controller and lifecycle management in `app/lib/presentation/widgets/add_otp_bottom_sheet.dart`
- [X] T012 [US1] Remediate any deprecated APIs or parameter calls identified across modified files in `app/lib/`

**Checkpoint**: User Story 1 is functional: all updated packages operate cleanly with zero functional regression across core features (MVP ready).

---

## Phase 4: User Story 2 - Automated Verification & Clean Build Quality (Priority: P2)

**Goal**: Ensure zero static analysis warnings under `flutter_lints ^6.0.0`, 100% green test assertions across the 96 automated tests, and multi-platform build sanity.

**Independent Test**: Run `flutter analyze`, `flutter test`, and platform build validations; confirm 0 errors, 0 warnings, 96/96 passing tests, and valid platform registrants.

### Implementation for User Story 2

- [X] T013 [US2] Run `flutter analyze` and resolve any linter issues under `flutter_lints ^6.0.0` in `app/lib/`
- [X] T014 [US2] Run automated test suite `flutter test` and ensure all 96 unit, widget, and integration tests pass in `app/test/`
- [X] T015 [P] [US2] Validate desktop plugin compilation for Windows in `app/windows/`
- [X] T016 [P] [US2] Validate desktop plugin registrations for macOS in `app/macos/Flutter/GeneratedPluginRegistrant.swift`
- [X] T017 [P] [US2] Validate desktop CMake plugin configuration for Linux in `app/linux/flutter/generated_plugins.cmake`
- [X] T018 [P] [US2] Validate mobile Android Gradle build configuration in `app/android/`

**Checkpoint**: User Story 2 is functional: 100% passing test gate, 0 linter warnings, and verified cross-platform plugin configurations.

---

## Phase 5: User Story 3 - Transparent Dependency Audit & Supply Chain Traceability (Priority: P3)

**Goal**: Document the complete upgrade inventory, previous vs upgraded version numbers, SemVer categories, and verified outdated package reduction.

**Independent Test**: Inspect the generated audit report and confirm all updated packages are cataloged with >80% reduction in outdated libraries.

### Implementation for User Story 3

- [X] T019 [US3] Generate dependency upgrade audit and version delta report in `specs/004-upgrade-dependencies/audit-report.md`
- [X] T020 [US3] Verify outdated package reduction metric (>80% reduction) via `flutter pub outdated` in `specs/004-upgrade-dependencies/audit-report.md`

**Checkpoint**: User Story 3 is complete: full supply chain traceability and metrics verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final end-to-end verification and repository hygiene

- [X] T021 Validate end-to-end execution against quickstart scenarios in `specs/004-upgrade-dependencies/quickstart.md`
- [X] T022 [P] Clean up temporary build caches and ensure clean git status in `app/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational completion — verifies core package compatibility.
- **User Story 2 (Phase 4)**: Depends on US1 completion — validates static analysis, tests, and multi-platform gates.
- **User Story 3 (Phase 5)**: Depends on US2 completion — captures final audit report and outdated metrics.
- **Polish (Phase 6)**: Depends on all user stories being complete.

### Parallel Opportunities

- **Setup**: T001 and T002 can run in parallel.
- **User Story 1**: T007 (`crypto_service.dart`), T008 (`app_theme.dart`), T009 (`api_client.dart`), T010 (`app_database.dart`), and T011 (`add_otp_bottom_sheet.dart`) can be verified in parallel as they touch independent files.
- **User Story 2**: T015 (Windows), T016 (macOS), T017 (Linux), and T018 (Android) platform validations can execute in parallel.
- **Polish**: T022 can execute in parallel with documentation verification.

---

## Implementation Strategy

### MVP First (User Story 1 Only)
1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (manifest and lockfile update)
3. Complete Phase 3: User Story 1 (core compatibility verification)
4. **STOP and VALIDATE**: Verify app compiles and runs baseline functionality cleanly (MVP achieved).

### Incremental Delivery
1. Foundational updates lockfile to newest safe packages.
2. US1 ensures no runtime or syntax breaks in application services.
3. US2 locks in 100% green tests and static analysis.
4. US3 documents the supply chain transition.
