# Data Model Specification

**Feature**: Application Optimization & Architecture Modernization
**Directory**: `specs/001-optimize-app-architecture`
**Status**: Completed (Phase 1)

---

## Entities

### 1. `OtpAccount` (Domain Entity)

Represents an individual two-factor authentication account saved in the user's encrypted vault.

| Field | Type | Required | Constraints / Validation | Description |
|---|---|:---:|---|---|
| `id` | `String` | Yes | Valid UUID v4 | Unique identifier for the account |
| `issuer` | `String` | Yes | Non-empty, max 100 chars | Service or provider name (e.g., "GitHub", "Google") |
| `accountLabel` | `String` | Yes | Non-empty, max 150 chars | User identifier or email address |
| `secretBase32` | `String` | Yes | Valid RFC 4648 Base32, min 4 chars | Shared secret key for HMAC computation |
| `algorithm` | `String` | Yes | One of `'SHA1'`, `'SHA256'`, `'SHA512'` | HMAC hash algorithm (case-insensitive) |
| `digits` | `int` | Yes | `6` or `8` | Number of digits in generated code |
| `period` | `int` | Yes | `10 <= period <= 300`, standard `30` | Rotation interval in seconds |
| `version` | `int` | Yes | `>= 1` | Monotonically increasing version for sync |
| `sortOrder` | `int` | Yes | `>= 0` | Manual sort position in vault |
| `shortcutKey` | `String?` | No | Single alphanumeric char or null | Desktop keyboard quick-copy shortcut |
| `createdAt` | `DateTime` | Yes | UTC ISO-8601 format | Account creation timestamp |
| `updatedAt` | `DateTime` | Yes | UTC ISO-8601 format | Last modification timestamp |
| `deletedAt` | `DateTime?` | No | UTC ISO-8601 format or null | Soft deletion timestamp |

#### Validation Rules
- `secretBase32` must strip spaces, hyphens, and padding before decoding.
- `algorithm` defaults to `'SHA1'`.
- `period` must be strictly positive; default is 30.
- `digits` must be either 6 or 8; default is 6.

---

### 2. `TotpCode` (Value Object)

Represents the computed ephemeral code and remaining lifecycle for an account.

| Field | Type | Description |
|---|---|---|
| `code` | `String` | Padded numeric string (e.g. `"491823"`) |
| `timeLeft` | `int` | Remaining seconds before expiration (`1 <= timeLeft <= totalPeriod`) |
| `totalPeriod` | `int` | Total period in seconds (e.g. `30`) |
| `algorithm` | `String` | Algorithm used for generation |
| `digits` | `int` | Number of digits |

#### State Transitions & Lifecycle
```
[Time Tick: epoch % period == 0] ──> [Regenerate Code] ──> [Emit new TotpCode with timeLeft = period]
                                                                        │
                                                                        ▼
[Time Tick: second increments]   ──> [Update timeLeft only] ──> [timeLeft decrements towards 1]
```

---

### 3. `SyncQueueItem` (Persistence Entity)

Represents a pending offline mutation destined for remote cloud repository synchronization.

| Field | Type | Required | Constraints | Description |
|---|---|:---:|---|---|
| `id` | `int` | Yes | Primary Key Autoincrement | Local queue sequence identifier |
| `recordId` | `String` | Yes | Non-empty | Target account UUID |
| `repoId` | `String` | Yes | Default `""` if unassigned | Repository cloud target |
| `action` | `String` | Yes | `'create'`, `'update'`, or `'delete'` | Change action type |
| `encryptedData` | `String` | Yes | Base64 AES-GCM ciphertext | Encrypted account payload |
| `nonce` | `String` | Yes | Base64 AES-GCM initialization vector | Cryptographic nonce |
| `salt` | `String` | Yes | Base64 PBKDF2 salt | Key derivation salt |
| `authTag` | `String` | Yes | Base64 AES-GCM tag | Authentication tag |
| `expectedVersion` | `int` | Yes | `>= 0` | Concurrency check version |
| `createdAt` | `DateTime` | Yes | UTC ISO-8601 | Queue entry creation time |
| `retryCount` | `int` | Yes | `>= 0`, default 0 | Failed sync attempt counter |

---

### 4. `AppSettings` (Configuration Entity)

Application-wide security, theming, and behavior preferences.

| Setting Key | Type | Default | Permitted Values | Description |
|---|---|---|---|---|
| `theme_mode` | `String` | `'system'` | `'system'`, `'light'`, `'dark'` | Visual brightness preference |
| `seed_color` | `int` | `0xFF6750A4` | Valid 32-bit ARGB color integer | Dynamic color palette seed |
| `pin_enabled` | `bool` | `false` | `true`, `false` | Master vault PIN lock status |
| `biometrics_enabled`| `bool` | `false` | `true`, `false` | Biometric authentication toggle |
| `auto_lock_timeout` | `String` | `'immediate'` | `'immediate'`, `'seconds30'`, `'minute1'`, `'minutes5'` | Inactivity lock delay |
| `sync_enabled` | `bool` | `false` | `true`, `false` | Cloud synchronization toggle |
| `active_repo_id` | `String?` | `null` | String or null | Currently active remote repository |
