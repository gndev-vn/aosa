# Phase 0 Research: Unified Shadcn Component Rework & Customizations

**Feature**: `006-complete-shadcn-rework`  
**Date**: 2026-09-12  
**Status**: Completed  

---

## 1. Direct `shadcn_ui` Primitives Migration

### Problem & Context
The user identified that the previous refactor was "mixed between this and that": custom `Container` decorations, `TextField` wrappers, and Flutter Material buttons were coexisting with partial Shadcn tokens rather than providing an authentic, pure Shadcn component experience. In Q1, the user explicitly selected **Option A: Direct `shadcn_ui` Primitives Everywhere**.

### Decision
Directly replace bespoke container widgets and custom button/input implementations with native `shadcn_ui` primitives:
- **Buttons**: Use `ShadButton`, `ShadButton.outline`, `ShadButton.secondary`, `ShadButton.destructive`, and `ShadButton.ghost`.
- **Inputs**: Use `ShadInput` and `ShadInputFormField` with static labels, 1px borders, and built-in focus rings.
- **Card Surfaces**: Use `ShadCard` with uniform padding, 1px Zinc borders, and standardized radii.
- **Switches**: Use `ShadSwitch` with authentic pill track and smooth thumb transition.
- **Badges**: Use `ShadBadge`, `ShadBadge.secondary`, and `ShadBadge.outline` for OTP copy chips, status badges, and chip labels.
- **Dialogs & Modals**: Use `ShadDialog` and `showShadDialog` / `showShadSheet` (with `side: ShadSheetSide.bottom`).
- **Progress**: Use `ShadProgress` styled with vibrant gradients for OTP timer countdowns.

### Rationale
Using the official `shadcn_ui` primitives directly eliminates visual drift, guarantees identical state behaviors (hover, active, focus, disabled), and ensures complete visual coherence across all screens and bottom sheets.

### Alternatives Considered
- *Custom Aosa* wrappers around Flutter widgets*: Rejected because bespoke containers easily deviate from Shadcn specifications and produce an inconsistent, hybrid appearance.
- *Hybrid adoption*: Rejected per user instruction (Q1: Option A) to eliminate all mixed styling.

---

## 2. Vibrant Accent & Glassmorphic Customizations

### Problem & Context
Standard Shadcn provides a clean, neutral minimalist foundation (Zinc/Slate), but mobile authenticator apps require immediate visual hierarchy, urgent expiration feedback, and high visual appeal. In Q2, the user selected **Option C: Vibrant Accent & Glassmorphic Accents**.

### Decision
Implement targeted visual enhancements on top of the Shadcn Zinc base:
1. **Frosted Translucent Header**:
   - Wrap the top app header in `ClipRect` + `BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12))` with a subtle semi-transparent Zinc surface (`Color(0xE609090B)` in dark mode, `Color(0xE6F4F4F5)` in light mode) and a 1px bottom border.
2. **Vibrant Gradient Progress Indicator**:
   - Customize the OTP countdown bar with a vibrant multi-stop gradient (e.g. emerald/cyan -> violet, shifting to fiery rose/amber when <5 seconds remain).
3. **Glowing Focus Rings**:
   - Active cards and focused inputs display a vibrant, smooth glow ring using the user's selected accent color (e.g. Emerald, Sky, Violet).
4. **Recessed Tabular Monospace Code Container**:
   - High-contrast tabular figures (`FontFeature.tabularFigures()`) framed inside an elevated/recessed card container with a sleek "Copy" badge.

### Rationale
These customizations elevate the authenticator from a standard web UI clone into a state-of-the-art mobile experience, blending Shadcn's clean typography and borders with rich mobile micro-aesthetics.

### Alternatives Considered
- *Flat Monochrome Monolith*: Rejected per user choice Q2: Option C.
- *Heavy Skeuomorphism*: Rejected as incompatible with modern Shadcn design language.

---

## 3. Adaptive Responsive Modals & Sheet Presentation

### Problem & Context
Authenticator operations include Add OTP, Edit OTP, Theme picker, and Delete confirmation. In Q3, the user selected **Option C: Adaptive Responsive Modals**.

### Decision
Implement an adaptive modal presentation pattern:
- **Mobile Viewports (<600dp)**:
  - Present as a docked bottom drawer with smooth grab handle, rounded top corners (`AppTheme.radiusLg` / 20-28dp), full device width, and upward slide animation.
- **Wide Viewports (>=600dp / Desktop & Tablet)**:
  - Automatically adapt to a centered floating modal dialog constrained to `maxWidth: 640dp`, preserving desktop usability and avoiding wide, stretched sheets.
- **Test Compatibility**:
  - Preserve the `StandardBottomSheet` and `ConfirmationBottomSheet` widget wrappers required by regression test suites, while updating their internal contents to use direct `ShadButton`, `ShadCard`, and `ShadInput` primitives.

### Rationale
Provides optimal ergonomic reach on mobile devices (thumb zone at bottom) while feeling like a native desktop dialog on tablets and desktop monitors.

### Alternatives Considered
- *Floating Card Sheets Only on Mobile*: Rejected per user choice Q3: Option C.
- *Strict Dialogs Only*: Poor mobile ergonomics; thumbs cannot easily reach center on large phones.

---

## 4. Test Suite Compatibility & Architecture

### Problem & Context
The test suite has 96 existing tests that enforce specific widget contracts (e.g., `find.text('AOSA')`, `find.byType(TextField)`, `find.byType(StandardBottomSheet)`, `find.descendant(of: ..., matching: find.byType(Material))`).

### Decision
- Keep root application configured with `ShadApp.custom` wrapping `MaterialApp` and `ShadAppBuilder` so that all `ShadTheme`, `MaterialTheme`, and `ScaffoldMessenger` contexts remain available simultaneously.
- Since `ShadInput` internally uses `TextField`, all existing `find.byType(TextField)` assertions in search and form tests will continue to pass seamlessly.
- Preserve widget class names (`StandardBottomSheet`, `ConfirmationBottomSheet`, `HomeEmptyState`) while upgrading their child hierarchies to native Shadcn components.

---

## 5. Summary of Decisions

| Area | Decision | Implementation Path |
| :--- | :--- | :--- |
| **Component Primitives** | Direct `shadcn_ui` primitives | Replace bespoke wrappers with `ShadButton`, `ShadInput`, `ShadCard`, `ShadSwitch`, `ShadBadge`, `ShadProgress`. |
| **Visual Customization** | Glassmorphic & Vibrant Accents | Frosted blurred header, vibrant gradient countdown progress, glowing accent focus rings, tabular mono OTP badge. |
| **Modal Presentation** | Adaptive Responsive Modals | Docked bottom drawer on mobile (<600dp); centered floating dialog on wide viewports (>=600dp). |
| **Theme System** | Zinc Light & Dark + Custom Accents | Zinc-950/Zinc-900 (Dark), Zinc-100/White (Light), dynamic user accent color. |
| **Testing** | Zero Regression | Retain all test-expected text, finders, and layout constraints (maxWidth: 640). |
