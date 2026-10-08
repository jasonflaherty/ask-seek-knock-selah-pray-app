enum PromiseType {
  explicitPromise,
  answeredPrayer,
  characterOfGod,
}

extension PromiseTypeX on PromiseType {
  String get storageValue => switch (this) {
        PromiseType.explicitPromise => 'explicit_promise',
        PromiseType.answeredPrayer => 'answered_prayer',
        PromiseType.characterOfGod => 'character_of_god',
      };

  String get label => switch (this) {
        PromiseType.explicitPromise => 'Promise',
        PromiseType.answeredPrayer => 'Answered prayer',
        PromiseType.characterOfGod => 'Character of God',
      };

  static PromiseType fromStorage(String value) {
    return switch (value) {
      'explicit_promise' => PromiseType.explicitPromise,
      'answered_prayer' => PromiseType.answeredPrayer,
      _ => PromiseType.characterOfGod,
    };
  }
}

class Verse {
  const Verse({
    required this.id,
    required this.ref,
    required this.text,
    required this.themes,
    required this.keywords,
    required this.promiseType,
    required this.note,
  });

  final String id;
  final String ref;
  final String text;
  final List<String> themes;
  final List<String> keywords;
  final PromiseType promiseType;
  final String note;

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'] as String,
      ref: json['ref'] as String,
      text: json['text'] as String,
      themes: (json['themes'] as List<dynamic>).cast<String>(),
      keywords: (json['keywords'] as List<dynamic>).cast<String>(),
      promiseType: PromiseTypeX.fromStorage(json['promiseType'] as String),
      note: json['note'] as String,
    );
  }
}
