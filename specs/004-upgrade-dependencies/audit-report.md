# Dependency Modernization Audit Report

**Feature**: Dependency Modernization & Package Upgrade
**Directory**: `specs/004-upgrade-dependencies`
**Date**: 2026-09-12
**Status**: Completed

---

## 1. Executive Summary

A comprehensive dependency modernization was performed on the `aosa` Flutter application to resolve supply chain debt, eliminate security vulnerabilities, and upgrade outdated third-party libraries across direct and transitive dependencies.

- **Direct Dependencies Outdated Before**: 16 packages
- **Direct Dependencies Outdated After**: 2 packages (intentionally pinned: `flutter_riverpod` and `uuid`)
- **Direct Outdated Reduction**: **87.5% reduction** (exceeds the 80% target criterion SC-004)
- **Total Packages Refreshed in Lockfile**: **60 packages**
- **Static Analysis Gate**: **Passed with 0 errors and 0 warnings** under `flutter_lints ^6.0.0`
- **Automated Regression Suite**: **100% pass rate (96 / 96 tests passed)**

---

## 2. Direct Dependencies Upgrade Inventory

| Package | Prior Version | Upgraded Version | SemVer Delta | Category & Release Highlights |
|---|---|---|:---:|---|
| `flutter_secure_storage` | `^10.3.1` (10.3.1) | `^11.1.1` (11.1.1) | **Major** | Native security bridge modernization; enhanced platform keychain accessibility on macOS/iOS and Windows DPAPI |
| `google_fonts` | `^6.2.1` (6.3.3) | `^8.2.1` (8.2.1) | **Major** | Enhanced asset fallback caching and font loader performance |
| `shimmer` | `^3.0.0` (3.0.0) | `^4.0.0` (4.0.0) | **Major** | Shimmer animation modernizations |
| `connectivity_plus` | `^7.1.1` (7.1.1) | `^7.3.1` (7.3.1) | Minor | Network change event stream reliability and desktop platform fixes |
| `dio` | `^5.7.0` (5.9.2) | `^5.11.1` (5.11.1) | Minor | HTTP connection pooling, stream handling, and security advisories |
| `flutter_local_notifications` | `^22.0.0` (22.0.0) | `^22.3.0` (22.3.0) | Minor | Platform notification channel handling and permission callbacks |
| `local_auth` | `^3.0.1` (3.0.1) | `^3.0.2` (3.0.2) | Patch | Biometric authentication reliability on Android and macOS |
| `mobile_scanner` | `^7.2.0` (7.2.0) | `^7.4.1` (7.4.1) | Minor | Camera controller lifecycle stabilization and barcode format parsing |
| `path_provider` | `^2.1.0` (2.1.5) | `^2.1.6` (2.1.6) | Patch | Platform directory path resolution fixes |
| `sqlite3` | `^3.3.3` (3.3.3) | `^3.5.2` (3.5.2) | Minor | SQLite FFI native binding memory management and query performance |
| `window_manager` | `^0.5.1` (0.5.1) | `^0.5.2` (0.5.2) | Patch | Desktop window resize, minimize, and focus event dispatching |
| `logger` | `^2.5.0` (2.7.0) | `^2.8.0` (2.8.0) | Minor | PrettyPrinter formatting improvements |
| `intl` | `^0.20.2` (0.20.2) | `^0.20.3` (0.20.3) | Patch | Unicode locale and pluralization fixes |
| `image_picker` | `^1.1.2` (1.2.2) | `^1.2.3` (1.2.3) | Patch | Platform image selection bridge fixes |

---

## 3. Invariant & Pinned Dependencies

Two direct dependencies were retained on their current versions to avoid unsolvable transitive graph collisions:

| Package | Retained Version | Constraint Reason |
|---|---|---|
| `system_tray` | `^2.0.0` | Latest release published on pub.dev. Depends strictly on `uuid: ^3.0.6`. |
| `uuid` | `^3.0.7` | Fulfills `system_tray ^2.0.0` constraint requirement. |
| `flutter_riverpod` | `^2.6.1` | Riverpod 3.x enforces `uuid: ^4.5.1`, colliding with `system_tray`. Retaining 2.6.1 (LTS) preserves 100% compatibility across the 7 application `StateNotifierProvider` architectures. |

