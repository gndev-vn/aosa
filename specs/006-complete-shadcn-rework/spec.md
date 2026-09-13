# Feature Specification: Unified Shadcn Component Rework & Customizations

**Feature Branch**: `006-complete-shadcn-rework`

**Created**: 2026-09-12

**Status**: Draft

**Input**: User description: "so you did not follow my request for the UI rework. I need every component, control, thing follow the shadcn design, with some new customization to make it better. right now it's not what I want to see and the design is mixed between this and that"

## Clarifications

### Session 2026-09-12

- Q1: Component Primitive Architecture → A: Option A (Direct `shadcn_ui` Primitives Everywhere) — Refactor all controls directly to native `shadcn_ui` primitives (`ShadButton`, `ShadInput`, `ShadCard`, `ShadSwitch`, `ShadBadge`, `ShadDialog`, `ShadSheet`), eliminating bespoke container wrappers and any residual Material design artifacts.
- Q2: Visual Customizations & Enhancements → A: Option C (Vibrant Accent & Glassmorphic Accents) — Translucent frosted headers/sheets, vibrant gradient progress indicators, glowing focus rings around active cards, and curated saturated color accents built atop clean Shadcn Zinc foundations.
- Q3: Modal Sheet & Dialog Presentation Style → A: Option C (Adaptive Responsive Modals) — Full-width docked bottom drawers with grab handles on mobile screens, automatically adapting to centered floating dialogs/popovers on wide tablet/desktop viewports.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Universal Shadcn Component Architecture (Priority: P1)

Users interact with an interface where every single visible element—buttons, inputs, card surfaces, switches, badges, progress bars, dialogs, and sheets—strictly adheres to a unified Shadcn design language. There are zero conflicting or unstyled legacy components, no hybrid "mixed between this and that" styling, and every control features uniform corner radii, consistent 1px borders, and coherent typography.

**Why this priority**: A truly cohesive, professional app cannot have mixed design paradigms. Standardizing every component and control on pure Shadcn primitives establishes the bedrock for visual excellence and predictability across the entire product.

**Independent Test**: Can be independently verified by inspecting every screen and modal in the application: verify that all buttons, inputs, switches, cards, badges, and sheets share identical border widths, border colors, focus states, and typography scales without any mismatched elements.

**Acceptance Scenarios**:

1. **Given** any screen in the application (Home, Settings, Edit, Lock), **When** viewed by a user, **Then** all interactive controls (buttons, inputs, switches, cards) render with uniform Shadcn visual characteristics (consistent 1px borders, standardized radii, subtle hover/press states).
2. **Given** any interactive button or control, **When** tapped or focused, **Then** it exhibits clean Shadcn state feedback (subtle scale/opacity/ring) with zero legacy ripple or incongruous styling.
3. **Given** any form input field, **When** focused or in an error state, **Then** it displays an authentic Shadcn border outline and inline message rather than mismatched floating labels or inconsistent outlines.

---

### User Story 2 - Elevated Mobile Customizations & Tactile Feedback (Priority: P2)

Users experience a refined, customized interpretation of Shadcn tailored specifically for a premium mobile authenticator. This includes recessed monospace OTP code badges with tabular figures, smooth linear/circular progress indicators, tactile haptic sensations on copy and tap actions, and curated vibrant accent themes against deep neutral or crisp light surfaces.

**Why this priority**: While standard Shadcn provides a clean baseline, authenticators require specialized, tactile mobile interactions—such as effortless one-tap code copying, urgent countdown transitions, and high-clarity tabular figures.

**Independent Test**: Can be tested on a live device/emulator by interacting with OTP cards: verify tabular figures alignment, countdown transitions as expiration approaches (<5s), smooth animated copy chips, and tactile haptic feedback on interactions.

**Acceptance Scenarios**:

1. **Given** an active OTP card, **When** displaying the authentication code, **Then** the digits are presented in high-contrast tabular monospace figures within a recessed card container that guarantees immediate readability.
2. **Given** an OTP code nearing expiration (<5 seconds remaining), **When** observed, **Then** the countdown indicator smoothly transitions to an urgent color state without jitter or layout reflow.
3. **Given** a user taps to copy a code, **When** triggered, **Then** the UI provides immediate tactile feedback, displays a clean confirmation badge, and updates clipboard contents in under 50ms.

---

### User Story 3 - Cohesive Sheets, Modals, & Form Controls (Priority: P3)

Users creating, editing, importing, or deleting accounts interact with polished modal sheets and dialogs that feel native to the Shadcn design system. Sheets feature rounded tops or floating card presentations with generous padding, static field labels, clear button hierarchies (primary, outline, destructive), and unambiguous confirmation prompts.

**Why this priority**: Account management involves high-stakes security operations (entering secret keys, scanning URIs, deleting accounts). Intuitive, beautifully structured dialogs give users complete confidence during these operations.

**Independent Test**: Can be tested by opening the Add Account sheet, editing an existing account, triggering a delete confirmation, and opening settings sheets: verify consistent sheet padding, high-contrast action buttons, and clear dismiss gestures.

**Acceptance Scenarios**:

