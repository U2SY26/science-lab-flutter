import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/firebase_ai_service.dart';

/// Translation cache to avoid re-translating the same content.
/// Key: "${text.hashCode}_$targetLang"
final Map<String, String> _translationCache = {};

/// A small translate button that translates text via FirebaseAiService.
/// Shows translated text below original when tapped.
class TranslateButton extends StatefulWidget {
  final String text;
  final String contentLanguageCode;

  const TranslateButton({
    super.key,
    required this.text,
    required this.contentLanguageCode,
  });

  @override
  State<TranslateButton> createState() => _TranslateButtonState();
}

class _TranslateButtonState extends State<TranslateButton> {
  bool _isTranslating = false;
  String? _translatedText;
  bool _showTranslation = false;
  String? _error;

  String get _cacheKey {
    final deviceLang = Localizations.localeOf(context).languageCode;
    return '${widget.text.hashCode}_$deviceLang';
  }

  Future<void> _translate() async {
    final deviceLang = Localizations.localeOf(context).languageCode;

    // Check cache first
    final cached = _translationCache[_cacheKey];
    if (cached != null) {
      setState(() {
        _translatedText = cached;
        _showTranslation = true;
      });
      return;
    }

    setState(() {
      _isTranslating = true;
      _error = null;
    });

    try {
      final langName = _languageName(deviceLang);
      final prompt =
          'Translate the following text to $langName. Only output the translation, nothing else: ${widget.text}';

      final result = await FirebaseAiService().chatGeneral(
        userMessage: prompt,
        languageCode: deviceLang,
        history: [],
      );

      if (mounted) {
        _translationCache[_cacheKey] = result;
        setState(() {
          _translatedText = result;
          _showTranslation = true;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _error = e.toString();
        });
      }
    }
  }

  String _languageName(String code) {
    switch (code) {
      case 'ko':
        return 'Korean';
      case 'en':
        return 'English';
      case 'ja':
        return 'Japanese';
      case 'zh':
        return 'Chinese';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      case 'pt':
        return 'Portuguese';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceLang = Localizations.localeOf(context).languageCode;

    // Don't show if content language matches device language
    if (widget.contentLanguageCode == deviceLang) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Translate button
        GestureDetector(
          onTap: _isTranslating
              ? null
              : () {
                  if (_showTranslation) {
                    setState(() => _showTranslation = false);
                  } else if (_translatedText != null) {
                    setState(() => _showTranslation = true);
                  } else {
                    _translate();
                  }
                },
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isTranslating)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 1.5,
                    ),
                  )
                else
                  Icon(
                    Icons.translate,
                    color: AppColors.accent,
                    size: 14,
                  ),
                const SizedBox(width: 4),
                Text(
                  _showTranslation
                      ? (deviceLang == 'ko' ? '원문 보기' : 'Show original')
                      : (deviceLang == 'ko' ? '번역' : 'Translate'),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Translated text
        if (_showTranslation && _translatedText != null)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceLang == 'ko' ? '번역됨' : 'Translated',
                  style: TextStyle(
                    color: AppColors.accent.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _translatedText!,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

        // Error
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              deviceLang == 'ko' ? '번역 실패' : 'Translation failed',
              style: const TextStyle(
                color: AppColors.accent2,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}
