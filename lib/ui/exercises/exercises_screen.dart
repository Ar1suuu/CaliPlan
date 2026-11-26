import 'package:material_ui/material_ui.dart';

import '../widgets/placeholder_view.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: const PlaceholderView(
        icon: Icons.fitness_center,
        title: 'Exercise library',
        message: 'The wger feed, muscle filter chips and favourites arrive in step 6.',
      ),
    );
  }
}
