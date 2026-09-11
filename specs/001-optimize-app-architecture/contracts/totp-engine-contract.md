# Interface Contract: TOTP Engine & URI Parser

**Contract Scope**: Cryptographic calculation, Base32 decoding, and URI parsing interfaces.

---

## 1. TOTP / HOTP Computation

### Method: `generateCode`
```dart
Future<String> generateCode(String secretBase32, {DateTime? timestamp});
```
- **Inputs**:
  - `secretBase32`: RFC 4648 Base32 encoded secret key (spaces, hyphens, and padding allowed).
  - `timestamp`: Optional `DateTime` reference. Defaults to `DateTime.now()`.
- **Outputs**:
  - `String`: Formatted numeric string padded to `digits` length (e.g. `'042918'`).
- **Mathematical Specification**:
  - Step 1: `T = unixSeconds ~/ period` (where `unixSeconds = timestamp.millisecondsSinceEpoch ~/ 1000`).
  - Step 2: `counterBytes = intToBytes(T)` (big-endian 8-byte array).
  - Step 3: `hmac = HMAC(algorithm, secretBytes, counterBytes)` using SHA-1, SHA-256, or SHA-512.
  - Step 4: `offset = hmac.last & 0x0f`.
  - Step 5: `truncated = ((hmac[offset] & 0x7f) << 24) | ((hmac[offset + 1] & 0xff) << 16) | ((hmac[offset + 2] & 0xff) << 8) | (hmac[offset + 3] & 0xff)`.
  - Step 6: `code = (truncated % 10^digits).toString().padLeft(digits, '0')`.

---

## 2. Base32 Decoding

### Method: `decodeBase32`
```dart
static List<int> decodeBase32(String input);
```
- **Alphabet**: RFC 4648 (`A-Z`, `2-7`).
- **Sanitization**: All whitespace, hyphens, and `=` padding characters must be stripped prior to decoding.
- **Case Handling**: Inputs are normalized to uppercase.
- **Test Vectors**:
  - `""` → `[]`
  - `"MY======"` → `[102]` (`'f'`)
  - `"JBSWY3DPEE======"` → `[72, 101, 108, 108, 111, 33]` (`"Hello!"`)
  - `"JBSWY3DPEBLW64TMMQ======"` → `[72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]` (`"Hello World"`)

---

## 3. URI Parser (`otpauth://`)

### Method: `parseUri`
```dart
static OtpAccount parse(String uriString);
```
- **Format**: `otpauth://TYPE/LABEL?PARAMETERS`
- **Supported TYPE**: `totp` (default) and `hotp`.
- **Query Parameters**:
  - `secret` (Required): Base32 secret string.
  - `issuer` (Optional): Provider string. If absent, parsed from prefix before `:` in `LABEL`.
  - `algorithm` (Optional): `'SHA1'` (default), `'SHA256'`, `'SHA512'`.
  - `digits` (Optional): `6` (default) or `8`.
  - `period` (Optional): `30` (default) or positive integer.
