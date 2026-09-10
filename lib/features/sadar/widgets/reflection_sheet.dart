import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/daily_reflection.dart';
import '../../../providers/sadar_providers.dart';

class ReflectionSheet extends ConsumerStatefulWidget {
  const ReflectionSheet({
    super.key,
    required this.dateString,
    this.existingReflection,
    required this.onSaved,
  });

  final String dateString;
  final DailyReflection? existingReflection;
  final VoidCallback onSaved;

  @override
  ConsumerState<ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends ConsumerState<ReflectionSheet> {
  late ReflectionFeeling _feeling;
  late TextEditingController _proudCtrl;
  late TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final r = widget.existingReflection;
    _feeling = r?.feeling ?? ReflectionFeeling.good;
    _proudCtrl = TextEditingController(text: r?.proudOfToday ?? '');
    _noteCtrl = TextEditingController(text: r?.note ?? '');
  }

  @override
  void dispose() {
    _proudCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    final reflection = widget.existingReflection ?? DailyReflection()
      ..dateString = widget.dateString;

    reflection.feeling = _feeling;
    reflection.proudOfToday = _proudCtrl.text.trim();
    reflection.note = _noteCtrl.text.trim();

    await ref.read(sadarRepoProvider).saveDailyReflection(reflection);
    // Invalidate provider so UI updates immediately
    ref.invalidate(dailyReflectionProvider(widget.dateString));
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPalette.stroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            const Row(
              children: [
                Icon(Icons.spa_rounded, color: AppPalette.accent, size: 22),
                SizedBox(width: 8),
                Text(
                  "Today's Reflection",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Did you do what mattered to you today?',
              style: TextStyle(fontSize: 13, color: AppPalette.textDim),
            ),

            const SizedBox(height: 24),

            // 1. Feeling Option Chips
            const Text(
              'HOW DO YOU FEEL ABOUT TODAY?',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppPalette.textDim,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _feelingChip(ReflectionFeeling.notSatisfied, '🌧️', 'Reflecting'),
                const SizedBox(width: 8),
                _feelingChip(ReflectionFeeling.okay, '☁️', 'Okay'),
                const SizedBox(width: 8),
                _feelingChip(ReflectionFeeling.good, '🌿', 'Good'),
                const SizedBox(width: 8),
                _feelingChip(ReflectionFeeling.proud, '🌟', 'Proud'),
              ],
            ),

            const SizedBox(height: 24),

            // 2. Proud of Today Concept
            const Text(
              'TODAY I AM PROUD THAT...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppPalette.accent,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'What did you do today that you are glad you did?',
              style: TextStyle(fontSize: 12, color: AppPalette.textDim),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _proudCtrl,
              style: const TextStyle(fontSize: 14, color: AppPalette.text),
              decoration: InputDecoration(
                hintText: 'misal: Aku belajar bahasa walau awalnya terasa lelah.',
                hintStyle: const TextStyle(color: AppPalette.textDim, fontSize: 13),
                filled: true,
                fillColor: AppPalette.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppPalette.stroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppPalette.stroke),
                ),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 18),

            // 3. Optional Reflection Note
            const Text(
              'OPTIONAL NOTE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppPalette.textDim,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(fontSize: 13, color: AppPalette.text),
              decoration: InputDecoration(
                hintText: 'Catatan tambahan tentang hari ini...',
                hintStyle: const TextStyle(color: AppPalette.textDim, fontSize: 13),
                filled: true,
                fillColor: AppPalette.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppPalette.stroke),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppPalette.stroke),
                ),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // Submit Button
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _save,
              child: const Text(
                'Save Reflection',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feelingChip(ReflectionFeeling feeling, String emoji, String label) {
    final isSelected = _feeling == feeling;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _feeling = feeling);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppPalette.accent.withValues(alpha: 0.2) : AppPalette.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppPalette.accent : AppPalette.stroke,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppPalette.accent : AppPalette.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
