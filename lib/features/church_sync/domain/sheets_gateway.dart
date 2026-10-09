import 'sheet_row.dart';

/// Reads and writes the church spreadsheet.
abstract class SheetsGateway {
  /// Signed-in Google account email, or null if signed out.
  Future<String?> currentEmail();

  Future<String> signIn();

  Future<void> signOut();

  /// Creates a workbook titled [title] with Prayers and Verses tabs.
  Future<String> createChurchSpreadsheet({String title = 'Selah Church Prayers'});

  Future<List<SheetPrayerRow>> readPrayers(String spreadsheetId);

  Future<List<SheetVerseRow>> readVerses(String spreadsheetId);

  /// Replaces the Prayers tab with [rows] (full rewrite after merge).
  Future<void> writePrayers(String spreadsheetId, List<SheetPrayerRow> rows);

  /// Upserts verse rows by id (merges with existing).
  Future<void> writeVerses(String spreadsheetId, List<SheetVerseRow> rows);
}

/// Thrown when Google APIs are unavailable or the user cancels sign-in.
class SheetsGatewayException implements Exception {
  SheetsGatewayException(this.message);
  final String message;

  @override
  String toString() => message;
}
