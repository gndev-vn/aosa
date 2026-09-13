import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';

class AosaInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? leadingIcon;
  final Widget? trailing;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const AosaInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.leadingIcon,
    this.trailing,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.maybeOf(context);
    final isDark = shadTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null && errorText!.isNotEmpty;

    final theme = shadTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: Theme.of(context).colorScheme.primary)
            : AppTheme.shadThemeLight(seedColor: Theme.of(context).colorScheme.primary));

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.foreground,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 6),
        ],
        ShadInput(
          controller: controller,
          focusNode: focusNode,
          placeholder: hint != null ? Text(hint!) : null,
          decoration: hasError
              ? ShadDecoration(
                  border: ShadBorder.all(color: theme.colorScheme.destructive),
                )
              : null,
          leading: leadingIcon != null
              ? Icon(
                  leadingIcon,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                )
              : null,
          trailing: trailing,
          obscureText: obscureText,
          enabled: enabled,
          autofocus: autofocus,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 13,
                color: theme.colorScheme.destructive,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.destructive,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (shadTheme == null) {
      return ShadTheme(
        data: theme,
        child: content,
      );
    }
    return content;
  }
}

