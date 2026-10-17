class SelahUser {
  const SelahUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;

  bool get hasDisplayName => displayName.trim().isNotEmpty;

  factory SelahUser.fromJson(Map<String, dynamic> json) {
    return SelahUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
    );
  }
}

class GroupMembership {
  const GroupMembership({
    required this.role,
    required this.groupId,
    required this.groupName,
    required this.inviteCode,
    required this.churchId,
    required this.churchName,
  });

  final String role;
  final String groupId;
  final String groupName;
  final String inviteCode;
  final String churchId;
  final String churchName;

  bool get isOwner => role == 'owner';

  factory GroupMembership.fromJson(Map<String, dynamic> json) {
    return GroupMembership(
      role: json['role'] as String? ?? 'member',
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String? ?? '',
      inviteCode: json['inviteCode'] as String? ?? '',
      churchId: json['churchId'] as String,
      churchName: json['churchName'] as String? ?? '',
    );
  }
}

class JoinRequestSummary {
  const JoinRequestSummary({
    required this.id,
    required this.groupId,
    required this.groupName,
    this.churchName = '',
    this.userId = '',
    this.email = '',
    this.displayName = '',
    this.status = 'pending',
  });

  final String id;
  final String groupId;
  final String groupName;
  final String churchName;
  final String userId;
  final String email;
  final String displayName;
  final String status;

  factory JoinRequestSummary.fromJson(Map<String, dynamic> json) {
    return JoinRequestSummary(
      id: json['id'] as String,
      groupId: json['groupId'] as String? ?? '',
      groupName: json['groupName'] as String? ?? '',
      churchName: json['churchName'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class GroupMember {
  const GroupMember({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String userId;
  final String email;
  final String displayName;
  final String role;

  bool get isOwner => role == 'owner';

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
    this.memberships = const [],
  });

  final String token;
  final SelahUser user;
  final List<GroupMembership> memberships;

  bool get hasGroup => memberships.isNotEmpty;

  /// First membership, for callers that only need "any group".
  GroupMembership? get membership =>
      memberships.isEmpty ? null : memberships.first;

  GroupMembership? membershipFor(String groupId) {
    for (final m in memberships) {
      if (m.groupId == groupId) return m;
    }
    return null;
  }

  AuthSession copyWith({
    String? token,
    SelahUser? user,
    List<GroupMembership>? memberships,
  }) {
    return AuthSession(
      token: token ?? this.token,
      user: user ?? this.user,
      memberships: memberships ?? this.memberships,
    );
  }
}

class RemoteSharedPrayer {
  const RemoteSharedPrayer({
    required this.syncId,
    required this.shareScope,
    required this.churchId,
    this.groupId,
    required this.name,
    required this.person,
    required this.request,
    required this.isAnswered,
    this.answeredAt,
    this.answeredNote,
    required this.tags,
    required this.verseIds,
    required this.customVerses,
    required this.authorUserId,
    required this.authorDisplayName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String syncId;
  final String shareScope;
  final String churchId;
  final String? groupId;
  final String name;
  final String person;
  final String request;
  final bool isAnswered;
  final DateTime? answeredAt;
  final String? answeredNote;
  final List<String> tags;
  final List<String> verseIds;
  final List<Map<String, dynamic>> customVerses;
  final String authorUserId;
  final String authorDisplayName;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RemoteSharedPrayer.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return RemoteSharedPrayer(
      syncId: json['syncId'] as String,
      shareScope: json['shareScope'] as String? ?? 'church',
      churchId: json['churchId'] as String? ?? '',
      groupId: json['groupId'] as String?,
      name: json['name'] as String? ?? '',
      person: json['person'] as String? ?? '',
      request: json['request'] as String? ?? '',
      isAnswered: json['isAnswered'] as bool? ?? false,
      answeredAt: parse(json['answeredAt']),
      answeredNote: json['answeredNote'] as String?,
      tags: (json['tags'] as List?)?.map((e) => '$e').toList() ?? const [],
      verseIds:
          (json['verseIds'] as List?)?.map((e) => '$e').toList() ?? const [],
      customVerses: (json['customVerses'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const [],
      authorUserId: json['authorUserId'] as String? ?? '',
      authorDisplayName: json['authorDisplayName'] as String? ?? '',
      createdAt: parse(json['createdAt']) ?? DateTime.now(),
      updatedAt: parse(json['updatedAt']) ?? DateTime.now(),
    );
  }
}

class RemoteTombstone {
  const RemoteTombstone({
    required this.syncId,
    required this.deletedAt,
  });

  final String syncId;
  final DateTime deletedAt;

  factory RemoteTombstone.fromJson(Map<String, dynamic> json) {
    return RemoteTombstone(
      syncId: json['syncId'] as String,
      deletedAt: DateTime.tryParse('${json['deletedAt']}') ?? DateTime.now(),
    );
  }
}

class StudyNote {
  const StudyNote({
    required this.id,
    required this.kind,
    required this.body,
    required this.authorUserId,
    required this.authorDisplayName,
    required this.createdAt,
    required this.updatedAt,
    this.groupId = '',
  });

  final String id;
  final String kind;
  final String body;
  final String authorUserId;
  final String authorDisplayName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String groupId;

  bool get isCurrentStudy => kind == 'current_study';

  factory StudyNote.fromJson(Map<String, dynamic> json) {
    DateTime? parse(Object? v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return StudyNote(
      id: json['id'] as String,
      kind: json['kind'] as String? ?? 'other',
      body: json['body'] as String? ?? '',
      authorUserId: json['authorUserId'] as String? ?? '',
      authorDisplayName: json['authorDisplayName'] as String? ?? '',
      createdAt: parse(json['createdAt']) ?? DateTime.now(),
      updatedAt: parse(json['updatedAt']) ?? DateTime.now(),
      groupId: json['groupId'] as String? ?? '',
    );
  }
}
