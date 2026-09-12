# Technical Research & Architectural Decisions

**Feature**: Dependency Modernization & Package Upgrade
**Directory**: `specs/004-upgrade-dependencies`
**Status**: Completed (Phase 0)

---

## 1. Dependency Analysis & Upgrade Feasibility

### Context & Problem
The application relies on 21 direct dependencies in `app/pubspec.yaml`. Running `flutter pub outdated` identified 52 locked packages with newer versions and 4 direct packages with available major version increments (`flutter_secure_storage`, `google_fonts`, `shimmer`, `uuid`, alongside `flutter_riverpod`). An uncoordinated upgrade can introduce broken transitive constraints, runtime native bridge crashes on specific platforms, or compile-time API breaks.

### Research Findings & Dependency Graph Analysis
1. **`flutter_secure_storage`**:
   - Current: `^10.3.1` (resolving 10.3.1).
   - Target: `^11.1.1`.
   - Breaking changes evaluated: Migration from v10 to v11 refactors internal native key-value storage handlers on macOS/iOS (Keychain accessibility) and Windows (Data Protection API). The core public Dart API (`read`, `write`, `delete`, `deleteAll`) remains compatible with `const FlutterSecureStorage()`.
2. **`google_fonts`**:
   - Current: `^6.2.1` (resolving 6.3.3).
   - Target: `^8.2.1`.
   - Breaking changes evaluated: v8 optimizes offline font asset caching, HTTP font fetching fallbacks, and font license manifests. Calls to `GoogleFonts.jetBrainsMono()` and `GoogleFonts.inter()` in `AppTheme` remain fully compatible.
3. **`shimmer`**:
   - Current: `^3.0.0`.
   - Target: `^4.0.0`.
   - Codebase scan: `Shimmer` widget is currently unused in application source files; upgrading constraint to `^4.0.0` preserves clean dependency resolution without code changes.
4. **Minor & Patch Upgrades**:
   - `connectivity_plus`: `7.1.1` → `7.3.1` (network state stream fixes).
   - `dio`: `5.9.2` → `5.11.1` (security patches, connection reuse).
   - `flutter_local_notifications`: `22.0.0` → `22.3.0` (platform notification channel fixes).
   - `local_auth`: `3.0.1` → `3.0.2` (biometric prompt reliability).
   - `mobile_scanner`: `7.2.0` → `7.4.1` (lifecycle camera controller stability).
   - `path_provider`: `2.1.5` → `2.1.6`.
   - `sqlite3`: `3.3.3` → `3.5.2` (SQLite engine performance).
   - `window_manager`: `0.5.1` → `0.5.2` (desktop window event dispatching).
   - `logger`: `2.7.0` → `2.8.0`.
   - `intl`: `0.20.2` → `0.20.3`.
   - `image_picker`: `1.2.2` → `1.2.3`.

---

## 2. Dependency Conflict Resolution: `system_tray` vs `uuid 4` & `riverpod 3`

### Context & Problem
Running dependency resolution simulations with `uuid: ^4.5.1` and `flutter_riverpod: ^3.4.3` revealed a hard constraint conflict:
```text
Because aosa depends on system_tray ^2.0.0 which depends on uuid ^3.0.6, uuid ^3.0.6 is required.
So, because aosa depends on uuid 4.5.1, version solving failed.
Because flutter_riverpod >=3.4.3 depends on riverpod 3.4.3 which depends on uuid ^4.5.1, flutter_riverpod >=3.4.3 requires uuid ^4.5.1.
So, because aosa depends on both uuid ^3.0.7 and flutter_riverpod 3.4.3, version solving failed.
```
`system_tray: ^2.0.0` is the latest published version of the desktop tray plugin on pub.dev and restricts `uuid` to `^3.0.6`. Consequently, upgrading `uuid` to v4 or `flutter_riverpod` to v3 induces a version collision with `system_tray`.

### Decision
1. **Retain `flutter_riverpod: ^2.6.1` and `uuid: ^3.0.7`**:
   - `flutter_riverpod: 2.6.1` is the stable LTS release of Riverpod 2.x and fully supports the 7 existing `StateNotifierProvider` architectures across the app (`authProvider`, `otpListProvider`, `settingsProvider`, `syncProvider`, `repoProvider`, `appInitProvider`, `navigationProvider`).
   - `uuid: ^3.0.7` fulfills `system_tray ^2.0.0` requirements while maintaining compatibility across `otpauth_parser.dart` and `add_otp_bottom_sheet.dart`.
2. **Upgrade Major Constraints where Solvable**:
   - `flutter_secure_storage: ^11.1.1`
   - `google_fonts: ^8.2.1`
   - `shimmer: ^4.0.0`
3. **Upgrade All Upgradable Transitive & Minor Packages**:
   - Bump 57 packages in `pubspec.lock` to latest releases.

### Rationale
- Prevents breaking the entire state management architecture (which would require rewriting all providers from `StateNotifier` to code-generated `@riverpod` syntax).
- Preserves desktop system tray integration on Windows, macOS, and Linux.
- Maximizes modernization by upgrading all other major and minor dependencies cleanly without hacky dependency overrides.

### Alternatives Considered
- *Force `dependency_overrides: uuid: ^4.5.1`*: Rejected; risky for desktop builds because native plugins with unverified overrides can exhibit subtle runtime symbol or serialization faults.
- *Drop `system_tray`*: Rejected; desktop background tray integration is an established application capability.

---

## 3. Platform Validation & Verification Architecture

### Context & Problem
Per user clarification (Session 2026-09-12, Q2: Option B), build and runtime integrity must be verified across all supported platforms (desktop: Windows, macOS, Linux; mobile: Android, iOS).

### Decision
- **Automated Gate**:
  - `flutter analyze`: Must pass with 0 errors and 0 warnings.
  - `flutter test`: 100% of the 96 automated tests must pass.
- **Platform Compilation & Smoke Verification**:
  - Windows: Verified directly on host system via `flutter build windows` or `flutter run -d windows`.
  - Android & iOS: Verify build toolchain and plugin configuration sanity via `flutter build apk --config-only` / plugin registry analysis.
  - macOS & Linux: Verify plugin registration syntax in `GeneratedPluginRegistrant.swift` and `generated_plugins.cmake`.

### Rationale
Guarantees zero platform-specific regression while ensuring the CI/CD pipeline remains healthy.

---

## 4. Deprecation Remediation Policy

### Context & Problem
Upgraded packages (such as `flutter_secure_storage 11.1.1` or `google_fonts 8.2.1`) may deprecate older configuration options or parameter names.

### Decision
- Remediate straightforward deprecations in touched application files (`app_theme.dart`, `crypto_service.dart`, `app_init_provider.dart`, etc.).
- Maintain zero linter warnings under `flutter_lints ^6.0.0`.
- Document any complex deprecations requiring separate feature work in the upgrade audit report.
