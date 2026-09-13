import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../data/encryption/crypto_service.dart';
import '../providers/app_lock_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/pin_widgets.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});
  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with TickerProviderStateMixin {
  String _enteredPin = '';
  bool _biometricAvailable = false;
  bool _biometricAttempted = false;
  bool _isAuthenticating = false;
  bool _unlockSuccess = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _bounceController;
  late final AnimationController _successController;
  late final Animation<double> _successScaleAnimation;
  late final Animation<double> _successFadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _bounceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _successScaleAnimation = CurvedAnimation(parent: _successController, curve: Curves.elasticOut);
    _successFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _successController, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)));
    _initBiometric();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _initBiometric() async {
    try {
      final available = await LocalAuthentication().canCheckBiometrics;
      if (!mounted) return;
      final settings = ref.read(settingsProvider);
      final useBiometric = available && settings.biometricEnabled;
      setState(() { _biometricAvailable = available; _isAuthenticating = useBiometric; if (!useBiometric) _biometricAttempted = true; });
      if (useBiometric) await _authenticateBiometric();
    } on LocalAuthException {
      if (mounted) setState(() => _biometricAttempted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final settings = ref.watch(settingsProvider);
    final existingTheme = ShadTheme.maybeOf(context);
    final isDark = existingTheme?.brightness == Brightness.dark ||
        Theme.of(context).brightness == Brightness.dark;
    final seed = Theme.of(context).colorScheme.primary;
    final shadTheme = existingTheme ??
        (isDark
            ? AppTheme.shadThemeDark(seedColor: seed)
            : AppTheme.shadThemeLight(seedColor: seed));

    if (_unlockSuccess) return _buildSuccessOverlay(shadTheme);

    final isCooldown = lockState.cooldownUntil != null && DateTime.now().isBefore(lockState.cooldownUntil!);
    final biometricPrimary = settings.biometricEnabled && _biometricAvailable && !isCooldown;
    final showPin = !biometricPrimary || _biometricAttempted;

    final scaffold = Scaffold(
      backgroundColor: shadTheme.colorScheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _buildLogo(shadTheme),
              const SizedBox(height: 20),
              if (showPin) ...[
                Text('Enter PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: shadTheme.colorScheme.foreground)),
                const SizedBox(height: 6),
                Text('Unlock app', style: TextStyle(fontSize: 14, color: shadTheme.colorScheme.mutedForeground)),
              ],
              if (biometricPrimary && !showPin)
                Text(_isAuthenticating ? 'Authenticating…' : 'Unlock app', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: shadTheme.colorScheme.foreground)),
              if (biometricPrimary && _biometricAttempted && !_isAuthenticating)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Biometric failed. Use your PIN.', style: TextStyle(fontSize: 12, color: shadTheme.colorScheme.mutedForeground)),
                ),
              if (isCooldown) const Padding(padding: EdgeInsets.only(top: 12), child: ErrorBanner(message: 'Too many attempts. Try again later.')),
              if (biometricPrimary && !_biometricAttempted && !_isAuthenticating)
                Padding(padding: const EdgeInsets.only(top: 12), child: Text('Checking biometric…', style: TextStyle(fontSize: 12, color: shadTheme.colorScheme.mutedForeground))),
              const SizedBox(height: 36),
              if (showPin) ...[
                PinDots(filledCount: _enteredPin.length, animate: true, spacing: 7),
                const SizedBox(height: 36),
                Numpad(onKeyPressed: _onKeyPress, disabled: isCooldown),
              ],
              if (biometricPrimary && !showPin) const SizedBox(height: 36),
              if (biometricPrimary)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: ShadButton.outline(
                    onPressed: _authenticateBiometric,
                    leading: const Icon(LucideIcons.fingerprint, size: 18),
                    width: 220,
                    height: 48,
                    child: Text(_biometricAttempted ? 'Retry Biometric' : 'Use Biometric'),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );

    if (existingTheme == null) {
      return ShadTheme(
        data: shadTheme,
        child: scaffold,
      );
    }
    return scaffold;
  }

  Widget _buildSuccessOverlay(ShadThemeData shadTheme) => Scaffold(
    backgroundColor: shadTheme.colorScheme.background,
    body: Center(
      child: FadeTransition(
        opacity: _successFadeAnimation,
        child: ScaleTransition(
          scale: _successScaleAnimation,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ShadAvatar(
              null,
              size: const Size.square(96),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: shadTheme.colorScheme.primary,
              placeholder: Icon(
                LucideIcons.check,
                size: 52,
                color: shadTheme.colorScheme.primaryForeground,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome back!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: shadTheme.colorScheme.foreground,
              ),
            ),
          ]),
        ),
      ),
    ),
  );

  Widget _buildLogo(ShadThemeData shadTheme) => AnimatedBuilder(
    animation: _pulseAnimation,
    builder: (context, child) => Transform.scale(scale: _isAuthenticating ? _pulseAnimation.value : 1.0, child: child),
    child: ShadAvatar(
      null,
      size: const Size.square(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      backgroundColor: shadTheme.colorScheme.primary,
      placeholder: Icon(
        _isAuthenticating ? LucideIcons.fingerprint : LucideIcons.lock,
        size: 40,
        color: shadTheme.colorScheme.primaryForeground,
      ),
    ),
  );

  void _onKeyPress(String key) {
    if (key == '\u232B') {
      if (_enteredPin.isNotEmpty) setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
    } else if (_enteredPin.length < 6) {
      setState(() { _enteredPin += key; _bounceController.forward(from: 0); });
      if (_enteredPin.length == 6) _verifyPin();
    }
  }

  Future<void> _verifyPin() async {
    final verified = await CryptoService.verifyStoredPin(_enteredPin);
    if (verified == null || verified) { _onUnlockSuccess(); return; }
    await HapticFeedback.mediumImpact();
    ref.read(appLockProvider.notifier).recordFailedAttempt();
    setState(() => _enteredPin = '');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [
      Icon(LucideIcons.circleAlert, size: 18, color: Theme.of(context).colorScheme.error),
      const SizedBox(width: 8),
      const Text('Incorrect PIN'),
    ])));
  }

  void _onUnlockSuccess() {
    HapticFeedback.heavyImpact();
    _pulseController.stop();
    setState(() => _unlockSuccess = true);
    _successController.forward();
    Future.delayed(const Duration(milliseconds: 900), () { if (mounted) ref.read(appLockProvider.notifier).unlock(); });
  }

  Future<void> _authenticateBiometric() async {
    setState(() => _isAuthenticating = true);
    try {
      final authenticated = await LocalAuthentication().authenticate(localizedReason: 'Unlock AOSA', biometricOnly: true);
      if (!mounted) return;
      if (authenticated) { _onUnlockSuccess(); }
      else setState(() { _isAuthenticating = false; _biometricAttempted = true; });
    } on LocalAuthException catch (e) {
      if (mounted) {
        setState(() { _isAuthenticating = false; _biometricAttempted = true; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_biometricErrorMessage(e))));
      }
    }
  }

  String _biometricErrorMessage(LocalAuthException e) {
    final code = e.code;
    if (code == LocalAuthExceptionCode.noBiometricsEnrolled) return 'No fingerprint registered. Go to Settings > Security to add one.';
    if (code == LocalAuthExceptionCode.temporaryLockout || code == LocalAuthExceptionCode.biometricLockout) return 'Biometric is locked. Use your PIN instead.';
    if (code == LocalAuthExceptionCode.noBiometricHardware) return 'Biometric is not available on this device.';
    if (code == LocalAuthExceptionCode.noCredentialsSet) return 'Set a device PIN, pattern, or password in your device settings first.';
    return e.description ?? 'Biometric authentication failed.';
  }
}
