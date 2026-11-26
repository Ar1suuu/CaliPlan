import 'package:material_ui/material_ui.dart';

import '../widgets/placeholder_view.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Workouts')),
      body: const PlaceholderView(
        icon: Icons.event_note,
        title: 'Your weekly plan',
        message:
            'Workout list, favourites and the create button arrive in step 8.',
      ),
    );
  }
}
