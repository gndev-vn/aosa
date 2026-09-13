# Phase 1 UI Contracts: Unified Shadcn Primitives & Custom Components

**Feature**: `006-complete-shadcn-rework`  
**Date**: 2026-09-12  
**Status**: Completed  

---

## 1. Direct Primitive Contracts

### Contract: `ShadButton`
Standardizes all interactive button triggers across the application.

```dart
// Primary Action Button
ShadButton(
  onPressed: onSave,
  size: ShadButtonSize.regular,
  child: const Text('Save Account'),
);

// Outline Action Button
ShadButton.outline(
  onPressed: onCancel,
  child: const Text('Cancel'),
);

// Destructive Action Button
ShadButton.destructive(
  onPressed: onDelete,
  child: const Text('Delete Account'),
);

// Ghost Icon Button
ShadButton.ghost(
  size: ShadButtonSize.sm,
  onPressed: onOpenMenu,
  icon: const Icon(LucideIcons.ellipsis, size: 18),
);
```

---

### Contract: `ShadInput`
Standardizes all text input fields in forms and bottom sheets.

```dart
ShadInput(
  controller: controller,
  placeholder: const Text('Enter issuer name'),
  leading: const Icon(LucideIcons.building, size: 16),
  trailing: isNotEmpty 
    ? GestureDetector(
        onTap: controller.clear,
        child: const Icon(Icons.clear, size: 16),
      )
    : null,
);
```

---

### Contract: `ShadCard`
Standardizes elevated container surfaces for OTP tokens, settings sections, and action sheets.

```dart
ShadCard(
  padding: const EdgeInsets.all(16),
  backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
  border: ShadBorder.all(
    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
    width: 1.0,
  ),
  child: cardContent,
);
```

---

### Contract: `ShadSwitch`
Standardizes binary settings toggles (e.g., biometric lock, auto-copy, system brightness).

```dart
ShadSwitch(
  value: isEnabled,
  onChanged: (val) => onToggle(val),
);
```

---

### Contract: `ShadBadge`
Standardizes status chips, category labels, and the OTP "Copy" pill.

```dart
// Copy State Pill
ShadBadge.secondary(
  backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(isCopied ? LucideIcons.check : LucideIcons.copy, size: 12),
      const SizedBox(width: 4),
      Text(isCopied ? 'Copied' : 'Copy'),
    ],
  ),
);
```

---

## 2. Custom Enhancement Contracts

### Contract: `FrostedHeader`
Delivers the glassmorphic frosted app header with blur and semi-transparent Zinc tint.

```dart
class FrostedHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const FrostedHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.darkCanvas : AppTheme.lightCanvas).withOpacity(0.85),
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (leading != null) leading!,
                  Text(title, style: AppTheme.titleStyle),
                  const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### Contract: `VibrantProgressBar`
Delivers the multi-stop gradient countdown progress bar with urgent color transition.

```dart
class VibrantProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final bool isUrgent;   // true when timeLeft < 5s
  final Color accentColor;

  const VibrantProgressBar({
    super.key,
    required this.progress,
    required this.isUrgent,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4.0,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2.0),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2.0),
            gradient: LinearGradient(
              colors: isUrgent
                ? [const Color(0xFFF43F5E), const Color(0xFFFB7185)]
                : [accentColor, accentColor.withOpacity(0.75)],
            ),
          ),
        ),
      ),
    );
  }
}
```
