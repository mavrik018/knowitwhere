# knowitwhere

Local-only iOS app (Flutter + native Swift extensions) for remembering where you put things. Requirements: `docs/SRS.md`.

**To finish the project, follow `docs/HANDOFF.md` task by task.** It covers the current state, architecture, remaining work, and the exact steps for the Xcode, Siri, screenshots, public pages and App Store parts.

## Rules

- No AI attribution: no `Co-Authored-By` trailers in commits, no "Generated with Claude Code" in PR descriptions.
- Work on a branch, open a PR that `Closes #N`, wait until CI has finished and passed, then `gh pr merge N --merge --delete-branch`.
- The CI iOS build is skipped on pull requests. For `ios/` changes, run `gh workflow run CI --ref <branch>` and check that run too.
- Before committing: `dart format lib test`, `flutter analyze` (no issues), `flutter test` (all pass). For Swift changes: `swift test` in `ios/KnowItWhereKit`.
- Don't add scope beyond the SRS. New ideas go to issue #26 (v1 backlog).
- Sizing (phone): every in-app dimension uses flutter_screenutil (`.w/.h/.r/.sp`) against the 411×914 design; text follows the iOS HIG scale in `lib/theme/app_theme.dart`. The onboarding screen keeps fixed sizes on purpose.
- iPad is a structural redesign, not scaling. `lib/layout/window_size.dart` picks the tier by **window width** (never device model): compact < 600 = phone UI, medium 600–899 = navigation rail, expanded ≥ 900 = sidebar + side inspector. On wide windows ScreenUtil runs at 1.0 (`designSizeFor` in `lib/app.dart`), so type and touch targets stay phone-sized; only spacing and structure change. Don't scale sizes up for tablets. Reuse the leaf widgets (cards, rows, `ItemDetailContent`) and change their parents. Add/Edit open as modal cards (`DialogPage`) on wide windows.
- The user does manual device testing at the end. Don't block on it; collect items for the final pass.

## Commands

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after changing Drift tables
flutter analyze && flutter test
flutter build ios --debug --no-codesign
(cd ios/KnowItWhereKit && swift test)
flutter test tool/screenshots/screenshots_test.dart --update-goldens   # screen previews
```
