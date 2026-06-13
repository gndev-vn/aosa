import 'package:flutter/material.dart';

class AosaHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget? leading;
  final List<Widget>? actions;
  final ColorScheme? colorScheme;
  final bool transparent;

  const AosaHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.colorScheme,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme ?? Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          if (leading != null)
            leading!
          else
            const SizedBox(width: 8),
          Expanded(
            child: titleWidget ??
                (title != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          title!,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: cs.onSurface,
                          ),
                        ),
                      )
                    : const SizedBox()),
          ),
          if (actions != null) ...actions!,
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}

Widget aosaBackButton(BuildContext context, {VoidCallback? onPressed}) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          cs.primary.withAlpha(30),
          cs.primary.withAlpha(15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: cs.primary.withAlpha(30),
        width: 0.5,
      ),
    ),
    child: IconButton(
      icon: Icon(Icons.arrow_back_rounded, size: 20, color: cs.onSurface),
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      padding: EdgeInsets.zero,
    ),
  );
}

Widget aosaIconButton({
  required IconData icon,
  required VoidCallback onPressed,
  Color? color,
}) {
  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
    ),
    child: IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      color: color,
    ),
  );
}

class AosaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? color;
  final Border? border;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AosaCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.border,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final radius = borderRadius ?? 16.0;

    final container = Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? (isDark ? const Color(0xFF232528) : cs.surface),
        borderRadius: BorderRadius.circular(radius),
        border: border ??
            Border.all(
              color: isDark
                  ? Colors.white.withAlpha(15)
                  : Colors.black.withAlpha(10),
              width: 0.5,
            ),
      ),
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: container,
      );
    }
    return container;
  }
}

class AosaSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AosaSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? cs.primary : cs.surfaceContainerHighest,
          border: value
              ? null
              : Border.all(
                  color: cs.outlineVariant,
                  width: 1,
                ),
        ),
        padding: const EdgeInsets.all(3),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AosaButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double borderRadius;
  final bool enabled;

  const AosaButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height = 52,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius = 14,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = enabled && onPressed != null;
    final bg = backgroundColor ?? cs.primary;
    final fg = foregroundColor ?? cs.onPrimary;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: GestureDetector(
        onTap: isActive ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive ? bg : bg.withAlpha(80),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isActive ? bg : bg.withAlpha(40),
              width: 1,
            ),
          ),
          child: Center(
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isActive ? fg : fg.withAlpha(160),
              ),
              child: IconTheme(
                data: IconThemeData(
                  size: 20,
                  color: isActive ? fg : fg.withAlpha(160),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
