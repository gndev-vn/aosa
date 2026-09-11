import 'dart:convert';

import 'package:aosa/domain/entities/otp_account.dart';
import 'package:uuid/uuid.dart';

class OtpAuthResult {
  final String issuer;
  final String accountLabel;
  final String secretBase32;
  final String algorithm;
  final int digits;
  final int period;
  final int? counter;

  const OtpAuthResult({
    required this.issuer,
    required this.accountLabel,
    required this.secretBase32,
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.period = 30,
    this.counter,
  });

  OtpAccount toAccount({required String id}) => OtpAccount(
        id: id,
        issuer: issuer,
        accountLabel: accountLabel,
        secretBase32: secretBase32,
        algorithm: algorithm,
        digits: digits,
        period: period,
      );
}

class OtpAuthParser {
  static OtpAuthResult? parse(String uri) {
    try {
      final parsed = Uri.parse(uri);
      if (parsed.scheme != 'otpauth') return null;

      final type = parsed.host.toLowerCase();
      if (type != 'totp' && type != 'hotp') return null;

      final label = parsed.pathSegments.join('/');
      final labelParts = _splitLabel(label);

      final params = parsed.queryParameters;
      final rawSecret = params['secret'] ?? '';
      final secret = rawSecret.replaceAll(RegExp(r'[\s\-_]'), '');
      if (secret.isEmpty) return null;

      final rawAlgo = (params['algorithm'] ?? 'SHA1').toUpperCase().replaceAll('-', '');
      final algorithm = switch (rawAlgo) {
        'SHA256' => 'SHA256',
        'SHA512' => 'SHA512',
        _ => 'SHA1',
      };

      final parsedDigits = int.tryParse(params['digits'] ?? '');
      final digits = (parsedDigits == 8) ? 8 : 6;

      final parsedPeriod = int.tryParse(params['period'] ?? '');
      final period = (parsedPeriod != null && parsedPeriod > 0) ? parsedPeriod : 30;
      final counterValue = int.tryParse(params['counter'] ?? '');

      final issuerParam = params['issuer']?.trim();
      final resolvedIssuer = (issuerParam != null && issuerParam.isNotEmpty)
          ? issuerParam
          : labelParts.$1;
      final resolvedLabel = labelParts.$2;

      return OtpAuthResult(
        issuer: resolvedIssuer,
        accountLabel: resolvedLabel,
        secretBase32: secret,
        algorithm: algorithm,
        digits: digits,
        period: period,
        counter: counterValue,
      );
    } catch (_) {
      return null;
    }
  }

  static List<OtpAccount> parseUriList(String text) {
    final accounts = <OtpAccount>[];
    var idCounter = 0;
    final lines = text.split(RegExp(r'[\n\r]+'));
    for (final line in lines) {
      final uri = line.trim();
      if (uri.isEmpty) continue;
      final result = parse(uri);
      if (result != null) {
        accounts.add(result.toAccount(id: _nextId(idCounter++)));
      }
    }
    return accounts;
  }

  static List<OtpAccount> parseGoogleAuthExport(String json) {
    try {
      final decoded = jsonDecode(json);

      List<dynamic> items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map && decoded['otpauth'] is List) {
        items = decoded['otpauth'] as List;
      } else {
        items = [];
      }

      final accounts = <OtpAccount>[];
      var idCounter = 0;

      // Try URI-based format first
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          final uri = item['uri'] as String?;
          if (uri != null) {
            final result = parse(uri);
            if (result != null) {
              accounts.add(result.toAccount(
                id: _nextId(idCounter++),
              ),);
            }
          } else {
            final secret = item['secret'] as String?;
            final issuer = item['issuer'] as String? ?? '';
            final name = item['name'] as String? ?? '';
            if (secret != null && secret.isNotEmpty && name.isNotEmpty) {
              accounts.add(OtpAccount(
                id: _nextId(idCounter++),
                issuer: issuer,
                accountLabel: name,
                secretBase32: secret,
              ),);
            }
          }
        }
      }

      return accounts;
    } catch (_) {
      return [];
    }
  }

  static (String, String) _splitLabel(String label) {
    final colonIndex = label.indexOf(':');
    if (colonIndex > 0 && colonIndex < label.length - 1) {
      return (
        label.substring(0, colonIndex).trim(),
        label.substring(colonIndex + 1).trim(),
      );
    }
    return ('', label.trim());
  }

  static String _nextId(int counter) => const Uuid().v4();
}
