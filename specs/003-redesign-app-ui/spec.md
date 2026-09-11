# Feature Specification: Complete Modern & Friendly App UI Redesign

**Feature Branch**: `003-redesign-app-ui`  
**Created**: 2026-09-11  
**Status**: Ready for Planning  
**Input**: User description: "I want to have a different design for the whole app. Maybe using any UI framework that available as open source but definitely make the app look stunning, easy to use and friendly. I prefer Modern Expressive & Friendly visual style and an Ergonomic Bottom Navigation Bar, but we also need to support foldable phone."

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fresh, Welcoming Visual Identity & Theme Foundation (Priority: P1)

Users interact with an application that feels inviting, delightful, and human-centered from the moment it opens. The interface embraces a Modern Expressive & Friendly design philosophy with warm tonal background palettes, rounded pill containers, soft card geometry (20–28dp radii), approachable brand avatars, high-contrast typography, and fluid micro-interactions across both Light and Dark modes.

**Why this priority**: Visual personality and foundational design tokens (colors, typography, radii, elevation, spacing) dictate the user's perception of "stunning, easy to use, and friendly." All downstream cards, sheets, and controls inherit this foundational design system.

**Independent Test**: Can be tested by launching the app and switching between Light and Dark themes. The app immediately displays harmonious color palettes, rounded pill containers, readable typography, and warm card surfaces without any unstyled elements.

**Acceptance Scenarios**:

1. **Given** a user opens the application, **When** they view any screen in Light or Dark theme, **Then** the interface presents a friendly visual hierarchy with warm tonal background surfaces, rounded card corners (20–28dp), high-contrast legible typography, and cheerful accent highlights.
2. **Given** a user changes their appearance mode or accent color, **When** the new selection is made, **Then** all surfaces, cards, buttons, and navigation elements smoothly update with coherent contrast and accessible text colors (WCAG AA compliant).
3. **Given** a user with accessibility font scaling enabled, **When** they view headings and body text, **Then** all labels scale gracefully without clipping, truncation of critical data, or visual collision.

---

### User Story 2 - Stunning & Effortless OTP Account Card Experience (Priority: P2)

Users can scan their list of two-factor authentication accounts effortlessly. Each account card features prominent brand identification, beautifully grouped and animated verification codes, an intuitive circular or bar-based countdown indicator, and a satisfying 1-tap copy action with clear sensory confirmation.

**Why this priority**: The primary daily task in an authenticator app is finding and copying a 6-to-8 digit code. Making this card stunning and friction-free delivers immediate, tangible daily value to every user.

**Independent Test**: Can be tested by creating or viewing an OTP account in the list. Tapping the code immediately copies it with visual feedback (pulsing checkmark or toast), while the countdown timer smoothly animates until code refresh.

**Acceptance Scenarios**:

1. **Given** an active OTP account, **When** the user views its card in the list, **Then** the verification code is presented in large, easily readable spaced groups (e.g. `123 456`), accompanied by a recognizable issuer avatar/icon, account label, and dynamic progress indicator showing remaining validity seconds.
2. **Given** an active code, **When** the remaining time drops below 5 seconds, **Then** the timer transitions smoothly to a warm warning color without jarring layout shifts or distracting flashing.
3. **Given** an OTP card, **When** the user taps the code or copy button, **Then** the code is copied to the clipboard, accompanied by an immediate friendly micro-interaction (such as an animated check icon and gentle visual confirmation).
4. **Given** multiple accounts, **When** the user searches in the search bar, **Then** the list filters instantly in real time with smooth item repositioning.

---

### User Story 3 - Ergonomic Navigation & Adaptive Foldable Phone Support (Priority: P3)

Users navigate through accounts, vaults/categories, and settings using an ergonomic Bottom Navigation Bar on standard phone displays, while foldable devices (such as Galaxy Z Fold and Pixel Fold) seamlessly adapt between compact outer screen mode and an expansive unfolded multi-column / navigation rail experience.

**Why this priority**: Navigation structure determines whether the app feels simple and friendly or confusing and cluttered. Full foldable support ensures users on modern flexible hardware enjoy a first-class, tailored layout rather than awkwardly stretched mobile views.

