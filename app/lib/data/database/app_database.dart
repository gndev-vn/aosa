import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class AppDatabase {
  static AppDatabase? _instance;
  late final Database _db;

  AppDatabase._();

  static Future<AppDatabase> getInstance() async {
    if (_instance != null) return _instance!;
    _instance = AppDatabase._();
    await _instance!._open();
    return _instance!;
  }

  Future<void> _open() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final path = p.join(dbFolder.path, 'aosa.db');
    _db = sqlite3.open(path);
    _createTables();
  }

  void _createTables() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS otp_accounts (
        id TEXT PRIMARY KEY,
        encrypted_data TEXT NOT NULL,
        nonce TEXT NOT NULL,
        salt TEXT NOT NULL,
        auth_tag TEXT NOT NULL,
        issuer TEXT NOT NULL,
        account_label TEXT NOT NULL,
        algorithm TEXT NOT NULL DEFAULT 'SHA1',
        digits INTEGER NOT NULL DEFAULT 6,
        period INTEGER NOT NULL DEFAULT 30,
        version INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        shortcut_key TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        encrypted_data TEXT NOT NULL,
        nonce TEXT NOT NULL,
        salt TEXT NOT NULL,
        auth_tag TEXT NOT NULL,
        expected_version INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // === OTP Accounts ===

  List<Map<String, dynamic>> getAllAccounts() {
    return _db.select('''
      SELECT * FROM otp_accounts WHERE deleted_at IS NULL ORDER BY sort_order ASC, created_at DESC
    ''').map(_rowToMap).toList();
  }

  Map<String, dynamic>? getAccount(String id) {
    final results = _db.select('SELECT * FROM otp_accounts WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return _rowToMap(results.first);
  }

  void insertAccount(Map<String, dynamic> data) {
    _db.execute('''
      INSERT INTO otp_accounts
        (id, encrypted_data, nonce, salt, auth_tag, issuer, account_label,
         algorithm, digits, period, version, sort_order, shortcut_key,
         created_at, updated_at, deleted_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      data['id'],
      data['encrypted_data'],
      data['nonce'],
      data['salt'],
      data['auth_tag'],
      data['issuer'],
      data['account_label'],
      data['algorithm'],
      data['digits'],
      data['period'],
      data['version'],
      data['sort_order'],
      data['shortcut_key'],
      data['created_at'],
      data['updated_at'],
      data['deleted_at'],
    ]);
  }

  void updateAccount(Map<String, dynamic> data) {
    _db.execute('''
      UPDATE otp_accounts SET
        encrypted_data = ?, nonce = ?, salt = ?, auth_tag = ?,
        issuer = ?, account_label = ?, algorithm = ?, digits = ?,
        period = ?, version = ?, sort_order = ?, shortcut_key = ?,
        created_at = ?, updated_at = ?, deleted_at = ?
      WHERE id = ?
    ''', [
      data['encrypted_data'],
      data['nonce'],
      data['salt'],
      data['auth_tag'],
      data['issuer'],
      data['account_label'],
      data['algorithm'],
      data['digits'],
      data['period'],
      data['version'],
      data['sort_order'],
      data['shortcut_key'],
      data['created_at'],
      data['updated_at'],
      data['deleted_at'],
      data['id'],
    ]);
  }

  void deleteAccount(String id) {
    _db.execute('DELETE FROM otp_accounts WHERE id = ?', [id]);
  }

  int accountCount() {
    final row = _db.select(
      'SELECT COUNT(*) AS count FROM otp_accounts WHERE deleted_at IS NULL',
    ).first;
    return row['count'] as int;
  }

  // === Settings ===

  String? getSetting(String key) {
    final rows = _db.select(
      'SELECT value FROM app_settings WHERE key = ?',
      [key],
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  void setSetting(String key, String value) {
    _db.execute(
      'INSERT OR REPLACE INTO app_settings (key, value) VALUES (?, ?)',
      [key, value],
    );
  }

  // === Sync Queue ===

  int addToQueue(Map<String, dynamic> data) {
    _db.execute('''
      INSERT INTO sync_queue
        (record_id, action, encrypted_data, nonce, salt, auth_tag,
         expected_version, created_at, retry_count)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      data['record_id'],
      data['action'],
      data['encrypted_data'],
      data['nonce'],
      data['salt'],
      data['auth_tag'],
      data['expected_version'],
      data['created_at'],
      data['retry_count'],
    ]);
    return _db.lastInsertRowId;
  }

  List<Map<String, dynamic>> getQueuedItems() {
    return _db.select(
      'SELECT * FROM sync_queue ORDER BY created_at ASC',
    ).map(_rowToMap).toList();
  }

  void clearQueue() {
    _db.execute('DELETE FROM sync_queue');
  }

  void clearQueuedForRecord(String recordId, int version) {
    _db.execute(
      'DELETE FROM sync_queue WHERE record_id = ? AND expected_version = ?',
      [recordId, version],
    );
  }

  void execute(String sql, List<Object?> params) {
    _db.execute(sql, params);
  }

  void dispose() {
    _db.dispose();
    _instance = null;
  }

  Map<String, dynamic> _rowToMap(Row row) {
    return {
      for (final col in row.keys)
        col: row[col],
    } as Map<String, dynamic>;
  }
}
