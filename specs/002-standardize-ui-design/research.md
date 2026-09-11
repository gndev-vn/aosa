# Phase 0 Research: Standardize UI Design & Modal Presentation

**Feature**: `002-standardize-ui-design`
**Date**: 2026-09-11
**Status**: Completed

## 1. Floating Bottom Sheet Architecture & Margin Implementation

### Context
User requested that all bottom sheets have horizontal margins to the left and right screen edges, and clarifications established that sheets should follow a **Floating Card** design with uniform margins on the left, right, and bottom (above safe area) and rounded corners on all four corners (24–28dp radius).

### Decision
- In `showSlideBottomSheet`, set `backgroundColor: Colors.transparent` and `elevation: 0` on `showModalBottomSheet`.
- In `StandardBottomSheet` (and `ConfirmationBottomSheet`), wrap the sheet content in an outer `Padding` providing:
  - Left & right margins: `16dp`
  - Bottom margin: `max(16dp, MediaQuery.of(context).padding.bottom)` or `viewInsets.bottom + 16dp` when keyboard is visible.
- Enclose the sheet body in a `Material` card with `borderRadius: BorderRadius.circular(28)`, `clipBehavior: Clip.antiAlias`, and background color from `Theme.of(context).colorScheme.surface` (or `dialogBackgroundColor`).
- Retain `constraints: const BoxConstraints(maxWidth: 640)` so that on wide viewports (Galaxy Z Fold unfolded, tablets, desktop), the sheet is horizontally centered, capped at 640dp, and maintains comfortable screen margins.

### Rationale
- Using a transparent bottom sheet background in Flutter's `showModalBottomSheet` decouples the physical sheet boundary from the root window edges, allowing genuine floating card margins with rounded bottom corners without clipping or gesture conflicts.
- `MediaQuery.viewInsets.bottom` integration ensures that input sheets (such as creating a repository or pasting a URI) smoothly slide up above the software keyboard while preserving the 16dp floating card offset.
- `ConstrainedBox(maxWidth: 640)` naturally interacts with Flutter's modal bottom sheet layout to center the card on wide viewports.

### Alternatives Considered
- **Anchored Inset Sheet (flush bottom)**: Margins on sides, but flat bottom attached to the screen edge. Rejected per user clarification; floating card with all 4 corners rounded provides a more cohesive, modern aesthetic.
- **Root Dialog (showDialog with alignment: bottomCenter)**: Using `showDialog` with custom transitions. Rejected because Flutter's `showModalBottomSheet` provides native drag-to-dismiss velocity tracking, modal barrier dismissal, and standard sheet lifecycle semantics.

---

## 2. Dialog Elimination & Standardized Modal Presentation

### Context
Currently, several workflows across the app use centered `showDialog<T>` or `AlertDialog`:
1. `showConfirmDeleteDialog` in `confirm_delete_dialog.dart` (delete OTP account)
2. `AosaConfirmDialog` in `add_otp_bottom_sheet.dart` (paste URI validation)
3. `OptionPicker` in `option_picker.dart` & `settings_helpers.dart` (Theme, Auto-lock)
4. Cloud sync disconnect confirmation in `cloud_sync_section.dart`
5. `_showCreateDialog` in `repo_manager_sheet.dart` (create new repo)
6. `AccentColorPicker` in `appearance_section.dart`

### Decision
- **Create `ConfirmationBottomSheet`**: A reusable, dedicated confirmation component in `lib/presentation/widgets/confirmation_bottom_sheet.dart` featuring:
  - Prominent top status/warning icon in an accent or error container
  - Bold title (`fontSize: 20`, `FontWeight.w700`)
  - Description message (`fontSize: 14`, high contrast)
  - Action buttons: Primary/Destructive filled button + Cancel outlined/tonal button
- **Refactor `OptionPicker`**: Transform `OptionPicker` from a `Dialog` into a bottom sheet invoked via `showSlideBottomSheet`.
- **Refactor `_showCreateDialog`**: Present the repository creation form inside a `StandardBottomSheet` with title "Create Repo", text field, and Save/Cancel actions.
- **Refactor `AccentColorPicker`**: Present color selection in a `StandardBottomSheet` with title "Accent Color".
- **Refactor `_showPasteUriDialog`**: Present URI import inside a `StandardBottomSheet`.

### Rationale
- Completely eliminates centered alert dialog pop-ups, unifying the application's mobile navigation pattern to thumb-friendly bottom sheets.
- Separate `ConfirmationBottomSheet` prevents confirmation prompts from having redundant form grabbers and header bars, optimizing decision focus and safety for destructive actions.

### Alternatives Considered
- **One single monolithic sheet widget**: Forcing confirmations into `StandardBottomSheet` with form headers. Rejected per clarification because binary decisions (e.g. Delete Account) are clearer and more accessible with centered status icons and direct action buttons.

---

## 3. Settings Row Padding & Typography Hierarchy

### Context
User reported:
1. "settings row should has higher padding left and right so the content not too close to the edges" (currently only 4dp).
2. "settings font is a bit thin, let's make the font regular".

### Decision
- **Padding**:
  - Increase `SettingsRow` horizontal padding from `4dp` to `16dp`.
  - Maintain `vertical: 14dp` for comfortable tap height (> 48dp touch target).
  - Update `ThinDivider` indent: with `16dp` left padding + `36dp` icon box + `14dp` gap, the text starts at `66dp`. Set `ThinDivider(indent: 66, endIndent: 16)` for clean alignment with the text baseline.
- **Typography**:
  - `SettingsRow` title: `fontSize: 16`, `fontWeight: FontWeight.w600` (semi-bold).
  - `SettingsRow` subtitle: `fontSize: 13`, `fontWeight: FontWeight.w400` (regular), with full opacity (`cs.onSurfaceVariant`).
  - `SettingsSelector` current label: `fontSize: 14`, `fontWeight: FontWeight.w500` (medium).
  - `SectionHeader` title: `fontSize: 14` or `15`, `fontWeight: FontWeight.w700`.

### Rationale
- `16dp` padding matches standard card padding conventions, providing immediate visual relief from card borders.
- Promoting titles to `w600` (semi-bold) gives crisp visual contrast against `w400` regular subtitles, resolving the perception of faint or thin typography in both Light and Dark themes.

### Alternatives Considered
- `24dp` horizontal padding: Evaluated, but on compact mobile devices (360dp width), 24dp padding significantly narrows available space for titles and trailing selectors, causing premature text wrapping. 16dp is the optimal balance.
