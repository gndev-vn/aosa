import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/settings_helpers.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final shadTheme = ShadTheme.maybeOf(context);
    final isDark = shadTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final primary = shadTheme?.colorScheme.primary ?? cs.primary;
    final primaryFg = shadTheme?.colorScheme.primaryForeground ?? cs.onPrimary;
    final mutedFg = shadTheme?.colorScheme.mutedForeground ??
        (isDark ? AppTheme.darkMuted : AppTheme.lightMuted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'About'),
        ShadCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsRow(
                leading: ShadAvatar(
                  null,
                  size: const Size.square(28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  backgroundColor: primary,
                  placeholder: Text(
                    'A',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryFg,
                    ),
                  ),
                ),
                title: 'AOSA',
                subtitle: 'Version 0.0.1',
              ),
              const ThinDivider(),
              SettingsRow(
                leading: const IconBox(icon: LucideIcons.code),
                title: 'License',
                trailing: Text(
                  'MIT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: mutedFg,
                  ),
                ),
              ),
              const ThinDivider(),
              SettingsRow(
                leading: const IconBox(icon: LucideIcons.externalLink),
                title: 'Source code',
                trailing: Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: mutedFg,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
