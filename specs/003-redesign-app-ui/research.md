# Phase 0 Research: Modern & Friendly UI Redesign with Foldable Support

**Feature**: `003-redesign-app-ui`  
**Date**: 2026-09-11  
**Status**: Completed  

---

## 1. Modern Open-Source Design Language & Component Architecture

### Context
User requested: "I want to have a different design for the whole app. Maybe using any UI framework that available as open source but definitely make the app look stunning, easy to use and friendly."

### Decision
- **Adopt Material 3 Expressive & Soft Card Architecture with Lucide-style Iconography**:
  - **Color & Tonal Palette**: Soft warm tinted surfaces (`surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh`) with dynamic pastel containers (`primaryContainer`, `secondaryContainer`, `tertiaryContainer`). In Dark mode, OLED-friendly soft charcoals (not harsh #000000) with glowing accent borders.
  - **Geometry**: Generous rounded pill corners (`24dp`–`28dp` for sheets and cards, `16dp` for compact buttons, `999dp` for pill chips).
  - **Component Structure**:
    - App Scaffold featuring an ergonomic persistent `NavigationBar` on compact devices and `NavigationRail` on wide/foldable devices.
    - Card containers featuring soft 1px border outlines (`outlineVariant.withAlpha(50)`), subtle drop shadows, and warm background fills.
    - Issuer brand avatars: 44x44dp rounded squares (`borderRadius: 14`) with colorful gradient backgrounds and clean typography or monogram badges.
  - **Micro-Animations**:
    - Animated code copy confirmation (morphing copy icon into a glowing green checkmark with scale bounce).
    - Smooth countdown indicator with dynamic color lerp from primary accent to amber/warning at 5 seconds.

### Rationale
- Pure Material 3 with Expressive extensions is built directly into Flutter's engine, zero external dependency conflicts, 100% testable without web or headless renderer quirks, and fully compliant with Material Design 3 Expressive guidelines.
- Clean separation of UI primitives allows custom styling to look distinct, friendly, and custom-crafted rather than a generic boilerplate app.

### Alternatives Considered
- **Third-party heavy UI libraries (e.g. Forui, Shadcn Flutter)**: Look clean, but introduce breaking external dependency trees, complex widget wrappers, and potential incompatibilities with Flutter's headless testing environment (as seen with shader test issues earlier).
- **Cupertino-only (iOS)**: Looks alien on Android devices and foldables. Material 3 Expressive adapts naturally to Android, iOS, foldable devices, and desktop.

---

## 2. Foldable Phone & Adaptive Wide-Screen Architecture

### Context
User requested: "we also need to support foldable phone". Devices like Samsung Galaxy Z Fold 4/5/6/7/8 and Google Pixel Fold have two primary states:
1. **Folded (Cover Display)**: Narrow aspect ratio (width ~340–400dp, height ~800–900dp).
2. **Unfolded (Main Inner Display)**: Nearly square or wide tablet-like aspect ratio (width ~700–850dp, height ~800–900dp), potentially with a physical or emulated hinge crease down the center.

### Decision
- **Responsive Layout Breakpoint Strategy**:
  - `Compact (< 600dp)`: Standard single-column vertical list with bottom `NavigationBar` (Accounts, Vaults, Settings).
  - `Expanded / Foldable Unfolded (>= 600dp)`:
    - Navigation transitions from bottom bar into a side `NavigationRail` docked to the left edge.
    - OTP Account List transitions into an adaptive 2-column Grid (`SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 2.2)`) or centered max-width 840dp container.
    - Bottom sheets and modals retain `maxWidth: 640dp`, centered horizontally, hugging intrinsic height (preventing the top void issue).
- **Display Feature / Hinge Awareness**:
  - Query `MediaQuery.of(context).displayFeatures` for `DisplayFeatureType.hinge` or `DisplayFeatureType.fold`.
  - In tabletop or book posture, avoid placing critical interactive buttons (copy button, action floating button) directly on the hinge coordinate.

### Rationale
- `NavigationRail` + 2-Column Grid on unfolded displays transforms the experience from an awkwardly stretched mobile app into a modern, bespoke foldable experience.
- Keeping single-column on the outer cover screen ensures comfortable one-handed use.

### Alternatives Considered
- **Master-Detail Layout (List on left, detail on right)**: For an authenticator app, users don't frequently "open" accounts to read details; their primary goal is glancing at multiple codes and copying quickly. A 2-column card grid is far more effective and satisfying on an unfolded square screen than a master-detail split.

---

## 3. Navigation Shell & Screen Decomposition

### Context
User selected Option A: Ergonomic Bottom Navigation Bar.

### Decision
- Create `AppNavigationShell` widget as the root screen container:
  - Destinaton 0: **Accounts** (`HomeScreen` with search, filter chips, and OTP card grid/list).
  - Destination 1: **Vaults** (`VaultsScreen` for categories: All, Personal, Work, Cloud Sync, Favorites).
  - Destination 2: **Settings** (`SettingsScreen` with Appearance, Security, Cloud Sync, About).
- Floating Action Button (Speed Dial for Scan QR, Paste URI, Manual Form) lives on the Accounts screen or centrally docked.

### Rationale
- 3 distinct tabs provide clear mental models: codes to use (Accounts), ways to organize (Vaults), and app configuration (Settings).
- No more hidden navigation buried behind top-left menu icons. Everything is 1 tap away.

---

## 4. OTP Account Card Redesign & 1-Tap Copy Ergonomics

### Context
Current card is functional but utilitarian. Needs to feel "stunning, easy to use and friendly."

### Decision
- **Card Anatomy**:
  - **Top Row**: 44dp Brand Avatar (with initials/icon and pastel tinted background) + Issuer Name (`FontWeight.w700`, 16sp) + Account Label/Email (`FontWeight.w400`, 13sp) + Favorite Star toggle.
  - **Middle Row**: Huge, spaced OTP code (`28sp`, monospaced tracking, `FontWeight.w700`, e.g. `834 · 291`) + Circular animated progress countdown ring with remaining seconds text in the center.
  - **Interaction**:
    - Tapping anywhere on the code or copy button triggers an immediate animated ripple, an icon morph from `Icons.copy_rounded` to `Icons.check_circle_rounded`, a floating pill toast ("Copied to clipboard"), and a light haptic tap.
    - Long press reveals quick actions: Edit, Move to Vault, Delete.
    - When remaining time is <= 5s, progress ring and countdown text transition from `theme.primary` to `Colors.amber` or `Colors.deepOrange`.

### Rationale
- Large spaced typography is instantly legible at arm's length.
- Circular timer inside the card gives immediate visual context without scanning other parts of the screen.

