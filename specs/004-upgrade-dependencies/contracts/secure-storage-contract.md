# Interface Contract: Secure Storage Abstraction

**Contract Scope**: Storage bridge between `FlutterSecureStorage` v11 and application authentication/key services.

---

## 1. Storage Operations Contract

The application consumes `FlutterSecureStorage` across `AuthService`, `CryptoService`, `AppInitNotifier`, `SettingsNotifier`, `SyncNotifier`, and `RepoNotifier`.

### Required API Signatures
```dart
abstract class ISecureStorageBridge {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String? value});
  Future<void> delete({required String key});
  Future<Map<String, String>> readAll();
}
```

### Storage Key Registry
| Key Name | Purpose | Value Format |
|---|---|---|
| `app_pin_hash` | PBKDF2 salt and hash of the master PIN | Encrypted JSON string |
| `app_master_key` | Ephemeral or encrypted vault key | Base64 string |
| `auth_token` | Cloud sync bearer token | JWT string |
| `cloud_sync_config` | Sync endpoints and credentials | JSON string |

---

## 2. Backward Compatibility & Migration Guarantees

- Upgrading to `flutter_secure_storage` v11 MUST preserve accessibility of existing keys written under v10.
- On macOS, keychain access options must default to `MacOsOptions(accessibility: KeychainAccessibility.unlocked)`.
- On Windows, encrypted key values must continue utilizing Windows Data Protection API (DPAPI) without key invalidation.
- Storage failures (e.g. platform hardware key unavailability) must throw handled exceptions caught gracefully by `CryptoService.secureRead`.
