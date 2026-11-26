# CaliPlan: Architecture and Stack

Build blueprint · follow this while creating the project · Flutter (Dart) track

The proposal says what we build and why. This document says how: layers, folders, packages, data model, state, navigation, background work and tests. Copy it into `docs/architecture.md` in the repository once the project exists.

## 1. Non-negotiable rules

1. The UI renders state only. Widgets never import `dio`, `retrofit`, `drift`, `shared_preferences` or `workmanager`.
2. All data access goes through repositories. Repositories are created only in `lib/di/providers.dart`, never inside UI code.
3. Reads are streams. The UI watches drift `watch()` queries, so a database write updates the screen with no manual refresh.
4. No `Color(0x...)` literals outside `app_theme.dart`. No HTTP or SQL in any screen file.
5. Every screen that loads data shows four distinct states: loading, error with retry, empty and data.
6. Everything must be testable by overriding providers with fakes.

Quick checks to run before every demo (both must print nothing):

```
grep -rE "package:(dio|retrofit|drift|shared_preferences|workmanager)" lib/ui
grep -rE "Color\(0x" lib/ui lib/di lib/data
```

## 2. Layers

```
UI screens (widgets, render state only)
   | events
State holders (Riverpod Notifier / StreamNotifier / AsyncNotifier)
   | calls
Repositories (one source of truth, injected by Riverpod)
   |-- Remote: WgerApi (dio + retrofit + json_serializable)
   |-- Local: AppDatabase (drift) + SharedPreferences

Background task (workmanager) --> own AppDatabase + WorkoutRepository --> notification
```

| Layer | Folder | Responsibility | May import |
| --- | --- | --- | --- |
| UI | `lib/ui` | Render state, send events | Flutter, Riverpod, domain, providers |
| State holders | `lib/ui/<feature>/*_notifier.dart` | Hold screen state, call repositories | domain, repository interfaces |
| Repositories | `lib/data/repositories` | Single source of truth, map DTOs and rows to domain models | `data/remote`, `data/local`, domain |
| Data sources | `lib/data/remote`, `lib/data/local` | HTTP and SQL | dio, retrofit, drift |
| Domain | `lib/domain` | Plain Dart models, `Result<T>` | nothing |
| DI | `lib/di` | Provider graph | everything |
| Background | `lib/background` | Worker, scheduler, notifications | data, domain |

Repositories return domain models only. DTOs and drift row classes never leave the data layer.

## 3. Folder structure

```
lib/
  main.dart                  runApp, ProviderScope overrides, Workmanager init
  app.dart                   MaterialApp.router, theme, AppLifecycleListener
  di/
    providers.dart           infrastructure and repository providers
  domain/
    exercise.dart            Exercise
    workout.dart             WorkoutSummary, WorkoutDetail, WorkoutLine, WorkoutDraft
    result.dart              sealed Result<T>: Success / Failure
    reminder_settings.dart   ReminderSettings with a ({int hour, int minute}) record
  data/
    remote/
      wger_api.dart          @RestApi interface
      dto/                   exercise_info_dto.dart (+ generated .g.dart)
    local/
      app_database.dart      @DriftDatabase, schemaVersion, migration strategy
      tables.dart            Exercises, Favorites, Workouts, WorkoutExercises
      daos/                  exercise_dao.dart, workout_dao.dart
    mappers/                 exercise_mapper.dart
    repositories/            exercise_repository.dart, workout_repository.dart, settings_repository.dart
  ui/
    theme/                   app_theme.dart
    router/                  app_router.dart
    widgets/                 async_value_view.dart, exercise_card.dart, error_state.dart, empty_state.dart
    exercises/               exercises_screen.dart, exercises_notifier.dart, exercise_filter_notifier.dart,
                             sync_notifier.dart, exercise_detail_screen.dart
    workouts/                workouts_screen.dart, workouts_notifier.dart,
                             workout_form_screen.dart, workout_form_notifier.dart
    settings/                settings_screen.dart, theme_mode_notifier.dart, reminder_notifier.dart
  background/                callback_dispatcher.dart, reminder_scheduler.dart, notification_service.dart
  core/                      extensions.dart, constants.dart
test/                        fakes/, helpers/, fixtures/, unit/, widget/
docs/                        proposal.md, architecture.md, screenshots/
```

