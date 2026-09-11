# Implementation Plan: Application Optimization & Architecture Modernization

**Branch**: `001-optimize-app-architecture` | **Date**: 2026-09-04 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/001-optimize-app-architecture/spec.md`

## Summary

Modernize, optimize, and stabilize the cross-platform Flutter TOTP authenticator (`aosa`) initially generated with Copilot. The optimization addresses critical architectural bottlenecks:
1. **Performance & Rendering**: Decouple account metadata from the 1-second countdown ticker to eliminate full-list rebuilds and card re-animation flickering, securing 60fps frame rates.
2. **Component & View Layer**: Consolidate design tokens in `AppTheme`, extract reusable `const` components (`HomeHeader`, `HomeSearchBar`, `OtpCard`), and provide responsive layouts for desktop and tablet screens.
3. **Database & Sync Resiliency**: Ensure `AppDatabase.addToQueue` safely handles non-null constraints for `repo_id`, eliminating runtime SQLite 1299 exceptions.
4. **Cryptographic Standards & Quality Gate**: Correct hallucinated unit test vectors in `totp_engine_test.dart` to match RFC 4226 and RFC 4648, repair `widget_test.dart`, and enforce a 100% green test suite with 0 static analysis warnings.

## Technical Context

**Language/Version**: Dart 3.5+, Flutter 3.27+

**Primary Dependencies**: Flutter Riverpod 2.6.1, cryptography 2.7.0, sqlite3 3.3.3, flutter_secure_storage 10.3.1, flutter_animate 4.5.0, google_fonts 6.2.1

**Storage**: Local encrypted SQLite database (`sqlite3` / `app_database.dart`), `flutter_secure_storage`

**Testing**: `flutter_test`, `flutter analyze`

**Target Platform**: Cross-platform (iOS, Android, macOS, Linux, Windows)

**Project Type**: Cross-platform Client Application (TOTP Authenticator)

**Performance Goals**: 60 fps rendering on list views during 1s countdown ticks; <50ms search latency for 100+ accounts; <1.5s cold start to interactive

**Constraints**: Completely offline-capable core operation; zero cryptographic secret leakage; zero unhandled database constraint exceptions; 0 lint warnings; 100% passing test suite

**Scale/Scope**: 100+ OTP accounts in vault; 63 Dart source files across presentation, domain, data, and core layers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Project constitution template contains no unratified blocking rules.
- Design preserves Clean Architecture separation: domain has zero UI dependencies, data layer isolates database/crypto details, presentation layer uses unidirectional Riverpod state.
- Offline-first privacy and security requirements strictly preserved.
- Gate status: **PASSED**.

## Project Structure

### Documentation (this feature)

```text
specs/001-optimize-app-architecture/
├── plan.md              # This implementation plan
├── research.md          # Technical research & architectural decisions (Phase 0)
├── data-model.md        # Entities, validation, and lifecycle state (Phase 1)
├── quickstart.md        # Runnable verification and testing scenarios (Phase 1)
├── contracts/           # Interface contracts (Phase 1)
│   ├── component-design-tokens.md
│   ├── totp-engine-contract.md
│   └── vault-storage-contract.md
├── checklists/
│   └── requirements.md  # Specification quality checklist
└── spec.md              # Feature specification
```

### Source Code Layout (`app/`)

```text
app/
├── lib/
│   ├── core/
│   │   ├── constants.dart
│   │   ├── platform/app_platform.dart
│   │   └── theme/
│   │       ├── app_theme.dart               # Unified design tokens & typography
│   │       └── color_picker.dart
│   ├── data/
│   │   ├── api/
│   │   │   └── api_client.dart             # Avoid print warnings; logger integration
│   │   ├── database/app_database.dart       # Safe addToQueue parameter binding
│   │   ├── encryption/crypto_service.dart
│   │   ├── repositories/otp_repository_impl.dart
│   │   └── services/sync_service.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── app_settings.dart
│   │   │   ├── otp_account.dart
│   │   │   └── totp_code.dart
│   │   ├── repositories/otp_repository.dart
│   │   └── usecases/
│   │       ├── otpauth_parser.dart
│   │       └── totp_engine.dart            # RFC 6238 TOTP / RFC 4226 HOTP engine
│   ├── presentation/
│   │   ├── providers/
│   │   │   ├── app_init_provider.dart
│   │   │   ├── app_lock_provider.dart
│   │   │   ├── otp_list_provider.dart      # Decoupled list notifier (no O(N) rebuilds)
│   │   │   ├── settings_provider.dart
│   │   │   └── sync_provider.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart            # Responsive, isolated card rendering
│   │   │   ├── lock_screen.dart
│   │   │   ├── edit_otp_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── widgets/
│   │       ├── otp_card.dart               # Isolated ticker & no jank re-animation
│   │       ├── home_search_bar.dart
│   │       └── standard_bottom_sheet.dart
│   └── main.dart                           # Responsive orientations, provider harness
└── test/
    ├── crypto_service_test.dart
    ├── database_test.dart                  # Validated sync_queue test cases
    ├── otpauth_parser_test.dart
    ├── totp_engine_test.dart               # Official RFC 4226 / 4648 test vectors
    └── widget_test.dart                    # App launch verification harness
```

**Structure Decision**: Retains existing modular Flutter layout (`core`, `data`, `domain`, `presentation`), refactoring key anti-patterns within providers and widgets while repairing broken test fixtures.

## Complexity Tracking

*No constitution violations or unjustified architectural complexity introduced.*
