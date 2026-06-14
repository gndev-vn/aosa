import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:aosa/data/database/app_database.dart';

class _TestPathProvider extends PathProviderPlatform {
  final Directory tempDir;

  _TestPathProvider(this.tempDir);

  @override
  Future<String> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String> getTemporaryPath() async =>
      Directory.systemTemp.createTempSync('aosa_test_tmp_').path;

  @override
  Future<String> getApplicationSupportPath() async => tempDir.path;
}

void main() {
  late Directory tempDir;
  late AppDatabase db;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('aosa_test_');
    PathProviderPlatform.instance = _TestPathProvider(tempDir);
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() {
    db.dispose();
    tempDir.deleteSync(recursive: true);
  });

  group('AppDatabase', () {
    test('creates tables on open', () async {
      db = await AppDatabase.getInstance();
      expect(db.getAllAccounts(), isEmpty);
    });

    test('inserts and retrieves an account', () async {
      db = await AppDatabase.getInstance();
      db.insertAccount({
        'id': 'test-id-1',
        'encrypted_data': 'enc123',
        'nonce': 'nonce123',
        'salt': 'salt123',
        'auth_tag': 'tag123',
        'issuer': 'Test Issuer',
        'account_label': 'test@example.com',
        'algorithm': 'SHA1',
        'digits': 6,
        'period': 30,
        'version': 1,
        'sort_order': 0,
        'shortcut_key': null,
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'deleted_at': null,
      });

      final result = db.getAccount('test-id-1');
      expect(result, isNotNull);
      expect(result!['issuer'], 'Test Issuer');
      expect(result['account_label'], 'test@example.com');
    });

    test('getAllAccounts returns only non-deleted', () async {
      db = await AppDatabase.getInstance();

      db.insertAccount({
        'id': 'active-1',
        'encrypted_data': 'e1',
        'nonce': 'n1',
        'salt': 's1',
        'auth_tag': 't1',
        'issuer': 'Active',
        'account_label': 'a@a.com',
        'algorithm': 'SHA1',
        'digits': 6,
        'period': 30,
        'version': 1,
        'sort_order': 0,
        'shortcut_key': null,
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'deleted_at': null,
      });

      db.insertAccount({
        'id': 'deleted-1',
        'encrypted_data': 'e2',
        'nonce': 'n2',
        'salt': 's2',
        'auth_tag': 't2',
        'issuer': 'Deleted',
        'account_label': 'b@b.com',
        'algorithm': 'SHA1',
        'digits': 6,
        'period': 30,
        'version': 1,
        'sort_order': 0,
        'shortcut_key': null,
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'deleted_at': '2025-01-02T00:00:00Z',
      });

      final all = db.getAllAccounts();
      expect(all.length, 1);
      expect(all[0]['id'], 'active-1');
    });

    test('updates an existing account', () async {
      db = await AppDatabase.getInstance();

      db.insertAccount({
        'id': 'update-test',
        'encrypted_data': 'original',
        'nonce': 'n',
        'salt': 's',
        'auth_tag': 't',
        'issuer': 'Original',
        'account_label': 'a@a.com',
        'algorithm': 'SHA1',
        'digits': 6,
        'period': 30,
        'version': 1,
        'sort_order': 0,
        'shortcut_key': null,
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-01T00:00:00Z',
        'deleted_at': null,
      });

      db.updateAccount({
        'id': 'update-test',
        'encrypted_data': 'updated',
        'nonce': 'n',
        'salt': 's',
        'auth_tag': 't',
        'issuer': 'Updated',
        'account_label': 'a@a.com',
        'algorithm': 'SHA256',
        'digits': 8,
        'period': 60,
        'version': 2,
        'sort_order': 0,
        'shortcut_key': null,
        'created_at': '2025-01-01T00:00:00Z',
        'updated_at': '2025-01-02T00:00:00Z',
        'deleted_at': null,
      });

      final result = db.getAccount('update-test');
      expect(result!['issuer'], 'Updated');
      expect(result['version'], 2);
    });

    test('account count returns correct number', () async {
      db = await AppDatabase.getInstance();
      expect(db.accountCount(), 0);

      for (int i = 1; i <= 5; i++) {
        db.insertAccount({
          'id': 'count-$i',
          'encrypted_data': 'e$i',
          'nonce': 'n$i',
          'salt': 's$i',
          'auth_tag': 't$i',
          'issuer': 'Count $i',
          'account_label': 'a@a.com',
          'algorithm': 'SHA1',
          'digits': 6,
          'period': 30,
          'version': 1,
          'sort_order': 0,
          'shortcut_key': null,
          'created_at': '2025-01-01T00:00:00Z',
          'updated_at': '2025-01-01T00:00:00Z',
          'deleted_at': null,
        });
      }

      expect(db.accountCount(), 5);
    });

    test('sync queue operations', () async {
      db = await AppDatabase.getInstance();

      db.addToQueue({
        'record_id': 'sync-1',
        'action': 'create',
        'encrypted_data': 'data1',
        'nonce': 'n1',
        'salt': 's1',
        'auth_tag': 't1',
        'expected_version': 0,
        'created_at': '2025-01-01T00:00:00Z',
        'retry_count': 0,
      });

      db.addToQueue({
        'record_id': 'sync-2',
        'action': 'update',
        'encrypted_data': 'data2',
        'nonce': 'n2',
        'salt': 's2',
        'auth_tag': 't2',
        'expected_version': 1,
        'created_at': '2025-01-01T00:00:00Z',
        'retry_count': 0,
      });

      var queued = db.getQueuedItems();
      expect(queued.length, 2);
      expect(queued[0]['record_id'], 'sync-1');

      db.clearQueuedForRecord('sync-1', 0);
      queued = db.getQueuedItems();
      expect(queued.length, 1);
      expect(queued[0]['record_id'], 'sync-2');

      db.clearQueue();
      queued = db.getQueuedItems();
      expect(queued, isEmpty);
    });

    test('settings get and set', () async {
      db = await AppDatabase.getInstance();

      expect(db.getSetting('nonexistent'), isNull);

      db.setSetting('theme', 'dark');
      db.setSetting('version', '2');

      expect(db.getSetting('theme'), 'dark');
      expect(db.getSetting('version'), '2');
    });

    test('execute raw SQL', () async {
      db = await AppDatabase.getInstance();

      db.execute('INSERT INTO app_settings (key, value) VALUES (?, ?)', [
        'custom_key',
        'custom_value',
      ]);

      expect(db.getSetting('custom_key'), 'custom_value');
    });
  });
}
