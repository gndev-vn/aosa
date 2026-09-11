# Component Contract: Expressive OTP Card Presentation

**Feature**: `003-redesign-app-ui`  
**Date**: 2026-09-11  
**Status**: Complete  

---

## 1. Widget Signature

```dart
class ExpressiveOtpCard extends StatefulWidget {
  final OtpCardItem item; // Contains OtpAccount entity and runtime parameters
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;

  const ExpressiveOtpCard({
    super.key,
    required this.item,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
  });
}
```

---

## 2. Visual & Interaction Invariants

1. **Card Container**:
   - `BorderRadius.circular(24)`
   - Background: `Theme.of(context).colorScheme.surface` (Light: pure white / soft tint; Dark: rich dark charcoal)
   - Border: 1px subtle outline `colorScheme.outlineVariant.withAlpha(50)`
   - Soft elevation shadow: `BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 16, offset: Offset(0, 4))`
   - Padding: `const EdgeInsets.all(18)`

2. **Header Row**:
   - Leading: 44x44dp brand avatar container (`BorderRadius.circular(14)`) with deterministic vibrant background generated from issuer hash and clean monogram letters or brand icon.
   - Title: Issuer name (`fontSize: 17`, `fontWeight: FontWeight.w700`, maxLines: 1, ellipsis).
   - Subtitle: Account label (`fontSize: 13`, `fontWeight: FontWeight.w400`, color: `onSurfaceVariant`, maxLines: 1, ellipsis).
   - Trailing: Action popup menu or favorite star button.

3. **Code & Timer Row**:
   - Code Display: Large, spaced digit groups (`fontSize: 26`, `letterSpacing: 2.0`, `FontWeight.w700`, monospaced numeral font features `[FontFeature.tabularFigures()]`). Example: `834 · 291` or `1234 · 5678`.
   - Countdown Progress Ring:
     - Circular indicator (`size: 38`, `strokeWidth: 3.5`).
     - Normal state: `colorScheme.primary`.
     - Expiring warning state (`remaining <= 5s`): Smooth color transition to `Colors.deepOrangeAccent` or `Colors.amber[700]`.
     - Center text: Integer seconds remaining (`fontSize: 12`, `fontWeight: FontWeight.w700`).

4. **1-Tap Copy Trigger**:
   - Tapping the code or copy button triggers:
     - Immediate clipboard copy of raw unspaced digits.
     - Animated icon transformation: `Icons.copy_rounded` morphs to `Icons.check_circle_rounded` in accent color for 1.8 seconds.
     - Visual snackbar / floating pill banner: `"Copied 834 291 to clipboard"`.
     - Light haptic feedback tap (`HapticFeedback.lightImpact()`).

