import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 손실 함수 비교 시뮬레이션
class LossFunctionsScreen extends StatefulWidget {
  const LossFunctionsScreen({super.key});

  @override
  State<LossFunctionsScreen> createState() => _LossFunctionsScreenState();
}

class _LossFunctionsScreenState extends State<LossFunctionsScreen> {
  String _selectedLoss = 'MSE';
  double _prediction = 0.5;
  double _target = 0.8;

  final Map<String, String> _lossFormulas = {
    'MSE': 'L = (y - ŷ)²',
    'MAE': 'L = |y - ŷ|',
    'Cross-Entropy': 'L = -y·log(ŷ)',
    'Huber': 'L = ½(y-ŷ)² or δ|y-ŷ|-½δ²',
  };

  final Map<String, String> _lossDescriptions = {
    'MSE': '평균 제곱 오차: 큰 오차에 더 민감, 회귀에 주로 사용',
    'MAE': '평균 절대 오차: 이상치에 덜 민감',
    'Cross-Entropy': '분류 문제에서 확률 분포 비교에 사용',
    'Huber': 'MSE와 MAE의 장점 결합, 이상치에 강건',
  };

  double _calculateLoss(String type, double y, double yHat) {
    final diff = y - yHat;
    switch (type) {
      case 'MSE':
        return diff * diff;
      case 'MAE':
        return diff.abs();
      case 'Cross-Entropy':
        // 안정성을 위해 클리핑
        final clipped = yHat.clamp(0.001, 0.999);
        return -y * math.log(clipped) - (1 - y) * math.log(1 - clipped);
      case 'Huber':
        const delta = 0.5;
        if (diff.abs() <= delta) {
          return 0.5 * diff * diff;
        } else {
          return delta * diff.abs() - 0.5 * delta * delta;
        }
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLoss = _calculateLoss(_selectedLoss, _target, _prediction);

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
              'AI/ML',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '손실 함수',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML',
          title: '손실 함수 비교',
          formula: _lossFormulas[_selectedLoss] ?? '',
          formulaDescription: _lossDescriptions[_selectedLoss] ?? '',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _LossFunctionsPainter(
                selectedLoss: _selectedLoss,
                target: _target,
                prediction: _prediction,
                calculateLoss: _calculateLoss,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 현재 손실 표시
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
                        _InfoItem(label: '목표 (y)', value: _target.toStringAsFixed(2), color: Colors.green),
                        _InfoItem(label: '예측 (ŷ)', value: _prediction.toStringAsFixed(2), color: Colors.blue),
                        _InfoItem(label: '손실 (L)', value: currentLoss.toStringAsFixed(4), color: Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 손실 함수 선택
              PresetGroup(
                label: '손실 함수',
                presets: _lossFormulas.keys.map((loss) {
                  return PresetButton(
                    label: loss,
                    isSelected: _selectedLoss == loss,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedLoss = loss);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '예측값 (ŷ)',
                  value: _prediction,
                  min: 0,
                  max: 1,
                  defaultValue: 0.5,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _prediction = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '목표값 (y)',
                    value: _target,
                    min: 0,
                    max: 1,
                    defaultValue: 0.8,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _target = v),
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
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _LossFunctionsPainter extends CustomPainter {
  final String selectedLoss;
  final double target;
  final double prediction;
  final double Function(String, double, double) calculateLoss;

  _LossFunctionsPainter({
    required this.selectedLoss,
    required this.target,
    required this.prediction,
    required this.calculateLoss,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 축
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );

    // 손실 함수 곡선 그리기
    final colors = {
      'MSE': Colors.blue,
      'MAE': Colors.green,
      'Cross-Entropy': Colors.purple,
      'Huber': Colors.orange,
    };

    for (var entry in colors.entries) {
      final path = Path();
      double maxLoss = 0;

      // 최대 손실 계산
      for (double x = 0; x <= 1; x += 0.01) {
        final loss = calculateLoss(entry.key, target, x);
        if (loss > maxLoss && loss.isFinite) maxLoss = loss;
      }
      maxLoss = maxLoss.clamp(0.1, 5.0);

      for (double x = 0; x <= 1; x += 0.01) {
        final loss = calculateLoss(entry.key, target, x);
        final px = padding + x * graphWidth;
        final py = size.height - padding - (loss / maxLoss * graphHeight).clamp(0, graphHeight);

        if (x == 0) {
          path.moveTo(px, py);
        } else if (loss.isFinite) {
          path.lineTo(px, py);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = entry.key == selectedLoss ? entry.value : entry.value.withValues(alpha: 0.2)
          ..strokeWidth = entry.key == selectedLoss ? 3 : 1
          ..style = PaintingStyle.stroke,
      );
    }

    // 현재 예측 위치 마커
    final loss = calculateLoss(selectedLoss, target, prediction);
    double maxLoss = 0;
    for (double x = 0; x <= 1; x += 0.01) {
      final l = calculateLoss(selectedLoss, target, x);
      if (l > maxLoss && l.isFinite) maxLoss = l;
    }
    maxLoss = maxLoss.clamp(0.1, 5.0);

    final markerX = padding + prediction * graphWidth;
    final markerY = size.height - padding - (loss / maxLoss * graphHeight).clamp(0, graphHeight);

    canvas.drawCircle(Offset(markerX, markerY), 8, Paint()..color = Colors.red);
    canvas.drawCircle(
      Offset(markerX, markerY),
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 목표 위치 수직선
    final targetX = padding + target * graphWidth;
    canvas.drawLine(
      Offset(targetX, padding),
      Offset(targetX, size.height - padding),
      Paint()
        ..color = Colors.green.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 라벨
    _drawText(canvas, 'ŷ (예측)', Offset(size.width - padding - 30, size.height - padding + 10), AppColors.muted);
    _drawText(canvas, 'Loss', Offset(padding - 30, padding - 10), AppColors.muted);
    _drawText(canvas, 'y', Offset(targetX - 5, size.height - padding + 10), Colors.green);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _LossFunctionsPainter oldDelegate) => true;
}
