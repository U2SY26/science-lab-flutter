import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 손실 함수 열거형
enum LossFunction {
  quadratic('이차 함수', 'f(x,y) = x² + y²', '볼록 함수, 전역 최적점'),
  rosenbrock('Rosenbrock', 'f(x,y) = (1-x)² + 100(y-x²)²', '좁은 골짜기'),
  saddle('안장점', 'f(x,y) = x² - y²', '안장점 존재'),
  rastrigin('Rastrigin', 'f(x,y) = 20 + x² + y² - 10cos(...)', '다수의 지역 최적점');

  final String label;
  final String formula;
  final String description;
  const LossFunction(this.label, this.formula, this.description);
}

/// 경사 하강법 시각화
class GradientDescentScreen extends StatefulWidget {
  const GradientDescentScreen({super.key});

  @override
  State<GradientDescentScreen> createState() => _GradientDescentScreenState();
}

class _GradientDescentScreenState extends State<GradientDescentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 기본값
  static const double _defaultLearningRate = 0.1;

  // 현재 위치
  double x = 2.0;
  double y = 2.0;

  // 하이퍼파라미터
  double learningRate = _defaultLearningRate;
  LossFunction _lossFunction = LossFunction.quadratic;

  // 경로 기록
  List<Offset> path = [];

  // 상태
  bool isRunning = false;
  int step = 0;
  bool _converged = false;

  // 프리셋
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _reset();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_update);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    final random = math.Random();
    setState(() {
      x = (random.nextDouble() - 0.5) * 4;
      y = (random.nextDouble() - 0.5) * 4;
      path = [Offset(x, y)];
      step = 0;
      _converged = false;
      isRunning = false;
      _controller.stop();
    });
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      _converged = false;
      isRunning = false;
      _controller.stop();

      switch (preset) {
        case 'fast':
          learningRate = 0.3;
          _lossFunction = LossFunction.quadratic;
          break;
        case 'slow':
          learningRate = 0.05;
          _lossFunction = LossFunction.quadratic;
          break;
        case 'challenge':
          learningRate = 0.001;
          _lossFunction = LossFunction.rosenbrock;
          break;
        case 'trap':
          learningRate = 0.1;
          _lossFunction = LossFunction.rastrigin;
          break;
      }
    });
    _reset();
  }

  // 손실 함수들
  double _loss(double x, double y) {
    switch (_lossFunction) {
      case LossFunction.quadratic:
        return x * x + y * y;
      case LossFunction.rosenbrock:
        return (math.pow(1 - x, 2) + 100 * math.pow(y - x * x, 2)).toDouble();
      case LossFunction.saddle:
        return x * x - y * y;
      case LossFunction.rastrigin:
        return 20 +
            x * x +
            y * y -
            10 * (math.cos(2 * math.pi * x) + math.cos(2 * math.pi * y));
    }
  }

  // 그래디언트 계산
  (double, double) _gradient(double x, double y) {
    switch (_lossFunction) {
      case LossFunction.quadratic:
        return (2 * x, 2 * y);
      case LossFunction.rosenbrock:
        double dx = -2 * (1 - x) - 400 * x * (y - x * x);
        double dy = 200 * (y - x * x);
        return (dx, dy);
      case LossFunction.saddle:
        return (2 * x, -2 * y);
      case LossFunction.rastrigin:
        double dx = 2 * x + 20 * math.pi * math.sin(2 * math.pi * x);
        double dy = 2 * y + 20 * math.pi * math.sin(2 * math.pi * y);
        return (dx, dy);
    }
  }

  void _update() {
    if (!isRunning) return;

    setState(() {
      final (dx, dy) = _gradient(x, y);

      // 그래디언트 클리핑
      double gradNorm = math.sqrt(dx * dx + dy * dy);
      double clipDx = dx;
      double clipDy = dy;
      if (gradNorm > 10) {
        clipDx = dx / gradNorm * 10;
        clipDy = dy / gradNorm * 10;
      }

      x -= learningRate * clipDx;
      y -= learningRate * clipDy;

      // 경계 제한
      x = x.clamp(-3.0, 3.0);
      y = y.clamp(-3.0, 3.0);

      path.add(Offset(x, y));
      if (path.length > 500) path.removeAt(0);

      step++;

      // 수렴 확인
      if (gradNorm < 0.001) {
        _converged = true;
        isRunning = false;
        _controller.stop();
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _toggleRunning() {
    HapticFeedback.selectionClick();
    setState(() {
      isRunning = !isRunning;
      if (isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _singleStep() {
    if (!isRunning) {
      HapticFeedback.lightImpact();
      setState(() {
        final (dx, dy) = _gradient(x, y);
        x -= learningRate * dx;
        y -= learningRate * dy;
        x = x.clamp(-3.0, 3.0);
        y = y.clamp(-3.0, 3.0);
        path.add(Offset(x, y));
        step++;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLoss = _loss(x, y);
    final (gradX, gradY) = _gradient(x, y);
    final gradNorm = math.sqrt(gradX * gradX + gradY * gradY);

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
              '딥러닝',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '경사 하강법',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '딥러닝',
          title: '경사 하강법',
          formula: 'θ = θ - α∇L(θ)',
          formulaDescription: _lossFunction.description,
          simulation: SizedBox.expand(
            child: CustomPaint(
              painter: GradientDescentPainter(
                x: x,
                y: y,
                path: path,
                lossFunction: _lossFunction,
                converged: _converged,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋
              PresetGroup(
                label: '학습 시나리오',
                presets: [
                  PresetButton(
                    label: '빠른 수렴',
                    isSelected: _selectedPreset == 'fast',
                    onPressed: () => _applyPreset('fast'),
                  ),
                  PresetButton(
                    label: '느린 수렴',
                    isSelected: _selectedPreset == 'slow',
                    onPressed: () => _applyPreset('slow'),
                  ),
                  PresetButton(
                    label: '도전',
                    isSelected: _selectedPreset == 'challenge',
                    onPressed: () => _applyPreset('challenge'),
                  ),
                  PresetButton(
                    label: '함정',
                    isSelected: _selectedPreset == 'trap',
                    onPressed: () => _applyPreset('trap'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 통계
              _StatsDisplay(
                step: step,
                loss: currentLoss,
                x: x,
                y: y,
                gradNorm: gradNorm,
                converged: _converged,
              ),
              const SizedBox(height: 16),
              // 손실 함수 선택
              PresetGroup(
                label: '손실 함수',
                presets: LossFunction.values.map((f) => PresetButton(
                  label: f.label,
                  isSelected: _lossFunction == f,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _lossFunction = f;
                      _selectedPreset = null;
                    });
                    _reset();
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
              // 학습률 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '학습률 (α)',
                  value: learningRate,
                  min: 0.001,
                  max: 0.5,
                  defaultValue: _defaultLearningRate,
                  formatValue: (v) => v.toStringAsFixed(3),
                  onChanged: (v) => setState(() {
                    learningRate = v;
                    _selectedPreset = null;
                  }),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning ? '정지' : '시작',
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleRunning,
              ),
              SimButton(
                label: '한 스텝',
                icon: Icons.skip_next,
                onPressed: _singleStep,
              ),
              SimButton(
                label: '리셋',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 통계 표시 위젯
class _StatsDisplay extends StatelessWidget {
  final int step;
  final double loss;
  final double x;
  final double y;
  final double gradNorm;
  final bool converged;

  const _StatsDisplay({
    required this.step,
    required this.loss,
    required this.x,
    required this.y,
    required this.gradNorm,
    required this.converged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: converged ? AppColors.accent2 : AppColors.cardBorder,
          width: converged ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(label: 'Step', value: '$step', color: AppColors.accent),
              _StatItem(
                label: 'Loss',
                value: loss.toStringAsFixed(4),
                color: converged ? AppColors.accent2 : AppColors.accent,
              ),
              _StatItem(label: '|∇L|', value: gradNorm.toStringAsFixed(4), color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '위치: (${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)})',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              if (converged) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent2.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '수렴!',
                    style: TextStyle(
                      color: AppColors.accent2,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class GradientDescentPainter extends CustomPainter {
  final double x;
  final double y;
  final List<Offset> path;
  final LossFunction lossFunction;
  final bool converged;

  GradientDescentPainter({
    required this.x,
    required this.y,
    required this.path,
    required this.lossFunction,
    required this.converged,
  });

  double _loss(double x, double y) {
    switch (lossFunction) {
      case LossFunction.quadratic:
        return x * x + y * y;
      case LossFunction.rosenbrock:
        return (math.pow(1 - x, 2) + 100 * math.pow(y - x * x, 2)).toDouble();
      case LossFunction.saddle:
        return x * x - y * y;
      case LossFunction.rastrigin:
        return 20 +
            x * x +
            y * y -
            10 * (math.cos(2 * math.pi * x) + math.cos(2 * math.pi * y));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 크기 유효성 검사
    if (size.width <= 0 || size.height <= 0) return;

    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 6;

    // 손실 함수 시각화 (히트맵) - 성능 최적화를 위해 step 8 사용
    const step = 8.0;
    for (double px = 0; px < size.width; px += step) {
      for (double py = 0; py < size.height; py += step) {
        final fx = (px - centerX) / scale;
        final fy = (py - centerY) / scale;
        double loss = _loss(fx, fy);

        double normalizedLoss;
        if (lossFunction == LossFunction.rosenbrock) {
          normalizedLoss = (math.log(loss + 1) / 10).clamp(0, 1);
        } else if (lossFunction == LossFunction.rastrigin) {
          normalizedLoss = (loss / 80).clamp(0, 1);
        } else {
          normalizedLoss = (loss / 18).clamp(0, 1);
        }

        final color = Color.lerp(
          const Color(0xFF001030),
          AppColors.accent2,
          normalizedLoss,
        )!;

        canvas.drawRect(
          Rect.fromLTWH(px, py, step, step),
          Paint()..color = color.withValues(alpha: 0.6),
        );
      }
    }

    // 등고선
    List<double> levels;
    if (lossFunction == LossFunction.rosenbrock) {
      levels = [0.1, 1, 10, 100, 500, 1000];
    } else if (lossFunction == LossFunction.rastrigin) {
      levels = [5, 10, 20, 30, 40, 50];
    } else {
      levels = [0.5, 1, 2, 4, 6, 8];
    }

    for (var level in levels) {
      final contourPath = Path();
      bool started = false;

      for (double angle = 0; angle <= 2 * math.pi; angle += 0.05) {
        double r = math.sqrt(level);
        if (lossFunction == LossFunction.rosenbrock) {
          r = math.sqrt(level) / 5;
        }

        final fx = r * math.cos(angle);
        final fy = r * math.sin(angle);
        final px = centerX + fx * scale;
        final py = centerY + fy * scale;

        if (!started) {
          contourPath.moveTo(px, py);
          started = true;
        } else {
          contourPath.lineTo(px, py);
        }
      }
      contourPath.close();

      canvas.drawPath(
        contourPath,
        Paint()
          ..color = AppColors.muted.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // 축
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);

    // 최적점 표시
    final optimumX = centerX;
    final optimumY = centerY;
    canvas.drawCircle(
      Offset(optimumX, optimumY),
      10,
      Paint()..color = Colors.green.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      Offset(optimumX, optimumY),
      8,
      Paint()
        ..color = Colors.green.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(optimumX, optimumY),
      8,
      Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 경로 그리기
    if (path.length > 1) {
      final pathPaint = Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final pathPath = Path();
      for (int i = 0; i < path.length; i++) {
        final px = centerX + path[i].dx * scale;
        final py = centerY + path[i].dy * scale;
        if (i == 0) {
          pathPath.moveTo(px, py);
        } else {
          pathPath.lineTo(px, py);
        }
      }
      canvas.drawPath(pathPath, pathPaint);

      // 경로 점들
      for (int i = 0; i < path.length; i++) {
        final px = centerX + path[i].dx * scale;
        final py = centerY + path[i].dy * scale;
        final alpha = (i / path.length).clamp(0.3, 1.0);
        canvas.drawCircle(
          Offset(px, py),
          3,
          Paint()..color = AppColors.accent.withValues(alpha: alpha),
        );
      }
    }

    // 현재 위치 (글로우 효과)
    final currentX = centerX + x * scale;
    final currentY = centerY + y * scale;

    if (converged) {
      canvas.drawCircle(
        Offset(currentX, currentY),
        16,
        Paint()..color = AppColors.accent2.withValues(alpha: 0.3),
      );
    }

    canvas.drawCircle(
      Offset(currentX, currentY),
      10,
      Paint()..color = converged ? AppColors.accent2 : AppColors.accent,
    );
    canvas.drawCircle(
      Offset(currentX, currentY),
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 라벨
    _drawText(canvas, 'x', Offset(size.width - 20, centerY + 5));
    _drawText(canvas, 'y', Offset(centerX + 5, 10));
    _drawText(canvas, '최적점', Offset(optimumX + 12, optimumY - 5));
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant GradientDescentPainter oldDelegate) => true;
}
