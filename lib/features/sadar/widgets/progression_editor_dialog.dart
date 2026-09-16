import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme.dart';
import '../../../models/habit.dart';

class ProgressionEditorDialog extends StatefulWidget {
  const ProgressionEditorDialog({
    super.key,
    required this.initialSteps,
    required this.onSaved,
  });

  final List<ProgressionStep> initialSteps;
  final ValueChanged<List<ProgressionStep>> onSaved;

  @override
  State<ProgressionEditorDialog> createState() => _ProgressionEditorDialogState();
}

class _ProgressionEditorDialogState extends State<ProgressionEditorDialog> {
  late List<ProgressionStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = widget.initialSteps.isNotEmpty
        ? List.from(widget.initialSteps)
        : List.from(defaultBodybuildingSteps);
  }

  void _applyPreset(List<ProgressionStep> preset) {
    HapticFeedback.mediumImpact();
    setState(() {
      _steps = List.from(preset);
    });
  }

  void _editStep(int index) {
    final step = _steps[index];
    final titleCtrl = TextEditingController(text: step.title);
    final targetCtrl = TextEditingController(text: step.target.toString());
    final unitCtrl = TextEditingController(text: step.unit);
    bool isRest = step.isRest;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF27272A)),
          ),
          title: Text(
            'Edit ${step.dayName}',
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Rest Day toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hari Istirahat (Rest Day)', style: TextStyle(color: Colors.white, fontSize: 14)),
                value: isRest,
                activeColor: AppPalette.accent,
                onChanged: (val) {
                  setLocal(() {
                    isRest = val;
                    if (val) {
                      titleCtrl.text = 'Rest & Recovery';
                      targetCtrl.text = '0';
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              if (!isRest) ...[
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Nama Latihan / Target',
                    labelStyle: TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: targetCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Jumlah',
                          labelStyle: TextStyle(color: Colors.white60),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: unitCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Satuan (reps/sets)',
                          labelStyle: TextStyle(color: Colors.white60),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppPalette.accent),
              onPressed: () {
                final targetVal = int.tryParse(targetCtrl.text.trim()) ?? 20;
                setState(() {
                  _steps[index] = ProgressionStep(
                    dayName: step.dayName,
                    title: isRest ? 'Rest Day' : titleCtrl.text.trim(),
                    target: isRest ? 0 : targetVal,
                    unit: isRest ? '' : unitCtrl.text.trim(),
                    isRest: isRest,
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141416),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF27272A)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.fitness_center_rounded, color: AppPalette.accent, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Jadwal Progresi Harian',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Target hanya akan bergeser ke hari berikutnya jika sudah di-accomplish. Jika belum, target tetap diam.',
                style: TextStyle(fontSize: 12, color: Colors.white54, height: 1.3),
              ),
              const SizedBox(height: 16),

              // Presets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      backgroundColor: const Color(0xFF202024),
                      side: const BorderSide(color: Color(0xFF333338)),
                      label: const Text('Push-Pull-Legs', style: TextStyle(color: Colors.white, fontSize: 11)),
                      onPressed: () => _applyPreset(defaultBodybuildingSteps),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      backgroundColor: const Color(0xFF202024),
                      side: const BorderSide(color: Color(0xFF333338)),
                      label: const Text('Full Body 100 Reps', style: TextStyle(color: Colors.white, fontSize: 11)),
                      onPressed: () => _applyPreset([
                        const ProgressionStep(dayName: 'Senin', title: 'Push Up', target: 50, unit: 'reps'),
                        const ProgressionStep(dayName: 'Selasa', title: 'Squat', target: 50, unit: 'reps'),
                        const ProgressionStep(dayName: 'Rabu', title: 'Rest & Stretch', isRest: true),
                        const ProgressionStep(dayName: 'Kamis', title: 'Pull Up / Rows', target: 30, unit: 'reps'),
                        const ProgressionStep(dayName: 'Jumat', title: 'Sit Up / Core', target: 50, unit: 'reps'),
                        const ProgressionStep(dayName: 'Sabtu', title: 'Plank Challenge', target: 3, unit: 'sets'),
                        const ProgressionStep(dayName: 'Minggu', title: 'Rest Day', isRest: true),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      backgroundColor: const Color(0xFF202024),
                      side: const BorderSide(color: Color(0xFF333338)),
                      label: const Text('Kalaam Course Rotation', style: TextStyle(color: Colors.white, fontSize: 11)),
                      onPressed: () => _applyPreset([
                        const ProgressionStep(dayName: 'Senin', title: 'Kalaam Modul 1', target: 1, unit: 'course'),
                        const ProgressionStep(dayName: 'Selasa', title: 'Kalaam Modul 2', target: 1, unit: 'course'),
                        const ProgressionStep(dayName: 'Rabu', title: 'Murojaah / Review', target: 1, unit: 'session'),
                        const ProgressionStep(dayName: 'Kamis', title: 'Kalaam Modul 3', target: 1, unit: 'course'),
                        const ProgressionStep(dayName: 'Jumat', title: 'Kalaam Modul 4', target: 1, unit: 'course'),
                        const ProgressionStep(dayName: 'Sabtu', title: 'Kuis & Praktik', target: 1, unit: 'quiz'),
                        const ProgressionStep(dayName: 'Minggu', title: 'Rest Day', isRest: true),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Steps List
              Expanded(
                child: ListView.separated(
                  itemCount: _steps.length,
                  separatorBuilder: (_, __) => const Divider(color: Color(0xFF27272A), height: 1),
                  itemBuilder: (ctx, idx) {
                    final s = _steps[idx];
                    return InkWell(
                      onTap: () => _editStep(idx),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 65,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: s.isRest ? const Color(0xFF1E293B) : const Color(0xFF27272A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s.dayName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: s.isRest ? const Color(0xFF60A5FA) : Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: s.isRest ? Colors.white60 : Colors.white,
                                    ),
                                  ),
                                  if (!s.isRest)
                                    Text(
                                      'Target: ${s.target} ${s.unit}',
                                      style: const TextStyle(fontSize: 12, color: AppPalette.accent),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              s.isRest ? Icons.nightlight_round : Icons.edit_outlined,
                              size: 16,
                              color: s.isRest ? const Color(0xFF60A5FA) : Colors.white38,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onSaved(_steps);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Gunakan Jadwal Ini',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
