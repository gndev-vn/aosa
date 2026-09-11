# Interface Contract: Vault Storage & Persistence

**Contract Scope**: SQLite database interface, cryptographic payload schema, and sync queue reliability.

---

## 1. Database Operations (`AppDatabase`)

### Methods
```dart
Future<void> insertAccount(Map<String, dynamic> data);
Future<void> updateAccount(Map<String, dynamic> data);
void deleteAccount(String id);
Map<String, dynamic>? getAccount(String id);
List<Map<String, dynamic>> getAllAccounts();
int accountCount();

String? getSetting(String key);
void setSetting(String key, String value);

int addToQueue(Map<String, dynamic> data);
List<Map<String, dynamic>> getPendingQueue({int limit = 50});
void removeQueueItem(int id);
void incrementRetryCount(int id);
```

### Defensive Contract Guarantees
- `addToQueue` MUST guarantee non-null binding for `repo_id`. If `data['repo_id']` is `null`, it must default to `""` or the active repo ID.
- `getAllAccounts` returns ordered records by `sort_order ASC, created_at DESC`, filtering out records where `deleted_at IS NOT NULL`.

---

## 2. Encryption Envelope (`EncryptedPayload`)

Each OTP account secret is encrypted with AES-GCM-256 before persisting to SQLite.

```dart
class EncryptedPayload {
  final String ciphertext; // Base64 encoded AES-256 ciphertext
  final String nonce;      // Base64 encoded 12-byte IV
  final String salt;       // Base64 encoded 16-byte PBKDF2 salt
  final String authTag;    // Base64 encoded 16-byte GCM authentication tag
}
```

- When storing: Raw account JSON containing the `secretBase32` is serialized, encrypted, and mapped into `encrypted_data`, `nonce`, `salt`, and `auth_tag` columns.
- When querying: Nonce, salt, ciphertext, and authTag are passed to `CryptoService.decrypt()` with derived master key.
