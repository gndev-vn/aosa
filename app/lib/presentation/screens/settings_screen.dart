import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../domain/entities/app_settings.dart';
import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/sync_provider.dart';
import '../providers/repo_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/api/repo_api.dart';
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
    final authFlow = ref.watch(authProvider);
    final reposAsync = ref.watch(repoProvider);

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
            _buildAppearanceSection(context, theme, colorScheme, settings, ref),
            const SizedBox(height: 24),
            _buildSecuritySection(context, theme, colorScheme, settings, ref),
            const SizedBox(height: 24),
            _buildCloudSyncSection(context, theme, colorScheme, settings, authFlow, reposAsync, ref),
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
      padding: const EdgeInsets.only(left: 8),
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
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
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
      child: Icon(icon,
          size: 18,
          color: color != null ? cs.onPrimary : cs.onPrimaryContainer),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
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
              _settingsRow(
                context,
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
                    if (v == 'light')
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(AppThemeMode.light);
                    if (v == 'dark')
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(AppThemeMode.dark);
                    if (v == 'system')
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(AppThemeMode.system);
                  },
                ),
              ),
              if (settings.themeMode != AppThemeMode.dark)
                _thinDivider(context),
              if (settings.themeMode != AppThemeMode.dark)
                _settingsRow(
                  context,
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
                      Icon(Icons.chevron_right,
                          size: 18, color: colorScheme.onSurfaceVariant),
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
              _settingsRow(
                context,
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
                _settingsRow(
                  context,
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
                _settingsRow(
                  context,
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
                      if (v == 'immediate')
                        ref
                            .read(settingsProvider.notifier)
                            .setAutoLockTimeout(AutoLockTimeout.immediate);
                      if (v == 'seconds30')
                        ref
                            .read(settingsProvider.notifier)
                            .setAutoLockTimeout(AutoLockTimeout.seconds30);
                      if (v == 'minute1')
                        ref
                            .read(settingsProvider.notifier)
                            .setAutoLockTimeout(AutoLockTimeout.minute1);
                      if (v == 'minutes5')
                        ref
                            .read(settingsProvider.notifier)
                            .setAutoLockTimeout(AutoLockTimeout.minutes5);
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCloudSyncSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    AppSettings settings,
    AuthFlow authFlow,
    AsyncValue<List<RepoInfo>> reposAsync,
    WidgetRef ref,
  ) {
    final syncState = ref.watch(syncProvider);
    final isConnected = authFlow == AuthFlow.authenticated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(colorScheme, 'Cloud sync'),
        AosaCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _settingsRow(
                context,
                leading: _iconBox(colorScheme, Icons.cloud_outlined),
                title: 'Cloud sync',
                subtitle: 'Store your data on your self-hosted server',
                trailing: AosaSwitch(
                  value: settings.syncEnabled,
                  onChanged: (v) async {
                    if (v) {
                      if (context.mounted) _showCloudConfigSheet(context, ref);
                    } else {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Turn off cloud sync?'),
                          content: const Text(
                            'All cloud data will be removed until you reconnect to the server. '
                            'Your existing local OTP accounts will remain.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Turn off'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        ref.read(settingsProvider.notifier).toggleSync(false);
                      }
                    }
                  },
                ),
              ),
              if (settings.syncEnabled) ...[
                _thinDivider(context),
                _settingsRow(
                  context,
                  leading: _iconBox(colorScheme, Icons.dns_outlined,
                      color: colorScheme.secondaryContainer),
                  title: 'Server',
                  subtitle: isConnected
                      ? 'Connected'
                      : (settings.serverUrl.isEmpty
                          ? 'Not configured'
                          : settings.serverUrl),
                  trailing: Icon(Icons.chevron_right,
                      size: 18, color: colorScheme.onSurfaceVariant),
                  onTap: () => _showCloudConfigSheet(context, ref),
                ),
                if (isConnected) ...[
                  _thinDivider(context, indent: 60),
                  _buildReposSection(context, colorScheme, reposAsync, ref),
                  _thinDivider(context),
                  _buildSyncActions(context, colorScheme, syncState, ref),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showCloudConfigSheet(BuildContext context, WidgetRef ref) async {
    final connected = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CloudConfigSheet(),
    );

    if (connected != true && context.mounted) {
      ref.read(settingsProvider.notifier).toggleSync(false);
    }
  }

  Widget _buildReposSection(
    BuildContext context,
    ColorScheme colorScheme,
    AsyncValue<List<RepoInfo>> reposAsync,
    WidgetRef ref,
  ) {
    return Column(
      children: [
        _settingsRow(
          context,
          leading: _iconBox(colorScheme, Icons.folder_outlined),
          title: 'Repos',
          subtitle: 'Manage your repositories',
          trailing: Icon(Icons.chevron_right,
              size: 18, color: colorScheme.onSurfaceVariant),
          onTap: () => _showRepoManager(context, ref),
        ),
      ],
    );
  }

  Widget _buildSyncActions(
    BuildContext context,
    ColorScheme colorScheme,
    SyncState syncState,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AosaButton(
                  onPressed: syncState == SyncState.syncing
                      ? null
                      : () => _triggerSync(context, ref),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        syncState == SyncState.syncing
                            ? Icons.hourglass_top
                            : Icons.sync_rounded,
                        size: 18,
                        color: colorScheme.onPrimary.withAlpha(160),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        syncState == SyncState.syncing
                            ? 'Syncing…'
                            : 'Sync now',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (syncState == SyncState.success)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Sync completed',
                  style: TextStyle(fontSize: 13, color: colorScheme.primary)),
            ),
          if (syncState == SyncState.error)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Sync failed',
                  style: TextStyle(fontSize: 13, color: colorScheme.error)),
            ),
        ],
      ),
    );
  }

  void _showRepoManager(BuildContext context, WidgetRef ref) {
    final reposAsync = ref.read(repoProvider);
    reposAsync.whenData((repos) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _RepoManagerSheet(repos: repos),
      );
    });
  }

  Future<void> _triggerSync(BuildContext context, WidgetRef ref) async {
    final error = await ref.read(syncProvider.notifier).runSync(ref);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
              _settingsRow(
                context,
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
              _settingsRow(
                context,
                leading: _iconBox(colorScheme, Icons.code_rounded,
                    color: colorScheme.surfaceContainerHighest),
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
              _settingsRow(
                context,
                leading: _iconBox(colorScheme, Icons.open_in_new_rounded,
                    color: colorScheme.surfaceContainerHighest),
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
                    'Biometric authentication is not available on this device')),
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

class _CloudConfigSheet extends ConsumerStatefulWidget {
  const _CloudConfigSheet();

  @override
  ConsumerState<_CloudConfigSheet> createState() => _CloudConfigSheetState();
}

class _CloudConfigSheetState extends ConsumerState<_CloudConfigSheet> {
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _useToken = false;

  @override
  void initState() {
    super.initState();
    final serverUrl = ref.read(settingsProvider).serverUrl;
    _serverController.text = serverUrl;
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isConnected = ref.watch(authProvider) == AuthFlow.authenticated;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Server', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface,
              )),
              const SizedBox(height: 16),
              TextField(
                controller: _serverController,
                decoration: const InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'https://aosa.example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Use token', style: TextStyle(color: cs.onSurface)),
                  const Spacer(),
                  AosaSwitch(
                    value: _useToken,
                    onChanged: (v) => setState(() => _useToken = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_useToken)
                TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Token',
                    hintText: 'Paste your token here',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                  textInputAction: TextInputAction.done,
                )
              else ...[
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AosaButton(
                  onPressed: _onConnect,
                  child: Text(isConnected ? 'Reconnect' : 'Connect'),
                ),
              ),
              if (isConnected) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _onDisconnect,
                    child: Text('Disconnect',
                        style: TextStyle(color: cs.error)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onConnect() async {
    final serverUrl = _serverController.text.trim();
    if (serverUrl.isEmpty) {
      _showError('Enter server URL');
      return;
    }

    ref.read(settingsProvider.notifier).setServerUrl(serverUrl);

    if (_useToken) {
      final token = _tokenController.text.trim();
      if (token.isEmpty) {
        _showError('Enter token');
        return;
      }
      final error = await ref.read(authProvider.notifier).connectWithToken(serverUrl, token);
      if (error != null) {
        _showError(error);
      } else if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      if (username.isEmpty || password.isEmpty) {
        _showError('Enter username and password');
        return;
      }
      final error = await ref.read(authProvider.notifier).login(serverUrl, username, password);
      if (error != null) {
        _showError(error);
      } else if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _onDisconnect() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) Navigator.of(context).pop(false);
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _RepoManagerSheet extends ConsumerStatefulWidget {
  final List<RepoInfo> repos;

  const _RepoManagerSheet({required this.repos});

  @override
  ConsumerState<_RepoManagerSheet> createState() => _RepoManagerSheetState();
}

class _RepoManagerSheetState extends ConsumerState<_RepoManagerSheet> {
  late List<RepoInfo> _repos;

  @override
  void initState() {
    super.initState();
    _repos = List.from(widget.repos);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Repos',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface)),
            const SizedBox(height: 8),
            ..._repos.map((repo) => ListTile(
                  dense: true,
                  leading: Icon(
                    repo.isDefault ? Icons.star : Icons.folder_outlined,
                    color: cs.primary,
                  ),
                  title: Text(repo.name),
                  subtitle: repo.isDefault ? Text('Default', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)) : null,
                  trailing: !repo.isDefault
                      ? IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: cs.error),
                          onPressed: () {
                            // TODO: wire up server URL + token
                          },
                        )
                      : null,
                )),
            const SizedBox(height: 8),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _showCreateDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Repo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Repo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Repo name',
            hintText: 'My Vault',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              // TODO: pass serverUrl + token
              Navigator.of(ctx).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            value == selected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 20,
                            color: value == selected
                                ? cs.primary
                                : cs.outlineVariant,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: value == selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
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
