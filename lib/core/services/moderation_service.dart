import 'firebase_ai_service.dart';

/// AI 콘텐츠 모더레이션 서비스
class ModerationService {
  static final ModerationService _instance = ModerationService._internal();
  factory ModerationService() => _instance;
  ModerationService._internal();

  /// 콘텐츠 검열 — true면 통과, false면 부적절
  Future<bool> checkContent(String content) async {
    if (content.trim().isEmpty) return false;

    // 짧은 텍스트는 모더레이션 스킵 (AI가 오판하기 쉬움)
    if (content.trim().length <= 10) return true;

    // AI 서비스 사용 불가 시 통과 (사후 신고로 대응)
    if (!FirebaseAiService().isAvailable) return true;

    try {
      final result = await FirebaseAiService().chatGeneral(
        userMessage: content,
        languageCode: 'en',
        history: [],
        personaPrompt: _moderationPrompt,
        isPro: false, // 무료 모델로 검열 (비용 절감)
      );

      // API 에러 응답인 경우 통과 (사후 신고로 대응)
      if (result.startsWith('Error:')) return true;

      final upper = result.trim().toUpperCase();
      // "PASS" 포함 또는 "FAIL" 미포함 시 통과 (보수적 차단 방지)
      return upper.contains('PASS') || !upper.contains('FAIL');
    } catch (_) {
      // AI 실패 시 통과 (사후 신고로 대응)
      return true;
    }
  }

  static const _moderationPrompt = '''
You are a content moderator for a science education app used by students worldwide.
Evaluate the following user-generated content and respond with ONLY "PASS" or "FAIL".

FAIL if the content contains:
- Hate speech, harassment, bullying, or threats
- Sexual or violent content
- Personal information (names, emails, phone numbers, addresses)
- Spam, advertising, or promotional content
- Profanity or offensive language in any language
- Content completely unrelated to science/education

PASS if the content is:
- Science-related discussion, questions, or answers
- Respectful feedback or opinions
- Educational tips or resources
- General friendly conversation

Respond with ONLY one word: PASS or FAIL.
''';
}
