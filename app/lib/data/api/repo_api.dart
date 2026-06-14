import 'package:dio/dio.dart';

class RepoApi {
  final Dio _dio;

  RepoApi(this._dio);

  Future<List<RepoInfo>> list() async {
    final response = await _dio.get('/api/v1/repos/');
    final data = response.data as List;
    return data
        .map((e) => RepoInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RepoInfo> create(String name) async {
    final response = await _dio.post('/api/v1/repos/', data: {
      'name': name,
    });
    final data = response.data as Map<String, dynamic>;
    return RepoInfo(
      id: data['id'] as String,
      name: data['name'] as String,
      ownerId: '',
      isDefault: false,
      shared: false,
    );
  }

  Future<void> rename(String id, String name) async {
    await _dio.put('/api/v1/repos/$id', data: {'name': name});
  }

  Future<void> delete(String id) async {
    await _dio.delete('/api/v1/repos/$id');
  }

  Future<void> share(String id, String username, String role) async {
    await _dio.post('/api/v1/repos/$id/share', data: {
      'username': username,
      'role': role,
    });
  }

  Future<void> unshare(String repoId, String userId) async {
    await _dio.delete('/api/v1/repos/$repoId/share/$userId');
  }

  Future<List<RepoMember>> members(String id) async {
    final response = await _dio.get('/api/v1/repos/$id/members');
    final data = response.data as List;
    return data
        .map((e) => RepoMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class RepoInfo {
  final String id;
  final String ownerId;
  final String name;
  final bool isDefault;
  final bool shared;

  const RepoInfo({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.isDefault,
    required this.shared,
  });

  factory RepoInfo.fromJson(Map<String, dynamic> json) => RepoInfo(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        name: json['name'] as String,
        isDefault: json['is_default'] as bool,
        shared: json['shared'] as bool,
      );
}

class RepoMember {
  final String userId;
  final String username;
  final String role;
  final DateTime since;

  const RepoMember({
    required this.userId,
    required this.username,
    required this.role,
    required this.since,
  });

  factory RepoMember.fromJson(Map<String, dynamic> json) => RepoMember(
        userId: json['user_id'] as String,
        username: json['username'] as String,
        role: json['role'] as String,
        since: DateTime.parse(json['since'] as String),
      );
}
