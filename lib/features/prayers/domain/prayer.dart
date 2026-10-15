import 'share_scope.dart';

/// Immutable prayer entity. Fields `timesViewed` and `lastPrayedAt` are
/// derived from `prayer_events` in the repository — not stored columns.
///
/// Prayers are private by default (device-local). Group and Church scopes
/// sync only after the person joins a group and confirms upload.
class Prayer {
  const Prayer({
    required this.id,
    required this.name,
    this.person = '',
    required this.request,
    required this.isAnswered,
    this.answeredAt,
    this.answeredNote,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.verseIds = const [],
    this.timesViewed = 0,
    this.lastPrayedAt,
    this.syncId,
    this.shareScope = ShareScope.justMe,
    this.groupId,
    this.churchId,
    this.authorEmail = '',
    this.authorDisplayName = '',
  });

  final int id;
  final String name;

  /// Who this prayer is for (optional). Empty means unassigned.
  final String person;
  final String request;
  final bool isAnswered;
  final DateTime? answeredAt;
  final String? answeredNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final List<String> verseIds;
  final int timesViewed;
  final DateTime? lastPrayedAt;

  /// Stable id for group/church sync. Null until first share.
  final String? syncId;

  final ShareScope shareScope;
  final String? groupId;
  final String? churchId;

  /// Account email of the author when shared (not shown in lists).
  final String authorEmail;

  /// Short name shown on shared lists.
  final String authorDisplayName;

  bool get hasPerson => person.trim().isNotEmpty;

  bool get shared => shareScope.isShared;

  bool get isChurch => shareScope == ShareScope.church;

  bool get isGroup => shareScope == ShareScope.group;

  Prayer copyWith({
    int? id,
    String? name,
    String? person,
    String? request,
    bool? isAnswered,
    DateTime? answeredAt,
    String? answeredNote,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    List<String>? verseIds,
    int? timesViewed,
    DateTime? lastPrayedAt,
    String? syncId,
    ShareScope? shareScope,
    String? groupId,
    String? churchId,
    String? authorEmail,
    String? authorDisplayName,
    bool clearAnsweredAt = false,
    bool clearAnsweredNote = false,
    bool clearLastPrayedAt = false,
    bool clearSyncId = false,
    bool clearGroupId = false,
    bool clearChurchId = false,
  }) {
    return Prayer(
      id: id ?? this.id,
      name: name ?? this.name,
      person: person ?? this.person,
      request: request ?? this.request,
      isAnswered: isAnswered ?? this.isAnswered,
      answeredAt: clearAnsweredAt ? null : (answeredAt ?? this.answeredAt),
      answeredNote:
          clearAnsweredNote ? null : (answeredNote ?? this.answeredNote),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      verseIds: verseIds ?? this.verseIds,
      timesViewed: timesViewed ?? this.timesViewed,
      lastPrayedAt:
          clearLastPrayedAt ? null : (lastPrayedAt ?? this.lastPrayedAt),
      syncId: clearSyncId ? null : (syncId ?? this.syncId),
      shareScope: shareScope ?? this.shareScope,
      groupId: clearGroupId ? null : (groupId ?? this.groupId),
      churchId: clearChurchId ? null : (churchId ?? this.churchId),
      authorEmail: authorEmail ?? this.authorEmail,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Prayer &&
          other.id == id &&
          other.name == name &&
          other.person == person &&
          other.request == request &&
          other.isAnswered == isAnswered &&
          other.answeredAt == answeredAt &&
          other.answeredNote == answeredNote &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          _listEq(other.tags, tags) &&
          _listEq(other.verseIds, verseIds) &&
          other.timesViewed == timesViewed &&
          other.lastPrayedAt == lastPrayedAt &&
          other.syncId == syncId &&
          other.shareScope == shareScope &&
          other.groupId == groupId &&
          other.churchId == churchId &&
          other.authorEmail == authorEmail &&
          other.authorDisplayName == authorDisplayName;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        person,
        request,
        isAnswered,
        answeredAt,
        answeredNote,
        createdAt,
        updatedAt,
        Object.hashAll(tags),
        Object.hashAll(verseIds),
        timesViewed,
        lastPrayedAt,
        syncId,
        shareScope,
        groupId,
        churchId,
        authorEmail,
        authorDisplayName,
      );
}

class NewPrayer {
  const NewPrayer({
    required this.name,
    this.person = '',
    required this.request,
    this.tags = const [],
    this.verseIds = const [],
    this.shareScope = ShareScope.justMe,
    this.groupId,
    this.churchId,
    this.authorEmail = '',
    this.authorDisplayName = '',
    this.syncId,
  });

  final String name;
  final String person;
  final String request;
  final List<String> tags;
  final List<String> verseIds;
  final ShareScope shareScope;
  final String? groupId;
  final String? churchId;
  final String authorEmail;
  final String authorDisplayName;
  final String? syncId;
}

class PrayerUpdate {
  const PrayerUpdate({
    required this.name,
    this.person = '',
    required this.request,
    this.tags = const [],
    this.verseIds = const [],
    this.isAnswered,
    this.answeredNote,
    this.shareScope,
    this.groupId,
    this.churchId,
    this.authorEmail,
    this.authorDisplayName,
    this.syncId,
  });

  final String name;
  final String person;
  final String request;
  final List<String> tags;
  final List<String> verseIds;
  final bool? isAnswered;
  final String? answeredNote;
  final ShareScope? shareScope;
  final String? groupId;
  final String? churchId;
  final String? authorEmail;
  final String? authorDisplayName;
  final String? syncId;
}

enum AnswerFilter { active, answered, all }

/// Filter prayers by who they are for. [all] shows everyone.
class PersonFilter {
  const PersonFilter._(this.value);

  /// Show all prayers regardless of person.
  static const all = PersonFilter._(null);

  /// Only prayers with no person set.
  static const unassigned = PersonFilter._('');

  /// Only prayers for this person (trimmed, case-sensitive match on stored value).
  factory PersonFilter.named(String name) => PersonFilter._(name.trim());

  final String? value;

  bool get isAll => value == null;
  bool get isUnassigned => value != null && value!.isEmpty;

  bool matches(Prayer prayer) {
    if (isAll) return true;
    if (isUnassigned) return !prayer.hasPerson;
    return prayer.person.trim() == value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PersonFilter && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Normalize person label: trim, collapse spaces; empty if blank.
String normalizePerson(String raw) {
  return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
}

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
