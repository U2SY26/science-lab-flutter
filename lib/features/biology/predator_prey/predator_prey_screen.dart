import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Predator-Prey Dynamics (Lotka-Volterra) Simulation
class PredatorPreyScreen extends ConsumerStatefulWidget {
  const PredatorPreyScreen({super.key});

  @override
  ConsumerState<PredatorPreyScreen> createState() => _PredatorPreyScreenState();
}

class _PredatorPreyScreenState extends ConsumerState<PredatorPreyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Lotka-Volterra parameters
  double _alpha = 1.0; // Prey birth rate
  double _beta = 0.1; // Predation rate
  double _gamma = 1.5; // Predator death rate
  double _delta = 0.075; // Predator reproduction rate

  // Population state
  double _prey = 40.0;
  double _predator = 9.0;
  double _time = 0.0;
  bool _isRunning = false;

  // History for graph
  final List<double> _preyHistory = [];
  final List<double> _predatorHistory = [];
  final List<double> _timeHistory = [];

  // Phase space
  final List<Offset> _phaseHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeHistory();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updatePopulations);
  }

  void _initializeHistory() {
    _preyHistory.clear();
    _predatorHistory.clear();
    _timeHistory.clear();
    _phaseHistory.clear();
    _preyHistory.add(_prey);
    _predatorHistory.add(_predator);
    _timeHistory.add(0);
    _phaseHistory.add(Offset(_prey, _predator));
  }

  void _updatePopulations() {
    if (!_isRunning) return;

    setState(() {
      const dt = 0.02;
      _time += dt;

      // Lotka-Volterra equations
      // dPrey/dt = alpha * Prey - beta * Prey * Predator
      // dPredator/dt = delta * Prey * Predator - gamma * Predator
      final dPrey = (_alpha * _prey - _beta * _prey * _predator) * dt;
      final dPredator = (_delta * _prey * _predator - _gamma * _predator) * dt;

      _prey = math.max(0.1, _prey + dPrey);
      _predator = math.max(0.1, _predator + dPredator);

      // Cap populations to prevent overflow
      _prey = math.min(_prey, 200);
      _predator = math.min(_predator, 200);

      // Record history
      _preyHistory.add(_prey);
      _predatorHistory.add(_predator);
      _timeHistory.add(_time);
      _phaseHistory.add(Offset(_prey, _predator));

      // Limit history size
      if (_preyHistory.length > 500) {
        _preyHistory.removeAt(0);
        _predatorHistory.removeAt(0);
        _timeHistory.removeAt(0);
      }
      if (_phaseHistory.length > 1000) {
        _phaseHistory.removeAt(0);
      }
    });
  }

  void _toggleRunning() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _controller.stop();
      _prey = 40.0;
      _predator = 9.0;
      _time = 0.0;
      _initializeHistory();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);

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
              isKorean ? '생물학' : 'BIOLOGY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '포식자-피식자 역학' : 'Predator-Prey Dynamics',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '생물학' : 'Biology',
          title: isKorean ? '포식자-피식자 역학' : 'Predator-Prey Dynamics',
          formula: 'dx/dt = ax - bxy, dy/dt = dxy - cy',
          formulaDescription: isKorean
              ? 'Lotka-Volterra 방정식: 피식자(x)와 포식자(y)의 개체군 변화를 모델링합니다.'
              : 'Lotka-Volterra equations: Models population changes of prey (x) and predator (y).',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PredatorPreyPainter(
                preyHistory: _preyHistory,
                predatorHistory: _predatorHistory,
                timeHistory: _timeHistory,
                phaseHistory: _phaseHistory,
                currentPrey: _prey,
                currentPredator: _predator,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoItem(
                      label: isKorean ? '피식자 (토끼)' : 'Prey (Rabbits)',
                      value: _prey.toStringAsFixed(1),
                      color: Colors.green,
                    ),
                    _InfoItem(
                      label: isKorean ? '포식자 (여우)' : 'Predator (Foxes)',
                      value: _predator.toStringAsFixed(1),
                      color: Colors.red,
                    ),
                    _InfoItem(
                      label: isKorean ? '시간' : 'Time',
                      value: _time.toStringAsFixed(1),
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? 'a (피식자 번식률)' : 'a (Prey birth rate)',
                  value: _alpha,
                  min: 0.1,
                  max: 2.0,
                  defaultValue: 1.0,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _alpha = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? 'b (포식률)' : 'b (Predation rate)',
                    value: _beta,
                    min: 0.01,
                    max: 0.3,
                    defaultValue: 0.1,
                    formatValue: (v) => v.toStringAsFixed(3),
                    onChanged: (v) => setState(() => _beta = v),
                  ),
                  SimSlider(
                    label: isKorean ? 'c (포식자 사망률)' : 'c (Predator death rate)',
                    value: _gamma,
                    min: 0.5,
                    max: 3.0,
                    defaultValue: 1.5,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _gamma = v),
                  ),
                  SimSlider(
                    label: isKorean ? 'd (포식자 번식률)' : 'd (Predator reproduction)',
                    value: _delta,
                    min: 0.01,
                    max: 0.2,
                    defaultValue: 0.075,
                    formatValue: (v) => v.toStringAsFixed(3),
                    onChanged: (v) => setState(() => _delta = v),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning
                    ? (isKorean ? '일시정지' : 'Pause')
                    : (isKorean ? '시작' : 'Start'),
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleRunning,
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
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PredatorPreyPainter extends CustomPainter {
  final List<double> preyHistory;
  final List<double> predatorHistory;
  final List<double> timeHistory;
  final List<Offset> phaseHistory;
  final double currentPrey;
  final double currentPredator;
  final bool isKorean;

  _PredatorPreyPainter({
    required this.preyHistory,
    required this.predatorHistory,
    required this.timeHistory,
    required this.phaseHistory,
    required this.currentPrey,
    required this.currentPredator,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final halfWidth = size.width / 2 - 10;

    // Draw time series (left half)
    _drawTimeSeries(canvas, Rect.fromLTWH(0, 0, halfWidth, size.height));

    // Draw phase space (right half)
    _drawPhaseSpace(canvas, Rect.fromLTWH(halfWidth + 20, 0, halfWidth, size.height));
  }

  void _drawTimeSeries(Canvas canvas, Rect bounds) {
    final padding = 40.0;
    final graphWidth = bounds.width - padding * 2;
    final graphHeight = bounds.height - padding * 2;

    // Axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(bounds.left + padding, bounds.top + padding),
      Offset(bounds.left + padding, bounds.bottom - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(bounds.left + padding, bounds.bottom - padding),
      Offset(bounds.right - padding, bounds.bottom - padding),
      axisPaint,
    );

    // Labels
    _drawText(canvas, isKorean ? '개체수' : 'Population',
        Offset(bounds.left + 5, bounds.top + padding - 15), AppColors.muted, 10);
    _drawText(canvas, isKorean ? '시간' : 'Time',
        Offset(bounds.right - 40, bounds.bottom - 15), AppColors.muted, 10);

    if (preyHistory.isEmpty) return;

    // Find max values
    final maxPop = math.max(
      preyHistory.reduce(math.max),
      predatorHistory.reduce(math.max),
    );
    final maxTime = timeHistory.isNotEmpty ? timeHistory.last : 1;

    // Draw prey line
    final preyPath = Path();
    for (int i = 0; i < preyHistory.length; i++) {
      final x = bounds.left + padding + (timeHistory[i] / maxTime) * graphWidth;
      final y = bounds.bottom - padding - (preyHistory[i] / maxPop) * graphHeight;
      if (i == 0) {
        preyPath.moveTo(x, y);
      } else {
        preyPath.lineTo(x, y);
      }
    }
    canvas.drawPath(preyPath, Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);

    // Draw predator line
    final predatorPath = Path();
    for (int i = 0; i < predatorHistory.length; i++) {
      final x = bounds.left + padding + (timeHistory[i] / maxTime) * graphWidth;
      final y = bounds.bottom - padding - (predatorHistory[i] / maxPop) * graphHeight;
      if (i == 0) {
        predatorPath.moveTo(x, y);
      } else {
        predatorPath.lineTo(x, y);
      }
    }
    canvas.drawPath(predatorPath, Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);

    // Legend
    canvas.drawLine(
      Offset(bounds.left + padding + 10, bounds.top + 10),
      Offset(bounds.left + padding + 30, bounds.top + 10),
      Paint()..color = Colors.green..strokeWidth = 2,
    );
    _drawText(canvas, isKorean ? '피식자' : 'Prey',
        Offset(bounds.left + padding + 35, bounds.top + 5), Colors.green, 10);

    canvas.drawLine(
      Offset(bounds.left + padding + 80, bounds.top + 10),
      Offset(bounds.left + padding + 100, bounds.top + 10),
      Paint()..color = Colors.red..strokeWidth = 2,
    );
    _drawText(canvas, isKorean ? '포식자' : 'Predator',
        Offset(bounds.left + padding + 105, bounds.top + 5), Colors.red, 10);
  }

  void _drawPhaseSpace(Canvas canvas, Rect bounds) {
    final padding = 40.0;
    final graphWidth = bounds.width - padding * 2;
    final graphHeight = bounds.height - padding * 2;

    // Axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(bounds.left + padding, bounds.bottom - padding),
      Offset(bounds.right - padding, bounds.bottom - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(bounds.left + padding, bounds.top + padding),
      Offset(bounds.left + padding, bounds.bottom - padding),
      axisPaint,
    );

    // Labels
    _drawText(canvas, isKorean ? '위상 공간' : 'Phase Space',
        Offset(bounds.left + padding, bounds.top + 5), AppColors.accent, 11, fontWeight: FontWeight.bold);
    _drawText(canvas, isKorean ? '피식자' : 'Prey',
        Offset(bounds.right - 50, bounds.bottom - 15), AppColors.muted, 10);
    _drawText(canvas, isKorean ? '포식자' : 'Predator',
        Offset(bounds.left + 5, bounds.top + padding + 10), AppColors.muted, 10);

    if (phaseHistory.isEmpty) return;

    // Find max values
    final maxPrey = phaseHistory.map((p) => p.dx).reduce(math.max);
    final maxPredator = phaseHistory.map((p) => p.dy).reduce(math.max);

    // Draw phase trajectory
    final phasePath = Path();
    for (int i = 0; i < phaseHistory.length; i++) {
      final x = bounds.left + padding + (phaseHistory[i].dx / maxPrey) * graphWidth * 0.9;
      final y = bounds.bottom - padding - (phaseHistory[i].dy / maxPredator) * graphHeight * 0.9;

      if (i == 0) {
        phasePath.moveTo(x, y);
      } else {
        phasePath.lineTo(x, y);
      }
    }

    // Draw with gradient
    for (int i = 1; i < phaseHistory.length; i++) {
      final t = i / phaseHistory.length;
      final x1 = bounds.left + padding + (phaseHistory[i - 1].dx / maxPrey) * graphWidth * 0.9;
      final y1 = bounds.bottom - padding - (phaseHistory[i - 1].dy / maxPredator) * graphHeight * 0.9;
      final x2 = bounds.left + padding + (phaseHistory[i].dx / maxPrey) * graphWidth * 0.9;
      final y2 = bounds.bottom - padding - (phaseHistory[i].dy / maxPredator) * graphHeight * 0.9;

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = Color.lerp(AppColors.accent.withValues(alpha: 0.3), AppColors.accent, t)!
          ..strokeWidth = 1 + t,
      );
    }

    // Current position
    final currentX = bounds.left + padding + (currentPrey / maxPrey) * graphWidth * 0.9;
    final currentY = bounds.bottom - padding - (currentPredator / maxPredator) * graphHeight * 0.9;

    canvas.drawCircle(
      Offset(currentX, currentY),
      8,
      Paint()..color = AppColors.accent.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      Offset(currentX, currentY),
      5,
      Paint()..color = AppColors.accent,
    );
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize,
      {FontWeight fontWeight = FontWeight.normal}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _PredatorPreyPainter oldDelegate) => true;
}
