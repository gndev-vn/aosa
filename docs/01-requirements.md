# AOSA — Requirements Specification v1.0

## 1. Product Overview

**AOSA (Another Open Source Authenticator)** is a cross-platform Time-based One-Time Password (TOTP) management application. It provides secure OTP generation, storage, and synchronization across user devices with an optional self-hosted backend.

### 1.1 Supported Platforms
- **Mobile**: Android 13+, iOS 18+, iPadOS 18+
- **Desktop**: Linux (any modern distro), macOS 18+

### 1.2 Core Principles
- **Zero-trust encryption**: OTP secrets are encrypted client-side and never exposed to the server in plaintext.
- **Privacy-first**: No telemetry, no analytics, no third-party network calls.
- **Offline-capable**: TOTP generation works entirely offline; sync is optional.

---

## 2. Functional Requirements

### FR-1: OTP Management
| ID | Requirement | Priority |
|---|---|---|
| FR-1.1 | User can add an OTP account by manually entering: issuer name, account label, secret key (Base32), algorithm (SHA1/SHA256/SHA512), digits (6/8), time period (30/60) | P0 |
| FR-1.2 | User can add an OTP account by scanning a QR code (`otpauth://` URI) | P0 |
| FR-1.3 | User can add OTP accounts in batch by importing from Google Authenticator export format (JSON array of `otpauth://` URIs) | P1 |
| FR-1.4 | User can edit any field of an existing OTP account | P0 |
| FR-1.5 | User can delete an OTP account (with confirmation dialog) | P0 |
| FR-1.6 | Deleted accounts are soft-deleted to support cross-device sync propagation | P1 |

### FR-2: OTP Display
| ID | Requirement | Priority |
|---|---|---|
| FR-2.1 | Home screen displays all OTP accounts in a list or grid layout (toggleable) | P0 |
| FR-2.2 | Each OTP card shows: issuer, account label, current OTP code, animated countdown bar | P0 |
| FR-2.3 | OTP codes auto-refresh at the period interval with smooth animation | P0 |
| FR-2.4 | User can tap on the OTP code to copy it to clipboard (with visual feedback) | P0 |
| FR-2.5 | Expired OTP codes are visually dimmed until the next refresh | P1 |

### FR-3: Search & Filter
| ID | Requirement | Priority |
|---|---|---|
| FR-3.1 | User can search OTP accounts by issuer or account label | P1 |
| FR-3.2 | User can sort accounts by: last used, issuer (A-Z), creation date | P2 |

### FR-4: Authentication & Security
| ID | Requirement | Priority |
|---|---|---|
| FR-4.1 | User can set a PIN (minimum 4 digits) to lock the app | P0 |
| FR-4.2 | User can enable biometric unlock (Face ID / Touch ID / Android Biometric) | P0 |
| FR-4.3 | App automatically locks when sent to background (configurable timeout: immediate / 30s / 1m / 5m) | P0 |
| FR-4.4 | PIN is hashed with Argon2id (memory-hard function) before storage | P0 |
| FR-4.5 | All OTP secrets are encrypted at rest with AES-256-GCM | P0 |

### FR-5: Settings
| ID | Requirement | Priority |
|---|---|---|
| FR-5.1 | Theme selection: Light / Dark / System default | P0 |
| FR-5.2 | Accent color picker (seed color for Material 3 dynamic palette) | P1 |
| FR-5.3 | Self-hosted API server configuration: URL, port, authentication token | P0 |
| FR-5.4 | Sync toggle: enable/disable cloud sync | P0 |
| FR-5.5 | PIN management: create / change / disable PIN | P0 |
| FR-5.6 | Biometric toggle: enable / disable biometric unlock | P0 |
| FR-5.7 | App lock timeout configuration | P1 |
| FR-5.8 | Hotkey configuration for desktop (global hotkey to open app) | P1 |

### FR-6: Desktop-Specific
| ID | Requirement | Priority |
|---|---|---|
| FR-6.1 | App minimizes to system tray when window is closed | P1 |
| FR-6.2 | Configurable global hotkey to bring the app window to front | P1 |
| FR-6.3 | Per-OTP shortcut keys: user can assign a keyboard shortcut to any OTP item (e.g. Ctrl+Shift+1) | P2 |
| FR-6.4 | When hotkey is pressed while app is in tray, OTP is copied directly to clipboard with a toast notification | P2 |

### FR-7: Self-Hosted Sync
| ID | Requirement | Priority |
|---|---|---|
| FR-7.1 | User can register their device with the self-hosted backend | P1 |
| FR-7.2 | OTP accounts are synced to the backend as encrypted opaque blobs | P1 |
| FR-7.3 | Sync is bi-directional: local changes pushed, remote changes pulled | P1 |
| FR-7.4 | Conflict resolution uses Last-Write-Win with version counters | P1 |
| FR-7.5 | On conflict (409), client fetches latest version and user can choose to keep local or remote | P2 |
| FR-7.6 | Deletes propagate across devices (soft-delete with tombstone) | P2 |

---

## 3. Non-Functional Requirements

| ID | Requirement | Target |
|---|---|---|
| NFR-1 | App cold start time (with PIN screen) | < 2 seconds |
| NFR-2 | TOTP code generation latency | < 50ms |
| NFR-3 | Home screen scroll performance (100 OTP items) | 60 fps |
| NFR-4 | Encrypted database size overhead | < 20% over plaintext |
| NFR-5 | Sync operation (100 items) | < 5 seconds on WiFi |
| NFR-6 | App binary size | < 50 MB (mobile), < 100 MB (desktop) |
| NFR-7 | Battery impact | < 1% per hour (background) |
| NFR-8 | Concurrent device support | Up to 10 devices per user |
