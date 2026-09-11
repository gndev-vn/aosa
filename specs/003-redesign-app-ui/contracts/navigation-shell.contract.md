# Component Contract: Adaptive Navigation Shell

**Feature**: `003-redesign-app-ui`  
**Date**: 2026-09-11  
**Status**: Complete  

---

## 1. Widget Signature

```dart
class AppNavigationShell extends ConsumerStatefulWidget {
  final Widget child; // Or pages: [HomeScreen(), VaultsScreen(), SettingsScreen()]
  final int initialIndex;

  const AppNavigationShell({
    super.key,
    this.initialIndex = 0,
    required this.child,
  });
}
```

---

## 2. Navigation Behavior & Responsive Transition Contract

```dart
enum AppTab {
  accounts(
    label: 'Accounts',
    icon: Icons.shield_outlined,
    selectedIcon: Icons.shield_rounded,
  ),
  vaults(
    label: 'Vaults',
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder_rounded,
  ),
  settings(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  );

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}
```

### Presentation Invariants:
1. **Compact Mode (`width < 600dp`)**:
   - Renders a floating/docked `NavigationBar` at the screen bottom.
   - 3 destinations: Accounts, Vaults, Settings.
   - Includes pill indicator on active destination (`surfaceContainerHighest` or `primaryContainer`).
2. **Foldable Unfolded / Wide Mode (`width >= 600dp`)**:
   - Omits the bottom bar entirely.
   - Renders an ergonomic `NavigationRail` on the leading edge (left in LTR).
   - Rail header includes app branding / logo icon.
   - Extended mode or compact rail depending on available width.
3. **State Preservation**:
   - Tab switching uses `IndexedStack` or `PageController` ensuring scroll position, search queries, and form inputs are preserved without reloading state.

