# AOSA — Sync Protocol v1.0

## 1. Overview

The sync protocol enables bi-directional synchronization of encrypted OTP records between an AOSA client device and the self-hosted server.

**Key properties:**
- **Opaque payloads**: Server never sees plaintext data
- **Optimistic concurrency**: Uses version counters for conflict detection
- **Last-Write-Win**: Timestamp-based conflict resolution
- **Tombstones**: Soft-deleted records are preserved for deletion propagation

---

## 2. Version Model

### 2.1 Per-Record Version
Each OTP record has a **monotonic integer version** maintained by the server:

```
Record {
    id: UUID,
    encrypted_blob: byte[],
    version: int,         // monotonic, server-authoritative
    created_at: datetime,
    updated_at: datetime,
    deleted_at: datetime?  // null = active, non-null = deleted
}
```

### 2.2 Server Version
The server also maintains a **global version counter** that increments on every mutation (create, update, delete) across all records. This enables quick "is there anything new?" checks.

### 2.3 Device Version
Each device tracks `last_seen_version` — the global server version at the time of the last successful pull. This is used as the `since_version` parameter for incremental pulls.

---

## 3. Sync Flow

### 3.1 Quick Status Check

```
Client                          Server
  │                               │
  │  GET /api/v1/sync/status      │
  │──────────────────────────────►│
  │                               │
  │  { server_version: 142 }     │
  │◄──────────────────────────────│
  │                               │
  │  Compare with local           │
  │  device_version: 135          │
  │                               │
  │  if server_version >          │
  │  device_version → pull        │
```

### 3.2 Pull Changes

```
Client                          Server
  │                               │
  │  GET /sync/pull?              │
  │   since_version=135           │
  │──────────────────────────────►│
  │                               │
  │  SELECT * FROM records        │
  │  WHERE version > 135          │
  │  AND device_id != :device     │
  │                               │
  │  {                            │
  │    items: [...],              │
  │    server_version: 142        │
  │  }                            │
  │◄──────────────────────────────│
  │                               │
  │  For each item:               │
  │    Decrypt blob with PIN key  │
  │    Compare with local version │
  │    If remote.version >        │
  │    local.version → apply      │
```

### 3.3 Push Changes

```
Client                          Server
  │                               │
  │  POST /sync/push              │
  │  {                            │
  │    changes: [                 │
  │      { id, encrypted_blob,    │
  │        expected_version,      │
  │        client_timestamp,      │
  │        deleted }              │
  │    ]                          │
  │  }                            │
  │──────────────────────────────►│
  │                               │
  │  For each change:             │
  │    if expected_version ==     │
  │    stored.version:            │
  │      → accept, increment ver  │
  │    else:                      │
  │      → conflict              │
  │                               │
  │  {                            │
  │    accepted: [{id, new_ver}], │
  │    conflicts: [{id,           │
  │      server_version}]         │
  │  }                            │
  │◄──────────────────────────────│
  │                               │
  │  For conflicts:               │
  │    Pull latest version        │
  │    Re-apply local change on   │
  │    top of remote              │
  │    (or prompt user)           │
```

---

## 4. Conflict Resolution

### 4.1 Automatic (default)

```
if remote.updated_at > local.updated_at:
    keep remote version

elif local.updated_at > remote.updated_at:
    push local as new version (re-try with new base)

else:  // timestamps equal (rare)
    deterministic: keep higher UUID (lexicographic)
```

### 4.2 Manual (fallback)

When automatic resolution is ambiguous or user wants control:
- Show both versions side by side with timestamps
- User picks which to keep
- Selected version is pushed as the new version

---

## 5. Deletion Propagation

Deletes use soft-deletion (tombstones):

```
DELETE /api/v1/otp/{id}
  → sets deleted_at = now()
  → increments version
  → tombstone is synced to other devices
```

On other devices:
- If record exists locally and `remote.deleted_at > local.updated_at`:
  - Soft-delete local record (or prompt user)
- If `remote.deleted_at > local.deleted_at`:
  - Update local tombstone timestamp

Tombstones are garbage-collected server-side after 90 days.

---

## 6. Error Handling

| Error | Client Action |
|---|---|
| HTTP 401 | Refresh JWT. If refresh fails, prompt user to re-register |
| HTTP 409 | Fetch latest version, re-apply local changes, retry |
| HTTP 429 | Exponential backoff (1s, 2s, 4s, 8s, max 60s) |
| HTTP 500 | Retry after 5s. Max 3 retries, then UI notification |
| Network timeout | Queue changes for next sync. Show "offline" indicator |
| Decryption failure | Log error, flag record as "corrupt" in UI, skip sync |

---

## 7. Sync Queue

Changes made while offline are queued locally:

```dart
class SyncQueue {
  final List<QueuedChange> pendingPushes;
  final int lastPullVersion;
  final DateTime lastSyncAttempt;
}
```

On reconnection (detected via `connectivity_plus`):
1. Pull latest from server
2. Apply remote changes to local
3. Push queued changes
4. Clear completed queue items

---

## 8. Encryption Before Sync

Before a record is sent to the server, the client:

1. Serializes plaintext OTP data to JSON
2. Generates random 12-byte nonce
3. Encrypts with AES-256-GCM using the derived master key
4. Base64-encodes: `1 byte version + 32 bytes salt + 12 bytes nonce + ciphertext + 16 bytes tag`
5. Sends base64 string as `encrypted_blob`

```dart
Future<String> encryptForSync(OtpAccount account, Uint8List masterKey) async {
  final plaintext = jsonEncode(account.toJson());
  final salt = generateRandomBytes(32);
  final nonce = generateRandomBytes(12);
  final key = deriveKey(masterKey, salt);  // HKDF-expand
  final encrypted = await aes256GcmEncrypt(plaintext, key, nonce);
  return base64Encode(concat([version, salt, nonce, encrypted.ciphertext, encrypted.tag]));
}
```
