# Siri voice UX (SRS Phase 1.4, FR5)

Siri "find" runs `FindItemLocationIntent` in the App Intents extension. It reads the App Group shared cache, matches the spoken name, and **answers out loud without opening the app**. The copy lives in code in `ios/KnowItWhereKit/Sources/KnowItWhereCore/VoiceCopy.swift` and is covered by `VoiceCopyTests`.

## Conversation

```
You:   Hey Siri, find something in knowitwhere
Siri:  What are you looking for?
You:   My passport
Siri:  Passport is here: Desk, top drawer.
```

### Why Siri has to ask a follow-up question

iOS only lets App Shortcut phrases contain parameters that are app-defined types (`AppEntity`/`AppEnum`), never free text. FR5.2 asks for a free-text spoken name, so a phrase can't carry the item name. Siri asks for it instead. The answer is still spoken and no screen opens, so the "zero screens" part of the success criterion holds. The one-shot phrase ("Where's my passport in knowitwhere") is a Phase 5 experiment. See below.

## Trigger phrases

Every phrase must contain the app name (an iOS rule). These are registered by the `AppShortcutsProvider` in the intents extension:

- "Find something in knowitwhere"
- "Where did I put something in knowitwhere"
- "Ask knowitwhere where something is"
- "knowitwhere, find an item"

Users can also run the intent from the Shortcuts app, or give it a personal phrase.

## Responses

| Case | Spoken response | Intent value |
| --- | --- | --- |
| Siri asks for the item | "What are you looking for?" | — |
| Found (exact, substring or fuzzy) | "**{name}** is here: **{location}**." | location |
| Found, several equally good matches | "{name} is here: {location}. That's the most recent of {n} matches." | location |
| No match | "I couldn't find anything matching "{what Siri heard}"." | "" |
| No items saved yet | "You haven't saved anything in knowitwhere yet." | "" |

Notes:

- The answer uses the **saved** name, not what Siri heard. A fuzzy match is therefore audible: asking for "hitmi cable" answers "HDMI cable is here: Drawer 2." That lets the user notice a wrong guess.
- The location is spoken exactly as typed, followed by a single full stop. "is here:" was chosen over "is in" because locations are free text ("on the hook", "Mum's house", "blue folder").
- Not found repeats what Siri heard, so a speech-to-text mistake is obvious. The app is **not** opened automatically (FR5.3).
- Ambiguity isn't a question (v1 simplification, SRS §9). The most recently updated match wins and the extra sentence says there were others.

## Matching (FR5.3)

`ItemMatcher` in `KnowItWhereCore`, tested by `ItemMatcherTests`:

1. **Normalise:** case- and accent-insensitive, punctuation removed, leading filler words dropped ("my", "the", "where's", "is", …).
2. **Exact** name match.
3. **Substring** either way: "hdmi" → "HDMI cable"; "my old passport" → "Passport" (reverse direction needs a name of 3+ characters).
4. **Fuzzy:** Levenshtein similarity ≥ 0.6 against the whole name or any run of its words, e.g. "hitmi cable" → "HDMI cable", "pasport" → "Passport".
5. In every tier, **ties go to the most recently updated** item.

Known risk (SRS §11): close names such as "charger" / "charger 2". An exact match always beats a substring match, so both are reachable by saying the full name.

## Phase 5 experiments

- **One-shot phrase:** model items as an `AppEntity` with an `EntityStringQuery` backed by `ItemMatcher`. Then phrases like "Where's my \(item) in knowitwhere" become possible, but the app has to call `updateAppShortcutParameters()` whenever items change. Test on a device whether Siri recognises user-created names reliably before adopting it.
- Try the phrasings people actually use ("where's my…", "where did I leave…", "find my…") and tune the filler-word list.
