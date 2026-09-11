# Feature Specification: Standardize UI Design & Modal Presentation

**Feature Branch**: `002-standardize-ui-design`

**Created**: 2026-09-07

**Status**: Draft

**Input**: User description: "let's standardize the design: - all dialogs should be shown as bottomsheet - bottomsheet should has margin to the screen left and right edge - settings row should has higher padding left and right so the content not too close to the edges - settings font is a bit thin, let's make the font regular"

## Clarifications

### Session 2026-09-07

- Q: How should the bottom sheet be positioned relative to the bottom edge of the screen when side margins are applied? → A: Option A (Floating Card) — Margins on left, right, and bottom (above safe area) with all four corners rounded (radius 24–28dp).
- Q: How should simple confirmation prompts (such as deleting an OTP account or turning off cloud sync) be structured within the bottom sheet? → A: Option A (Dedicated Confirmation Layout) — Compact card layout with top status/warning icon, bold title, descriptive message, and prominent action buttons (Confirm/Delete and Cancel).
- Q: What font weight hierarchy should be used across Settings rows to ensure high legibility? → A: Option A (Semi-bold & Regular, w600 / w400) — Titles use w600 (semi-bold) and subtitles use w400 (regular) with full contrast opacity.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unified Bottom Sheet Presentation for All Modals (Priority: P1)

As an AOSA user, when I perform an action that requires confirmation or input (e.g., deleting an account, entering a repository name, selecting an option, choosing an accent color, or disconnecting cloud sync), I want the interaction to appear as an intuitive bottom sheet anchored to the bottom of the screen rather than an intrusive centered pop-up dialog box.

**Why this priority**: Unifies modal interactions across the application into a cohesive, thumb-accessible mobile-first design pattern, removing jarring context switches between centered dialogs and bottom sheets.

**Independent Test**: Trigger each modal flow (delete OTP confirmation, disconnect cloud sync, option picker in appearance, create repo in repository manager, custom accent color picker, and paste URI dialog). Verify every interaction appears as a slide-up bottom sheet with consistent header and action layouts.

**Acceptance Scenarios**:

1. **Given** the user is on the OTP account actions sheet, **When** they tap "Delete", **Then** a confirmation bottom sheet slides up from the bottom with "Delete" and "Cancel" actions.
2. **Given** the user is in Settings > Appearance, **When** they tap the Theme or Accent color selector, **Then** an option selector bottom sheet appears from the bottom instead of a centered dialog.
3. **Given** the user is in Settings > Cloud Sync, **When** they toggle cloud sync off, **Then** a confirmation bottom sheet appears asking to confirm disconnect.
4. **Given** the user is in Repo Manager, **When** they tap "Add Repo", **Then** a bottom sheet with a text input appears from the bottom instead of an alert dialog.

---

### User Story 2 - Floating Bottom Sheet Margins (Priority: P2)

As a user on any device (phone, foldable, or tablet), I want bottom sheets to have clear horizontal margins from the left and right edges of the screen, so the sheet looks like a polished, floating card rather than stretching edge-to-edge across the display.

**Why this priority**: Enhances visual ergonomics and modern card aesthetics across various screen sizes, especially on wide screens and foldable devices like Galaxy Z Fold.

**Independent Test**: Open any bottom sheet on both standard mobile viewports (375-412dp wide) and wide/foldable viewports (700-1200dp wide). Verify the sheet maintains distinct horizontal margins from the display boundaries and has clean rounded corners.

**Acceptance Scenarios**:

1. **Given** a user opens any bottom sheet on a mobile device, **When** the sheet is displayed, **Then** it has visible horizontal padding/margin (at least 12-16dp) from the left and right edges of the screen.
2. **Given** a user opens a bottom sheet on a wide foldable or tablet screen, **When** the sheet is displayed, **Then** it is centered horizontally, respects the maximum width limit (640dp), and retains margins from the screen edges.
3. **Given** the sheet is dismissed or dragged down, **When** interacting with the sheet, **Then** the rounded corners and margins remain intact throughout the transition.

---

### User Story 3 - Comfortable Settings Row Padding (Priority: P3)

As a user browsing the Settings screen, I want settings rows to have ample horizontal breathing room inside cards, so icons, labels, and action controls do not sit uncomfortably close to the card borders.

**Why this priority**: Improves visual hierarchy, readability, and tap confidence by preventing content crowding against card edges.

**Independent Test**: Navigate to Settings and inspect each card (Appearance, Security, Cloud Sync, About). Verify that leading icons and trailing controls maintain generous horizontal padding (minimum 16dp) from the card boundary.

**Acceptance Scenarios**:

1. **Given** the user opens Settings, **When** viewing any settings section card, **Then** the leading icon has at least 16dp of left padding from the card edge.
2. **Given** the user views trailing controls (switches, text selectors, chevron icons), **When** viewing the card, **Then** trailing elements maintain at least 16dp of right padding from the card edge.
3. **Given** the user looks at dividers between settings rows, **When** dividers are rendered, **Then** they align harmoniously with the updated row content inset.

