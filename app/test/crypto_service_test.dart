import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:aosa/data/encryption/crypto_service.dart';

void main() {
  late CryptoService crypto;

  setUp(() {
    crypto = CryptoService(Uint8List.fromList(
      List.generate(32, (i) => i),
    ));
  });

  group('CryptoService', () {
    test('encrypt and decrypt roundtrip', () async {
      const plaintext = 'Hello, AOSA!';
      final encrypted = await crypto.encrypt(plaintext);
      expect(encrypted.ciphertext, isNotEmpty);
      expect(encrypted.nonce, isNotEmpty);
      expect(encrypted.authTag, isNotEmpty);

      final decrypted = await crypto.decrypt(encrypted);
      expect(decrypted, plaintext);
    });

    test('encrypt generates different nonces each time', () async {
      const plaintext = 'same text';
      final e1 = await crypto.encrypt(plaintext);
      final e2 = await crypto.encrypt(plaintext);
      expect(e1.nonce, isNot(equals(e2.nonce)));
    });

    test('decrypt with wrong key fails', () async {
      const plaintext = 'secret data';
      final encrypted = await crypto.encrypt(plaintext);

      final wrongCrypto = CryptoService(Uint8List.fromList(
        List.generate(32, (i) => 0xff),
      ));

      await expectLater(
        () => wrongCrypto.decrypt(encrypted),
        throwsA(isA<Exception>()),
      );
    });

    test('encrypts and decrypts large text', () async {
      final large = 'A' * 10000;
      final encrypted = await crypto.encrypt(large);
      final decrypted = await crypto.decrypt(encrypted);
      expect(decrypted, large);
    });

    test('EncryptedPayload toJson/fromJson roundtrip', () async {
      const plaintext = 'test payload';
      final encrypted = await crypto.encrypt(plaintext);
      final json = encrypted.toJson();
      final restored = EncryptedPayload.fromJson(json);
      expect(restored.ciphertext, encrypted.ciphertext);
      expect(restored.nonce, encrypted.nonce);
      expect(restored.salt, encrypted.salt);
      expect(restored.authTag, encrypted.authTag);
    });
  });

  group('CryptoService.deriveKey', () {
    test('derives same key from same pin and salt', () async {
      final salt = CryptoService.generateSalt();
      final key1 = await CryptoService.deriveKey('test-pin', salt);
      final key2 = await CryptoService.deriveKey('test-pin', salt);
      expect(key1, key2);
    });

    test('derives different keys for different pins', () async {
      final salt = CryptoService.generateSalt();
      final key1 = await CryptoService.deriveKey('pin-a', salt);
      final key2 = await CryptoService.deriveKey('pin-b', salt);
      expect(key1, isNot(equals(key2)));
    });
  });

  group('CryptoService.verifyToken and verifyPin', () {
    test('verifyToken and verifyPin roundtrip', () async {
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      final token = await CryptoService.verifyToken(key);
      expect(token, isNotEmpty);

      final valid = await CryptoService.verifyPin(key, token);
      expect(valid, isTrue);
    });

    test('verifyPin returns false for wrong key', () async {
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      final wrongKey = Uint8List.fromList(List.generate(32, (i) => 0xff));
      final token = await CryptoService.verifyToken(key);

      final valid = await CryptoService.verifyPin(wrongKey, token);
      expect(valid, isFalse);
    });
  });
}
