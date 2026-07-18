import 'package:flutter/material.dart';

import '../../widgets/aosa_widgets.dart';
import '../../widgets/settings_helpers.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'About'),
        AosaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsRow(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withAlpha(180),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                title: 'AOSA',
                subtitle: 'Version 0.0.1',
              ),
              const ThinDivider(),
              SettingsRow(
                leading: IconBox(
                  icon: Icons.code_rounded,
                  color: colorScheme.surfaceContainerHighest,
                ),
                title: 'License',
                trailing: Text(
                  'MIT',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const ThinDivider(),
              SettingsRow(
                leading: IconBox(
                  icon: Icons.open_in_new_rounded,
                  color: colorScheme.surfaceContainerHighest,
                ),
                title: 'Source code',
                trailing: Icon(Icons.chevron_right,
                    size: 18, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
