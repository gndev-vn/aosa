# TDR-001: Target SDK Versions

## Context
The app must support specific platform versions per requirements.

## Decision

| Platform | Minimum | Target | Rationale |
|---|---|---|---|
| Android | API 33 (13) | API 35 (15) | Biometric API maturity, Material You |
| iOS | 18.0 | Latest | Swift 6, new crypto APIs |
| iPadOS | 18.0 | Latest | Same as iOS |
| Linux | Any modern distro | Ubuntu 24.04+ | Wide package availability |
| macOS | 18 (Sequoia) | Latest | Swift 6, Keychain features |
| Flutter SDK | ^3.27.0 | Latest stable | Impeller default, Dart 3 features |
| Dart SDK | ^3.5.0 | Latest | Pattern matching, sealed classes |
| .NET SDK | 9.0+ | 10.0 | Native AOT, Minimal API improvements |

## Reasoning
- Android 13+ covers ~85% of active devices while providing modern BiometricManager
- iOS 18+ ensures Swift 6 and modern security APIs
- Flutter 3.27+ makes Impeller the default renderer, providing 120fps guarantee
- .NET 10 provides the latest performance improvements for Minimal APIs
