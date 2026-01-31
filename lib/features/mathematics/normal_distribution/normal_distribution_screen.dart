import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 정규분포 시뮬레이션
class NormalDistributionScreen extends StatefulWidget {
  const NormalDistributionScreen({super.key});

  @override
  State<NormalDistributionScreen> createState() => _NormalDistributionScreenState();
}

class _NormalDistributionScreenState extends State<NormalDistributionScreen> {
  double _mean = 0;
  double _stdDev = 1;
  bool _showAreas = true;

  double _normalPdf(double x) {
    final exponent = -0.5 * math.pow((x - _mean) / _stdDev, 2);
    return math.exp(exponent) / (_stdDev * math.sqrt(2 * math.pi));
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
              '수학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '정규분포',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '정규분포 (Normal Distribution)',
          formula: 'f(x) = (1/σ√2π) × e^(-(x-μ)²/2σ²)',
          formulaDescription: '자연과 사회 현상에서 가장 흔한 확률분포',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _NormalDistributionPainter(
                mean: _mean,
                stdDev: _stdDev,
                showAreas: _showAreas,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 정보 표시
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '평균 (μ)', value: _mean.toStringAsFixed(1), color: Colors.blue),
                        _InfoItem(label: '표준편차 (σ)', value: _stdDev.toStringAsFixed(1), color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '68-95-99.7 법칙',
                      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const Text(
                      '±1σ: 68.3% | ±2σ: 95.4% | ±3σ: 99.7%',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 영역 표시 토글
              Row(
                children: [
                  const Text('σ 영역 표시', style: TextStyle(color: AppColors.muted)),
                  const Spacer(),
                  Switch(
                    value: _showAreas,
                    onChanged: (v) => setState(() => _showAreas = v),
                    activeColor: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '평균 (μ)',
                  value: _mean,
                  min: -3,
                  max: 3,
                  defaultValue: 0,
                  formatValue: (v) => v.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _mean = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '표준편차 (σ)',
                    value: _stdDev,
                    min: 0.5,
                    max: 2.5,
                    defaultValue: 1,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _stdDev = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _NormalDistributionPainter extends CustomPainter {
  final double mean;
  final double stdDev;
  final bool showAreas;

  _NormalDistributionPainter({
    required this.mean,
    required this.stdDev,
    required this.showAreas,
  });

  double _normalPdf(double x) {
    final exponent = -0.5 * math.pow((x - mean) / stdDev, 2);
    return math.exp(exponent) / (stdDev * math.sqrt(2 * math.pi));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;
    final centerY = size.height - padding;

    // x 범위
    final xMin = mean - 4 * stdDev;
    final xMax = mean + 4 * stdDev;
    final xScale = graphWidth / (xMax - xMin);
    final yScale = graphHeight * 0.9;

    // 축
    canvas.drawLine(
      Offset(padding, centerY),
      Offset(size.width - padding, centerY),
      Paint()..color = AppColors.muted,
    );

    // σ 영역 색칠
    if (showAreas) {
      // ±3σ
      _fillArea(canvas, size, padding, centerY, xMin, xScale, yScale, mean - 3 * stdDev, mean + 3 * stdDev, Colors.blue.withValues(alpha: 0.1));
      // ±2σ
      _fillArea(canvas, size, padding, centerY, xMin, xScale, yScale, mean - 2 * stdDev, mean + 2 * stdDev, Colors.blue.withValues(alpha: 0.15));
      // ±1σ
      _fillArea(canvas, size, padding, centerY, xMin, xScale, yScale, mean - stdDev, mean + stdDev, Colors.blue.withValues(alpha: 0.2));
    }

    // 곡선
    final path = Path();
    for (double px = 0; px <= graphWidth; px += 2) {
      final x = xMin + px / xScale;
      final y = _normalPdf(x);
      final screenX = padding + px;
      final screenY = centerY - y * yScale;

      if (px == 0) {
        path.moveTo(screenX, screenY);
      } else {
        path.lineTo(screenX, screenY);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 평균선
    final meanX = padding + (mean - xMin) * xScale;
    canvas.drawLine(
      Offset(meanX, padding),
      Offset(meanX, centerY),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 2,
    );

    // σ 표시
    if (showAreas) {
      for (int i = -3; i <= 3; i++) {
        if (i == 0) continue;
        final sigmaX = padding + (mean + i * stdDev - xMin) * xScale;
        canvas.drawLine(
          Offset(sigmaX, centerY - 5),
          Offset(sigmaX, centerY + 5),
          Paint()..color = AppColors.muted..strokeWidth = 1,
        );
        _drawText(canvas, '${i}σ', Offset(sigmaX - 8, centerY + 8), AppColors.muted, fontSize: 9);
      }
    }

    // μ 표시
    _drawText(canvas, 'μ', Offset(meanX - 5, centerY + 8), Colors.red, fontSize: 10);

    // 범례
    if (showAreas) {
      _drawText(canvas, '±1σ: 68.3%', Offset(size.width - 80, 20), Colors.blue.withValues(alpha: 0.8), fontSize: 9);
      _drawText(canvas, '±2σ: 95.4%', Offset(size.width - 80, 32), Colors.blue.withValues(alpha: 0.6), fontSize: 9);
      _drawText(canvas, '±3σ: 99.7%', Offset(size.width - 80, 44), Colors.blue.withValues(alpha: 0.4), fontSize: 9);
    }
  }

  void _fillArea(Canvas canvas, Size size, double padding, double centerY, double xMin, double xScale, double yScale, double x1, double x2, Color color) {
    final path = Path();
    final startPx = (x1 - xMin) * xScale;
    final endPx = (x2 - xMin) * xScale;

    path.moveTo(padding + startPx, centerY);
    for (double px = startPx; px <= endPx; px += 2) {
      final x = xMin + px / xScale;
      final y = _normalPdf(x);
      path.lineTo(padding + px, centerY - y * yScale);
    }
    path.lineTo(padding + endPx, centerY);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
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
  bool shouldRepaint(covariant _NormalDistributionPainter oldDelegate) => true;
}
