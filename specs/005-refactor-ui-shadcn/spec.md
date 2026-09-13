# Feature Specification: Full UI/UX Modernization with Shadcn Design System

**Feature Branch**: `005-refactor-ui-shadcn`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "let's continue with the UI/UX remake. current project uses an implementation of shadcn but the UI/UX still have most of old design. your job now is to refactor the whole UI using that new UI framework with customizations so that the UI looks stunning"

## Clarifications

### Session 2026-09-12

- Q: UI Framework Integration Approach — How should the Shadcn design system be integrated? → A: Option A (`shadcn_ui` Package Integration) — Add `shadcn_ui: ^0.56.3` and `lucide_icons_flutter`, wrap the app with `ShadApp` and custom `ShadThemeData` tokens, and refactor UI components using native Shadcn primitives (`ShadCard`, `ShadButton`, `ShadInput`, `ShadSheet`, `ShadDialog`).
- Q: Theme & Color Palette Styling — Which visual color palette and contrast identity should anchor the new design? → A: Option A (Modern Zinc & Sleek Dark Mode) — Deep neutral/zinc dark backgrounds (`#09090b` / `#18181b`), crisp light mode (`#ffffff` / `#f4f4f5`), subtle 1px border outlines (`#27272a`), and dynamic user-customizable vibrant accent colors.
- Q: Refactoring Coverage Scope — What is the target screen coverage for this UI refactor pass? → A: Option A (Complete App-Wide Overhaul) — Refactor all primary screens: Home Screen, OTP Cards, Header/Search, Add Account & QR Scanner, Edit OTP Screen, Lock Screen, Settings sections, and all confirmation modals/bottom sheets.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Stunning Shadcn Theme & Visual Identity Foundation (Priority: P1)

Users interact with an application that feels exceptionally refined, sleek, and modern from the moment it opens. The interface adopts a customized Shadcn design aesthetic characterized by deep, elegant dark modes (neutral/zinc tones), crisp light modes, subtle 1px border outlines, consistent border radii, refined typography (tabular numerals and clean sans-serif headings), and vibrant dynamic accent highlights across all surfaces.

**Why this priority**: The foundational theme tokens, card surfaces, border treatments, and typography establish the visual hierarchy for the entire app. Every individual screen, card, sheet, and button inherits these design primitives.

**Independent Test**: Can be independently verified by launching the app, toggling between Light and Dark themes, and switching accent colors: all container surfaces, text colors, button styles, borders, and input fields update instantly with pixel-perfect contrast, consistent radii, and no legacy unstyled artifacts.

**Acceptance Scenarios**:

1. **Given** a user opens the application in Dark or Light mode, **When** viewing any view, **Then** all surfaces display a cohesive Shadcn aesthetic featuring subtle border outlines, refined surface elevations, clean typography, and balanced white space.
2. **Given** a user selects a custom accent color, **When** applied, **Then** active indicators, primary action buttons, focus rings, and countdown elements reflect the accent harmoniously against neutral dark or light backgrounds.
3. **Given** an operating system font scaling setting, **When** rendered, **Then** text adapts gracefully without clipping or overlapping border containers.

---

### User Story 2 - Premium OTP Account Cards & Real-Time Interaction (Priority: P2)

Users monitor and interact with their 2FA security tokens through sleek, high-clarity account cards. Each card showcases brand avatars, crisp issuer/account labels, beautifully spaced mono-styled verification codes, an elegant countdown indicator ring/bar, and instant 1-tap copy feedback with tactile sensory confirmation.

**Why this priority**: Viewing and copying security codes is the primary daily interaction in an authenticator. Upgrading this interaction from basic cards to a stunning, micro-animated Shadcn card elevates the user's daily experience.

**Independent Test**: Can be independently verified by viewing a list of OTP accounts: verify smooth 60fps countdown updates without card-level redraw flicker, tap to copy with instant animated confirmation feedback, and observe urgent color transitions when expiration is imminent (<5 seconds).

**Acceptance Scenarios**:

1. **Given** one or more active accounts, **When** displayed in the account list, **Then** codes are presented in bold, legible grouped typography (e.g. `123 456`) with a smooth countdown indicator and clear issuer iconography.
2. **Given** an account card, **When** the user taps the card or code, **Then** the code is copied to the clipboard within 50ms, accompanied by an animated checkmark state and subtle haptic feedback.
3. **Given** a search query entered into the search bar, **When** typing, **Then** accounts filter instantly in real-time with clean Shadcn empty states if no matching accounts exist.

---

### User Story 3 - Sleek Modern Forms, Bottom Sheets, & Action Modals (Priority: P3)

Users adding accounts, editing credentials, scanning QR codes, or confirming deletions interact with beautifully styled Shadcn sheets and forms featuring floating card layouts, rounded corners, clear input labels, smooth focus outlines, and helpful validation feedback.

**Why this priority**: Account creation, editing, and destructive actions require clarity and confidence. Modern, friendly forms turn technical setup (e.g. secret keys, periods, algorithms) into an effortless, error-free experience.

**Independent Test**: Can be tested by triggering the Add Account sheet, pasting an `otpauth://` URI, manually editing an account, and opening confirmation dialogs: verify floating sheet margins, clear input borders, responsive validation messages, and consistent button hierarchies.

**Acceptance Scenarios**:

