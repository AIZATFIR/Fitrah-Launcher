import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../providers/sadar_providers.dart';

class DailyFulfillmentBanner extends ConsumerWidget {
  const DailyFulfillmentBanner({
    super.key,
    required this.selectedDate,
    required this.onToggleAwareness,
    required this.isShowingAwareness,
  });

  final DateTime selectedDate;
  final VoidCallback onToggleAwareness;
  final bool isShowingAwareness;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final y = selectedDate.year.toString().padLeft(4, '0');
    final m = selectedDate.month.toString().padLeft(2, '0');
    final d = selectedDate.day.toString().padLeft(2, '0');
    final dateStr = '$y-$m-$d';

    final fulfillmentAsync = ref.watch(dailyFulfillmentProvider(dateStr));
    final dateFormatted = DateFormat('EEEE, d MMMM').format(selectedDate);

    final isToday = _isSameDay(selectedDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Date & Action Switcher
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dateFormatted,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppPalette.text,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppPalette.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppPalette.accent.withValues(alpha: 0.5)),
                          ),
                          child: const Text(
                            'HARI INI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppPalette.accent,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '"Did I live today in a way I can be proud of?"',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppPalette.textDim,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Awareness Toggle Button
              IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor: isShowingAwareness
                      ? AppPalette.accent.withValues(alpha: 0.25)
                      : AppPalette.bg,
                  foregroundColor: isShowingAwareness ? AppPalette.accent : AppPalette.textDim,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isShowingAwareness ? AppPalette.accent : AppPalette.stroke,
                    ),
                  ),
                ),
                tooltip: isShowingAwareness ? 'Tutup Pola Kesadaran' : 'Lihat Pola Kesadaran',
                icon: Icon(
                  isShowingAwareness ? Icons.calendar_view_week_rounded : Icons.insights_rounded,
                  size: 20,
                ),
                onPressed: onToggleAwareness,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fulfillment Progress Track
          fulfillmentAsync.when(
            data: (summary) {
              final ratio = summary.ratio;
              final completed = summary.completedCount;
              final total = summary.totalCount;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        total > 0
                            ? '$completed / $total tindakan bermakna terlaksana'
                            : 'Belum ada habit yang terdaftar',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.text,
                        ),
                      ),
                      Text(
                        summary.isFulfilled
                            ? 'Hari Terpenuhi 🌿'
                            : (completed > 0 ? 'Membangun Hari' : 'Mulai dari satu aksi'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: summary.isFulfilled ? const Color(0xFF22C55E) : AppPalette.textDim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: total > 0 ? ratio : 0.0,
                      minHeight: 6,
                      backgroundColor: AppPalette.bg,
                      valueColor: AlwaysStoppedAnimation(
                        summary.isFulfilled ? const Color(0xFF22C55E) : AppPalette.accent,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(minHeight: 6),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
