class TextNormalizer {
  TextNormalizer(this.synonyms);

  final Map<String, List<String>> synonyms;

  static const stopwords = {
    'a', 'an', 'the', 'and', 'or', 'but', 'if', 'in', 'on', 'at', 'to', 'for',
    'of', 'is', 'are', 'was', 'were', 'be', 'been', 'am', 'i', 'me', 'my', 'we',
    'our', 'you', 'your', 'he', 'she', 'it', 'they', 'them', 'their', 'this',
    'that', 'with', 'from', 'as', 'by', 'so', 'not', 'no', 'do', 'does', 'did',
    'have', 'has', 'had', 'will', 'would', 'can', 'could', 'should', 'about',
    'into', 'out', 'up', 'down', 'over', 'under', 'again', 'further', 'then',
    'once', 'here', 'there', 'when', 'where', 'why', 'how', 'all', 'each',
    'few', 'more', 'most', 'other', 'some', 'such', 'than', 'too', 'very',
    'just', 'also', 'im', "i'm", 'dont', "don't", 'please', 'pray', 'prayer',
    'need', 'needs', 'help',
  };

  /// Returns map of stem -> weight (1.0 literal, 0.6 synonym expansion).
  Map<String, double> tokenize(String input) {
    final lower = input.toLowerCase().replaceAll(RegExp(r"[^\w\s'-]"), ' ');
    final raw = lower.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    final weights = <String, double>{};

    void add(String token, double weight) {
      final stem = stemToken(token);
      if (stem.isEmpty || stopwords.contains(stem)) return;
      weights[stem] = (weights[stem] ?? 0) + weight;
    }

    for (final token in raw) {
      add(token, 1.0);
      final stem = stemToken(token);
      final expanded = synonyms[token] ??
          synonyms[stem] ??
          synonyms.entries
              .where((e) => stemToken(e.key) == stem)
              .map((e) => e.value)
              .firstOrNull;
      if (expanded != null) {
        for (final syn in expanded) {
          add(syn, 0.6);
        }
      }
    }
    return weights;
  }

  /// Light stemmer: strip trailing s / ed / ing / ly.
  static String stemToken(String token) {
    var t = token.toLowerCase();
    if (t.length <= 3) return t;
    if (t.endsWith('ing') && t.length > 5) {
      t = t.substring(0, t.length - 3);
    } else if (t.endsWith('ed') && t.length > 4) {
      t = t.substring(0, t.length - 2);
    } else if (t.endsWith('ly') && t.length > 4) {
      t = t.substring(0, t.length - 2);
    } else if (t.endsWith('s') && !t.endsWith('ss') && t.length > 3) {
      t = t.substring(0, t.length - 1);
    }
    return t;
  }
}
