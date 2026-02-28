import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CalorimetryScreen extends StatefulWidget {
  const CalorimetryScreen({super.key});
  @override
  State<CalorimetryScreen> createState() => _CalorimetryScreenState();
}

class _CalorimetryScreenState extends State<CalorimetryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _sampleMass = 100;
  double _deltaTemp = 10;
  double _heatQ = 0;

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
      _heatQ = _sampleMass * 4.184 * _deltaTemp;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _sampleMass = 100; _deltaTemp = 10;
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
          Text('화학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('열량 측정', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '열량 측정',
          formula: 'q = mcΔT',
          formulaDescription: '열량계를 이용하여 열 전달을 측정합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CalorimetryScreenPainter(
                time: _time,
                sampleMass: _sampleMass,
                deltaTemp: _deltaTemp,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '시료 질량 (g)',
                value: _sampleMass,
                min: 10,
                max: 500,
                step: 10,
                defaultValue: 100,
                formatValue: (v) => '${v.toStringAsFixed(0)} g',
                onChanged: (v) => setState(() => _sampleMass = v),
              ),
              advancedControls: [
            SimSlider(
                label: '온도 변화 ΔT (°C)',
                value: _deltaTemp,
                min: 1,
                max: 50,
                step: 1,
                defaultValue: 10,
                formatValue: (v) => '${v.toStringAsFixed(0)} °C',
                onChanged: (v) => setState(() => _deltaTemp = v),
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
          _V('q (열량)', '${(_heatQ / 1000).toStringAsFixed(2)} kJ'),
          _V('질량', '${_sampleMass.toStringAsFixed(0)} g'),
          _V('ΔT', '${_deltaTemp.toStringAsFixed(0)} °C'),
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

class _CalorimetryScreenPainter extends CustomPainter {
  final double time;
  final double sampleMass;
  final double deltaTemp;

  _CalorimetryScreenPainter({
    required this.time,
    required this.sampleMass,
    required this.deltaTemp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;

    // Layout: calorimeter cross-section (left 48%) | T-t graph (right 52%)
    final calW = w * 0.46;
    final graphX = calW + 10;
    final graphW = w - graphX - 8;

    // Heat progress (0→1 based on time, capped)
    final progress = (time / 8.0).clamp(0.0, 1.0);
    final currentDT = deltaTemp * progress;
    final heatIntensity = progress;

    // ── Calorimeter cross-section ─────────────────────────────────────────
    final calCX = calW / 2;
    final calCY = h * 0.46;

    // Outer insulation ring
    canvas.drawCircle(Offset(calCX, calCY), 72,
        Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(calCX, calCY), 72,
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Water layer (middle ring) — color shifts with temperature
    final waterColor = Color.lerp(
      const Color(0xFF0A3060), const Color(0xFF4A2000), heatIntensity)!;
    canvas.drawCircle(Offset(calCX, calCY), 56,
        Paint()..color = waterColor..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(calCX, calCY), 56,
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)
          ..strokeWidth = 1.0..style = PaintingStyle.stroke);

    // Inner vessel (steel)
    canvas.drawCircle(Offset(calCX, calCY), 36,
        Paint()..color = const Color(0xFF0D2030)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(calCX, calCY), 36,
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.2..style = PaintingStyle.stroke);

    // Combustion chamber (core) — glows red-orange with heat
    final coreColor = Color.lerp(
      const Color(0xFF0D2030), const Color(0xFFFF4400), heatIntensity)!;
    canvas.drawCircle(Offset(calCX, calCY), 20,
        Paint()..color = coreColor..style = PaintingStyle.fill);
    if (heatIntensity > 0.05) {
      canvas.drawCircle(Offset(calCX, calCY), 20,
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: heatIntensity * 0.8)
            ..strokeWidth = 2.0..style = PaintingStyle.stroke);
    }

    // Heat flow arrows (outward from core, animated)
    final arrowCount = 6;
    for (int i = 0; i < arrowCount; i++) {
      final angle = i * math.pi * 2 / arrowCount + time * 0.5;
      final innerR = 22.0;
      final outerR = 50.0 + heatIntensity * 4;
      final x1 = calCX + innerR * math.cos(angle);
      final y1 = calCY + innerR * math.sin(angle);
      final x2 = calCX + outerR * math.cos(angle);
      final y2 = calCY + outerR * math.sin(angle);
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: heatIntensity * 0.6)
          ..strokeWidth = 1.5,
      );
    }

    // Labels on cross-section
    void calLabel(String t, double x, double y, Color c, {double fs = 7.5}) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(color: c, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
    calLabel('연소실', calCX, calCY, const Color(0xFFFF6B35));
    calLabel('물 (${sampleMass.toStringAsFixed(0)} g)', calCX, calCY - 44, const Color(0xFF00D4FF));
    calLabel('단열재', calCX, calCY - 64, const Color(0xFF5A8A9A));
    calLabel('봄브 열량계', calCX, h * 0.03, const Color(0xFF5A8A9A), fs: 9);
    calLabel('ΔT = ${currentDT.toStringAsFixed(1)} °C', calCX, h * 0.78, const Color(0xFFFF6B35), fs: 10);
    calLabel('q = ${(sampleMass * 4.184 * currentDT / 1000).toStringAsFixed(2)} kJ',
        calCX, h * 0.88, const Color(0xFF64FF8C), fs: 9);

    // ── Temperature-time graph ────────────────────────────────────────────
    final gLeft = graphX, gRight = graphX + graphW - 6;
    final gTop = 18.0, gBottom = h - 28.0;
    final gH = gBottom - gTop;
    final gW = gRight - gLeft;

    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0;
    canvas.drawLine(Offset(gLeft, gTop), Offset(gLeft, gBottom), axisPaint);
    canvas.drawLine(Offset(gLeft, gBottom), Offset(gRight, gBottom), axisPaint);

    // Grid
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.4;
    for (int gi = 1; gi <= 4; gi++) {
      final gy = gTop + gH * gi / 4;
      canvas.drawLine(Offset(gLeft, gy), Offset(gRight, gy), gridP);
    }

    void gLabel(String t, double x, double y, Color c, {double fs = 7.5}) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(color: c, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }
    gLabel('T (°C)', gLeft + gW / 2, gTop - 4, const Color(0xFF5A8A9A));
    gLabel('시간 (s)', gLeft + gW / 2, gBottom + 14, const Color(0xFF5A8A9A));

    // T-t curve: rises then flattens (sigmoid shape)
    final tPath = Path();
    for (int px = 0; px <= gW.toInt(); px++) {
      final tFrac = px / gW; // 0..1 = simulation time 0..8s
      // Sigmoid rise
      final rise = 1.0 / (1.0 + math.exp(-10 * (tFrac - 0.3)));
      // Only show up to current progress
      final visRise = (tFrac <= progress) ? rise : (progress > 0 ? 1.0 / (1.0 + math.exp(-10 * (progress - 0.3))) : 0.0);
      final tNorm = visRise * deltaTemp / (deltaTemp + 5); // normalize
      final py = gBottom - tNorm * gH * 0.85;
      if (px == 0) { tPath.moveTo(gLeft, py); }
      else { tPath.lineTo(gLeft + px, py); }
    }
    canvas.drawPath(tPath,
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // Fill under curve
    final fillPath = Path()..addPath(tPath, Offset.zero);
    fillPath.lineTo(gRight, gBottom);
    fillPath.lineTo(gLeft, gBottom);
    fillPath.close();
    canvas.drawPath(fillPath,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.1)..style = PaintingStyle.fill);

    // ΔT annotation
    final riseEnd = gBottom - (deltaTemp / (deltaTemp + 5)) * gH * 0.85;
    canvas.drawLine(
      Offset(gRight - 12, gBottom),
      Offset(gRight - 12, riseEnd),
      Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.7)
        ..strokeWidth = 1.0..style = PaintingStyle.stroke,
    );
    gLabel('ΔT', gRight - 4, (gBottom + riseEnd) / 2, const Color(0xFF64FF8C));

    // T-axis ticks
    gLabel('T₀', gLeft - 6, gBottom, const Color(0xFF5A8A9A));
    gLabel('+${deltaTemp.toStringAsFixed(0)}', gLeft - 10, riseEnd, const Color(0xFFFF6B35));
  }

  @override
  bool shouldRepaint(covariant _CalorimetryScreenPainter oldDelegate) => true;
}
