import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:aosa/domain/usecases/totp_engine.dart';

void main() {
  group('Base32 Decoding', () {
    test('decodes standard Base32', () {
      // "Hello!" = "JBSWY3DPEE======" (RFC 4648)
      final result = TotpEngine.decodeBase32('JBSWY3DPEE======');
      expect(result, [72, 101, 108, 108, 111, 33]);
    });

    test('decodes with lowercase input', () {
      final result = TotpEngine.decodeBase32('jbswy3dpee======');
      expect(result, [72, 101, 108, 108, 111, 33]);
    });

    test('decodes standard Base32 sentence', () {
      // "Hello World" = "JBSWY3DPEBLW64TMMQ======"
      final result = TotpEngine.decodeBase32('JBSWY3DPEBLW64TMMQ======');
      expect(result, [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100]);
    });

    test('decodes with padding', () {
      final result = TotpEngine.decodeBase32('MY======');
      expect(result, [102]);
    });

    test('returns empty for empty input', () {
      final result = TotpEngine.decodeBase32('');
      expect(result, isEmpty);
    });

    test('decodes with internal spaces and hyphens', () {
      final expected = [72, 101, 108, 108, 111, 33];
      expect(TotpEngine.decodeBase32('JBSW Y3DP EE======'), expected);
      expect(TotpEngine.decodeBase32('JBSW-Y3DP-EE======'), expected);
      expect(TotpEngine.decodeBase32('JBSW_Y3DP_EE======'), expected);
      expect(TotpEngine.decodeBase32('  jbsw-y3dp ee======  '), expected);
    });

    test('decodes without padding (missing padding)', () {
      final expected = [72, 101, 108, 108, 111, 33];
      expect(TotpEngine.decodeBase32('JBSWY3DPEE'), expected);
      expect(TotpEngine.decodeBase32('jbswy3dpee'), expected);
    });

    test('isValidBase32 returns true for valid input', () {
      expect(TotpEngine.isValidBase32('JBSWY3DPEE======'), isTrue);
      expect(TotpEngine.isValidBase32('JBSW-Y3DP-EE'), isTrue);
      expect(TotpEngine.isValidBase32('jbsw y3dp ee'), isTrue);
    });

    test('isValidBase32 returns false for empty or short input', () {
      expect(TotpEngine.isValidBase32(''), isFalse);
      expect(TotpEngine.isValidBase32('   ---   '), isFalse);
      expect(TotpEngine.isValidBase32('ABC'), isFalse);
    });

    test('isValidBase32 returns false for invalid chars', () {
      expect(TotpEngine.isValidBase32('JBSWY3DP!!'), isFalse);
    });
  });

  group('HOTP (RFC 4226) - SHA1 6-digit', () {
    const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

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
    const secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

    test('counter 0 with 8 digits', () async {
      final result = await TotpEngine.generateHotp(secret, 0, digits: 8);
      expect(result, '84755224');
    });

    test('counter 1 with 8 digits', () async {
      final result = await TotpEngine.generateHotp(secret, 1, digits: 8);
      expect(result, '94287082');
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
      const engine = TotpEngine();
      final tl = engine.timeLeft;
      expect(tl, greaterThan(0));
      expect(tl, lessThanOrEqualTo(30));
    });

    test('timeLeft with 60s period', () {
      const engine = TotpEngine(period: 60);
      final tl = engine.timeLeft;
      expect(tl, greaterThan(0));
      expect(tl, lessThanOrEqualTo(60));
    });
  });

  group('Full TOTP Generation', () {
    test('generates 6-digit code by default', () async {
      const engine = TotpEngine();
      final code = await engine.generateCode('JBSWY3DPEHPK3PXP');
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
    });

    test('generates 8-digit code', () async {
      const engine = TotpEngine(digits: 8);
      final code = await engine.generateCode('JBSWY3DPEHPK3PXP');
      expect(code.length, 8);
      expect(int.tryParse(code), isNotNull);
    });

    test('different codes at different time windows', () async {
      const engine = TotpEngine();
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
      const engine = TotpEngine();
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
      const engine = TotpEngine(algorithm: 'SHA256');
      final code = await engine.generateCode('JBSWY3DPEHPK3PXP');
      expect(code.length, 6);
    });

    test('SHA512 algorithm works', () async {
      const engine = TotpEngine(algorithm: 'SHA512');
      final code = await engine.generateCode('JBSWY3DPEHPK3PXP');
      expect(code.length, 6);
    });

    test('60 second period works', () async {
      const engine = TotpEngine(period: 60);
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

  group('RFC 6238 Reference Vectors (Appendix B)', () {
    final sha1Secret = ascii.encode('12345678901234567890');
    final sha256Secret = ascii.encode('12345678901234567890123456789012');
    final sha512Secret = ascii.encode(
      '1234567890123456789012345678901234567890123456789012345678901234',
    );

    test('SHA1 test vectors match RFC 6238 Appendix B', () async {
      final vectors = [
        (59 ~/ 30, '94287082'),
        (1111111109 ~/ 30, '07081804'),
        (1111111111 ~/ 30, '14050471'),
        (1234567890 ~/ 30, '89005924'),
        (2000000000 ~/ 30, '69279037'),
        (20000000000 ~/ 30, '65353130'),
      ];

      for (final (counter, expected) in vectors) {
        final code = await TotpEngine.generateHotpRaw(
          sha1Secret,
          counter,
          digits: 8,
          algorithm: 'SHA1',
        );
        expect(code, expected, reason: 'Failed for counter $counter');
      }
    });

    test('SHA256 test vectors match RFC 6238 Appendix B', () async {
      final vectors = [
        (59 ~/ 30, '46119246'),
        (1111111109 ~/ 30, '68084774'),
        (1111111111 ~/ 30, '67062674'),
        (1234567890 ~/ 30, '91819424'),
        (2000000000 ~/ 30, '90698825'),
        (20000000000 ~/ 30, '77737706'),
      ];

      for (final (counter, expected) in vectors) {
        final code = await TotpEngine.generateHotpRaw(
          sha256Secret,
          counter,
          digits: 8,
          algorithm: 'SHA256',
        );
        expect(code, expected, reason: 'Failed for counter $counter');
      }
    });

    test('SHA512 test vectors match RFC 6238 Appendix B', () async {
      final vectors = [
        (59 ~/ 30, '90693936'),
        (1111111109 ~/ 30, '25091201'),
        (1111111111 ~/ 30, '99943326'),
        (1234567890 ~/ 30, '93441116'),
        (2000000000 ~/ 30, '38618901'),
        (20000000000 ~/ 30, '47863826'),
      ];

      for (final (counter, expected) in vectors) {
        final code = await TotpEngine.generateHotpRaw(
          sha512Secret,
          counter,
          digits: 8,
          algorithm: 'SHA512',
        );
        expect(code, expected, reason: 'Failed for counter $counter');
      }
    });

    test('generateCode with Base32 secret generates exact RFC 6238 code', () async {
      // Base32 for '12345678901234567890' is 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ'
      const engine = TotpEngine(digits: 8, algorithm: 'SHA1');
      final code = await engine.generateCode(
        'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ',
        timestamp: DateTime.fromMillisecondsSinceEpoch(59 * 1000),
      );
      expect(code, '94287082');
    });

    test('generateCode handles secrets with spaces, hyphens, and lowercase', () async {
      const engine = TotpEngine(digits: 8, algorithm: 'SHA1');
      final code = await engine.generateCode(
        '  gezd-gnbv-gy3t-qojq  gezd-gnbv-gy3t-qojq  ',
        timestamp: DateTime.fromMillisecondsSinceEpoch(59 * 1000),
      );
      expect(code, '94287082');
    });

    test('varying periods (10s, 60s, 300s) calculate time and step correctly', () async {
      for (final period in [10, 30, 60, 120, 300]) {
        final engine = TotpEngine(period: period);
        expect(engine.timeLeft, greaterThan(0));
        expect(engine.timeLeft, lessThanOrEqualTo(period));

        final code = await engine.generateCode(
          'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ',
          timestamp: DateTime.fromMillisecondsSinceEpoch(100000),
        );
        expect(code.length, 6);
      }
    });
  });
}
