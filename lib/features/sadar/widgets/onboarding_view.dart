import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/habit.dart';
import '../../../providers/sadar_providers.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  final Set<String> _selectedTopics = {'Fokus', 'Olahraga', 'Membaca'};

  static const List<({String title, String icon, int target, int color})> _inspirations = [
    (title: 'Fokus / Deep Work', icon: '💻', target: 45, color: 0xFF10B981),
    (title: 'Olahraga / Health', icon: '🏃', target: 30, color: 0xFFF97316),
    (title: 'Membaca / Reading', icon: '📚', target: 20, color: 0xFF8B5CF6),
    (title: 'Meditasi / Mindfulness', icon: '🧘', target: 15, color: 0xFF06B6D4),
    (title: 'Belajar Bahasa', icon: '🌐', target: 20, color: 0xFF3B82F6),
    (title: 'Menulis / Journaling', icon: '✍️', target: 15, color: 0xFFF59E0B),
  ];

  void _nextPage() {
    HapticFeedback.selectionClick();
    if (_currentPage < 4) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    HapticFeedback.mediumImpact();
    // Ensure the selected starter habits are in repo
    final repo = ref.read(sadarRepoProvider);
    final existing = await repo.getHabits();
    if (existing.isEmpty) {
      for (var i = 0; i < _inspirations.length; i++) {
        final item = _inspirations[i];
        final h = Habit()
          ..name = item.title
          ..iconKey = item.icon
          ..target = item.target
          ..unit = HabitUnit.min
          ..colorValue = item.color
          ..orderIndex = i
          ..createdAt = DateTime.now();
        await repo.upsertHabit(h);
      }
    }
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top page indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final active = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: active ? AppPalette.accent : AppPalette.stroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                  _buildStep5(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return _buildContainer(
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppPalette.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppPalette.accent.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.spa_rounded, size: 54, color: AppPalette.accent),
        ),
        const SizedBox(height: 32),
        const Text(
          'SADAR',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
            color: AppPalette.text,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Become conscious of how you live.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppPalette.textDim, height: 1.4),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.accent,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _nextPage,
          child: const Text('Begin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep2() {
    return _buildContainer(
      children: [
        const Spacer(),
        const Text(
          'What matters to you?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppPalette.text),
        ),
        const SizedBox(height: 12),
        const Text(
          'Choose a few things you genuinely want to make space for every day.',
          style: TextStyle(fontSize: 14, color: AppPalette.textDim, height: 1.5),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['Quran', 'Learning', 'Exercise', 'Language', 'Creative Work', 'Family', 'Reflection'].map((topic) {
            final isSel = _selectedTopics.contains(topic);
            return FilterChip(
              selected: isSel,
              label: Text(topic),
              labelStyle: TextStyle(
                color: isSel ? Colors.black : AppPalette.text,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
              ),
              selectedColor: AppPalette.accent,
              backgroundColor: AppPalette.card,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedTopics.add(topic);
                  } else {
                    _selectedTopics.remove(topic);
                  }
                });
              },
            );
          }).toList(),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.accent,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _nextPage,
          child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep3() {
    return _buildContainer(
      children: [
        const SizedBox(height: 16),
        const Text(
          'Inspirasi Kebiasaan',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppPalette.text),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kamu memegang kendali penuh atas waktumu.',
          style: TextStyle(fontSize: 13, color: AppPalette.textDim),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: _inspirations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final item = _inspirations[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppPalette.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.stroke),
                ),
                child: Row(
                  children: [
                    Text(item.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppPalette.text),
                      ),
                    ),
                    Text(
                      '${item.target} min',
                      style: const TextStyle(fontSize: 12, color: AppPalette.accent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.accent,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _nextPage,
          child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep4() {
    return _buildContainer(
      children: [
        const Spacer(),
        const Text(
          'How much is realistic?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppPalette.text),
        ),
        const SizedBox(height: 12),
        const Text(
          'Start small. Repetition is more powerful than occasional intensity.\n15 minutes practiced 100 times shapes your life.',
          style: TextStyle(fontSize: 14, color: AppPalette.textDim, height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppPalette.stroke),
          ),
          child: const Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fokus / Deep Work', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('45 minutes', style: TextStyle(color: AppPalette.accent)),
                ],
              ),
              Divider(height: 20, color: AppPalette.stroke),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Olahraga / Exercise', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('30 minutes', style: TextStyle(color: AppPalette.accent)),
                ],
              ),
              Divider(height: 20, color: AppPalette.stroke),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Membaca / Reading', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('20 minutes', style: TextStyle(color: AppPalette.accent)),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.accent,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _nextPage,
          child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStep5() {
    return _buildContainer(
      children: [
        const Spacer(),
        const Icon(Icons.check_circle_outline_rounded, size: 64, color: Color(0xFF22C55E)),
        const SizedBox(height: 24),
        const Text(
          "That's enough.",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppPalette.text),
        ),
        const SizedBox(height: 12),
        const Text(
          'Start living your day intentionally.\none fulfilled action at a time.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppPalette.textDim, height: 1.5),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppPalette.accent,
            foregroundColor: Colors.black,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _finishOnboarding,
          child: const Text(
            'Enter Sadar',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContainer({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}
