import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../providers/sadar_providers.dart';

class WhatIRepeatView extends ConsumerWidget {
  const WhatIRepeatView({super.key});

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repeatStatsAsync = ref.watch(whatIRepeatProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
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
                      Icon(Icons.repeat_rounded, color: AppPalette.accent, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'WHAT YOU REPEAT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: AppPalette.accent,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    '“We are what we repeatedly do.”',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.text,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Satu sesi tampak kecil. Ratusan sesi yang diulang menjadi pola hidupmu yang sesungguhnya.',
                    style: TextStyle(fontSize: 12, color: AppPalette.textDim, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'AKUMULASI BUKTI HIDUP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppPalette.textDim,
              ),
            ),
            const SizedBox(height: 14),

            repeatStatsAsync.when(
              data: (stats) {
                if (stats.isEmpty) {
                  return const Text(
                    'Belum ada repetisi yang tercatat.',
                    style: TextStyle(color: AppPalette.textDim),
                  );
                }

                // Find max days to normalize progress bar
                final maxDays = stats.fold<int>(1, (maxVal, s) => max(maxVal, s.totalDays));

                return Column(
                  children: stats.map((stat) {
                    final habit = stat.habit;
                    final habitColor = Color(habit.colorValue);
                    final ratio = maxDays > 0 ? (stat.totalDays / maxDays).clamp(0.05, 1.0) : 0.05;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppPalette.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppPalette.stroke),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(habit.iconKey, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  habit.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppPalette.text,
                                  ),
                                ),
                              ),
                              Text(
                                '${stat.totalDays} hari',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: habitColor,
                                ),
                              ),
                              if (stat.totalMinutes > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '(${_formatDuration(stat.totalMinutes)})',
                                  style: const TextStyle(fontSize: 11, color: AppPalette.textDim),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 8,
                              backgroundColor: AppPalette.bg,
                              valueColor: AlwaysStoppedAnimation(habitColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err', style: const TextStyle(color: Color(0xFFEF4444))),
            ),
          ],
        ),
      ),
    );
  }
}
