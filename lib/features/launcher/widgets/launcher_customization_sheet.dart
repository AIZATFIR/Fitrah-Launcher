import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../models/launcher_settings.dart';
import '../providers/launcher_settings_provider.dart';
import '../services/app_launcher_service.dart';

class LauncherCustomizationSheet extends ConsumerStatefulWidget {
  const LauncherCustomizationSheet({super.key});

  @override
  ConsumerState<LauncherCustomizationSheet> createState() =>
      _LauncherCustomizationSheetState();
}

class _LauncherCustomizationSheetState
    extends ConsumerState<LauncherCustomizationSheet> {
  final TextEditingController _urlCtrl = TextEditingController();

  static const List<Map<String, dynamic>> _wallpaperPresets = [
    {
      'id': 'amoled_black',
      'label': 'AMOLED Hitam',
      'color': Color(0xFF000000),
      'desc': 'Hemat daya baterai & minimalis murni',
    },
    {
      'id': 'midnight_slate',
      'label': 'Midnight Slate',
      'color': Color(0xFF0B111E),
      'desc': 'Nuansa gelap malam kebiruan tenang',
    },
    {
      'id': 'forest_night',
      'label': 'Forest Night',
      'color': Color(0xFF0A150E),
      'desc': 'Hijau alami zaitun malam',
    },
    {
      'id': 'deep_obsidian',
      'label': 'Deep Obsidian',
      'color': Color(0xFF101014),
      'desc': 'Batu obsidian arang monokrom',
    },
    {
      'id': 'warm_charcoal',
      'label': 'Warm Charcoal',
      'color': Color(0xFF161412),
      'desc': 'Cokelat hangat arang bersahaja',
    },
  ];

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _openDockSlotPicker(int slotIndex, String currentPkg) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppPalette.stroke),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, child) {
          final appsAsync = ref.watch(installedAppsFutureProvider);
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.65,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (ctx, scrollCtrl) {
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppPalette.stroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      'Pilih Aplikasi untuk Slot ${slotIndex + 1}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppPalette.text,
                      ),
                    ),
                  ),
                  const Divider(color: AppPalette.stroke, height: 1),
                  Expanded(
                    child: appsAsync.when(
                      data: (apps) {
                        return ListView.separated(
                          controller: scrollCtrl,
                          itemCount: apps.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: AppPalette.stroke, height: 1),
                          itemBuilder: (context, i) {
                            final app = apps[i];
                            final isSelected = app.packageName == currentPkg;
                            return ListTile(
                              leading: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppPalette.bg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppPalette.stroke),
                                ),
                                child: Center(
                                  child: Text(
                                    app.appName.isNotEmpty ? app.appName[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppPalette.accent,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                app.appName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppPalette.accent : AppPalette.text,
                                ),
                              ),
                              subtitle: Text(
                                app.packageName,
                                style: const TextStyle(fontSize: 10, color: AppPalette.textDim),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle_rounded, color: AppPalette.accent, size: 18)
                                  : null,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(launcherSettingsProvider.notifier)
                                    .setDockPackage(slotIndex, app.packageName);
                                Navigator.of(ctx).pop();
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(launcherSettingsProvider);
    final notifier = ref.read(launcherSettingsProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppPalette.stroke, width: 1.5)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppPalette.stroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  const Icon(Icons.tune_rounded, color: AppPalette.accent, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'PENGATURAN FITRAH LAUNCHER',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppPalette.text,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppPalette.textDim, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Android Default Home App Setting Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppPalette.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPalette.accent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.home_filled, size: 18, color: AppPalette.accent),
                        SizedBox(width: 8),
                        Text(
                          'Aplikasi Beranda Utama',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppPalette.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Jadikan Fitrah Launcher sebagai launcher default HP Android agar aktif setiap menekan tombol Home.',
                      style: TextStyle(fontSize: 12, color: AppPalette.textDim, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.accent,
                          foregroundColor: const Color(0xFF0F0F1A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ref.read(appLauncherServiceProvider).openHomeSettings();
                        },
                        icon: const Icon(Icons.launch_rounded, size: 16),
                        label: const Text(
                          'Buka Pengaturan Home App Android',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Wallpaper Selection & Customization
              const Text(
                'WALLPAPER & TAMPILAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppPalette.textDim,
                ),
              ),
              const SizedBox(height: 12),

              // Wallpaper Presets
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _wallpaperPresets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final preset = _wallpaperPresets[i];
                    final isSelected = settings.wallpaperType == preset['id'];
                    final color = preset['color'] as Color;

                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        notifier.setWallpaperType(preset['id'] as String);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 90,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppPalette.accent : AppPalette.stroke,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppPalette.accent.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: AppPalette.accent, size: 20)
                            else
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white30),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              preset['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppPalette.accent : AppPalette.text,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Custom Wallpaper Image Option
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppPalette.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: settings.wallpaperType == 'custom_image'
                        ? AppPalette.accent
                        : AppPalette.stroke,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, size: 18, color: AppPalette.accent),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Wallpaper Gambar Kustom',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppPalette.text),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _showCustomImageDialog(context, notifier, settings);
                      },
                      child: Text(
                        settings.wallpaperType == 'custom_image' ? 'Ubah URL / Gambar' : 'Pilih Gambar',
                        style: const TextStyle(fontSize: 12, color: AppPalette.accent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Dimming & Blur Sliders (For maintaining readability)
              Row(
                children: [
                  const Text(
                    'Kegelapan Wallpaper (Dimming)',
                    style: TextStyle(fontSize: 12, color: AppPalette.textDim),
                  ),
                  const Spacer(),
                  Text(
                    '${(settings.wallpaperDimming * 100).round()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppPalette.accent),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppPalette.accent,
                  inactiveTrackColor: AppPalette.stroke,
                  thumbColor: AppPalette.accent,
                  overlayColor: AppPalette.accent.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: settings.wallpaperDimming,
                  min: 0.0,
                  max: 0.9,
                  onChanged: (val) => notifier.setWallpaperDimming(val),
                ),
              ),

              Row(
                children: [
                  const Text(
                    'Efek Blur Wallpaper',
                    style: TextStyle(fontSize: 12, color: AppPalette.textDim),
                  ),
                  const Spacer(),
                  Text(
                    '${settings.wallpaperBlur.round()}px',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppPalette.accent),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppPalette.accent,
                  inactiveTrackColor: AppPalette.stroke,
                  thumbColor: AppPalette.accent,
                  overlayColor: AppPalette.accent.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: settings.wallpaperBlur,
                  min: 0.0,
                  max: 15.0,
                  onChanged: (val) => notifier.setWallpaperBlur(val),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Customize 4 Dock Slots
              const Text(
                'ATUR 4 TOMBOL DOCK BAWAH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppPalette.textDim,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: List.generate(4, (index) {
                  final pkg = index < settings.dockPackages.length
                      ? settings.dockPackages[index]
                      : 'com.android.browser';
                  final slotLabel = _getShortSlotLabel(pkg, index);

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                      child: InkWell(
                        onTap: () => _openDockSlotPicker(index, pkg),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppPalette.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppPalette.stroke),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Slot ${index + 1}',
                                style: const TextStyle(fontSize: 9, color: AppPalette.textDim),
                              ),
                              const SizedBox(height: 4),
                              Icon(_getSlotIcon(pkg, index), size: 20, color: AppPalette.accent),
                              const SizedBox(height: 4),
                              Text(
                                slotLabel,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppPalette.text),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // 4. Clock & Widget Toggles
              const Text(
                'JAM & TAMPILAN BERANDA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppPalette.textDim,
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppPalette.accent,
                title: const Text('Format Jam 24 Jam', style: TextStyle(fontSize: 13, color: AppPalette.text)),
                value: settings.is24h,
                onChanged: (val) => notifier.setClockFormat(is24h: val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppPalette.accent,
                title: const Text('Tampilkan Detik', style: TextStyle(fontSize: 13, color: AppPalette.text)),
                value: settings.showSeconds,
                onChanged: (val) => notifier.setClockFormat(showSeconds: val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppPalette.accent,
                title: const Text('Kartu Event Sedang Berlangsung', style: TextStyle(fontSize: 13, color: AppPalette.text)),
                value: settings.showHeroEvent,
                onChanged: (val) => notifier.toggleWidget(showHero: val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppPalette.accent,
                title: const Text('Daftar Agenda Focus Clock Hari Ini', style: TextStyle(fontSize: 13, color: AppPalette.text)),
                value: settings.showAgendaWidget,
                onChanged: (val) => notifier.toggleWidget(showAgenda: val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppPalette.accent,
                title: const Text('Daftar Kebiasaan Fitrah / Sadar', style: TextStyle(fontSize: 13, color: AppPalette.text)),
                value: settings.showHabitsWidget,
                onChanged: (val) => notifier.toggleWidget(showHabits: val),
              ),

              const SizedBox(height: 20),

              // 5. Prayer Times Section (Muslim Anchor)
              const Text(
                'WAKTU SHOLAT & FITRAH (MUSLIM ONLY)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppPalette.textDim,
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppPalette.accent,
                title: const Text('Tampilkan Waktu Sholat di Garis Waktu', style: TextStyle(fontSize: 13, color: AppPalette.text)),
                subtitle: const Text('Menyelaraskan kegiatan harian dengan waktu sholat 5 waktu', style: TextStyle(fontSize: 11, color: AppPalette.textDim)),
                value: settings.showPrayerTimes,
                onChanged: (val) => notifier.togglePrayerTimes(val),
              ),
              if (settings.showPrayerTimes) ...[
                const SizedBox(height: 8),
                const Text(
                  'Ketuk waktu untuk menyesuaikan jadwal sholat di kotamu:',
                  style: TextStyle(fontSize: 11, color: AppPalette.textDim),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPrayerTimeChip('Subuh', settings.prayerSubuh, notifier),
                    _buildPrayerTimeChip('Syuruq', settings.prayerSyuruq, notifier),
                    _buildPrayerTimeChip('Dzuhur', settings.prayerDzuhur, notifier),
                    _buildPrayerTimeChip('Ashar', settings.prayerAshar, notifier),
                    _buildPrayerTimeChip('Maghrib', settings.prayerMaghrib, notifier),
                    _buildPrayerTimeChip('Isya', settings.prayerIsya, notifier),
                  ],
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomImageDialog(
      BuildContext context, LauncherSettingsNotifier notifier, LauncherSettings settings) {
    _urlCtrl.text = settings.customImageUrl;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPalette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppPalette.stroke),
        ),
        title: const Text(
          'URL Wallpaper Gambar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppPalette.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan URL gambar atau path wallpaper yang ingin dijadikan latar belakang:',
              style: TextStyle(fontSize: 12, color: AppPalette.textDim),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtrl,
              style: const TextStyle(fontSize: 13, color: AppPalette.text),
              decoration: InputDecoration(
                hintText: 'https://images.unsplash.com/...',
                hintStyle: const TextStyle(color: AppPalette.textDim),
                filled: true,
                fillColor: AppPalette.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppPalette.stroke),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: AppPalette.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.accent),
            onPressed: () {
              final url = _urlCtrl.text.trim();
              if (url.isNotEmpty) {
                notifier.setWallpaperType('custom_image', customUrl: url);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Terapkan', style: TextStyle(color: Color(0xFF0F0F1A))),
          ),
        ],
      ),
    );
  }

  String _getShortSlotLabel(String pkg, int index) {
    if (pkg.contains('dialer') || pkg.contains('phone')) return 'Telepon';
    if (pkg.contains('mms') || pkg.contains('message')) return 'Pesan';
    if (pkg.contains('browser') || pkg.contains('chrome')) return 'Browser';
    if (pkg.contains('camera')) return 'Kamera';
    final parts = pkg.split('.');
    return parts.isNotEmpty ? parts.last : 'App ${index + 1}';
  }

  IconData _getSlotIcon(String pkg, int index) {
    if (pkg.contains('dialer') || pkg.contains('phone')) return Icons.phone_outlined;
    if (pkg.contains('mms') || pkg.contains('message')) return Icons.chat_bubble_outline_rounded;
    if (pkg.contains('browser') || pkg.contains('chrome')) return Icons.language_rounded;
    if (pkg.contains('camera')) return Icons.camera_alt_outlined;
    return Icons.apps_rounded;
  }

  Widget _buildPrayerTimeChip(String name, String time, LauncherSettingsNotifier notifier) {
    return InkWell(
      onTap: () => _pickPrayerTime(name, time, notifier),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppPalette.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppPalette.stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppPalette.text),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppPalette.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                time,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppPalette.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPrayerTime(String name, String currentTime, LauncherSettingsNotifier notifier) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 12 : 12,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppPalette.accent,
              surface: AppPalette.card,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      notifier.setPrayerTime(name, '$h:$m');
    }
  }
}
