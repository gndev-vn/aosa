import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_init_provider.dart';
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
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _generalError;
  String? _urlError;
  String? _usernameError;
  String? _passwordError;
  String? _tokenError;

  @override
  void initState() {
    super.initState();
    final serverUrl = ref.read(settingsProvider).serverUrl;
    _serverController.text = serverUrl;
    // Pre-fill username and password from stored credentials
    final auth = ref.read(authProvider.notifier);
    auth.getUsername().then((username) {
      if (username != null && username.isNotEmpty && mounted) {
        _usernameController.text = username;
      }
    });
    auth.getPassword().then((password) {
      if (password != null && password.isNotEmpty && mounted) {
        _passwordController.text = password;
      }
    });
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
      confirmLabel: isConnected ? 'Reconnect' : 'Connect',
      onConfirm: _isLoading ? null : _onConnect,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_generalError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 18, color: cs.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _generalError!,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _serverController,
            decoration: InputDecoration(
              labelText: 'Server URL',
              hintText: 'https://aosa.example.com',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.dns_outlined),
              errorText: _urlError,
            ),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.url,
            enabled: !_isLoading,
            onChanged: (_) => setState(() => _urlError = null),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Use token', style: TextStyle(color: cs.onSurface)),
              const Spacer(),
              IgnorePointer(
                ignoring: _isLoading,
                child: AosaSwitch(
                  value: _useToken,
                  onChanged: (v) => setState(() => _useToken = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_useToken)
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Token',
                hintText: 'Paste your token here',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                errorText: _tokenError,
              ),
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              onChanged: (_) => setState(() => _tokenError = null),
            )
          else ...[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
                errorText: _usernameError,
              ),
              textInputAction: TextInputAction.next,
              enabled: !_isLoading,
              onChanged: (_) => setState(() => _usernameError = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: _passwordError,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              onChanged: (_) => setState(() => _passwordError = null),
            ),
          ],
          if (isConnected) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _onDisconnect,
                child: Text('Disconnect', style: TextStyle(color: cs.error)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Uri? _validateUrl(String url) {
    if (url.isEmpty) {
      setState(() => _urlError = 'Enter server URL');
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      setState(() => _urlError = 'Use a valid URL (https://...)');
      return null;
    }
    setState(() => _urlError = null);
    return uri;
  }

  Future<void> _onConnect() async {
    setState(() {
      _generalError = null;
      _urlError = null;
      _usernameError = null;
      _passwordError = null;
      _tokenError = null;
    });

    final serverUrl = _serverController.text.trim();
    final uri = _validateUrl(serverUrl);
    if (uri == null) return;

    if (_useToken) {
      final token = _tokenController.text.trim();
      if (token.isEmpty) {
        setState(() => _tokenError = 'Enter token');
        return;
      }
    } else {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      if (username.isEmpty) {
        setState(() => _usernameError = 'Enter username');
        return;
      }
      if (password.isEmpty) {
        setState(() => _passwordError = 'Enter password');
        return;
      }
    }

    setState(() => _isLoading = true);

    final services = ref.read(appInitProvider);
    if (services == null) {
      setState(() {
        _isLoading = false;
        _generalError = 'App not initialized';
      });
      return;
    }

    final api = services.apiClient;
    api.updateBaseUrl(serverUrl);

    try {
      await api.dio.get<Map<String, dynamic>>('health');
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _generalError = _humanizeError(e, 'Cannot reach server');
      });
      return;
    }

    if (_useToken) {
      final token = _tokenController.text.trim();
      final error =
          await ref.read(authProvider.notifier).connectWithToken(api, serverUrl, token);
      if (error != null) {
        setState(() {
          _isLoading = false;
          _generalError = error;
        });
        return;
      }
    } else {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final error =
          await ref.read(authProvider.notifier).login(api, username, password);
      if (error != null) {
        setState(() {
          _isLoading = false;
          _generalError = error;
        });
        return;
      }
    }

    ref.read(settingsProvider.notifier).setServerUrl(serverUrl);
    ref.read(settingsProvider.notifier).toggleSync(true);
    ref.read(appInitProvider.notifier).configureSync(serverUrl);
    setState(() => _isLoading = false);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _onDisconnect() async {
    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).logout();
    if (mounted) Navigator.of(context).pop(false);
  }

  static String _humanizeError(DioException e, String fallback) {
    final status = e.response?.statusCode;
    if (status == 401) return 'Invalid credentials';
    if (status == 404) return 'Server not found';
    if (status == 429) return 'Too many requests. Try again later';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot reach server';
    }
    return fallback;
  }
}
