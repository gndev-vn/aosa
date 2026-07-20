# FAB Liquid Drip Animation

## Summary
Replace the current spring-scale FAB menu animation with a liquid drip effect. When tapped, the FAB stretches vertically and releases teardrop-shaped drops that fall to their target positions, leaving fluid smear trails.

## Animation Behavior

### Opening (FAB → drops)
1. **FAB stretch** (0–150ms): FAB elongates vertically (scaleY ~1.4, scaleX ~0.75), `+` icon fades out
2. **Drop release** (100–400ms, staggered ~80ms apart): Each drop detaches from bottom of stretched FAB, falls to target. FAB snaps back briefly between releases. Fluid smear trail connects drop to FAB, opacity 0.6→0 with distance
3. **Settle** (300–500ms): Drop bounces at target, action icon fades in

### Closing (drops → FAB)
Reverse of opening, 300ms total. Drops retract upward, trails reform briefly, FAB deflates, `+` icon returns.

### FAB idle
Subtle breathing: scaleY oscillates 1.0↔1.02 over 2s.

## Visual Design

### Drop shape
Teardrop: circle at top tapering to a point at bottom (trail end). Drawn with `CustomPainter` using bezier curves.

### Trail
Series of overlapping circles along the drop's path, decreasing in radius (wider near drop, tapering to nothing) and opacity (0.6 near drop, 0 at tail). Color blends from FAB primary to action color.

### Colors
Each drop uses its action's color. Trail blends from FAB primary color → action color during travel.

## Architecture

### Files to modify
- `app/lib/presentation/widgets/fab_menu.dart` — Complete rewrite with CustomPainter-based animation
- `app/lib/presentation/screens/home_screen.dart` — Update FAB to use breathing idle animation

### New painter classes (in fab_menu.dart)
- `_DropTrailPainter` — CustomPainter for the fluid smear trail
- `_TeardropShape` — Path helper for teardrop shape

### Animation controllers
- `_ctrl` — Main animation (0→1 for open, 1→0 for close)
- `_fabStretchController` — FAB deformation during drop release
- Per-drop controllers for settle bounce (or use intervals on main controller)

### Hit testing
- Drops are tappable via `GestureDetector` on each drop widget
- Background tap dismisses menu (same as current)
