import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Modular Arithmetic Visualization
/// 모듈러 연산 시각화
class ModularArithmeticScreen extends StatefulWidget {
  const ModularArithmeticScreen({super.key});

  @override
  State<ModularArithmeticScreen> createState() => _ModularArithmeticScreenState();
}

class _ModularArithmeticScreenState extends State<ModularArithmeticScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int modulus = 12;
  int valueA = 7;
  int valueB = 5;
  int operationIndex = 0; // 0: add, 1: subtract, 2: multiply, 3: power
  bool showClock = true;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  int get _result {
    switch (operationIndex) {
      case 0: // Addition
        return (valueA + valueB) % modulus;
      case 1: // Subtraction
        return ((valueA - valueB) % modulus + modulus) % modulus;
      case 2: // Multiplication
        return (valueA * valueB) % modulus;
      case 3: // Power
        return _modPow(valueA, valueB, modulus);
      default:
        return 0;
    }
  }

  int _modPow(int base, int exp, int mod) {
    int result = 1;
    base = base % mod;
    while (exp > 0) {
      if (exp % 2 == 1) {
        result = (result * base) % mod;
      }
      exp = exp ~/ 2;
      base = (base * base) % mod;
    }
    return result;
  }

  String get _operationSymbol {
    switch (operationIndex) {
      case 0:
        return '+';
      case 1:
        return '-';
      case 2:
        return '×';
      case 3:
        return '^';
      default:
        return '+';
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      modulus = 12;
      valueA = 7;
      valueB = 5;
      operationIndex = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              isKorean ? '수론' : 'NUMBER THEORY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '모듈러 연산' : 'Modular Arithmetic',
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
          category: isKorean ? '수론' : 'NUMBER THEORY',
          title: isKorean ? '모듈러 연산' : 'Modular Arithmetic',
          formula: 'a ≡ b (mod n) ⟺ n | (a - b)',
          formulaDescription: isKorean
              ? '모듈러 연산은 나머지를 기반으로 한 산술입니다. 시계 산술이라고도 불립니다.'
              : 'Modular arithmetic is based on remainders. Also known as clock arithmetic.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: ModularArithmeticPainter(
                modulus: modulus,
                valueA: valueA,
                valueB: valueB,
                result: _result,
                operationIndex: operationIndex,
                showClock: showClock,
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
                      '$valueA $_operationSymbol $valueB ≡ $_result (mod $modulus)',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getExplanation(),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Operation selection
              PresetGroup(
                label: isKorean ? '연산' : 'Operation',
                presets: [
                  PresetButton(
                    label: isKorean ? '덧셈 (+)' : 'Add (+)',
                    isSelected: operationIndex == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationIndex = 0);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '뺄셈 (-)' : 'Sub (-)',
                    isSelected: operationIndex == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationIndex = 1);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '곱셈 (×)' : 'Mul (×)',
                    isSelected: operationIndex == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationIndex = 2);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '거듭제곱 (^)' : 'Pow (^)',
                    isSelected: operationIndex == 3,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => operationIndex = 3);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Modulus presets
              PresetGroup(
                label: isKorean ? '모듈러스 프리셋' : 'Modulus Presets',
                presets: [
                  PresetButton(
                    label: '12 (${isKorean ? '시계' : 'Clock'})',
                    isSelected: modulus == 12,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => modulus = 12);
                    },
                  ),
                  PresetButton(
                    label: '7 (${isKorean ? '요일' : 'Week'})',
                    isSelected: modulus == 7,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => modulus = 7);
                    },
                  ),
                  PresetButton(
                    label: '26 (${isKorean ? '알파벳' : 'Alphabet'})',
                    isSelected: modulus == 26,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => modulus = 26);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sliders
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '모듈러스 (n)' : 'Modulus (n)',
                  value: modulus.toDouble(),
                  min: 2,
                  max: 30,
                  defaultValue: 12,
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) => setState(() => modulus = v.toInt()),
                ),
                advancedControls: [
                  SimSlider(
                    label: 'a',
                    value: valueA.toDouble(),
                    min: 0,
                    max: 30,
                    defaultValue: 7,
                    formatValue: (v) => '${v.toInt()}',
                    onChanged: (v) => setState(() => valueA = v.toInt()),
                  ),
                  SimSlider(
                    label: 'b',
                    value: valueB.toDouble(),
                    min: 0,
                    max: operationIndex == 3 ? 10 : 30,
                    defaultValue: 5,
                    formatValue: (v) => '${v.toInt()}',
                    onChanged: (v) => setState(() => valueB = v.toInt()),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SimToggle(
                label: isKorean ? '시계 표시' : 'Show Clock',
                value: showClock,
                onChanged: (v) => setState(() => showClock = v),
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

  String _getExplanation() {
    switch (operationIndex) {
      case 0:
        final sum = valueA + valueB;
        return isKorean
            ? '$valueA + $valueB = $sum, $sum ÷ $modulus = ${sum ~/ modulus} 나머지 $_result'
            : '$valueA + $valueB = $sum, $sum ÷ $modulus = ${sum ~/ modulus} remainder $_result';
      case 1:
        final diff = valueA - valueB;
        return isKorean
            ? '$valueA - $valueB = $diff, mod $modulus = $_result'
            : '$valueA - $valueB = $diff, mod $modulus = $_result';
      case 2:
        final prod = valueA * valueB;
        return isKorean
            ? '$valueA × $valueB = $prod, $prod mod $modulus = $_result'
            : '$valueA × $valueB = $prod, $prod mod $modulus = $_result';
      case 3:
        return isKorean
            ? '$valueA^$valueB mod $modulus = $_result (모듈러 거듭제곱)'
            : '$valueA^$valueB mod $modulus = $_result (modular exponentiation)';
      default:
        return '';
    }
  }
}

class ModularArithmeticPainter extends CustomPainter {
  final int modulus;
  final int valueA;
  final int valueB;
  final int result;
  final int operationIndex;
  final bool showClock;

  ModularArithmeticPainter({
    required this.modulus,
    required this.valueA,
    required this.valueB,
    required this.result,
    required this.operationIndex,
    required this.showClock,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (showClock) {
      _drawClockVisualization(canvas, size);
    } else {
      _drawNumberLineVisualization(canvas, size);
    }
  }

  void _drawClockVisualization(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) / 2 - 40;

    // Draw clock circle
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw tick marks and numbers
    for (int i = 0; i < modulus; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / modulus);
      final innerRadius = radius - 15;
      final outerRadius = radius;

      final x1 = centerX + innerRadius * math.cos(angle);
      final y1 = centerY + innerRadius * math.sin(angle);
      final x2 = centerX + outerRadius * math.cos(angle);
      final y2 = centerY + outerRadius * math.sin(angle);

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = 2,
      );

      // Number label
      final labelRadius = radius - 30;
      final lx = centerX + labelRadius * math.cos(angle);
      final ly = centerY + labelRadius * math.sin(angle);

      final isHighlighted = i == (valueA % modulus) || i == result;
      _drawText(
        canvas,
        '$i',
        Offset(lx, ly),
        isHighlighted ? AppColors.accent : AppColors.muted,
        fontSize: isHighlighted ? 14 : 12,
      );
    }

    // Draw value A position
    final aAngle = -math.pi / 2 + (2 * math.pi * (valueA % modulus) / modulus);
    final aRadius = radius - 50;
    canvas.drawCircle(
      Offset(centerX + aRadius * math.cos(aAngle), centerY + aRadius * math.sin(aAngle)),
      10,
      Paint()..color = Colors.blue,
    );

    // Draw result position
    final rAngle = -math.pi / 2 + (2 * math.pi * result / modulus);
    canvas.drawCircle(
      Offset(centerX + aRadius * math.cos(rAngle), centerY + aRadius * math.sin(rAngle)),
      10,
      Paint()..color = Colors.green,
    );

    // Draw arc showing the operation
    if (operationIndex == 0) {
      // Addition - draw arc from A to result
      final startAngle = -math.pi / 2 + (2 * math.pi * (valueA % modulus) / modulus);
      final sweepAngle = (2 * math.pi * valueB / modulus);

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: aRadius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Legend
    _drawText(canvas, 'a', Offset(20, size.height - 40), Colors.blue, fontSize: 12);
    canvas.drawCircle(Offset(35, size.height - 35), 5, Paint()..color = Colors.blue);

    _drawText(canvas, 'result', Offset(60, size.height - 40), Colors.green, fontSize: 12);
    canvas.drawCircle(Offset(105, size.height - 35), 5, Paint()..color = Colors.green);
  }

  void _drawNumberLineVisualization(Canvas canvas, Size size) {
    final padding = 40.0;
    final lineY = size.height / 2;
    final lineWidth = size.width - padding * 2;
    final spacing = lineWidth / modulus;

    // Draw number line
    canvas.drawLine(
      Offset(padding, lineY),
      Offset(size.width - padding, lineY),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2,
    );

    // Draw ticks and numbers
    for (int i = 0; i <= modulus; i++) {
      final x = padding + i * spacing;
      final displayNum = i % modulus;

      canvas.drawLine(
        Offset(x, lineY - 10),
        Offset(x, lineY + 10),
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = 2,
      );

      final isHighlighted = displayNum == (valueA % modulus) || displayNum == result;
      _drawText(
        canvas,
        '$displayNum',
        Offset(x, lineY + 25),
        isHighlighted ? AppColors.accent : AppColors.muted,
        fontSize: isHighlighted ? 14 : 11,
      );
    }

    // Draw wrapping arrow
    canvas.drawLine(
      Offset(size.width - padding, lineY - 30),
      Offset(padding, lineY - 30),
      Paint()
        ..color = Colors.purple.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );
    _drawText(canvas, 'wrap around', Offset(size.width / 2, lineY - 45), Colors.purple, fontSize: 10);

    // Highlight a and result
    final aX = padding + (valueA % modulus) * spacing;
    canvas.drawCircle(Offset(aX, lineY), 8, Paint()..color = Colors.blue);

    final rX = padding + result * spacing;
    canvas.drawCircle(Offset(rX, lineY), 8, Paint()..color = Colors.green);
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
  bool shouldRepaint(covariant ModularArithmeticPainter oldDelegate) =>
      modulus != oldDelegate.modulus ||
      valueA != oldDelegate.valueA ||
      valueB != oldDelegate.valueB ||
      result != oldDelegate.result ||
      showClock != oldDelegate.showClock;
}
