# Implementation Plan: Dependency Modernization & Package Upgrade

**Branch**: `004-upgrade-dependencies` | **Date**: 2026-09-12 | **Spec**: [spec.md](file:///d:/Projects/aosa/specs/004-upgrade-dependencies/spec.md)

**Input**: Feature specification from `specs/004-upgrade-dependencies/spec.md`

## Summary

Modernize, upgrade, and audit the application's third-party dependencies in `app/pubspec.yaml` and `app/pubspec.lock` to resolve 52 outdated locked packages and advance major and minor libraries.

The modernization approach addresses:
1. **Major Constraint Upgrades**: Advance `flutter_secure_storage` to `^11.1.1`, `google_fonts` to `^8.2.1`, and `shimmer` to `^4.0.0`.
2. **Minor & Patch Direct Upgrades**: Upgrade `connectivity_plus` to `^7.3.1`, `dio` to `^5.11.1`, `flutter_local_notifications` to `^22.3.0`, `local_auth` to `^3.0.2`, `mobile_scanner` to `^7.4.1`, `path_provider` to `^2.1.6`, `sqlite3` to `^3.5.2`, `window_manager` to `^0.5.2`, `logger` to `^2.8.0`, `intl` to `^0.20.3`, and `image_picker` to `^1.2.3`.
3. **Constraint Stability & Conflict Isolation**: Retain `flutter_riverpod: ^2.6.1` and `uuid: ^3.0.7` to prevent version collision with `system_tray ^2.0.0` (which enforces `uuid ^3.0.6`) and maintain stability across the 7 application state providers.
4. **Clean Verification Gate**: Maintain zero static analysis warnings under `flutter_lints ^6.0.0`, 100% green pass rate across the 96 automated tests, and multi-platform compilation verification across desktop (Windows, macOS, Linux) and mobile (Android, iOS).

## Technical Context

**Language/Version**: Dart 3.5+ (active: 3.13.3), Flutter 3.27+ (active: 3.47.4)

**Primary Dependencies**: Flutter Riverpod 2.6.1, cryptography 2.7.0, sqlite3 3.5.2, flutter_secure_storage 11.1.1, flutter_animate 4.5.0, google_fonts 8.2.1, connectivity_plus 7.3.1, dio 5.11.1, mobile_scanner 7.4.1, local_auth 3.0.2, flutter_local_notifications 22.3.0, window_manager 0.5.2, system_tray 2.0.0

**Storage**: Local encrypted SQLite database (`sqlite3` / `app_database.dart`), `flutter_secure_storage`

**Testing**: `flutter_test`, `flutter analyze`

**Target Platform**: Cross-platform (Windows, macOS, Linux, Android, iOS)

**Project Type**: Cross-platform Client Application (TOTP Authenticator)

**Performance Goals**: Zero increase in app launch latency; maintain 60fps rendering across all views; zero memory leaks introduced by updated plugin bridges

**Constraints**: Zero compilation errors; zero linter warnings; 100% passing tests (96 / 96); full offline vault operation preserved

**Scale/Scope**: 21 direct dependencies, 60 total updated dependencies across `pubspec.lock`, 63 Dart source files

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Project constitution template contains no unratified blocking rules.
- Design preserves Clean Architecture separation: domain has zero UI dependencies, data layer isolates database/crypto details, presentation layer uses unidirectional Riverpod state.
- Security and offline-first privacy requirements strictly preserved; cryptographic operations unaffected.
- Gate status: **PASSED**.

## Project Structure

### Documentation (this feature)

```text
specs/004-upgrade-dependencies/
├── plan.md              # This implementation plan
├── research.md          # Technical research & architectural decisions (Phase 0)
├── data-model.md        # Entities, validation, and lifecycle state (Phase 1)
├── quickstart.md        # Runnable verification and testing scenarios (Phase 1)
├── contracts/           # Interface contracts (Phase 1)
│   ├── dependency-manifest-contract.md
│   ├── secure-storage-contract.md
│   └── verification-gate-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code Layout (`app/`)

```text
app/
├── pubspec.yaml         # Updated package constraints
├── pubspec.lock         # Locked resolved dependency versions
├── lib/
│   ├── core/
│   │   ├── constants.dart
│   │   ├── platform/app_platform.dart
│   │   └── theme/app_theme.dart             # GoogleFonts 8.2.1 integration
│   ├── data/
│   │   ├── api/api_client.dart              # Dio 5.11.1 integration
│   │   ├── database/app_database.dart       # Sqlite3 3.5.2 integration
│   │   ├── encryption/crypto_service.dart   # FlutterSecureStorage 11.1.1 verification
│   │   ├── repositories/otp_repository_impl.dart
│   │   └── services/
│   │       ├── auth_service.dart            # FlutterSecureStorage 11.1.1 integration
│   │       └── sync_service.dart
│   ├── domain/
│   │   ├── entities/
│   │   └── usecases/
│   │       ├── otpauth_parser.dart          # Uuid 3.0.7 verification
│   │       └── totp_engine.dart
│   └── presentation/
│       ├── providers/                       # Riverpod 2.6.1 state providers
│       ├── screens/
│       └── widgets/                         # MobileScanner 7.4.1 / AddOtpBottomSheet
└── test/                                    # 96 automated tests verifying regression safety
```

**Structure Decision**: Retains existing clean architecture structure inside `app/`, focusing modifications on manifest declarations (`pubspec.yaml`, `pubspec.lock`) and any API/deprecation updates across touched files.

## Complexity Tracking

| Item | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Pinning `uuid: ^3.0.7` & `flutter_riverpod: ^2.6.1` | `system_tray ^2.0.0` has a strict constraint on `uuid: ^3.0.6` | Forcing `uuid: ^4` with dependency overrides risks runtime crashes on desktop and breaks Riverpod SAT solving |
