/// One church prayer as represented on the spreadsheet.
class SheetPrayerRow {
  const SheetPrayerRow({
    required this.syncId,
    required this.authorEmail,
    required this.name,
    this.person = '',
    required this.request,
    this.tags = const [],
    this.verseIds = const [],
    this.isAnswered = false,
    this.answeredNote,
    required this.updatedAt,
    this.deleted = false,
  });

  final String syncId;
  final String authorEmail;
  final String name;
  final String person;
  final String request;
  final List<String> tags;
  final List<String> verseIds;
  final bool isAnswered;
  final String? answeredNote;
  final DateTime updatedAt;
  final bool deleted;

  /// Fingerprint of content fields used for three-way merge.
  String fingerprint() {
    final tagsJoined = tags.join('|');
    final versesJoined = verseIds.join('|');
    return [
      syncId,
      authorEmail,
      name,
      person,
      request,
      tagsJoined,
      versesJoined,
      isAnswered ? '1' : '0',
      answeredNote ?? '',
      updatedAt.toUtc().toIso8601String(),
      deleted ? '1' : '0',
    ].join('\u001f');
  }

  SheetPrayerRow copyWith({
    String? syncId,
    String? authorEmail,
    String? name,
    String? person,
    String? request,
    List<String>? tags,
    List<String>? verseIds,
    bool? isAnswered,
    String? answeredNote,
    DateTime? updatedAt,
    bool? deleted,
    bool clearAnsweredNote = false,
  }) {
    return SheetPrayerRow(
      syncId: syncId ?? this.syncId,
      authorEmail: authorEmail ?? this.authorEmail,
      name: name ?? this.name,
      person: person ?? this.person,
      request: request ?? this.request,
      tags: tags ?? this.tags,
      verseIds: verseIds ?? this.verseIds,
      isAnswered: isAnswered ?? this.isAnswered,
      answeredNote:
          clearAnsweredNote ? null : (answeredNote ?? this.answeredNote),
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }
}

/// Custom Scripture row for the Verses sheet tab.
class SheetVerseRow {
  const SheetVerseRow({
    required this.id,
    required this.ref,
    required this.text,
    this.note,
  });

  final String id;
  final String ref;
  final String text;
  final String? note;
}

/// Local tombstone waiting to be pushed.
class PendingTombstone {
  const PendingTombstone({required this.syncId, required this.deletedAt});

  final String syncId;
  final DateTime deletedAt;
}
