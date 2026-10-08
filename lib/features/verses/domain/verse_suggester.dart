import 'verse.dart';

abstract class VerseSuggester {
  Future<List<Verse>> suggest(String request, {int limit = 6});

  Verse? byId(String id);

  List<Verse> byIds(List<String> ids);
}
