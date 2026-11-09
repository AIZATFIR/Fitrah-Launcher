import '../../core/time_math.dart';
import '../../providers/providers.dart';
import '../../providers/intent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../focusclock/focusclock_tab.dart';
import 'widgets/focus_clock_home_view.dart';
import 'widgets/minimalist_app_drawer.dart';

class FitrahLauncherShell extends ConsumerStatefulWidget {
  const FitrahLauncherShell({super.key, this.onExitLauncher});

  final VoidCallback? onExitLauncher;

  @override
  ConsumerState<FitrahLauncherShell> createState() =>
      _FitrahLauncherShellState();
}

class _FitrahLauncherShellState extends ConsumerState<FitrahLauncherShell> {
  static const _homeChannel = MethodChannel('fitrah_launcher/home');
  late final PageController _pageCtrl;
  bool _returningHome = false;
  int _currentPage =
      1; // 0 = Focus Clock Face, 1 = Home (Center), 2 = Minimalist App Drawer

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: 1);
    _homeChannel.setMethodCallHandler((call) async {
      if (call.method == 'home') await _returnHome();
    });
  }

  @override
  void dispose() {
    _homeChannel.setMethodCallHandler(null);
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _returnHome() async {
    if (!mounted || _returningHome) return;
    _returningHome = true;
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      final navigator = Navigator.of(context);
      final shellRoute = ModalRoute.of(context);
      Route<dynamic>? topRoute() {
        Route<dynamic>? top;
        navigator.popUntil((route) {
          top = route;
          return true;
        });
        return top;
      }

      var top = topRoute();
      while (mounted && navigator.mounted && top != shellRoute) {
        if (top == null || !await navigator.maybePop()) return;
        if (!mounted || !navigator.mounted) return;
        final next = topRoute();
        // A PopScope guard (or local history) kept this route: stop here.
        if (next == top) return;
        top = next;
      }
      if (!mounted) return;
      _refreshHomeDate();
      if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(1);
    } finally {
      _returningHome = false;
    }
  }

  void _refreshHomeDate() {
    final now = ref.read(intentNowProvider);
    ref.read(currentDateProvider.notifier).state = dateOnly(now);
    ref.read(ampmHalfProvider.notifier).state = halfOfNow(now);
  }

  void _goToPage(int page) {
    if (_pageCtrl.hasClients) {
      HapticFeedback.selectionClick();
      _pageCtrl.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
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
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0x1A000000)],
            ),
          ),
          child: PageView(
            controller: _pageCtrl,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            onPageChanged: (page) {
              if (!mounted) return;
              if (page == 1) _refreshHomeDate();
              setState(() => _currentPage = page);
            },
            children: [
              // Page 0 (Slide Left): Full Focus Clock Face
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: const FocusClockTab(),
                ),
              ),

              // Page 1 (Center): Focus Clock Home View (Loop Habits + Google Tasks)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: FocusClockHomeView(
                    onOpenFocusClock: () => _goToPage(0),
                    onOpenAppDrawer: () => _goToPage(2),
                  ),
                ),
              ),

              // Page 2 (Slide Right): Minimalist App Drawer (Niagara wave scrubber)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: MinimalistAppDrawer(
                    isActive: _currentPage == 2,
                    onBackToHome: () => _goToPage(1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
