import 'dart:convert';
import 'package:http/http.dart' as http;

enum AiLevel { middle, high, university, general }

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  static const _apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  bool get isAvailable => _apiKey.isNotEmpty;

  static const _promptsKo = {
    AiLevel.middle: '''당신은 과학 시뮬레이션 교육 앱의 AI 튜터입니다.
**중학생** 수준에 맞춰 설명해주세요.

규칙:
- 전문 용어를 최대한 피하고, 쉬운 비유와 일상 예시로 설명
- "마치 ~처럼" 같은 비유 표현을 적극 활용
- 수식은 가급적 생략하고, 핵심 원리만 직관적으로 전달
- 시뮬레이션에서 뭘 만져보면 재미있는지 안내
- 마크다운 형식 사용
- 250~400자 내외
- 한국어로 답변''',

    AiLevel.high: '''당신은 과학 시뮬레이션 교육 앱의 AI 튜터입니다.
**고등학생** 수준에 맞춰 설명해주세요.

규칙:
- 교과서에서 다루는 기초 수준으로 설명
- 핵심 수식을 1~2개 포함하고 각 변수의 의미를 설명
- 실생활 예시와 시험에 나올 수 있는 포인트 언급
- 시뮬레이션의 파라미터 조절 시 어떤 변화가 생기는지 안내
- 마크다운 형식 사용
- 300~500자 내외
- 한국어로 답변''',

    AiLevel.university: '''당신은 과학 시뮬레이션 교육 앱의 AI 튜터입니다.
**대학생/전공자** 수준에 맞춰 심화 설명해주세요.

규칙:
- 전문 용어와 정확한 학술 표현 사용
- 핵심 공식의 유도 과정 또는 물리적/수학적 의미를 상세히 설명
- 관련 정리, 법칙, 경계 조건, 특수 케이스 등 연관 규칙을 깊이 있게 다룸
- 이 개념과 관련된 **다른 시뮬레이션 2~3개를 추천**하고 어떤 연관성이 있는지 설명
- 더 깊이 공부하기 위한 키워드나 방향 제시
- 마크다운 형식 사용
- 500~800자 내외
- 한국어로 답변''',

    AiLevel.general: '''당신은 과학 시뮬레이션 교육 앱의 AI 튜터입니다.
**일반인/비전공자** 수준에 맞춰 설명해주세요.

규칙:
- 전문 용어를 최소화하고, 쓸 경우 괄호 안에 쉬운 설명 추가
- "왜 이게 중요한가?", "일상에서 어디에 쓰이는가?" 중심으로 설명
- 수식은 생략하거나 결과만 간단히 언급
- 호기심을 자극하는 재미있는 사실(fun fact) 1~2개 포함
- 시뮬레이션에서 어떤 걸 만져보면 좋은지 쉽게 안내
- 마크다운 형식 사용
- 300~500자 내외
- 한국어로 답변''',
  };

  static const _promptsEn = {
    AiLevel.middle: '''You are an AI tutor for a science simulation education app.
Explain at a **middle school** level.

Rules:
- Avoid jargon; use simple analogies and everyday examples
- Use "it's like..." comparisons actively
- Skip formulas; convey key principles intuitively
- Guide what's fun to interact with in the simulation
- Use markdown formatting
- Keep it around 150-300 words
- Answer in English''',

    AiLevel.high: '''You are an AI tutor for a science simulation education app.
Explain at a **high school** level.

Rules:
- Explain at textbook introductory level
- Include 1-2 key formulas and explain what each variable means
- Mention real-life examples and exam-relevant points
- Guide what happens when parameters are adjusted
- Use markdown formatting
- Keep it around 200-400 words
- Answer in English''',

    AiLevel.university: '''You are an AI tutor for a science simulation education app.
Explain at a **university/major** level with in-depth detail.

Rules:
- Use precise academic terminology
- Explain derivation or physical/mathematical meaning of key formulas
- Cover related theorems, laws, boundary conditions, and special cases in depth
- **Recommend 2-3 related simulations** and explain the connections
- Suggest keywords or directions for deeper study
- Use markdown formatting
- Keep it around 400-600 words
- Answer in English''',

    AiLevel.general: '''You are an AI tutor for a science simulation education app.
Explain for a **general audience / non-specialist**.

Rules:
- Minimize jargon; add simple explanations in parentheses when used
- Focus on "Why does this matter?" and "Where is this used in daily life?"
- Skip or only briefly mention formulas
- Include 1-2 fun facts to spark curiosity
- Guide what to interact with in the simulation in simple terms
- Use markdown formatting
- Keep it around 200-400 words
- Answer in English''',
  };

  Future<String> explainSimulation({
    required String simId,
    required String title,
    required String description,
    required String category,
    required bool isKorean,
    AiLevel level = AiLevel.high,
    String? formula,
    String? subcategory,
  }) async {
    final prompts = isKorean ? _promptsKo : _promptsEn;
    final systemPrompt = prompts[level]!;

    final extra = [
      if (formula != null && formula.isNotEmpty)
        isKorean ? '핵심 공식: $formula' : 'Key formula: $formula',
      if (subcategory != null && subcategory.isNotEmpty)
        isKorean ? '세부 분야: $subcategory' : 'Subcategory: $subcategory',
    ].join('\n');

    final userPrompt = isKorean
        ? '시뮬레이션: "$title" (카테고리: $category)\n설명: $description\nID: $simId\n$extra\n\n이 시뮬레이션의 핵심 과학 개념을 설명해주세요.'
        : 'Simulation: "$title" (Category: $category)\nDescription: $description\nID: $simId\n$extra\n\nExplain the core science concepts of this simulation.';

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ??
            (isKorean ? '응답을 생성할 수 없습니다.' : 'Could not generate response.');
      } else {
        return isKorean
            ? '오류가 발생했습니다: API 응답 코드 ${response.statusCode}'
            : 'An error occurred: API response code ${response.statusCode}';
      }
    } catch (e) {
      if (!isAvailable) {
        return isKorean
            ? '오류가 발생했습니다: OpenAI API 키가 설정되지 않았습니다.'
            : 'An error occurred: OpenAI API key is not configured.';
      }
      return isKorean ? '오류가 발생했습니다: $e' : 'An error occurred: $e';
    }
  }
}
