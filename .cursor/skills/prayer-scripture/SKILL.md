---
name: prayer-scripture
description: >-
  Guides Scripture selection, prayer copy, and verse-library edits for the
  Selah Flutter app. Use when adding verses, prayer strategies, notes, themes,
  keywords, or any user-facing prayer text. Keep it strictly biblical, orthodox
  and reformed.
---

# Prayer and Scripture

Keep it strictly biblical, orthodox and reformed.

The user selects Scripture. Strategies only decide which verses to offer. Do not render `name`, `summary`, `howToPray`, `sources`, `caution`, or `note` from a strategy.

## When editing the verse library

1. Add the reference, themes, keywords, promise type, and note in `tool/generate_verses.py`.
2. Run `python3 tool/generate_verses.py` so the text is copied from `tool/data/kjv.json`.
3. Run `dart run tool/build_verses.dart`.
4. Spot-check the new text against `tool/data/kjv.json`.

Promise types: `explicit_promise`, `answered_prayer`, `character_of_god`. Use `character_of_god` when the verse shows who God is rather than a stated promise.

## When editing strategies

`assets/verses/strategies.json` fields that matter: `id`, `alwaysOn`, `order`, `triggers`, `seedRefs`.

- `alwaysOn` may contribute one verse even with no trigger. Use it only for praying God's words back and for thanksgiving.
- Triggers are whole words. Do not use `still`, `yet`, `how`, `say`, `long`, `never`, or `keep`.
- `seedRefs` must match a `ref` already in `assets/verses/verses.json`. If the passage is missing, add it first. Do not point at a neighboring verse.
- Leave fasting and spiritual warfare out of the default pools.

## Copy

Write notes in one or two sentences. Say what the text says. Do not tell the user their prayer failed because of sin or doubt.

```text
Bad: Ask once, then thank Him as if it is already done.
Good: Ask plainly for what fits God's will, and keep bringing it to Him.
```

More examples: [examples.md](examples.md).