**Independent Test**: Can be tested on a standard phone by switching tabs via the bottom navigation bar, and on a foldable device (or emulator with fold simulation) by unfolding the device: the layout dynamically transitions to a multi-column card grid with a side navigation rail, maintaining balanced spacing and 0 layout defects.

**Acceptance Scenarios**:

1. **Given** a user on a standard mobile display or folded outer screen, **When** they navigate the app, **Then** a persistent, thumb-reachable Bottom Navigation Bar provides 1-tap access to primary destinations (Accounts, Vaults, Settings).
2. **Given** a user unfolds a foldable phone (e.g. Galaxy Z Fold, Pixel Fold) or rotates to a wide screen, **When** the display width expands beyond the mobile threshold (>= 600dp), **Then** the bottom navigation bar smoothly transitions into an ergonomic side Navigation Rail, and OTP account cards rearrange into a multi-column grid.
3. **Given** a foldable device in tabletop or half-folded posture, **When** the fold crease is detected, **Then** content aligns to avoid visual clipping or button splitting across the hinge line.
4. **Given** an unfolded foldable or tablet, **When** opening modal dialogs or bottom sheets, **Then** sheets remain centered as floating cards with maxWidth: 640dp constraint, hugging content height without expansive empty top voids.

---

### User Story 4 - Inviting, Human-Centered Forms & Interactive Sheets (Priority: P4)

Users adding an account, configuring cloud sync, or setting up security PINs are guided through clean, friendly modal forms with helpful instructional copy, large touch targets, soft input fields, and clear validation feedback.

**Why this priority**: Setup flows are often where users encounter friction or intimidating technical jargon (e.g. "Base32 secret", "SHA512"). Friendly form design turns technical setup into an approachable experience.

**Independent Test**: Can be tested by opening the "Add Account" flow, entering an account manually or pasting a URI, and submitting. The form provides instant inline validation with supportive error messaging.

**Acceptance Scenarios**:

1. **Given** a user opens the "Add Account" flow, **When** presented with entry options, **Then** options (QR Scan, Paste Key/URI, Manual Form) are presented with friendly descriptive icons and clear, jargon-free labels.
2. **Given** an input field (Issuer, Secret Key, PIN), **When** focused, **Then** the field displays a soft pill border, active accent glow, and clear helper hints.
3. **Given** invalid or incomplete input, **When** the user attempts to submit, **Then** supportive, non-punitive guidance explains exactly how to correct the issue without resetting valid fields.

---

### Edge Cases

