# CaliPlan: Calisthenics Workout Planner — Proposal

> Condensed from the original proposal PDF, kept in this folder as
> `CaliPlan Calisthenics Workout Planner.pdf`. Demo date: 14.12.2026.

## Overview

CaliPlan is an Android app for people who train with their own body weight.
Users discover calisthenics exercises, save the ones they like, build weekly
workouts with sets and reps, and get a daily reminder with that day's workout.
The exercise library comes from a public REST API and is cached in a local
database, so the app keeps working without internet.

**Problem.** Calisthenics information is scattered across videos and forums, and
weekly plans usually end up in notes apps or screenshots. CaliPlan keeps the
exercise library, the plan and the reminder in one place.

## Goals

- A complete Android app that uses every layer taught in classes 1–24.
- Clean architecture: the UI only renders state, and all data goes through
  injected repositories.
- An offline-first experience where database changes update the screen
  reactively.

## Main features

- Browse bodyweight exercises with photos, muscle groups and instructions;
  filter by muscle group.
- Save favourite exercises.
- Create, edit and delete workouts: a name, a planned weekday, and exercises
  with sets and reps.
- Get a daily reminder notification with today's workout, scheduled by a
  background task.
- Choose a light, dark or system theme, remembered between launches.
- Use the app offline: data is cached locally and refreshed when the network is
  available.

## Screens

Navigation is a bottom bar with three tabs. Each tab keeps its own back stack.

| Screen | Purpose |
| --- | --- |
| Exercises | Feed with muscle filter chips, favourite toggle, pull-to-refresh (tab 1) |
| Exercise detail | Photo, muscles, instructions, favourite, add to workout |
| My Workouts | The user's workouts and favourites (tab 2) |
| Workout form | Create or edit a workout, with validation |
| Settings | Theme choice and reminder settings (tab 3) |

## Architecture

Layered architecture with one rule: the UI never talks to a data source
directly.

```text
UI screens (widgets, render state only)
  | events
State holders (Riverpod Notifier / AsyncNotifier)
  | calls
Repositories (one source of truth, injected by Riverpod)
  |-- Remote: wger REST API (dio + retrofit)
  |-- Local: drift database + shared_preferences
Background task (workmanager) --> own database + repository --> notification
```

The screen watches a state holder. The state holder watches a repository stream
backed by the local database. A refresh calls the API and writes the result into
the database; the database change updates the screen automatically.

## Technology stack

Dart 3, Flutter, Material 3, Riverpod, go_router, dio, retrofit,
json_serializable, drift, shared_preferences, cached_network_image,
workmanager, flutter_local_notifications, flutter_test, mocktail,
flutter_lints.

## Data

- **Remote:** the free wger exercise REST API (exercises, muscles, equipment,
  images). Public read access, no API key.
- **Local database (drift):** four tables — `exercises`, `favorites`,
  `workouts`, `workout_exercises`.
- **Settings:** theme mode and reminder settings in `shared_preferences`.

## Planned extras

- Offline-first sync (the UI reads only from the database; refresh upserts API
  data).
- A signed release APK with a custom app name and launcher icon.

## Timeline

| Phase | Dates | Result |
| --- | --- | --- |
| Foundation | 26.11–30.11 | Repository, theme, navigation, API layer, exercises feed and detail |
| Local data | 01.12–03.12 | Database, offline-first sync, favourites, settings |
| Features | 04.12–08.12 | Workouts and form, reminder, lifecycle, accessibility, tests, clean analysis |
| Extras and polish | 09.12–13.12 | Extra features, release build, README, rehearsal |
| Demo | 14.12 | Live presentation |
