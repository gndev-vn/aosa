import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../data/encryption/crypto_service.dart';
import '../providers/app_lock_provider.dart';
import '../providers/settings_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with TickerProviderStateMixin {
  String _enteredPin = '';
  bool _biometricAvailable = false;
  bool _biometricAttempted = false;
  bool _isAuthenticating = false;
  bool _unlockSuccess = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;
  late final AnimationController _successController;
  late final Animation<double> _successScaleAnimation;
  late final Animation<double> _successFadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _successScaleAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _successFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

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
    final auth = LocalAuthentication();
    try {
      final available = await auth.canCheckBiometrics;
      if (!mounted) return;
      final settings = ref.read(settingsProvider);
      setState(() {
        _biometricAvailable = available;
        if (available && settings.biometricEnabled) {
          _isAuthenticating = true;
        } else {
          _biometricAttempted = true;
        }
      });
      if (available && settings.biometricEnabled) {
        await _authenticateBiometric();
      }
    } on LocalAuthException {
      if (mounted) setState(() => _biometricAttempted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_unlockSuccess) {
      return _buildSuccessOverlay(theme, colorScheme);
    }

    final isCooldown = lockState.cooldownUntil != null &&
        DateTime.now().isBefore(lockState.cooldownUntil!);
    final biometricPrimary = settings.biometricEnabled &&
        _biometricAvailable &&
        !isCooldown;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withAlpha(180),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(colorScheme),
                  const SizedBox(height: 20),
                  if (!biometricPrimary || _biometricAttempted)
                    Text(
                      'Enter PIN',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (!biometricPrimary || _biometricAttempted)
                    const SizedBox(height: 6),
                  if (!biometricPrimary || _biometricAttempted)
                    Text(
                      'Unlock app',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (biometricPrimary && !_biometricAttempted)
                    Text(
                      _isAuthenticating ? 'Authenticating…' : 'Unlock app',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (biometricPrimary && _biometricAttempted && !_isAuthenticating)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Biometric failed. Use your PIN.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (isCooldown)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Too many attempts. Try again later.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  if (biometricPrimary && !_biometricAttempted && !_isAuthenticating)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Checking biometric…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 36),
                  if (!biometricPrimary || _biometricAttempted) ...[
                    _buildPinDots(theme, colorScheme),
                    const SizedBox(height: 36),
                    _buildNumpad(theme, colorScheme, isCooldown),
                  ],
                  if (biometricPrimary && !_biometricAttempted)
                    const SizedBox(height: 36),
                  if (biometricPrimary)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: FilledButton.icon(
                        onPressed: _authenticateBiometric,
                        icon: const Icon(Icons.fingerprint, size: 20),
                        label: Text(
                          _biometricAttempted
                              ? 'Retry Biometric'
                              : 'Use Biometric',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(200, 48),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(ThemeData theme, ColorScheme colorScheme) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withAlpha(180),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _successFadeAnimation,
            child: ScaleTransition(
              scale: _successScaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withAlpha(180),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(80),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 52,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome back!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _isAuthenticating ? _pulseAnimation.value : 1.0,
        child: child,
      ),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withAlpha(180),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          _isAuthenticating ? Icons.fingerprint : Icons.lock_outline_rounded,
          size: 40,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }

  Widget _buildPinDots(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (i) {
        final filled = i < _enteredPin.length;
        return AnimatedScale(
          scale: filled && i == _enteredPin.length - 1 ? 1.3 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.elasticOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 7),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled
                  ? colorScheme.primary
                  : Colors.transparent,
              border: Border.all(
                color: filled
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: filled ? 0 : 2,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumpad(ThemeData theme, ColorScheme colorScheme, bool disabled) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 76);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Material(
                    color: disabled
                        ? Colors.transparent
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    elevation: disabled ? 0 : 1,
                    shadowColor: colorScheme.shadow.withAlpha(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: disabled
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              _onKeyPress(key);
                            },
                      child: Center(
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: disabled
                                ? colorScheme.onSurfaceVariant.withAlpha(80)
                                : key == '⌫'
                                    ? colorScheme.onSurfaceVariant
                                    : colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  void _onKeyPress(String key) {
    if (key == '⌫') {
      if (_enteredPin.isNotEmpty) {
        setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
      }
    } else if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += key;
        _bounceController.forward(from: 0);
      });
      if (_enteredPin.length == 6) {
        _verifyPin();
      }
    }
  }

  Future<void> _verifyPin() async {
    final storage = const FlutterSecureStorage();
    final storedToken = await _readStorage(storage, 'pin_token');
    final storedSalt = await _readStorage(storage, 'pin_salt');

    if (storedToken == null || storedSalt == null) {
      _onUnlockSuccess();
      return;
    }

    final salt = base64Decode(storedSalt);
    final key = await CryptoService.deriveKey(_enteredPin, salt);

    final verified = await CryptoService.verifyPin(key, storedToken);
    if (verified) {
      _onUnlockSuccess();
    } else {
      HapticFeedback.mediumImpact();
      ref.read(appLockProvider.notifier).recordFailedAttempt();
      setState(() => _enteredPin = '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, size: 18, color: Colors.redAccent),
              const SizedBox(width: 8),
              const Text('Incorrect PIN'),
            ],
          ),
        ),
      );
    }
  }

  void _onUnlockSuccess() {
    HapticFeedback.heavyImpact();
    _pulseController.stop();
    setState(() => _unlockSuccess = true);
    _successController.forward();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        ref.read(appLockProvider.notifier).unlock();
      }
    });
  }

  Future<void> _authenticateBiometric() async {
    final auth = LocalAuthentication();
    setState(() => _isAuthenticating = true);
    try {
      final authenticated = await auth.authenticate(
        localizedReason: 'Unlock AOSA',
        biometricOnly: true,
      );
      if (!mounted) return;
      if (authenticated) {
        _onUnlockSuccess();
      } else {
        setState(() {
          _isAuthenticating = false;
          _biometricAttempted = true;
        });
      }
    } on LocalAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _biometricAttempted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_biometricErrorMessage(e))),
        );
      }
    }
  }

  String _biometricErrorMessage(LocalAuthException e) {
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

  Future<String?> _readStorage(FlutterSecureStorage storage, String key) async {
    try {
      return await storage.read(key: key);
    } on PlatformException {
      return null;
    }
  }
}
