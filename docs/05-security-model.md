# AOSA — Security Model v1.0

## 1. Threat Model

### 1.1 Assets
| Asset | Sensitivity | Description |
|---|---|---|
| OTP secrets | Critical | Base32-encoded shared secrets used to generate TOTP codes |
| User PIN | Critical | Unlocks the app and derives encryption key |
| Encrypted blobs | Medium | Server-stored encrypted data (useless without key) |
| Device ID | Low | Public identifier for device registration |
| Sync metadata | Low | Version numbers, timestamps |

### 1.2 Attack Scenarios

| ID | Scenario | Impact | Mitigation |
|---|---|---|---|
| T1 | Device lost/stolen | Attacker has physical access to encrypted DB | PIN + biometric gate, encrypted storage |
| T2 | Server compromised | Attacker accesses all stored blobs | Zero-trust: blobs are encrypted, server has no key |
| T3 | Man-in-the-middle | Attacker intercepts sync traffic | HTTPS + certificate pinning |
| T4 | PIN brute-force | Attacker tries all 4-digit PINs | Argon2id memory-hard KDF + rate limiting + cooldown |
| T5 | Screenshot/screen recording | OTP codes visible on screen | Android FLAG_SECURE, iOS screenshot detection |
| T6 | Malware/keylogger | Attacker reads PIN input | OS-level screen keyboard + biometric as alternative |

---

## 2. Cryptographic Primitives

| Use Case | Algorithm | Parameters |
|---|---|---|
| PIN hashing | Argon2id | t=3, m=64MB, p=4, output=32 bytes |
| Data encryption at rest | AES-256-GCM | 256-bit key, 96-bit nonce, 128-bit tag |
| OTP generation | HMAC-SHA1/SHA256/SHA512 | Per RFC 4226/6238 |
| Transport security | TLS 1.3 | Certificate pinning |
| Token signing (server) | HMAC-SHA256 (HS256) | 256-bit server secret |

---

## 3. Key Hierarchy

```
User PIN (entered by user, not stored)
        │
        ▼
   Argon2id (salt = random 32 bytes stored with blob)
        │
        ▼
   Master Encryption Key (256-bit AES key)
        │
        ├──► OTP records encryption (AES-256-GCM)
        │
        └──► PIN verification token
             (encrypt known plaintext, store as PIN verifier)
```

- The master key is **never stored on disk**. It exists only in memory during an unlocked session.
- When the app is locked, the key is zeroed from memory.
- On PIN change: derive new key from old PIN to decrypt all data → derive new key from new PIN → re-encrypt all data.

---

## 4. PIN Verification

Instead of hashing the PIN and comparing (which would leak the hash), we use a **verification token**:

```
PIN → Argon2id → MasterKey
    │
    encrypt("AOSA_PIN_VERIFY", nonce) → stored_token
```

On unlock: decrypt `stored_token` → if it equals `"AOSA_PIN_VERIFY"`, PIN is correct.

This means the PIN verifier is indistinguishable from encrypted data — no "hash" to attack.

---

## 5. Platform Security

### 5.1 Android
- **Screen security**: `FLAG_SECURE` on all OTP screens (prevents screenshot/recording)
- **Keystore**: Store device registration keys in Android Keystore (hardware-backed)
- **Biometric**: Use `BiometricManager` with `BIOMETRIC_STRONG` only
- **Background sensing**: Lock app on `onPause()` via `WidgetsBindingObserver`

### 5.2 iOS / iPadOS
- **Data protection**: `NSFileProtectionComplete` for database file
- **Keychain**: Store device keys in Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- **Biometric**: `LABiometryType` faceID/touchID
- **Screenshot detection**: `UIApplication.userDidTakeScreenshotNotification`

### 5.3 Desktop (Linux / macOS)
- **Linux**: Use `libsecret` or `keyutils` for key storage
- **macOS**: Use Keychain via `flutter_keychain`
- **Window security**: Hide window content from screen capture APIs where possible

---

## 6. Secure Coding Practices

| Practice | Enforcement |
|---|---|
| No secrets in logs | Custom logger strips sensitive fields |
| No hardcoded keys | All keys derived at runtime from user PIN |
| Memory clearing | Dart `Uint8List.fillRange(0)` after use |
| SQL injection prevention | Drift ORM (parameterized queries) |
| Input validation | All user input sanitized and length-limited |
| Dependency scanning | CI pipeline runs `dart pub deps` audit |
| Code obfuscation | Flutter's `--obfuscate` flag for release builds |

---

## 7. Audit Trail

The app logs security-relevant events locally (never sent externally):
- PIN change attempts (success/failure)
- Biometric authentication results
- App lock/unlock events
- Sync operations

These logs are stored encrypted and can be exported for debugging.
