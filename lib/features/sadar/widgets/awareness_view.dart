import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../models/habit.dart';
import '../../../providers/sadar_providers.dart';

class AwarenessView extends ConsumerWidget {
  const AwarenessView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awarenessAsync = ref.watch(awarenessStatsProvider);
    final habitsAsync = ref.watch(habitsStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Philosophical Quote Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppPalette.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPalette.stroke),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.remove_red_eye_outlined, color: AppPalette.accent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'PRINSIP KESADARAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: AppPalette.accent,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '"Until you make the unconscious conscious, it will direct your life and you will call it fate."',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppPalette.text,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Aplikasi ini hadir bukan untuk menghakimimu, melainkan untuk menyadarkan pola nyata yang berulang dalam hidupmu.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPalette.textDim,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section 1: "Apa yang berulang kali kulakukan?"
          const Text(
            'APA YANG BERULANG KALI KAU LAKUKAN?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppPalette.textDim,
            ),
          ),
          const SizedBox(height: 10),

          awarenessAsync.when(
            data: (stats) {
              return habitsAsync.when(
                data: (habits) {
                  if (habits.isEmpty) {
                    return const Text('Belum ada data kebiasaan.', style: TextStyle(color: AppPalette.textDim));
                  }

                  // Sort habits by completed sessions descending
                  final sorted = List<Habit>.from(habits)
                    ..sort((a, b) {
                      final countA = stats.habitCompletedCounts[a.id] ?? 0;
                      final countB = stats.habitCompletedCounts[b.id] ?? 0;
                      return countB.compareTo(countA);
                    });

                  return Column(
                    children: sorted.map((h) {
                      final completedSessions = stats.habitCompletedCounts[h.id] ?? 0;
                      final habitColor = Color(h.colorValue);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppPalette.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppPalette.stroke),
                        ),
                        child: Row(
                          children: [
                            Text(h.iconKey, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    h.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppPalette.text,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$completedSessions sesi terpenuhi (30 hari terakhir)',
                                    style: const TextStyle(fontSize: 12, color: AppPalette.textDim),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: habitColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: habitColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                '$completedSessions ✓',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: habitColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // Section 2: "Pola yang membutuhkan perhatian"
          const Text(
            'POLA YANG MEMBUTUHKAN PERHATIAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppPalette.textDim,
            ),
          ),
          const SizedBox(height: 10),

          awarenessAsync.when(
            data: (stats) {
              final neglected = stats.neglectedHabits;
              if (neglected.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: Color(0xFF22C55E), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Semua kebiasaan berjalan dengan ritme yang stabil minggu ini. Pertahankan ketenanganmu.',
                          style: TextStyle(fontSize: 12, color: AppPalette.text, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: neglected.map((h) {
                  final missedCount = stats.habitMissedCounts[h.id] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppPalette.stroke),
                    ),
                    child: Row(
                      children: [
                        Text(h.iconKey, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                missedCount > 0
                                    ? '$missedCount kali terlewati belakangan ini. Sadari tanpa menghakimi diri.'
                                    : 'Belum sering dilakukan. Apakah ini masih penting bagimu?',
                                style: const TextStyle(fontSize: 11, color: AppPalette.textDim),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
        ),
      ),
    );
  }
}
