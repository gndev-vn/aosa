# TDR-002: TOTP Implementation Strategy

## Context
The app must generate TOTP codes per RFC 6238. Implementation must be fast, correct, and auditable.

## Decision
Implement TOTP natively in Dart using the `cryptography` package (HMAC) rather than relying on platform channels or JS interop.

### Algorithm (RFC 6238)
```
T = floor((Current Unix Timestamp - T0) / Period)
HMAC = HMAC-SHA1/HMAC-SHA256/HMAC-SHA512(Secret, T)
Truncated = DynamicTruncation(HMAC)  // RFC 4226 Section 5.3
OTP = Truncated mod 10^Digits
```

### Key properties
- No network required for code generation (fully offline)
- Generation time: <1μs per code
- Supports variable: periods (30/60s), digits (6/8), algorithms (SHA1/256/512)
- Implemented as pure Dart function with no dependencies on platform channels

### Clock sync
- Use `DateTime.now().millisecondsSinceEpoch ~/ 1000` for Unix time
- Period 30s is the default per RFC 6238
- One-time offset allowed via settings for clock-skewed devices

## File Location
`app/lib/domain/usecases/totp_engine.dart`
