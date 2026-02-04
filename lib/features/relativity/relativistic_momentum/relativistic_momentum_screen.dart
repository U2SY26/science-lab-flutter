import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Relativistic Momentum Simulation
class RelativisticMomentumScreen extends StatefulWidget {
  const RelativisticMomentumScreen({super.key});

  @override
  State<RelativisticMomentumScreen> createState() => _RelativisticMomentumScreenState();
}

class _RelativisticMomentumScreenState extends State<RelativisticMomentumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _velocity = 0.5; // v/c
  double _restMass = 1.0; // kg (normalized)
  bool _isAnimating = false;
  bool _showClassical = true;
  bool _isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(_updateAnimation);
  }

  void _updateAnimation() {
    if (!_isAnimating) return;
    setState(() {
      _velocity = _controller.value * 0.99;
    });
  }

  void _startAnimation() {
    _controller.forward(from: 0);
    setState(() => _isAnimating = true);
  }

  void _stopAnimation() {
    _controller.stop();
    setState(() => _isAnimating = false);
  }

  double get _gamma => 1 / math.sqrt(1 - _velocity * _velocity);
  double get _relativisticMomentum => _gamma * _restMass * _velocity;
  double get _classicalMomentum => _restMass * _velocity;

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.reset();
    setState(() {
      _velocity = 0.5;
      _isAnimating = false;
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
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '상대론적 운동량' : 'Relativistic Momentum',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => _isKorean = !_isKorean),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
          title: _isKorean ? '상대론적 운동량' : 'Relativistic Momentum',
          formula: 'p = γmv = mv/√(1-v²/c²)',
          formulaDescription: _isKorean
              ? '상대론적 운동량은 속도가 빛의 속도에 가까워질수록 무한대로 발산합니다. 이것이 질량이 있는 물체가 빛의 속도에 도달할 수 없는 이유입니다.'
              : 'Relativistic momentum diverges to infinity as velocity approaches light speed. This is why massive objects cannot reach the speed of light.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: RelativisticMomentumPainter(
                velocity: _velocity,
                restMass: _restMass,
                gamma: _gamma,
                relativisticMomentum: _relativisticMomentum,
                classicalMomentum: _classicalMomentum,
                showClassical: _showClassical,
                isKorean: _isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '속도 (v/c)' : 'Velocity (v/c)',
                  value: _velocity,
                  min: 0,
                  max: 0.99,
                  defaultValue: 0.5,
                  formatValue: (v) => '${(v * 100).toStringAsFixed(1)}% c',
                  onChanged: (v) => setState(() => _velocity = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '정지 질량' : 'Rest Mass',
                    value: _restMass,
                    min: 0.5,
                    max: 2.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                    onChanged: (v) => setState(() => _restMass = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '고전 운동량 비교' : 'Show Classical',
                    value: _showClassical,
                    onChanged: (v) => setState(() => _showClassical = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                velocity: _velocity,
                gamma: _gamma,
                relativisticMomentum: _relativisticMomentum,
                classicalMomentum: _classicalMomentum,
                isKorean: _isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isAnimating
                    ? (_isKorean ? '정지' : 'Stop')
                    : (_isKorean ? '가속' : 'Accelerate'),
                icon: _isAnimating ? Icons.pause : Icons.fast_forward,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (_isAnimating) {
                    _stopAnimation();
                  } else {
                    _startAnimation();
                  }
                },
              ),
              SimButton(
                label: _isKorean ? '리셋' : 'Reset',
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

class _InfoCard extends StatelessWidget {
  final double velocity;
  final double gamma;
  final double relativisticMomentum;
  final double classicalMomentum;
  final bool isKorean;

  const _InfoCard({
    required this.velocity,
    required this.gamma,
    required this.relativisticMomentum,
    required this.classicalMomentum,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = relativisticMomentum / (classicalMomentum == 0 ? 1 : classicalMomentum);

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
          Row(
            children: [
              Icon(Icons.speed, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '상대론적 운동량' : 'Relativistic p',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${relativisticMomentum.toStringAsFixed(3)} kg⋅c',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.compare_arrows, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                isKorean ? '고전 운동량' : 'Classical p',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${classicalMomentum.toStringAsFixed(3)} kg⋅c',
                style: TextStyle(color: AppColors.muted, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.trending_up, size: 14, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                isKorean ? '상대론적 증가율' : 'Relativistic Factor',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${ratio.toStringAsFixed(2)}x',
                style: const TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RelativisticMomentumPainter extends CustomPainter {
  final double velocity;
  final double restMass;
  final double gamma;
  final double relativisticMomentum;
  final double classicalMomentum;
  final bool showClassical;
  final bool isKorean;

  RelativisticMomentumPainter({
    required this.velocity,
    required this.restMass,
    required this.gamma,
    required this.relativisticMomentum,
    required this.classicalMomentum,
    required this.showClassical,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final left = 60.0;
    final right = size.width - 30;
    final top = 40.0;
    final bottom = size.height - 50;
    final graphWidth = right - left;
    final graphHeight = bottom - top;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0A0A1A),
    );

    // Draw axes
    _drawAxes(canvas, left, right, top, bottom);

    // Draw classical momentum curve (linear)
    if (showClassical) {
      _drawClassicalCurve(canvas, left, graphWidth, top, graphHeight);
    }

    // Draw relativistic momentum curve
    _drawRelativisticCurve(canvas, left, graphWidth, top, graphHeight);

    // Draw current point
    _drawCurrentPoint(canvas, left, graphWidth, top, graphHeight);

    // Draw particle representation
    _drawParticle(canvas, size);

    // Labels
    _drawLabels(canvas, size, left, right, top, bottom);
  }

  void _drawAxes(Canvas canvas, double left, double right, double top, double bottom) {
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // X axis
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), axisPaint);

    // Y axis
    canvas.drawLine(Offset(left, top), Offset(left, bottom), axisPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;

    for (double v = 0.2; v < 1; v += 0.2) {
      final x = left + v * (right - left);
      canvas.drawLine(Offset(x, top), Offset(x, bottom), gridPaint);
    }

    for (double p = 0.25; p <= 1; p += 0.25) {
      final y = bottom - p * (bottom - top);
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }
  }

  void _drawClassicalCurve(Canvas canvas, double left, double width, double top, double height) {
    final path = Path();
    bool first = true;

    for (double v = 0; v <= 0.99; v += 0.01) {
      final x = left + v * width;
      final p = restMass * v;
      final y = top + height - (p / 5) * height; // Scale to fit

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.grey.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawRelativisticCurve(Canvas canvas, double left, double width, double top, double height) {
    final path = Path();
    bool first = true;

    for (double v = 0; v <= 0.99; v += 0.01) {
      final x = left + v * width;
      final g = 1 / math.sqrt(1 - v * v);
      final p = g * restMass * v;
      final y = top + height - (p / 5).clamp(0, 1) * height;

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _drawCurrentPoint(Canvas canvas, double left, double width, double top, double height) {
    final x = left + velocity * width;
    final yRelativistic = top + height - (relativisticMomentum / 5).clamp(0, 1) * height;
    final yClassical = top + height - (classicalMomentum / 5).clamp(0, 1) * height;

    // Vertical line at current velocity
    canvas.drawLine(
      Offset(x, top),
      Offset(x, top + height),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // Classical point
    if (showClassical) {
      canvas.drawCircle(
        Offset(x, yClassical),
        6,
        Paint()..color = Colors.grey,
      );
    }

    // Relativistic point
    canvas.drawCircle(
      Offset(x, yRelativistic),
      8,
      Paint()..color = AppColors.accent,
    );
    canvas.drawCircle(
      Offset(x, yRelativistic),
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Difference indicator
    if (showClassical && (yClassical - yRelativistic).abs() > 10) {
      canvas.drawLine(
        Offset(x + 15, yClassical),
        Offset(x + 15, yRelativistic),
        Paint()
          ..color = Colors.orange
          ..strokeWidth = 2,
      );
    }
  }

  void _drawParticle(Canvas canvas, Size size) {
    final particleX = size.width * 0.8;
    final particleY = size.height * 0.3;

    // Draw contracted particle (length contraction visualization)
    final originalWidth = 40.0;
    final contractedWidth = originalWidth / gamma;

    // Original size (ghost)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(particleX, particleY), width: originalWidth, height: 25),
        const Radius.circular(5),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Contracted size
    final particleGradient = LinearGradient(
      colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.5)],
    ).createShader(Rect.fromCenter(center: Offset(particleX, particleY), width: contractedWidth, height: 25));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(particleX, particleY), width: contractedWidth, height: 25),
        const Radius.circular(5),
      ),
      Paint()..shader = particleGradient,
    );

    // Velocity arrow
    final arrowLength = velocity * 50;
    canvas.drawLine(
      Offset(particleX + contractedWidth / 2 + 5, particleY),
      Offset(particleX + contractedWidth / 2 + 5 + arrowLength, particleY),
      Paint()
        ..color = const Color(0xFF00FF88)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Arrow head
    if (arrowLength > 5) {
      final arrowX = particleX + contractedWidth / 2 + 5 + arrowLength;
      canvas.drawLine(
        Offset(arrowX, particleY),
        Offset(arrowX - 8, particleY - 5),
        Paint()
          ..color = const Color(0xFF00FF88)
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(arrowX, particleY),
        Offset(arrowX - 8, particleY + 5),
        Paint()
          ..color = const Color(0xFF00FF88)
          ..strokeWidth = 2,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size, double left, double right, double top, double bottom) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // X axis label
    textPainter.text = TextSpan(
      text: isKorean ? '속도 v/c' : 'Velocity v/c',
      style: const TextStyle(color: Colors.white70, fontSize: 11),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((left + right) / 2 - textPainter.width / 2, bottom + 25));

    // Y axis label
    canvas.save();
    canvas.translate(20, (top + bottom) / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.text = TextSpan(
      text: isKorean ? '운동량 p' : 'Momentum p',
      style: const TextStyle(color: Colors.white70, fontSize: 11),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
    canvas.restore();

    // Velocity markers
    for (double v = 0; v <= 1; v += 0.2) {
      final x = left + v * (right - left);
      textPainter.text = TextSpan(
        text: v.toStringAsFixed(1),
        style: const TextStyle(color: Colors.white54, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, bottom + 5));
    }

    // Light speed asymptote label
    textPainter.text = TextSpan(
      text: 'c',
      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(right + 5, bottom - 5));

    // Legend
    textPainter.text = TextSpan(
      text: isKorean ? '파랑: 상대론적, 회색: 고전' : 'Blue: Relativistic, Grey: Classical',
      style: const TextStyle(color: Colors.white54, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height - 15));

    // Gamma value
    textPainter.text = TextSpan(
      text: 'γ = ${gamma.toStringAsFixed(2)}',
      style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 10, 10));
  }

  @override
  bool shouldRepaint(covariant RelativisticMomentumPainter oldDelegate) {
    return velocity != oldDelegate.velocity ||
        restMass != oldDelegate.restMass ||
        showClassical != oldDelegate.showClassical;
  }
}
