import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/chat_message.dart';
import '../../../../core/models/quiz_question.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/user_profile_provider.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../core/services/community_service.dart';
import '../../../../core/services/firebase_ai_service.dart';
import '../../../../core/services/quiz_service.dart';
import '../../../../shared/widgets/ad_banner.dart';
import 'level_up_overlay.dart';

/// AI 퀴즈 다이얼로그 — 반복 도전 가능, XP는 최초 1회만 지급
class QuizDialog extends ConsumerStatefulWidget {
  final String simId;
  final String title;
  final String description;
  final String category;
  final String? formula;
  final AiLevel? aiLevel;

  const QuizDialog({
    super.key,
    required this.simId,
    required this.title,
    required this.description,
    required this.category,
    this.formula,
    this.aiLevel,
  });

  static Future<void> show(
    BuildContext context, {
    required String simId,
    required String title,
    required String description,
    required String category,
    String? formula,
    AiLevel? aiLevel,
  }) async {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => QuizDialog(
        simId: simId, title: title, description: description,
        category: category, formula: formula, aiLevel: aiLevel,
      ),
    );
  }

  @override
  ConsumerState<QuizDialog> createState() => _QuizDialogState();
}

enum _QuizPhase { loading, question, correct, wrong, error, retryLoading }

class _QuizDialogState extends ConsumerState<QuizDialog> {
  _QuizPhase _phase = _QuizPhase.loading;
  QuizQuestion? _quiz;
  int? _selectedIndex;
  bool _alreadyCompleted = false;
  bool _xpAwarded = false;

  // Hint
  bool _isHintLoading = false;
  String? _hintText;
  bool _hintUsed = false;

