import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../domain/entities/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/pin_setup_dialog.dart';
import '../../widgets/settings_helpers.dart';

class SecuritySection extends ConsumerWidget {
  final AppSettings settings;

  const SecuritySection({super.key, required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Security'),
        ShadCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsRow(
                leading: const IconBox(icon: LucideIcons.lock),
                title: 'PIN Lock',
                subtitle: 'Require PIN to open the app',
                trailing: ShadSwitch(
                  value: settings.pinEnabled,
                  onChanged: (v) => _handlePinToggle(context, ref, v),
                ),
              ),
              if (settings.pinEnabled) const ThinDivider(),
              if (settings.pinEnabled)
                SettingsRow(
                  leading: const IconBox(icon: LucideIcons.fingerprint),
                  title: 'Biometric',
                  subtitle: 'Use fingerprint or face unlock',
                  trailing: ShadSwitch(
                    value: settings.biometricEnabled,
                    onChanged: (v) => _handleBiometricToggle(context, ref, v),
                  ),
                ),
              if (settings.pinEnabled) const ThinDivider(),
              if (settings.pinEnabled)
                SettingsRow(
                  leading: const IconBox(icon: LucideIcons.timer),
                  title: 'Auto-lock timeout',
                  trailing: SettingsSelector(
                    title: 'Auto-lock timeout',
                    value: settings.autoLockTimeout.name,
                    options: const [
                      ('Immediate', 'immediate'),
                      ('30 seconds', 'seconds30'),
                      ('1 minute', 'minute1'),
                      ('5 minutes', 'minutes5'),
                    ],
                    onChanged: (v) {
                      final notifier = ref.read(settingsProvider.notifier);
                      if (v == 'immediate') {
                        notifier.setAutoLockTimeout(AutoLockTimeout.immediate);
                      }
                      if (v == 'seconds30') {
                        notifier.setAutoLockTimeout(AutoLockTimeout.seconds30);
                      }
                      if (v == 'minute1') {
                        notifier.setAutoLockTimeout(AutoLockTimeout.minute1);
                      }
                      if (v == 'minutes5') {
                        notifier.setAutoLockTimeout(AutoLockTimeout.minutes5);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handlePinToggle(
      BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled) {
      final created = await showPinSetupDialog(context, PinSetupMode.create);
      if (created && context.mounted) {
        ref.read(settingsProvider.notifier).setPinEnabled(true);
      }
    } else {
      final removed = await showPinSetupDialog(context, PinSetupMode.remove);
      if (removed && context.mounted) {
        ref.read(settingsProvider.notifier).setPinEnabled(false);
      }
    }
  }

  Future<void> _handleBiometricToggle(
      BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled) {
      final auth = LocalAuthentication();
      final available = await auth.canCheckBiometrics;
      if (!available) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Biometric authentication is not available on this device'),
            ),
          );
        }
        return;
      }
      try {
        final authenticated = await auth.authenticate(
          localizedReason: 'Authenticate to enable biometric unlock',
        );
        if (authenticated && context.mounted) {
          ref.read(settingsProvider.notifier).toggleBiometric(true);
        }
      } on LocalAuthException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_biometricFriendlyError(e)),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      ref.read(settingsProvider.notifier).toggleBiometric(false);
    }
  }

  String _biometricFriendlyError(LocalAuthException e) {
    final code = e.code;
    if (code == LocalAuthExceptionCode.noBiometricsEnrolled) {
      return 'No fingerprint registered. Go to Settings > Security to add one.';
    }
    if (code == LocalAuthExceptionCode.biometricLockout) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Biometric authentication failed.';
  }
}
