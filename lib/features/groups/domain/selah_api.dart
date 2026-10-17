import 'group_models.dart';

class SelahApiException implements Exception {
  SelahApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// HTTPS API for email sign-in, groups, shared prayers, and notes.
abstract class SelahApi {
  Future<void> requestCode(String email);
  Future<AuthSession> verifyCode(String email, String code);
  Future<void> signOut(String token);
  Future<AuthSession> me(String token);
  Future<AuthSession> setDisplayName(String token, String displayName);
  Future<AuthSession> createGroup(
    String token, {
    required String churchName,
    required String groupName,
  });

  /// Asks to join; does not create membership until the owner allows.
  Future<({AuthSession session, JoinRequestSummary? request})> requestJoin(
    String token,
    String inviteCode,
  );
  Future<AuthSession> leaveGroup(String token, String groupId);
  Future<AuthSession> deleteGroup(String token, String groupId);

  Future<List<JoinRequestSummary>> listIncomingJoinRequests(String token);
  Future<List<JoinRequestSummary>> listMyJoinRequests(String token);
  Future<void> allowJoinRequest(String token, String requestId);
  Future<void> denyJoinRequest(String token, String requestId);

  Future<List<GroupMember>> listMembers(String token, String groupId);
  Future<void> removeMember(
    String token, {
    required String groupId,
    required String userId,
  });

  Future<({List<RemoteSharedPrayer> prayers, List<RemoteTombstone> tombstones})>
      pullPrayers(String token);
  Future<RemoteSharedPrayer> pushPrayer(
    String token,
    Map<String, dynamic> body,
  );
  Future<void> deletePrayer(String token, String syncId);

  Future<List<StudyNote>> listNotes(String token, {String? groupId});
  Future<StudyNote> upsertNote(
    String token, {
    String? id,
    required String kind,
    required String body,
    String? groupId,
  });
  Future<void> deleteNote(String token, String id);
}
