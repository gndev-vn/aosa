# Interface Contract: Dependency Manifest & Version Constraints

**Contract Scope**: Specifications for `app/pubspec.yaml`, version constraints, and dependency solver guarantees.

---

## 1. Upgraded Package Constraints

| Package | Upgraded Constraint | Prior Version | Type | Major Breaking Evaluation |
|---|---|---|:---:|---|
| `flutter_secure_storage` | `^11.1.1` | `^10.3.1` | Direct | Keychain/DataProtection native bridge refactor; public Dart API backward-compatible |
| `google_fonts` | `^8.2.1` | `^6.2.1` | Direct | Asset fallback optimization; font loading methods backward-compatible |
| `shimmer` | `^4.0.0` | `^3.0.0` | Direct | Unused in codebase; constraint modernized |
| `connectivity_plus` | `^7.3.1` | `^7.1.1` | Direct | Stream-based connectivity updates; non-breaking |
| `dio` | `^5.11.1` | `^5.7.0` | Direct | HTTP request/response options, connection pooling; non-breaking |
| `flutter_local_notifications` | `^22.3.0` | `^22.0.0` | Direct | Notification channel settings; non-breaking |
| `local_auth` | `^3.0.2` | `^3.0.1` | Direct | Biometric prompt API; non-breaking |
| `mobile_scanner` | `^7.4.1` | `^7.2.0` | Direct | Barcode scanner controller; non-breaking |
| `path_provider` | `^2.1.6` | `^2.1.0` | Direct | Directory path resolution; non-breaking |
| `sqlite3` | `^3.5.2` | `^3.3.3` | Direct | FFI SQLite bindings; non-breaking |
| `window_manager` | `^0.5.2` | `^0.5.1` | Direct | Window resize/docking listener; non-breaking |
| `logger` | `^2.8.0` | `^2.5.0` | Direct | Logging filter and printer; non-breaking |
| `intl` | `^0.20.3` | `^0.20.2` | Direct | Formatting and pluralization; non-breaking |
| `image_picker` | `^1.2.3` | `^1.1.2` | Direct | Media picking API; non-breaking |

---

## 2. Invariant Constraints & Pinned Packages

| Package | Pinned Constraint | Reason for Pinning |
|---|---|---|
| `system_tray` | `^2.0.0` | Latest published release on pub.dev; requires `uuid ^3.0.6` |
| `uuid` | `^3.0.7` | Required by `system_tray ^2.0.0` |
| `flutter_riverpod` | `^2.6.1` | Retains stable `StateNotifierProvider` support across all 7 app providers without version conflict with `system_tray` |

---

## 3. Dependency Resolution Invariants

- Resolution MUST produce an unambiguous `pubspec.lock` with zero constraint collisions.
- No `dependency_overrides` that bypass semantic version bounds shall be introduced.
- Dart SDK boundary MUST remain compatible with `^3.5.0` and Flutter `^3.27.0`.
