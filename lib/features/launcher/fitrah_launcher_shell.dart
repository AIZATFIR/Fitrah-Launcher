import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../focusclock/focusclock_tab.dart';
import 'widgets/fitrah_home_view.dart';
import 'widgets/minimalist_app_drawer.dart';

class FitrahLauncherShell extends ConsumerStatefulWidget {
  const FitrahLauncherShell({
    super.key,
    this.onExitLauncher,
  });

  final VoidCallback? onExitLauncher;

  @override
  ConsumerState<FitrahLauncherShell> createState() => _FitrahLauncherShellState();
}

class _FitrahLauncherShellState extends ConsumerState<FitrahLauncherShell> {
  late final PageController _pageCtrl;
  int _currentPage = 1; // 0 = Focus Clock Face, 1 = Home (Center), 2 = Minimalist App Drawer

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: 1);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (_pageCtrl.hasClients) {
      HapticFeedback.selectionClick();
      _pageCtrl.animateToPage(
        page,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_currentPage != 1) {
            _goToPage(1); // Return to home on back press
          } else if (widget.onExitLauncher != null) {
            widget.onExitLauncher!();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppPalette.bg,
        body: PageView(
          controller: _pageCtrl,
          physics: _currentPage == 0
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          onPageChanged: (page) => setState(() => _currentPage = page),
          children: [
            // Page 0 (Slide Left): Full Focus Clock Face with Back to Home button
            Stack(
              children: [
                const FocusClockTab(),
                // Floating Home pill at top right
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 18,
                  child: GestureDetector(
                    onTap: () => _goToPage(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'HOME',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: AppPalette.accent, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Page 1 (Center): Fitrah Home Dashboard
            FitrahHomeView(
              onOpenFocusClock: () => _goToPage(0),
              onOpenAppDrawer: () => _goToPage(2),
            ),

            // Page 2 (Slide Right): Niagara-Style Minimalist App Drawer
            const MinimalistAppDrawer(),
          ],
        ),
      ),
    );
  }
}
