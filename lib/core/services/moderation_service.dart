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
    if (content.trim().length <= 50) return true;

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
You are a lenient content moderator for a science education community app.
Respond with ONLY "PASS" or "FAIL".

ONLY FAIL for clearly harmful content:
- Explicit hate speech, serious threats, or harassment targeting individuals
- Sexually explicit or graphically violent content
- Phone numbers, email addresses, or home addresses (personal info)
- Obvious spam with external links or advertising

PASS everything else, including:
- Greetings, casual conversation, emojis, slang
- Off-topic but harmless chat
- Opinions, feedback, jokes
- Short messages like "hi", "thanks", "lol", "ㅋㅋ"
- Science questions AND non-science questions
- Any content that is not clearly harmful

When in doubt, ALWAYS respond PASS. Be very lenient.
Respond with ONLY one word: PASS or FAIL.
''';
}
