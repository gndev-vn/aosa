import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/aosa_widgets.dart';
import '../../widgets/standard_bottom_sheet.dart';

class CloudConfigSheet extends ConsumerStatefulWidget {
  const CloudConfigSheet({super.key});

  @override
  ConsumerState<CloudConfigSheet> createState() => _CloudConfigSheetState();
}

class _CloudConfigSheetState extends ConsumerState<CloudConfigSheet> {
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

    return StandardBottomSheet(
      title: 'Server',
      isScrollControlled: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
      final error =
          await ref.read(authProvider.notifier).connectWithToken(serverUrl, token);
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
      final error = await ref
          .read(authProvider.notifier)
          .login(serverUrl, username, password);
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
