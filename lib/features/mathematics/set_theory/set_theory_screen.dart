import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 집합 연산 열거형
enum SetOperation {
  union('합집합', 'A ∪ B', '두 집합의 모든 원소'),
  intersection('교집합', 'A ∩ B', '공통 원소만'),
  differenceAB('차집합 A-B', 'A - B', 'A에만 있는 원소'),
  differenceBA('차집합 B-A', 'B - A', 'B에만 있는 원소'),
  symmetric('대칭차', 'A △ B', '한쪽에만 있는 원소');

  final String label;
  final String symbol;
  final String description;
  const SetOperation(this.label, this.symbol, this.description);
}

/// 집합 연산 화면
class SetTheoryScreen extends StatefulWidget {
  const SetTheoryScreen({super.key});

  @override
  State<SetTheoryScreen> createState() => _SetTheoryScreenState();
}

class _SetTheoryScreenState extends State<SetTheoryScreen> {
  SetOperation _operation = SetOperation.union;
  Set<int> _setA = {1, 2, 3, 4, 5};
  Set<int> _setB = {4, 5, 6, 7, 8};

  // 프리셋
  String? _selectedPreset;

  Set<int> get _result {
    switch (_operation) {
      case SetOperation.union:
        return _setA.union(_setB);
      case SetOperation.intersection:
        return _setA.intersection(_setB);
      case SetOperation.differenceAB:
        return _setA.difference(_setB);
      case SetOperation.differenceBA:
        return _setB.difference(_setA);
      case SetOperation.symmetric:
        return _setA.union(_setB).difference(_setA.intersection(_setB));
    }
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;

      switch (preset) {
        case 'disjoint':
          _setA = {1, 2, 3};
          _setB = {4, 5, 6};
          break;
        case 'subset':
          _setA = {1, 2, 3, 4, 5};
          _setB = {2, 3, 4};
          break;
        case 'equal':
          _setA = {1, 2, 3};
          _setB = {1, 2, 3};
          break;
        case 'overlap':
          _setA = {1, 2, 3, 4, 5};
          _setB = {4, 5, 6, 7, 8};
          break;
      }
    });
  }

  void _randomize() {
    HapticFeedback.mediumImpact();
    final random = math.Random();
    setState(() {
      _setA = Set<int>.from(
          List.generate(5, (_) => random.nextInt(10) + 1).toSet());
      _setB = Set<int>.from(
          List.generate(5, (_) => random.nextInt(10) + 1).toSet());
      _selectedPreset = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final intersection = _setA.intersection(_setB);
    final onlyA = _setA.difference(_setB);
    final onlyB = _setB.difference(_setA);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이산수학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '집합 연산',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '이산수학',
          title: '집합 연산',
          formula: _operation.symbol,
          formulaDescription: _operation.description,
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: VennDiagramPainter(
                setA: _setA,
                setB: _setB,
                operation: _operation,
                onlyA: onlyA,
                onlyB: onlyB,
                intersection: intersection,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 집합 관계 프리셋
              PresetGroup(
                label: '집합 관계',
                presets: [
                  PresetButton(
                    label: '서로소',
                    isSelected: _selectedPreset == 'disjoint',
                    onPressed: () => _applyPreset('disjoint'),
                  ),
                  PresetButton(
                    label: '부분집합',
                    isSelected: _selectedPreset == 'subset',
                    onPressed: () => _applyPreset('subset'),
                  ),
                  PresetButton(
                    label: '동치',
                    isSelected: _selectedPreset == 'equal',
                    onPressed: () => _applyPreset('equal'),
                  ),
                  PresetButton(
                    label: '겹침',
                    isSelected: _selectedPreset == 'overlap',
                    onPressed: () => _applyPreset('overlap'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 연산 선택
              PresetGroup(
                label: '연산 선택',
                presets: SetOperation.values.take(4).map((op) => PresetButton(
                  label: op.symbol,
                  isSelected: _operation == op,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _operation = op);
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
              // 집합 정보
              _SetStatsDisplay(
                setA: _setA,
                setB: _setB,
                result: _result,
                operation: _operation,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '랜덤 생성',
                icon: Icons.shuffle,
                isPrimary: true,
                onPressed: _randomize,
              ),
              SimButton(
                label: '대칭차',
                icon: Icons.compare_arrows,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _operation = SetOperation.symmetric);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 집합 통계 표시 위젯
class _SetStatsDisplay extends StatelessWidget {
  final Set<int> setA;
  final Set<int> setB;
  final Set<int> result;
  final SetOperation operation;

  const _SetStatsDisplay({
    required this.setA,
    required this.setB,
    required this.result,
    required this.operation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SetInfo(
                  label: 'A',
                  elements: setA,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SetInfo(
                  label: 'B',
                  elements: setB,
                  color: AppColors.accent2,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.cardBorder, height: 16),
          _SetInfo(
            label: '${operation.symbol} 결과',
            elements: result,
            color: Colors.white,
            isResult: true,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(label: '|A|', value: '${setA.length}', color: AppColors.accent),
              _StatChip(label: '|B|', value: '${setB.length}', color: AppColors.accent2),
              _StatChip(label: '|A∩B|', value: '${setA.intersection(setB).length}', color: Colors.purple),
              _StatChip(label: '|결과|', value: '${result.length}', color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// 집합 정보 위젯
class _SetInfo extends StatelessWidget {
  final String label;
  final Set<int> elements;
  final Color color;
  final bool isResult;

  const _SetInfo({
    required this.label,
    required this.elements,
    required this.color,
    this.isResult = false,
  });

  @override
  Widget build(BuildContext context) {
    final sortedList = elements.toList()..sort();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: isResult ? 13 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            elements.isEmpty ? '∅ (공집합)' : '{${sortedList.join(', ')}}',
            style: TextStyle(
              color: isResult ? Colors.white : AppColors.ink,
              fontSize: isResult ? 14 : 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// 벤 다이어그램 페인터
class VennDiagramPainter extends CustomPainter {
  final Set<int> setA;
  final Set<int> setB;
  final SetOperation operation;
  final Set<int> onlyA;
  final Set<int> onlyB;
  final Set<int> intersection;

  VennDiagramPainter({
    required this.setA,
    required this.setB,
    required this.operation,
    required this.onlyA,
    required this.onlyB,
    required this.intersection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final circleRadius = size.width * 0.25;
    final centerA = Offset(size.width * 0.35, centerY);
    final centerB = Offset(size.width * 0.65, centerY);

    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // 집합 A 원 (기본)
    canvas.drawCircle(
      centerA,
      circleRadius,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );

    // 집합 B 원 (기본)
    canvas.drawCircle(
      centerB,
      circleRadius,
      Paint()
        ..color = AppColors.accent2.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );

    // 결과 영역 하이라이트
    canvas.save();

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    switch (operation) {
      case SetOperation.union:
        canvas.drawCircle(centerA, circleRadius, highlightPaint);
        canvas.drawCircle(centerB, circleRadius, highlightPaint);
        break;
      case SetOperation.intersection:
        final path = Path();
        path.addOval(Rect.fromCircle(center: centerA, radius: circleRadius));
        canvas.clipPath(path);
        canvas.drawCircle(centerB, circleRadius, highlightPaint);
        break;
      case SetOperation.differenceAB:
        canvas.drawCircle(centerA, circleRadius, highlightPaint);
        canvas.drawCircle(
          centerB,
          circleRadius,
          Paint()
            ..color = AppColors.simBg
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          centerB,
          circleRadius,
          Paint()
            ..color = AppColors.accent2.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill,
        );
        break;
      case SetOperation.differenceBA:
        canvas.drawCircle(centerB, circleRadius, highlightPaint);
        canvas.drawCircle(
          centerA,
          circleRadius,
          Paint()
            ..color = AppColors.simBg
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          centerA,
          circleRadius,
          Paint()
            ..color = AppColors.accent.withValues(alpha: 0.2)
            ..style = PaintingStyle.fill,
        );
        break;
      case SetOperation.symmetric:
        canvas.drawCircle(centerA, circleRadius, highlightPaint);
        canvas.drawCircle(centerB, circleRadius, highlightPaint);
        // 교집합 부분 어둡게
        final path = Path();
        path.addOval(Rect.fromCircle(center: centerA, radius: circleRadius));
        canvas.clipPath(path);
        canvas.drawCircle(
          centerB,
          circleRadius,
          Paint()
            ..color = AppColors.simBg
            ..style = PaintingStyle.fill,
        );
        break;
    }

    canvas.restore();

    // 테두리 그리기
    canvas.drawCircle(
      centerA,
      circleRadius,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawCircle(
      centerB,
      circleRadius,
      Paint()
        ..color = AppColors.accent2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 원소 표시
    _drawElements(canvas, onlyA, centerA.dx - 40, centerY, AppColors.accent);
    _drawElements(canvas, onlyB, centerB.dx + 20, centerY, AppColors.accent2);
    _drawElements(canvas, intersection, (centerA.dx + centerB.dx) / 2 - 10, centerY, Colors.purple);

    // 레이블
    _drawText(canvas, 'A', Offset(centerA.dx - circleRadius + 10, centerY - circleRadius + 20),
        color: AppColors.accent, fontSize: 24, bold: true);
    _drawText(canvas, 'B', Offset(centerB.dx + circleRadius - 30, centerY - circleRadius + 20),
        color: AppColors.accent2, fontSize: 24, bold: true);
  }

  void _drawElements(Canvas canvas, Set<int> elements, double x, double y, Color color) {
    if (elements.isEmpty) return;

    final sortedList = elements.toList()..sort();
    final text = sortedList.join('\n');

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y - textPainter.height / 2));
  }

  void _drawText(Canvas canvas, String text, Offset position,
      {Color color = Colors.white, double fontSize = 14, bool bold = false}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant VennDiagramPainter oldDelegate) =>
      operation != oldDelegate.operation ||
      setA != oldDelegate.setA ||
      setB != oldDelegate.setB;
}
