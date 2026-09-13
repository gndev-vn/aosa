import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../data/encryption/crypto_service.dart';
import 'pin_widgets.dart';
import 'standard_bottom_sheet.dart';

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
  bool _saving = false;
  bool _oldPinVerified = false;

  bool get _isSuccessStep => switch (widget.mode) {
    PinSetupMode.create => _step == 2,
    PinSetupMode.change => _step == 3,
    PinSetupMode.remove => _step == 1,
  };

  bool get _canGoBack => switch (widget.mode) {
    PinSetupMode.create => _step == 1,
    PinSetupMode.change => _step == 1 || _step == 2,
    PinSetupMode.remove => false,
  };

  String get _entered => switch (widget.mode) {
    PinSetupMode.create => _step == 0 ? _newPin : _confirmPin,
    PinSetupMode.change => _step == 0 ? _oldPin : _step == 1 ? _newPin : _confirmPin,
    PinSetupMode.remove => _oldPin,
  };

  bool get _showSave => switch (widget.mode) {
    PinSetupMode.create => _step == 1 && _confirmPin.length == 6 && _confirmPin == _newPin,
    PinSetupMode.change => _step == 2 && _confirmPin.length == 6 && _confirmPin == _newPin,
    PinSetupMode.remove => _step == 0 && _oldPinVerified,
  };

  String get _confirmHeaderLabel => switch (widget.mode) {
    PinSetupMode.create => 'Save',
    PinSetupMode.change => 'Save',
    PinSetupMode.remove => 'Remove',
  };

  String get _instruction => switch (widget.mode) {
    PinSetupMode.create => _step == 0 ? 'Enter PIN' : 'Confirm PIN',
    PinSetupMode.change => _step == 0 ? 'Enter PIN' : _step == 1 ? 'Enter new PIN' : 'Confirm new PIN',
    PinSetupMode.remove => 'Enter PIN',
  };

  ValueChanged<String> get _onChange => switch (widget.mode) {
    PinSetupMode.create => _step == 0 ? _onNewPin : _onConfirmPin,
    PinSetupMode.change => _step == 0 ? _onOldPin : _step == 1 ? _onNewPin : _onConfirmPin,
    PinSetupMode.remove => _onOldPin,
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StandardBottomSheet(
      title: _isSuccessStep
          ? switch (widget.mode) { PinSetupMode.create => 'PIN created', PinSetupMode.change => 'PIN changed', PinSetupMode.remove => 'PIN removed' }
          : _instruction,
      onBack: _canGoBack ? _goBack : null,
      confirmLabel: _isSuccessStep ? 'Done' : _showSave ? _confirmHeaderLabel : null,
      onConfirm: _isSuccessStep
          ? () => Navigator.of(context).pop(true)
          : _showSave
              ? _confirm
              : null,
      useSafeArea: true,
      child: _isSuccessStep ? _buildSuccess() : _buildPinEntry(cs),
    );
  }

  Widget _buildPinEntry(ColorScheme cs) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      PinDots(filledCount: _entered.length),
      if (_error != null) ...[
        const SizedBox(height: 10),
        ErrorBanner(message: _error!),
      ],
      const SizedBox(height: 16),
      Numpad(
        keySize: 48,
        onKeyPressed: (key) {
          final v = _entered;
          final newValue = key == '\u232B'
              ? (v.isNotEmpty ? v.substring(0, v.length - 1) : '')
              : v.length < 6 ? v + key : v;
          _onChange(newValue);
        },
      ),
    ]);
  }

  Widget _buildSuccess() {
    final shadTheme = ShadTheme.maybeOf(context);
    final primary = shadTheme?.colorScheme.primary ??
        Theme.of(context).colorScheme.primary;
    final primaryFg = shadTheme?.colorScheme.primaryForeground ?? Colors.white;
    final mutedFg = shadTheme?.colorScheme.mutedForeground ??
        Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      ShadAvatar(
        null,
        size: const Size.square(64),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: primary,
        placeholder: Icon(LucideIcons.check, size: 32, color: primaryFg),
      ),
      const SizedBox(height: 16),
      Text(
        switch (widget.mode) { PinSetupMode.create => 'Your new PIN has been set.', PinSetupMode.change => 'Your PIN has been updated.', PinSetupMode.remove => 'Your PIN has been removed.' },
        style: TextStyle(fontSize: 14, color: mutedFg),
      ),
    ]);
  }

  void _onOldPin(String value) {
    setState(() { _oldPin = value; _error = null; _oldPinVerified = false; });
    if (value.length == 6) _verifyOldPin();
  }

  void _onNewPin(String value) {
    setState(() { _newPin = value; _error = null; });
    if (value.length == 6) _advance();
  }

  void _onConfirmPin(String value) {
    setState(() {
      _confirmPin = value;
      if (value.length == 6 && value != _newPin) {
        _error = 'PINs do not match';
      } else {
        _error = null;
      }
    });
  }

  void _goBack() {
    setState(() {
      _error = null;
      switch (widget.mode) {
        case PinSetupMode.create:
          _step = 0;
          _newPin = '';
          _confirmPin = '';
          break;
        case PinSetupMode.change:
          if (_step == 2) {
            _step = 1;
            _confirmPin = '';
          } else if (_step == 1) {
            _step = 0;
            _newPin = '';
          }
          break;
        case PinSetupMode.remove:
          break;
      }
    });
  }

  void _advance() {
    setState(() { _step++; _error = null; });
  }

  Future<void> _verifyOldPin() async {
    final verified = await CryptoService.verifyStoredPin(_oldPin);
    if (verified == null || !mounted) return;
    setState(() {
      if (verified) {
        if (widget.mode == PinSetupMode.change) {
          _step = 1;
          _oldPin = '';
        } else {
          _oldPinVerified = true;
        }
      } else {
        _oldPin = '';
        _error = 'Incorrect PIN';
      }
    });
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (widget.mode == PinSetupMode.remove) {
        const storage = FlutterSecureStorage();
        await storage.delete(key: 'pin_token');
        await storage.delete(key: 'pin_salt');
        setState(() => _step = 1);
        return;
      }
      final salt = CryptoService.generateSalt();
      final key = await CryptoService.deriveKey(_newPin, salt);
      final token = await CryptoService.verifyToken(key);
      const storage = FlutterSecureStorage();
      await storage.write(key: 'pin_salt', value: base64Encode(salt));
      await storage.write(key: 'pin_token', value: token);
      setState(() => _step = widget.mode == PinSetupMode.change ? 3 : 2);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

Future<bool> showPinSetupDialog(BuildContext context, PinSetupMode mode) async {
  final result = await showSlideBottomSheet<bool>(
    context,
    builder: (_) => PinSetupDialog(mode: mode),
  );
  return result ?? false;
}
