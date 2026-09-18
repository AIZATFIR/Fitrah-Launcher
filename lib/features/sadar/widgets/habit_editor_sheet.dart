import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/habit.dart';
import '../../../providers/sadar_providers.dart';
import 'allowed_apps_selector_dialog.dart';
import 'progression_editor_dialog.dart';

class HabitEditorSheet extends ConsumerStatefulWidget {
  const HabitEditorSheet({
    super.key,
    this.habit,
    required this.onSaved,
  });

  final Habit? habit;
  final VoidCallback onSaved;

  @override
  ConsumerState<HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends ConsumerState<HabitEditorSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _targetCtrl;
  late TextEditingController _hybridSetsCtrl;
  late TextEditingController _hybridSecsCtrl;
  late String _selectedIcon;
  late HabitUnit _selectedUnit;
  late String _habitType; // 'timed' | 'count' | 'progression' | 'hybrid'
  late List<String> _allowedPackages;
  late List<ProgressionStep> _progressionSteps;
  late int _selectedColor;

  static const List<String> _popularIcons = [
    '📖', '💻', '🏋️', '🏃', '🇫🇷', '🧘', '📚', '✍️', '💧', '🥗', '🎯', '⚡'
  ];

  static const List<int> _colorOptions = [
    0xFF10B981, // Emerald
    0xFF3B82F6, // Blue
    0xFFF59E0B, // Amber
    0xFFF97316, // Orange
    0xFF8B5CF6, // Purple
    0xFFEC4899, // Pink
    0xFF06B6D4, // Cyan
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameCtrl = TextEditingController(text: h?.name ?? '');
    _targetCtrl = TextEditingController(text: (h?.target ?? 20).toString());
    _hybridSetsCtrl = TextEditingController(text: (h?.hybridSets ?? 3).toString());
    _hybridSecsCtrl = TextEditingController(text: (h?.hybridDurationSeconds ?? 60).toString());
    _selectedIcon = h?.iconKey.isNotEmpty == true ? h!.iconKey : '🎯';
    _selectedUnit = h?.unit ?? HabitUnit.min;
    _habitType = h?.effectiveHabitType ?? 'timed';
    _allowedPackages = List.from(h?.allowedPackages ?? []);
    _progressionSteps = List.from(h?.progressionSteps ?? defaultBodybuildingSteps);
    _selectedColor = h?.colorValue ?? _colorOptions[0];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _hybridSetsCtrl.dispose();
    _hybridSecsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final target = int.tryParse(_targetCtrl.text.trim()) ?? 20;
    final hybridSets = int.tryParse(_hybridSetsCtrl.text.trim()) ?? 3;
    final hybridSecs = int.tryParse(_hybridSecsCtrl.text.trim()) ?? 60;

    final habit = widget.habit ?? Habit();
    habit.name = name;
    habit.iconKey = _selectedIcon;
    habit.target = target.clamp(1, 9999);
    habit.unit = _selectedUnit;
    habit.habitType = _habitType;
    habit.timerEnabled = _habitType == 'timed' || _habitType == 'hybrid';
    habit.allowedPackages = _allowedPackages;
    habit.progressionPlanJson = jsonEncode(_progressionSteps.map((s) => s.toJson()).toList());
    habit.hybridSets = hybridSets.clamp(1, 100);
    habit.hybridDurationSeconds = hybridSecs.clamp(5, 3600);
    habit.colorValue = _selectedColor;
    if (widget.habit == null) {
      habit.createdAt = DateTime.now();
    }

    HapticFeedback.mediumImpact();
    await ref.read(sadarRepoProvider).upsertHabit(habit);
    widget.onSaved();
  }

