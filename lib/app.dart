import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/constants.dart';
import 'ui/router/app_router.dart';
import 'ui/settings/theme_mode_notifier.dart';
import 'ui/theme/app_theme.dart';

/// Root widget: owns the router, both themes and the selected theme mode.
class CaliPlanApp extends ConsumerWidget {
  const CaliPlanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
