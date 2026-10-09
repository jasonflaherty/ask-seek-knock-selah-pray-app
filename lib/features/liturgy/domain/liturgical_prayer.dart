class LiturgicalPrayer {
  const LiturgicalPrayer({
    required this.id,
    required this.title,
    required this.text,
    required this.section,
    required this.order,
    this.calendarKeys = const [],
  });

  final String id;
  final String title;
  final String text;
  final String section;
  final int order;
  final List<String> calendarKeys;

  factory LiturgicalPrayer.fromJson(Map<String, dynamic> json) {
    final keys = json['calendarKeys'];
    return LiturgicalPrayer(
      id: json['id'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      section: json['section'] as String,
      order: json['order'] as int,
      calendarKeys: keys is List
          ? keys.cast<String>()
          : const <String>[],
    );
  }
}
