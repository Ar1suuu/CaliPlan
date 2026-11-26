import 'package:caliplan/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('starts on the exercises tab', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CaliPlanApp()));
    await tester.pumpAndSettle();

    expect(find.text('Exercise library'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('bottom navigation switches tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CaliPlanApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Workouts'));
    await tester.pumpAndSettle();

    expect(find.text('Your weekly plan'), findsOneWidget);
  });

  testWidgets('settings switches the app to dark mode', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CaliPlanApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
