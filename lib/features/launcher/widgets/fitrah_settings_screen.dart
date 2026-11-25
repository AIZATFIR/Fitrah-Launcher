import 'dart:async';
import 'drawer_preferences_controls.dart';
import 'launcher_action_feedback.dart';
import 'default_home_status_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/habit.dart';
import '../../../models/timer_session.dart';
import '../../../providers/providers.dart';
import '../../../core/theme.dart';
import '../../sadar/widgets/sadar_ypt_focus_view.dart';
import '../models/launcher_settings.dart';
import '../providers/launcher_settings_provider.dart';
import '../services/app_launcher_service.dart';
import '../services/screen_time_service.dart';
import 'launcher_customization_sheet.dart';

class FitrahSettingsScreen extends ConsumerStatefulWidget {
  const FitrahSettingsScreen({super.key});

  @override
  ConsumerState<FitrahSettingsScreen> createState() =>
      _FitrahSettingsScreenState();
}

class _FitrahSettingsScreenState extends ConsumerState<FitrahSettingsScreen>
    with WidgetsBindingObserver {
  final _screenTime = ScreenTimeService();
  bool _usageGranted = false;
  bool _overlayGranted = false;
  bool _cueActive = false;
  bool _cueWindowFailed = false;
  bool _goalCuePermissionGranted = false;
  bool _goalCuePermissionDenied = false;
  bool _goalCuePreferenceSaveFailed = false;
  Completer<void>? _settingsReturn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshScreenTimePermissions();
    _refreshGoalCuePermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!(_settingsReturn?.isCompleted ?? true)) _settingsReturn?.complete();
      _refreshScreenTimePermissions();
      _refreshGoalCuePermission();
    }
  }

  Future<void> _refreshScreenTimePermissions() async {
    final usage = await _screenTime.hasUsageAccess();
    final overlay = await _screenTime.hasOverlayAccess();
    if (!mounted) return;
    setState(() {
      _usageGranted = usage;
      _overlayGranted = overlay;
    });
    final settings = ref.read(launcherSettingsProvider);
    final cueActive = await _screenTime.sync(
      cueEnabled: await _screenTime.cueAvailable(
        optedIn: settings.screenTimeCueEnabled,
      ),
    );
    if (!mounted) return;
    setState(() {
      _cueActive = cueActive;
      _cueWindowFailed =
          settings.screenTimeCueEnabled && usage && overlay && !cueActive;
    });
  }

  bool get _androidOnly =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _refreshGoalCuePermission() async {
    await ref.read(launcherSettingsProvider.notifier).hydration;
    if (!mounted) return;
    if (!ref.read(launcherSettingsProvider).lockScreenGoalCueEnabled) {
      setState(() {
        _goalCuePermissionGranted = false;
        _goalCuePermissionDenied = false;
      });
      return;
    }
    final granted = await ref
        .read(notificationServiceProvider)
        .goalCuePermissionGranted();
    if (!mounted) return;
    setState(() {
      _goalCuePermissionGranted = granted;
      _goalCuePermissionDenied = false;
    });
  }

  Future<void> _toggleGoalCue(bool enabled) async {
    final notifications = ref.read(notificationServiceProvider);
    final notifier = ref.read(launcherSettingsProvider.notifier);
    if (!enabled) {
      final saved = await notifier.setLockScreenGoalCueEnabled(false);
      await notifications.cancelPinnedGoal();
      if (mounted) {
        setState(() {
          _goalCuePermissionDenied = false;
          _goalCuePreferenceSaveFailed = !saved;
        });
      }
      return;
    }
    final granted = _goalCuePermissionGranted
        ? true
        : await notifications.requestGoalCuePermission();
    if (!granted) {
      await notifications.cancelPinnedGoal();
      if (mounted) {
        setState(() {
          _goalCuePermissionGranted = false;
          _goalCuePermissionDenied = true;
          _goalCuePreferenceSaveFailed = false;
        });
      }
      return;
    }
    final saved = await notifier.setLockScreenGoalCueEnabled(true);
    if (!saved) await notifications.cancelPinnedGoal();
    if (mounted) {
      setState(() {
        _goalCuePermissionGranted = true;
        _goalCuePermissionDenied = false;
        _goalCuePreferenceSaveFailed = !saved;
      });
    }
  }

  Future<bool> _explainAndOpen(String capability) async {
    final isUsage = capability == 'Usage Access';
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$capability diperlukan'),
        content: Text(
          isUsage
              ? 'Fitrah membaca total waktu layar hari ini dari Android. Data yang tidak tersedia akan ditandai, bukan dianggap nol.'
              : 'Android meminta izin tampil di atas aplikasi lain agar cue kecil dan tombol Tujuan tetap terlihat. Sentuhan di luar cue tetap menuju aplikasi di bawahnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
    if (open != true) return false;
    final returned = Completer<void>();
    _settingsReturn = returned;
    bool opened;
    if (isUsage) {
      opened = await _screenTime.openUsageSettings();
    } else {
      opened = await _screenTime.openOverlaySettings();
    }
    if (!opened) {
      _settingsReturn = null;
      return false;
    }
    try {
      await returned.future.timeout(const Duration(minutes: 5));
    } on TimeoutException {
      return false;
    } finally {
      if (identical(_settingsReturn, returned)) _settingsReturn = null;
    }
    if (!mounted) return false;
    final granted = isUsage
        ? await _screenTime.hasUsageAccess()
        : await _screenTime.hasOverlayAccess();
    setState(() {
      if (isUsage) {
        _usageGranted = granted;
      } else {
        _overlayGranted = granted;
      }
    });
    return granted;
  }

  Future<void> _toggleCue(bool enabled) async {
    final notifier = ref.read(launcherSettingsProvider.notifier);
    if (!enabled) {
      await notifier.setScreenTimeCueEnabled(false);
      await _refreshScreenTimePermissions();
      return;
    }
    if (!_usageGranted && !await _explainAndOpen('Usage Access')) return;
    if (!_overlayGranted && !await _explainAndOpen('Izin overlay')) return;
    if (!_usageGranted || !_overlayGranted) return;
    await notifier.setScreenTimeCueEnabled(true);
    await _refreshScreenTimePermissions();
  }

  Future<void> _toggleLimit(bool enabled) async {
    if (enabled && !_usageGranted && !await _explainAndOpen('Usage Access')) {
      return;
    }
    await ref
        .read(launcherSettingsProvider.notifier)
        .setGentleLimitEnabled(enabled);
    await _refreshScreenTimePermissions();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(launcherSettingsProvider);
    final notifier = ref.read(launcherSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppPalette.bg,
      appBar: AppBar(
        backgroundColor: AppPalette.bg,
        elevation: 0,
        title: const Text('Pengaturan Launcher'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                _buildScreenTimeSection(settings),
                if (_androidOnly) _buildGoalCueSection(settings),
                const SizedBox(height: 20),
                const DrawerPreferencesControls(),

                const SizedBox(height: 24),

                // Section dropdown items
                _buildDropdownTile(
                  title: 'Kustomisasi',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const LauncherCustomizationSheet(),
                    );
                  },
                ),
                _buildDropdownTile(
                  title: 'Tema dan warna aksen',
                  onTap: () =>
                      _showThemePaletteSheet(context, settings, notifier),
                ),
                _buildDropdownTile(
                  title: 'Layar utama',
                  onTap: () => _showHomeCustomizationDialog(context),
                ),
                _buildDropdownTile(
                  title: 'Daftar aplikasi',
                  onTap: () => _showAppDrawerSheet(context),
                ),
                _buildDropdownTile(
                  title: 'Notifikasi',
                  onTap: () => _showInterruptsSheet(context),
                ),
                _buildDropdownTile(
                  title: 'Mode fokus',
                  onTap: () => _showFocusModeSheet(context),
                ),
                _buildDropdownTile(
                  title: 'Jenis huruf',
                  onTap: () => _showFontPicker(context),
                ),
                _buildDropdownTile(
                  title: 'Gestur',
                  onTap: () => _showGesturesSheet(context),
                ),
                _buildDropdownTile(
                  title: 'Lainnya',
                  onTap: () => _showMoreSheet(context),
                ),

                const SizedBox(height: 16),

                // Plain Action Items
                _buildPlainTile(
                  title: 'Beri ulasan di Play Store',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Halaman Play Store belum tersedia. Kirim masukan lewat Lainnya > Dukungan via email.',
                        ),
                      ),
                    );
                  },
                ),
                _buildPlainTile(
                  title: 'Pengaturan aplikasi beranda',
                  onTap: () {
                    runLauncherAction(
                      context,
                      ref.read(appLauncherServiceProvider),
                      (service) => service.openHomeSettings(),
                    );
                  },
                ),
                const DefaultHomeStatusControl(),

                const SizedBox(height: 40),

                // Bottom Right Version
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 24, right: 4),
                    child: Text(
                      'Focus Clock',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white38,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreenTimeSection(LauncherSettings settings) {
    final android = _screenTime.supported;
    final usageLabel = _usageGranted
        ? 'Usage Access aktif'
        : 'Usage Access belum diizinkan';
    final overlayLabel = _overlayGranted
        ? 'Overlay aktif'
        : 'Overlay belum diizinkan';
    return Card(
      color: AppPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppPalette.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Waktu layar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppPalette.bookpaperText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Cue kecil dan batas harian yang lembut. Keduanya mati secara default.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.textDim),
            ),
            const SizedBox(height: 10),
            if (android) ...[
              _permissionStatus(usageLabel),
              _permissionStatus(overlayLabel),
              _permissionStatus(
                _cueActive
                    ? 'Cue aktif'
                    : _cueWindowFailed
                    ? 'Android belum dapat menampilkan cue'
                    : 'Cue tidak aktif',
              ),
            ] else
              _permissionStatus('Fitur waktu layar tersedia di Android.'),
            SwitchListTile.adaptive(
              key: const ValueKey('screen-time-cue-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Tampilkan cue waktu layar'),
              subtitle: const Text(
                'Menampilkan menit hari ini dan aksi Tujuan.',
              ),
              value: settings.screenTimeCueEnabled,
              onChanged: android ? _toggleCue : null,
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Batas harian lembut'),
              subtitle: const Text(
                'Jeda singkat saat membuka aplikasi dari drawer Fitrah.',
              ),
              value: settings.gentleLimitEnabled,
              onChanged: android ? _toggleLimit : null,
            ),
            if (android) ...[
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _numberSetting(
                    'Batas',
                    settings.dailyLimitMinutes,
                    'menit',
                    const [30, 60, 90, 120, 180, 240],
                    (value) => ref
                        .read(launcherSettingsProvider.notifier)
                        .setScreenTimeThreshold(limitMinutes: value),
                  ),
                  _numberSetting(
                    'Jeda',
                    settings.gentleWaitSeconds,
                    'detik',
                    const [10, 20, 30, 60],
                    (value) => ref
                        .read(launcherSettingsProvider.notifier)
                        .setScreenTimeThreshold(waitSeconds: value),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Aplikasi sistem dan jalur darurat tetap dapat digunakan. Statistik bisa tidak tersedia bila akses dicabut.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPalette.textDim),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCueSection(LauncherSettings settings) {
    final status = _goalCuePreferenceSaveFailed
        ? 'Pengaturan belum tersimpan. Coba lagi.'
        : _goalCuePermissionDenied
        ? 'Pengingat belum aktif. Izinkan notifikasi Android untuk menyalakannya.'
        : settings.lockScreenGoalCueEnabled && !_goalCuePermissionGranted
        ? 'Notifikasi Android dinonaktifkan; tujuan tidak ditampilkan.'
        : _goalCuePermissionGranted
        ? 'Akses notifikasi Android tersedia.'
        : 'Belum aktif.';
    return Card(
      color: AppPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppPalette.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tujuan di layar kunci',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppPalette.bookpaperText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Menampilkan tujuan pilihanmu di notifikasi perangkat ini. Teks mengikuti pengaturan privasi layar kunci Android.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.textDim),
            ),
            const SizedBox(height: 8),
            _permissionStatus(status),
            SwitchListTile.adaptive(
              key: const ValueKey('lock-screen-goal-cue-switch'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Tampilkan tujuan pilihan'),
              subtitle: const Text(
                'Mati secara default; bisa dimatikan kapan saja.',
              ),
              value: settings.lockScreenGoalCueEnabled,
              onChanged: _toggleGoalCue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionStatus(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        const Icon(Icons.circle, size: 7, color: AppPalette.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppPalette.textDim, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _numberSetting(
    String label,
    int value,
    String unit,
    List<int> choices,
    ValueChanged<int> onChanged,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$label ', style: const TextStyle(color: AppPalette.text)),
      Flexible(
        child: DropdownButton<int>(
          isExpanded: true,
          value: choices.contains(value) ? value : null,
          hint: Text(
            '$value',
            style: const TextStyle(color: AppPalette.bookpaperText),
          ),
          dropdownColor: AppPalette.cardHigh,
          items: choices
              .map(
                (choice) => DropdownMenuItem(
                  value: choice,
                  child: Text('$choice $unit'),
                ),
              )
              .toList(),
          onChanged: (choice) {
            if (choice != null) onChanged(choice);
          },
        ),
      ),
    ],
  );

  Widget _buildDropdownTile({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlainTile({required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPlainTile(
                title: 'Support via Email',
                onTap: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(
                    'mailto:aizatfir@gmail.com?subject=Fitrah%20Launcher%20Support',
                  );
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
              ),
              _buildPlainTile(
                title: 'GitHub Repository',
                onTap: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(
                    'https://github.com/AIZATFIR/Fitrah-Launcher',
                  );
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
              ),
              _buildPlainTile(
                title: 'Credits & Open Source Licenses',
                onTap: () {
                  Navigator.pop(ctx);
                  showLicensePage(
                    context: context,
                    applicationName: 'Fitrah Launcher',
                    applicationVersion: '0.5.3',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHomeCustomizationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final settings = ref.watch(launcherSettingsProvider);
          final notifier = ref.read(launcherSettingsProvider.notifier);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kustomisasi Tampilan Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Widget Utama Layar Depan:',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            notifier.setWidgetDisplayMode('prayer');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: settings.widgetDisplayMode != 'focus_clock'
                                  ? Colors.white.withOpacity(0.2)
                                  : const Color(0xFF222226),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    settings.widgetDisplayMode != 'focus_clock'
                                    ? Colors.white
                                    : Colors.white24,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Waktu Sholat',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            notifier.setWidgetDisplayMode('focus_clock');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: settings.widgetDisplayMode == 'focus_clock'
                                  ? Colors.white.withOpacity(0.2)
                                  : const Color(0xFF222226),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    settings.widgetDisplayMode == 'focus_clock'
                                    ? Colors.white
                                    : Colors.white24,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Focus Events',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.showPrayerTimes,
                    activeColor: Colors.white,
                    title: const Text(
                      'Tampilkan Baris Waktu Sholat',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    onChanged: (v) {
                      notifier.togglePrayerTimes(v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.showDate,
                    activeColor: Colors.white,
                    title: const Text(
                      'Tampilkan Tanggal & Hijriah',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    onChanged: (v) {
                      notifier.setClockFormat(showDate: v);
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Buka Kustomisasi Lengkap',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const LauncherCustomizationSheet(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAppDrawerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengaturan App Drawer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              DrawerPreferencesControls(),
              SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.swipe_left_rounded, color: Colors.white70),
                title: Text(
                  'Cara Akses App Drawer',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  'Geser layar utama ke kiri untuk membuka daftar aplikasi. Gunakan pencarian untuk menemukan aplikasi.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInterruptsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Akses Pengaturan Notifikasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Fitrah Launcher belum menyaring notifikasi. Tombol ini hanya membuka pengaturan akses notifikasi Android; aktifkan akses hanya jika Anda memahami izinnya.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.security_rounded,
                    size: 18,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Buka Pengaturan Akses Notifikasi',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    runLauncherAction(
                      context,
                      ref.read(appLauncherServiceProvider),
                      (service) => service.openNotificationListenerSettings(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFocusModeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Mulai Sesi Fokus Sadar (YPT)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Kunci layar ke mode fokus penuh layaknya Yeolpumpta (YPT) untuk belajar atau bekerja tanpa distraksi.',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.amber,
                ),
                title: const Text(
                  '25 Menit (Pomodoro Sprint)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Fokus singkat terarah',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () =>
                    _launchFocusSession(context, 25, 'Pomodoro Sprint'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.psychology_rounded,
                  color: Color(0xFF38BDF8),
                ),
                title: const Text(
                  '50 Menit (Deep Work)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Ideal untuk belajar / ngoding',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () =>
                    _launchFocusSession(context, 50, 'Deep Work Session'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.all_inclusive_rounded,
                  color: Color(0xFF34D399),
                ),
                title: const Text(
                  '90 Menit (Flow State)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Siklus ritme ultradian optimal',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () => _launchFocusSession(context, 90, 'Flow State'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchFocusSession(BuildContext context, int minutes, String title) {
    Navigator.pop(context);
    final habit = Habit()
      ..name = title
      ..target = minutes
      ..habitType = 'timed'
      ..unit = HabitUnit.min;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SadarYptFocusView(
          habit: habit,
          sessionSourceKind: TimerSessionSourceKind.preset,
          sourceIdentity: 'focus-preset:$minutes',
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showGesturesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.gesture_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Panduan Gestur Launcher',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildGestureRow(
                icon: Icons.swipe_up_rounded,
                title: 'Geser ke Kiri dari Home',
                desc: 'Membuka daftar aplikasi.',
              ),
              const SizedBox(height: 12),
              _buildGestureRow(
                icon: Icons.swipe_left_rounded,
                title: 'Geser ke Kanan dari Home',
                desc: 'Membuka halaman Focus Clock.',
              ),
              const SizedBox(height: 12),
              _buildGestureRow(
                icon: Icons.touch_app_rounded,
                title: 'Tap tab Jadwal / Sholat',
                desc: 'Beralih antara agenda hari ini dan waktu sholat.',
              ),
              const SizedBox(height: 12),
              _buildGestureRow(
                icon: Icons.back_hand_rounded,
                title: 'Tekan & Tahan Layar Fokus',
                desc: 'Keluar darurat dari sesi fokus penuh (Hold to Exit)',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGestureRow({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFontPicker(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Font antarmuka saat ini Inter. Pilihan font belum tersedia.',
        ),
      ),
    );
  }

  void _showThemePaletteSheet(
    BuildContext context,
    LauncherSettings settings,
    LauncherSettingsNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Tema & Warna Aksen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ubah suasana visual seluruh launcher',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 18),
              _buildPaletteOption(
                ctx,
                title: 'Matcha Green (Tenang & Segar)',
                key: 'fino_green',
                color: const Color(0xFF70C050),
                current: settings.themePalette,
                notifier: notifier,
              ),
              _buildPaletteOption(
                ctx,
                title: 'Sky Blue (Fokus & Jernih)',
                key: 'sky_blue',
                color: const Color(0xFF38BDF8),
                current: settings.themePalette,
                notifier: notifier,
              ),
              _buildPaletteOption(
                ctx,
                title: 'Deep Ocean (Aliran Dalam)',
                key: 'ocean_blue',
                color: const Color(0xFF0284C7),
                current: settings.themePalette,
                notifier: notifier,
              ),
              _buildPaletteOption(
                ctx,
                title: 'Bookpaper',
                key: 'full_book',
                color: AppPalette.accent,
                current: settings.themePalette,
                notifier: notifier,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaletteOption(
    BuildContext context, {
    required String title,
    required String key,
    required Color color,
    required String current,
    required LauncherSettingsNotifier notifier,
  }) {
    final isSelected = current == key;
    return InkWell(
      onTap: () async {
        HapticFeedback.selectionClick();
        final saved = await notifier.setThemePalette(key);
        if (!context.mounted) return;
        if (saved) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tema belum tersimpan. Coba lagi.')),
          );
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
