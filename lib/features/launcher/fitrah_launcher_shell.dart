import 'dart:async';
import 'dart:ui' show ImageFilter;

import '../../core/time_math.dart';
import '../../core/theme.dart';
import '../../providers/providers.dart';
import '../../providers/intent_providers.dart';
import '../../domain/focus_intent.dart';
import 'models/launcher_settings.dart';
import 'providers/launcher_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../focusclock/focusclock_tab.dart';
import 'widgets/focus_clock_home_view.dart';
import 'widgets/minimalist_app_drawer.dart';
import 'services/screen_time_service.dart';
import 'widgets/habit_library_view.dart';
import '../sadar/widgets/sadar_timer_view.dart';
import '../../models/habit.dart';

class FitrahLauncherShell extends ConsumerStatefulWidget {
  const FitrahLauncherShell({super.key, this.onExitLauncher});

  final VoidCallback? onExitLauncher;

  @override
  ConsumerState<FitrahLauncherShell> createState() =>
      _FitrahLauncherShellState();
}

class _FitrahLauncherShellState extends ConsumerState<FitrahLauncherShell>
    with WidgetsBindingObserver {
  static const _homeChannel = MethodChannel('fitrah_launcher/home');
  late final PageController _pageCtrl;
  bool _returningHome = false;
  final _screenTime = ScreenTimeService();
  AsyncValue<IntentState> _goalState = const AsyncLoading();
  LauncherSettings _goalCueSettings = LauncherSettings();
  Future<void> _goalCueQueue = Future.value();
  late final StreamSubscription<void> _goalCueTapSubscription;
  late int _currentPage; // 0 = Clock, 1 = Home, 2 = Habits, 3 = Apps

  @override
  void initState() {
    super.initState();
    final initialPage = ref.read(selectedAppModeProvider) == 'focus' ? 0 : 1;
    _currentPage = initialPage;
    WidgetsBinding.instance.addObserver(this);
    _pageCtrl = PageController(initialPage: initialPage);
    _goalCueTapSubscription = ref
        .read(notificationServiceProvider)
        .goalCueTaps
        .listen((_) => _returnHome());
    _goalCueSettings = ref.read(launcherSettingsProvider);
    ref.listenManual<LauncherSettings>(launcherSettingsProvider, (_, next) {
      _goalCueSettings = next;
      _queueGoalCueReconciliation();
    }, fireImmediately: true);
    ref.listenManual<AsyncValue<IntentState>>(intentStateProvider, (_, next) {
      _goalState = next;
      _queueGoalCueReconciliation();
    }, fireImmediately: true);
    _homeChannel.setMethodCallHandler((call) async {
      if (call.method == 'home') await _returnHome();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(launcherSettingsProvider.notifier).hydration;
      if (mounted) {
        _syncScreenTime(ref.read(launcherSettingsProvider));
        if (ref.read(notificationServiceProvider).consumeGoalCueLaunch()) {
          _refreshHomeDate();
          if (_pageCtrl.hasClients) _pageCtrl.jumpToPage(1);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _goalCueTapSubscription.cancel();
    _homeChannel.setMethodCallHandler(null);
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncScreenTime(ref.read(launcherSettingsProvider));
      _queueGoalCueReconciliation();
    }
  }

  Future<void> _syncScreenTime(LauncherSettings settings) async {
    if (!mounted) return;
    await _screenTime.sync(
      cueEnabled: await _screenTime.cueAvailable(
        optedIn: settings.screenTimeCueEnabled,
      ),
    );
  }

  void _queueGoalCueReconciliation() {
    _goalCueQueue = _goalCueQueue
        .then((_) async {
          final settings = _goalCueSettings;
          final goal = _goalState.valueOrNull?.pinnedGoal;
          final notifications = ref.read(notificationServiceProvider);
          if (!settings.lockScreenGoalCueEnabled || goal == null) {
            await notifications.cancelPinnedGoal();
            return;
          }
          await notifications.showPinnedGoal(goal.title);
        })
        .catchError((_) {});
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

  void _openHabitTimer(Habit habit) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => SadarTimerView(
          habit: habit,
          onClose: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(launcherSettingsProvider);
    ref.listen<LauncherSettings>(launcherSettingsProvider, (_, next) {
      _syncScreenTime(next);
    });
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildWallpaper(settings),
            PageView(
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
                      onOpenAppDrawer: () => _goToPage(3),
                      onOpenHabits: () => _goToPage(2),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: HabitLibraryView(onStartTimer: _openHabitTimer),
                  ),
                ),

                // Page 3 (last): Minimalist App Drawer (Niagara wave scrubber)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: MinimalistAppDrawer(
                      isActive: _currentPage == 3,
                      onBackToHome: () => _goToPage(1),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWallpaper(LauncherSettings settings) {
    final color = switch (settings.wallpaperType) {
      'amoled_black' => const Color(0xFF000000),
      'midnight_slate' => const Color(0xFF0B111E),
      'forest_night' => const Color(0xFF0A150E),
      'deep_obsidian' => const Color(0xFF101014),
      'warm_charcoal' => const Color(0xFF161412),
      _ => AppPalette.bg,
    };
    final uri = Uri.tryParse(settings.customImageUrl);
    final canLoadImage =
        settings.wallpaperType == 'custom_image' &&
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          key: const ValueKey('launcher-wallpaper-base'),
          color: color,
        ),
        if (canLoadImage)
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: settings.wallpaperBlur,
              sigmaY: settings.wallpaperBlur,
            ),
            child: Image.network(
              settings.customImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(color: color),
            ),
          ),
        ColoredBox(
          color: Colors.black.withValues(alpha: settings.wallpaperDimming),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0x1A000000)],
            ),
          ),
        ),
      ],
    );
  }
}
