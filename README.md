# Selah

A calm, offline prayer journal. Record prayer requests, pick promise verses that speak to the need, and pray through your list each day.

## Setup

```bash
flutter pub get
dart run build_runner build
flutter run
```

Minimum SDKs: iOS 13+, Android API 24+. The journal is offline by default. Optional church spreadsheet sync uses Google Sign-In and needs network when the user syncs.

## Church spreadsheet sync (optional)

Prayers marked **Just me** never leave the device. Prayers marked **Church** two-way sync with one shared Google Sheet (`Prayers` and `Verses` tabs).

1. In Google Cloud Console, create an OAuth client for iOS and a Web client (server client id). Enable the Google Sheets API.
2. Add test users on the OAuth consent screen while the app is unpublished / unverified.
3. Share the church spreadsheet (edit access) with each Google account that will sync.
4. Build with the OAuth client ids (iOS + Web / server client id):

```bash
flutter run \
  --dart-define=GOOGLE_IOS_CLIENT_ID=871420508075-o79md62ij2uair87rb6ueaumem20krbm.apps.googleusercontent.com \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=871420508075-n8h5mh5rmbkr7vqsq4e3h2d5ia5h998q.apps.googleusercontent.com
```

5. On iOS, the reversed iOS client id is already registered as a URL scheme in `ios/Runner/Info.plist`.
6. In Settings: Sign in with Google → link or create the church spreadsheet → Sync now.

Public Play / App Store distribution of the `spreadsheets` scope requires Google’s app verification.

## Architecture

Feature-first layers: presentation → Riverpod application state → domain interfaces → local data (Drift SQLite + bundled verse JSON). Domain code is pure Dart (no Flutter or Drift imports).

```
lib/
  app/           MaterialApp, router, theme, AppConfig.appName
  core/          database, providers, clock, shuffle helpers
  features/
    prayers/     list, add/edit, detail, repository
    verses/      suggester, picker, asset loader
    analytics/   EventLogger (local only)
```

## Code generation

After changing Drift tables:

```bash
dart run build_runner build
```

## Extending the verse dataset

1. Add a curated entry to `tool/generate_verses.py` (reference, themes from the controlled vocabulary, keywords, promise type, note).
2. Run `python3 tool/generate_verses.py` — verse **text** is copied from `tool/data/kjv.json` (public-domain KJV). Never paste paraphrased scripture.
3. Validate: `dart run tool/build_verses.dart`
4. Spot-check new entries against the source file. See [assets/verses/SOURCE.md](assets/verses/SOURCE.md).

## Assumptions

- Display name is `AppConfig.appName` (`Selah`).
- Translation is KJV (public domain).
- Sort mode and theme mode persist via `shared_preferences`.
- Shuffle seed is per calendar day; reshuffle count is not persisted across days.
- Domain entities are plain immutable Dart classes (freezed was omitted due to analyzer/SDK mismatch on Flutter 3.47).

## Accessibility

Automated:

- `test/theme_contrast_test.dart` — WCAG contrast for light/dark tokens
- `test/prayers/accessibility_widget_test.dart` — 200% text scale and tap-target guidelines

Manual checklist (device / simulator):

- [ ] TalkBack (Android) and VoiceOver (iOS): prayer cards announce name, preview, verses, tags, status; custom actions Mark answered / Delete
- [ ] 200% system font size: list, edit, and detail with no overflow or horizontal scroll
- [ ] Bold Text and Reduce Motion OS settings
- [ ] Light and dark mode; System theme follows OS
- [ ] Color-blindness simulation: answered state still readable via badge text + check icon
- [ ] Swipe actions also available from each card’s overflow menu

## Theme

Colors, type, and radii live only in `lib/app/theme.dart`. UI font: Atkinson Hyperlegible. Scripture font: Lora. Both are bundled under `assets/fonts/`.