Dart 3 features we use on purpose: null safety everywhere, a generic sealed `Result<T>`, a record for the reminder time, and extensions such as `MuscleLabel` on `String` and `PlainText` on `String` (strips HTML).

## 4. Stack and setup

| Concern | Package | Role in the app |
| --- | --- | --- |
| State and DI | `flutter_riverpod` | Notifiers and the provider graph |
| Navigation | `go_router` | `StatefulShellRoute` for tabs, route arguments |
| Network | `dio`, `retrofit`, `json_annotation` (dev: `retrofit_generator`, `json_serializable`, `build_runner`) | Typed API client and DTOs |
| Database | `drift`, `drift_flutter` (dev: `drift_dev`) | Tables, DAOs, streams, migrations |
| Key-value | `shared_preferences` | Theme mode and reminder settings |
| Images | `cached_network_image` | Cached photos with placeholder and error widget |
| Background | `workmanager`, `flutter_local_notifications` | Daily reminder and notification |
| Tests | `flutter_test` (SDK), `mocktail` | Unit and widget tests |
| Lints | `flutter_lints` (in the template) | `flutter analyze` with 0 issues |

Setup commands (let pub choose the current stable versions, then commit `pubspec.lock`):

```
flutter create caliplan --platforms=android
cd caliplan
flutter pub add flutter_riverpod go_router dio retrofit json_annotation cached_network_image shared_preferences drift drift_flutter workmanager flutter_local_notifications
flutter pub add --dev build_runner retrofit_generator json_serializable drift_dev mocktail
dart run build_runner build --delete-conflicting-outputs
```

Follow each package's current setup page for the Android parts (drift sqlite setup, `flutter_local_notifications` desugaring and manifest entries, `workmanager` Android setup). Commit generated `*.g.dart` files so the project builds right after cloning, and exclude them from analysis:

```yaml
analyzer:
  exclude:
    - "**/*.g.dart"
```

## 5. Data layer

### 5.1 Remote API (wger)

- Base URL `https://wger.de/api/v2/`, public read access, no key.
- Main endpoint: `exerciseinfo/` with `language=2` (English), `limit` and `offset`. Filter by equipment for calisthenics: bodyweight and pull-up bar. Look up ids with `equipment/`; get muscles with `muscle/`.
- Verify everything first: `curl "https://wger.de/api/v2/exerciseinfo/?language=2&limit=5"`. Save the response as `test/fixtures/exercises.json` and build the DTOs from the real JSON, not from memory.
- DTOs use `@JsonSerializable(fieldRename: FieldRename.snake)`. Every field that can be missing is nullable.

### 5.2 Mapping DTO to domain

One pure, tested function in `exercise_mapper.dart`:

- Pick the English translation, and skip entries without a name.
- Strip HTML tags from the description (the API returns `<p>` and `<ol>`).
- Pick the main image URL, or `null`.
- Store muscles and equipment as pipe-delimited text (for example `|Pectoralis major|Triceps brachii|`) so filters can use `LIKE '%|name|%'`.

### 5.3 Database (drift, schema v1)

| Table | Columns |
| --- | --- |
| `exercises` | `id` int primary key (API id), `name` text, `description` text, `category` text, `muscles` text, `equipment` text, `imageUrl` text nullable, `cachedAt` datetime |
| `favorites` | `exerciseId` int primary key, references `exercises.id`, `addedAt` datetime |
| `workouts` | `id` int auto-increment, `name` text (1 to 50 chars), `weekday` int nullable (1 = Monday to 7 = Sunday), `notes` text default empty, `createdAt` datetime |
| `workout_exercises` | `id` int auto-increment, `workoutId` references `workouts.id` on delete cascade, `exerciseId` references `exercises.id`, `sets` int default 3, `reps` int default 10, `position` int |

Rules: enable `PRAGMA foreign_keys = ON` in `beforeOpen`. Upsert exercises with `insertAllOnConflictUpdate` inside a batch or transaction, and never delete rows from `exercises` (favourites and workouts depend on them).

