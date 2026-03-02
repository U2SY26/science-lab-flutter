import 'package:flutter/foundation.dart' show debugPrint;
import 'package:speech_to_text/speech_to_text.dart';

/// Speech-to-Text 서비스 (싱글톤)
class SttService {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  final SpeechToText _speech = SpeechToText();
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;

  Future<void> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (error) => debugPrint('[SttService] Error: ${error.errorMsg}'),
      );
      debugPrint('[SttService] Initialized: available=$_isAvailable');
    } catch (e) {
      debugPrint('[SttService] Init failed: $e');
      _isAvailable = false;
    }
  }

  Future<void> startListening({
    required void Function(String text) onResult,
    required String localeId,
  }) async {
    if (!_isAvailable) return;
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}
