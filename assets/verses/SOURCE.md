# Verse dataset source

- **Translation:** King James Version (public domain)
- **Source file:** [`tool/data/kjv.json`](../../tool/data/kjv.json) from getbible.net KJV JSON (`translation: King James Version`, `abbreviation: kjv`, `lang: en`)
- **Build:** `python3 tool/generate_verses.py` copies verse text programmatically from that file; keywords, themes, notes, and promise types are curated by hand in the script.
- **Validate:** `dart run tool/build_verses.dart`

## Spot-check (hand-verified against source)

At least these twenty entries were compared verse-for-verse to `tool/data/kjv.json`:

1. Exodus 32:11–14
2. Jeremiah 33:3
3. Matthew 7:7–8
4. Philippians 4:19
5. James 5:14–15
6. Isaiah 41:10
7. Philippians 4:6–7
8. Proverbs 3:5–6
9. 1 John 1:9
10. Psalm 34:18
11. Acts 16:31
12. 2 Chronicles 7:14
13. Psalm 91:1–2
14. Isaiah 40:29–31
15. Revelation 21:4
16. John 14:27
17. Romans 8:28
18. Hebrews 13:5
19. Psalm 23:1
20. 1 Peter 5:7
