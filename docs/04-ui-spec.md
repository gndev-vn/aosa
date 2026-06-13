# AOSA — UI/UX Specification v1.0

## 1. Design System

### 1.1 Brand
- **Name**: AOSA
- **Typography**: System default (SF Pro on Apple, Roboto on Android, system on Linux)
- **Iconography**: Material Symbols (rounded weight)

### 1.2 Theme
- **Base**: Material 3 (M3)
- **Color**: Dynamic color via `ColorScheme.fromSeed(seedColor)`
- **Modes**: Light / Dark / System-follow
- **Surface**: M3 elevation-based surfaces with tonal overlays

### 1.3 Spacing Scale (dp)
| Token | Value |
|---|---|
| xs | 4 |
| sm | 8 |
| md | 16 |
| lg | 24 |
| xl | 32 |

---

## 2. Screen Flows

### 2.1 App Lock Gate

```
[App Launch]
     │
     ▼
┌────────────────────┐
│   Lock Screen       │
│                    │
│   [○ ○ ○ ○ ○ ○]   │ ← PIN dots
│   "Enter PIN"      │
│                    │
│   [1][2][3]        │ ← Numpad
│   [4][5][6]        │
│   [7][8][9]        │
│   [  ][0][⌫]       │
│                    │
│   [Use Biometric]  │ ← if enabled
└────────┬───────────┘
         │ PIN correct
         ▼
    [Main App]
```

**States:**
- First launch after PIN enabled → PIN creation flow
- Subsequent launches → PIN entry or biometric
- PIN entry attempts: max 5, then cooldown (30s)
- Failed attempts increment exponentially (5, 10, 20, 40s)

### 2.2 Home Screen

```
┌──────────────────────────────────────┐
│  AOSA                     🔍 ⚙️     │ ← AppBar
├──────────────────────────────────────┤
│ ┌───────────────┐ ┌───────────────┐  │
│ │ Google         │ │ GitHub         │  │ ← OTP Cards
│ │ user@gmail.com │ │ dev@github.com │  │    (List or Grid)
│ │ 482 039        │ │ 193 847        │  │
│ │ ████████████░░ │ │ ██████░░░░░░░░ │  │ ← Animated progress
│ │ [Tap to copy]  │ │ [Tap to copy]  │  │
│ └───────────────┘ └───────────────┘  │
│ ┌───────────────┐                    │
│ │ Microsoft      │                    │
│ │ user@outlook  │                    │
│ │ 729 104        │                    │
│ │ ████████████░░ │                    │
│ │ [Tap to copy]  │                    │
│ └───────────────┘                    │
├──────────────────────────────────────┤
│                    [+ Add] [Grid ▼]  │ ← Bottom bar
└──────────────────────────────────────┘
```

**Interactions:**
- **Tap OTP code**: Copy to clipboard + snackbar "Copied!" + haptic feedback
- **Long press card**: Enter edit mode / select for batch operations
- **Swipe left**: Delete with confirmation
- **Pull down**: Manual sync trigger (if sync enabled)
- **FAB**: Add new OTP

**Layout toggle:**
- List view (default): full-width cards with all details
- Grid view: compact cards showing issuer + OTP only

### 2.3 Add OTP Screen

```
┌──────────────────────────────────────┐
│  ←  Add Account                      │
├──────────────────────────────────────┤
│                                      │
│  [📷 Scan QR Code]     [✏️ Manual]  │ ← Segmented control
│                                      │
│  ── Manual Entry ──                  │
│  Issuer          [Google     ]      │
│  Account Label   [user@gmail ]      │
│  Secret Key      [JBSWY3DPE ]      │ ← Base32
│  Algorithm       [SHA1 ▼     ]      │
│  Digits          [6 ▼        ]      │
│  Period (sec)    [30 ▼       ]      │
│                                      │
│  [  Save  ]                         │ ← Primary button
│                                      │
└──────────────────────────────────────┘
```

**QR Scanner state:**
- Full-screen camera viewfinder with guidance overlay
- Auto-detects `otpauth://` URIs
- On success: vibrate, auto-fill form, transition to preview

### 2.4 Settings Screen

```
┌──────────────────────────────────────┐
│  ←  Settings                         │
├──────────────────────────────────────┤
│  ── Appearance ──                    │
│    Theme               [System  ▼]  │
│    Accent color       [🎨 Pick   ]  │
│                                      │
│  ── Security ──                      │
│    PIN Lock            [ON   ✏️]    │
│    Biometric           [ON        ]  │
│    Auto-lock timeout   [30s ▼    ]  │
│                                      │
│  ── Sync ──                          │
│    Enable sync         [ON        ]  │
│    Server URL     [https://... ]    │
│    Device name    [My Phone    ]    │
│    Sync now          [   Sync   ]   │
│                                      │
│  ── Desktop ──                        │
│    Global hotkey   [Ctrl+Shift+A  ]  │
│    Minimize to tray      [ON     ]   │
│    OTP shortcuts    [Configure ▼]    │
│                                      │
│  ── About ──                         │
│    Version                1.0.0      │
│    License               MIT         │
│    Source code    [github.com/...]   │
└──────────────────────────────────────┘
```

---

## 3. Component Tree

```
App
├── AppLockGate
│   ├── PinDotIndicator
│   ├── NumpadWidget
│   └── BiometricButton
├── MainShell
│   ├── HomeScreen
│   │   ├── SearchBar
│   │   ├── OtpListView / OtpGridView
│   │   │   └── OtpCard
│   │   │       ├── IssuerLabel
│   │   │       ├── AccountLabel
│   │   │       ├── OtpCodeText (tappable)
│   │   │       ├── CountdownProgressBar (animated)
│   │   │       └── CopyIndicator (on tap)
│   │   └── FloatingActionButton
│   └── SettingsScreen
│       ├── ThemeSelector
│       ├── ColorPicker
│       ├── PinConfigSection
│       ├── BiometricToggle
│       ├── SyncConfigSection
│       └── HotkeyConfigSection (desktop only)
├── AddOtpScreen
│   ├── MethodSelector (QR / Manual)
│   ├── QrScannerView
│   └── ManualEntryForm
└── EditOtpScreen (same form as Add, pre-filled)
```

---

## 4. Animation Spec

| Element | Animation | Duration | Curve |
|---|---|---|---|
| Countdown bar | Width tween from 100% → 0% | period (30s) | Linear |
| OTP refresh | Cross-fade old → new code | 300ms | easeInOut |
| Card entry | Fade + slide up | 200ms | easeOut |
| Copy toast | Slide up from bottom | 150ms | easeOut |
| Screen transition | Slide forward/back | 300ms | easeInOut |
| Theme switch | Instant (no animation) | 0ms | — |
