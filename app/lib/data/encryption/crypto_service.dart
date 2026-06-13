import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class CryptoService {
  static const int _saltLength = 32;
  static const int _nonceLength = 12;
  static const int _tagLength = 16;
  static const int _keyLength = 32;

  final Uint8List _masterKey;

  CryptoService(this._masterKey);

  static Future<CryptoService> fromPin(String pin, Uint8List salt) async {
    final key = await deriveKey(pin, salt);
    return CryptoService(key);
  }

  Future<EncryptedPayload> encrypt(String plaintext) async {
    final nonce = _generateRandomBytes(_nonceLength);
    final cipher = AesGcm.with256bits();
    final secretBox = await cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: SecretKey(_masterKey),
      nonce: nonce,
    );

    return EncryptedPayload(
      ciphertext: base64Encode(secretBox.cipherText),
      nonce: base64Encode(nonce),
      salt: base64Encode(Uint8List(0)),
      authTag: base64Encode(secretBox.mac.bytes),
    );
  }

  Future<String> decrypt(EncryptedPayload payload) async {
    final cipher = AesGcm.with256bits();
    final secretBox = SecretBox(
      base64Decode(payload.ciphertext),
      nonce: base64Decode(payload.nonce),
      mac: Mac(base64Decode(payload.authTag)),
    );

    final plaintext = await cipher.decrypt(
      secretBox,
      secretKey: SecretKey(_masterKey),
    );

    return utf8.decode(plaintext);
  }

  static Future<Uint8List> deriveKey(String pin, List<int> salt) async {
    final argon2 = Argon2id(
      parallelism: 4,
      memory: 65536,
      iterations: 3,
      hashLength: _keyLength,
    );

    final key = await argon2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );

    final extracted = await key.extract();
    return Uint8List.fromList(extracted.bytes);
  }

  static Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  static Uint8List generateSalt() => _generateRandomBytes(_saltLength);

  static Future<String> verifyToken(Uint8List key) async {
    final cipher = AesGcm.with256bits();
    final nonce = _generateRandomBytes(_nonceLength);
    final secretBox = await cipher.encrypt(
      utf8.encode('AOSA_PIN_VERIFY'),
      secretKey: SecretKey(key),
      nonce: nonce,
    );
    return base64Encode([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  static Future<bool> verifyPin(Uint8List key, String storedToken) async {
    try {
      final decoded = base64Decode(storedToken);
      final nonce = decoded.sublist(0, _nonceLength);
      final cipherText = decoded.sublist(_nonceLength, decoded.length - _tagLength);
      final tag = decoded.sublist(decoded.length - _tagLength);

      final cipher = AesGcm.with256bits();
      final plaintext = await cipher.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(tag)),
        secretKey: SecretKey(key),
      );
      return utf8.decode(plaintext) == 'AOSA_PIN_VERIFY';
    } catch (_) {
      return false;
    }
  }
}

class EncryptedPayload {
  final String ciphertext;
  final String nonce;
  final String salt;
  final String authTag;

  const EncryptedPayload({
    required this.ciphertext,
    required this.nonce,
    required this.salt,
    required this.authTag,
  });

  Map<String, dynamic> toJson() => {
        'ciphertext': ciphertext,
        'nonce': nonce,
        'salt': salt,
        'auth_tag': authTag,
      };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) =>
      EncryptedPayload(
        ciphertext: json['ciphertext'] as String,
        nonce: json['nonce'] as String,
        salt: json['salt'] as String,
        authTag: json['auth_tag'] as String,
      );
}
