import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import 'option_picker.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.maybeOf(context);
    final isDark = shadTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final muted = shadTheme?.colorScheme.mutedForeground ??
        (isDark ? AppTheme.darkMuted : AppTheme.lightMuted);

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: muted,
        ),
      ),
    );
  }
}

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const IconBox({super.key, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.maybeOf(context);
    final iconColor = color ?? shadTheme?.colorScheme.foreground;

    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.maybeOf(context);
    final isDark = shadTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final fg = shadTheme?.colorScheme.foreground ??
        Theme.of(context).colorScheme.onSurface;
    final muted = shadTheme?.colorScheme.mutedForeground ??
        (isDark ? AppTheme.darkMuted : AppTheme.lightMuted);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: fg,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap!();
      },
      child: content,
    );
  }
}

class ThinDivider extends StatelessWidget {
  final double indent;
  final double endIndent;

  const ThinDivider({
    super.key,
    this.indent = 66,
    this.endIndent = 16,
  });

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.maybeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = shadTheme?.colorScheme.border ??
        (isDark ? AppTheme.darkBorder : AppTheme.lightBorder);
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: indent, right: endIndent),
      color: borderColor,
    );
  }
}

class SettingsSelector extends StatelessWidget {
  final String? title;
  final String value;
  final List<(String label, String value)> options;
  final ValueChanged<String> onChanged;

  const SettingsSelector({
    super.key,
    this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final existingTheme = ShadTheme.maybeOf(context);
    final isDark = existingTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final seed = Theme.of(context).colorScheme.primary;
    final theme = existingTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: seed)
            : AppTheme.shadThemeLight(seedColor: seed));
    final currentLabel = options
        .firstWhere((o) => o.$2 == value, orElse: () => (value, value))
        .$1;

    final btn = ShadButton.outline(
      size: ShadButtonSize.sm,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      onPressed: () {
        HapticFeedback.lightImpact();
        showOptionPickerSheet(
          context,
          title: title ?? '',
          options: options,
          selected: value,
        ).then((result) {
          if (result != null && result != value) {
            onChanged(result);
          }
        });
      },
      trailing: Icon(
        LucideIcons.chevronsUpDown,
        size: 13,
        color: theme.colorScheme.mutedForeground,
      ),
      child: Text(
        currentLabel,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.foreground,
        ),
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
}