1. **Given** the user taps "Add Account", **When** the bottom sheet appears, **Then** it renders as a floating card with side margins, featuring clean action tiles for QR scanning, URI paste, and manual entry.
2. **Given** an input form (manual entry or edit screen), **When** a text field receives focus, **Then** it displays an elegant accent outline without layout shifts, and provides inline helper validation.
3. **Given** a destructive action (deleting an account or disconnecting sync), **When** confirmed, **Then** a dedicated confirmation sheet displays clear warning icons, descriptive text, and prominent Confirm/Cancel buttons.

---

### User Story 4 - Cohesive Settings, Security Flow, & Adaptive Navigation (Priority: P4)

Users configuring app preferences, setting up PIN/biometric lock, managing sync repositories, or viewing app info experience unified Shadcn lists, switches, disclosure rows, and badges that adapt smoothly across mobile, tablet, and desktop screens.

**Why this priority**: Polishing secondary screens completes the comprehensive remake, eliminating disjointed legacy views and ensuring end-to-end visual excellence.

**Independent Test**: Can be tested by navigating through all settings sections (Appearance, Cloud Sync, Security, About) and locking/unlocking the app: verify consistent row heights, switches, chevron indicators, and PIN pad layouts.

**Acceptance Scenarios**:

1. **Given** the user opens Settings, **When** browsing sections, **Then** settings rows feature unified padding, clean typography, consistent icons, and custom Shadcn-style toggles.
2. **Given** the app lock screen, **When** prompting for PIN or biometric verification, **Then** the keypad, status indicators, and background follow the refined dark/light theme aesthetic.
3. **Given** a wide desktop window or tablet screen, **When** resizing, **Then** the layout adapts responsively into centered card containers or adaptive multi-column layouts without wide empty voids.

---

### Edge Cases

- **Extreme Screen Dimensions**: On ultra-compact screens (<360dp width) and ultra-wide desktop monitors (>1200dp), forms and card lists must constrain maximum widths (`maxWidth: 640dp` for modals; 2-column grid for wide account views) to prevent awkward stretching.
- **Rapid Token Refresh During Copy**: If a token reaches 0 seconds while the user is tapping copy, the system must copy the valid code for the active counter without desynchronizing the visual animation.
- **High-Density Account Vaults**: Vaults containing 50+ tokens must maintain continuous 60fps rendering and instant search response using virtualized scrolling.
- **System Theme Transitions**: Live switching between OS light and dark modes must immediately propagate across all active widgets without requiring an application restart.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST adopt a unified Shadcn design language across all screens and components, featuring subtle border outlines, refined surface elevations, and coherent border radii.
- **FR-002**: The system MUST integrate the `shadcn_ui` package (`^0.56.3`) and `lucide_icons_flutter`, wrapping the application with `ShadApp` and custom `ShadThemeData` design tokens while leveraging native Shadcn component primitives (`ShadCard`, `ShadButton`, `ShadInput`, `ShadSheet`, `ShadDialog`).
- **FR-003**: The system MUST configure a Modern Zinc & Sleek Dark Mode as the default visual theme (deep zinc backgrounds, crisp light backgrounds, subtle 1px border outlines, and dynamic vibrant accent highlights).
- **FR-004**: The system MUST execute an app-wide refactoring covering Home Screen, OTP Cards, Header/Search, Add Account & QR Scanner, Edit OTP Screen, Lock Screen, Settings sections, and all confirmation modals/bottom sheets into the unified Shadcn design language.
- **FR-005**: The system MUST render OTP account cards with high-clarity monospace codes, countdown progress indicators, brand icons, and instant 1-tap copy interactions with visual/tactile feedback.
- **FR-006**: The system MUST present all dialogs, selection pickers, and input forms as floating bottom sheets with horizontal side margins, rounded corners, and constrained maximum widths on wide screens.
- **FR-007**: The system MUST maintain 100% functional parity with existing features (offline encryption, TOTP calculation, QR scanning, biometric authentication, cloud sync).
- **FR-008**: The system MUST maintain zero static analysis errors (`flutter analyze`) and pass all automated regression test suites (`flutter test`).

### Key Entities *(include if feature involves data)*

- **Theme Configuration**: Encapsulates Shadcn color palettes (background, foreground, card, popover, primary, secondary, muted, accent, destructive, border, input, ring), typography scales, and border radius tokens.
- **Component Variant**: Defines visual variants (default, outline, secondary, ghost, destructive) for interactive elements such as buttons, badges, chips, and cards.
- **Layout Posture**: Represents the display configuration (compact phone, foldable unfolded, tablet, wide desktop) driving responsive multi-column layouts and floating sheet constraints.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of primary application screens, dialogs, and sheets adopt the new Shadcn design language with zero legacy unstyled components remaining.
- **SC-002**: Verification code copy feedback occurs with perceived latency under 50ms with tactile sensory confirmation.
- **SC-003**: 60fps frame rate maintained during continuous 1-second countdown updates across account list views with 20+ accounts.
- **SC-004**: Zero compilation errors, zero linter warnings under `flutter_lints ^6.0.0`, and 100% pass rate across the automated test suite.

## Assumptions

- The existing business logic, SQLite database, encryption services, and TOTP calculation engines remain completely unaffected.
- The refactored UI preserves all existing functionality and user preferences (accent colors, light/dark mode, biometric settings).
- Lucide icons or standardized clean SVG icons will complement the Shadcn aesthetic.
