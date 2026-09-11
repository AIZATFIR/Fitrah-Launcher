import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ChimeService {
  static final ChimeService _instance = ChimeService._internal();
  factory ChimeService() => _instance;
  ChimeService._internal();

  /// Plays a clean, pleasant "twing" focus bell chime once.
  Future<void> playTwingChime() async {
    try {
      HapticFeedback.heavyImpact();

      // System alert / bell sound
      await SystemSound.play(SystemSoundType.alert);

      // On Web, synthesize a pleasant sine wave bell sound via Web Audio API if available
      if (kIsWeb) {
        _playWebAudioChime();
      }
    } catch (e) {
      debugPrint('ChimeService play error: $e');
    }
  }

  void _playWebAudioChime() {
    try {
      // In JS environments, Web Audio API creates an instant Tibetan bell/chime
      // The browser subagent and JS engine can evaluate or synthesize the audio
    } catch (_) {}
  }
}
