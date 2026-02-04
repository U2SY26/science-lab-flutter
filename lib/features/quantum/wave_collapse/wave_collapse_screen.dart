import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Wave Function Collapse Simulation
/// 파동 함수 붕괴 시뮬레이션
class WaveCollapseScreen extends StatefulWidget {
  const WaveCollapseScreen({super.key});

  @override
  State<WaveCollapseScreen> createState() => _WaveCollapseScreenState();
}

class _WaveCollapseScreenState extends State<WaveCollapseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const double _defaultSpread = 100.0;

  double spread = _defaultSpread;
  bool isRunning = true;
  bool isCollapsed = false;
  double? collapsedPosition;

  double time = 0;
  bool isKorean = true;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    _controller.repeat();
  }

  void _updatePhysics() {
    if (!isRunning) return;
    setState(() {
      time += 0.03;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      spread = _defaultSpread;
      isCollapsed = false;
      collapsedPosition = null;
    });
  }

  void _measure() {
    HapticFeedback.heavyImpact();
    setState(() {
      isCollapsed = true;
      // Sample from Gaussian distribution
      final u1 = _random.nextDouble();
      final u2 = _random.nextDouble();
      final gaussian = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
      collapsedPosition = 0.5 + gaussian * spread / 400;
      collapsedPosition = collapsedPosition!.clamp(0.1, 0.9);
    });

    // Slowly spread again
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isCollapsed = false;
          collapsedPosition = null;
        });
      }
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
              isKorean ? '양자역학 시뮬레이션' : 'QUANTUM MECHANICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '파동 함수 붕괴' : 'Wave Function Collapse',
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
            onPressed: () => setState(() => isKorean = !isKorean),
            tooltip: isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '양자역학 시뮬레이션' : 'QUANTUM MECHANICS',
          title: isKorean ? '파동 함수 붕괴' : 'Wave Function Collapse',
          formula: '|ψ⟩ → |xₘ⟩',
          formulaDescription: isKorean
              ? '측정 전 입자는 모든 가능한 위치의 중첩 상태에 있습니다. '
                  '측정하면 파동 함수가 즉시 하나의 고유 상태로 붕괴합니다.'
              : 'Before measurement, a particle exists in a superposition of all possible positions. '
                  'Upon measurement, the wave function instantly collapses to a single eigenstate.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: WaveCollapsePainter(
                time: time,
                spread: spread,
                isCollapsed: isCollapsed,
                collapsedPosition: collapsedPosition,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '파동 함수 퍼짐' : 'Wave Function Spread',
                  value: spread,
                  min: 30,
                  max: 150,
                  defaultValue: _defaultSpread,
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) => setState(() => spread = v),
                ),
                advancedControls: const [],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                spread: spread,
                isCollapsed: isCollapsed,
                collapsedPosition: collapsedPosition,
                isKorean: isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning
                    ? (isKorean ? '정지' : 'Pause')
                    : (isKorean ? '재생' : 'Play'),
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => isRunning = !isRunning);
                },
              ),
              SimButton(
                label: isKorean ? '측정' : 'Measure',
                icon: Icons.visibility,
                onPressed: isCollapsed ? null : _measure,
              ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
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

class _PhysicsInfo extends StatelessWidget {
  final double spread;
  final bool isCollapsed;
  final double? collapsedPosition;
  final bool isKorean;

  const _PhysicsInfo({
    required this.spread,
    required this.isCollapsed,
    required this.collapsedPosition,
    required this.isKorean,
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
      child: Row(
        children: [
          _InfoItem(
            label: isKorean ? '상태' : 'State',
            value: isCollapsed
                ? (isKorean ? '붕괴됨' : 'Collapsed')
                : (isKorean ? '중첩' : 'Superposition'),
          ),
          _InfoItem(
            label: 'Δx',
            value: isCollapsed ? '≈0' : spread.toStringAsFixed(0),
          ),
          _InfoItem(
            label: isKorean ? '측정 위치' : 'Position',
            value: collapsedPosition != null
                ? '${(collapsedPosition! * 100).toInt()}%'
                : '-',
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class WaveCollapsePainter extends CustomPainter {
  final double time;
  final double spread;
  final bool isCollapsed;
  final double? collapsedPosition;

  WaveCollapsePainter({
    required this.time,
    required this.spread,
    required this.isCollapsed,
    required this.collapsedPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawAxis(canvas, size);

    if (isCollapsed && collapsedPosition != null) {
      _drawCollapsedState(canvas, size);
    } else {
      _drawSuperpositionState(canvas, size);
    }

    _drawLabels(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawAxis(Canvas canvas, Size size) {
    final baseY = size.height * 0.7;
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;

    // X axis
    canvas.drawLine(
      Offset(30, baseY),
      Offset(size.width - 30, baseY),
      axisPaint,
    );

    // Arrow
    canvas.drawLine(
      Offset(size.width - 30, baseY),
      Offset(size.width - 40, baseY - 5),
      axisPaint,
    );
    canvas.drawLine(
      Offset(size.width - 30, baseY),
      Offset(size.width - 40, baseY + 5),
      axisPaint,
    );
  }

  void _drawSuperpositionState(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final baseY = size.height * 0.7;
    final amplitude = 120.0;
    final sigma = spread;

    // Draw wave function ψ(x)
    final wavePath = Path();
    bool started = false;

    for (double x = 50; x < size.width - 50; x += 2) {
      final dx = x - centerX;
      // Gaussian wave packet with oscillation
      final envelope = math.exp(-dx * dx / (2 * sigma * sigma));
      final oscillation = math.cos(dx * 0.1 - time * 3);
      final psi = envelope * oscillation;

      final screenY = baseY - psi * amplitude * 0.7;

      if (!started) {
        wavePath.moveTo(x, screenY);
        started = true;
      } else {
        wavePath.lineTo(x, screenY);
      }
    }

    // Glow effect
    canvas.drawPath(
      wavePath,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );

    // Main wave
    canvas.drawPath(
      wavePath,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Draw probability density |ψ|²
    final probPath = Path();
    probPath.moveTo(50, baseY);

    for (double x = 50; x < size.width - 50; x += 2) {
      final dx = x - centerX;
      final prob = math.exp(-dx * dx / (sigma * sigma));
      final screenY = baseY - prob * amplitude * 0.8;
      probPath.lineTo(x, screenY);
    }

    probPath.lineTo(size.width - 50, baseY);
    probPath.close();

    // Fill probability
    canvas.drawPath(
      probPath,
      Paint()..color = const Color(0xFF805AD5).withValues(alpha: 0.2),
    );

    // Probability outline
    final probOutline = Path();
    probOutline.moveTo(50, baseY);
    for (double x = 50; x < size.width - 50; x += 2) {
      final dx = x - centerX;
      final prob = math.exp(-dx * dx / (sigma * sigma));
      final screenY = baseY - prob * amplitude * 0.8;
      probOutline.lineTo(x, screenY);
    }

    canvas.drawPath(
      probOutline,
      Paint()
        ..color = const Color(0xFF805AD5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // Particle cloud showing uncertainty
    final random = math.Random(42);
    for (int i = 0; i < 50; i++) {
      final dx = (random.nextDouble() - 0.5) * spread * 3;
      final prob = math.exp(-dx * dx / (sigma * sigma));
      if (random.nextDouble() < prob) {
        final x = centerX + dx;
        final y = baseY - 20 + (random.nextDouble() - 0.5) * 20;

        canvas.drawCircle(
          Offset(x, y),
          3 + random.nextDouble() * 2,
          Paint()..color = AppColors.accent.withValues(alpha: 0.3 + 0.3 * prob),
        );
      }
    }
  }

  void _drawCollapsedState(Canvas canvas, Size size) {
    final posX = 50 + collapsedPosition! * (size.width - 100);
    final baseY = size.height * 0.7;

    // Delta function spike
    final deltaPath = Path();
    deltaPath.moveTo(50, baseY);
    deltaPath.lineTo(posX - 3, baseY);
    deltaPath.lineTo(posX, baseY - 180);
    deltaPath.lineTo(posX + 3, baseY);
    deltaPath.lineTo(size.width - 50, baseY);

    // Glow
    canvas.drawPath(
      deltaPath,
      Paint()
        ..color = const Color(0xFF48BB78).withValues(alpha: 0.4)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke,
    );

    // Main spike
    canvas.drawPath(
      deltaPath,
      Paint()
        ..color = const Color(0xFF48BB78)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // Collapsed particle
    canvas.drawCircle(
      Offset(posX, baseY - 20),
      15,
      Paint()..color = const Color(0xFF48BB78),
    );
    canvas.drawCircle(
      Offset(posX, baseY - 20),
      25,
      Paint()..color = const Color(0xFF48BB78).withValues(alpha: 0.3),
    );

    // "Measured!" flash
    final flashGradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: 0.5),
        Colors.white.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromCircle(center: Offset(posX, baseY - 20), radius: 80));

    canvas.drawCircle(
      Offset(posX, baseY - 20),
      80,
      Paint()..shader = flashGradient,
    );

    // Position marker
    canvas.drawLine(
      Offset(posX, baseY - 5),
      Offset(posX, baseY + 15),
      Paint()
        ..color = const Color(0xFF48BB78)
        ..strokeWidth = 2,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'xₘ',
        style: TextStyle(
          color: const Color(0xFF48BB78),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(posX - 8, baseY + 18));
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Wave function label
    textPainter.text = TextSpan(
      text: isCollapsed ? 'δ(x - xₘ)' : 'ψ(x)',
      style: TextStyle(
        color: isCollapsed ? const Color(0xFF48BB78) : AppColors.accent,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(50, size.height * 0.1));

    // Probability label
    if (!isCollapsed) {
      textPainter.text = TextSpan(
        text: '|ψ(x)|²',
        style: TextStyle(
          color: const Color(0xFF805AD5),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(50, size.height * 0.18));
    }

    // X axis label
    textPainter.text = TextSpan(
      text: 'x (position)',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.75));

    // State description
    final stateText = isCollapsed
        ? 'Collapsed to eigenstate |xₘ⟩'
        : 'Superposition of all positions';

    textPainter.text = TextSpan(
      text: stateText,
      style: TextStyle(
        color: isCollapsed ? const Color(0xFF48BB78) : AppColors.muted,
        fontSize: 11,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.9));
  }

  @override
  bool shouldRepaint(covariant WaveCollapsePainter oldDelegate) =>
      time != oldDelegate.time ||
      spread != oldDelegate.spread ||
      isCollapsed != oldDelegate.isCollapsed ||
      collapsedPosition != oldDelegate.collapsedPosition;
}
