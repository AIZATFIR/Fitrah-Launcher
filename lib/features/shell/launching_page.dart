import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/google_auth_dialog.dart';

class LaunchingPage extends ConsumerStatefulWidget {
  const LaunchingPage({super.key});

  @override
  ConsumerState<LaunchingPage> createState() => _LaunchingPageState();
}

class _LaunchingPageState extends ConsumerState<LaunchingPage> {
  int _quoteIndex = 0;
  late Timer _timer;

  static const List<String> _affirmations = [
    'Beri makna pada setiap detikan energimu.',
    'Salurkan kreativitasmu, lindungi kedamaian pikiranmu.',
    'Setiap langkah kecil hari ini adalah karya emas hidupmu.',
    'Hadir sepenuhnya. Seize the day & fulfill your life.',
    'Kamu memegang kendali penuh atas waktumu.',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _quoteIndex = (_quoteIndex + 1) % _affirmations.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _selectMode(String mode) {
    HapticFeedback.mediumImpact();
    ref.read(selectedAppModeProvider.notifier).state = mode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top Row: Google Sync Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Consumer(
                        builder: (context, ref, child) {
                          final gcalSigned = ref.watch(gcalSignedInProvider);
                          return InkWell(
                            onTap: () => showGoogleAuthDialog(context, ref),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: gcalSigned ? AppPalette.accent.withValues(alpha: 0.15) : AppPalette.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: gcalSigned ? AppPalette.accent : AppPalette.stroke),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.sync_rounded, size: 14, color: AppPalette.accent),
                                  const SizedBox(width: 6),
                                  Text(
                                    gcalSigned ? 'Google Sync: Terhubung' : 'Sinkronkan Akun Google',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: gcalSigned ? AppPalette.accent : AppPalette.textDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Logo Icon (Enlarged)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppPalette.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppPalette.accent.withValues(alpha: 0.5), width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: AppPalette.accent.withValues(alpha: 0.25),
                          blurRadius: 28,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.schedule_rounded, size: 64, color: AppPalette.accent),
                  ),
                  const SizedBox(height: 24),

                  // Title & Tagline (Enlarged UI)
                  const Text(
                    'FOCUS CLOCK',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.5,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Private time secretary',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppPalette.textDim,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // 2 LARGE PRIMARY HERO BUTTONS (Simple Mode vs Focus Clock Mode)
                  Row(
                    children: [
                      // HERO CARD 1: SIMPLE MODE (Large button filling width)
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectMode('simple'),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: AppPalette.card,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppPalette.accent, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppPalette.accent.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppPalette.accent,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.bolt_rounded, size: 28, color: Colors.black),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_forward_rounded, color: AppPalette.accent, size: 24),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                const Text(
                                  'SIMPLE MODE',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppPalette.accent,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Fokus Cepat',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Input 1-tap, preset durasi, dan asisten suara.',
                                  style: TextStyle(fontSize: 12, color: AppPalette.textDim, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // HERO CARD 2: FOCUS CLOCK MODE (Large button filling width)
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectMode('overview'),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: AppPalette.card,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppPalette.stroke),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppPalette.bg,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppPalette.stroke),
                                      ),
                                      child: const Icon(Icons.pie_chart_rounded, size: 28, color: AppPalette.accent),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_forward_rounded, color: AppPalette.textDim, size: 24),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                const Text(
                                  'FOCUS CLOCK',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: AppPalette.text,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Visualisasi Jam 24-Jam',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Dial jam 24-jam interaktif dan jurnal refleksi.',
                                  style: TextStyle(fontSize: 12, color: AppPalette.textDim, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // HERO CARD 3: SADAR (Way of Life)
                  InkWell(
                    onTap: () => _selectMode('sadar'),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppPalette.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.spa_rounded, size: 26, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'SADAR',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF10B981),
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'WAY OF LIFE',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF10B981), letterSpacing: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Fulfill your day, one meaningful action at a time.',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppPalette.text),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Timeline kebiasaan harian, self-validation, dan akumulasi kesadaran hidup.',
                                  style: TextStyle(fontSize: 11, color: AppPalette.textDim),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_rounded, color: Color(0xFF10B981), size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // HERO CARD 4: FITRAH LAUNCHER (Minimalist Home Launcher)
                  InkWell(
                    onTap: () => _selectMode('fitrah'),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: AppPalette.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppPalette.accent.withValues(alpha: 0.8), width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: AppPalette.accent.withValues(alpha: 0.18),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppPalette.accent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppPalette.accent.withValues(alpha: 0.4)),
                            ),
                            child: const Icon(Icons.home_outlined, size: 26, color: AppPalette.accent),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'FITRAH LAUNCHER',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppPalette.accent,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppPalette.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'HOME',
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppPalette.accent, letterSpacing: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Minimalist phone launcher & intentional time companion.',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppPalette.text),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  '3 panel geser: Jam analog Focus Clock (kiri) | Event hari ini (tengah) | Niagara App Drawer (kanan).',
                                  style: TextStyle(fontSize: 11, color: AppPalette.textDim),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_rounded, color: AppPalette.accent, size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Rolling Subconscious Kind Affirmation Banner (Placed at bottom, BORDERLESS without outline)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      key: ValueKey<int>(_quoteIndex),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Colors.transparent, // Borderless, clean text display at bottom
                      ),
                      child: Text(
                        _affirmations[_quoteIndex],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppPalette.accent.withValues(alpha: 0.85),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
