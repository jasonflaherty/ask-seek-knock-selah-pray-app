import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../domain/group_models.dart';
import '../domain/selah_api.dart';
import 'group_sync_service.dart';

final groupSessionProvider =
    StateNotifierProvider<GroupSessionNotifier, GroupSessionState>((ref) {
  return GroupSessionNotifier(
    api: ref.watch(selahApiProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    sync: ref.watch(groupSyncServiceProvider),
  );
});

class GroupSessionState {
  const GroupSessionState({
    this.session,
    this.loading = false,
    this.error,
    this.pendingChurchUploadConfirm = false,
    this.myJoinRequests = const [],
    this.incomingJoinRequests = const [],
  });

  final AuthSession? session;
  final bool loading;
  final String? error;
  final bool pendingChurchUploadConfirm;
  final List<JoinRequestSummary> myJoinRequests;
  final List<JoinRequestSummary> incomingJoinRequests;

  bool get isSignedIn => session != null;
  bool get hasGroup => session?.hasGroup ?? false;

  /// Sole membership when the person is in a group.
  GroupMembership? get membership => session?.membership;

  GroupSessionState copyWith({
    AuthSession? session,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearSession = false,
    bool? pendingChurchUploadConfirm,
    List<JoinRequestSummary>? myJoinRequests,
    List<JoinRequestSummary>? incomingJoinRequests,
  }) {
    return GroupSessionState(
      session: clearSession ? null : (session ?? this.session),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      pendingChurchUploadConfirm:
          pendingChurchUploadConfirm ?? this.pendingChurchUploadConfirm,
      myJoinRequests: clearSession
          ? const []
          : (myJoinRequests ?? this.myJoinRequests),
      incomingJoinRequests: clearSession
          ? const []
          : (incomingJoinRequests ?? this.incomingJoinRequests),
    );
  }
}

class GroupSessionNotifier extends StateNotifier<GroupSessionState> {
  GroupSessionNotifier({
    required SelahApi api,
    required SharedPreferences prefs,
    required GroupSyncService sync,
  })  : _api = api,
        _prefs = prefs,
        _sync = sync,
        super(const GroupSessionState()) {
    _restore();
  }

  static const _tokenKey = 'selah_session_token';
  static const _churchUploadKey = 'selah_church_upload_confirmed';
  static const _legacyActiveGroupKey = 'selah_active_group_id';

  final SelahApi _api;
  final SharedPreferences _prefs;
  final GroupSyncService _sync;

  Future<void> _refreshRequests(AuthSession session) async {
    try {
      final incoming = await _api.listIncomingJoinRequests(session.token);
      final mine = await _api.listMyJoinRequests(session.token);
      state = state.copyWith(
        incomingJoinRequests: incoming,
        myJoinRequests: mine,
      );
    } catch (_) {}
  }

  Future<AuthSession> _applySession(
    AuthSession session, {
    bool? pendingChurchUpload,
  }) async {
    final confirmed = _prefs.getBool(_churchUploadKey) ?? false;
    state = state.copyWith(
      session: session,
      loading: false,
      pendingChurchUploadConfirm:
          pendingChurchUpload ?? (session.hasGroup && !confirmed),
    );
    await _refreshRequests(session);
    return session;
  }

  Future<void> _restore() async {
    await _prefs.remove(_legacyActiveGroupKey);
    final token = _prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final session = await _api.me(token);
      await _applySession(session);
      await _sync.syncNow(session);
    } catch (_) {
      await _prefs.remove(_tokenKey);
      state = state.copyWith(clearSession: true, loading: false);
    }
  }

  Future<void> requestCode(String email) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _api.requestCode(email.trim());
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> verifyCode(String email, String code) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final session = await _api.verifyCode(email.trim(), code.trim());
      await _prefs.setString(_tokenKey, session.token);
      await _applySession(session);
      await _sync.syncNow(session);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    final token = state.session?.token;
    if (token != null) {
      try {
        await _api.signOut(token);
      } catch (_) {}
    }
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_legacyActiveGroupKey);
    state = state.copyWith(
      clearSession: true,
      pendingChurchUploadConfirm: false,
    );
  }

  Future<void> setDisplayName(String name) async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final next = await _api.setDisplayName(session.token, name);
      await _applySession(
        next,
        pendingChurchUpload: state.pendingChurchUploadConfirm,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> createGroup({
    required String churchName,
    required String groupName,
  }) async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final next = await _api.createGroup(
        session.token,
        churchName: churchName,
        groupName: groupName,
      );
      await _prefs.setBool(_churchUploadKey, false);
      await _applySession(next, pendingChurchUpload: true);
      await _sync.syncNow(next);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> requestJoin(String inviteCode) async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final result = await _api.requestJoin(session.token, inviteCode);
      await _applySession(
        result.session,
        pendingChurchUpload: state.pendingChurchUploadConfirm,
      );
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> leaveGroup(String groupId) async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final next = await _api.leaveGroup(session.token, groupId);
      if (!next.hasGroup) {
        await _prefs.remove(_churchUploadKey);
      }
      await _applySession(
        next,
        pendingChurchUpload:
            next.hasGroup ? state.pendingChurchUploadConfirm : false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> deleteGroup(String groupId) async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final next = await _api.deleteGroup(session.token, groupId);
      if (!next.hasGroup) {
        await _prefs.remove(_churchUploadKey);
      }
      await _applySession(
        next,
        pendingChurchUpload:
            next.hasGroup ? state.pendingChurchUploadConfirm : false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> allowJoinRequest(String requestId) async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _api.allowJoinRequest(session.token, requestId);
      await _refreshRequests(session);
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> denyJoinRequest(String requestId) async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _api.denyJoinRequest(session.token, requestId);
      await _refreshRequests(session);
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<List<GroupMember>> listMembers(String groupId) async {
    final session = state.session;
    if (session == null) return const [];
    return _api.listMembers(session.token, groupId);
  }

  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    final session = state.session;
    if (session == null) return;
    await _api.removeMember(
      session.token,
      groupId: groupId,
      userId: userId,
    );
  }

  Future<void> confirmChurchUpload() async {
    final session = state.session;
    if (session == null || !session.hasGroup) return;
    await _prefs.setBool(_churchUploadKey, true);
    state = state.copyWith(pendingChurchUploadConfirm: false);
    await _sync.uploadLocalChurchPrayers(session);
  }

  Future<void> declineChurchUpload() async {
    await _prefs.setBool(_churchUploadKey, true);
    state = state.copyWith(pendingChurchUploadConfirm: false);
  }

  Future<void> syncNow() async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final refreshed = await _api.me(session.token);
      await _applySession(
        refreshed,
        pendingChurchUpload: state.pendingChurchUploadConfirm,
      );
      await _sync.syncNow(refreshed);
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }
}
