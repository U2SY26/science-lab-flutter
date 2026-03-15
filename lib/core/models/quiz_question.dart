/// AI 생성 퀴즈 문제 모델
class QuizQuestion {
  final String question;
  final List<String> choices;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: _sanitize(json['question'] as String? ?? ''),
      choices: (json['choices'] as List? ?? []).map((c) => _sanitize(c as String)).toList(),
      correctIndex: json['correctIndex'] as int? ?? 0,
      explanation: _sanitize(json['explanation'] as String? ?? ''),
    );
  }

  /// 특수 유니코드 수학 기호를 ASCII로 치환 (엑박 방지)
  static String _sanitize(String text) {
    return text
        // 수학 이탤릭/볼드 (U+1D400-1D7FF)
        .replaceAll(RegExp(r'[\u{1D400}-\u{1D7FF}]', unicode: true), '')
        // 위첨자 숫자
        .replaceAll('\u00B2', '^2')
        .replaceAll('\u00B3', '^3')
        .replaceAll('\u2074', '^4')
        .replaceAll('\u2075', '^5')
        .replaceAll('\u2076', '^6')
        .replaceAll('\u207F', '^n')
        .replaceAll('\u207A', '+')
        .replaceAll('\u207B', '-')
        // 아래첨자
        .replaceAll('\u2080', '_0')
        .replaceAll('\u2081', '_1')
        .replaceAll('\u2082', '_2')
        .replaceAll('\u2083', '_3')
        // 그리스 문자 (일반적으로 렌더링 가능하지만 안전하게)
        .replaceAll('\u03A3', 'Sigma')
        .replaceAll('\u03C3', 'sigma')
        .replaceAll('\u0394', 'Delta')
        .replaceAll('\u03B4', 'delta')
        // 수학 기호
        .replaceAll('\u221A', 'sqrt')
        .replaceAll('\u221E', 'infinity')
        .replaceAll('\u2248', '≈')
        .replaceAll('\u2260', '!=')
        .replaceAll('\u2264', '<=')
        .replaceAll('\u2265', '>=')
        .replaceAll('\u00D7', '*')
        .replaceAll('\u00F7', '/')
        // 빈 replacement character 제거
        .replaceAll('\uFFFD', '?')
        .trim();
  }
}
