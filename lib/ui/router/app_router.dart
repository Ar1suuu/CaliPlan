import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../exercises/exercise_detail_screen.dart';
import '../exercises/exercises_screen.dart';
import '../settings/settings_screen.dart';
import '../workouts/workout_form_screen.dart';
import '../workouts/workouts_screen.dart';
import 'app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// App-wide router: three stateful tabs plus full-screen workout form routes.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/exercises',
    routes: [
      GoRoute(
        path: '/workouts/new',
        name: 'workout-new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WorkoutFormScreen(),
      ),
      GoRoute(
        path: '/workouts/:id/edit',
        name: 'workout-edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => WorkoutFormScreen(
          workoutId: int.parse(state.pathParameters['id']!),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/exercises',
                name: 'exercises',
                builder: (context, state) => const ExercisesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'exercise-detail',
                    builder: (context, state) => ExerciseDetailScreen(
                      exerciseId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workouts',
                name: 'workouts',
                builder: (context, state) => const WorkoutsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(child: Text('No route for ${state.uri}')),
      );
    },
  );

  ref.onDispose(router.dispose);
  return router;
});