---

### User Story 4 - Clear, Regular Typography in Settings (Priority: P4)

As a user reading settings descriptions, labels, and options, I want text to render in regular and medium font weights rather than faint, thin weights, so I can comfortably read all labels in both Light and Dark themes.

**Why this priority**: Eliminates eye strain and visual washout caused by hairline or overly thin font rendering in settings lists and subtitles.

**Independent Test**: Open Settings in both Light and Dark themes. Inspect row titles, subtitles, section headers, and option values. Verify text is rendered with clear regular (`w400`) or medium (`w500`) weights with high contrast against the background.

**Acceptance Scenarios**:

1. **Given** the user views settings item subtitles, **When** subtitles are displayed, **Then** they use regular font weight (`FontWeight.w400`) with full contrast opacity rather than faint/thin weights.
2. **Given** the user views settings row titles, **When** titles are displayed, **Then** they use semi-bold font weight (`FontWeight.w600`) for prominent readability and visual hierarchy.
3. **Given** the user switches between Light and Dark themes, **When** theme toggles, **Then** all settings text remains crisp and easy to read without weight degradation.

---

### Edge Cases

- **Small Viewports (< 360dp width)**: Horizontal margins must not constrain row contents so much that titles or controls wrap awkwardly.
- **On-Screen Soft Keyboard**: When a bottom sheet with a text field (e.g. Repo creation or URI paste) gains focus, the sheet must shift above the keyboard while preserving horizontal margins and scrolling behavior.
- **Dynamic Content Changes**: Option pickers with long option names must truncate cleanly or wrap without overflowing the floating bottom sheet width.
- **System Back and Scrim Taps**: Tapping outside the floating bottom sheet (in the margin or dim area) or triggering the system back button/gesture must cleanly dismiss the sheet.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST present all interactive modal workflows (delete confirmations, sync disconnect confirmation, option picker, custom color picker, repo creation, URI input) as bottom sheets instead of centered alert dialogs.
- **FR-002**: Bottom sheets MUST render as floating cards with uniform margins on the left, right, and bottom (above safe area, minimum 12dp on mobile, up to 16dp).
- **FR-003**: Bottom sheets MUST feature consistent rounded corners on all four corners (24–28dp radius) matching the floating card design language.
- **FR-004**: `SettingsRow` components MUST provide at least 16dp of horizontal padding (left and right) within their enclosing cards.
- **FR-005**: All settings text elements MUST adhere to an explicit weight hierarchy: row titles MUST use semi-bold (`FontWeight.w600`), descriptions and subtitles MUST use regular (`FontWeight.w400` with full contrast opacity), and selector labels MUST use medium (`FontWeight.w500`), prohibiting faint or thin weights (`w100`–`w300`).
- **FR-006**: Dividers separating settings rows MUST be adjusted to start and end consistent with the new horizontal padding.
- **FR-007**: Bottom sheets MUST retain existing responsive constraints (capping at `maxWidth: 640dp` and centering horizontally on wide viewports).
- **FR-008**: Confirmation bottom sheets MUST feature a dedicated compact layout with a status icon, title, description, and primary/cancel action buttons without redundant form grabbers or navigation bars.

### Key Entities

- **StandardBottomSheet**: The reusable container component providing header, navigation, grabber, scrolling content area, and floating margin styling.
- **ConfirmationBottomSheet**: A specialized bottom sheet layout for binary confirmations (e.g. deletion, disconnect) featuring top status icon, title, message, and distinct action buttons.
- **SettingsRow**: The reusable list tile component used across settings sections, providing icon container, title, subtitle, and trailing controls with standardized padding and typography.
- **OptionPicker**: A standardized bottom sheet for picking from a list of options (e.g., Theme mode, auto-lock timeout).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of modal prompts in the application are presented as bottom sheets (`showDialog` / `AlertDialog` eliminated from user-facing flows).
- **SC-002**: Bottom sheets display with visible horizontal spacing (minimum 12dp) from viewport edges on all mobile and wide screens.
- **SC-003**: Settings row content has at least 16dp horizontal inset from the enclosing card edge across all settings sections.
- **SC-004**: Zero typography styles in settings use font weights below `w400`, ensuring distinct regular and medium text hierarchy.
- **SC-005**: All automated regression, widget, and responsive layout tests pass with zero warnings and zero errors (`flutter test` and `flutter analyze`).

## Assumptions

- Floating bottom sheets will use the existing theme surface colors (`AppTheme.darkSurface` / `AppTheme.lightSurface` / `Colors.white`) with elevation or barrier tint.
- The standard width limit of 640dp remains active for large displays (tablets, foldables, desktops), with margins applied relative to the available layout bounds.
- System navigation bars and safe areas will be respected at the bottom of the floating sheet.