### 5.4 Key-value (shared\_preferences)

`theme_mode` (`light`, `dark`, `system`), `reminder_enabled` (bool), `reminder_hour` (int), `reminder_minute` (int).

### 5.5 Repository contracts

```dart
abstract interface class ExerciseRepository {
  Stream<List<Exercise>> watchExercises({String? muscle});
  Stream<Exercise?> watchExercise(int id);
  Stream<Set<int>> watchFavoriteIds();
  Stream<List<String>> watchMuscles();      // filter chips
  Future<Result<int>> refresh();            // API -> upsert, returns number of rows
  Future<void> toggleFavorite(int exerciseId);
}

abstract interface class WorkoutRepository {
  Stream<List<WorkoutSummary>> watchWorkouts();
  Stream<WorkoutDetail?> watchWorkout(int id);
  Future<int> save(WorkoutDraft draft);     // insert or update, returns id
  Future<void> delete(int id);
  Future<void> addExercise(int workoutId, int exerciseId, {int sets = 3, int reps = 10});
  Future<WorkoutDetail?> workoutForWeekday(int weekday); // used by the background worker
}

abstract interface class SettingsRepository {
  ThemeMode get themeMode;
  Future<void> setThemeMode(ThemeMode mode);
  ReminderSettings get reminder;            // enabled + ({int hour, int minute}) time
  Future<void> setReminder(ReminderSettings value);
}
```

`refresh()` never throws: it catches network errors and returns `Failure`, and a failed refresh never clears the cache.

## 6. State and dependency injection

Infrastructure and repository providers (all in `lib/di/providers.dart`):

| Provider | Type | Depends on |
| --- | --- | --- |
| `sharedPreferencesProvider` | `Provider<SharedPreferences>` | Overridden in `main()` after `await SharedPreferences.getInstance()` |
| `dioProvider` | `Provider<Dio>` | Base URL, timeouts, logging interceptor in debug only |
| `wgerApiProvider` | `Provider<WgerApi>` | `dioProvider` |
| `appDatabaseProvider` | `Provider<AppDatabase>` | `ref.onDispose(db.close)` |
| `exerciseRepositoryProvider` | `Provider<ExerciseRepository>` | `wgerApiProvider`, `appDatabaseProvider` |
| `workoutRepositoryProvider` | `Provider<WorkoutRepository>` | `appDatabaseProvider` |
| `settingsRepositoryProvider` | `Provider<SettingsRepository>` | `sharedPreferencesProvider` |
| `notificationServiceProvider` | `Provider<NotificationService>` | none |

State holders (one per screen, in `lib/ui/<feature>/`):

| State holder | Kind | State |
| --- | --- | --- |
| `ExerciseFilterNotifier` | `Notifier` | Selected muscle or none |
| `ExercisesNotifier` | `StreamNotifier` | `AsyncValue<List<Exercise>>` from `watchExercises`, rebuilt when the filter changes |
| `SyncNotifier` | `Notifier` | Sealed `SyncState`: `Idle`, `Syncing`, `Failed(message)`; method `refresh()` |
| `ExerciseDetailNotifier` | Family `StreamNotifier` keyed by id | `AsyncValue<Exercise?>` |
| `WorkoutsNotifier` | `StreamNotifier` | `AsyncValue<List<WorkoutSummary>>` |
| `WorkoutFormNotifier` | Family `Notifier` keyed by workout id (null for new) | Draft, field errors, dirty flag, save status |
| `ThemeModeNotifier` | `Notifier` | `ThemeMode`, persisted through the settings repository |
| `ReminderNotifier` | Async`Notifier` | `ReminderSettings`, loaded and changed asynchronously (request the notification permission, then schedule or cancel the worker) |

A small read-only `favoriteIdsProvider` (`StreamProvider<Set<int>>`) is fine for the heart icons. Check the Riverpod documentation for the family syntax of the version you install.

**Four screen states without extra widgets.** The feed combines the data stream and the sync state in one pure function, `exercisesViewState(AsyncValue<List<Exercise>>, SyncState)`, which returns a sealed `ExercisesViewState`:

