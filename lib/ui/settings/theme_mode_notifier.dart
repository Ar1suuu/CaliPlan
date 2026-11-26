import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
  name: 'themeMode',
);

/// Holds the selected [ThemeMode].
///
/// TODO(step 7): read the initial value from `SettingsRepository` and persist
/// every change through `shared_preferences`.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}
