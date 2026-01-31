import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 황금비 시뮬레이션
class GoldenRatioScreen extends StatefulWidget {
  const GoldenRatioScreen({super.key});

  @override
  State<GoldenRatioScreen> createState() => _GoldenRatioScreenState();
}

class _GoldenRatioScreenState extends State<GoldenRatioScreen> {
  String _visualization = 'rectangle';
  int _spiralSteps = 8;

  static const double phi = 1.6180339887498948;

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
              '수학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '황금비',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '황금비 (Golden Ratio)',
          formula: 'φ = (1 + √5) / 2 ≈ 1.618',
          formulaDescription: '자연과 예술에서 발견되는 가장 아름다운 비율',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _GoldenRatioPainter(
                visualization: _visualization,
                spiralSteps: _spiralSteps,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 황금비 값
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('φ = ', style: TextStyle(color: AppColors.muted, fontSize: 20)),
                        Text(
                          phi.toStringAsFixed(10),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Text('...', style: TextStyle(color: AppColors.muted, fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'φ² = φ + 1,  1/φ = φ - 1',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 시각화 선택
              PresetGroup(
                label: '시각화',
                presets: [
                  PresetButton(
                    label: '황금 사각형',
                    isSelected: _visualization == 'rectangle',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _visualization = 'rectangle');
                    },
                  ),
                  PresetButton(
                    label: '피보나치',
                    isSelected: _visualization == 'fibonacci',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _visualization = 'fibonacci');
                    },
                  ),
                  PresetButton(
                    label: '오각형',
                    isSelected: _visualization == 'pentagon',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _visualization = 'pentagon');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_visualization == 'rectangle')
                ControlGroup(
                  primaryControl: SimSlider(
                    label: '나선 단계',
                    value: _spiralSteps.toDouble(),
                    min: 3,
                    max: 12,
                    defaultValue: 8,
                    formatValue: (v) => '${v.toInt()}단계',
                    onChanged: (v) => setState(() => _spiralSteps = v.toInt()),
                  ),
                ),

              // 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('황금비의 발견', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 4),
                    Text(
                      '• 피보나치 수열의 연속 항 비율\n'
                      '• 정오각형의 대각선과 변의 비\n'
                      '• 자연: 해바라기, 소라껍데기\n'
                      '• 예술: 파르테논 신전, 모나리자',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldenRatioPainter extends CustomPainter {
  final String visualization;
  final int spiralSteps;

  static const double phi = 1.6180339887498948;

  _GoldenRatioPainter({required this.visualization, required this.spiralSteps});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    switch (visualization) {
      case 'rectangle':
        _drawGoldenRectangle(canvas, size);
        break;
      case 'fibonacci':
        _drawFibonacci(canvas, size);
        break;
      case 'pentagon':
        _drawPentagon(canvas, size);
        break;
    }
  }

  void _drawGoldenRectangle(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    var rectWidth = size.width * 0.7;
    var rectHeight = rectWidth / phi;

    if (rectHeight > size.height * 0.8) {
      rectHeight = size.height * 0.8;
      rectWidth = rectHeight * phi;
    }

    var x = centerX - rectWidth / 2;
    var y = centerY - rectHeight / 2;
    var w = rectWidth;
    var h = rectHeight;

    // 황금 사각형과 나선
    final spiralPath = Path();
    spiralPath.moveTo(x + w, y + h);

    for (int i = 0; i < spiralSteps; i++) {
      // 사각형 그리기
      canvas.drawRect(
        Rect.fromLTWH(x, y, w, h),
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      // 정사각형 분할
      final squareSize = h;
      canvas.drawRect(
        Rect.fromLTWH(x, y, squareSize, squareSize),
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill,
      );

      // 사분원 추가 (나선)
      final arcRect = Rect.fromLTWH(x, y, squareSize * 2, squareSize * 2);
      spiralPath.arcTo(arcRect, math.pi, -math.pi / 2, false);

      // 다음 사각형으로 이동
      x += squareSize;
      w -= squareSize;
      final temp = w;
      w = h;
      h = temp;

      // 회전
      if (i % 4 == 0) {
        y += 0;
      } else if (i % 4 == 1) {
        y += h;
      }
    }

    // 나선 그리기
    canvas.drawPath(
      spiralPath,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawFibonacci(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 피보나치 수열
    final fib = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55];
    final barWidth = size.width / 12;
    final maxHeight = size.height * 0.8;
    final scale = maxHeight / fib.last;

    for (int i = 0; i < fib.length; i++) {
      final barHeight = fib[i] * scale;
      final x = centerX - (fib.length * barWidth) / 2 + i * barWidth;
      final y = size.height - 20 - barHeight;

      canvas.drawRect(
        Rect.fromLTWH(x + 2, y, barWidth - 4, barHeight),
        Paint()..color = AppColors.accent,
      );

      _drawText(canvas, '${fib[i]}', Offset(x + barWidth / 2 - 8, y - 15), AppColors.ink, fontSize: 10);
    }

    // 비율 표시
    _drawText(canvas, '연속 항의 비: 1, 2, 1.5, 1.67, 1.6, 1.625... → φ', Offset(20, 20), AppColors.muted, fontSize: 11);
  }

  void _drawPentagon(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.35;

    // 정오각형 꼭짓점
    final points = <Offset>[];
    for (int i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / 5;
      points.add(Offset(
        centerX + radius * math.cos(angle),
        centerY + radius * math.sin(angle),
      ));
    }

    // 정오각형
    final pentagonPath = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < 5; i++) {
      pentagonPath.lineTo(points[i].dx, points[i].dy);
    }
    pentagonPath.close();

    canvas.drawPath(
      pentagonPath,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      pentagonPath,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 대각선
    for (int i = 0; i < 5; i++) {
      for (int j = i + 2; j < 5; j++) {
        if ((j - i) != 4) {
          canvas.drawLine(
            points[i],
            points[j],
            Paint()
              ..color = Colors.blue
              ..strokeWidth = 1,
          );
        }
      }
    }

    // 대각선/변 = φ
    _drawText(canvas, '대각선 / 변 = φ', Offset(centerX - 50, size.height - 30), AppColors.muted, fontSize: 12);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _GoldenRatioPainter oldDelegate) => true;
}
