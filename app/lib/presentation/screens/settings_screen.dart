import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shadcn_ui/shadcn_ui.dart';

import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';
import 'settings_sections/about_section.dart';
import 'settings_sections/appearance_section.dart';
import 'settings_sections/cloud_sync_section.dart';
import 'settings_sections/security_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final shadTheme = ShadTheme.maybeOf(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Row(
                children: [
                  ShadButton.outline(
                    width: 36,
                    height: 36,
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        ref.read(navigationProvider.notifier).goToHome(),
                    child: const Icon(LucideIcons.arrowLeft, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: shadTheme?.colorScheme.foreground,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppearanceSection(settings: settings),
            const SizedBox(height: 24),
            SecuritySection(settings: settings),
            const SizedBox(height: 24),
            CloudSyncSection(settings: settings),
            const SizedBox(height: 24),
            const AboutSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