  // Retry loading bar
  double _retryProgress = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _checkCompletionAndLoad();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkCompletionAndLoad() async {
    try {
      _alreadyCompleted = await CommunityService().hasCompletedQuiz(widget.simId);
    } catch (_) {}
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _phase = _QuizPhase.loading;
      _selectedIndex = null;
      _hintText = null;
      _hintUsed = false;
      _xpAwarded = false;
    });

    final isKorean = ref.read(isKoreanProvider);
    final quiz = await QuizService().generateQuiz(
      simId: widget.simId, title: widget.title,
      description: widget.description, category: widget.category,
      formula: widget.formula, languageCode: isKorean ? 'ko' : 'en',
      difficulty: widget.aiLevel,
    );

    if (!mounted) return;
    if (quiz == null || quiz.choices.length < 2) {
      setState(() => _phase = _QuizPhase.error);
    } else {
      setState(() { _quiz = quiz; _phase = _QuizPhase.question; });
    }
  }

  /// 재도전 — 5초 로딩바 + 네이티브 광고 → 새 퀴즈 로드
  void _retryWithAd() {
    setState(() {
      _phase = _QuizPhase.retryLoading;
      _retryProgress = 0;
    });

    const totalMs = 5000;
    const intervalMs = 50;
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _retryProgress += intervalMs / totalMs;
      });
      if (_retryProgress >= 1.0) {
        timer.cancel();
        _loadQuiz();
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedIndex == null || _quiz == null) return;
    final correct = _selectedIndex == _quiz!.correctIndex;
    final isFirstCompletion = !_alreadyCompleted && correct;
    _xpAwarded = isFirstCompletion;

    if (isFirstCompletion) {
      await CommunityService().saveQuizResult(
        simId: widget.simId, correct: correct, xpAwarded: 15,
      );
      _alreadyCompleted = true;
    }

    if (correct) {
      if (isFirstCompletion) {
        final leveledUp = await ref.read(userProfileProvider.notifier).addXpAndRefresh(15);
        // 즐겨찾기에 자동 추가
        await _addToFavorites();
        setState(() => _phase = _QuizPhase.correct);
        if (leveledUp && mounted) {
          final profile = ref.read(userProfileProvider).profile;
          final int lvl = ref.read(currentLevelProvider);
          final int xp = profile?.xp ?? 0;
          final int nextXp = xp + (profile?.xpToNextLevel ?? 0);
          LevelUpOverlay.show(context, lvl, currentXp: xp, nextLevelXp: nextXp);
        }
      } else {
        setState(() => _phase = _QuizPhase.correct);
      }
    } else {
      setState(() => _phase = _QuizPhase.wrong);
    }
  }

  /// 즐겨찾기에 자동 추가 (최초 정답 시)
  Future<void> _addToFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorites') ?? [];
      if (!favorites.contains(widget.simId)) {
        favorites.add(widget.simId);
        await prefs.setStringList('favorites', favorites);
        if (mounted) {
          final isKorean = ref.read(isKoreanProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isKorean
                    ? '학습 완료! 즐겨찾기에 추가되었습니다'
                    : 'Completed! Added to favorites',
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {}
  }

  /// 힌트 — 보상형 광고 후 AI 힌트 (거의 정답을 알려주는 수준)
  Future<void> _showHint() async {
    if (_quiz == null || _hintUsed) return;

    // 힌트 사용 즉시 마킹 (광고 후 리빌드되어도 유지)
    setState(() { _hintUsed = true; _isHintLoading = true; });

    // 보상형 광고
    await AdService().showRewardedInterstitialAd(
      onRewarded: () {},
      onFailed: () {},
    );

    if (!mounted) return;

    final isKorean = ref.read(isKoreanProvider);
    final correctAnswer = _quiz!.choices[_quiz!.correctIndex];
    try {
      final hintPrompt = isKorean
          ? '정답은 "$correctAnswer"입니다. 정답 선택지의 첫 글자와 핵심 키워드를 포함해서 1문장으로 힌트를 주세요. '
            '예시: "정답은 0으로 시작하는 숫자이고, 계산하면 0.X가 됩니다" 형식으로.\n\n'
            '문제: ${_quiz!.question}'
          : 'The answer is "$correctAnswer". Include the first character and key numbers from the correct choice. '
            'Example: "The answer starts with 0 and equals 0.X when calculated".\n\n'
            'Question: ${_quiz!.question}';

      final result = await FirebaseAiService().chatGeneral(
        userMessage: hintPrompt,
        languageCode: isKorean ? 'ko' : 'en',
        history: const <ChatMessage>[],
      );

      if (!mounted) return;
      setState(() {
        _hintText = result.startsWith('Error:')
            ? (isKorean ? '힌트를 불러올 수 없습니다.' : 'Could not load hint.')
            : result;
        _isHintLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hintText = isKorean ? '힌트를 불러올 수 없습니다.' : 'Could not load hint.';
        _isHintLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: _buildContent(isKorean),
              ),
            ),
            // 하단 배너 광고
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: const AdBannerWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isKorean) {
    switch (_phase) {
      case _QuizPhase.loading:
        return _buildLoading(isKorean);
      case _QuizPhase.retryLoading:
        return _buildRetryLoading(isKorean);
      case _QuizPhase.question:
        return _buildQuestion(isKorean);
      case _QuizPhase.correct:
        return _buildResult(isKorean, correct: true);
      case _QuizPhase.wrong:
        return _buildResult(isKorean, correct: false);
      case _QuizPhase.error:
        return _buildError(isKorean);
    }
  }

  Widget _buildLoading(bool isKorean) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.accent),
        const SizedBox(height: 16),
        Text(
          isKorean ? 'AI가 퀴즈를 생성 중...' : 'AI is generating a quiz...',
          style: const TextStyle(color: AppColors.ink, fontSize: 14),
        ),
      ],
    );
  }

  /// 재도전 로딩 — 5초 프로그레스바 + 네이티브 광고
  Widget _buildRetryLoading(bool isKorean) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isKorean ? '새 퀴즈 준비 중...' : 'Preparing new quiz...',
          style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _retryProgress,
            backgroundColor: AppColors.cardBorder,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${(_retryProgress * 100).toInt()}%',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ),
        const SizedBox(height: 16),
        // 네이티브 광고
        const NativeAdWidget(),
      ],
    );
  }

  Widget _buildQuestion(bool isKorean) {
    final quiz = _quiz!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Row(
          children: [
            const Icon(Icons.quiz, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              isKorean ? '퀴즈 챌린지' : 'Quiz Challenge',
              style: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (_alreadyCompleted ? AppColors.muted : AppColors.accent).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _alreadyCompleted ? (isKorean ? '재도전' : 'Retry') : '+15 XP',
                style: TextStyle(
                  color: _alreadyCompleted ? AppColors.muted : AppColors.accent,
                  fontSize: 12, fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 질문
        Text(quiz.question, style: const TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),

        // 힌트
        if (_hintText != null) ...[
          _buildHintBox(_hintText!),
          const SizedBox(height: 12),
        ] else if (_isHintLoading) ...[
          _buildHintLoading(isKorean),
          const SizedBox(height: 12),
        ],

        // 선택지
        ...List.generate(quiz.choices.length, (i) {
          final selected = _selectedIndex == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = i),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.cardBorder,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  quiz.choices[i],
                  style: TextStyle(color: selected ? AppColors.accent : AppColors.ink, fontSize: 14),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),

        // 버튼
        Row(
          children: [
            if (!_hintUsed && _hintText == null)
              TextButton.icon(
                onPressed: _isHintLoading ? null : _showHint,
                icon: const Icon(Icons.lightbulb_outline, size: 16),
                label: Text(isKorean ? '힌트 (광고)' : 'Hint (Ad)', style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFC4B5FD)),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isKorean ? '나중에' : 'Later', style: const TextStyle(color: AppColors.muted)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _selectedIndex != null ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isKorean ? '제출' : 'Submit'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHintBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: Color(0xFFC4B5FD), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildHintLoading(bool isKorean) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Color(0xFFC4B5FD), strokeWidth: 2)),
          const SizedBox(width: 8),
          Text(isKorean ? '힌트 생성 중...' : 'Generating hint...', style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildResult(bool isKorean, {required bool correct}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          correct ? Icons.check_circle : Icons.cancel,
          color: correct ? const Color(0xFF4CAF50) : AppColors.accent2,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          correct ? (isKorean ? '정답입니다!' : 'Correct!') : (isKorean ? '오답입니다' : 'Incorrect'),
          style: TextStyle(
            color: correct ? const Color(0xFF4CAF50) : AppColors.accent2,
            fontSize: 20, fontWeight: FontWeight.bold,
          ),
        ),
        if (correct && _xpAwarded) ...[
          const SizedBox(height: 4),
          const Text('+15 XP', style: TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold)),
        ] else if (correct && !_xpAwarded) ...[
          const SizedBox(height: 4),
          Text(isKorean ? 'XP 이미 획득 완료' : 'XP already earned', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
        if (_quiz?.explanation.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Text(_quiz!.explanation, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _retryWithAd,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(isKorean ? '다시 도전' : 'Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent, foregroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isKorean ? '확인' : 'OK'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(bool isKorean) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: AppColors.muted, size: 40),
        const SizedBox(height: 12),
        Text(
          isKorean ? '퀴즈 생성에 실패했습니다' : 'Failed to generate quiz',
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _loadQuiz,
              child: Text(isKorean ? '다시 시도' : 'Retry', style: const TextStyle(color: AppColors.accent)),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isKorean ? '닫기' : 'Close', style: const TextStyle(color: AppColors.muted)),
            ),
          ],
        ),
      ],
    );
  }
}
