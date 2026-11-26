import 'package:material_ui/material_ui.dart';

import '../widgets/placeholder_view.dart';

class WorkoutFormScreen extends StatelessWidget {
  const WorkoutFormScreen({super.key, this.workoutId});

  /// Null when creating a new workout.
  final int? workoutId;

  @override
  Widget build(BuildContext context) {
    final isEditing = workoutId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit workout' : 'New workout')),
      body: PlaceholderView(
        icon: Icons.edit_note,
        title: isEditing ? 'Edit workout #$workoutId' : 'Create a workout',
        message:
            'Name, weekday, exercises, sets, reps and validation arrive in '
            'step 8.',
      ),
    );
  }
}
