import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class RadiationBudgetScreen extends StatefulWidget {
  const RadiationBudgetScreen({super.key});
  @override
  State<RadiationBudgetScreen> createState() => _RadiationBudgetScreenState();
}

class _RadiationBudgetScreenState extends State<RadiationBudgetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _albedo = 0.3;
  
  double _eqTemp = 255, _absorbed = 240;

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
      _absorbed = 1361 * (1 - _albedo) / 4;
      _eqTemp = math.pow(_absorbed / 5.67e-8, 0.25).toDouble();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _albedo = 0.3;
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
          Text('지구과학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('지구 복사 수지', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '지구 복사 수지',
          formula: 'S(1-α)/4 = εσT⁴',
          formulaDescription: '지구의 에너지 수입과 지출 균형을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _RadiationBudgetScreenPainter(
                time: _time,
                albedo: _albedo,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '알베도 (α)',
                value: _albedo,
                min: 0,
                max: 1,
                step: 0.01,
                defaultValue: 0.3,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _albedo = v),
              ),
              
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
          _V('T_eq', _eqTemp.toStringAsFixed(1) + ' K'),
          _V('흡수', _absorbed.toStringAsFixed(1) + ' W/m²'),
          _V('α', _albedo.toStringAsFixed(2)),
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

class _RadiationBudgetScreenPainter extends CustomPainter {
  final double time;
  final double albedo;

  _RadiationBudgetScreenPainter({
    required this.time,
    required this.albedo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);
    _drawGrid(canvas, size);
    final cx = size.width / 2, cy = size.height / 2;
    final tp = TextPainter(
      text: TextSpan(text: '지구 복사 수지', style: TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold)),
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
  bool shouldRepaint(covariant _RadiationBudgetScreenPainter oldDelegate) => true;
}
