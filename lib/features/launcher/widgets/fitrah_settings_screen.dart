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
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. 100% Free Forever Card
            _buildTopActionCard(
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFFE11D48),
              iconBgColor: const Color(0xFF27151A),
              title: '100% FREE FOREVER',
              subtitle: 'Support through Sadaqah\n(voluntary giving)',
              onTap: () async {
                HapticFeedback.lightImpact();
                final uri = Uri.parse('https://github.com/sponsors/AIZATFIR');
                if (await canLaunchUrl(uri)) launchUrl(uri);
              },
            ),

            const SizedBox(height: 12),

            // 2. Rate Us Card
            _buildTopActionCard(
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFFBBF24),
              iconBgColor: const Color(0xFF292212),
              title: 'RATE US',
              subtitle: 'Help others discover this free Islamic app',
              borderColor: const Color(0xFF534117),
              onTap: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Terima kasih atas dukungannya! ⭐')),
                );
              },
            ),

            const SizedBox(height: 28),

            // APPEARANCE SECTION
            _buildSectionHeader('APPEARANCE'),
            const SizedBox(height: 8),
            _buildCardGroup([
              _buildSettingTile(
                icon: Icons.home_outlined,
                title: 'Home Customization',
                subtitle: 'Customize as you prefer',
                onTap: () => _showHomeCustomizationDialog(context, settings, notifier),
              ),
              _buildSettingTile(
                icon: Icons.font_download_outlined,
                title: 'Font Style',
                subtitle: 'Montserrat / Outfit',
                onTap: () => _showFontPicker(context),
              ),
              _buildSettingTile(
                icon: Icons.text_fields_rounded,
                title: 'Font Size',
                subtitle: 'Normal',
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.wallpaper_rounded,
                title: 'Wallpaper',
                subtitle: settings.wallpaperType == 'campfire'
                    ? 'Campfire (Default)'
                    : (settings.wallpaperType == 'amoled_black' ? 'AMOLED Black' : 'Custom'),
                onTap: () => _showWallpaperPicker(context, settings, notifier),
              ),
              _buildSettingTile(
                icon: Icons.palette_outlined,
                title: 'Theme Color',
                subtitle: 'White',
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.access_time_rounded,
                title: 'Time Format',
                subtitle: settings.is24h ? '24-Hour' : '12-Hour',
                onTap: () {
                  HapticFeedback.selectionClick();
                  notifier.setClockFormat(is24h: !settings.is24h);
                },
              ),
              _buildSettingTile(
                icon: Icons.touch_app_outlined,
                title: 'Icon Style',
                subtitle: 'Minimal Text Only',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 28),

            // QURAN SECTION
            _buildSectionHeader('QURAN'),
            const SizedBox(height: 8),
            _buildCardGroup([
              _buildSettingTile(
                icon: Icons.translate_rounded,
                title: 'Arabic Font',
                subtitle: 'System Default',
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.menu_book_rounded,
                title: 'Quran Settings',
                subtitle: 'Reciter, translation, tafseer & downloads',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 28),

            // DIGITAL WELLBEING SECTION
            _buildSectionHeader('DIGITAL WELLBEING'),
            const SizedBox(height: 8),
            _buildCardGroup([
              _buildSettingTile(
                icon: Icons.phonelink_erase_rounded,
                title: 'App Interrupts',
                subtitle: 'Reduce distractions from apps',
                onTap: () => _showComingSoon(context, 'App Interrupts'),
              ),
              _buildSettingTile(
                icon: Icons.lock_clock_rounded,
                title: 'Focus Mode',
                subtitle: 'Block distracting apps during focus',
                onTap: () => _showComingSoon(context, 'Focus Mode'),
              ),
              _buildSettingTile(
                icon: Icons.shield_outlined,
                title: 'Khandaq Mode',
                subtitle: 'Timed digital fortress mode',
                onTap: () => _showComingSoon(context, 'Khandaq Mode'),
              ),
              _buildSettingTile(
                icon: Icons.block_rounded,
                title: 'App Blocker',
                subtitle: 'Block apps for specific durations',
                onTap: () => _showComingSoon(context, 'App Blocker'),
              ),
            ]),

            const SizedBox(height: 28),

            // SYSTEM SECTION
            _buildSectionHeader('SYSTEM'),
            const SizedBox(height: 8),
            _buildCardGroup([
              _buildSettingTile(
                icon: Icons.home_filled,
                title: 'Change Default Launcher',
                subtitle: 'Set as default home app',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(appLauncherServiceProvider).openHomeSettings();
                },
              ),
            ]),

            const SizedBox(height: 28),

            // SUPPORT SECTION
            _buildSectionHeader('SUPPORT'),
            const SizedBox(height: 8),
            _buildCardGroup([
              _buildSettingTile(
                icon: Icons.mail_outline_rounded,
                title: 'Support via Email',
                subtitle: 'Get help or report an issue',
                onTap: () async {
                  final uri = Uri.parse('mailto:aizatfir@gmail.com?subject=Fitrah%20Launcher%20Support');
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
              ),
              _buildSettingTile(
                icon: Icons.forum_outlined,
                title: 'Join Community',
                subtitle: 'Connect with the community',
                onTap: () async {
                  final uri = Uri.parse('https://github.com/AIZATFIR/Fitrah-Launcher');
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
              ),
              _buildSettingTile(
                icon: Icons.share_outlined,
                title: 'Recommend to a Friend',
                subtitle: 'Share the app with others',
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.person_outline_rounded,
                title: 'Connect with Developer',
                subtitle: 'Follow on GitHub / LinkedIn',
                onTap: () async {
                  final uri = Uri.parse('https://github.com/AIZATFIR');
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
              ),
            ]),

            const SizedBox(height: 28),

            // ABOUT SECTION
            _buildSectionHeader('ABOUT'),
            const SizedBox(height: 8),
            _buildCardGroup([
              _buildSettingTile(
                icon: Icons.info_outline_rounded,
                title: 'Version',
                subtitle: 'v0.3.0',
                onTap: () {},
              ),
              _buildSettingTile(
                icon: Icons.description_outlined,
                title: 'Credits & Licenses',
                subtitle: 'Islamic & minimal open source community',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildTopActionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF161618),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? const Color(0xFF26262B), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF232327), width: 1.0),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 18),
          ],
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
