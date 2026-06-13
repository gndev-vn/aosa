import 'package:flutter_test/flutter_test.dart';

import 'package:aosa/domain/usecases/totp_engine.dart';

void main() {
  group('Base32 Decoding', () {
    test('decodes standard Base32', () {
      // "Hello!" = "JBSWY3DPEBLW64T"
      final result = TotpEngine.decodeBase32('JBSWY3DPEBLW64T');
      expect(result, [72, 101, 108, 108, 111, 33]);
    });

    test('decodes with lowercase input', () {
      final result = TotpEngine.decodeBase32('jbswy3dpeblw64t');
      expect(result, [72, 101, 108, 108, 111, 33]);
    });

    test('decodes with padding', () {
      final result = TotpEngine.decodeBase32('MY======');
      expect(result, [102]);
    });

    test('returns empty for empty input', () {
      final result = TotpEngine.decodeBase32('');
      expect(result, isEmpty);
    });

    test('isValidBase32 returns true for valid input', () {
      expect(TotpEngine.isValidBase32('JBSWY3DPEBLW64T'), isTrue);
    });

    test('isValidBase32 returns false for empty', () {
      expect(TotpEngine.isValidBase32(''), isFalse);
    });

    test('isValidBase32 returns false for invalid chars', () {
      expect(TotpEngine.isValidBase32('JBSWY3DP!!'), isFalse);
    });
  });

  group('HOTP (RFC 4226) - SHA1 6-digit', () {
    final secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

    test('counter 0 = 755224', () async {
      expect(await TotpEngine.generateHotp(secret, 0), '755224');
    });

    test('counter 1 = 287082', () async {
      expect(await TotpEngine.generateHotp(secret, 1), '287082');
    });

    test('counter 2 = 359152', () async {
      expect(await TotpEngine.generateHotp(secret, 2), '359152');
    });

    test('counter 3 = 969429', () async {
      expect(await TotpEngine.generateHotp(secret, 3), '969429');
    });

    test('counter 4 = 338314', () async {
      expect(await TotpEngine.generateHotp(secret, 4), '338314');
    });

    test('counter 5 = 254676', () async {
      expect(await TotpEngine.generateHotp(secret, 5), '254676');
    });

    test('counter 6 = 287922', () async {
      expect(await TotpEngine.generateHotp(secret, 6), '287922');
    });

    test('counter 7 = 162583', () async {
      expect(await TotpEngine.generateHotp(secret, 7), '162583');
    });

    test('counter 8 = 399871', () async {
      expect(await TotpEngine.generateHotp(secret, 8), '399871');
    });

    test('counter 9 = 520489', () async {
      expect(await TotpEngine.generateHotp(secret, 9), '520489');
    });
  });

  group('HOTP - 8 Digit Codes', () {
    final secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

    test('counter 0 with 8 digits', () async {
      final result = await TotpEngine.generateHotp(secret, 0, digits: 8);
      expect(result, '4755224'.padLeft(8, '0'));
    });

    test('counter 1 with 8 digits', () async {
      final result = await TotpEngine.generateHotp(secret, 1, digits: 8);
      expect(result, '8287082'.padLeft(8, '0'));
    });
  });

  group('Dynamic Truncation', () {
    test('produces 31-bit positive number', () async {
      final hmac = await TotpEngine.computeHmac(
        TotpEngine.decodeBase32('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ'),
        [0, 0, 0, 0, 0, 0, 0, 0],
        'SHA1',
      );
      final truncated = TotpEngine.dynamicTruncation(hmac);
      expect(truncated, greaterThan(0));
      expect(truncated, lessThan(1 << 31));
    });
  });

  group('Algorithm Validation', () {
    test('SHA1 is valid', () {
      expect(TotpEngine.isValidAlgorithm('SHA1'), isTrue);
    });

    test('SHA256 is valid', () {
      expect(TotpEngine.isValidAlgorithm('SHA256'), isTrue);
    });

    test('SHA512 is valid', () {
      expect(TotpEngine.isValidAlgorithm('SHA512'), isTrue);
    });

    test('case insensitive', () {
      expect(TotpEngine.isValidAlgorithm('sha1'), isTrue);
      expect(TotpEngine.isValidAlgorithm('Sha256'), isTrue);
    });
  });

  group('Time Left Calculation', () {
    test('timeLeft is within period range', () {
      final engine = TotpEngine();
      final tl = engine.timeLeft;
      expect(tl, greaterThan(0));
      expect(tl, lessThanOrEqualTo(30));
    });

    test('timeLeft with 60s period', () {
      final engine = TotpEngine(period: 60);
      final tl = engine.timeLeft;
      expect(tl, greaterThan(0));
      expect(tl, lessThanOrEqualTo(60));
    });
  });

  group('Full TOTP Generation', () {
    test('generates 6-digit code by default', () async {
      final engine = TotpEngine();
      final code = await engine.generateCode('JBSWY3DPEHPK3PXP');
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
    });

    test('generates 8-digit code', () async {
      final engine = TotpEngine(digits: 8);
      final code = await engine.generateCode('JBSWY3DPEHPK3PXP');
      expect(code.length, 8);
      expect(int.tryParse(code), isNotNull);
    });

    test('different codes at different time windows', () async {
      final engine = TotpEngine();
      final code1 = await engine.generateCode(
        'JBSWY3DPEHPK3PXP',
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final code2 = await engine.generateCode(
        'JBSWY3DPEHPK3PXP',
        timestamp: DateTime.fromMillisecondsSinceEpoch(30000),
      );
      expect(code1, isNot(equals(code2)));
    });

    test('same code within same time window', () async {
      final engine = TotpEngine();
      final code1 = await engine.generateCode(
        'JBSWY3DPEHPK3PXP',
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );
      final code2 = await engine.generateCode(
        'JBSWY3DPEHPK3PXP',
        timestamp: DateTime.fromMillisecondsSinceEpoch(5000),
      );
      expect(code1, equals(code2));
    });

    test('SHA256 algorithm works', () async {
      final engine = TotpEngine(algorithm: 'SHA256');
      final code = await engine.generateCode('JBSWY3DPEHPK3PXP');
      expect(code.length, 6);
    });

    test('SHA512 algorithm works', () async {
      final engine = TotpEngine(algorithm: 'SHA512');
      final code = await engine.generateCode('JBSWY3DPEHPK3PXP');
      expect(code.length, 6);
    });

    test('60 second period works', () async {
      final engine = TotpEngine(period: 60);
      final code = await engine.generateCode('JBSWY3DPEHPK3PXP');
      expect(code.length, 6);
    });
  });

  group('Int to Bytes Conversion', () {
    test('0 produces 8 zero bytes', () {
      expect(TotpEngine.intToBytes(0), [0, 0, 0, 0, 0, 0, 0, 0]);
    });

    test('1 produces big-endian representation', () {
      expect(TotpEngine.intToBytes(1), [0, 0, 0, 0, 0, 0, 0, 1]);
    });

    test('large number big-endian', () {
      expect(TotpEngine.intToBytes(0x1234567890), [
        0x00, 0x00, 0x00, 0x12, 0x34, 0x56, 0x78, 0x90,
      ]);
    });
  });
}
