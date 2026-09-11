# Interface Contract: Component Design Tokens & View Layout

**Contract Scope**: Visual design system, theme tokens, and component interface contracts.

---

## 1. Design Tokens (`AppTheme`)

All visual styling is centralized in `AppTheme` to avoid runtime styling allocations.

### Spatial Dimensions
- Corner Radii:
  - Small (`radiusSm`): `12.0` (cards, snackbars, inputs)
  - Large (`radiusLg`): `28.0` (dialogs, bottom sheets)
  - Pill (`radiusPill`): `24.0` (buttons, chips)
- Card Margins: `vertical: 6.0, horizontal: 16.0`
- Padding: `16.0` standard inner container padding

### Color Schemes & Brightness
- Material 3 dynamic color scheme anchored by user-selected `seedColor`.
- Surface Colors:
  - Light mode: Pure white (`0xFFFFFFFF`)
  - Dark mode: Charcoal (`0xFF1A1C1E`)
  - Dark mode card surface: `0xFF232528`
  - High-urgency indicator (`timeLeft <= 5`): `colorScheme.error`

### Typography Contract
All typography is resolved through Google Fonts Inter within `AppTheme`:
- Large Header (`headlineLarge`): 28pt, bold (used for app titles, no inline GoogleFonts instantiation)
- Card Code (`displaySmall` / custom mono): 32pt, bold, monospace tabular figures
- Issuer Title (`titleMedium`): 16pt, semi-bold
- Account Label (`bodySmall`): 12pt, regular

---

## 2. Component Contracts

### `OtpCard`
```dart
class OtpCard extends StatelessWidget {
  final OtpAccount account;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
}
```
- **Guarantees**:
  - Does NOT rebuild the card background, icons, or text when time ticks.
  - Sub-widgets (`OtpProgressIndicator`, `OtpCodeDisplay`) isolate reactive updates to timer intervals.
  - No entrance `.animate().fadeIn()` called dynamically during periodic rebuilds.

### `HomeHeader`
```dart
class HomeHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const HomeHeader({super.key, required this.title, this.trailing});
}
```
- **Guarantees**:
  - Uses static `AppTheme` styles without re-allocating GoogleFonts instances.
  - `const` constructible to prevent unnecessary rebuilds during search or scroll.

### Responsive View Layout
- On screens narrower than 600px (phones): Single full-width column.
- On screens 600px and wider (tablets, desktop): Centered maximum width container (`maxWidth: 640px`) preventing awkward card stretching.
