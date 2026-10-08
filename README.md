# Selah

A calm, offline prayer journal. Record prayer requests, pick promise verses that speak to the need, and pray through your list each day.

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Minimum SDKs: iOS 13+, Android API 24+.

## Architecture

Feature-first layers: presentation → Riverpod application state → domain interfaces → local data (Drift SQLite + bundled verse JSON). Domain code is pure Dart.

## Code generation

After changing Drift tables or freezed models:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Extending the verse dataset

See [assets/verses/SOURCE.md](assets/verses/SOURCE.md). Validate with:

```bash
dart run tool/build_verses.dart
```

## Assumptions

- Display name is `AppConfig.appName` (`Selah`).
- Translation is KJV (public domain).
- Sort mode and theme mode persist via `shared_preferences`.
- Shuffle seed is per calendar day; reshuffle count is not persisted across days.