- `Loading`: no items yet and syncing (or the stream is loading).
- `Failure`: no items and the sync failed, shown with a Retry button that calls `refresh()`.
- `Empty`: no items, sync finished, nothing matches the filter.
- `Content(items, offline)`: items exist; `offline` shows a notice if the last sync failed.

The widget only switches over this type, and the function is trivially unit-tested. The other screens use `AsyncValue.when` through the shared `AsyncValueView` widget (loading, error with retry, empty, data). It covers every data screen: the feed, the detail screen, the workouts tab, and the workout form when it opens an existing workout.

## 7. Navigation

`go_router` with `StatefulShellRoute.indexedStack` and a `NavigationBar`. Initial location: `/exercises`.

| Path | Screen | Notes |
| --- | --- | --- |
| `/exercises` | `ExercisesScreen` | Tab 1, filter chips, pull-to-refresh |
| `/exercises/:id` | `ExerciseDetailScreen` | Nested in tab 1, route argument, Hero image |
| `/workouts` | `WorkoutsScreen` | Tab 2 |
| `/workouts/new` | `WorkoutFormScreen` | Full screen (root navigator), create |
| `/workouts/:id/edit` | `WorkoutFormScreen` | Full screen, edit |
| `/settings` | `SettingsScreen` | Tab 3 |

Back behaviour: detail pops to the feed with its scroll position kept (`PageStorageKey` on the list). The form uses `PopScope` to confirm discarding unsaved changes. Add to workout from the detail screen opens a bottom sheet with the user's workouts (default 3 sets of 10 reps) and calls `addExercise`.

## 8. UI conventions

**Theme.** `ColorScheme.fromSeed` with a custom seed colour (for example a burnt orange), Material 3, one `ThemeData` for light and one for dark, `themeMode` from `ThemeModeNotifier`. Widgets read colours only from `Theme.of(context).colorScheme`.

**Lists.** `GridView.builder` for the exercise feed and `ListView.builder` for workouts, both from stream-backed state. Images use `cached_network_image` with a placeholder and an error widget.

**Animation.** `Hero` with tag `'exercise-image-$id'` from card to detail; `AnimatedContainer` or `AnimatedSwitcher` on the favourite heart and selected filter chip; `AnimatedSwitcher` between loading, content and error.

**Animation controller.** The favourite heart is a small `StatefulWidget` with a `SingleTickerProviderStateMixin` and one `AnimationController` that plays a short scale pulse when the user taps it (created in `initState`, disposed in `dispose`).

**Widget types.** Cards and screens that only render state are `StatelessWidget` or `ConsumerWidget`. The favourite heart and the workout form (text controllers) are `StatefulWidget` or `ConsumerStatefulWidget`, so both kinds appear in the code.

**Accessibility.** `Semantics` labels or `tooltip`s on every icon button, `semanticLabel` on images (the exercise name), `ExcludeSemantics` on decorative images, touch targets of at least 48 dp, no overflow at 1.5x text scale, contrast verified in both themes.

**Lifecycle.** State lives in Riverpod, so rotation keeps it. The form draft lives in `WorkoutFormNotifier`, and text controllers are created in `initState` and disposed in `dispose`. The root widget in `app.dart` owns an `AppLifecycleListener` that calls `SyncNotifier.refresh()` on resume, throttled to once every 5 minutes.

## 9. Background work

1. `main()` initialises `Workmanager` with a top-level `@pragma('vm:entry-point') callbackDispatcher`.
2. In Settings, enabling reminders first requests the Android 13+ notification permission (`POST_NOTIFICATIONS`, declared in `AndroidManifest.xml`) through the `flutter_local_notifications` Android implementation. If denied, the toggle stays off and the screen explains how to enable it in system settings.
3. If granted, `ReminderScheduler.schedule(time)` registers a unique periodic task `daily_reminder` with a 24-hour frequency and an initial delay up to the next chosen time, replacing any existing task. Disabling cancels it by its unique name.
4. The worker runs in its own isolate, so it cannot use the UI's providers. It builds its own `AppDatabase` and `WorkoutRepository` from the same classes, reads `workoutForWeekday(DateTime.now().weekday)`, initialises `NotificationService` again, and closes the database. The worker only reads, so two isolates sharing the SQLite file is safe here.
5. If a workout is planned for today, it shows "Today: {name}, {n} exercises". If none, the periodic task stays silent.
6. Settings has a "Send test reminder" button that registers a one-off task, which shows a notification even when nothing is planned. This is for the demo, because periodic work is not exact and has a 15-minute minimum.

