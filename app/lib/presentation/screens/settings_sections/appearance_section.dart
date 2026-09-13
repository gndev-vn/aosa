import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../domain/entities/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/accent_color_picker.dart';
import '../../widgets/settings_helpers.dart';
import '../../widgets/standard_bottom_sheet.dart';

class AppearanceSection extends ConsumerWidget {
  final AppSettings settings;

  const AppearanceSection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Appearance'),
        ShadCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsRow(
                leading: const IconBox(icon: LucideIcons.palette),
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
                  leading: const IconBox(icon: LucideIcons.pipette),
                  title: 'Accent color',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShadAvatar(
                        null,
                        size: const Size.square(24),
                        shape: const CircleBorder(),
                        backgroundColor: Color(settings.seedColor),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: ShadTheme.of(context).colorScheme.mutedForeground,
                      ),
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
