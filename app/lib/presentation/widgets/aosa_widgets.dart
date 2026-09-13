import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import 'loading_indicator.dart';

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
          if (leading != null) leading! else const SizedBox(width: 8),
          Expanded(
            child: titleWidget ??
                (title != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          title!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: ShadTheme.maybeOf(context)?.colorScheme.foreground ?? cs.onSurface,
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

ShadThemeData _resolveShadTheme(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final seed = Theme.of(context).colorScheme.primary;
  return isDark
      ? AppTheme.shadThemeDark(seedColor: seed)
      : AppTheme.shadThemeLight(seedColor: seed);
}

Widget aosaBackButton(BuildContext context, {VoidCallback? onPressed}) {
  final existingTheme = ShadTheme.maybeOf(context);
  final theme = existingTheme ?? _resolveShadTheme(context);
  final btn = ShadButton.outline(
    width: 36,
    height: 36,
    padding: EdgeInsets.zero,
    onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    child: Icon(
      LucideIcons.arrowLeft,
      size: 16,
      color: theme.colorScheme.foreground,
    ),
  );
  if (existingTheme == null) {
    return ShadTheme(
      data: theme,
      child: btn,
    );
  }
  return btn;
}

Widget aosaIconButton({
  required IconData icon,
  required VoidCallback onPressed,
  Color? color,
}) {
  return Builder(
    builder: (context) {
      final existingTheme = ShadTheme.maybeOf(context);
      final theme = existingTheme ?? _resolveShadTheme(context);
      final btn = ShadButton.outline(
        width: 36,
        height: 36,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Icon(
          icon,
          size: 16,
          color: color ?? theme.colorScheme.foreground,
        ),
      );
      if (existingTheme == null) {
        return ShadTheme(
          data: theme,
          child: btn,
        );
      }
      return btn;
    },
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
    final existingTheme = ShadTheme.maybeOf(context);
    final card = ShadCard(
      padding: padding ?? const EdgeInsets.all(16),
      backgroundColor: color,
      radius: borderRadius != null
          ? BorderRadius.circular(borderRadius!)
          : BorderRadius.circular(AppTheme.radiusSm),
      border: border != null ? ShadBorder.all(color: border!.top.color, width: border!.top.width) : null,
      child: child,
    );

    Widget result = card;
    if (onTap != null || onLongPress != null) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: result,
      );
    }
    if (margin != null) {
      result = Padding(padding: margin!, child: result);
    }
    if (existingTheme == null) {
      return ShadTheme(
        data: _resolveShadTheme(context),
        child: result,
      );
    }
    return result;
  }
}

class AosaSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AosaSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final existingTheme = ShadTheme.maybeOf(context);
    final sw = ShadSwitch(
      value: value,
      onChanged: onChanged,
    );
    if (existingTheme == null) {
      return ShadTheme(
        data: _resolveShadTheme(context),
        child: sw,
      );
    }
    return sw;
  }
}

enum AosaButtonVariant {
  primary,
  secondary,
  outline,
  destructive,
  ghost,
}

enum AosaButtonSize {
  sm,
  md,
  lg,
}

class AosaButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final AosaButtonVariant variant;
  final AosaButtonSize size;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;
  final bool enabled;
  final bool isLoading;
  final Widget? leading;
  final Widget? trailing;

  const AosaButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = AosaButtonVariant.primary,
    this.size = AosaButtonSize.md,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.enabled = true,
    this.isLoading = false,
    this.leading,
    this.trailing,
  });

  const AosaButton.secondary({
    super.key,
    required this.child,
    this.onPressed,
    this.size = AosaButtonSize.md,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.enabled = true,
    this.isLoading = false,
    this.leading,
    this.trailing,
  }) : variant = AosaButtonVariant.secondary;

  const AosaButton.outline({
    super.key,
    required this.child,
    this.onPressed,
    this.size = AosaButtonSize.md,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.enabled = true,
    this.isLoading = false,
    this.leading,
    this.trailing,
  }) : variant = AosaButtonVariant.outline;

  const AosaButton.destructive({
    super.key,
    required this.child,
    this.onPressed,
    this.size = AosaButtonSize.md,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.enabled = true,
    this.isLoading = false,
    this.leading,
    this.trailing,
  }) : variant = AosaButtonVariant.destructive;

  const AosaButton.ghost({
    super.key,
    required this.child,
    this.onPressed,
    this.size = AosaButtonSize.md,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.enabled = true,
    this.isLoading = false,
    this.leading,
    this.trailing,
  }) : variant = AosaButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final defaultHeight = switch (size) {
      AosaButtonSize.sm => 36.0,
      AosaButtonSize.md => 44.0,
      AosaButtonSize.lg => 48.0,
    };
    final btnHeight = height ?? defaultHeight;
    final isActive = enabled && !isLoading && onPressed != null;

    final btnLeading = isLoading
        ? const SizedBox(
            width: 14,
            height: 14,
            child: AosaLoadingIndicator(size: 14),
          )
        : leading;

    final existingTheme = ShadTheme.maybeOf(context);
    final button = switch (variant) {
      AosaButtonVariant.primary => ShadButton(
          onPressed: isActive ? onPressed : null,
          enabled: enabled && !isLoading,
          width: width,
          height: btnHeight,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          leading: btnLeading,
          trailing: trailing,
          child: child,
        ),
      AosaButtonVariant.secondary => ShadButton.secondary(
          onPressed: isActive ? onPressed : null,
          enabled: enabled && !isLoading,
          width: width,
          height: btnHeight,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          leading: btnLeading,
          trailing: trailing,
          child: child,
        ),
      AosaButtonVariant.outline => ShadButton.outline(
          onPressed: isActive ? onPressed : null,
          enabled: enabled && !isLoading,
          width: width,
          height: btnHeight,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          leading: btnLeading,
          trailing: trailing,
          child: child,
        ),
      AosaButtonVariant.destructive => ShadButton.destructive(
          onPressed: isActive ? onPressed : null,
          enabled: enabled && !isLoading,
          width: width,
          height: btnHeight,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          leading: btnLeading,
          trailing: trailing,
          child: child,
        ),
      AosaButtonVariant.ghost => ShadButton.ghost(
          onPressed: isActive ? onPressed : null,
          enabled: enabled && !isLoading,
          width: width,
          height: btnHeight,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          leading: btnLeading,
          trailing: trailing,
          child: child,
        ),
    };

    if (existingTheme == null) {
      return ShadTheme(
        data: _resolveShadTheme(context),
        child: button,
      );
    }
    return button;
  }
}

