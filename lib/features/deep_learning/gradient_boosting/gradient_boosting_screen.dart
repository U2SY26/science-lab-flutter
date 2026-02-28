import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class GradientBoostingScreen extends StatefulWidget {
  const GradientBoostingScreen({super.key});
  @override
  State<GradientBoostingScreen> createState() => _GradientBoostingScreenState();
}

class _GradientBoostingScreenState extends State<GradientBoostingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _numRounds = 5.0;
  double _learningRate = 0.3;
  double _trainError = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;
    setState(() {
      _time += 0.016;
      _trainError = 1.0;
      for (int i = 0; i < _numRounds.toInt(); i++) {
        _trainError *= (1 - _learningRate * 0.5);
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _numRounds = 5.0;
      _learningRate = 0.3;
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI/ML 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('그래디언트 부스팅', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '그래디언트 부스팅',
          formula: 'F_m(x) = F_{m-1}(x) + ν·h_m(x)',
          formulaDescription: '잔차를 순차적으로 줄여가며 강한 학습기를 만듭니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GradientBoostingScreenPainter(
                time: _time,
                numRounds: _numRounds,
                learningRate: _learningRate,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '라운드 수',
                value: _numRounds,
                min: 1.0,
                max: 20.0,
                defaultValue: 5.0,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => _numRounds = v),
              ),
              advancedControls: [
            SimSlider(
                label: '학습률 (ν)',
                value: _learningRate,
                min: 0.01,
                max: 1.0,
                step: 0.01,
                defaultValue: 0.3,
                formatValue: (v) => '${v.toStringAsFixed(2)}',
                onChanged: (v) => setState(() => _learningRate = v),
              ),
              ],
            ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(children: [
          _V('훈련 오차', '${(_trainError * 100).toStringAsFixed(1)}%'),
          _V('라운드', '${_numRounds.toInt()}'),
          _V('학습률', '${_learningRate.toStringAsFixed(2)}'),
                ]),
              ),
            ],
          ),
          buttons: SimButtonGroup(expanded: true, buttons: [
            SimButton(
              label: _isRunning ? '정지' : '재생',
              icon: _isRunning ? Icons.pause : Icons.play_arrow,
              isPrimary: true,
              onPressed: () { HapticFeedback.selectionClick(); setState(() => _isRunning = !_isRunning); },
            ),
            SimButton(label: '리셋', icon: Icons.refresh, onPressed: _reset),
          ]),
        ),
      ),
    );
  }
}

class _V extends StatelessWidget {
  final String label, value;
  const _V(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
  ]));
}

class _GradientBoostingScreenPainter extends CustomPainter {
  final double time;
  final double numRounds;
  final double learningRate;

  _GradientBoostingScreenPainter({
    required this.time,
    required this.numRounds,
    required this.learningRate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);
    _drawGrid(canvas, size);
    // Simulation-specific drawing
    final cx = size.width / 2, cy = size.height / 2;
    final labelStyle = TextStyle(color: AppColors.muted, fontSize: 11);
    final tp = TextPainter(
      text: TextSpan(text: '그래디언트 부스팅', style: TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, 15));
    // Animated visualization
    final paint = Paint()..color = AppColors.accent..strokeWidth = 2..style = PaintingStyle.stroke;
    final fillPaint = Paint()..color = AppColors.accent.withValues(alpha: 0.3);
    final radius = 40 + 20 * math.sin(time * 2);
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);
    canvas.drawCircle(Offset(cx, cy), radius, paint);
    // Animated elements
    for (int i = 0; i < 5; i++) {
      final angle = time + i * math.pi * 2 / 5;
      final x = cx + (radius + 30) * math.cos(angle);
      final y = cy + (radius + 30) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = AppColors.accent2.withValues(alpha: 0.7));
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final p = Paint()..color = AppColors.simGrid.withValues(alpha: 0.3)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 30) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 30) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }

  @override
  bool shouldRepaint(covariant _GradientBoostingScreenPainter oldDelegate) => true;
}
