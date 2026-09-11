# Phase 1 Data Model: Modern & Friendly UI Redesign with Foldable Support

**Feature**: `003-redesign-app-ui`  
**Date**: 2026-09-11  
**Status**: Completed  

---

## 1. Display & Layout Entities

### `DisplayPosture`
Encapsulates runtime screen geometry, device folding state, and responsive layout decisions.

| Field | Type | Description |
|---|---|---|
| `deviceClass` | `DeviceClass` (`compact`, `medium`, `expanded`) | Categorized screen size based on effective width |
| `screenWidth` | `double` | Logical width of active viewport |
| `screenHeight` | `double` | Logical height of active viewport |
| `isFoldable` | `bool` | True if device features physical fold or hinge display feature |
| `hingeBounds` | `Rect?` | Screen coordinates occupied by fold crease (if present) |
| `gridColumns` | `int` | Number of columns for OTP card grid (`1` if width < 600dp, `2` if width >= 600dp, `3` if width >= 1100dp) |
| `useNavigationRail` | `bool` | True if screen should use side `NavigationRail` instead of bottom `NavigationBar` |

#### Validation & Breakpoint Rules
- `compact`: `screenWidth < 600dp` → `gridColumns = 1`, `useNavigationRail = false`
- `medium` (Foldable unfolded, Galaxy Z Fold, Pixel Fold, iPad mini): `600dp <= screenWidth < 840dp` → `gridColumns = 2`, `useNavigationRail = true`
- `expanded` (Large tablets, Desktop): `screenWidth >= 840dp` → `gridColumns = 2` or `3` (max container width 1080dp), `useNavigationRail = true`

---

## 2. Navigation State Entities

### `NavigationDestination`
Defines available top-level navigation tabs in the application shell.

| Field | Type | Description |
|---|---|---|
| `tab` | `AppTab` (`accounts`, `vaults`, `settings`) | Unique tab identifier |
| `label` | `String` | Human-readable title (*Accounts*, *Vaults*, *Settings*) |
| `icon` | `IconData` | Inactive outlined icon |
| `selectedIcon` | `IconData` | Active filled/expressive icon |
| `badgeCount` | `int?` | Optional counter badge (e.g. number of pending sync items) |

---

## 3. Presentation View Models

### `OtpCardViewModel`
Enriched visual model derived from `OtpAccount` entity for rendering the expressive OTP card.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Unique account identifier |
| `issuer` | `String` | Service or organization name (e.g. "GitHub", "Google") |
| `accountLabel` | `String?` | Account identifier (e.g. "user@example.com") |
| `rawCode` | `String` | Current 6-digit or 8-digit OTP string |
| `formattedCode` | `String` | Digit-grouped code with friendly separator (e.g. `482 · 910` or `1234 · 5678`) |
| `remainingSeconds` | `int` | Integer seconds remaining in current time window |
| `progress` | `double` | Normalised timer progress value `0.0` (empty) to `1.0` (full) |
| `isExpiringSoon` | `bool` | True when `remainingSeconds <= 5` (triggers warm warning amber state) |
| `isFavorite` | `bool` | Whether account is starred as favorite |
| `avatarInitials` | `String` | 1 or 2 uppercase letters representing the issuer monogram |
| `avatarColor` | `Color` | Deterministic pastel container color generated from issuer string hash |

---

## 4. Theme Token Entity

### `AppThemeTokens`
Comprehensive design tokens expressing the Modern Expressive & Friendly personality.

| Token | Type | Light Value | Dark Value | Purpose |
|---|---|---|---|---|
| `surfacePrimary` | `Color` | `#F8F9FC` | `#111318` | Base window canvas |
| `cardSurface` | `Color` | `#FFFFFF` | `#1D2026` | Card background fill |
| `cardBorder` | `Color` | `rgba(0,0,0,0.06)` | `rgba(255,255,255,0.08)` | Soft 1px micro-border |
| `pillRadius` | `BorderRadius` | `BorderRadius.circular(24)` | `BorderRadius.circular(24)` | Chip & selector rounding |
| `cardRadius` | `BorderRadius` | `BorderRadius.circular(24)` | `BorderRadius.circular(24)` | OTP card and card containers |
| `sheetRadius` | `BorderRadius` | `BorderRadius.circular(28)` | `BorderRadius.circular(28)` | Bottom sheet cards |
| `timerWarning` | `Color` | `#E65100` (Deep Orange) | `#FFA726` (Amber Accent) | Expiration warning |

