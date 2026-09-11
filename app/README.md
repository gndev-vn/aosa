# AOSA Authenticator

A high-performance, cross-platform Two-Factor (TOTP / HOTP) Authenticator built with Flutter.

---

## Architecture Overview

AOSA follows Clean Architecture principles with clear separation across domain, data, and presentation layers, managed reactively with Riverpod:

```
app/
├── lib/
│   ├── core/                  # Shared utilities, platform helpers, and design tokens
│   │   ├── platform/          # Platform detection (AppPlatformUtil)
│   │   └── theme/             # AppTheme centralized tokens, colors, typography
│   ├── data/                  # Infrastructure, database, encryption, and API
│   │   ├── api/               # Server API client with structured logging
│   │   ├── database/          # SQLite persistence & sync queue
│   │   ├── encryption/        # PBKDF2 key derivation & AES-GCM vault encryption
│   │   └── repositories/      # Concrete repository implementations
│   ├── domain/                # Pure business logic and cryptographic use cases
│   │   ├── entities/          # OtpAccount, TotpCode, AppSettings
│   │   ├── repositories/      # Repository interfaces (Clean Architecture contracts)
│   │   └── usecases/          # TotpEngine (RFC 6238/4226) & OtpauthParser
│   └── presentation/          # Riverpod state management & Flutter UI widgets
│       ├── providers/         # OtpListNotifier, TotpTickerProvider, AppLockProvider
│       ├── screens/           # HomeScreen, SettingsScreen, LockScreen, EditOtpScreen
│       └── widgets/           # OtpCard, HomeHeader, HomeSearchBar, StandardBottomSheet
└── test/                      # Comprehensive unit, cryptographic, and widget test suite
```

---

## Key Performance & Architectural Modernizations

1. **Isolated Countdown Ticker (`totpTickerProvider`)**:
   - The second-by-second countdown runs through a dedicated lightweight broadcast stream ticker.
   - Only individual badge countdowns and progress bars rebuild every second, eliminating full list re-renders.
   - Card entrance fade animations execute once on mount rather than replaying on each timer tick.

2. **Full RFC 6238 & RFC 4226 Cryptographic Compliance**:
   - 100% verified against RFC 6238 Appendix B test vectors across SHA-1, SHA-256, and SHA-512 with 6 and 8-digit padding.
   - Robust Base32 decoding supporting uppercase, lowercase, spaces, hyphens, and missing padding.
   - Case-insensitive URI algorithm parsing and parameter normalization in `OtpauthParser`.

3. **Resilient Offline Database & Sync Queue**:
   - Defensive parameter binding ensures offline queue operations never fail with SQLite constraint exceptions even before an active remote repository is linked.

4. **Multi-Screen Responsive Layout**:
   - Orientation locks are restricted strictly to handheld mobile phones (`AppPlatformUtil.isMobile`).
   - Desktop and tablet screens dynamically center dashboard views and modals with an adaptive `maxWidth: 640px` constraint, preventing awkward widescreen card stretching.

5. **Centralized Design System**:
   - Typography, radii, surface colors, and card elevations are unified in `AppTheme`.
   - Ad-hoc `GoogleFonts` reallocations inside build methods are replaced with centralized theme definitions.

---

## Verification & Testing

### Running Static Analysis

Ensure zero lint issues and strict type safety:

```bash
flutter analyze
```

### Running Automated Test Suite

Execute all 86 unit, cryptographic, database, and widget tests:

```bash
flutter test
```

### Profile Mode Performance Testing

To profile 60fps rendering in Flutter DevTools:

```bash
flutter run --profile
```

Open DevTools Performance view and observe smooth frame times (<16ms) without jank or full-list invalidation.
