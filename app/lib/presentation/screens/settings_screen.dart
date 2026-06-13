import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../domain/entities/app_settings.dart';
import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/accent_color_picker.dart';
import '../widgets/aosa_widgets.dart';
import '../widgets/pin_setup_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            AosaHeader(
              leading: aosaBackButton(context, onPressed: () => ref.read(navigationProvider.notifier).goToHome()),
              title: 'Settings',
            ),
            const SizedBox(height: 8),
            _buildAppearanceSection(context, theme, colorScheme, settings, ref),
            const SizedBox(height: 24),
            _buildSecuritySection(context, theme, colorScheme, settings, ref),
            const SizedBox(height: 24),
            _buildSyncSection(context, theme, colorScheme, settings, ref),
            const SizedBox(height: 24),
            _buildAboutSection(context, theme, colorScheme, settings),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme colorScheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(ColorScheme cs, IconData icon, {Color? color}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color ?? cs.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color != null ? cs.onPrimary : cs.onPrimaryContainer),
    );
  }

  Widget _settingsRow(
    BuildContext context, {
    required Widget leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }

  Widget _thinDivider(BuildContext context, {double indent = 60}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: indent, right: 16),
      color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8),
    );
  }

  Widget _selector({
    required String value,
    required List<(String label, String value)> options,
    required ValueChanged<String> onChanged,
    required BuildContext context,
  }) {
    final cs = Theme.of(context).colorScheme;
    final currentLabel = options.firstWhere((o) => o.$2 == value).$1;
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => _OptionPicker(
            title: '',
            options: options,
            selected: value,
            onSelected: (v) {
              Navigator.of(ctx).pop();
              onChanged(v);
            },
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppSettings settings,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colorScheme, 'Appearance'),
        AosaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _settingsRow(context,
                leading: _iconBox(colorScheme, Icons.palette_outlined),
                title: 'Theme',
                trailing: _selector(
                  context: context,
                  value: settings.themeMode.name,
                  options: const [
                    ('Light', 'light'),
                    ('Dark', 'dark'),
                    ('System', 'system'),
                  ],
                  onChanged: (v) {
                    if (v == 'light') ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.light);
                    if (v == 'dark') ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.dark);
                    if (v == 'system') ref.read(settingsProvider.notifier).setThemeMode(AppThemeMode.system);
                  },
                ),
              ),
              if (settings.themeMode != AppThemeMode.dark) _thinDivider(context),
              if (settings.themeMode != AppThemeMode.dark)
                _settingsRow(context,
                  leading: _iconBox(colorScheme, Icons.colorize_outlined),
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
                      Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  onTap: () => _pickAccentColor(context, ref),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppSettings settings,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colorScheme, 'Security'),
        AosaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _settingsRow(context,
                leading: _iconBox(colorScheme, Icons.lock_outline_rounded),
                title: 'PIN Lock',
                subtitle: 'Require PIN to open the app',
                trailing: AosaSwitch(
                  value: settings.pinEnabled,
                  onChanged: (v) => _handlePinToggle(context, ref, v),
                ),
              ),
              if (settings.pinEnabled) _thinDivider(context),
              if (settings.pinEnabled)
                _settingsRow(context,
                  leading: _iconBox(colorScheme, Icons.fingerprint),
                  title: 'Biometric',
                  subtitle: 'Use fingerprint or face unlock',
                  trailing: AosaSwitch(
                    value: settings.biometricEnabled,
                    onChanged: (v) => _handleBiometricToggle(context, ref, v),
                  ),
                ),
              if (settings.pinEnabled) _thinDivider(context),
              if (settings.pinEnabled)
                _settingsRow(context,
                  leading: _iconBox(colorScheme, Icons.timer_outlined),
                  title: 'Auto-lock timeout',
                  trailing: _selector(
                    context: context,
                    value: settings.autoLockTimeout.name,
                    options: const [
                      ('Immediate', 'immediate'),
                      ('30 seconds', 'seconds30'),
                      ('1 minute', 'minute1'),
                      ('5 minutes', 'minutes5'),
                    ],
                    onChanged: (v) {
                      if (v == 'immediate') ref.read(settingsProvider.notifier).setAutoLockTimeout(AutoLockTimeout.immediate);
                      if (v == 'seconds30') ref.read(settingsProvider.notifier).setAutoLockTimeout(AutoLockTimeout.seconds30);
                      if (v == 'minute1') ref.read(settingsProvider.notifier).setAutoLockTimeout(AutoLockTimeout.minute1);
                      if (v == 'minutes5') ref.read(settingsProvider.notifier).setAutoLockTimeout(AutoLockTimeout.minutes5);
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSyncSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppSettings settings,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colorScheme, 'Sync'),
        AosaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _settingsRow(context,
                leading: _iconBox(colorScheme, Icons.sync_rounded),
                title: 'Enable sync',
                subtitle: 'Sync across devices',
                trailing: AosaSwitch(
                  value: settings.syncEnabled,
                  onChanged: (v) => ref.read(settingsProvider.notifier).toggleSync(v),
                ),
              ),
              if (settings.syncEnabled) _thinDivider(context),
              if (settings.syncEnabled) ...[
                _settingsRow(context,
                  leading: _iconBox(colorScheme, Icons.dns_outlined, color: colorScheme.secondaryContainer),
                  title: 'Server URL',
                  trailing: SizedBox(
                    width: 140,
                    child: Text(
                      settings.serverUrl.isEmpty ? 'Not configured' : settings.serverUrl,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                _thinDivider(context, indent: 60),
                _settingsRow(context,
                  leading: _iconBox(colorScheme, Icons.phone_android, color: colorScheme.secondaryContainer),
                  title: 'Device name',
                  trailing: SizedBox(
                    width: 120,
                    child: Text(
                      settings.deviceName.isEmpty ? 'Not set' : settings.deviceName,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: AosaButton(
                    onPressed: null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sync_rounded, size: 18, color: colorScheme.onPrimary.withAlpha(160)),
                        const SizedBox(width: 8),
                        Text('Sync now'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppSettings settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colorScheme, 'About'),
        AosaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _settingsRow(context,
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
              _thinDivider(context, indent: 60),
              _settingsRow(context,
                leading: _iconBox(colorScheme, Icons.code_rounded, color: colorScheme.surfaceContainerHighest),
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
              _thinDivider(context, indent: 60),
              _settingsRow(context,
                leading: _iconBox(colorScheme, Icons.open_in_new_rounded, color: colorScheme.surfaceContainerHighest),
                title: 'Source code',
                trailing: Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handlePinToggle(BuildContext context, WidgetRef ref, bool enabled) async {
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

  Future<void> _handleBiometricToggle(BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled) {
      final auth = LocalAuthentication();
      final available = await auth.canCheckBiometrics;
      if (!available) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication is not available on this device')),
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
    if (code == LocalAuthExceptionCode.temporaryLockout ||
        code == LocalAuthExceptionCode.biometricLockout) {
      return 'Biometric is locked. Use your PIN instead.';
    }
    if (code == LocalAuthExceptionCode.noBiometricHardware) {
      return 'Biometric is not available on this device.';
    }
    if (code == LocalAuthExceptionCode.noCredentialsSet) {
      return 'Set a device PIN, pattern, or password in your device settings first.';
    }
    return e.description ?? 'Biometric authentication failed.';
  }

  void _pickAccentColor(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const AccentColorPicker(),
    );
  }
}

class _OptionPicker extends StatelessWidget {
  final String title;
  final List<(String label, String value)> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _OptionPicker({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cs.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (label, value) in options)
                  GestureDetector(
                    onTap: () => onSelected(value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            value == selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 20,
                            color: value == selected ? cs.primary : cs.outlineVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: value == selected ? FontWeight.w600 : FontWeight.w400,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
