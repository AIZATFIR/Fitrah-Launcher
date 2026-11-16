import 'package:flutter/material.dart';

/// Renders semantic icon keys and legacy emoji keys with one Material style.
class ActivityIcon extends StatelessWidget {
  const ActivityIcon({super.key, this.iconKey, this.size = 20, this.color});

  final String? iconKey;
  final double size;
  final Color? color;

  static const _icons = <String, IconData>{
    // Stable keys used by current UI and stored activities.
    'target': Icons.track_changes_rounded,
    'computer': Icons.computer_rounded,
    'book': Icons.menu_book_rounded,
    'running': Icons.directions_run_rounded,
    'art': Icons.palette_outlined,
    'music': Icons.music_note_rounded,
    'writing': Icons.edit_note_rounded,
    'thinking': Icons.psychology_alt_rounded,
    'coffee': Icons.local_cafe_rounded,
    'meditate': Icons.self_improvement_rounded,
    'fire': Icons.local_fire_department_rounded,
    'launch': Icons.rocket_launch_rounded,
    'idea': Icons.lightbulb_outline_rounded,
    'pin': Icons.push_pin_rounded,
    'bolt': Icons.bolt_rounded,
    'strength': Icons.fitness_center_rounded,
    'sleep': Icons.bedtime_rounded,
    'meal': Icons.restaurant_rounded,
    'gaming': Icons.sports_esports_rounded,
    'home': Icons.home_rounded,
    'relax': Icons.spa_rounded,
    'driving': Icons.directions_car_rounded,
    'meeting': Icons.handshake_rounded,
    'call': Icons.call_rounded,
    'shopping': Icons.shopping_cart_outlined,
    'cleaning': Icons.cleaning_services_rounded,
    'record': Icons.mic_none_rounded,
    'prayer': Icons.mosque_rounded,
    'nature': Icons.spa_outlined,
    'nutrition': Icons.restaurant_menu_rounded,
    'language': Icons.translate_rounded,
    'water': Icons.water_drop_outlined,
    'star': Icons.star_outline_rounded,
    'cloud': Icons.cloud_outlined,
    'rain': Icons.cloudy_snowing,
    'sunrise': Icons.wb_twilight_rounded,
    'moon': Icons.nightlight_round,
    'study': Icons.school_rounded,
    'reflection': Icons.light_mode_outlined,
    'plan': Icons.assignment_outlined,
    'lunch': Icons.lunch_dining_rounded,

    // Existing records keep rendering correctly after the icon key cleanup.
    '🎯': Icons.track_changes_rounded,
    '😇': Icons.sentiment_satisfied_alt_rounded,
    '💪': Icons.fitness_center_rounded,
    '🎬': Icons.movie_outlined,
    '💻': Icons.computer_rounded,
    '📖': Icons.menu_book_rounded,
    '📚': Icons.menu_book_rounded,
    '🏃': Icons.directions_run_rounded,
    '🎨': Icons.palette_outlined,
    '🎵': Icons.music_note_rounded,
    '✍️': Icons.edit_note_rounded,
    '🧠': Icons.psychology_alt_rounded,
    '☕': Icons.local_cafe_rounded,
    '🧘': Icons.self_improvement_rounded,
    '🔥': Icons.local_fire_department_rounded,
    '🚀': Icons.rocket_launch_rounded,
    '💡': Icons.lightbulb_outline_rounded,
    '📌': Icons.push_pin_rounded,
    '⚡': Icons.bolt_rounded,
    '🏋️': Icons.fitness_center_rounded,
    '😴': Icons.bedtime_rounded,
    '🍽️': Icons.restaurant_rounded,
    '🎮': Icons.sports_esports_rounded,
    '🏠': Icons.home_rounded,
    '💆': Icons.spa_rounded,
    '🚗': Icons.directions_car_rounded,
    '🤝': Icons.handshake_rounded,
    '📞': Icons.call_rounded,
    '🛒': Icons.shopping_cart_outlined,
    '🧹': Icons.cleaning_services_rounded,
    '🎙️': Icons.mic_none_rounded,
    '🕌': Icons.mosque_rounded,
    '🌿': Icons.spa_outlined,
    '🥗': Icons.restaurant_menu_rounded,
    '🇫🇷': Icons.translate_rounded,
    '💧': Icons.water_drop_outlined,
    '⭐': Icons.star_outline_rounded,
    '🌟': Icons.auto_awesome_outlined,
    '☁️': Icons.cloud_outlined,
    '🌧️': Icons.cloudy_snowing,
    '🌐': Icons.language_rounded,
    '🌅': Icons.wb_twilight_rounded,
    '🌙': Icons.nightlight_round,
    '🎓': Icons.school_rounded,
    '🪶': Icons.edit_outlined,
    '🕯️': Icons.light_mode_outlined,
    '🛌': Icons.bed_rounded,
    '📋': Icons.assignment_outlined,
    '🍱': Icons.lunch_dining_rounded,
    '💤': Icons.bedtime_rounded,
  };

  static IconData dataFor(String? key) {
    if (key == null || key.trim().isEmpty) return Icons.circle_outlined;
    final normalized = key.trim();
    final exact = _icons[normalized];
    if (exact != null) return exact;
    for (final token in normalized.split(RegExp(r'\s+'))) {
      final match = _icons[token];
      if (match != null) return match;
    }
    return Icons.circle_outlined;
  }

  @override
  Widget build(BuildContext context) =>
      Icon(dataFor(iconKey), size: size, color: color);
}
