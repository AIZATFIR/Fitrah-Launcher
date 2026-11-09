import 'package:flutter/material.dart';
import '../../../models/habit.dart';

class HabitActionSaveDialog extends StatefulWidget {
  const HabitActionSaveDialog({
    super.key,
    required this.title,
    required this.body,
    required this.onSave,
  });
  final String title;
  final Widget body;
  final Future<void> Function() onSave;
  @override
  State<HabitActionSaveDialog> createState() => HabitActionSaveDialogState();
}

class HabitActionSaveDialogState extends State<HabitActionSaveDialog> {
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeFocus(
              excluding: busy,
              child: AbsorbPointer(absorbing: busy, child: widget.body),
            ),
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  setState(() {
                    busy = true;
                    error = null;
                  });
                  try {
                    await widget.onSave();
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        busy = false;
                        error = '$e';
                      });
                    }
                  }
                },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

String habitExecutionLimit(Habit habit) {
  if (habit.habitType != 'progression' && habit.habitType != 'hybrid') {
    return 'Jenis habit ini belum didukung. Rincian pelaksanaan tidak tersedia; tindakan ini tidak menandai selesai.';
  }
  final detail = habit.habitType == 'progression'
      ? '${habit.currentStep.dayName}: ${habit.currentStep.title} — ${habit.currentStep.isRest ? 'Istirahat' : '${habit.currentStep.target} ${habit.currentStep.unit}'}'
      : '${habit.hybridSets} set × ${habit.hybridDurationSeconds} detik; istirahat ${habit.hybridRestSeconds} detik';
  return '$detail\nPencatatan langkah/set belum didukung. Rincian ini tidak menandai selesai.';
}

Future<void> showHabitActionDialog({
  required BuildContext context,
  required WidgetBuilder builder,
}) async {
  final route = DialogRoute<void>(
    context: context,
    builder: builder,
    barrierDismissible: false,
  );
  await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
}
