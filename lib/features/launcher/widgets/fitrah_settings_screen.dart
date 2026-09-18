import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/habit.dart';
import '../../sadar/widgets/sadar_ypt_focus_view.dart';
import '../models/launcher_settings.dart';
import '../providers/launcher_settings_provider.dart';
import '../services/app_launcher_service.dart';
import 'launcher_customization_sheet.dart';

class FitrahSettingsScreen extends ConsumerStatefulWidget {
  const FitrahSettingsScreen({super.key});

  @override
  ConsumerState<FitrahSettingsScreen> createState() => _FitrahSettingsScreenState();
}

class _FitrahSettingsScreenState extends ConsumerState<FitrahSettingsScreen> {
  bool _showAppIcons = false;
  bool _useDeviceWallpaper = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(launcherSettingsProvider);
    final notifier = ref.read(launcherSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            // Top Description
            const Padding(
              padding: EdgeInsets.only(bottom: 28),
              child: Text(
                'Remove distractions from notifications by filtering out unnecessary notifications from the apps you choose',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),

            // 1. Show App Icons switch
            _buildSwitchTile(
              title: 'Show App Icons',
              value: _showAppIcons,
              onChanged: (val) {
                setState(() => _showAppIcons = val);
              },
            ),

            const SizedBox(height: 16),

            // 2. Use device wallpaper ★ switch
            _buildSwitchTile(
              title: 'Use device wallpaper ★',
              value: _useDeviceWallpaper,
              onChanged: (val) {
                setState(() => _useDeviceWallpaper = val);
                if (val) {
                  notifier.setWallpaperType('custom');
                } else {
                  notifier.setWallpaperType('campfire');
                }
              },
            ),

            const SizedBox(height: 16),

            // 3. Auto open keyboard on Apps switch
            _buildSwitchTile(
              title: 'Auto Open Keyboard on Apps',
              value: settings.autoFocusSearch,
              onChanged: (val) {
                notifier.setAutoFocusSearch(val);
              },
            ),

            const SizedBox(height: 24),

            // Section dropdown items
            _buildDropdownTile(
              title: 'Customization',
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
              title: 'Home Screen',
              onTap: () => _showHomeCustomizationDialog(context, settings, notifier),
            ),
            _buildDropdownTile(
              title: 'App Drawer',
              onTap: () => _showAppDrawerSheet(context),
            ),
            _buildDropdownTile(
              title: 'Interrupts',
              onTap: () => _showInterruptsSheet(context),
            ),
            _buildDropdownTile(
              title: 'Focus Mode',
              onTap: () => _showFocusModeSheet(context),
            ),
            _buildDropdownTile(
              title: 'Font',
              onTap: () => _showFontPicker(context),
            ),
            _buildDropdownTile(
              title: 'Gestures',
              onTap: () => _showGesturesSheet(context),
            ),
            _buildDropdownTile(
              title: 'More',
              onTap: () => _showMoreSheet(context),
            ),

            const SizedBox(height: 16),

            // Plain Action Items
            _buildPlainTile(
              title: 'Rate us on Play Store',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Terima kasih atas dukungannya! ⭐')),
                );
              },
            ),
            _buildPlainTile(
              title: 'Device Settings',
              onTap: () {
                ref.read(appLauncherServiceProvider).openHomeSettings();
              },
            ),
            _buildPlainTile(
              title: 'Change Default Launcher',
              onTap: () {
                HapticFeedback.mediumImpact();
                ref.read(appLauncherServiceProvider).openHomeSettings();
              },
            ),

            const SizedBox(height: 40),

