import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Combinatorics Visualization
/// 조합론 시각화
class CombinatoricsScreen extends StatefulWidget {
  const CombinatoricsScreen({super.key});

  @override
  State<CombinatoricsScreen> createState() => _CombinatoricsScreenState();
}

class _CombinatoricsScreenState extends State<CombinatoricsScreen> {
  int n = 5;
  int r = 3;
  int operationType = 0; // 0: permutation, 1: combination, 2: permutation with rep, 3: combination with rep
  bool showVisualization = true;
  bool isKorean = true;

  // Factorial
  int _factorial(int x) {
    if (x <= 1) return 1;
    int result = 1;
    for (int i = 2; i <= x; i++) {
      result *= i;
    }
    return result;
  }

  // Permutation P(n, r) = n! / (n-r)!
  int get _permutation {
    if (r > n) return 0;
    int result = 1;
    for (int i = n; i > n - r; i--) {
      result *= i;
    }
    return result;
  }

  // Combination C(n, r) = n! / (r! * (n-r)!)
  int get _combination {
    if (r > n) return 0;
    return _factorial(n) ~/ (_factorial(r) * _factorial(n - r));
  }

  // Permutation with repetition = n^r
  int get _permutationWithRep => math.pow(n, r).toInt();

  // Combination with repetition = C(n+r-1, r)
  int get _combinationWithRep {
    final nPrime = n + r - 1;
    return _factorial(nPrime) ~/ (_factorial(r) * _factorial(nPrime - r));
  }

  int get _result {
    switch (operationType) {
      case 0:
        return _permutation;
      case 1:
        return _combination;
      case 2:
        return _permutationWithRep;
      case 3:
        return _combinationWithRep;
      default:
        return 0;
    }
  }

  String get _formula {
    switch (operationType) {
      case 0:
        return 'P($n,$r) = $n!/($n-$r)!';
      case 1:
        return 'C($n,$r) = $n!/($r!($n-$r)!)';
      case 2:
        return '$n^$r';
      case 3:
        return 'C(${n + r - 1},$r)';
      default:
        return '';
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      n = 5;
      r = 3;
      operationType = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKorean ? '이산수학' : 'DISCRETE MATH',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '조합론' : 'Combinatorics',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => isKorean = !isKorean),
            tooltip: isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '이산수학' : 'DISCRETE MATH',
          title: isKorean ? '조합론' : 'Combinatorics',
          formula: _formula,
          formulaDescription: isKorean
              ? '순열은 순서가 중요한 배열, 조합은 순서가 중요하지 않은 선택입니다.'
              : 'Permutations care about order, combinations do not.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: CombinatoricsPainter(
                n: n,
                r: r,
                operationType: operationType,
                result: _result,
                showVisualization: showVisualization,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Result display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _getOperationName(),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_result',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formula,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Operation type
              PresetGroup(
                label: isKorean ? '연산 종류' : 'Operation Type',
                presets: [
                  PresetButton(
                    label: isKorean ? '순열' : 'Permutation',
                    isSelected: operationType == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationType = 0);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '조합' : 'Combination',
                    isSelected: operationType == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationType = 1);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '중복순열' : 'Perm+Rep',
                    isSelected: operationType == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationType = 2);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '중복조합' : 'Comb+Rep',
                    isSelected: operationType == 3,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationType = 3);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              SimSlider(
                label: 'n (${isKorean ? '전체 개수' : 'total items'})',
                value: n.toDouble(),
                min: 1,
                max: 10,
                defaultValue: 5,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() {
                  n = v.toInt();
                  if (r > n && operationType < 2) r = n;
                }),
              ),
              const SizedBox(height: 8),
              SimSlider(
                label: 'r (${isKorean ? '선택 개수' : 'choose'})',
                value: r.toDouble(),
                min: 0,
                max: operationType < 2 ? n.toDouble() : 10,
                defaultValue: 3,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => r = v.toInt()),
              ),
              const SizedBox(height: 12),

              // Explanation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _getExplanation(),
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                isPrimary: true,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getOperationName() {
    switch (operationType) {
      case 0:
        return isKorean ? '순열 (순서 O, 중복 X)' : 'Permutation (order matters, no repetition)';
      case 1:
        return isKorean ? '조합 (순서 X, 중복 X)' : 'Combination (order irrelevant, no repetition)';
      case 2:
        return isKorean ? '중복순열 (순서 O, 중복 O)' : 'Permutation with Repetition';
      case 3:
        return isKorean ? '중복조합 (순서 X, 중복 O)' : 'Combination with Repetition';
      default:
        return '';
    }
  }

  String _getExplanation() {
    switch (operationType) {
      case 0:
        return isKorean
            ? '$n개 중 $r개를 순서 있게 나열: ${List.generate(r, (i) => '($n-$i)').join(' × ')} = $_result'
            : 'Arrange $r from $n with order: ${List.generate(r, (i) => '($n-$i)').join(' × ')} = $_result';
      case 1:
        return isKorean
            ? '$n개 중 $r개를 선택 (순서 무관): P($n,$r)/$r! = $_result'
            : 'Choose $r from $n (order irrelevant): P($n,$r)/$r! = $_result';
      case 2:
        return isKorean
            ? '$n가지에서 $r번 선택 (중복 허용, 순서 O): $n^$r = $_result'
            : '$r choices from $n options (repetition allowed): $n^$r = $_result';
      case 3:
        return isKorean
            ? '$n가지에서 $r개 선택 (중복 허용, 순서 X): "stars and bars" = $_result'
            : 'Choose $r from $n with repetition: "stars and bars" = $_result';
      default:
        return '';
    }
  }
}

