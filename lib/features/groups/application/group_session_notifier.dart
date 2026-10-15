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
  });

  final AuthSession? session;
  final bool loading;
  final String? error;
  final bool pendingChurchUploadConfirm;

  bool get isSignedIn => session != null;
  bool get hasGroup => session?.membership != null;

  GroupSessionState copyWith({
    AuthSession? session,
    bool? loading,
    String? error,
    bool clearError = false,
    bool clearSession = false,
    bool? pendingChurchUploadConfirm,
  }) {
    return GroupSessionState(
      session: clearSession ? null : (session ?? this.session),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      pendingChurchUploadConfirm:
          pendingChurchUploadConfirm ?? this.pendingChurchUploadConfirm,
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

  final SelahApi _api;
  final SharedPreferences _prefs;
  final GroupSyncService _sync;

  Future<void> _restore() async {
    final token = _prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final session = await _api.me(token);
      final confirmed = _prefs.getBool(_churchUploadKey) ?? false;
      state = state.copyWith(
        session: session,
        loading: false,
        pendingChurchUploadConfirm: session.membership != null && !confirmed,
      );
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
      final confirmed = _prefs.getBool(_churchUploadKey) ?? false;
      state = state.copyWith(
        session: session,
        loading: false,
        pendingChurchUploadConfirm: session.membership != null && !confirmed,
      );
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
    state = state.copyWith(clearSession: true, pendingChurchUploadConfirm: false);
  }

  Future<void> setDisplayName(String name) async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final next = await _api.setDisplayName(session.token, name);
      state = state.copyWith(session: next, loading: false);
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
      state = state.copyWith(
        session: next,
        loading: false,
        pendingChurchUploadConfirm: true,
      );
      await _sync.syncNow(next);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> joinGroup(String inviteCode) async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final next = await _api.joinGroup(session.token, inviteCode);
      await _prefs.setBool(_churchUploadKey, false);
      state = state.copyWith(
        session: next,
        loading: false,
        pendingChurchUploadConfirm: true,
      );
      await _sync.syncNow(next);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> leaveGroup() async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final next = await _api.leaveGroup(session.token);
      await _prefs.remove(_churchUploadKey);
      state = state.copyWith(
        session: next,
        loading: false,
        pendingChurchUploadConfirm: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> deleteGroup() async {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final next = await _api.deleteGroup(session.token);
      await _prefs.remove(_churchUploadKey);
      state = state.copyWith(
        session: next,
        loading: false,
        pendingChurchUploadConfirm: false,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }

  Future<void> confirmChurchUpload() async {
    final session = state.session;
    if (session == null || session.membership == null) return;
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
      await _sync.syncNow(session);
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
      rethrow;
    }
  }
}
