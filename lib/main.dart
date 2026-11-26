import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO(step 7): override sharedPreferencesProvider after
  // SharedPreferences.getInstance().
  // TODO(step 9): initialise Workmanager with the background callback
  // dispatcher.
  runApp(const ProviderScope(child: CaliPlanApp()));
}
