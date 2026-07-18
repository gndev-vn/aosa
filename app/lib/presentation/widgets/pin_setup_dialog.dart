import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  bool get _isSuccessStep => switch (widget.mode) {
    PinSetupMode.create => _step == 2,
    PinSetupMode.change => _step == 3,
    PinSetupMode.remove => _step == 1,
  };

  int get _totalSteps => switch (widget.mode) {
    PinSetupMode.create => 2,
    PinSetupMode.change => 3,
    PinSetupMode.remove => 1,
  };

  String get _entered => switch (widget.mode) {
    PinSetupMode.create => _step == 0 ? _newPin : _confirmPin,
    PinSetupMode.change => _step == 0 ? _oldPin : _step == 1 ? _newPin : _confirmPin,
    PinSetupMode.remove => _oldPin,
  };

  bool get _showNext => switch (widget.mode) {
    PinSetupMode.create => _step == 0,
    PinSetupMode.change => _step == 0 || _step == 1,
    PinSetupMode.remove => false,
  };

  bool get _showConfirm => switch (widget.mode) {
    PinSetupMode.create => _step == 1,
    PinSetupMode.change => _step == 2,
    PinSetupMode.remove => false,
  };

  bool get _canConfirm => _confirmPin.length >= 4 && _confirmPin == _newPin;

  String get _confirmLabel => switch (widget.mode) {
    PinSetupMode.create => 'Set PIN',
    PinSetupMode.change => 'Change PIN',
    PinSetupMode.remove => 'Remove PIN',
  };

  String get _instruction => switch (widget.mode) {
    PinSetupMode.create => _step == 0 ? 'Enter a new PIN' : 'Confirm your PIN',
    PinSetupMode.change => _step == 0 ? 'Enter your current PIN' : _step == 1 ? 'Enter a new PIN' : 'Confirm your new PIN',
    PinSetupMode.remove => 'Enter your current PIN',
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
          ? switch (widget.mode) { PinSetupMode.create => 'PIN Created', PinSetupMode.change => 'PIN Changed', PinSetupMode.remove => 'PIN Removed' }
          : _instruction,
      leadingAction: GestureDetector(
        onTap: () => Navigator.of(context).pop(false),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.primary)),
        ),
      ),
      trailingAction: _step > 0 && !_isSuccessStep
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
              child: Text('Step ${_step + 1} of $_totalSteps',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
            )
          : null,
      useSafeArea: true,
      child: _isSuccessStep ? _buildSuccess() : _buildPinEntry(),
    );
  }

  Widget _buildPinEntry() {
    final cs = Theme.of(context).colorScheme;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Center(
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cs.primary, cs.primary.withAlpha(180)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.lock_outline_rounded, size: 28, color: cs.onPrimary),
        ),
      ),
      const SizedBox(height: 16),
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
          _onChange(key == '\u232B'
              ? (v.isNotEmpty ? v.substring(0, v.length - 1) : '')
              : v.length < 6 ? v + key : v);
        },
      ),
      const SizedBox(height: 8),
      _buildActionButton(cs),
    ]);
  }

  Widget _buildActionButton(ColorScheme cs) {
    if (widget.mode == PinSetupMode.remove && _step == 0) {
      return _pinButton(label: 'Remove PIN', color: cs.error, fg: cs.onError, enabled: _entered.length >= 4, onTap: _confirm);
    }
    if (_showNext) {
      return _pinButton(label: 'Next', color: cs.primary, fg: cs.onPrimary, enabled: _entered.length >= 4, onTap: _advance);
    }
    if (_showConfirm) {
      return _pinButton(label: _confirmLabel, color: cs.primary, fg: cs.onPrimary, enabled: _canConfirm, onTap: _confirm);
    }
    return const SizedBox.shrink();
  }

  Widget _pinButton({required String label, required Color color, required Color fg, required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: color),
        child: Center(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: enabled ? fg : fg.withAlpha(120)))),
      ),
    );
  }

  Widget _buildSuccess() {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.check_circle_outline_rounded, size: 40, color: cs.primary),
      ),
      const SizedBox(height: 16),
      Text(
        switch (widget.mode) { PinSetupMode.create => 'Your new PIN has been set.', PinSetupMode.change => 'Your PIN has been updated.', PinSetupMode.remove => 'Your PIN has been removed.' },
        style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
      const SizedBox(height: 20),
      _pinButton(label: 'Done', color: cs.primary, fg: cs.onPrimary, enabled: true, onTap: () => Navigator.of(context).pop(true)),
    ]);
  }

  void _onOldPin(String value) => setState(() => _oldPin = value);
  void _onNewPin(String value) => setState(() { _newPin = value; _error = null; });
  void _onConfirmPin(String value) => setState(() {
    _confirmPin = value;
    _error = (value.length >= 4 && value != _newPin) ? 'PINs do not match' : null;
  });

  void _advance() {
    if (widget.mode == PinSetupMode.change && _step == 0) {
      _verifyOldPin();
    } else {
      setState(() { _step++; _error = null; });
    }
  }

  Future<void> _verifyOldPin() async {
    final verified = await CryptoService.verifyStoredPin(_oldPin);
    if (verified == null) return;
    setState(() {
      if (verified) { _step = 1; _oldPin = ''; } else { _oldPin = ''; }
      _error = verified ? null : 'Incorrect PIN';
    });
  }

  Future<void> _confirm() async {
    if (widget.mode == PinSetupMode.remove) {
      final verified = await CryptoService.verifyStoredPin(_oldPin);
      if (verified != true) { setState(() => _error = 'Incorrect PIN'); return; }
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
  }
}

Future<bool> showPinSetupDialog(BuildContext context, PinSetupMode mode) async {
  final result = await showSlideBottomSheet<bool>(
    context,
    isDismissible: false,
    builder: (_) => PinSetupDialog(mode: mode),
  );
  return result ?? false;
}
