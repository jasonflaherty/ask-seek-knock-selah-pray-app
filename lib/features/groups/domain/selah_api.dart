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
  Future<AuthSession> joinGroup(String token, String inviteCode);
  Future<AuthSession> leaveGroup(String token);
  Future<AuthSession> deleteGroup(String token);

  Future<({List<RemoteSharedPrayer> prayers, List<RemoteTombstone> tombstones})>
      pullPrayers(String token);
  Future<RemoteSharedPrayer> pushPrayer(
    String token,
    Map<String, dynamic> body,
  );
  Future<void> deletePrayer(String token, String syncId);

  Future<List<StudyNote>> listNotes(String token);
  Future<StudyNote> upsertNote(
    String token, {
    String? id,
    required String kind,
    required String body,
  });
  Future<void> deleteNote(String token, String id);
}