## 10. Testing blueprint

Helpers in `test/`:

- `fakes/`: `FakeWgerApi` (returns the fixture or throws), `FakeExerciseRepository` and `FakeWorkoutRepository` (in-memory, stream controllers).
- `helpers/pump_app.dart`: wraps a widget in `ProviderScope(overrides: ...)` and a themed `MaterialApp`.
- Repository tests use an in-memory drift database (`NativeDatabase.memory()`) and `FakeWgerApi`.

Unit tests (target 8, minimum 5):

1. `exercisesViewState` returns Loading, Failure, Empty and Content for the right inputs.
2. `ExercisesNotifier` follows the filter and emits new data.
3. `ExerciseRepository.refresh` upserts DTOs into the database.
4. `ExerciseRepository.refresh` keeps the cache and returns `Failure` when the API throws (use a mocktail mock of WgerApi for this one).
5. `WorkoutRepository` saves, updates, deletes and loads a workout with its exercises, and `workoutForWeekday` finds today's workout.
6. `WorkoutFormNotifier` rejects an empty name and sets or reps of 0 or less.
7. `SettingsRepository` persists the theme mode (`SharedPreferences.setMockInitialValues`).
8. The mapper handles missing translation, image and HTML in descriptions.

Widget tests (target 4, minimum 3), all with provider overrides:

1. The exercises screen shows loading, content, error with Retry, and empty.
2. The detail screen shows the name and muscles, and the favourite toggle works.
3. The workout form blocks saving with an empty name and shows the error.
4. Choosing dark in settings changes the app's `ThemeMode`.

Run `flutter test` and `flutter analyze` before every push.

## 11. Git and quality

- Create the repository and share it with the instructor on day 1. The first real commit must be on or before 30.11, so 15+ commits span at least 2 weeks.
- One commit per finished step, with short prefixes: `feat:`, `fix:`, `test:`, `refactor:`, `docs:`, `chore:`.
- `.gitignore` must include `key.properties`, `*.jks`, `*.keystore` and `.env`. wger needs no key, so nothing secret should ever be committed.
- Keep `analysis_options.yaml` on `flutter_lints`, fix every issue instead of silencing it.
- Screen files contain widgets only: no HTTP, no SQL, no business rules.

## 12. Build order

| Step | Work | Done when |
| --- | --- | --- |
| 1 | Repo, `flutter create`, packages, folders, lints, `.gitignore`, README skeleton | First commit pushed, `flutter analyze` clean |
| 2 | Theme (light and dark), router shell with 3 tabs, placeholder screens | Tabs keep their state |
| 3 | Domain models, `Result<T>`, wger DTOs, `WgerApi`, fixture, mapper and its tests | Fixture parses in a unit test |
| 4 | drift schema v1, DAOs, in-memory DAO tests | Schema v1 committed |
| 5 | `ExerciseRepository` (watch and refresh), providers, tests | Refresh fills the database |
| 6 | Exercises feed, detail screen, four states, Hero, cached images | Works online and in airplane mode |
| 7 | Settings screen, theme persistence through shared\_preferences | Theme survives restart |
| 8 | `WorkoutRepository`, My Workouts, workout form, add from detail | New workout appears instantly |
| 9 | Lifecycle refresh, background reminder, notification permission, test reminder | Notification appears with the app closed |
| 10 | Animation and accessibility pass, tests to target, `flutter analyze` 0 issues, README | All 13 core requirements work |
| 11 | Extra credit: signed release APK with a custom app name and launcher icon (flutter\_launcher\_icons, keystore, key.properties, flutter build apk --release) | The APK installs and works on a real device, including airplane mode |

Step 11 is extra credit and comes only after step 10. Offline-first sync, the other planned extra, is already the design from step 5. Never commit the keystore or key.properties.
