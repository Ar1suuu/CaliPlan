import 'package:material_ui/material_ui.dart';

import '../widgets/placeholder_view.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final int exerciseId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Exercise #$exerciseId')),
      body: const PlaceholderView(
        icon: Icons.image_outlined,
        title: 'Exercise detail',
        message:
            'Photo, muscles, instructions, favourite toggle and add-to-workout '
            'arrive in step 6.',
      ),
    );
  }
}
