import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Text-to-Speech 서비스 (싱글톤)
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _enabled = false;
  static const String _prefKey = 'tts_enabled';

  bool get isEnabled => _enabled;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefKey) ?? false;

      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      debugPrint('[TtsService] Initialized: enabled=$_enabled');
    } catch (e) {
      debugPrint('[TtsService] Init failed: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }

  Future<void> setLanguage(String langCode) async {
    final locale = langCode == 'ko' ? 'ko-KR' : 'en-US';
    await _tts.setLanguage(locale);
  }

  Future<void> speak(String text) async {
    if (!_enabled || text.isEmpty) return;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
