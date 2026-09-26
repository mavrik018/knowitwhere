# Handoff runbook: finishing knowitwhere on a Mac

**For Claude Code:** this is your brief. The project was built in an earlier session that you can't see, so everything you need is here and in the files it links to. Work through the tasks **in order**. Before each task, read the files it names. After each task, run its checks, open a PR, and wait for CI before merging. When a step needs the user (Xcode GUI clicks, Apple account, App Store Connect), tell them exactly what to click and wait.

**For the user:** open Terminal in the repo folder, run `claude`, and say:
> Read docs/HANDOFF.md and follow it to finish the project.

---

## 1. What the app is

knowitwhere is a local-only iOS app for remembering where you put physical things. You find them again by typing, from a home-screen widget, or by asking Siri. Requirements: [docs/SRS.md](SRS.md), written under the working title "Where Did I Put That?". Every feature must pass the SRS rule: *does this make "add" or "find" faster?* Anything else belongs in the backlog (SRS §9, issue #26). Don't add scope.

| | |
| --- | --- |
| Repo | https://github.com/mavrik018/knowitwhere (private until launch) |
| Bundle ID | `com.AandMapps.knowitwhere` |
| App Group | `group.com.AandMapps.knowitwhere` |
| URL scheme | `knowitwhere://add`, `knowitwhere://item/{id}` |
| Widget kind | `KnowItWhereWidget` |
| Min iOS | 17.0 |
| Flutter | 3.44.1 stable (Dart 3.12) |

### Architecture (SRS §4)

```
Flutter app (source of truth: Drift/SQLite in Documents, photos by relative path)
  │ after every add / edit / delete, and at launch:
  ├─ SharedCacheSink ─► App Group UserDefaults key "items" = JSON [{id,name,location,updatedAt}]
  │                     + reload widget timeline "KnowItWhereWidget"
  └─ SpotlightSink ───► ios/Runner/SpotlightPlugin.swift (Core Spotlight)
Widget extension ─┐
Siri extension  ──┴─ read-only from the App Group JSON via ios/KnowItWhereKit
```

### Where things are

| Path | What |
| --- | --- |
| `lib/data/` | Drift DB (`database.dart`, generated `database.g.dart` committed), `item_repository.dart` (mutations call `ItemChangeSink`), `photo_store.dart` |
| `lib/platform/` | `shared_cache.dart` (App Group writer), `spotlight.dart`, `deep_links.dart` |
| `lib/features/` | `home/` (Board / Index / Locations, search; `tablet_home.dart` is the iPad shell), `item_form/`, `item_detail/` (`item_inspector.dart` is the iPad side pane), `onboarding/` |
| `lib/layout/` | iPad support: `window_size.dart` (compact / medium / expanded by window width), `dialog_page.dart` (Add/Edit as modal cards), `hover_lift.dart` (pointer hover) |
| `lib/theme/app_theme.dart` | Cream / ink / orange tokens; `AppPalette` extension; iOS HIG type scale in `.sp` (ScreenUtil design size 411×914, set in `lib/app.dart`) |
| `ios/Runner/` | `SpotlightPlugin.swift`, `Runner.entitlements` (App Group), `Info.plist` (usage strings, URL scheme) |
| `ios/KnowItWhereKit/` | Swift package: `KnowItWhereCore` (cache reader, `ItemMatcher`, `VoiceCopy`, `DeepLink`), `KnowItWhereWidgetUI` (the widget), `KnowItWhereIntents` (`FindItemLocationIntent`). XCTests in `Tests/` |
| `docs/phase-4-xcode-setup.md` | Step-by-step Xcode target creation with the exact entry files |
| `docs/siri-voice-ux.md` | Siri phrases, spoken copy, matching rules |
| `docs/app-store.md` | Listing copy, keywords, privacy answers, reviewer notes |
| `site/` | Public home / privacy / support pages (GitHub Pages, see Task 6) |
| `tool/` | `make_app_icon.py`, `cut_out_mascot.py`, `screenshots/` (renders `docs/screens`) |

## 2. Working agreements (follow these)

- **No AI attribution anywhere:** no `Co-Authored-By` trailers in commits, no "Generated with Claude Code" line in PRs.
- **Branch → PR → CI → merge.** Use a branch per task (`phase-4/...`, `phase-6/...`). The PR body links issues with `Closes #N`. Merge with `gh pr merge N --merge --delete-branch` once every check passes. Wait until checks have actually *registered and finished*; `gh pr checks --watch` can return early.
- **CI:** `.github/workflows/ci.yml` runs format, analyze and tests on PRs. Its **iOS build job is skipped on PRs** (macOS minutes cost 10×), so for any change under `ios/`, also run `gh workflow run CI --ref <branch>` and check that run. `swift.yml` runs the Swift package tests when `ios/KnowItWhereKit/**` changes.
- **Before every commit:** `dart format lib test`, `flutter analyze` (must print "No issues found"), `flutter test` (all green). For Swift: `cd ios/KnowItWhereKit && swift test`.
- **The user tests on a device only once everything is built.** Don't block on manual testing. Collect items for the final pass (Task 7).
- Code style: match the surrounding code; comments explain *why*; tests alongside changes.

## 3. First-time setup on the Mac

```bash
flutter --version            # expect 3.44.x; otherwise: flutter upgrade / install 3.44.1
gh auth status               # log in with: gh auth login
git pull
flutter pub get
flutter analyze && flutter test
cd ios/KnowItWhereKit && swift test && cd ../..
flutter build ios --debug --no-codesign
```

If all of these pass, start Task 0.

---

## Task 0: App icon (done)

The app icon is the squirrel. The master is `design/app-icon/app-icon-master.png` (1024×1024, no transparency); `python tool/make_app_icon.py` regenerates every iOS size and `site/icon.png`. Don't use `flutter_launcher_icons`: it breaks `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` in `project.pbxproj` and adds Android files. The shipping target is iOS only. `android/` exists for the user's local testing on an Android phone; keep it, but don't build Android features or submit to Google Play (out of scope, SRS §9).

## Task 1: Add the widget and Siri extension targets (user + Claude)

**Issues:** #14, #15, #22. **Read first:** `docs/phase-4-xcode-setup.md`.

The user does the Xcode GUI steps while you guide them one step at a time from that doc. Then:

1. Check `project.pbxproj`:
   - The targets `KnowItWhereWidgetExtension` and `KnowItWhereSiri` exist.
   - Both link their package product (`KnowItWhereWidgetUI` / `KnowItWhereIntents`).
   - `IPHONEOS_DEPLOYMENT_TARGET = 17.0`.
   - Each has an entitlements file with `group.com.AandMapps.knowitwhere`.
   - **Embed Foundation Extensions** comes before **Thin Binary** in the Runner build phases.
2. Check that the entry files match the doc (`KnowItWhereWidgetBundle.swift`, `KnowItWhereSiri.swift` with `AppShortcutsProvider` and `includedPackages`).
3. Add `NSSiriUsageDescription` to the extension's Info.plist if Xcode created one. The Runner already has it.
4. `flutter build ios --debug --no-codesign`, then `flutter run` on the user's iPhone.
5. Quick device check with the user:
   - Add an item; the widget updates.
   - A widget row opens that item.
   - "Hey Siri, find something in knowitwhere" → "What are you looking for?" → spoken answer.
6. Commit the `ios/` changes, PR (closes #14, #15), dispatch CI for the iOS build, merge.

If the GUI isn't available, an alternative is scripting the targets with the `xcodeproj` Ruby gem. That's riskier, so prefer the GUI.

## Task 2: One-sentence Siri phrase (Claude)

**Goal (agreed with the user):** "Hey Siri, **where's my passport in knowitwhere**?" → spoken location, with no follow-up question and no app launch. The onboarding and detail screens already advertise this phrase (`lib/widgets/siri_bar.dart`, `lib/features/home/smart_tip.dart`, `lib/features/item_detail/item_detail_screen.dart`).

**Why it needs new work:** App Shortcut phrases can only contain `AppEntity`/`AppEnum` parameters, never a free `String`. The current `FindItemLocationIntent` takes a String, so Siri has to ask a follow-up question. Read `docs/siri-voice-ux.md`.

**Build it in `ios/KnowItWhereKit/Sources/KnowItWhereIntents/`:**

1. `ItemEntity: AppEntity` with `id` (item id), `name`, `location`. `displayRepresentation` is the name. `typeDisplayRepresentation` is "Item".
2. `ItemEntityQuery: EntityStringQuery`:
   - `entities(for:)` looks up ids in `SharedCache.load()`.
   - `entities(matching:)` returns **at most one** entity: `ItemMatcher.bestMatch(...)`. v1 has no disambiguation (SRS §9).
   - `suggestedEntities()` returns all items, most recent first. Siri learns the spoken names from these.
3. `WhereIsItemIntent: AppIntent` with `@Parameter var item: ItemEntity` and `openAppWhenRun = false`. `perform()` returns `.result(value: location, dialog: VoiceCopy.found(...))`. Reuse `VoiceCopy`; add a `found(item:)` overload if needed.
4. In the Siri extension's `AppShortcutsProvider` (from Task 1), add phrases with the entity:
   - `"Where's my \(\.$item) in \(.applicationName)"`
   - `"Where is my \(\.$item) in \(.applicationName)"`
   - `"Where did I put my \(\.$item) in \(.applicationName)"`
   - `"Find my \(\.$item) in \(.applicationName)"`

   Keep the existing `FindItemLocationIntent` shortcut as the fallback.
5. **Keep Siri's item names current:** `AppShortcutsProvider.updateAppShortcutParameters()` has to run whenever items change. Check Apple's current documentation for where it may be called from when the provider lives in an App Intents extension. Options, in order of preference:
   - (a) The app calls it after each mutation through a new method on the existing Spotlight channel (`SpotlightPlugin.swift`: add `"updateSiri"`, called from `SpotlightSink` or a new small sink). This only works if the provider type is reachable from Runner, e.g. by moving the provider into the package and linking `KnowItWhereIntents` to Runner.
   - (b) The extension calls it inside `perform()` and in `suggestedEntities()`.

   Pick the option Apple's docs support for iOS 17+, document the choice in `docs/siri-voice-ux.md`, and keep FR5.3 (no app launch).
6. **Tests:** XCTests for `ItemEntityQuery.entities(matching:)` (uses the matcher, returns ≤ 1) and for the new voice copy. `swift test` must pass, and the `Swift kit` CI must be green.
7. **Device check with the user:**
   - Say "Hey Siri, where's my passport in knowitwhere?" with and without "my", and with a fuzzy name ("hitmi cable").
   - Add a new item, then ask for it straight away (checks that Siri's names update).
8. If the one-sentence phrase proves unreliable on the device, switch the advertised phrase in the three Dart files back to "Hey Siri, find something in knowitwhere" and say so in the PR.

## Task 3: Widget and Spotlight polish on the device (Claude + user)

**iPad check (also here):** run on an iPad or the iPad simulator and verify:
- Landscape: sidebar, 4-column board, and a tapped item opens in the right-hand inspector
- Portrait: navigation rail and a 3-column board; items open as a two-column page
- Split View / Slide Over: at 1/3 width the phone layout appears, at 1/2 width the rail layout
- Magic Keyboard: ⌘N opens Add, ⌘F focuses search, Esc closes the inspector or the Add/Edit card; cards lift on trackpad hover
- Previews of every layout are in `docs/screens/ipad_*.png`


Check the widget in light and dark mode, both sizes, at large Dynamic Type, and with an empty state. Check that Spotlight shows items and that a tap opens the detail screen, including when the app is closed (cold start). Fix whatever turns up. Record results in issue #19.

## Task 4: App Store screenshots (Claude + user)

**Issue:** #21. Run the app on the **iPhone 16 Pro Max / 6.9" simulator** (1320×2868). Seed realistic items with photos, set dark or light mode deliberately, and capture with `xcrun simctl io booted screenshot <file>.png`. Follow the caption plan in `docs/app-store.md` (onboarding hero, board, Siri, widget, detail). Put the files in `docs/app-store-screenshots/`. Captioned marketing frames are optional.

## Task 5: Final manual test pass (user, guided by Claude)

**Issues:** #19, #20. Walk the user through this checklist and file a GitHub issue for every failure:

- [ ] Add, edit, delete (swipe and detail), undo; search on name and location
- [ ] Photo from the camera and from the library; the photo survives an app restart
- [ ] Widget: updates immediately after each change; a row opens the item; empty space opens Add
- [ ] Siri: one-sentence phrase, follow-up phrase, not-found case, nothing-saved case
- [ ] Spotlight: search, tap result (app running and app closed)
- [ ] Airplane mode: everything works
- [ ] VoiceOver: rows read "{name}, stored in {location}"; the Delete custom action works
- [ ] Largest Dynamic Type: no clipped text on every screen
- [ ] Backup and restore (optional): items return and the widget and Siri work after a restore

## Task 6: Public pages for App Store Connect (Claude, after the user makes the repo public)

The pages are already written in `site/` (`index.html`, `privacy.html`, `support.html`). `.github/workflows/pages.yml` deploys them, but only once the repo is public; free GitHub Pages needs a public repo.

1. The user makes the repo public (Settings → General → Danger Zone), or run `gh repo edit mavrik018/knowitwhere --visibility public --accept-visibility-change-consequences` **only with the user's explicit OK**.
2. Enable Pages with GitHub Actions as the source: `gh api -X POST repos/mavrik018/knowitwhere/pages -f build_type=workflow` (ignore "already exists").
3. `gh workflow run Pages`. When it finishes, open and check:
   - https://mavrik018.github.io/knowitwhere/
   - https://mavrik018.github.io/knowitwhere/privacy.html
   - https://mavrik018.github.io/knowitwhere/support.html
4. The support page uses GitHub Issues as the contact. Ask the user whether they also want a support email shown, and add it if so.
5. Put the URLs into `docs/app-store.md`. Close #22 when the entitlements are verified too.

## Task 7: Archive and submit (user, guided by Claude)

**Issue:** #24. Checklist in `docs/app-store.md`:

1. Bump the version in `pubspec.yaml` if needed (`1.0.0+1`).
2. Signing: the same team on all three targets; the App Group is registered.
3. `flutter build ipa`, or Xcode → Product → Archive (Any iOS Device) → Distribute → App Store Connect.
4. App Store Connect:
   - Listing copy and keywords from `docs/app-store.md`
   - Screenshots from Task 4
   - Privacy "Data Not Collected"
   - Privacy and support URLs from Task 6
   - Reviewer notes from `docs/app-store.md`. Update them with the one-sentence Siri phrase if Task 2 shipped
5. Submit. Track any review feedback as issues.

## Task 8: After launch

Issue #25: crash reports via Xcode Organizer only (no analytics SDKs); review backlog #26 only against real usage.

---

## Known gotchas

- **Drift in widget tests:** create the DB with `DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true)`. Do database writes in the test zone, **not** inside `tester.runAsync`, or they hang.
- **Screens below the fold** aren't built in tests. Use `scrollTo` / `scrollAndTap` from `test/test_helpers.dart`.
- **Onboarding layout:** don't put `LayoutBuilder` inside anything that measures intrinsic height (the onboarding uses `IntrinsicHeight`).
- **Screen previews:** `flutter test tool/screenshots/screenshots_test.dart --update-goldens` writes `docs/screens/*.png`, using Roboto from the SDK.
- **Flutter + app extensions:** the "Cycle inside Runner" build error means the **Embed Foundation Extensions** phase must move above **Thin Binary**.
- **`ItemMatcher` threshold (0.6):** close names like "charger" / "charger 2" are a known v1 risk (SRS §11). Exact match always wins.
