import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Boolean Algebra Visualization
/// 불 대수 시각화
class BooleanAlgebraScreen extends StatefulWidget {
  const BooleanAlgebraScreen({super.key});

  @override
  State<BooleanAlgebraScreen> createState() => _BooleanAlgebraScreenState();
}

class _BooleanAlgebraScreenState extends State<BooleanAlgebraScreen> {
  bool inputA = true;
  bool inputB = false;
  bool inputC = true;
  int expressionIndex = 0;
  bool isKorean = true;

  final List<(String, String, bool Function(bool, bool, bool))> _expressions = [
    ('A AND B', 'A ∧ B', (a, b, c) => a && b),
    ('A OR B', 'A ∨ B', (a, b, c) => a || b),
    ('NOT A', '¬A', (a, b, c) => !a),
    ('A XOR B', 'A ⊕ B', (a, b, c) => a != b),
    ('A NAND B', '¬(A ∧ B)', (a, b, c) => !(a && b)),
    ('A NOR B', '¬(A ∨ B)', (a, b, c) => !(a || b)),
    ('(A AND B) OR C', '(A ∧ B) ∨ C', (a, b, c) => (a && b) || c),
    ('A AND (B OR C)', 'A ∧ (B ∨ C)', (a, b, c) => a && (b || c)),
    ("De Morgan's 1", '¬(A ∧ B) = ¬A ∨ ¬B', (a, b, c) => !(a && b)),
    ("De Morgan's 2", '¬(A ∨ B) = ¬A ∧ ¬B', (a, b, c) => !(a || b)),
  ];