  Future<void> _delete() async {
    if (widget.habit == null) return;
    HapticFeedback.heavyImpact();
    await ref.read(sadarRepoProvider).deleteHabit(widget.habit!.id);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.habit != null;

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
            // Handle
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
            const SizedBox(height: 16),

            // Title
            Row(
              children: [
                Text(
                  isEditing ? 'Ubah Kebiasaan' : 'Kebiasaan Bermakna Baru',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppPalette.text),
                ),
                const Spacer(),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
                    tooltip: 'Hapus Kebiasaan',
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Habit Name Input
            TextField(
              controller: _nameCtrl,
              autofocus: !isEditing,
              style: const TextStyle(fontSize: 15, color: AppPalette.text),
              decoration: InputDecoration(
                labelText: 'Nama Kebiasaan',
                hintText: 'misal: Deep Work, Olahraga, Belajar Bahasa, Membaca',
                labelStyle: const TextStyle(color: AppPalette.textDim),
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
            ),
            const SizedBox(height: 16),

            // Emoji Picker Row
            const Text('Pilih Simbol / Emoji', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppPalette.textDim)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularIcons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIcon = icon);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? AppPalette.accent.withValues(alpha: 0.25) : AppPalette.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppPalette.accent : AppPalette.stroke,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            const SizedBox(height: 18),

            // Tipe Kebiasaan Selector
            const Text(
              'Tipe Kebiasaan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppPalette.textDim),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeChip('timed', '⏱️ Timed (YPT)'),
                  const SizedBox(width: 8),
                  _buildTypeChip('count', '🔢 Count'),
                  const SizedBox(width: 8),
                  _buildTypeChip('progression', '🏋️ Bodybuilding'),
                  const SizedBox(width: 8),
                  _buildTypeChip('hybrid', '⚡ Hybrid'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // DYNAMIC SECTION BASED ON TYPE
            if (_habitType == 'timed') ...[
              // Timed (YPT Focus)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, color: AppPalette.text),
                      decoration: InputDecoration(
                        labelText: 'Durasi Fokus (Menit)',
                        labelStyle: const TextStyle(color: AppPalette.textDim),
                        filled: true,
                        fillColor: AppPalette.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppPalette.stroke),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Whitelist button
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AllowedAppsSelectorDialog(
                      initialAllowed: _allowedPackages,
                      onSaved: (packages) {
                        setState(() => _allowedPackages = packages);
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppPalette.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppPalette.stroke),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 18, color: AppPalette.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _allowedPackages.isEmpty
                              ? 'Pilih Aplikasi Diizinkan (Whitelist: Belum Ada)'
                              : '${_allowedPackages.length} Aplikasi Diizinkan selama Fokus',
                          style: const TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white54),
                    ],
                  ),
                ),
              ),
            ] else if (_habitType == 'count') ...[
              // Count Mode
              TextField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14, color: AppPalette.text),
                decoration: InputDecoration(
                  labelText: 'Target Jumlah / Repetisi',
                  hintText: 'misal: 1 untuk course/kegiatan harian, 20 untuk push up',
                  labelStyle: const TextStyle(color: AppPalette.textDim),
                  filled: true,
                  fillColor: AppPalette.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppPalette.stroke),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cocok untuk target repetisi, 1 course Kalaam, atau checklist kegiatan harian.',
                style: TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ] else if (_habitType == 'progression') ...[
              // Progression / Bodybuilding Mode
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => ProgressionEditorDialog(
                      initialSteps: _progressionSteps,
                      onSaved: (steps) {
                        setState(() => _progressionSteps = steps);
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppPalette.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppPalette.accent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center_rounded, size: 20, color: AppPalette.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Konfigurasi Jadwal Mingguan (${_progressionSteps.length} Hari)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Target tidak berubah jika hari ini belum di-accomplish.',
                              style: TextStyle(fontSize: 11, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_note_rounded, size: 20, color: AppPalette.accent),
                    ],
                  ),
                ),
              ),
            ] else if (_habitType == 'hybrid') ...[
              // Hybrid Mode (Set x Duration)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hybridSetsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, color: AppPalette.text),
                      decoration: InputDecoration(
                        labelText: 'Jumlah Set',
                        hintText: '3',
                        labelStyle: const TextStyle(color: AppPalette.textDim),
                        filled: true,
                        fillColor: AppPalette.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppPalette.stroke),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _hybridSecsCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14, color: AppPalette.text),
                      decoration: InputDecoration(
                        labelText: 'Detik per Set',
                        hintText: '60',
                        labelStyle: const TextStyle(color: AppPalette.textDim),
                        filled: true,
                        fillColor: AppPalette.bg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppPalette.stroke),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Kombinasi Repetisi Set x Timer. Contoh: Plank 3 set @ 60 detik.',
                style: TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
            const SizedBox(height: 16),

            // Color Accent Selection
            const Text('Warna Tag', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppPalette.textDim)),
            const SizedBox(height: 8),
            Row(
              children: _colorOptions.map((c) {
                final isSelected = _selectedColor == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedColor = c);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: Color(c).withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)]
                            : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _save,
              child: Text(
                isEditing ? 'Simpan Perubahan' : 'Buat Kebiasaan',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _habitType == type;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.black : Colors.white70,
        ),
      ),
      selected: isSelected,
      selectedColor: AppPalette.accent,
      backgroundColor: const Color(0xFF1E1E22),
      onSelected: (val) {
        if (val) setState(() => _habitType = type);
      },
    );
  }
}
