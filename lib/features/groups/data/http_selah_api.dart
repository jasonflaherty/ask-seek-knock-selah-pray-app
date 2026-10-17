import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../app/app_config.dart';
import '../domain/group_models.dart';
import '../domain/selah_api.dart';

class HttpSelahApi implements SelahApi {
  HttpSelahApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = (baseUrl ?? AppConfig.selahApiBaseUrl).replaceAll(
          RegExp(r'/+$'),
          '',
        );

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String path, {
    String? token,
    Object? body,
    Map<String, String>? query,
  }) async {
    if (_baseUrl.isEmpty) {
      throw SelahApiException(
        'Selah sync is not configured. Build with SELAH_API_BASE_URL.',
      );
    }
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    final uri = _uri(path, query);
    late http.Response res;
    switch (method) {
      case 'GET':
        res = await _client.get(uri, headers: headers);
      case 'POST':
        res = await _client.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      case 'PUT':
        res = await _client.put(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      case 'PATCH':
        res = await _client.patch(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      case 'DELETE':
        res = await _client.delete(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      default:
        throw SelahApiException('Unsupported method $method');
    }
    Map<String, dynamic> data = {};
    if (res.body.isNotEmpty) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    }
    if (res.statusCode >= 400) {
      throw SelahApiException(
        data['error'] as String? ?? 'Request failed (${res.statusCode})',
        statusCode: res.statusCode,
      );
    }
    return data;
  }

  AuthSession _session(Map<String, dynamic> data, {String? token}) {
    final user = SelahUser.fromJson(data['user'] as Map<String, dynamic>);
    final list = data['memberships'];
    List<GroupMembership> memberships = const [];
    if (list is List) {
      memberships = list
          .whereType<Map>()
          .map((e) => GroupMembership.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      final single = data['membership'];
      if (single is Map<String, dynamic>) {
        memberships = [GroupMembership.fromJson(single)];
      }
    }
    final t = token ?? data['token'] as String? ?? '';
    return AuthSession(token: t, user: user, memberships: memberships);
  }

  @override
  Future<void> requestCode(String email) async {
    await _json('POST', '/api/auth/request-code', body: {'email': email});
  }

  @override
  Future<AuthSession> verifyCode(String email, String code) async {
    final data = await _json(
      'POST',
      '/api/auth/verify-code',
      body: {'email': email, 'code': code},
    );
    return _session(data);
  }

  @override
  Future<void> signOut(String token) async {
    await _json('POST', '/api/auth/sign-out', token: token);
  }

  @override
  Future<AuthSession> me(String token) async {
    final data = await _json('GET', '/api/me', token: token);
    return _session(data, token: token);
  }

  @override
  Future<AuthSession> setDisplayName(String token, String displayName) async {
    final data = await _json(
      'PATCH',
      '/api/me',
      token: token,
      body: {'displayName': displayName},
    );
    return _session(data, token: token);
  }

  @override
  Future<AuthSession> createGroup(
    String token, {
    required String churchName,
    required String groupName,
  }) async {
    final data = await _json(
      'POST',
      '/api/groups',
      token: token,
      body: {'churchName': churchName, 'groupName': groupName},
    );
    return _session(data, token: token);
  }

  @override
  Future<({AuthSession session, JoinRequestSummary? request})> requestJoin(
    String token,
    String inviteCode,
  ) async {
    final data = await _json(
      'POST',
      '/api/groups/join',
      token: token,
      body: {'inviteCode': inviteCode},
    );
    final session = _session(data, token: token);
    JoinRequestSummary? request;
    final jr = data['joinRequest'];
    if (jr is Map<String, dynamic>) {
      request = JoinRequestSummary(
        id: jr['id'] as String? ?? '',
        groupId: jr['groupId'] as String? ?? '',
        groupName: jr['groupName'] as String? ?? '',
        status: jr['status'] as String? ?? 'pending',
      );
    }
    return (session: session, request: request);
  }

  @override
  Future<AuthSession> leaveGroup(String token, String groupId) async {
    final data = await _json(
      'POST',
      '/api/groups/leave',
      token: token,
      body: {'groupId': groupId},
    );
    return _session(data, token: token);
  }

  @override
  Future<AuthSession> deleteGroup(String token, String groupId) async {
    final data = await _json(
      'DELETE',
      '/api/groups',
      token: token,
      body: {'groupId': groupId},
      query: {'groupId': groupId},
    );
    return _session(data, token: token);
  }

  @override
  Future<List<JoinRequestSummary>> listIncomingJoinRequests(
    String token,
  ) async {
    final data = await _json('GET', '/api/join-requests', token: token);
    return (data['incoming'] as List? ?? [])
        .whereType<Map>()
        .map((e) => JoinRequestSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<JoinRequestSummary>> listMyJoinRequests(String token) async {
    final data = await _json('GET', '/api/join-requests', token: token);
    return (data['mine'] as List? ?? [])
        .whereType<Map>()
        .map((e) => JoinRequestSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> allowJoinRequest(String token, String requestId) async {
    await _json(
      'POST',
      '/api/join-requests/$requestId/allow',
      token: token,
    );
  }

  @override
  Future<void> denyJoinRequest(String token, String requestId) async {
    await _json(
      'POST',
      '/api/join-requests/$requestId/deny',
      token: token,
    );
  }

  @override
  Future<void> sendEmailInvite(
    String token, {
    required String groupId,
    required String email,
  }) async {
    await _json(
      'POST',
      '/api/groups/$groupId/email-invites',
      token: token,
      body: {'email': email},
    );
  }

  @override
  Future<List<EmailInviteSummary>> listEmailInvites(
    String token,
    String groupId,
  ) async {
    final data = await _json(
      'GET',
      '/api/groups/$groupId/email-invites',
      token: token,
    );
    return (data['invites'] as List? ?? [])
        .whereType<Map>()
        .map((e) => EmailInviteSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<GroupMember>> listMembers(String token, String groupId) async {
    final data = await _json(
      'GET',
      '/api/groups/$groupId/members',
      token: token,
    );
    return (data['members'] as List? ?? [])
        .whereType<Map>()
        .map((e) => GroupMember.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> removeMember(
    String token, {
    required String groupId,
    required String userId,
  }) async {
    await _json(
      'DELETE',
      '/api/groups/$groupId/members/$userId',
      token: token,
    );
  }

  @override
  Future<({List<RemoteSharedPrayer> prayers, List<RemoteTombstone> tombstones})>
      pullPrayers(String token) async {
    final data = await _json('GET', '/api/prayers', token: token);
    final prayers = (data['prayers'] as List? ?? [])
        .whereType<Map>()
        .map((e) => RemoteSharedPrayer.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final tombstones = (data['tombstones'] as List? ?? [])
        .whereType<Map>()
        .map((e) => RemoteTombstone.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (prayers: prayers, tombstones: tombstones);
  }

  @override
  Future<RemoteSharedPrayer> pushPrayer(
    String token,
    Map<String, dynamic> body,
  ) async {
    final syncId = body['syncId'] as String;
    final data = await _json(
      'PUT',
      '/api/prayers/$syncId',
      token: token,
      body: body,
    );
    return RemoteSharedPrayer.fromJson(
      data['prayer'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deletePrayer(String token, String syncId) async {
    await _json('DELETE', '/api/prayers/$syncId', token: token);
  }

  @override
  Future<List<StudyNote>> listNotes(String token, {String? groupId}) async {
    final data = await _json(
      'GET',
      '/api/notes',
      token: token,
      query: groupId == null ? null : {'groupId': groupId},
    );
    return (data['notes'] as List? ?? [])
        .whereType<Map>()
        .map((e) => StudyNote.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<StudyNote> upsertNote(
    String token, {
    String? id,
    required String kind,
    required String body,
    String? groupId,
  }) async {
    final data = await _json(
      'POST',
      '/api/notes',
      token: token,
      body: {
        if (id != null) 'id': id,
        'kind': kind,
        'body': body,
        if (groupId != null) 'groupId': groupId,
      },
    );
    return StudyNote.fromJson(data['note'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteNote(String token, String id) async {
    await _json('DELETE', '/api/notes/$id', token: token);
  }
}
