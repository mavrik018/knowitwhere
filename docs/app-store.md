# App Store submission (SRS §8, Phase 6)

Draft copy and answers for App Store Connect. Field limits are noted where Apple enforces them.

## Listing (6.1)

| Field | Value |
| --- | --- |
| Name (30) | KnowItWhere |
| Subtitle (30) | Remember where you put things |
| Bundle ID | com.AandMapps.knowitwhere |
| Primary category | Productivity |
| Secondary category | Utilities |
| Price | Free, no in-app purchases (SRS §2.1) |
| Age rating | 4+ (no objectionable content) |

**Keywords (100, comma-separated, no spaces; the app name is indexed automatically)**

```
where did i put,storage tracker,item finder,inventory,declutter,find my stuff,organizer,lost,stash
```

(98 characters.)

**Promotional text (170)**

> Put it somewhere safe, then forgot where? Save it in seconds, then find it by typing, glancing at your home screen, or asking Siri.

**Description (4000)**

> KnowItWhere remembers where you put things, so you don't have to.
>
> Passports, spare keys, cables, warranty papers, the tent in the loft: save what it is and where it went, with a photo if you like. When you need it again, find it in seconds.
>
> FIND IT THREE WAYS
> • Type: live search as you type, best matches first
> • Glance: a home-screen widget shows what you put away most recently
> • Ask: "Hey Siri, where's my passport in KnowItWhere?" — Siri tells you where it is, without opening the app
>
> FAST TO ADD
> • Just a name and a place — free text, no folders to set up
> • Optional photo of the spot
> • Edit when you move it, swipe to delete
>
> PRIVATE BY DESIGN
> • Everything stays on your iPhone. No account, no cloud, no tracking, no ads
> • Works fully offline
> • Included in your normal iPhone backup
>
> Also shows up in Spotlight search.

**Screenshots:** use the hero-shot pattern from Phase 1: a large caption over a device frame, cream background. Required size is 6.9" (1320 × 2868); Apple scales it down for smaller displays. Suggested set:

1. "Never lose it again" (onboarding hero with the squirrel)
2. "Where is my…?" (home board with photo cards)
3. "Ask Siri" ("Hey Siri, where's my passport in KnowItWhere?" and the spoken answer)
4. "Right on your home screen" (medium widget)
5. "Private. On your phone only." (detail screen)

Draft renders of the in-app screens are in `docs/screens/`.

## App Privacy (6.2)

App Store Connect → App Privacy → **Data Not Collected**. There are no network calls, analytics SDKs or accounts (SRS §7). Nothing leaves the device apart from the user's own iCloud/iTunes device backup, which Apple doesn't count as collection.

**Privacy policy URL:** https://mavrik018.github.io/knowitwhere/privacy.html

**Support URL:** https://mavrik018.github.io/knowitwhere/support.html

**Marketing URL (optional):** https://mavrik018.github.io/knowitwhere/

The pages live in `site/` and are published by `.github/workflows/pages.yml` once the repo is public (see Task 6 in `docs/HANDOFF.md`). Check that each URL loads before you submit.

### Usage strings in Info.plist

| Key | Text |
| --- | --- |
| NSCameraUsageDescription | Used to photograph where you stored an item. |
| NSPhotoLibraryUsageDescription | Used to attach a photo of where you stored an item. |
| NSSiriUsageDescription | Lets you ask Siri where you put something. |

### Entitlements checklist

- [ ] `group.com.AandMapps.knowitwhere` ticked on Runner and the widget extension (Siri runs inside the app, so there is no Siri extension)
- [ ] Both share team `PUS7W2V7BL`; bundle IDs are `com.AandMapps.knowitwhere` and `com.AandMapps.knowitwhere.KnowItWhereWidget`

## Review notes (6.3)

Paste into App Store Connect → App Review Information → Notes:

> KnowItWhere stores everything locally; there is no account or login.
>
> To test the core flow:
> 1. Open the app and tap "Add item". Enter "Passport" as the name and "Desk drawer" as the location, then tap "Save item".
> 2. Type "pass" in the search field. The item appears.
>
> To test Siri (the main feature; please test on a device with Siri enabled):
> 1. After step 1 above, say: "Hey Siri, where's my passport in KnowItWhere?"
> 2. Expected: Siri says "Passport is here: Desk drawer." The app does not open.
> 3. Alternatively, say "Hey Siri, find something in KnowItWhere". Siri asks "What are you looking for?"; say "Passport" and Siri gives the same answer.
>
> Both actions are also available in the Shortcuts app ("Where Is It?" and "Find an Item").
>
> To test the widget: add the "Recent items" widget from the home-screen widget gallery. It shows saved items; tapping one opens it in the app.
>
> To test Spotlight: swipe down on the home screen and search "Passport". Tapping the result opens the item.

## Submission (6.4)

- [ ] Archive from Xcode (Product → Archive) with the Runner scheme, *Any iOS Device*
- [ ] Upload, then attach the build in App Store Connect
- [ ] Fill in listing, privacy, review notes above; submit
