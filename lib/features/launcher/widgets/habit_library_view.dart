import 'package:flutter/material.dart';

import '../../../models/habit.dart';
import 'loop_habit_grid_widget.dart';

class HabitLibraryView extends StatelessWidget {
  const HabitLibraryView({super.key, this.onStartTimer});

  final void Function(Habit habit)? onStartTimer;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Semua kebiasaan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          LoopHabitGridWidget(onStartTimer: onStartTimer),
        ],
      ),
    ),
  );
}
