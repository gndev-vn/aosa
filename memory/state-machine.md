# AOSA — Project State Machine

## Current Phase: Phase 4 — Settings ✅ COMPLETE

### Phase Progress
| ID | Task | Priority | Status |
|---|---|---|---|
| 4.1 | PIN creation/change flow (dialog + storage) | P0 | ✅ Done |
| 4.2 | PIN removal flow (verify first) | P0 | ✅ Done |
| 4.3 | Biometric toggle with availability check | P0 | ✅ Done |
| 4.4 | App lock timeout configuration (Timer-based) | P1 | ✅ Done |
| 4.5 | Theme picker (Light/Dark/System) with persistence | P0 | ✅ Done |
| 4.6 | Appearance settings persistence (FlutterSecureStorage JSON) | P1 | ✅ Done |
| 4.7 | Desktop settings (stub) | P2 | ✅ Done |

### Phase 4 Details
- **`settings_provider.dart`**: UPDATED with `load()`/`_persist()` — reads/writes `AppSettings` as JSON in `FlutterSecureStorage` under key `app_settings`. All mutations auto-persist. Loaded in `main.dart` before app starts.
- **`pin_setup_dialog.dart`**: NEW — 3-mode dialog (create/change/remove). Each mode uses numpad PIN entry with confirmation step. `PinSetupMode.create`: enter → confirm → store salt+token via `CryptoService`. `PinSetupMode.change`: verify old → create new → store. `PinSetupMode.remove`: verify → delete stored salt+token. Results returned via `Navigator.pop(bool)`.
- **`settings_screen.dart`**: UPDATED — PIN toggle opens `PinSetupDialog` (creation or removal). Biometric toggle checks `LocalAuthentication.canCheckBiometrics` before enabling. Auto-lock timeout DropdownButton wired to `SettingsNotifier.setAutoLockTimeout`. Accent color tile placeholder. Removed unused imports.
- **`main.dart`**: UPDATED — loads settings via `settingsProvider.notifier.load()` before runApp. `_AosaAppState` now uses a `Timer` for delayed auto-lock: `immediate` → lock on pause, `seconds30`/`minute1`/`minutes5` → start timer on pause, cancel on resume.
- **`app_settings.dart`**: Already had `toJson()`/`fromJson()` — used by persistence.
- **`lock_screen.dart`**: Already had PIN verification via `CryptoService.verifyPin()` — no changes needed.

### File Changes in Phase 4
- `presentation/providers/settings_provider.dart` — UPDATED: load/persist settings via FlutterSecureStorage
- `presentation/widgets/pin_setup_dialog.dart` — NEW: create/change/remove PIN dialog
- `presentation/screens/settings_screen.dart` — UPDATED: PIN dialog wiring, biometric check, auto-lock dropdown
- `app/lib/main.dart` — UPDATED: settings load + auto-lock Timer

### Packages Upgraded (after Phase 3)
- `flutter_riverpod`: 2→2.6.1 (pinned, no breaking changes)
- `sqlite3`: 2→3.3.3 (Row API: `row.keys`)
- `flutter_secure_storage`: 9→10.3.1
- `local_auth`: 2→3.0.1
- `connectivity_plus`: 6→7.1.1
- `mobile_scanner`: 6→7.2.0
- `window_manager`: 0.4→0.5.1
- `flutter_local_notifications`: 18→22.0.0
- `intl`: 0.19→0.20.2
- `flutter_lints`: 5→6.0.0
- `sqlite3_flutter_libs`: 0.5→0.6.0+eol
- Remaining build warnings: `System.load` (JDK 25/Gradle 9.1, cosmetic), `mobile_scanner` KGP (plugin-side, cosmetic)

---

## Next: Phase 5 — Backend Full Implementation

### Phase Pipeline
```
Phase 0 ✅ → Phase 1 ✅ → Phase 2 ✅ → Phase 3 ✅ → Phase 4 ✅ → Phase 5 [NEXT] → Phase 6 → Phase 7 → Phase 8
                                                    Add/Edit    Settings   Backend     Sync     Desktop  Polish
                                                    /Remove                Full Impl.  Int.    Features  + Store
```

### Phase 5 Tasks
| ID | Task | Priority |
|---|---|---|
| 5.1 | JWT authentication (register/login/refresh) | P0 |
| 5.2 | Rate limiting middleware | P0 |
| 5.3 | Dockerfile + docker-compose | P0 |
| 5.4 | API documentation (OpenAPI/Swagger) | P1 |
| 5.5 | Health endpoint improvements | P1 |

### Current Blockers
- None

### Next Action
Implement JWT authentication on the ASP.NET Core backend.
