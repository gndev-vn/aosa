import 'dart:convert';

import 'package:aosa/data/api/sync_api.dart';
import 'package:aosa/data/database/app_database.dart';
import 'package:aosa/data/encryption/crypto_service.dart';
import 'package:aosa/domain/entities/otp_account.dart';

enum SyncResult { success, error }

class SyncService {
  final SyncApi _syncApi;
  final AppDatabase _db;
  final CryptoService _crypto;

  SyncService(this._syncApi, this._db, this._crypto);

  Future<String?> fullSync({required String repoId}) async {
    try {
      await _pushChanges(repoId: repoId);
      await _pullChanges(repoId: repoId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> _pushChanges({required String repoId}) async {
    final queued = _db.getQueuedItems();
    if (queued.isEmpty) return;

    final changes = <PushChange>[];
    for (final item in queued) {
      changes.add(PushChange(
        id: item['record_id'] as String,
        encryptedBlob: item['encrypted_data'] as String,
        expectedVersion: item['expected_version'] as int,
        clientTimestamp: DateTime.parse(item['created_at'] as String),
      ));
    }

    final result = await _syncApi.push(repoId: repoId, changes: changes);

    for (final a in result.accepted) {
      _db.clearQueuedForRecord(a.id, a.newVersion - 1);
    }
  }

  Future<void> _pullChanges({required String repoId}) async {
    final status = await _syncApi.getStatus(repoId: repoId);
    if (status.serverVersion == 0) return;

    final localVersion = _getLocalVersion();
    if (status.serverVersion <= localVersion) return;

    final pullResult = await _syncApi.pull(repoId: repoId, sinceVersion: localVersion);

    for (final record in pullResult.items) {
      final local = _db.getAccount(record.id);
      if (local != null && (local['version'] as int) >= record.version) continue;

      if (record.deletedAt != null) {
        _db.deleteAccount(record.id);
        continue;
      }

      try {
        final parsed = jsonDecode(record.encryptedBlob) as Map<String, dynamic>;
        final decrypted = await _crypto.decrypt(
          EncryptedPayload.fromJson(parsed),
        );
        final accountJson = jsonDecode(decrypted) as Map<String, dynamic>;
        final account = OtpAccount.fromJson(accountJson);

        _db.execute(
          '''INSERT OR REPLACE INTO otp_accounts
             (id, encrypted_data, nonce, salt, auth_tag, issuer, account_label,
              algorithm, digits, period, version, sort_order, shortcut_key,
              created_at, updated_at, deleted_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
          [
            account.id,
            parsed['ciphertext'],
            parsed['nonce'],
            parsed['salt'],
            parsed['auth_tag'],
            account.issuer,
            account.accountLabel,
            account.algorithm,
            account.digits,
            account.period,
            record.version,
            account.sortOrder,
            account.shortcutKey,
            record.createdAt.toIso8601String(),
            record.updatedAt.toIso8601String(),
            record.deletedAt?.toIso8601String(),
          ],
        );
      } catch (_) {}
    }

    _setLocalVersion(pullResult.serverVersion);
  }

  int _getLocalVersion() {
    final val = _db.getSetting('server_version');
    if (val == null) return 0;
    return int.tryParse(val) ?? 0;
  }

  void _setLocalVersion(int version) {
    _db.setSetting('server_version', version.toString());
  }
}
