import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Bayes' Theorem Visualization
/// 베이즈 정리 시각화
class BayesTheoremScreen extends StatefulWidget {
  const BayesTheoremScreen({super.key});

  @override
  State<BayesTheoremScreen> createState() => _BayesTheoremScreenState();
}

class _BayesTheoremScreenState extends State<BayesTheoremScreen> {
  // P(A) - Prior probability
  double priorA = 0.01; // Disease prevalence
  // P(B|A) - Likelihood (true positive rate / sensitivity)
  double likelihood = 0.95;
  // P(B|not A) - False positive rate
  double falsePositive = 0.05;

  int exampleIndex = 0; // 0: medical, 1: spam, 2: custom
  bool showDiagram = true;
  bool isKorean = true;

  // P(B) = P(B|A)P(A) + P(B|not A)P(not A)
  double get _pB => likelihood * priorA + falsePositive * (1 - priorA);

  // P(A|B) = P(B|A)P(A) / P(B) - Posterior
  double get _posterior => _pB > 0 ? (likelihood * priorA) / _pB : 0;

  void _setExample(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      exampleIndex = index;
      switch (index) {
        case 0: // Medical test
          priorA = 0.01;
          likelihood = 0.95;
          falsePositive = 0.05;
          break;
        case 1: // Spam filter
          priorA = 0.30;
          likelihood = 0.90;
          falsePositive = 0.01;
          break;
        case 2: // Custom - keep current values
          break;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      priorA = 0.01;
      likelihood = 0.95;
      falsePositive = 0.05;
      exampleIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final posterior = _posterior;
    final pB = _pB;

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
              isKorean ? '확률론' : 'PROBABILITY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '베이즈 정리' : "Bayes' Theorem",
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
          category: isKorean ? '확률론' : 'PROBABILITY',
          title: isKorean ? '베이즈 정리' : "Bayes' Theorem",
          formula: 'P(A|B) = P(B|A)P(A) / P(B)',
          formulaDescription: isKorean
              ? '베이즈 정리는 새로운 증거(B)가 주어졌을 때 가설(A)의 확률이 어떻게 업데이트되는지 보여줍니다.'
              : "Bayes' theorem shows how the probability of a hypothesis (A) is updated given new evidence (B).",
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: BayesPainter(
                priorA: priorA,
                likelihood: likelihood,
                falsePositive: falsePositive,
                posterior: posterior,
                showDiagram: showDiagram,
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
                  color: posterior > 0.5
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: posterior > 0.5 ? Colors.green : Colors.orange,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isKorean ? '사후 확률 P(A|B)' : 'Posterior P(A|B)',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(posterior * 100).toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: posterior > 0.5 ? Colors.green : Colors.orange,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getInterpretation(),
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Example selection
              PresetGroup(
                label: isKorean ? '예시' : 'Examples',
                presets: [
                  PresetButton(
                    label: isKorean ? '의료 검사' : 'Medical Test',
                    isSelected: exampleIndex == 0,
                    onPressed: () => _setExample(0),
                  ),
                  PresetButton(
                    label: isKorean ? '스팸 필터' : 'Spam Filter',
                    isSelected: exampleIndex == 1,
                    onPressed: () => _setExample(1),
                  ),
                  PresetButton(
                    label: isKorean ? '직접 설정' : 'Custom',
                    isSelected: exampleIndex == 2,
                    onPressed: () => _setExample(2),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Probability displays
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _ProbDisplay(
                      label: 'P(A)',
                      value: priorA,
                      color: Colors.blue,
                      description: isKorean ? '사전 확률' : 'Prior',
                    ),
                    _ProbDisplay(
                      label: 'P(B|A)',
                      value: likelihood,
                      color: Colors.green,
                      description: isKorean ? '우도' : 'Likelihood',
                    ),
                    _ProbDisplay(
                      label: 'P(B)',
                      value: pB,
                      color: Colors.purple,
                      description: isKorean ? '증거 확률' : 'Evidence',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sliders
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? 'P(A): 사전 확률 (유병률)' : 'P(A): Prior (Prevalence)',
                  value: priorA,
                  min: 0.001,
                  max: 0.5,
                  defaultValue: 0.01,
                  formatValue: (v) => '${(v * 100).toStringAsFixed(1)}%',
                  onChanged: (v) => setState(() {
                    priorA = v;
                    exampleIndex = 2;
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? 'P(B|A): 민감도 (참양성률)' : 'P(B|A): Sensitivity (True Positive)',
                    value: likelihood,
                    min: 0.5,
                    max: 1.0,
                    defaultValue: 0.95,
                    formatValue: (v) => '${(v * 100).toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      likelihood = v;
                      exampleIndex = 2;
                    }),
                  ),
                  SimSlider(
                    label: isKorean ? 'P(B|~A): 위양성률' : 'P(B|~A): False Positive Rate',
                    value: falsePositive,
                    min: 0.001,
                    max: 0.3,
                    defaultValue: 0.05,
                    formatValue: (v) => '${(v * 100).toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() {
                      falsePositive = v;
                      exampleIndex = 2;
                    }),
                  ),
                ],
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

  String _getInterpretation() {
    final posterior = _posterior;
    if (isKorean) {
      if (exampleIndex == 0) {
        return '양성 판정을 받았을 때 실제로 질병이 있을 확률';
      } else if (exampleIndex == 1) {
        return '스팸으로 분류되었을 때 실제 스팸일 확률';
      }
    } else {
      if (exampleIndex == 0) {
        return 'Probability of actually having the disease given positive test';
      } else if (exampleIndex == 1) {
        return 'Probability of actual spam given spam classification';
      }
    }
    return posterior > 0.5
        ? (isKorean ? '증거 B가 주어졌을 때 A일 가능성이 높음' : 'A is likely given evidence B')
        : (isKorean ? '증거 B에도 불구하고 A일 가능성은 낮음' : 'A is unlikely despite evidence B');
  }
}

class _ProbDisplay extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String description;

  const _ProbDisplay({
    required this.label,
    required this.value,
    required this.color,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(
            '${(value * 100).toStringAsFixed(1)}%',
            style: TextStyle(color: color, fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.bold),
          ),
          Text(description, style: const TextStyle(color: AppColors.muted, fontSize: 9)),
        ],
      ),
    );
  }
}