  bool get _result => _expressions[expressionIndex].$3(inputA, inputB, inputC);

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      inputA = true;
      inputB = false;
      inputC = true;
      expressionIndex = 0;
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
              isKorean ? '불 대수' : 'Boolean Algebra',
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
          title: isKorean ? '불 대수' : 'Boolean Algebra',
          formula: _expressions[expressionIndex].$2,
          formulaDescription: isKorean
              ? '불 대수는 참/거짓 값에 대한 연산을 다룹니다. 디지털 회로와 프로그래밍의 기초입니다.'
              : 'Boolean algebra deals with true/false values. It is the foundation of digital circuits and programming.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: BooleanAlgebraPainter(
                inputA: inputA,
                inputB: inputB,
                inputC: inputC,
                expressionIndex: expressionIndex,
                result: _result,
                expression: _expressions[expressionIndex].$2,
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
                  color: _result
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _result ? Colors.green : Colors.red),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expressions[expressionIndex].$2,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 20,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '=',
                      style: const TextStyle(color: AppColors.muted, fontSize: 20),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _result ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _result ? (isKorean ? '참' : 'TRUE') : (isKorean ? '거짓' : 'FALSE'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Input variables
              Row(
                children: [
                  Expanded(child: _InputToggle(label: 'A', value: inputA, onChanged: (v) => setState(() => inputA = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _InputToggle(label: 'B', value: inputB, onChanged: (v) => setState(() => inputB = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _InputToggle(label: 'C', value: inputC, onChanged: (v) => setState(() => inputC = v))),
                ],
              ),
              const SizedBox(height: 16),

              // Expression selection
              PresetGroup(
                label: isKorean ? '논리 연산' : 'Logic Operations',
                presets: [
                  PresetButton(label: 'AND', isSelected: expressionIndex == 0, onPressed: () { HapticFeedback.selectionClick(); setState(() => expressionIndex = 0); }),
                  PresetButton(label: 'OR', isSelected: expressionIndex == 1, onPressed: () { HapticFeedback.selectionClick(); setState(() => expressionIndex = 1); }),
                  PresetButton(label: 'NOT', isSelected: expressionIndex == 2, onPressed: () { HapticFeedback.selectionClick(); setState(() => expressionIndex = 2); }),
                  PresetButton(label: 'XOR', isSelected: expressionIndex == 3, onPressed: () { HapticFeedback.selectionClick(); setState(() => expressionIndex = 3); }),
                  PresetButton(label: 'NAND', isSelected: expressionIndex == 4, onPressed: () { HapticFeedback.selectionClick(); setState(() => expressionIndex = 4); }),
                  PresetButton(label: 'NOR', isSelected: expressionIndex == 5, onPressed: () { HapticFeedback.selectionClick(); setState(() => expressionIndex = 5); }),
                ],
              ),
              const SizedBox(height: 12),
              PresetGroup(
                label: isKorean ? '복합 표현식' : 'Compound Expressions',
                presets: [
                  PresetButton(label: '(A∧B)∨C', isSelected: expressionIndex == 6, onPressed: () { HapticFeedback.selectionClick(); setState(() => expressionIndex = 6); }),
                  PresetButton(label: 'A∧(B∨C)', isSelected: expressionIndex == 7, onPressed: () { HapticFeedback.selectionClick(); setState(() => expressionIndex = 7); }),
                  PresetButton(label: "De Morgan 1", isSelected: expressionIndex == 8, onPressed: () { HapticFeedback.selectionClick(); setState(() => expressionIndex = 8); }),
                  PresetButton(label: "De Morgan 2", isSelected: expressionIndex == 9, onPressed: () { HapticFeedback.selectionClick(); setState(() => expressionIndex = 9); }),
                ],
              ),
              const SizedBox(height: 16),

              // Truth table preview
              _TruthTablePreview(
                expressionIndex: expressionIndex,
                expression: _expressions[expressionIndex],
                isKorean: isKorean,
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
}

class _InputToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _InputToggle({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: value ? AppColors.accent.withValues(alpha: 0.2) : AppColors.simBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: value ? AppColors.accent : AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: value ? AppColors.accent : AppColors.muted, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value ? '1' : '0', style: TextStyle(color: value ? AppColors.accent : AppColors.muted, fontSize: 20, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}

class _TruthTablePreview extends StatelessWidget {
  final int expressionIndex;
  final (String, String, bool Function(bool, bool, bool)) expression;
  final bool isKorean;

  const _TruthTablePreview({required this.expressionIndex, required this.expression, required this.isKorean});

  @override
  Widget build(BuildContext context) {
    // Simplified truth table for 2 variables
    final rows = <List<dynamic>>[];

    for (int a = 0; a <= 1; a++) {
      for (int b = 0; b <= 1; b++) {
        final result = expression.$3(a == 1, b == 1, true);
        rows.add([a, b, result ? 1 : 0]);
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKorean ? '진리표 (A, B만)' : 'Truth Table (A, B only)',
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _TableCell(text: 'A', isHeader: true),
              _TableCell(text: 'B', isHeader: true),
              Expanded(child: _TableCell(text: isKorean ? '결과' : 'Out', isHeader: true)),
            ],
          ),
          ...rows.map((row) => Row(
                children: [
                  _TableCell(text: '${row[0]}'),
                  _TableCell(text: '${row[1]}'),
                  Expanded(child: _TableCell(text: '${row[2]}', isResult: row[2] == 1)),
                ],
              )),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isResult;

  const _TableCell({required this.text, this.isHeader = false, this.isResult = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isHeader ? AppColors.muted : isResult ? Colors.green : AppColors.ink,
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class BooleanAlgebraPainter extends CustomPainter {
  final bool inputA, inputB, inputC;
  final int expressionIndex;
  final bool result;
  final String expression;
  final bool isKorean;

  BooleanAlgebraPainter({
    required this.inputA,
    required this.inputB,
    required this.inputC,
    required this.expressionIndex,
    required this.result,
    required this.expression,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Draw Venn diagram representation
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = 60.0;

    // Circle A (left)
    final circleACenter = Offset(centerX - 30, centerY);
    _drawCircle(canvas, circleACenter, radius, 'A', inputA);

    // Circle B (right)
    final circleBCenter = Offset(centerX + 30, centerY);
    _drawCircle(canvas, circleBCenter, radius, 'B', inputB);

    // Highlight result region
    _highlightResultRegion(canvas, circleACenter, circleBCenter, radius);

    // Labels
    _drawText(canvas, 'A', circleACenter + const Offset(-40, -50), inputA ? Colors.green : Colors.red);
    _drawText(canvas, 'B', circleBCenter + const Offset(40, -50), inputB ? Colors.green : Colors.red);
  }

  void _drawCircle(Canvas canvas, Offset center, double radius, String label, bool value) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = value
            ? AppColors.accent.withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.1),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = value ? AppColors.accent : Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _highlightResultRegion(Canvas canvas, Offset centerA, Offset centerB, double radius) {
    // Simplified: just highlight intersection or union based on operation
    if (expressionIndex == 0 && inputA && inputB) {
      // AND - intersection
      _drawIntersection(canvas, centerA, centerB, radius);
    } else if (expressionIndex == 1 && (inputA || inputB)) {
      // OR - union (simplified as both circles highlighted)
    }
  }

  void _drawIntersection(Canvas canvas, Offset centerA, Offset centerB, double radius) {
    // Approximate intersection highlight
    final path = Path();
    path.addArc(
      Rect.fromCircle(center: centerA, radius: radius),
      -0.8,
      1.6,
    );
    path.addArc(
      Rect.fromCircle(center: centerB, radius: radius),
      2.34,
      1.6,
    );
    canvas.drawPath(
      path,
      Paint()..color = Colors.yellow.withValues(alpha: 0.5),
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant BooleanAlgebraPainter oldDelegate) =>
      inputA != oldDelegate.inputA ||
      inputB != oldDelegate.inputB ||
      expressionIndex != oldDelegate.expressionIndex;
}
