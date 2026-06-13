import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/encryption/crypto_service.dart';

enum PinSetupMode { create, change, remove }

class PinSetupDialog extends StatefulWidget {
  final PinSetupMode mode;

  const PinSetupDialog({super.key, required this.mode});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  int _step = 0;
  String _oldPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Dialog(
      insetPadding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Container(
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
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(theme, colorScheme),
                const Spacer(),
                _buildCenter(theme, colorScheme),
                const Spacer(),
                _buildBottom(theme, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const Spacer(),
          if (_step > 0 && !_isSuccessStep)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Step ${_step + 1} of $_totalSteps',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool get _isSuccessStep {
    return switch (widget.mode) {
      PinSetupMode.create => _step == 2,
      PinSetupMode.change => _step == 3,
      PinSetupMode.remove => _step == 1,
    };
  }

  int get _totalSteps {
    return switch (widget.mode) {
      PinSetupMode.create => 2,
      PinSetupMode.change => 3,
      PinSetupMode.remove => 1,
    };
  }

  Widget _buildCenter(ThemeData theme, ColorScheme colorScheme) {
    if (_isSuccessStep) {
      return _buildSuccess(theme, colorScheme);
    }

    final instruction = switch (widget.mode) {
      PinSetupMode.create => _step == 0 ? 'Enter a new PIN' : 'Confirm your PIN',
      PinSetupMode.change => _step == 0
          ? 'Enter your current PIN'
          : _step == 1
              ? 'Enter a new PIN'
              : 'Confirm your new PIN',
      PinSetupMode.remove => 'Enter your current PIN',
    };

    final entered = switch (widget.mode) {
      PinSetupMode.create => _step == 0 ? _newPin : _confirmPin,
      PinSetupMode.change => _step == 0 ? _oldPin : _step == 1 ? _newPin : _confirmPin,
      PinSetupMode.remove => _oldPin,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withAlpha(180),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 36,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            instruction,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _buildPinDots(theme, colorScheme, entered),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPinDots(ThemeData theme, ColorScheme colorScheme, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (i) {
        final filled = i < value.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? colorScheme.primary : Colors.transparent,
            border: Border.all(
              color: filled ? colorScheme.primary : colorScheme.outlineVariant,
              width: filled ? 0 : 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottom(ThemeData theme, ColorScheme colorScheme) {
    if (_isSuccessStep) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.primary,
              ),
              child: Center(
                child: Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final entered = switch (widget.mode) {
      PinSetupMode.create => _step == 0 ? _newPin : _confirmPin,
      PinSetupMode.change => _step == 0 ? _oldPin : _step == 1 ? _newPin : _confirmPin,
      PinSetupMode.remove => _oldPin,
    };

    final onChange = switch (widget.mode) {
      PinSetupMode.create => _step == 0 ? _onNewPin : _onConfirmPin,
      PinSetupMode.change => _step == 0 ? _onOldPin : _step == 1 ? _onNewPin : _onConfirmPin,
      PinSetupMode.remove => _onOldPin,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNumpad(theme, colorScheme, entered, onChange),
        const SizedBox(height: 16),
        _buildActionButton(theme, colorScheme, entered),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActionButton(ThemeData theme, ColorScheme colorScheme, String entered) {
    final button = switch (widget.mode) {
      PinSetupMode.remove when _step == 0 => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: entered.length >= 4 ? _confirm : null,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.error,
              ),
              child: Center(
                child: Text(
                  'Remove PIN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: entered.length >= 4 ? colorScheme.onError : colorScheme.onError.withAlpha(120),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      _ when _showNext => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: entered.length >= 4 ? _advance : null,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.primary,
              ),
              child: Center(
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: entered.length >= 4 ? colorScheme.onPrimary : colorScheme.onPrimary.withAlpha(120),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      _ when _showConfirm => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _canConfirm ? _confirm : null,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.primary,
              ),
              child: Center(
                child: Text(
                  _confirmLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _canConfirm ? colorScheme.onPrimary : colorScheme.onPrimary.withAlpha(120),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      _ => null,
    };

    if (button == null) return const SizedBox.shrink();

    return button;
  }

  bool get _showNext {
    return switch (widget.mode) {
      PinSetupMode.create => _step == 0,
      PinSetupMode.change => _step == 0 || _step == 1,
      PinSetupMode.remove => false,
    };
  }

  bool get _showConfirm {
    return switch (widget.mode) {
      PinSetupMode.create => _step == 1,
      PinSetupMode.change => _step == 2,
      PinSetupMode.remove => false,
    };
  }

  bool get _canConfirm {
    return switch (widget.mode) {
      PinSetupMode.create => _confirmPin.length >= 4 && _confirmPin == _newPin,
      PinSetupMode.change => _confirmPin.length >= 4 && _confirmPin == _newPin,
      _ => false,
    };
  }

  String get _confirmLabel {
    return switch (widget.mode) {
      PinSetupMode.create => 'Set PIN',
      PinSetupMode.change => 'Change PIN',
      PinSetupMode.remove => 'Remove PIN',
    };
  }

  Widget _buildNumpad(
    ThemeData theme,
    ColorScheme colorScheme,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
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
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        if (key == '⌫') {
                          if (currentValue.isNotEmpty) {
                            onChanged(currentValue.substring(0, currentValue.length - 1));
                          }
                        } else if (currentValue.length < 6) {
                          onChanged(currentValue + key);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            key,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: key == '⌫'
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

  Widget _buildSuccess(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            switch (widget.mode) {
              PinSetupMode.create => 'PIN Created',
              PinSetupMode.change => 'PIN Changed',
              PinSetupMode.remove => 'PIN Removed',
            },
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            switch (widget.mode) {
              PinSetupMode.create => 'Your new PIN has been set.',
              PinSetupMode.change => 'Your PIN has been updated.',
              PinSetupMode.remove => 'Your PIN has been removed.',
            },
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _onOldPin(String value) => setState(() => _oldPin = value);
  void _onNewPin(String value) {
    setState(() {
      _newPin = value;
      _error = null;
    });
  }

  void _onConfirmPin(String value) {
    setState(() {
      _confirmPin = value;
      if (value.length >= 4 && value != _newPin) {
        _error = 'PINs do not match';
      } else {
        _error = null;
      }
    });
  }

  Future<String?> _readStorage(FlutterSecureStorage storage, String key) async {
    try {
      return await storage.read(key: key);
    } on PlatformException {
      return null;
    }
  }

  void _advance() {
    if (widget.mode == PinSetupMode.change && _step == 0) {
      _verifyOldPin();
    } else {
      setState(() {
        _step++;
        _error = null;
      });
    }
  }

  Future<void> _verifyOldPin() async {
    final storage = const FlutterSecureStorage();
    final storedToken = await _readStorage(storage, 'pin_token');
    final storedSalt = await _readStorage(storage, 'pin_salt');
    if (storedToken == null || storedSalt == null) return;

    final salt = base64Decode(storedSalt);
    final key = await CryptoService.deriveKey(_oldPin, salt);
    final verified = await CryptoService.verifyPin(key, storedToken);

    if (verified) {
      setState(() {
        _step = 1;
        _oldPin = '';
        _error = null;
      });
    } else {
      setState(() {
        _oldPin = '';
        _error = 'Incorrect PIN';
      });
    }
  }

  Future<void> _confirm() async {
    if (widget.mode == PinSetupMode.remove) {
      final storage = const FlutterSecureStorage();
      final storedToken = await _readStorage(storage, 'pin_token');
      final storedSalt = await _readStorage(storage, 'pin_salt');
      if (storedToken == null || storedSalt == null) return;

      final salt = base64Decode(storedSalt);
      final key = await CryptoService.deriveKey(_oldPin, salt);
      final verified = await CryptoService.verifyPin(key, storedToken);
      if (!verified) {
        setState(() => _error = 'Incorrect PIN');
        return;
      }

      await storage.delete(key: 'pin_token');
      await storage.delete(key: 'pin_salt');
      setState(() => _step = 1);
      return;
    }

    final pin = _newPin;
    final salt = CryptoService.generateSalt();
    final key = await CryptoService.deriveKey(pin, salt);
    final token = await CryptoService.verifyToken(key);
    final storage = const FlutterSecureStorage();
    await storage.write(key: 'pin_salt', value: base64Encode(salt));
    await storage.write(key: 'pin_token', value: token);

    setState(() {
      _step = widget.mode == PinSetupMode.change ? 3 : 2;
    });
  }
}

Future<bool> showPinSetupDialog(BuildContext context, PinSetupMode mode) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PinSetupDialog(mode: mode),
  );
  return result ?? false;
}
