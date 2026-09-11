import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/aosa_widgets.dart';
import '../../widgets/accent_color_picker.dart';
import '../../widgets/settings_helpers.dart';
import '../../widgets/standard_bottom_sheet.dart';

class AppearanceSection extends ConsumerWidget {
  final AppSettings settings;

  const AppearanceSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Appearance'),
        AosaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsRow(
                leading: const IconBox(icon: Icons.palette_outlined),
                title: 'Theme',
                trailing: SettingsSelector(
                  title: 'Theme',
                  value: settings.themeMode.name,
                  options: const [
                    ('Light', 'light'),
                    ('Dark', 'dark'),
                    ('System', 'system'),
                  ],
                  onChanged: (v) {
                    final notifier = ref.read(settingsProvider.notifier);
                    if (v == 'light') notifier.setThemeMode(AppThemeMode.light);
                    if (v == 'dark') notifier.setThemeMode(AppThemeMode.dark);
                    if (v == 'system') notifier.setThemeMode(AppThemeMode.system);
                  },
                ),
              ),
              if (settings.themeMode != AppThemeMode.dark)
                const ThinDivider(),
              if (settings.themeMode != AppThemeMode.dark)
                SettingsRow(
                  leading: const IconBox(icon: Icons.colorize_outlined),
                  title: 'Accent color',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(settings.seedColor),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right,
                          size: 18, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  onTap: () {
                    showSlideBottomSheet<void>(
                      context,
                      builder: (_) => const AccentColorPicker(),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
