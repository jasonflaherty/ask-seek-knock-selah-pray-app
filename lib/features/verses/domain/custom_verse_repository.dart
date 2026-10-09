import 'verse.dart';

abstract class CustomVerseRepository {
  Future<Verse> addCustom({
    required String ref,
    required String text,
    String? note,
  });

  Future<Verse?> getById(String id);

  Future<List<Verse>> getByIds(List<String> ids);

  Stream<List<Verse>> watchAll();
}
