# Selah agent instructions

Selah is an offline Flutter prayer journal. People record petitions and select Scripture to pray. The app does not teach a prayer method.

Keep it strictly biblical, orthodox and reformed.

## Read before editing

- `.cursor/rules/selah-faith.mdc` applies to every change.
- `.cursor/rules/selah-flutter.mdc` applies to Dart.
- `.cursor/skills/prayer-scripture/SKILL.md` applies when changing verses, strategies, or prayer copy.

## Product rules already in the code

- Verse text is public-domain KJV, generated from `tool/data/kjv.json`. Do not paste paraphrases into `assets/verses/verses.json`.
- `assets/verses/strategies.json` is a hidden index for choosing verses. The user only sees and selects Scripture.
- Layers are presentation, Riverpod application state, pure-Dart domain, then Drift or JSON data.
- The journal is offline by default. Optional email sign-in and group sync (`SELAH_API_BASE_URL`) are the only network path. Just me prayers never leave the device. Do not hard-code a production hostname in docs or defaults.
- Prayer asks God according to His will. Do not write copy that treats prayer as a technique that binds God, or that blames the person when an answer is delayed.
