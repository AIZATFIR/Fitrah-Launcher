import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/launcher_settings_provider.dart';
import '../services/app_launcher_service.dart';

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

            const SizedBox(height: 24),

            // Section dropdown items
            _buildDropdownTile(
              title: 'Customization',
              onTap: () => _showWallpaperPicker(context, settings, notifier),
            ),
            _buildDropdownTile(
              title: 'Home Screen',
              onTap: () => _showHomeCustomizationDialog(context, settings, notifier),
            ),
            _buildDropdownTile(
              title: 'App Drawer',
              onTap: () {},
            ),
            _buildDropdownTile(
              title: 'Interrupts',
              onTap: () => _showComingSoon(context, 'Interrupts'),
            ),
            _buildDropdownTile(
              title: 'Focus Mode',
              onTap: () => _showComingSoon(context, 'Focus Mode'),
            ),
            _buildDropdownTile(
              title: 'Font',
              onTap: () => _showFontPicker(context),
            ),
            _buildDropdownTile(
              title: 'Gestures',
              onTap: () => _showComingSoon(context, 'Gestures'),
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature akan segera hadir di pembaruan berikutnya!')),
    );
  }

  void _showWallpaperPicker(
    BuildContext context,
    dynamic settings,
    LauncherSettingsNotifier notifier,
  ) {
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
              const Text(
                'Pilih Wallpaper',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFF97316)),
                title: const Text('Campfire (Default Minimalist)', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Api unggun hangat di malam hari', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  notifier.setWallpaperType('campfire');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_2_rounded, color: Colors.white70),
                title: const Text('AMOLED Pure Black', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Hitam pekat hemat daya', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  notifier.setWallpaperType('amoled_black');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_android_rounded, color: Colors.white70),
                title: const Text('Device Wallpaper (Transparan)', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Gunakan wallpaper bawaan HP', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  notifier.setWallpaperType('device_transparent');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHomeCustomizationDialog(
    BuildContext context,
    dynamic settings,
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
              children: [
                const Text(
                  'Kustomisasi Tampilan Home',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: settings.showPrayerTimes,
                  activeColor: Colors.white,
                  title: const Text('Tampilkan Jadwal Sholat', style: TextStyle(color: Colors.white)),
                  onChanged: (v) {
                    notifier.togglePrayerTimes(v);
                    setLocal(() {});
                  },
                ),
                SwitchListTile(
                  value: settings.showDate,
                  activeColor: Colors.white,
                  title: const Text('Tampilkan Tanggal & Hijriah', style: TextStyle(color: Colors.white)),
                  onChanged: (v) {
                    notifier.setClockFormat(showDate: v);
                    setLocal(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFontPicker(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Font Montserrat aktif.')),
    );
  }
}
