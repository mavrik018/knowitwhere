# Software Requirements Specification

## "Where Did I Put That?" 📦 — v1.0

**Platform:** iOS (App Store)
**Stack:** Flutter (main app) + native Swift (Widget Extension + App Intents/Siri Extension)
**Status:** Planning — pre-development

---

## 1. Product Vision

A local-only personal storage tracker. The user logs where they put a physical object; later they retrieve that location in under 5 seconds — by typing, by glancing at a widget, or by asking Siri out loud.

**Success criterion for v1:** "Hey Siri, where's my passport?" → spoken answer, zero screens opened.

The whole product is judged against one rule: **does this make "add" or "find" faster, or does it slow them down?** Anything that doesn't clearly pass is deferred (see §9).

## 2. Scope

### 2.1 In scope (v1)

- Add / edit / delete items (name, location, optional photo)
- Live search
- Home-screen widget (recent items, tap-to-open, tap-to-add)
- Siri Tier 2 App Intent — spoken answer, no app launch, for "find" only
- Spotlight (system search) indexing
- No monetization in v1 — free, no IAP, no subscriptions, no paywall

### 2.2 Out of scope (v1) — see §9 for full backlog

Sync/multi-device, categories/tags/folders, Siri add-item voice flow, barcode/NFC, Android, sharing/collaboration.

## 3. Users & Core Use Cases

| #   | Use case                         | Trigger                      | Target time          |
| --- | -------------------------------- | ---------------------------- | -------------------- |
| UC1 | Store an item's location         | Open app → Add               | < 10 sec             |
| UC2 | Find an item (typing)            | Open app → Search            | < 5 sec              |
| UC3 | Find an item (glance)            | Look at home-screen widget   | < 2 sec              |
| UC4 | Find an item (voice, hands full) | "Hey Siri, where's my X"     | < 3 sec, no screen   |
| UC5 | Update an item's location        | Item detail → edit           | < 10 sec             |

## 4. System Architecture

This is the piece that makes Siri Tier 2 and the widget possible without writing the app's data layer twice.

### 4.1 Two data stores, one source of truth

```
┌─────────────────────────────┐
│         Flutter App          │
│  (source of truth)           │
│  Local DB: sqflite/Drift     │
│  Full Item records + photos  │
└───────────────┬──────────────┘
                │ on every add/edit/delete:
                │ write a flattened JSON snapshot
                ▼
┌─────────────────────────────────────┐
│   Shared App Group Container         │
│   (UserDefaults suite or JSON file)  │
│   [{id, name, location, updatedAt}]  │
└───────┬───────────────────┬─────────┘
        │ read-only         │ read-only
        ▼                   ▼
┌─────────────────┐  ┌──────────────────────┐
│ Widget Extension│  │ App Intents Extension│
│   (SwiftUI)     │  │   (Siri Tier 2)      │
└─────────────────┘  └──────────────────────┘
```

**Why this shape, not a shared SQLite file:** Flutter's local DB stays whatever is comfortable (sqflite or Drift), with full records including photo file paths — the extensions never need to understand that schema. Every mutation, the Flutter app also writes a small flattened JSON array (id, name, location, updatedAt only — no photos) into the shared App Group container, using the `home_widget` package, which already wraps this exact UserDefaults-suite pattern. Both native extensions become simple, stateless readers of that one JSON blob. No cross-language DB drivers, no sync conflicts, one write path.

### 4.2 Required capability: App Groups

All three targets — main app, Widget Extension, App Intents Extension — must share one App Group ID (e.g. `group.com.yourco.wheredidiputit`), enabled in each target's Signing & Capabilities. This is the wiring that makes §4.1 possible; set it up before writing either extension.

### 4.3 Deep linking

A custom URL scheme (e.g. `wdipit://item/{id}` and `wdipit://add`) lets the widget hand off taps to the running/launching Flutter app. Handle these in Flutter via `app_links` or `uni_links`.

### 4.4 Widget refresh strategy

Don't use WidgetKit's time-based refresh policy — nothing here changes on a schedule. Instead, after every Flutter-side mutation, call `home_widget`'s reload/update method, which triggers `WidgetCenter.shared.reloadTimelines` natively. The widget updates the moment data changes, not on a timer.

## 5. Data Model

**Flutter local DB (source of truth):**

```
Item {
  id: String (UUID)
  name: String
  location: String
  photoPath: String?      // relative path in app's documents dir
  dateAdded: DateTime
  dateUpdated: DateTime
}
```

**Shared cache (App Group JSON, written on every mutation):**

```json
[
  { "id": "uuid", "name": "HDMI cable", "location": "Drawer 2", "updatedAt": "ISO8601" }
]
```

