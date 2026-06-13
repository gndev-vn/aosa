import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

class TotpEngine {
  static const int _defaultPeriod = 30;
  static const int _defaultDigits = 6;
  static const String _defaultAlgorithm = 'SHA1';
  static final _base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  final int period;
  final int digits;
  final String algorithm;

  const TotpEngine({
    this.period = _defaultPeriod,
    this.digits = _defaultDigits,
    this.algorithm = _defaultAlgorithm,
  });

  Future<String> generateCode(String secretBase32, {DateTime? timestamp}) async {
    final time = timestamp ?? DateTime.now();
    final unixSeconds = time.millisecondsSinceEpoch ~/ 1000;
    final counter = unixSeconds ~/ period;
    return generateHotp(secretBase32, counter, digits: digits, algorithm: algorithm);
  }

  int get timeLeft {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = period - (now % period);
    return remaining == 0 ? period : remaining;
  }

  @visibleForTesting
  static Future<String> generateHotp(
    String secretBase32,
    int counter, {
    int digits = _defaultDigits,
    String algorithm = _defaultAlgorithm,
  }) async {
    final secret = decodeBase32(secretBase32);
    return generateHotpRaw(secret, counter, digits: digits, algorithm: algorithm);
  }

  @visibleForTesting
  static Future<String> generateHotpRaw(
    List<int> secret,
    int counter, {
    int digits = _defaultDigits,
    String algorithm = _defaultAlgorithm,
  }) async {
    final counterBytes = intToBytes(counter);
    final hmac = await computeHmac(secret, counterBytes, algorithm);
    final truncated = dynamicTruncation(hmac);
    final codeNum = truncated % pow(10, digits).toInt();
    return codeNum.toString().padLeft(digits, '0');
  }

  @visibleForTesting
  static List<int> intToBytes(int value) {
    final bytes = List<int>.filled(8, 0);
    for (int i = 7; i >= 0; i--) {
      bytes[i] = value & 0xff;
      value >>= 8;
    }
    return bytes;
  }

  @visibleForTesting
  static Future<List<int>> computeHmac(
    List<int> secret,
    List<int> counterBytes,
    String algorithm,
  ) async {
    final hmac = Hmac(getHmacAlgorithm(algorithm));
    final mac = await hmac.calculateMac(
      counterBytes,
      secretKey: SecretKey(secret),
    );
    return mac.bytes;
  }

  @visibleForTesting
  static HashAlgorithm getHmacAlgorithm(String algorithm) {
    return switch (algorithm.toUpperCase()) {
      'SHA256' => Sha256(),
      'SHA512' => Sha512(),
      _ => Sha1(),
    };
  }

  @visibleForTesting
  static int dynamicTruncation(List<int> hmac) {
    final offset = hmac.last & 0x0f;
    final truncated = ((hmac[offset] & 0x7f) << 24) |
        ((hmac[offset + 1] & 0xff) << 16) |
        ((hmac[offset + 2] & 0xff) << 8) |
        (hmac[offset + 3] & 0xff);
    return truncated;
  }

  @visibleForTesting
  static List<int> decodeBase32(String input) {
    final cleaned = input
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('=', '');

    final bytes = <int>[];
    int buffer = 0;
    int bitsLeft = 0;

    for (final char in cleaned.runes) {
      final value = _base32Alphabet.indexOf(String.fromCharCode(char));
      if (value == -1) continue;

      buffer = (buffer << 5) | value;
      bitsLeft += 5;

      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        bytes.add((buffer >> bitsLeft) & 0xff);
        buffer &= (1 << bitsLeft) - 1;
      }
    }

    return bytes;
  }

  static bool isValidBase32(String input) {
    if (input.isEmpty) return false;
    final cleaned = input
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('=', '');
    if (cleaned.length < 4) return false;
    return cleaned
        .runes
        .every((c) => _base32Alphabet.contains(String.fromCharCode(c)));
  }

  static bool isValidAlgorithm(String algo) {
    return ['SHA1', 'SHA256', 'SHA512'].contains(algo.toUpperCase());
  }
}