class BayesPainter extends CustomPainter {
  final double priorA;
  final double likelihood;
  final double falsePositive;
  final double posterior;
  final bool showDiagram;
  final bool isKorean;

  BayesPainter({
    required this.priorA,
    required this.likelihood,
    required this.falsePositive,
    required this.posterior,
    required this.showDiagram,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 30.0;
    final width = size.width - padding * 2;
    final height = size.height - padding * 2;

    // Draw probability tree or area diagram
    if (showDiagram) {
      _drawAreaDiagram(canvas, size, padding, width, height);
    }
  }

  void _drawAreaDiagram(Canvas canvas, Size size, double padding, double width, double height) {
    // Total population rectangle
    final totalRect = Rect.fromLTWH(padding, padding, width, height);

    // Draw total area
    canvas.drawRect(totalRect, Paint()..color = Colors.grey.withValues(alpha: 0.1));
    canvas.drawRect(
      totalRect,
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // A area (disease)
    final aWidth = width * priorA;
    final aRect = Rect.fromLTWH(padding, padding, aWidth, height);
    canvas.drawRect(aRect, Paint()..color = Colors.blue.withValues(alpha: 0.2));

    // Not A area (no disease)
    final notARect = Rect.fromLTWH(padding + aWidth, padding, width - aWidth, height);
    canvas.drawRect(notARect, Paint()..color = Colors.grey.withValues(alpha: 0.1));

    // True positives (A and B)
    final tpHeight = height * likelihood;
    final tpRect = Rect.fromLTWH(padding, padding, aWidth, tpHeight);
    canvas.drawRect(tpRect, Paint()..color = Colors.green.withValues(alpha: 0.6));

    // False positives (not A but B)
    final fpHeight = height * falsePositive;
    final fpRect = Rect.fromLTWH(padding + aWidth, padding, width - aWidth, fpHeight);
    canvas.drawRect(fpRect, Paint()..color = Colors.orange.withValues(alpha: 0.6));

    // Labels
    _drawText(canvas, isKorean ? 'A (질병 있음)' : 'A (Disease)',
        Offset(padding + aWidth / 2, size.height - 15), Colors.blue, fontSize: 10, center: true);
    _drawText(canvas, isKorean ? '~A (질병 없음)' : '~A (No Disease)',
        Offset(padding + aWidth + (width - aWidth) / 2, size.height - 15), Colors.grey, fontSize: 10, center: true);

    // B labels
    _drawText(canvas, isKorean ? '검사 양성 (B)' : 'Test Positive (B)',
        Offset(padding - 25, padding + 20), AppColors.muted, fontSize: 9, vertical: true);

    // Area labels
    if (aWidth > 30) {
      _drawText(canvas, isKorean ? '참양성' : 'TP',
          Offset(padding + aWidth / 2, padding + tpHeight / 2), Colors.white, fontSize: 11, center: true);
    }
    if (width - aWidth > 30) {
      _drawText(canvas, isKorean ? '위양성' : 'FP',
          Offset(padding + aWidth + (width - aWidth) / 2, padding + fpHeight / 2), Colors.white, fontSize: 11, center: true);
    }

    // Draw P(A|B) highlight
    final pB = likelihood * priorA + falsePositive * (1 - priorA);
    if (pB > 0) {
      // Highlight the region that represents P(A|B)
      final highlightRect = Rect.fromLTWH(padding, padding, aWidth, tpHeight);
      canvas.drawRect(
        highlightRect,
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Formula visualization
    final formulaY = size.height - 40;
    _drawText(
      canvas,
      'P(A|B) = ${isKorean ? '녹색 영역' : 'Green Area'} / (${isKorean ? '녹색' : 'Green'} + ${isKorean ? '주황색' : 'Orange'})',
      Offset(size.width / 2, formulaY),
      AppColors.accent,
      fontSize: 11,
      center: true,
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color,
      {double fontSize = 12, bool center = false, bool vertical = false}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    if (vertical) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(-1.5708); // -90 degrees
      textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
      canvas.restore();
    } else {
      final offset = center
          ? Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2)
          : pos;
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant BayesPainter oldDelegate) =>
      priorA != oldDelegate.priorA ||
      likelihood != oldDelegate.likelihood ||
      falsePositive != oldDelegate.falsePositive;
}