- **Dynamic Fold/Unfold Transitions**: When a user folds or unfolds the device mid-session, the app dynamically reorganizes between single-column and multi-column views without losing search state, scroll position, or clipboard feedback.
- **Massive Account Lists (50+ items)**: Virtualized scrolling maintains 60fps/120fps performance with zero stutter; search instantly narrows results with highlighted query matches.
- **Extra Long Account Names or Email Labels**: Text truncates gracefully with middle/end ellipsis or dynamic subtitle wrapping without pushing action buttons off-screen.
- **Device Theme Mismatch**: Manual theme overrides (Light, Dark, System) remain strictly respected across cold boots and system brightness shifts.
- **Code Refresh During Interaction**: If the OTP expires while the user is actively reading or tapping copy, the timer smoothly resets to full period and immediately updates the code without freezing the interface.
- **One-Handed Reachability**: Key action targets (copying codes, initiating account addition, searching) remain accessible within the bottom two-thirds of the screen on folded devices.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST adopt a Modern Expressive & Friendly visual design philosophy featuring warm rounded surfaces (20–28dp radii), approachable tonal pastel container backgrounds, friendly brand avatars, and joyful micro-interactions.
- **FR-002**: The system MUST provide an Ergonomic Bottom Navigation Bar on compact screens (with tabs for Accounts, Vaults, and Settings) that automatically adapts into a side Navigation Rail on wide viewports and unfolded foldable devices.
- **FR-003**: The system MUST present OTP accounts in expressive, high-clarity cards featuring bold grouped verification codes, countdown progress indicators, issuer branding avatars, and 1-tap copy triggers.
- **FR-004**: The system MUST provide instant visual and tactile feedback when a code is copied, showing an animated confirmation state and optional haptic pulse.
- **FR-005**: The system MUST provide a real-time account search bar that instantly filters the list as characters are typed, with clear visual empty states when no matches are found.
- **FR-006**: The system MUST feature an encouraging, friendly empty state for new users with a prominent, welcoming call-to-action to add their first account.
- **FR-007**: The system MUST support seamless Light and Dark modes with automatic contrast adjustments ensuring all text meets or exceeds WCAG 2.1 AA readability standards (minimum 4.5:1 for normal text).
- **FR-008**: The system MUST support user-customizable accent color schemes that dynamically propagate across primary buttons, progress rings, active indicators, and focus states.
- **FR-009**: All modal interactions (adding accounts, editing accounts, confirming destructive decisions, selecting options) MUST be presented as floating slide-up cards with uniform margins (16dp) and rounded corners (28dp).
- **FR-010**: All interactive touch targets MUST have a minimum dimension of 48x48dp to ensure effortless accessibility on mobile touchscreens.
- **FR-011**: Form inputs MUST use soft rounded styling, clear inline labels, assistive placeholder hints, and supportive error guidance without technical jargon.
- **FR-012**: The system MUST adapt dynamically to foldable phone screen transitions, switching seamlessly between single-column mobile view (folded cover screen) and an optimized multi-column layout with centered modal constraints (unfolded wide screen).
- **FR-013**: On unfolded foldable screens and tablets, modals and bottom sheets MUST maintain an intrinsic height layout centered with a maximum width of 640dp, preventing excessive vertical blank space above content.

---

### Key Entities

- **Theme Palette**: Defines tonal primary, secondary, surface, background, outline, error, and text contrast tokens across Light and Dark appearances.
- **Account Display Model**: Represents the visual presentation of an OTP credential, including issuer title, account subtitle, grouped code string, expiration percentage, brand avatar/color, and search tokens.
- **Navigation Destination**: Represents the active top-level view state (Accounts, Vaults, Settings) with corresponding transitions, icons, and adaptive rail/bar layouts.
- **Display Posture Configuration**: Encapsulates device screen category (Compact Phone, Folded Cover, Unfolded Wide/Tablet, Desktop) and dictates layout column count and navigation orientation.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can locate and copy their desired verification code in under 3 seconds from opening the application.
- **SC-002**: 100% of text and visual elements meet or exceed WCAG 2.1 AA contrast requirements (minimum 4.5:1 for standard text, 3:1 for large text and graphical controls) in both Light and Dark modes.
- **SC-003**: First-time users can successfully add an account via QR scan or manual entry in under 30 seconds without encountering unassisted errors.
- **SC-004**: Dynamic fold/unfold layout reorganization completes in under 150ms with zero perceptible UI freezing or state loss.
- **SC-005**: Code list scrolling and search filtering maintain a consistent 60fps/120fps refresh rate with zero frame drops on standard mobile and foldable hardware.
- **SC-006**: User satisfaction evaluation across aesthetic appeal, friendliness, and ease of use achieves at least 90% positive ratings in user testing.

---

## Assumptions

- The redesign focuses on presentation, interaction design, animation, and UI layout; underlying cryptographic algorithms (RFC 6238 TOTP engine, Base32 parser, encryption service) remain intact and fully compatible.
- The design system leverages modern, open-source Flutter design libraries and Material 3 Expressive primitives (such as `shadcn_ui`, `flutter_animate`, `lucide_icons`, or high-end Material 3 expressive tokens) to ensure rapid development and long-term maintainability.
- Foldable detection relies on standard Flutter MediaQuery / DisplayFeature APIs to detect screen width expansion and hinge posture without proprietary device-specific SDKs.
- Haptic feedback will be gracefully omitted on platforms or hardware where vibration hardware is unavailable.
- Offline-first functionality remains preserved; no cloud connectivity is required to render any UI screen or animations.

