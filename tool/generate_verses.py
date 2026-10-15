#!/usr/bin/env python3
"""Build assets/verses/verses.json from curated specs + public-domain KJV."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KJV_PATH = ROOT / "tool" / "data" / "kjv.json"
OUT_PATH = ROOT / "assets" / "verses" / "verses.json"
HOME_MEDITATION_OUT_PATH = ROOT / "assets" / "verses" / "home_meditation.json"

BOOK_ABBREV = {
    "Genesis": "gen",
    "Exodus": "exo",
    "Leviticus": "lev",
    "Numbers": "num",
    "Deuteronomy": "deu",
    "Joshua": "jos",
    "Judges": "jdg",
    "Ruth": "rut",
    "1 Samuel": "1sa",
    "2 Samuel": "2sa",
    "1 Kings": "1ki",
    "2 Kings": "2ki",
    "1 Chronicles": "1ch",
    "2 Chronicles": "2ch",
    "Ezra": "ezr",
    "Nehemiah": "neh",
    "Esther": "est",
    "Job": "job",
    "Psalm": "psa",
    "Psalms": "psa",
    "Proverbs": "pro",
    "Ecclesiastes": "ecc",
    "Song of Solomon": "sng",
    "Isaiah": "isa",
    "Jeremiah": "jer",
    "Lamentations": "lam",
    "Ezekiel": "eze",
    "Daniel": "dan",
    "Hosea": "hos",
    "Joel": "jol",
    "Amos": "amo",
    "Obadiah": "oba",
    "Jonah": "jon",
    "Micah": "mic",
    "Nahum": "nah",
    "Habakkuk": "hab",
    "Zephaniah": "zep",
    "Haggai": "hag",
    "Zechariah": "zec",
    "Malachi": "mal",
    "Matthew": "mat",
    "Mark": "mar",
    "Luke": "luk",
    "John": "jhn",
    "Acts": "act",
    "Romans": "rom",
    "1 Corinthians": "1co",
    "2 Corinthians": "2co",
    "Galatians": "gal",
    "Ephesians": "eph",
    "Philippians": "phi",
    "Colossians": "col",
    "1 Thessalonians": "1th",
    "2 Thessalonians": "2th",
    "1 Timothy": "1ti",
    "2 Timothy": "2ti",
    "Titus": "tit",
    "Philemon": "phm",
    "Hebrews": "heb",
    "James": "jam",
    "1 Peter": "1pe",
    "2 Peter": "2pe",
    "1 John": "1jo",
    "2 John": "2jo",
    "3 John": "3jo",
    "Jude": "jud",
    "Revelation": "rev",
}

THEMES = {
    "provision", "healing", "fear", "anxiety", "peace", "guidance", "wisdom",
    "forgiveness", "mercy", "intercession", "protection", "strength", "comfort",
    "grief", "salvation", "family", "children", "marriage", "work", "nation",
    "faith", "hope", "perseverance", "prayer",
}


def load_kjv():
    data = json.loads(KJV_PATH.read_text())
    books = {}
    for book in data["books"]:
        name = book["name"]
        chapters = {}
        for ch in book["chapters"]:
            verses = {v["verse"]: v["text"].strip() for v in ch["verses"]}
            chapters[ch["chapter"]] = verses
        books[name] = chapters
        if name == "Psalms":
            books["Psalm"] = chapters
    return books


def parse_ref(ref: str):
    m = re.match(r"^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$", ref)
    if not m:
        raise ValueError(f"Bad ref: {ref}")
    book, chapter, start, end = m.group(1), int(m.group(2)), int(m.group(3)), m.group(4)
    end = int(end) if end else start
    return book, chapter, start, end


def make_id(book: str, chapter: int, start: int, end: int) -> str:
    ab = BOOK_ABBREV[book]
    if start == end:
        return f"{ab}-{chapter}-{start}"
    return f"{ab}-{chapter}-{start}-{end}"


def verse_text(books, book, chapter, start, end) -> str:
    parts = []
    for v in range(start, end + 1):
        parts.append(books[book][chapter][v])
    return " ".join(parts)


# Curated specs: (ref, themes, keywords, promiseType, note)
SPECS = [
    # Intercession / answered prayer
    ("Exodus 32:11-14", ["intercession", "mercy", "nation", "forgiveness"],
     ["intercede", "pray for others", "spare", "judgment", "relent", "people", "moses", "nation"],
     "answered_prayer", "Moses pleaded for Israel and the LORD relented."),
    ("Genesis 18:23-32", ["intercession", "mercy", "nation"],
     ["intercede", "plead", "spare", "city", "righteous", "abraham", "judgment"],
     "answered_prayer", "Abraham interceded for Sodom and God listened."),
    ("Numbers 14:19-20", ["intercession", "mercy", "forgiveness", "nation"],
     ["pardon", "forgive", "mercy", "people", "moses", "intercede"],
     "answered_prayer", "Moses asked God to pardon Israel and the LORD said, I have pardoned."),
    ("2 Kings 20:5-6", ["healing", "prayer", "answered_prayer"],
     ["heal", "sick", "prayer", "tear", "hezekiah", "life", "recover"],
     "answered_prayer", "God heard Hezekiah's prayer and healed him."),
    ("1 Samuel 1:27", ["prayer", "children", "family"],
     ["asked", "prayer", "child", "son", "hanna", "petition", "granted"],
     "answered_prayer", "Hannah received the son she had asked of the LORD."),
    ("Jonah 3:10", ["mercy", "nation", "repentance"],
     ["repent", "turn", "spare", "city", "mercy", "judgment", "nineveh"],
     "answered_prayer", "God saw Nineveh repent and did not destroy the city."),
    ("2 Chronicles 7:14", ["nation", "prayer", "forgiveness", "healing"],
     ["humble", "pray", "seek", "turn", "heal", "land", "nation", "country", "leaders"],
     "explicit_promise", "God promises to hear, forgive, and heal the land when His people humble themselves."),
    # Prayer promises
    ("Jeremiah 33:3", ["prayer", "guidance"],
     ["call", "answer", "pray", "show", "great", "mighty", "things"],
     "explicit_promise", "Call unto me, and I will answer thee."),
    ("Matthew 7:7-8", ["prayer", "faith"],
     ["ask", "seek", "knock", "receive", "find", "open", "pray"],
     "explicit_promise", "Ask, and it shall be given you; seek, and ye shall find."),
    ("Mark 11:24", ["prayer", "faith"],
     ["pray", "believe", "receive", "ask", "faith", "whatsoever"],
     "explicit_promise", "What things soever ye desire, when ye pray, believe that ye receive them."),
    ("John 14:13-14", ["prayer", "faith"],
     ["ask", "name", "jesus", "pray", "whatsoever", "answer"],
     "explicit_promise", "Whatsoever ye shall ask in my name, that will I do."),
    ("1 John 5:14-15", ["prayer", "faith"],
     ["confidence", "ask", "will", "hear", "petition", "pray"],
     "explicit_promise", "If we ask any thing according to his will, he heareth us."),
    ("Psalm 50:15", ["prayer", "protection"],
     ["call", "trouble", "deliver", "pray", "day", "honor"],
     "explicit_promise", "Call upon me in the day of trouble: I will deliver thee."),
    ("Psalm 145:18-19", ["prayer", "mercy"],
     ["near", "call", "truth", "desire", "hear", "cry", "save"],
     "explicit_promise", "The LORD is nigh unto all them that call upon him."),
    # Provision
    ("Philippians 4:19", ["provision", "work"],
     ["supply", "need", "riches", "provide", "money", "bills", "job", "lack"],
     "explicit_promise", "My God shall supply all your need according to his riches in glory."),
    ("Matthew 6:31-33", ["provision", "anxiety", "fear"],
     ["worry", "food", "drink", "clothes", "seek", "kingdom", "need", "bills", "anxious"],
     "explicit_promise", "Seek first the kingdom; all these things shall be added unto you."),
    ("Psalm 37:25", ["provision"],
     ["forsaken", "begging", "bread", "righteous", "provide", "food"],
     "character_of_god", "I have not seen the righteous forsaken, nor his seed begging bread."),
    ("2 Corinthians 9:8", ["provision"],
     ["grace", "sufficiency", "abound", "good work", "provide", "enough"],
     "explicit_promise", "God is able to make all grace abound toward you."),
    ("Psalm 23:1", ["provision", "peace", "guidance"],
     ["shepherd", "want", "lack", "provide", "care", "lead"],
     "character_of_god", "The LORD is my shepherd; I shall not want."),
    # Healing
    ("James 5:14-15", ["healing", "prayer"],
     ["sick", "hospital", "anoint", "pray", "heal", "illness", "disease", "save"],
     "explicit_promise", "The prayer of faith shall save the sick."),
    ("Exodus 15:26", ["healing"],
     ["heal", "disease", "health", "lord", "physician", "sick"],
     "explicit_promise", "I am the LORD that healeth thee."),
    ("Psalm 103:2-3", ["healing", "forgiveness", "mercy"],
     ["heal", "disease", "forgive", "iniquity", "benefit", "sick"],
     "character_of_god", "Who forgiveth all thine iniquities; who healeth all thy diseases."),
    ("Jeremiah 30:17", ["healing"],
     ["restore", "health", "heal", "wounds", "sick", "recover"],
     "explicit_promise", "I will restore health unto thee, and I will heal thee of thy wounds."),
    ("Isaiah 53:5", ["healing", "salvation"],
     ["wounded", "bruise", "stripe", "heal", "peace", "iniquity"],
     "character_of_god", "With his stripes we are healed."),
    ("Psalm 147:3", ["healing", "comfort", "grief"],
     ["heal", "broken", "heart", "wound", "bind", "grief"],
     "character_of_god", "He healeth the broken in heart, and bindeth up their wounds."),
    # Fear / anxiety / peace
    ("Isaiah 41:10", ["fear", "strength", "anxiety"],
     ["fear", "afraid", "strengthen", "help", "uphold", "scared", "worried"],
     "explicit_promise", "Fear thou not; for I am with thee."),
    ("Philippians 4:6-7", ["anxiety", "peace", "prayer", "fear"],
     ["anxious", "worried", "careful", "pray", "peace", "guard", "heart", "mind"],
     "explicit_promise", "Be careful for nothing; the peace of God shall keep your hearts."),
    ("1 Peter 5:7", ["anxiety", "fear", "comfort"],
     ["care", "cast", "anxiety", "worry", "burden", "concern"],
     "explicit_promise", "Casting all your care upon him; for he careth for you."),
    ("Joshua 1:9", ["fear", "strength", "courage"],
     ["afraid", "dismayed", "courage", "strong", "with thee", "fear"],
     "explicit_promise", "Be strong and of a good courage; be not afraid."),
    ("Psalm 56:3", ["fear", "faith"],
     ["afraid", "trust", "fear", "scared", "worry", "courage"],
     "character_of_god", "What time I am afraid, I will trust in thee."),
    ("John 14:27", ["peace", "fear", "anxiety"],
     ["peace", "afraid", "troubled", "heart", "leave", "give"],
     "explicit_promise", "Peace I leave with you, my peace I give unto you."),
    ("Isaiah 26:3", ["peace", "anxiety", "faith"],
     ["peace", "mind", "trust", "stay", "perfect"],
     "explicit_promise", "Thou wilt keep him in perfect peace, whose mind is stayed on thee."),
    # Guidance / wisdom
    ("Proverbs 3:5-6", ["guidance", "wisdom", "work"],
     ["trust", "lean", "understanding", "acknowledge", "direct", "path", "decision"],
     "explicit_promise", "In all thy ways acknowledge him, and he shall direct thy paths."),
    ("Psalm 32:8", ["guidance", "wisdom"],
     ["instruct", "teach", "guide", "way", "counsel", "decision"],
     "explicit_promise", "I will instruct thee and teach thee in the way which thou shalt go."),
    ("James 1:5", ["wisdom", "guidance", "prayer"],
     ["wisdom", "lack", "ask", "give", "liberally", "decision"],
     "explicit_promise", "If any of you lack wisdom, let him ask of God."),
    ("Jeremiah 29:11", ["hope", "guidance", "future"],
     ["thoughts", "peace", "future", "hope", "expected end", "plan"],
     "explicit_promise", "Thoughts of peace, and not of evil, to give you an expected end."),
    ("Isaiah 30:21", ["guidance"],
     ["voice", "way", "walk", "right", "left", "guide", "direction"],
     "explicit_promise", "This is the way, walk ye in it."),
    ("Proverbs 2:6", ["wisdom", "guidance"],
     ["wisdom", "knowledge", "understanding", "mouth", "lord"],
     "character_of_god", "The LORD giveth wisdom: out of his mouth cometh knowledge."),
    # Forgiveness
    ("1 John 1:9", ["forgiveness", "mercy"],
     ["confess", "sin", "forgive", "cleanse", "guilt", "guilty", "sorry", "faithful", "shame"],
     "explicit_promise", "If we confess our sins, he is faithful and just to forgive us."),
    ("Psalm 103:12", ["forgiveness", "mercy"],
     ["remove", "transgression", "east", "west", "forgive", "guilt", "guilty", "sin", "shame"],
     "character_of_god", "As far as the east is from the west, so far hath he removed our transgressions."),
    ("Isaiah 1:18", ["forgiveness", "mercy"],
     ["scarlet", "white", "snow", "sin", "forgive", "reason"],
     "explicit_promise", "Though your sins be as scarlet, they shall be as white as snow."),
    ("Micah 7:18-19", ["forgiveness", "mercy"],
     ["pardon", "iniquity", "compassion", "cast", "sea", "sin", "forgive"],
     "character_of_god", "He delighteth in mercy and will cast all their sins into the depths of the sea."),
    ("Acts 3:19", ["forgiveness", "salvation"],
     ["repent", "converted", "blot", "sin", "refreshing", "forgive"],
     "explicit_promise", "Repent ye therefore, and be converted, that your sins may be blotted out."),
    # Strength / weariness
    ("Isaiah 40:29-31", ["strength", "hope", "perseverance"],
     ["faint", "weary", "tired", "wait", "renew", "eagle", "strength", "run"],
     "explicit_promise", "They that wait upon the LORD shall renew their strength."),
    ("2 Corinthians 12:9", ["strength", "mercy"],
     ["grace", "sufficient", "weakness", "strength", "power", "tired"],
     "explicit_promise", "My grace is sufficient for thee: for my strength is made perfect in weakness."),
    ("Psalm 46:1", ["strength", "protection", "fear"],
     ["refuge", "strength", "help", "trouble", "present"],
     "character_of_god", "God is our refuge and strength, a very present help in trouble."),
    ("Matthew 11:28", ["strength", "comfort", "rest"],
     ["weary", "heavy laden", "rest", "tired", "come", "burden"],
     "explicit_promise", "Come unto me, all ye that labour and are heavy laden, and I will give you rest."),
    # Comfort / grief
    ("Psalm 34:18", ["comfort", "grief"],
     ["nigh", "broken", "heart", "contrite", "save", "grief", "died", "mourning"],
     "character_of_god", "The LORD is nigh unto them that are of a broken heart."),
    ("Matthew 5:4", ["comfort", "grief"],
     ["mourn", "comfort", "grief", "blessed", "sorrow"],
     "explicit_promise", "Blessed are they that mourn: for they shall be comforted."),
    ("Revelation 21:4", ["comfort", "grief", "hope"],
     ["wipe", "tear", "death", "sorrow", "crying", "pain", "died", "grief"],
     "explicit_promise", "God shall wipe away all tears from their eyes."),
    ("2 Corinthians 1:3-4", ["comfort", "grief", "mercy"],
     ["comfort", "tribulation", "consolation", "mercy", "affliction"],
     "character_of_god", "The God of all comfort comforts us in all our tribulation."),
    # Salvation of loved ones
    ("Acts 16:31", ["salvation", "family", "marriage"],
     ["believe", "saved", "house", "jesus", "husband", "wife", "unsaved", "family"],
     "explicit_promise", "Believe on the Lord Jesus Christ, and thou shalt be saved, and thy house."),
    ("2 Peter 3:9", ["salvation", "mercy", "hope"],
     ["longsuffering", "perish", "repent", "all", "unsaved", "salvation", "come"],
     "character_of_god", "Not willing that any should perish, but that all should come to repentance."),
    ("1 Timothy 2:3-4", ["salvation"],
     ["saved", "truth", "will", "all men", "knowledge", "unsaved"],
     "character_of_god", "Who will have all men to be saved, and to come unto the knowledge of the truth."),
    ("Romans 10:13", ["salvation", "prayer"],
     ["call", "name", "lord", "saved", "whosoever"],
     "explicit_promise", "Whosoever shall call upon the name of the Lord shall be saved."),
    # Protection
    ("Psalm 91:1-2", ["protection", "fear"],
     ["dwell", "secret", "refuge", "fortress", "trust", "almighty", "protect"],
     "character_of_god", "He that dwelleth in the secret place of the most High shall abide under the shadow of the Almighty."),
    ("Psalm 91:11", ["protection"],
     ["angel", "charge", "keep", "way", "protect", "guard"],
     "explicit_promise", "He shall give his angels charge over thee, to keep thee in all thy ways."),
    ("Psalm 121:7-8", ["protection"],
     ["preserve", "evil", "soul", "going", "coming", "keep", "protect"],
     "explicit_promise", "The LORD shall preserve thee from all evil."),
    ("Isaiah 54:17", ["protection"],
     ["weapon", "prosper", "condemn", "heritage", "protect", "defense"],
     "explicit_promise", "No weapon that is formed against thee shall prosper."),
    ("2 Thessalonians 3:3", ["protection", "faith"],
     ["faithful", "stablish", "keep", "evil", "protect"],
     "explicit_promise", "The Lord is faithful, who shall stablish you, and keep you from evil."),
    # Work / direction
    ("Psalm 37:4-5", ["work", "guidance", "hope"],
     ["delight", "desire", "commit", "way", "trust", "bring", "job", "work"],
     "explicit_promise", "Delight thyself also in the LORD; and he shall give thee the desires of thine heart."),
    ("Proverbs 16:3", ["work", "guidance"],
     ["commit", "work", "establish", "thought", "job", "plan"],
     "explicit_promise", "Commit thy works unto the LORD, and thy thoughts shall be established."),
    # Children / family
    ("Isaiah 54:13", ["children", "family", "peace"],
     ["children", "taught", "lord", "peace", "son", "daughter"],
     "explicit_promise", "All thy children shall be taught of the LORD; and great shall be the peace of thy children."),
    ("Proverbs 22:6", ["children", "family"],
     ["train", "child", "way", "old", "depart", "son", "daughter"],
     "character_of_god", "Train up a child in the way he should go."),
    # Additional verses to reach 100+
    ("Psalm 91:4", ["protection", "fear"],
     ["feather", "wing", "refuge", "shield", "buckler", "protect", "truth"],
     "character_of_god", "He shall cover thee with his feathers, and under his wings shalt thou trust."),
    ("Romans 8:26-27", ["prayer", "hope"],
     ["spirit", "help", "infirmity", "pray", "intercession", "will", "groaning"],
     "character_of_god",
     "The Spirit helps us pray and intercedes according to the will of God."),
    ("Romans 8:28", ["hope", "perseverance", "faith"],
     ["work", "good", "love", "purpose", "called", "all things"],
     "explicit_promise", "All things work together for good to them that love God."),
    ("Romans 8:38-39", ["hope", "faith", "love"],
     ["persuaded", "separate", "love", "death", "life", "christ"],
     "explicit_promise", "Nothing shall be able to separate us from the love of God."),
    ("Hebrews 13:5", ["provision", "fear", "faith"],
     ["content", "leave", "forsake", "help", "money", "presence"],
     "explicit_promise", "I will never leave thee, nor forsake thee."),
    ("Hebrews 4:16", ["prayer", "mercy"],
     ["boldly", "throne", "grace", "mercy", "help", "time of need"],
     "explicit_promise", "Come boldly unto the throne of grace, that we may obtain mercy."),
    ("Psalm 27:1", ["fear", "strength"],
     ["light", "salvation", "afraid", "strength", "fear", "whom"],
     "character_of_god", "The LORD is my light and my salvation; whom shall I fear?"),
    ("Psalm 27:14", ["hope", "strength", "perseverance"],
     ["wait", "lord", "courage", "strengthen", "heart", "hope"],
     "character_of_god", "Wait on the LORD: be of good courage, and he shall strengthen thine heart."),
    ("Psalm 55:22", ["anxiety", "burden", "strength"],
     ["cast", "burden", "sustain", "suffer", "righteous", "care"],
     "explicit_promise", "Cast thy burden upon the LORD, and he shall sustain thee."),
    ("Nahum 1:7", ["protection", "strength", "trust"],
     ["good", "stronghold", "trouble", "trust", "know"],
     "character_of_god", "The LORD is good, a strong hold in the day of trouble."),
    ("Deuteronomy 31:6", ["fear", "strength", "courage"],
     ["strong", "courage", "afraid", "fail", "forsake", "fear"],
     "explicit_promise", "Be strong and of a good courage… he will not fail thee, nor forsake thee."),
    ("Deuteronomy 31:8", ["fear", "guidance"],
     ["go", "before", "fail", "forsake", "afraid", "dismayed"],
     "explicit_promise", "The LORD, he it is that doth go before thee."),
    ("Psalm 121:1-2", ["help", "protection", "hope"],
     ["hills", "help", "come", "lord", "made", "heaven", "earth"],
     "character_of_god", "My help cometh from the LORD, which made heaven and earth."),
    ("Psalm 139:13-14", ["family", "children", "hope"],
     ["formed", "inward", "covered", "womb", "fearfully", "wonderfully", "child"],
     "character_of_god", "I will praise thee; for I am fearfully and wonderfully made."),
    ("Isaiah 43:1-2", ["fear", "protection", "comfort"],
     ["fear", "redeemed", "called", "name", "water", "fire", "pass"],
     "explicit_promise", "When thou passest through the waters, I will be with thee."),
    ("Isaiah 43:19", ["hope", "guidance"],
     ["new thing", "spring", "way", "wilderness", "river", "desert"],
     "explicit_promise", "Behold, I will do a new thing… I will even make a way in the wilderness."),
    ("Lamentations 3:22-23", ["mercy", "hope", "perseverance"],
     ["mercy", "compassions", "fail", "faithful", "new", "morning", "hope"],
     "character_of_god", "It is of the LORD's mercies that we are not consumed… great is thy faithfulness."),
    ("Zephaniah 3:17", ["comfort", "joy", "strength"],
     ["mighty", "save", "rejoice", "rest", "love", "joy"],
     "character_of_god", "The LORD thy God in the midst of thee is mighty; he will save."),
    ("Malachi 3:10", ["provision", "faith"],
     ["tithe", "storehouse", "prove", "open", "windows", "blessing", "pour"],
     "explicit_promise", "Prove me now herewith… if I will not open you the windows of heaven."),
    ("Matthew 6:34", ["anxiety", "fear", "peace"],
     ["tomorrow", "thought", "sufficient", "day", "evil", "worry"],
     "character_of_god", "Take therefore no thought for the morrow."),
    ("Matthew 18:19-20", ["prayer", "intercession"],
     ["agree", "ask", "gather", "name", "midst", "pray", "two", "three"],
     "explicit_promise", "If two of you shall agree on earth as touching any thing that they shall ask, it shall be done."),
    ("Matthew 19:26", ["faith", "hope"],
     ["impossible", "possible", "man", "god", "hard"],
     "character_of_god", "With God all things are possible."),
    ("Luke 1:37", ["faith", "hope"],
     ["impossible", "word", "god", "possible", "believe", "miracle"],
     "character_of_god", "For with God nothing shall be impossible."),
    ("Luke 11:9-10", ["prayer", "faith"],
     ["ask", "seek", "knock", "receive", "find", "open"],
     "explicit_promise", "Ask, and it shall be given you."),
    ("John 15:7", ["prayer", "faith"],
     ["abide", "word", "ask", "desire", "done"],
     "explicit_promise", "If ye abide in me, and my words abide in you, ye shall ask what ye will."),
    ("John 16:33", ["peace", "perseverance", "hope"],
     ["peace", "tribulation", "overcome", "world", "cheer", "trouble"],
     "explicit_promise", "In the world ye shall have tribulation: but be of good cheer; I have overcome the world."),
    ("Acts 2:21", ["salvation", "prayer"],
     ["call", "name", "lord", "saved", "whosoever"],
     "explicit_promise", "Whosoever shall call on the name of the Lord shall be saved."),
    ("Romans 5:8", ["salvation", "mercy", "love"],
     ["commend", "love", "sinners", "christ", "died", "yet"],
     "character_of_god", "While we were yet sinners, Christ died for us."),
    ("Romans 15:13", ["hope", "peace", "faith"],
     ["hope", "joy", "peace", "believe", "power", "holy ghost"],
     "character_of_god", "The God of hope fill you with all joy and peace in believing."),
    ("1 Corinthians 10:13", ["perseverance", "temptation", "strength"],
     ["temptation", "common", "faithful", "escape", "endure", "bear"],
     "explicit_promise", "God is faithful, who will not suffer you to be tempted above that ye are able."),
    ("2 Corinthians 4:16-18", ["hope", "perseverance", "strength"],
     ["faint", "outward", "inward", "renew", "affliction", "eternal"],
     "character_of_god", "Though our outward man perish, yet the inward man is renewed day by day."),
    ("Galatians 6:9", ["perseverance", "hope", "work"],
     ["weary", "well doing", "faint", "reap", "season", "tired"],
     "explicit_promise", "Let us not be weary in well doing: for in due season we shall reap."),
    ("Ephesians 3:20", ["prayer", "hope", "faith"],
     ["able", "exceeding", "ask", "think", "power", "work"],
     "character_of_god", "Able to do exceeding abundantly above all that we ask or think."),
    ("Ephesians 6:10", ["strength"],
     ["strong", "lord", "power", "might", "strength"],
     "character_of_god", "Be strong in the Lord, and in the power of his might."),
    ("Philippians 1:6", ["hope", "perseverance", "faith"],
     ["confident", "begin", "perform", "day", "christ", "complete"],
     "explicit_promise", "He which hath begun a good work in you will perform it."),
    ("Philippians 4:13", ["strength"],
     ["can", "do", "all", "strengthen", "christ", "able"],
     "character_of_god", "I can do all things through Christ which strengtheneth me."),
    ("Colossians 1:11", ["strength", "perseverance"],
     ["strengthened", "might", "patience", "longsuffering", "joyfulness"],
     "character_of_god", "Strengthened with all might, according to his glorious power."),
    ("1 Thessalonians 5:16-18", ["prayer", "joy", "hope"],
     ["rejoice", "pray", "thanks", "everything", "will"],
     "character_of_god", "Rejoice evermore. Pray without ceasing. In every thing give thanks."),
    ("2 Timothy 1:7", ["fear", "strength", "peace"],
     ["spirit", "fear", "power", "love", "sound mind", "afraid"],
     "character_of_god", "God hath not given us the spirit of fear; but of power, and of love, and of a sound mind."),
    ("Hebrews 11:1", ["faith", "hope"],
     ["faith", "substance", "hope", "evidence", "seen"],
     "character_of_god", "Faith is the substance of things hoped for, the evidence of things not seen."),
    ("Hebrews 11:6", ["faith", "prayer"],
     ["faith", "please", "come", "reward", "diligent", "seek"],
     "character_of_god", "He that cometh to God must believe that he is, and that he is a rewarder."),
    ("James 5:16", ["prayer", "healing", "forgiveness"],
     ["confess", "fault", "pray", "effectual", "righteous", "avail"],
     "character_of_god", "The effectual fervent prayer of a righteous man availeth much."),
    ("1 Peter 5:10", ["strength", "perseverance", "hope"],
     ["grace", "suffer", "perfect", "stablish", "strengthen", "settle"],
     "explicit_promise", "After that ye have suffered a while, make you perfect, stablish, strengthen, settle you."),
    ("1 John 4:18", ["fear", "love", "peace"],
     ["fear", "love", "perfect", "torment", "cast"],
     "character_of_god", "There is no fear in love; but perfect love casteth out fear."),
    ("Jude 1:24", ["protection", "hope", "salvation"],
     ["able", "keep", "falling", "present", "faultless", "joy"],
     "character_of_god", "Able to keep you from falling, and to present you faultless."),
    ("Revelation 3:20", ["salvation", "prayer"],
     ["stand", "door", "knock", "hear", "open", "sup"],
     "explicit_promise", "Behold, I stand at the door, and knock."),
    ("Psalm 9:9-10", ["protection", "refuge", "trust"],
     ["refuge", "oppressed", "trouble", "know", "trust", "forsake"],
     "character_of_god", "The LORD also will be a refuge for the oppressed, a refuge in times of trouble."),
    ("Psalm 16:11", ["hope", "joy", "guidance"],
     ["path", "life", "presence", "fulness", "joy", "pleasure"],
     "character_of_god", "Thou wilt shew me the path of life: in thy presence is fulness of joy."),
    ("Psalm 18:2", ["protection", "strength", "refuge"],
     ["rock", "fortress", "deliverer", "strength", "trust", "buckler"],
     "character_of_god", "The LORD is my rock, and my fortress, and my deliverer."),
    ("Psalm 34:4", ["fear", "prayer", "deliverance"],
     ["sought", "heard", "deliver", "fear", "afraid"],
     "answered_prayer", "I sought the LORD, and he heard me, and delivered me from all my fears."),
    ("Psalm 34:17", ["prayer", "protection"],
     ["cry", "hear", "deliver", "trouble", "righteous"],
     "explicit_promise", "The righteous cry, and the LORD heareth, and delivereth them out of all their troubles."),
    ("Psalm 37:7", ["peace", "patience", "trust"],
     ["rest", "wait", "patient", "fret", "prosper"],
     "character_of_god", "Rest in the LORD, and wait patiently for him."),
    ("Psalm 40:1-2", ["prayer", "hope", "perseverance"],
     ["waited", "heard", "cry", "pit", "rock", "establish"],
     "answered_prayer", "I waited patiently for the LORD; and he inclined unto me, and heard my cry."),
    ("Psalm 46:10", ["peace", "trust"],
     ["still", "know", "god", "exalted", "peace"],
     "character_of_god", "Be still, and know that I am God."),
    ("Psalm 51:10", ["forgiveness", "mercy"],
     ["create", "clean", "heart", "renew", "spirit", "right", "sin"],
     "character_of_god", "Create in me a clean heart, O God; and renew a right spirit within me."),
    ("Psalm 84:11", ["provision", "protection"],
     ["sun", "shield", "grace", "glory", "withhold", "good", "walk"],
     "explicit_promise", "No good thing will he withhold from them that walk uprightly."),
    ("Psalm 94:19", ["anxiety", "comfort", "peace"],
     ["thoughts", "within", "comfort", "delight", "soul", "worry"],
     "character_of_god", "In the multitude of my thoughts within me thy comforts delight my soul."),
    ("Psalm 119:105", ["guidance", "wisdom"],
     ["lamp", "feet", "light", "path", "word", "guide"],
     "character_of_god", "Thy word is a lamp unto my feet, and a light unto my path."),
    ("Proverbs 3:24", ["peace", "fear", "sleep"],
     ["lie down", "afraid", "sleep", "sweet", "fear"],
     "explicit_promise", "When thou liest down, thou shalt not be afraid: yea, thou shalt thy sleep be sweet."),
    ("Isaiah 40:11", ["comfort", "family", "children"],
     ["shepherd", "feed", "gather", "lambs", "carry", "gently", "children"],
     "character_of_god", "He shall gather the lambs with his arm, and carry them in his bosom."),
    ("Isaiah 41:13", ["fear", "strength", "help"],
     ["hold", "hand", "fear", "help", "right hand"],
     "explicit_promise", "I the LORD thy God will hold thy right hand, saying unto thee, Fear not; I will help thee."),
    ("Isaiah 49:15-16", ["comfort", "family", "love"],
     ["forget", "child", "compassion", "graven", "hands", "mother"],
     "character_of_god", "Yet will I not forget thee. Behold, I have graven thee upon the palms of my hands."),
    ("Jeremiah 17:7-8", ["hope", "trust", "strength"],
     ["trust", "hope", "tree", "water", "heat", "drought", "fruit"],
     "explicit_promise", "Blessed is the man that trusteth in the LORD, and whose hope the LORD is."),
    ("Ezekiel 36:26", ["hope", "forgiveness", "renewal"],
     ["new heart", "spirit", "stone", "flesh", "within"],
     "explicit_promise", "A new heart also will I give you, and a new spirit will I put within you."),
    ("Joel 2:25", ["hope", "restoration", "provision"],
     ["restore", "year", "locust", "eaten", "loss", "recover"],
     "explicit_promise", "I will restore to you the years that the locust hath eaten."),
    ("Habakkuk 3:17-18", ["hope", "joy", "perseverance"],
     ["fig", "fail", "flock", "rejoice", "joy", "salvation", "hard"],
     "character_of_god", "Yet I will rejoice in the LORD, I will joy in the God of my salvation."),
    ("Matthew 28:20", ["presence", "fear", "hope"],
     ["with you", "always", "end", "world", "presence", "alone"],
     "explicit_promise", "Lo, I am with you alway, even unto the end of the world."),
    ("John 10:10", ["hope", "life", "salvation"],
     ["thief", "steal", "life", "abundant", "more"],
     "character_of_god", "I am come that they might have life, and that they might have it more abundantly."),
    ("Romans 12:12", ["hope", "perseverance", "prayer"],
     ["rejoice", "hope", "patient", "tribulation", "continuing", "prayer"],
     "character_of_god", "Rejoicing in hope; patient in tribulation; continuing instant in prayer."),
    ("2 Timothy 4:17", ["strength", "protection"],
     ["stood", "strengthened", "preach", "deliver", "lion", "mouth"],
     "answered_prayer", "The Lord stood with me, and strengthened me… and I was delivered out of the mouth of the lion."),
]

# Home-screen meditation: God's holiness and a Spirit-led life.
# Refs only; text is copied from kjv.json. Interleaved holiness / Spirit.
_HOME_HOLINESS = [
    "Habakkuk 2:20",
    "Isaiah 6:3",
    "Revelation 4:8",
    "1 Peter 1:15-16",
    "Leviticus 19:2",
    "Psalm 99:5",
    "Psalm 99:9",
    "Exodus 15:11",
    "Isaiah 57:15",
    "Psalm 29:2",
    "Psalm 96:9",
    "Revelation 15:4",
    "1 Samuel 2:2",
    "Psalm 145:17",
    "Psalm 93:5",
    "Psalm 111:9",
    "Exodus 3:5",
    "Psalm 22:3",
    "Isaiah 40:25",
    "Proverbs 9:10",
    "Isaiah 8:13",
    "1 Chronicles 16:29",
    "Psalm 103:1",
    "Revelation 4:11",
    "1 John 1:5",
    "Psalm 11:4",
    "Hebrews 12:14",
    "1 Thessalonians 4:7",
    "2 Corinthians 7:1",
    "Romans 12:1",
    "Hebrews 12:10",
    "Matthew 5:8",
    "Psalm 24:3-4",
    "1 Peter 2:9",
    "Ephesians 4:23-24",
]

_HOME_SPIRIT = [
    "Galatians 5:16",
    "Galatians 5:22-23",
    "Galatians 5:25",
    "Galatians 5:18",
    "Romans 8:14",
    "Romans 8:4",
    "Romans 8:5-6",
    "Romans 8:9",
    "Romans 8:2",
    "Romans 8:26",
    "Ephesians 5:18",
    "Ephesians 5:8",
    "Ezekiel 36:27",
    "Psalm 143:10",
    "Psalm 51:10-11",
    "Proverbs 3:5-6",
    "John 16:13",
    "John 14:26",
    "John 4:24",
    "John 15:5",
    "John 3:5-6",
    "2 Corinthians 3:18",
    "Zechariah 4:6",
    "Philippians 2:13",
    "Isaiah 11:2",
    "Ephesians 3:16",
    "Romans 15:13",
    "2 Timothy 1:7",
    "Titus 3:5",
    "1 Peter 1:2",
    "2 Thessalonians 2:13",
    "Ephesians 4:30",
    "1 Thessalonians 5:19",
    "Isaiah 30:21",
    "Psalm 119:133",
    "1 Corinthians 6:19",
    "Galatians 6:8",
    "Luke 11:13",
    "Micah 6:8",
]


def _interleave_home_refs() -> list[str]:
    out: list[str] = []
    for i in range(max(len(_HOME_HOLINESS), len(_HOME_SPIRIT))):
        if i < len(_HOME_HOLINESS):
            out.append(_HOME_HOLINESS[i])
        if i < len(_HOME_SPIRIT):
            out.append(_HOME_SPIRIT[i])
    return out


HOME_MEDITATION_SPECS = _interleave_home_refs()


def display_ref(book: str, chapter: int, start: int, end: int) -> str:
    if start == end:
        return f"{book} {chapter}:{start}"
    return f"{book} {chapter}:{start}–{end}"


def build_home_meditation(books) -> list[dict]:
    verses = []
    seen = set()
    for ref in HOME_MEDITATION_SPECS:
        book, chapter, start, end = parse_ref(ref)
        key = (book, chapter, start, end)
        if key in seen:
            raise SystemExit(f"Duplicate home meditation ref {ref}")
        seen.add(key)
        verses.append({
            "ref": display_ref(book, chapter, start, end),
            "text": verse_text(books, book, chapter, start, end),
        })
    return verses


def main():
    books = load_kjv()
    verses = []
    seen = set()
    for ref, themes, keywords, promise_type, note in SPECS:
        book, chapter, start, end = parse_ref(ref)
        vid = make_id(book, chapter, start, end)
        if vid in seen:
            raise SystemExit(f"Duplicate id {vid}")
        seen.add(vid)
        for t in themes:
            if t not in THEMES and t != "repentance" and t != "temptation" and t != "deliverance" and t != "refuge" and t != "joy" and t != "love" and t != "rest" and t != "courage" and t != "presence" and t != "renewal" and t != "restoration" and t != "future" and t != "sleep" and t != "burden":
                # Allow a few soft tags but prefer controlled vocab — map extras out
                pass
        # Filter themes to controlled vocabulary only
        controlled = [t for t in themes if t in THEMES]
        if not controlled:
            controlled = ["hope"]
        text = verse_text(books, book, chapter, start, end)
        verses.append({
            "id": vid,
            "ref": display_ref(book, chapter, start, end),
            "text": text,
            "themes": controlled[:4],
            "keywords": keywords[:15],
            "promiseType": promise_type,
            "note": note,
        })

    payload = {"translation": "KJV", "version": 1, "verses": verses}
    OUT_PATH.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n")
    print(f"Wrote {len(verses)} verses to {OUT_PATH}")

    home = build_home_meditation(books)
    home_payload = {
        "translation": "KJV",
        "version": 1,
        "verses": home,
    }
    HOME_MEDITATION_OUT_PATH.write_text(
        json.dumps(home_payload, indent=2, ensure_ascii=False) + "\n"
    )
    print(f"Wrote {len(home)} home meditation verses to {HOME_MEDITATION_OUT_PATH}")


if __name__ == "__main__":
    main()
