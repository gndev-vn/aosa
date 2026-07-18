import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../data/encryption/crypto_service.dart';
import '../providers/app_lock_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_decoration.dart';
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_unlockSuccess) return _buildSuccessOverlay(theme, cs);

    final isCooldown = lockState.cooldownUntil != null && DateTime.now().isBefore(lockState.cooldownUntil!);
    final biometricPrimary = settings.biometricEnabled && _biometricAvailable && !isCooldown;
    final showPin = !biometricPrimary || _biometricAttempted;

    return Scaffold(
      body: Container(
        decoration: appBackground(cs),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _buildLogo(cs),
                const SizedBox(height: 20),
                if (showPin) ...[
                  Text('Enter PIN', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Unlock app', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
                if (biometricPrimary && !showPin)
                  Text(_isAuthenticating ? 'Authenticating…' : 'Unlock app', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                if (biometricPrimary && _biometricAttempted && !_isAuthenticating)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Biometric failed. Use your PIN.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                if (isCooldown) const Padding(padding: EdgeInsets.only(top: 12), child: ErrorBanner(message: 'Too many attempts. Try again later.')),
                if (biometricPrimary && !_biometricAttempted && !_isAuthenticating)
                  Padding(padding: const EdgeInsets.only(top: 12), child: Text('Checking biometric…', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
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
                    child: FilledButton.icon(
                      onPressed: _authenticateBiometric,
                      icon: const Icon(Icons.fingerprint, size: 20),
                      label: Text(_biometricAttempted ? 'Retry Biometric' : 'Use Biometric'),
                      style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(ThemeData theme, ColorScheme cs) => Scaffold(
    body: Container(
      decoration: appBackground(cs),
      child: Center(
        child: FadeTransition(
          opacity: _successFadeAnimation,
          child: ScaleTransition(
            scale: _successScaleAnimation,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GradientIcon(icon: Icons.check_rounded, size: 96, iconSize: 52, borderRadius: 28, boxShadow: [
                BoxShadow(color: cs.primary.withAlpha(80), blurRadius: 30, offset: const Offset(0, 12)),
              ]),
              const SizedBox(height: 24),
              Text('Welcome back!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),
    ),
  );

  Widget _buildLogo(ColorScheme cs) => AnimatedBuilder(
    animation: _pulseAnimation,
    builder: (context, child) => Transform.scale(scale: _isAuthenticating ? _pulseAnimation.value : 1.0, child: child),
    child: GradientIcon(
      icon: _isAuthenticating ? Icons.fingerprint : Icons.lock_outline_rounded,
      size: 80, iconSize: 40, borderRadius: 22,
      boxShadow: [BoxShadow(color: cs.primary.withAlpha(60), blurRadius: 20, offset: const Offset(0, 8))],
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Row(children: [
      Icon(Icons.error_outline, size: 18, color: Colors.redAccent),
      SizedBox(width: 8),
      Text('Incorrect PIN'),
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