---

## 4. Transitive Dependencies Refreshed

46 transitive packages in `app/pubspec.lock` were refreshed to their newest compatible releases, including:
- `clock`: 1.1.2 → 1.1.3
- `code_assets`: 1.2.1 → 2.0.0
- `cross_file`: 0.3.5+2 → 0.3.5+5
- `dbus`: 0.7.13 → 0.7.15
- `dio_web_adapter`: 2.1.2 → 2.2.2
- `file_selector_linux`: 0.9.4 → 0.9.4+1
- `file_selector_macos`: 0.9.5 → 0.9.5+1
- `file_selector_windows`: 0.9.3+5 → 0.9.3+6
- `flutter_local_notifications_platform_interface`: 12.0.0 → 12.2.0
- `flutter_local_notifications_windows`: 3.1.0 → 3.1.1
- `flutter_secure_storage_darwin`: 0.3.2 → 0.4.2
- `flutter_secure_storage_linux`: 3.0.1 → 3.0.3
- `flutter_secure_storage_platform_interface`: 2.0.1 → 2.1.0
- `glob`: 2.1.3 → 2.2.0
- `hooks`: 2.0.2 → 2.2.0
- `image_picker_android`: 0.8.13+19 → 0.8.13+23
- `image_picker_ios`: 0.8.13+6 → 0.8.13+7
- `jni`: 1.0.0 → 1.0.3
- `jni_flutter`: 1.0.1 → 1.0.3
- `jni_util`: Added 1.0.0
- `local_auth_android`: 2.0.9 → 2.0.10
- `local_auth_darwin`: 2.0.3 → 2.0.4
- `local_auth_windows`: 2.0.1 → 2.0.2
- `mime`: 2.0.0 → 2.1.0
- `native_toolchain_c`: 0.19.1 → 0.19.4
- `objective_c`: 9.4.1 → 9.6.0
- `package_config`: 2.2.0 → 3.0.0
- `path_provider_linux`: 2.2.1 → 2.2.2
- `path_provider_platform_interface`: 2.1.2 → 2.1.3
- `platform`: 3.1.6 → 3.2.0
- `process`: Added 5.0.6
- `pub_semver`: 2.2.0 → 2.2.1
- `record_use`: 0.6.0 → 1.1.1
- `screen_retriever`: 0.2.1 → 0.2.2
- `screen_retriever_linux`: 0.2.1 → 0.2.2
- `screen_retriever_macos`: 0.2.1 → 0.2.2
- `screen_retriever_platform_interface`: 0.2.1 → 0.2.2
- `screen_retriever_windows`: 0.2.1 → 0.2.2
- `stack_trace`: 1.12.1 → 1.12.2
- `timezone`: 0.11.0 → 0.11.1
- `vm_service`: 15.2.0 → 15.3.0
- `win32`: 6.3.0 → 6.4.0
- `yaml`: 3.1.3 → 3.1.4

---

## 5. Verification Gate Results

### Static Analysis (`flutter analyze`)
- Command: `flutter analyze`
- Result: **0 issues found** (0 errors, 0 warnings, 0 infos).

### Automated Regression Suite (`flutter test`)
- Command: `flutter test`
- Result: **96 / 96 passed (100%)** across:
  - Cryptographic key derivation and AES-GCM roundtrips (`crypto_service_test.dart`)
  - SQLite database account CRUD and sync queue constraints (`database_test.dart`)
  - Real-time search filtering (`home_search_test.dart`)
  - Multi-screen responsive layouts on mobile & desktop viewports (`home_screen_responsive_test.dart`)
  - Application launch and root view tree integration (`widget_test.dart`)

### Multi-Platform Configuration Validation
- **macOS**: `GeneratedPluginRegistrant.swift` maps all active Darwin plugins.
- **Linux**: `generated_plugins.cmake` includes all native and FFI plugin targets.
- **Android**: `app/build.gradle.kts` configured with Java 17, coreLibraryDesugaring 2.1.4, and valid namespace.
- **iOS**: CocoaPods registrations intact and compatible.
