# Component Contract: Foldable & Adaptive Grid Layout

**Feature**: `003-redesign-app-ui`  
**Date**: 2026-09-11  
**Status**: Complete  

---

## 1. Widget Signature

```dart
class AdaptiveFoldableLayout extends StatelessWidget {
  final Widget Function(BuildContext context, DisplayPosture posture) builder;

  const AdaptiveFoldableLayout({
    super.key,
    required this.builder,
  });
}
```

---

## 2. Layout Invariants & Responsive Breakpoints

1. **Width Breakpoints**:
   - **Compact (`width < 600dp`)**:
     - 1-column vertical card list.
     - Bottom `NavigationBar` active.
     - Horizontal padding: `16dp`.
   - **Foldable Unfolded / Medium (`600dp <= width < 1100dp`)**:
     - 2-column grid for OTP cards (`SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.1)`).
     - Left-docked `NavigationRail` active.
     - Horizontal content padding: `24dp`.
   - **Large Expanded (`width >= 1100dp`)**:
     - Centered content container capped at `maxWidth: 1200dp`.
     - 3-column grid for OTP cards.

2. **Fold Crease & Hinge Handling**:
   - Query `MediaQuery.of(context).displayFeatures` for `DisplayFeatureType.hinge` or `DisplayFeatureType.fold`.
   - In 2-column mode on a book-folded device with vertical hinge:
     - Left column occupies the left sub-screen (left of hinge).
     - Right column occupies the right sub-screen (right of hinge).
     - Ensures no card is positioned or clipped directly over the physical screen fold.

3. **Bottom Sheets on Foldable Viewports**:
   - Modal bottom sheets always constrain width with `ConstrainedBox(maxWidth: 640)`.
   - Floating card margin `16dp` left/right and `16dp` bottom above safe area.
   - Sheets hug intrinsic content height (`mainAxisSize: MainAxisSize.min`), strictly eliminating empty vertical voids on tall or unfolded aspect ratios.

