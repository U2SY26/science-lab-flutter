import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class StrangeAttractorExplorerScreen extends StatefulWidget {
  const StrangeAttractorExplorerScreen({super.key});
  @override
  State<StrangeAttractorExplorerScreen> createState() => _StrangeAttractorExplorerScreenState();
}

class _StrangeAttractorExplorerScreenState extends State<StrangeAttractorExplorerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _attractorType = 0;
  double _paramA = 10;
  double _lyapunov = 0.9;

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
      _lyapunov = 0.5 + _paramA * 0.05 + math.sin(_time) * 0.1;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _attractorType = 0.0; _paramA = 10.0;
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
          Text('카오스 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('이상 끌개 탐색기', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스 시뮬레이션',
          title: '이상 끌개 탐색기',
          formula: 'dx/dt = f(x,y,z)',
          formulaDescription: '다양한 이상 끌개를 탐색하고 비교합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _StrangeAttractorExplorerScreenPainter(
                time: _time,
                attractorType: _attractorType,
                paramA: _paramA,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '끌개 유형',
                value: _attractorType,
                min: 0,
                max: 3,
                step: 1,
                defaultValue: 0,
                formatValue: (v) => ['Lorenz','Rossler','Chen','Lu'][v.toInt()],
                onChanged: (v) => setState(() => _attractorType = v),
              ),
              advancedControls: [
            SimSlider(
                label: '매개변수 a',
                value: _paramA,
                min: 1,
                max: 50,
                step: 0.5,
                defaultValue: 10,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _paramA = v),
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
          _V('유형', ['Lorenz','Rossler','Chen','Lu'][_attractorType.toInt()]),
          _V('λ', _lyapunov.toStringAsFixed(3)),
          _V('a', _paramA.toStringAsFixed(1)),
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

class _StrangeAttractorExplorerScreenPainter extends CustomPainter {
  final double time;
  final double attractorType;
  final double paramA;

  _StrangeAttractorExplorerScreenPainter({
    required this.time,
    required this.attractorType,
    required this.paramA,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);
    _drawGrid(canvas, size);
    final cx = size.width / 2, cy = size.height / 2;
    final tp = TextPainter(
      text: TextSpan(text: '이상 끌개 탐색기', style: TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, 15));
    final paint = Paint()..color = AppColors.accent..strokeWidth = 2..style = PaintingStyle.stroke;
    final fillPaint = Paint()..color = AppColors.accent.withValues(alpha: 0.3);
    final radius = 40 + 20 * math.sin(time * 2);
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);
    canvas.drawCircle(Offset(cx, cy), radius, paint);
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
  bool shouldRepaint(covariant _StrangeAttractorExplorerScreenPainter oldDelegate) => true;
}
