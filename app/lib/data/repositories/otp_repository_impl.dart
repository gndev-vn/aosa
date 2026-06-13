import 'dart:async';
import 'dart:convert';
import 'package:aosa/data/database/app_database.dart';
import 'package:aosa/data/encryption/crypto_service.dart';
import 'package:aosa/domain/entities/otp_account.dart';
import 'package:aosa/domain/repositories/otp_repository.dart';

class OtpRepositoryImpl implements OtpRepository {
  final AppDatabase _db;
  final CryptoService _crypto;

  OtpRepositoryImpl(this._db, this._crypto);

  @override
  Future<List<OtpAccount>> getAll() async {
    final rows = _db.getAllAccounts();
    final results = <OtpAccount>[];
    for (final row in rows) {
      final account = await _toDomain(row);
      results.add(account);
    }
    return results;
  }

  @override
  Stream<List<OtpAccount>> watchAll() {
    // Simple polling stream — can be upgraded to a proper reactive stream later
    return Stream.periodic(const Duration(seconds: 1), (_) => getAll())
        .asyncMap((f) => f);
  }

  @override
  Future<OtpAccount?> getById(String id) async {
    final row = _db.getAccount(id);
    if (row == null) return null;
    return _toDomain(row);
  }

  @override
  Future<void> save(OtpAccount account) async {
    final encryptedJson = await _crypto.encrypt(jsonEncode(account.toJson()));
    final now = DateTime.now().toUtc().toIso8601String();

    final data = <String, dynamic>{
      'id': account.id,
      'encrypted_data': encryptedJson.ciphertext,
      'nonce': encryptedJson.nonce,
      'salt': encryptedJson.salt,
      'auth_tag': encryptedJson.authTag,
      'issuer': account.issuer,
      'account_label': account.accountLabel,
      'algorithm': account.algorithm,
      'digits': account.digits,
      'period': account.period,
      'version': account.version,
      'sort_order': account.sortOrder,
      'shortcut_key': account.shortcutKey,
      'created_at': account.createdAt?.toUtc().toIso8601String() ?? now,
      'updated_at': now,
      'deleted_at': account.deletedAt?.toUtc().toIso8601String(),
    };

    final existing = _db.getAccount(account.id);
    if (existing != null) {
      _db.updateAccount(data);
    } else {
      _db.insertAccount(data);
    }
  }

  @override
  Future<void> delete(String id) async {
    _db.deleteAccount(id);
  }

  @override
  Future<int> count() async => _db.accountCount();

  @override
  Future<List<OtpAccount>> search(String query) async {
    final all = await getAll();
    final lowerQuery = query.toLowerCase();
    return all.where((a) {
      return a.issuer.toLowerCase().contains(lowerQuery) ||
          a.accountLabel.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  Future<OtpAccount> _toDomain(Map<String, dynamic> row) async {
    String secret = '';
    try {
      final payload = EncryptedPayload(
        ciphertext: row['encrypted_data'] as String,
        nonce: row['nonce'] as String,
        salt: row['salt'] as String,
        authTag: row['auth_tag'] as String,
      );
      final decrypted = await _crypto.decrypt(payload);
      final json = jsonDecode(decrypted) as Map<String, dynamic>;
      secret = json['secret_base32'] as String? ?? '';
    } catch (_) {}

    return OtpAccount(
      id: row['id'] as String,
      issuer: row['issuer'] as String,
      accountLabel: row['account_label'] as String,
      secretBase32: secret,
      algorithm: row['algorithm'] as String? ?? 'SHA1',
      digits: row['digits'] as int? ?? 6,
      period: row['period'] as int? ?? 30,
      version: row['version'] as int? ?? 1,
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
      deletedAt: _parseDate(row['deleted_at']),
      shortcutKey: row['shortcut_key'] as String?,
      sortOrder: row['sort_order'] as int? ?? -1,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String);
  }
}
