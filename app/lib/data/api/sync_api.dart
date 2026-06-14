import 'package:dio/dio.dart';

class SyncApi {
  final Dio _dio;

  SyncApi(this._dio);

  Future<SyncStatusResult> getStatus({required String repoId}) async {
    final response = await _dio.get(
      '/api/v1/sync/status',
      queryParameters: {'repo_id': repoId},
    );
    final data = response.data as Map<String, dynamic>;
    return SyncStatusResult(
      serverVersion: data['server_version'] as int,
    );
  }

  Future<PullResult> pull(
      {required String repoId, required int sinceVersion}) async {
    final response = await _dio.get(
      '/api/v1/sync/pull',
      queryParameters: {'repo_id': repoId, 'since_version': sinceVersion},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => SyncRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    return PullResult(
      items: items,
      serverVersion: data['server_version'] as int,
    );
  }

  Future<PushResult> push(
      {required String repoId, required List<PushChange> changes}) async {
    final response = await _dio.post('/api/v1/sync/push', data: {
      'changes': changes
          .map((c) => {
                'id': c.id,
                'repo_id': repoId,
                'encrypted_blob': c.encryptedBlob,
                'expected_version': c.expectedVersion,
                'client_timestamp': c.clientTimestamp.toIso8601String(),
              })
          .toList(),
    });
    final data = response.data as Map<String, dynamic>;
    return PushResult(
      accepted: (data['accepted'] as List)
          .map((e) => AcceptedResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      conflicts: (data['conflicts'] as List)
          .map((e) => ConflictResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SyncStatusResult {
  final int serverVersion;

  const SyncStatusResult({required this.serverVersion});
}

class SyncRecord {
  final String id;
  final String encryptedBlob;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const SyncRecord({
    required this.id,
    required this.encryptedBlob,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory SyncRecord.fromJson(Map<String, dynamic> json) => SyncRecord(
        id: json['id'] as String,
        encryptedBlob: json['encrypted_blob'] as String,
        version: json['version'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
      );
}

class PullResult {
  final List<SyncRecord> items;
  final int serverVersion;

  const PullResult({required this.items, required this.serverVersion});
}

class PushChange {
  final String id;
  final String encryptedBlob;
  final int expectedVersion;
  final DateTime clientTimestamp;

  const PushChange({
    required this.id,
    required this.encryptedBlob,
    required this.expectedVersion,
    required this.clientTimestamp,
  });
}

class PushResult {
  final List<AcceptedResult> accepted;
  final List<ConflictResult> conflicts;

  const PushResult({required this.accepted, required this.conflicts});
}

class AcceptedResult {
  final String id;
  final int newVersion;

  const AcceptedResult({required this.id, required this.newVersion});

  factory AcceptedResult.fromJson(Map<String, dynamic> json) => AcceptedResult(
        id: json['id'] as String,
        newVersion: json['new_version'] as int,
      );
}

class ConflictResult {
  final String id;
  final int serverVersion;
  final String message;

  const ConflictResult({
    required this.id,
    required this.serverVersion,
    required this.message,
  });

  factory ConflictResult.fromJson(Map<String, dynamic> json) => ConflictResult(
        id: json['id'] as String,
        serverVersion: json['server_version'] as int,
        message: json['message'] as String,
      );
}