class CombinatoricsPainter extends CustomPainter {
  final int n;
  final int r;
  final int operationType;
  final int result;
  final bool showVisualization;
  final bool isKorean;

  CombinatoricsPainter({
    required this.n,
    required this.r,
    required this.operationType,
    required this.result,
    required this.showVisualization,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw items
    final itemRadius = 20.0;
    final spacing = math.min((size.width - 60) / n, 50.0);
    final startX = centerX - (n - 1) * spacing / 2;

    // Draw all items
    for (int i = 0; i < n; i++) {
      final x = startX + i * spacing;
      final y = centerY - 60;
      final isSelected = i < r;

      // Circle
      canvas.drawCircle(
        Offset(x, y),
        itemRadius,
        Paint()
          ..color = isSelected
              ? AppColors.accent.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
      );
      canvas.drawCircle(
        Offset(x, y),
        itemRadius,
        Paint()
          ..color = isSelected ? AppColors.accent : Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 3 : 1,
      );

      // Label
      _drawText(
        canvas,
        '${i + 1}',
        Offset(x, y),
        isSelected ? AppColors.accent : AppColors.muted,
        fontSize: 14,
      );
    }

    // Draw selected positions (slots)
    final slotY = centerY + 40;
    final slotSpacing = math.min((size.width - 60) / r, 60.0);
    final slotStartX = centerX - (r - 1) * slotSpacing / 2;

    for (int i = 0; i < r; i++) {
      final x = slotStartX + i * slotSpacing;

      // Slot box
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, slotY), width: 40, height: 40),
          const Radius.circular(8),
        ),
        Paint()..color = AppColors.accent.withValues(alpha: 0.1),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, slotY), width: 40, height: 40),
          const Radius.circular(8),
        ),
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Position number
      _drawText(
        canvas,
        operationType == 0 || operationType == 2 ? '#${i + 1}' : '?',
        Offset(x, slotY),
        AppColors.accent,
        fontSize: 12,
      );
    }

    // Labels
    _drawText(
      canvas,
      isKorean ? '전체 항목 (n = $n)' : 'All items (n = $n)',
      Offset(centerX, centerY - 100),
      AppColors.muted,
      fontSize: 11,
    );

    _drawText(
      canvas,
      isKorean ? '선택 슬롯 (r = $r)' : 'Selection slots (r = $r)',
      Offset(centerX, slotY + 40),
      AppColors.muted,
      fontSize: 11,
    );

    // Result at bottom
    _drawText(
      canvas,
      isKorean ? '가능한 경우의 수: $result' : 'Possible arrangements: $result',
      Offset(centerX, size.height - 30),
      AppColors.accent,
      fontSize: 14,
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CombinatoricsPainter oldDelegate) =>
      n != oldDelegate.n || r != oldDelegate.r || operationType != oldDelegate.operationType;
}