            // Bottom Right Version
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: 24, right: 4),
                child: Text(
                  'Version 5.17',
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
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.white38,
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

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

  Widget _buildPlainTile({
    required String title,
    required VoidCallback onTap,
  }) {
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
                  final uri = Uri.parse('mailto:aizatfir@gmail.com?subject=Fitrah%20Launcher%20Support');
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
              ),
              _buildPlainTile(
                title: 'GitHub Repository',
                onTap: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse('https://github.com/AIZATFIR/Fitrah-Launcher');
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
              ),
              _buildPlainTile(
                title: 'Credits & Open Source Licenses',
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _showHomeCustomizationDialog(
    BuildContext context,
    LauncherSettings settings,
    LauncherSettingsNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kustomisasi Tampilan Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
                          setLocal(() {});
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
                              color: settings.widgetDisplayMode != 'focus_clock'
                                  ? Colors.white
                                  : Colors.white24,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '🕌 Waktu Sholat',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
                          setLocal(() {});
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
                              color: settings.widgetDisplayMode == 'focus_clock'
                                  ? Colors.white
                                  : Colors.white24,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '⏱️ Focus Events',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
                  title: const Text('Tampilkan Baris Waktu Sholat', style: TextStyle(color: Colors.white, fontSize: 14)),
                  onChanged: (v) {
                    notifier.togglePrayerTimes(v);
                    setLocal(() {});
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: settings.showDate,
                  activeColor: Colors.white,
                  title: const Text('Tampilkan Tanggal & Hijriah', style: TextStyle(color: Colors.white, fontSize: 14)),
                  onChanged: (v) {
                    notifier.setClockFormat(showDate: v);
                    setLocal(() {});
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.tune_rounded, size: 16, color: Colors.white),
                    label: const Text('Buka Kustomisasi Lengkap', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        ),
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pengaturan App Drawer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _showAppIcons,
                  activeColor: Colors.white,
                  title: const Text('Tampilkan Ikon Aplikasi', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Menampilkan ikon warna-warni di samping nama aplikasi', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onChanged: (val) {
                    setState(() => _showAppIcons = val);
                    setLocal(() {});
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.swipe_up_rounded, color: Colors.white70),
                  title: const Text('Cara Akses App Drawer', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Geser ke atas dari layar utama atau ketuk tombol search lonjong di tengah layar.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ],
            ),
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
                  Icon(Icons.notifications_off_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Filter Gangguan Notifikasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Fitrah Launcher membantu menjaga fokus Anda dengan menyaring notifikasi acak dari media sosial dan game selama jam produktif dan waktu ibadah.',
                style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.security_rounded, size: 18, color: Colors.black),
                  label: const Text('Buka Pengaturan Notifikasi HP', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(appLauncherServiceProvider).openNotificationListenerSettings();
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
                leading: const Icon(Icons.flash_on_rounded, color: Colors.amber),
                title: const Text('25 Menit (Pomodoro Sprint)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Fokus singkat terarah', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () => _launchFocusSession(context, 25, 'Pomodoro Sprint'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.psychology_rounded, color: Color(0xFF38BDF8)),
                title: const Text('50 Menit (Deep Work)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Ideal untuk belajar / ngoding', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () => _launchFocusSession(context, 50, 'Deep Work Session'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.all_inclusive_rounded, color: Color(0xFF34D399)),
                title: const Text('90 Menit (Flow State)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text('Siklus ritme ultradian optimal', style: TextStyle(color: Colors.white54, fontSize: 12)),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildGestureRow(
                icon: Icons.swipe_up_rounded,
                title: 'Geser ke Atas',
                desc: 'Membuka Laci Aplikasi (App Drawer)',
              ),
              const SizedBox(height: 12),
              _buildGestureRow(
                icon: Icons.swipe_left_rounded,
                title: 'Geser ke Kiri / Tap Jam',
                desc: 'Membuka dial 24 jam Focus Clock',
              ),
              const SizedBox(height: 12),
              _buildGestureRow(
                icon: Icons.touch_app_rounded,
                title: 'Tap Tab Sholat / Focus',
                desc: 'Beralih antara jadwal sholat dan kartu event harian',
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
      const SnackBar(content: Text('Font Montserrat aktif.')),
    );
  }
}
