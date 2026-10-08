/// Immutable prayer entity. Fields `timesViewed` and `lastPrayedAt` are
/// derived from `prayer_events` in the repository — not stored columns.
class Prayer {
  const Prayer({
    required this.id,
    required this.name,
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
  });

  final int id;
  final String name;
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

  Prayer copyWith({
    int? id,
    String? name,
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
    bool clearAnsweredAt = false,
    bool clearAnsweredNote = false,
    bool clearLastPrayedAt = false,
  }) {
    return Prayer(
      id: id ?? this.id,
      name: name ?? this.name,
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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Prayer &&
          other.id == id &&
          other.name == name &&
          other.request == request &&
          other.isAnswered == isAnswered &&
          other.answeredAt == answeredAt &&
          other.answeredNote == answeredNote &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          _listEq(other.tags, tags) &&
          _listEq(other.verseIds, verseIds) &&
          other.timesViewed == timesViewed &&
          other.lastPrayedAt == lastPrayedAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
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
      );
}

class NewPrayer {
  const NewPrayer({
    required this.name,
    required this.request,
    this.tags = const [],
    this.verseIds = const [],
  });

  final String name;
  final String request;
  final List<String> tags;
  final List<String> verseIds;
}

class PrayerUpdate {
  const PrayerUpdate({
    required this.name,
    required this.request,
    this.tags = const [],
    this.verseIds = const [],
    this.isAnswered,
    this.answeredNote,
  });

  final String name;
  final String request;
  final List<String> tags;
  final List<String> verseIds;
  final bool? isAnswered;
  final String? answeredNote;
}

enum AnswerFilter { active, answered, all }

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
