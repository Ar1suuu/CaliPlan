# CaliPlan

CaliPlan is an offline-first calisthenics workout planner for Android, built with
Flutter (Dart). Browse bodyweight exercises from the public wger API, save
favourites, build weekly workouts with sets and reps, and get a daily reminder
with the day's plan.

**Track:** Flutter (Dart) · **Course:** Android Development · **Demo:** 14.12.2026

## Status

Scaffold stage (build-order steps 1–2):

- [x] Flutter project, packages, layered folders, lints
- [x] Material 3 light and dark theme
- [x] `go_router` shell with three stateful tabs and placeholder screens
- [ ] Domain models, wger DTOs, mapper
- [ ] drift schema, DAOs, repositories, offline-first feed
- [ ] Workouts and the workout form
- [ ] Settings persistence, daily reminder
- [ ] Tests to target, animation/accessibility pass, release APK

## Tech stack

| Concern | Package |
| --- | --- |
| State and DI | `flutter_riverpod` |
| Navigation | `go_router` |
| Networking | `dio`, `retrofit`, `json_serializable` |
| Database | `drift`, `drift_flutter` |
| Key-value storage | `shared_preferences` |
| Images | `cached_network_image` |
| Background work | `workmanager`, `flutter_local_notifications` |
| Tests | `flutter_test`, `mocktail` |
| Lints | `flutter_lints` |

## Getting started

Requirements: Flutter 3.50+ (Dart 3.14+), Android SDK with the API 37
platform, and a device or emulator.

```bash
flutter pub get
flutter run
```

No API key is needed: the wger API is public for reads.

Useful checks before every commit:

```bash
flutter analyze
flutter test
```

### Recommended IDE

VS Code is the primary editor (fast, excellent Dart/Flutter extension). Keep
Android Studio installed for the emulator manager, Logcat and native Android
debugging. The project opens in either IDE with no extra setup.

## Project structure

```text
lib/
  main.dart          app entry point
  app.dart           MaterialApp.router, themes, theme mode
  core/              constants and shared extensions
  di/                Riverpod provider graph
  domain/            plain Dart models and Result<T>
  data/              remote API, drift database, mappers, repositories
  ui/                theme, router, widgets, feature screens/notifiers
  background/        Workmanager callback, scheduler, notifications
test/                fakes, helpers, fixtures, unit and widget tests
docs/                proposal, architecture, screenshots
```

Full details: [docs/architecture.md](docs/architecture.md).

## API

CaliPlan reads exercises from the public
[wger API](https://wger.de/api/v2/) at `https://wger.de/api/v2/`.
The main endpoint is `exerciseinfo/` with `language=2` (English). Responses are
cached in drift so the exercise feed works in airplane mode.

## Core requirement coverage

This table is completed as features land (step 10 of the build order).

| # | Requirement | Planned location | Status |
| --- | --- | --- | --- |
| 1 | 4+ screens incl. list, detail, form | `lib/ui/` | Shell + placeholders |
| 2 | Lazy list/grid from real data | `lib/ui/exercises/` | Planned |
| 3 | Material 3 light/dark, theme colours | `lib/ui/theme/app_theme.dart` | Done |
| 4 | Animation (Hero, controller) | `lib/ui/exercises/` | Planned |
| 5 | Accessibility | all screens | Planned |
| 6 | Lifecycle and refresh on resume | `lib/app.dart` | Planned |
| 7 | State holders, no logic in UI | `lib/ui/*/` | Example notifier done |
| 8 | Bottom tabs + argument route | `lib/ui/router/app_router.dart` | Done |
| 9 | Loading/error/empty/data states | `lib/ui/widgets/` | Planned |
| 10 | Retrofit-style API + typed JSON | `lib/data/remote/` | Planned |
| 11 | Repository layer + injected DI | `lib/data/repositories/`, `lib/di/` | Folders ready |
| 12 | Relational DB + saved setting | `lib/data/local/` | Planned |
| 13 | Background task + notification | `lib/background/` | Planned |

## Tests

```bash
flutter test
```

The scaffold currently has widget tests for tab navigation and theme switching.
Unit and repository tests are added with their features (target: 8 unit, 4 widget).

## Git conventions

Commit prefixes: `feat:`, `fix:`, `test:`, `refactor:`, `docs:`, `chore:`.
Never commit `key.properties`, keystores or `.env` files.