1. **Given** the user triggers an account action (Add, Edit, or Delete), **When** the modal appears, **Then** it displays with a clean backdrop dim, rounded corners, clear titles, and standardized action buttons.
2. **Given** a destructive operation (such as deleting an account or wiping local keys), **When** prompted, **Then** a dedicated confirmation dialog clearly explains the consequences using a distinct destructive variant button alongside a neutral cancel button.
3. **Given** an input form within a sheet, **When** the software keyboard appears, **Then** the sheet adjusts dynamically so that action buttons and active inputs remain fully visible without clipping.

---

### User Story 4 - Unified Settings, Navigation, & Multi-Column Layouts (Priority: P4)

Users managing security preferences, theme settings, or cloud sync experience grouped card lists with clean section dividers, standardized switches, and responsive layouts that adapt smoothly from compact mobile viewports to wide tablet and desktop screens.

**Why this priority**: Settings screens and secondary flows must look and feel just as polished and intentional as the primary home screen to eliminate any perception of an incomplete rework.

**Independent Test**: Can be tested by opening Settings, toggling security options, switching themes, and resizing the application window: verify clean grouped card sections, fluid switch toggles, and responsive multi-column layouts on wide displays.

**Acceptance Scenarios**:

1. **Given** the Settings view, **When** scrolling through categories, **Then** items are grouped into distinct, rounded cards with subtle borders and clear section headers.
2. **Given** a toggle switch in settings, **When** flipped, **Then** it animates smoothly with authentic Shadcn pill styling and instant state persistence.
3. **Given** a wide display or tablet orientation, **When** displaying account cards, **Then** the grid responsively presents a balanced 2-column or 3-column layout rather than stretching across the entire width.

---

### Edge Cases

- **Mixed Theme Inheritance**: What happens when a modal sheet is presented while the user changes system theme mode? All open sheets, dialogs, and popovers must update their surfaces and border colors synchronously without visual flicker or unstyled flash.
- **Very Long Account Labels or Issuers**: How does the unified card handle 50+ character account names? Labels must truncate gracefully with ellipsis (`TextOverflow.ellipsis`) while preserving the full width and legibility of the OTP code badge and action icons.
- **Rapid Navigation / Back Swipes**: What happens when a user rapidly dismisses a bottom sheet while an action is executing? The system must gracefully cancel or complete background tasks without throwing unhandled context or lifecycle exceptions.
- **High-Contrast Accessibility Settings**: How do border outlines and text contrast behave under system high-contrast mode? Border contrast must automatically scale to ensure all card boundaries and form controls remain distinctly visible.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST replace all custom, ad-hoc, and Material container wrappers with a standardized suite of unified Shadcn component primitives across every screen and modal.
- **FR-002**: The system MUST adopt a direct `shadcn_ui` primitive architecture across all interactive elements, replacing bespoke container wrappers with `ShadButton`, `ShadInput`, `ShadCard`, `ShadSwitch`, `ShadBadge`, `ShadDialog`, and `ShadSheet`.
- **FR-003**: The system MUST integrate custom visual enhancements atop the Shadcn foundation, including translucent frosted headers and sheets, vibrant gradient progress indicators, glowing focus rings on active elements, and curated saturated color accents.
- **FR-004**: The system MUST present all modal forms and action sheets using an adaptive responsive modal model: docked bottom drawers with grab handles on mobile screens, transitioning automatically to centered floating dialogs/popovers on wide viewports.
- **FR-005**: The system MUST render all OTP codes inside a dedicated recessed badge featuring bold tabular monospace typography and instant 1-tap copy capability with tactile feedback.
- **FR-006**: The system MUST ensure all form inputs feature static label positioning, authentic 1px border outlines, focus highlight rings, and integrated error states without floating Material labels.
- **FR-007**: The system MUST provide responsive multi-column grid layouts for wide viewports and tablets, preventing card stretching beyond optimal readable widths (max 480dp per card).
- **FR-008**: The system MUST maintain 100% feature parity with all existing core functionality (offline encryption, TOTP calculation, QR scanning, biometrics, search, and cloud sync).
- **FR-009**: The system MUST achieve zero static analysis issues under `flutter analyze` and pass 100% of all automated test suites under `flutter test`.

### Key Entities *(include if feature involves data)*

- **Shadcn Component System**: The unified collection of design tokens, primitives (buttons, inputs, cards, switches, badges, sheets, dialogs), and customized variants powering all app surfaces.
- **Card Presentation State**: The active visual state of an OTP account card, including brand icon, issuer text, account label, tabular code display, countdown progress value, and urgent countdown warning status.
- **Modal Surface Configuration**: The presentation metadata governing dialogs and sheets (backdrop blur/dim, corner radius, elevation shadows, layout constraints, dismiss behavior).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of application components, controls, and dialogs adhere to the unified Shadcn design language, with zero residual unstyled or conflicting Material elements.
- **SC-002**: OTP code copy action provides visual confirmation and clipboard update in under 50ms.
- **SC-003**: 60fps frame rate maintained during continuous countdown animations and list scrolling across vaults containing 20+ accounts.
- **SC-004**: 100% pass rate across all automated unit, widget, and responsive layout tests with zero static analysis warnings.

## Assumptions

- The underlying cryptographic, encryption, TOTP computation, and storage logic are preserved without modification.
- Customizations will build upon and elevate the Shadcn foundation rather than introducing incompatible design paradigms.
- The design system will support both Dark Mode (Zinc-950/Zinc-900) and Light Mode (Zinc-100/White) with high-contrast borders and typography.
