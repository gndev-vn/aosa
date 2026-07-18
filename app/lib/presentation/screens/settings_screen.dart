import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/aosa_widgets.dart';
import 'settings_sections/appearance_section.dart';
import 'settings_sections/security_section.dart';
import 'settings_sections/cloud_sync_section.dart';
import 'settings_sections/about_section.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            AosaHeader(
              leading: aosaBackButton(context,
                  onPressed: () =>
                      ref.read(navigationProvider.notifier).goToHome()),
              title: 'Settings',
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
