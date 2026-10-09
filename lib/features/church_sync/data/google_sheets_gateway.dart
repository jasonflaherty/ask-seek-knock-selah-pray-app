import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;

import '../domain/sheet_row.dart';
import '../domain/sheets_gateway.dart';
import 'sheet_codec.dart';

const _sheetsScope = 'https://www.googleapis.com/auth/spreadsheets';

/// Compile-time OAuth client ids (not committed). Pass via `--dart-define`.
const _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
const _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

bool get googleSignInConfigured =>
    _iosClientId.isNotEmpty || _serverClientId.isNotEmpty;

class GoogleSheetsGateway implements SheetsGateway {
  GoogleSheetsGateway({GoogleSignIn? signIn})
      : _signIn = signIn ??
            GoogleSignIn(
              scopes: const [_sheetsScope],
              clientId: _iosClientId.isEmpty ? null : _iosClientId,
              serverClientId:
                  _serverClientId.isEmpty ? null : _serverClientId,
            );

  final GoogleSignIn _signIn;
  GoogleSignInAccount? _account;

  void _ensureConfigured() {
    if (!googleSignInConfigured) {
      throw SheetsGatewayException(
        'Google sign-in is not configured. Build with '
        'GOOGLE_IOS_CLIENT_ID and GOOGLE_SERVER_CLIENT_ID dart-defines.',
      );
    }
  }

  Future<sheets.SheetsApi> _sheetsApi() async {
    _ensureConfigured();
    final account = _account ?? await _signIn.signInSilently() ?? _account;
    if (account == null) {
      throw SheetsGatewayException('Sign in with Google first.');
    }
    _account = account;
    final client = await _signIn.authenticatedClient();
    if (client == null) {
      throw SheetsGatewayException('Could not authorize Google Sheets access.');
    }
    return sheets.SheetsApi(client);
  }

  @override
  Future<String?> currentEmail() async {
    _account ??= await _signIn.signInSilently();
    return _account?.email;
  }

  @override
  Future<String> signIn() async {
    _ensureConfigured();
    try {
      final account = await _signIn.signIn();
      if (account == null) {
        throw SheetsGatewayException('Google sign-in was cancelled.');
      }
      _account = account;
      return account.email;
    } catch (e) {
      if (e is SheetsGatewayException) rethrow;
      if (e.toString().contains('ApiException: 10')) {
        throw SheetsGatewayException(
          'Google sign-in is not set up for this Android build. '
          'In Google Cloud Console, add an Android OAuth client for '
          'com.psithurismlabs.selahprayerapp with this build’s SHA-1. '
          'Keep the Web client id as GOOGLE_SERVER_CLIENT_ID.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _signIn.signOut();
    _account = null;
  }

  @override
  Future<String> createChurchSpreadsheet({
    String title = 'Selah Church Prayers',
  }) async {
    final api = await _sheetsApi();
    final created = await api.spreadsheets.create(
      sheets.Spreadsheet(
        properties: sheets.SpreadsheetProperties(title: title),
        sheets: [
          sheets.Sheet(
            properties: sheets.SheetProperties(title: 'Prayers'),
          ),
          sheets.Sheet(
            properties: sheets.SheetProperties(title: 'Verses'),
          ),
        ],
      ),
    );
    final id = created.spreadsheetId;
    if (id == null || id.isEmpty) {
      throw SheetsGatewayException('Could not create the church spreadsheet.');
    }
    await writePrayers(id, const []);
    await writeVerses(id, const []);
    return id;
  }

  @override
  Future<List<SheetPrayerRow>> readPrayers(String spreadsheetId) async {
    final api = await _sheetsApi();
    final result = await api.spreadsheets.values.get(
      spreadsheetId,
      'Prayers',
    );
    final values = result.values ?? const <List<Object?>>[];
    return decodePrayerRows(values);
  }

  @override
  Future<List<SheetVerseRow>> readVerses(String spreadsheetId) async {
    final api = await _sheetsApi();
    try {
      final result = await api.spreadsheets.values.get(
        spreadsheetId,
        'Verses',
      );
      final values = result.values ?? const <List<Object?>>[];
      return decodeVerseRows(values);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> writePrayers(
    String spreadsheetId,
    List<SheetPrayerRow> rows,
  ) async {
    final api = await _sheetsApi();
    await _ensureSheetTab(api, spreadsheetId, 'Prayers');
    await api.spreadsheets.values.clear(
      sheets.ClearValuesRequest(),
      spreadsheetId,
      'Prayers',
    );
    final encoded = encodePrayerRows(rows);
    await api.spreadsheets.values.update(
      sheets.ValueRange(values: encoded),
      spreadsheetId,
      'Prayers',
      valueInputOption: 'RAW',
    );
  }

  @override
  Future<void> writeVerses(
    String spreadsheetId,
    List<SheetVerseRow> rows,
  ) async {
    final api = await _sheetsApi();
    await _ensureSheetTab(api, spreadsheetId, 'Verses');
    final existing = await readVerses(spreadsheetId);
    final byId = {for (final v in existing) v.id: v};
    for (final v in rows) {
      byId[v.id] = v;
    }
    final merged = byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    await api.spreadsheets.values.clear(
      sheets.ClearValuesRequest(),
      spreadsheetId,
      'Verses',
    );
    await api.spreadsheets.values.update(
      sheets.ValueRange(values: encodeVerseRows(merged)),
      spreadsheetId,
      'Verses',
      valueInputOption: 'RAW',
    );
  }

  Future<void> _ensureSheetTab(
    sheets.SheetsApi api,
    String spreadsheetId,
    String title,
  ) async {
    final meta = await api.spreadsheets.get(spreadsheetId);
    final exists = meta.sheets?.any(
          (s) => s.properties?.title == title,
        ) ??
        false;
    if (exists) return;
    await api.spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest(
        requests: [
          sheets.Request(
            addSheet: sheets.AddSheetRequest(
              properties: sheets.SheetProperties(title: title),
            ),
          ),
        ],
      ),
      spreadsheetId,
    );
  }
}

/// In-memory gateway for tests and builds without Google client ids.
class FakeSheetsGateway implements SheetsGateway {
  FakeSheetsGateway({this.email});

  String? email;
  String? lastCreatedId;
  final Map<String, List<SheetPrayerRow>> prayers = {};
  final Map<String, List<SheetVerseRow>> verses = {};

  @override
  Future<String?> currentEmail() async => email;

  @override
  Future<String> signIn() async {
    email ??= 'tester@example.com';
    return email!;
  }

  @override
  Future<void> signOut() async {
    email = null;
  }

  @override
  Future<String> createChurchSpreadsheet({
    String title = 'Selah Church Prayers',
  }) async {
    final id = lastCreatedId ?? 'sheet-${DateTime.now().millisecondsSinceEpoch}';
    lastCreatedId = id;
    prayers[id] = [];
    verses[id] = [];
    return id;
  }

  @override
  Future<List<SheetPrayerRow>> readPrayers(String spreadsheetId) async =>
      List.of(prayers[spreadsheetId] ?? const []);

  @override
  Future<List<SheetVerseRow>> readVerses(String spreadsheetId) async =>
      List.of(verses[spreadsheetId] ?? const []);

  @override
  Future<void> writePrayers(
    String spreadsheetId,
    List<SheetPrayerRow> rows,
  ) async {
    prayers[spreadsheetId] = List.of(rows);
  }

  @override
  Future<void> writeVerses(
    String spreadsheetId,
    List<SheetVerseRow> rows,
  ) async {
    verses[spreadsheetId] = List.of(rows);
  }
}
