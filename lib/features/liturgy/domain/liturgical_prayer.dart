class LiturgicalPrayer {
  const LiturgicalPrayer({
    required this.id,
    required this.title,
    required this.text,
    required this.section,
    required this.order,
  });

  final String id;
  final String title;
  final String text;
  final String section;
  final int order;

  factory LiturgicalPrayer.fromJson(Map<String, dynamic> json) {
    return LiturgicalPrayer(
      id: json['id'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      section: json['section'] as String,
      order: json['order'] as int,
    );
  }
}
