import 'package:flutter_test/flutter_test.dart';
import 'package:aosa/domain/usecases/otpauth_parser.dart';

void main() {
  group('OtpAuthParser.parse', () {
    test('parses standard TOTP URI', () {
      final result = OtpAuthParser.parse(
        'otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example',
      );
      expect(result, isNotNull);
      expect(result!.issuer, 'Example');
      expect(result.accountLabel, 'alice@google.com');
      expect(result.secretBase32, 'JBSWY3DPEHPK3PXP');
      expect(result.algorithm, 'SHA1');
      expect(result.digits, 6);
      expect(result.period, 30);
    });

    test('parses TOTP with custom algorithm, digits and period', () {
      final result = OtpAuthParser.parse(
        'otpauth://totp/ACME:john@example.com?secret=GEZDGNBVGY3TQOJQ&algorithm=SHA256&digits=8&period=60&issuer=ACME',
      );
      expect(result, isNotNull);
      expect(result!.issuer, 'ACME');
      expect(result.accountLabel, 'john@example.com');
      expect(result.secretBase32, 'GEZDGNBVGY3TQOJQ');
      expect(result.algorithm, 'SHA256');
      expect(result.digits, 8);
      expect(result.period, 60);
    });

    test('parses HOTP URI with counter', () {
      final result = OtpAuthParser.parse(
        'otpauth://hotp/ACME:john@example.com?secret=GEZDGNBVGY3TQOJQ&counter=42&issuer=ACME',
      );
      expect(result, isNotNull);
      expect(result!.issuer, 'ACME');
      expect(result.accountLabel, 'john@example.com');
      expect(result.counter, 42);
    });

    test('uses issuer from label when no issuer param', () {
      final result = OtpAuthParser.parse(
        'otpauth://totp/Big%20Corp:alice@bigcorp.com?secret=JBSWY3DPEHPK3PXP',
      );
      expect(result, isNotNull);
      expect(result!.issuer, 'Big Corp');
      expect(result.accountLabel, 'alice@bigcorp.com');
    });

    test('returns null for non-otpauth scheme', () {
      expect(OtpAuthParser.parse('https://example.com'), isNull);
    });

    test('returns null for empty secret', () {
      expect(
        OtpAuthParser.parse('otpauth://totp/Test:test?secret='),
        isNull,
      );
    });

    test('returns null for invalid URI', () {
      expect(OtpAuthParser.parse('not a uri'), isNull);
    });

    test('handles special characters in label', () {
      final result = OtpAuthParser.parse(
        'otpauth://totp/GitHub:user%2Btest@github.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub',
      );
      expect(result, isNotNull);
      expect(result!.issuer, 'GitHub');
      expect(result.accountLabel, 'user+test@github.com');
    });

    test('toAccount generates valid OtpAccount', () {
      final result = OtpAuthParser.parse(
        'otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example',
      );
      expect(result, isNotNull);
      final account = result!.toAccount(id: 'test-id');
      expect(account.id, 'test-id');
      expect(account.issuer, 'Example');
      expect(account.secretBase32, 'JBSWY3DPEHPK3PXP');
      expect(account.digits, 6);
      expect(account.period, 30);
    });
  });

  group('OtpAuthParser.parseUriList', () {
    test('parses multiple URIs from text', () {
      final text = 'otpauth://totp/Example1:alice@test.com?secret=JBSWY3DPEHPK3PXP&issuer=Example1\n'
          'otpauth://totp/Example2:bob@test.com?secret=GEZDGNBVGY3TQOJQ&issuer=Example2';
      final accounts = OtpAuthParser.parseUriList(text);
      expect(accounts.length, 2);
      expect(accounts[0].issuer, 'Example1');
      expect(accounts[1].issuer, 'Example2');
    });

    test('skips empty lines and invalid URIs', () {
      final text = 'otpauth://totp/Test:test@test.com?secret=JBSWY3DPEHPK3PXP\n\ninvalid\n';
      final accounts = OtpAuthParser.parseUriList(text);
      expect(accounts.length, 1);
    });
  });

  group('OtpAuthParser.parseGoogleAuthExport', () {
    test('parses URI-based format', () {
      final json = '''
      [
        {"uri": "otpauth://totp/Example:alice@test.com?secret=JBSWY3DPEHPK3PXP&issuer=Example"},
        {"uri": "otpauth://totp/ACME:bob@test.com?secret=GEZDGNBVGY3TQOJQ&issuer=ACME"}
      ]
      ''';
      final accounts = OtpAuthParser.parseGoogleAuthExport(json);
      expect(accounts.length, 2);
      expect(accounts[0].issuer, 'Example');
      expect(accounts[1].issuer, 'ACME');
    });

    test('parses secret-based format', () {
      final json = '''
      [
        {"secret": "JBSWY3DPEHPK3PXP", "issuer": "GitHub", "name": "alice@github.com"},
        {"secret": "GEZDGNBVGY3TQOJQ", "issuer": "Google", "name": "bob@gmail.com"}
      ]
      ''';
      final accounts = OtpAuthParser.parseGoogleAuthExport(json);
      expect(accounts.length, 2);
      expect(accounts[0].issuer, 'GitHub');
      expect(accounts[1].secretBase32, 'GEZDGNBVGY3TQOJQ');
    });

    test('returns empty list for invalid JSON', () {
      expect(OtpAuthParser.parseGoogleAuthExport('not json'), isEmpty);
    });
  });
}