No photo reference needed here — widget and Siri are both text-first by design (a widget can't take input, and voice answers are inherently textual).

## 6. Functional Requirements

### FR1 — Item CRUD (Flutter)

- **FR1.1** Add item: name (required), location (required, free text — not a picker), photo (optional, camera or library)
- **FR1.2** Edit item: same fields, updates `dateUpdated`
- **FR1.3** Delete item (swipe or from detail view)
- **FR1.4** Every mutation triggers: (a) local DB write, (b) shared-cache JSON rewrite, (c) widget reload signal, (d) Spotlight index update

### FR2 — Search (Flutter)

- **FR2.1** Live, case-insensitive substring filter on name (and optionally location) as the user types
- **FR2.2** Empty state distinct from "no results" state
- **FR2.3** Results sorted by relevance-then-recency (exact prefix match first, then most recently updated)

### FR3 — Photo capture (Flutter)

- **FR3.1** Camera or photo-library picker on Add/Edit
- **FR3.2** Store in app's local Documents directory; store relative path only in DB (never absolute, since sandbox paths can change between launches)
- **FR3.3** Downscale/compress before saving (target ≤ 1MB per photo) — this is a personal reference photo, not archival quality

### FR4 — Widget (Native, reads §4.1 shared cache)

- **FR4.1** Small/Medium widget shows the 3–5 most recently updated items as name → location rows
- **FR4.2** Tapping a row deep-links to that item's detail screen (app launches if needed)
- **FR4.3** Tapping empty widget space opens the app; the medium widget also has a "+" button that deep-links to Add Item (changed after device testing, 2026-10-24)
- **FR4.4** Widget has a graceful empty state ("Nothing saved yet — tap to add your first"); tapping it deep-links to Add Item
- **FR4.5** No search, no input, no scrolling inside the widget — display + shortcut only (WidgetKit constraint, and intentional per §1)

### FR5 — Siri Tier 2: Find (Native App Intent)

- **FR5.1** One App Intent, e.g. `FindItemLocationIntent`, exposed to Siri and Shortcuts
- **FR5.2** Parameter: spoken item name (String, via Siri's speech-to-text)
- **FR5.3** On invocation: read the shared JSON cache (§4.1), match spoken name against `name` field
  - Match strategy: case-insensitive, then substring, then simple fuzzy (e.g. Levenshtein or NSString fuzzy compare) as fallback for near-misses ("hitmi cable" → "HDMI cable")
  - On single match: return location as a spoken `.result(value:dialog:)` — no UI, no app launch
  - On zero matches: spoken fallback ("I couldn't find anything matching that") — do not open the app automatically
  - On multiple ambiguous matches (v1 simplification): return the most recently updated match rather than building a disambiguation UI — document this as a known v1 limitation, not a bug
- **FR5.4** Siri usage requires `NSSiriUsageDescription` in Info.plist and the App Intent marked as available to Siri (`AppShortcutsProvider`)

### FR6 — Siri Tier 1: Add (deferred rationale)

Explicitly not building voice-driven Add in v1. Adding requires typing/dictating a location and optionally a photo — a voice-only flow degrades the core UX rather than speeding it up. If ever added, it would open the app pre-filled (Tier 1), not answer silently (Tier 2).

### FR7 — Spotlight indexing (Native, via Core Spotlight)

- **FR7.1** Every item indexed with name as searchable title, location as description, on every add/edit; de-indexed on delete
- **FR7.2** Tapping a Spotlight result deep-links into the app (same mechanism as FR4.2)

## 7. Non-Functional Requirements

| Category            | Requirement |
| ------------------- | ----------- |
| Privacy             | Fully local. No network calls, no accounts, no analytics SDKs in v1. App Store privacy label: "Data Not Collected." |
| Performance         | Cold start < 1s. Search filtering feels instant up to ~1,000 items (in-memory filter, no debounce needed at this scale). |
| Reliability / backup| Do not exclude the local DB from iOS device backup. This gives free durability (standard iCloud/iTunes backup) without building any sync system — a deliberate, low-effort reliability win. |
| Accessibility       | Support Dynamic Type on all screens. VoiceOver labels on list rows and the Add/Edit form. Siri responses are audio-first by construction. |
| Offline             | 100% functional with no network, permanently — not a fallback mode, the actual design. |

## 8. App Store Submission Checklist

- [ ] `NSCameraUsageDescription` — plain sentence, e.g. "Used to photograph where you stored an item."
- [ ] `NSSiriUsageDescription` — e.g. "Lets you ask Siri where you put something."
- [ ] App Groups capability enabled identically on all 3 targets
- [ ] Privacy Nutrition Label: Data Not Collected
- [ ] Reviewer notes in App Store Connect explaining how to test the Siri intent (reviewers won't discover voice features on their own — give them the exact phrase to say and expected result)
- [ ] ASO keywords: "where did I put," "storage tracker," "item finder," "inventory," "declutter," "find my stuff"

## 9. Explicitly Out of Scope (v1 parking lot)

Categories/tags/nested locations · iCloud sync across devices · Siri add-item voice flow · barcode/NFC tagging · multiple photos per item · sharing/collaboration · Android · item disambiguation UI for ambiguous Siri matches.

Write these down, don't revisit until v1 has real usage.

## 10. Software Engineering Phases

Each phase has a clear exit criterion — don't start the next phase until the current one's is met. Phases 2 and 3 are pure Flutter; Phase 3→4 is the handoff point where native work begins.

### Phase 0 — Requirements (complete)

- Covers: §1–9 of this SRS
- **Exit criteria:** scope is frozen, all FRs are agreed, no-monetization decision is final

### Phase 1 — Design

- 1.1 System architecture sign-off: confirm the shared-cache data flow in §4 before writing any code
- 1.2 UI/theme design: Home, Add, Detail screens — the cream/charcoal/green direction and hero-shot pattern
- 1.3 Widget layout design (matches app card style, §4.4 refresh strategy confirmed)
- 1.4 Siri voice UX: exact spoken copy for found / not-found / ambiguous-match cases (FR5.3)
- **Deliverable:** approved screen mockups + the architecture diagram in §4.1
- **Exit criteria:** happy with the visual direction and data flow before touching Xcode or a Flutter project

### Phase 2 — Core implementation (Flutter, offline app only)

Maps to FR1–FR3

- 2.1 Data layer: local DB schema (sqflite/Drift), Item model (§5)
- 2.2 Home/Search screen — static list first, then live filter (FR2)
- 2.3 Add Item flow + persistence (FR1.1–1.2)
- 2.4 Item Detail / Edit / Delete (FR1.2–1.3)
- 2.5 Photo capture + local storage (FR3)
- **Deliverable:** a fully usable standalone app — no widget, no Siri yet
- **Exit criteria:** you can add, search, edit, delete, and photograph items reliably offline

### Phase 3 — Shared data layer (integration foundation)

Maps to §4.1–4.4

- 3.1 Provision one App Group ID across all three targets (main app, widget, intents extension) — §4.2
- 3.2 Flutter write-through: flattened JSON snapshot written to the shared container via `home_widget` on every mutation (FR1.4)
- 3.3 Deep-link scheme wiring (`wdipit://item/{id}`, `wdipit://add`) — §4.3
- **Deliverable:** the shared cache reliably reflects app state immediately after every mutation
- **Exit criteria:** confirm (via logging or a native test harness) that an edit in the Flutter app is visible in the shared JSON with no delay — this is the foundation everything native depends on

### Phase 4 — Native extensions (Swift)

Maps to FR4, FR5, FR7

- 4.1 Widget Extension: recents list, tap-to-open, tap-to-add, empty state (FR4)
- 4.2 App Intents Extension: `FindItemLocationIntent`, matching logic, spoken dialog, `NSSiriUsageDescription` (FR5)
- 4.3 Spotlight indexing: index on mutation, deep link on tap (FR7)
- **Deliverable:** widget live on the home screen, "Hey Siri, where's my X" answering with no app launch, items appearing in system search
- **Exit criteria:** all three native surfaces read live data correctly and none of them require the app to be open

### Phase 5 — Testing & QA

- 5.1 Unit tests: DB layer, search filter, Siri matching/fuzzy logic (FR5.3)
- 5.2 Integration tests: mutation → shared cache → widget reload chain; mutation → Spotlight index chain
- 5.3 Manual device testing: widget in light/dark mode and multiple sizes, Siri phrasing variations, photo capture on real hardware, offline behavior, device-backup/restore behavior (§7 reliability note)
- 5.4 Accessibility pass: VoiceOver labels, Dynamic Type (§7)
- **Deliverable:** a pass/fail test log and known-issues list
- **Exit criteria:** no critical bugs open; Siri find succeeds for the range of natural phrasings tested

### Phase 6 — Release prep & deployment

Maps to §8

- 6.1 App icon, screenshots (using the hero-shot marketing pattern from Phase 1), App Store listing copy and keywords
- 6.2 Privacy label, Info.plist usage strings, App Group entitlements review across all targets
- 6.3 Reviewer notes explaining how to test the Siri flow
- 6.4 Submit for App Review
- **Deliverable:** app live on the App Store
- **Exit criteria:** passes review, ideally on the first submission

### Phase 7 — Post-launch / maintenance

- Monitor crash reports via Xcode Organizer (no third-party analytics SDK, consistent with the local-only privacy stance)
- Watch real usage to decide whether §9 backlog items (categories, sync, Siri add-flow) are actually worth building
- Set a bug-fix vs. new-feature cadence rather than letting scope creep back in

## 11. Known v1 Risks

- **Siri fuzzy-match false positives** at small item-name distances ("charger" vs "charger 2") — acceptable for v1, revisit matching quality post-launch based on real use.
- **App Review unfamiliarity with the Siri flow** — mitigated by explicit reviewer notes (§8).
- **Shared-cache write timing** — if the JSON rewrite isn't synchronous with the DB write, widget/Siri could briefly show stale data after an edit. Keep the write-through in FR1.4 unconditional and immediate, not batched.
