# Siri voice UX (SRS Phase 1.4, FR5)

Siri answers "where is it?" out loud **without opening the app** (FR5.3). Two intents in `ios/KnowItWhereKit/Sources/KnowItWhereIntents/` do this; both read the App Group shared cache:

- `WhereIsItemIntent`: one sentence, with the item name in the phrase
- `FindItemLocationIntent`: the fallback. Siri asks for the name

The copy lives in code in `ios/KnowItWhereKit/Sources/KnowItWhereCore/VoiceCopy.swift` and is covered by `VoiceCopyTests`.

## Conversation

```
You:   Hey Siri, where's my passport in KnowItWhere?
Siri:  Passport is here: Desk, top drawer.
```

Fallback, for anything Siri doesn't recognise as a saved item name:

```
You:   Hey Siri, find something in KnowItWhere
Siri:  What are you looking for?
You:   My passport
Siri:  Passport is here: Desk, top drawer.
```

### How the one-sentence phrase works

App Shortcut phrases can only contain app-defined parameter types (`AppEntity`/`AppEnum`), never free text. So each saved item is an `ItemEntity` (id, name, location), and `ItemEntityQuery`:

- `suggestedEntities()` returns every item, most recent first. Siri learns the names it listens for from this list.
- `entities(matching:)` runs `ItemMatcher` on what Siri heard and returns **at most one** item. v1 never asks Siri to disambiguate (SRS §9).
- `entities(for:)` looks items up by id.

`WhereIsItemIntent.perform()` re-reads the item by id, so an edit since Siri last fetched names is reflected. An item deleted in the meantime gets the not-found answer.

### Keeping Siri's names current

Siri only knows the names it last fetched, so the app calls `KnowItWhereShortcuts.updateAppShortcutParameters()` after every add, edit and delete, and at launch. In Dart, `SiriSink` (`lib/platform/siri.dart`) runs after `SharedCacheSink`, so the cache is up to date when Siri reads it. It calls `refresh` on the `knowitwhere/siri` channel, which `SiriShortcutsPlugin` in `ios/Runner/KnowItWhereShortcuts.swift` handles.

**Why the intents run in the app, not an App Intents extension:** the app can only call `updateAppShortcutParameters()` on a provider it contains. Apple DTS's guidance is that the `AppShortcutsProvider` and the intents it uses must be in the main app target for this ([developer forums](https://developer.apple.com/forums/thread/759160)). An extension has no way to learn that items changed. So `KnowItWhereShortcuts` is in Runner, and Runner links `KnowItWhereIntents` and includes it via `AppIntentsPackage`. With `openAppWhenRun = false`, iOS runs the intent in the background without bringing the app to the foreground. The Flutter engine starts with the window scene, so a Siri request doesn't start Dart.

## Trigger phrases

Every phrase must contain the app name (an iOS rule). They are registered by `KnowItWhereShortcuts` in `ios/Runner/KnowItWhereShortcuts.swift`.

One sentence (`{item}` is a saved item's name):

- "Ask KnowItWhere where my {item} is"
- "Ask KnowItWhere where I put my {item}"
- "KnowItWhere, where's my {item}"
- "KnowItWhere, where is my {item}"
- "Where did I put my {item} in KnowItWhere"
- "Where did I leave my {item} in KnowItWhere"
- "Where's my {item} in KnowItWhere"
- "Where is my {item} in KnowItWhere"

There is deliberately no "Find my {item} in KnowItWhere": see *Find My overlap* below.

Fallback:

- "Find something in KnowItWhere"
- "Where did I put something in KnowItWhere"
- "Ask KnowItWhere where something is"
- "KnowItWhere, find an item"

Users can also run either intent from the Shortcuts app, or give it a personal phrase.

## Responses

| Case | Spoken response | Intent value |
| --- | --- | --- |
| Siri asks for the item | "What are you looking for?" | — |
| Found (exact, substring or fuzzy) | "**{name}** is here: **{location}**." | location |
| Found, several equally good matches | "{name} is here: {location}. That's the most recent of {n} matches." | location |
| No match | "I couldn't find anything matching "{what Siri heard}"." | "" |
| No items saved yet (fallback phrase only) | "You haven't saved anything in KnowItWhere yet." | "" |

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

## Known behaviour from device testing (2026-10-24)

- **First use asks to turn on shortcuts.** The first time a KnowItWhere phrase is spoken, iOS shows a one-time card offering to turn on the app's shortcuts with Siri. After "Turn on", Siri answers, and the card doesn't come back. This is system behaviour and the app can't skip it. Opening the app once after installing makes the phrases available sooner.
- **Find My overlap.** "Where's my …" and "Find my …" are Find My's own trigger words (AirTags, devices, people). With "in KnowItWhere" at the end, Siri usually picks the app, but now and then it goes to Find My or a web search instead, especially as the first request of a session. Phrases that **start** with the app name ("Ask KnowItWhere where my passport is", "KnowItWhere, where's my passport") or that Find My doesn't own ("Where did I put my passport in KnowItWhere") avoid the collision, so they are listed first.
- **Recognising the name.** "KnowItWhere" is a made-up word that speech recognition can hear as "know it where". `INAlternativeAppNames` in `ios/Runner/Info.plist` adds "Know It Where" as a synonym, which Apple says App Shortcuts honour.

## Device checks

- The one-sentence phrase with and without "my", and with a fuzzy name ("hitmi cable")
- Add a new item, then ask for it straight away (checks that Siri's names update)
- Compare "Ask KnowItWhere where my passport is" with "Where's my passport in KnowItWhere", each as the first request after locking the phone
- If the "Where's my …" form stays unreliable but the "Ask KnowItWhere …" form works, change the advertised phrase to the latter. If neither works reliably, switch the phrase advertised in `lib/widgets/siri_bar.dart`, `lib/features/home/smart_tip.dart` and `lib/features/item_detail/item_detail_screen.dart` back to "Hey Siri, find something in KnowItWhere"
