import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class RelativisticEnergyScreen extends StatefulWidget {
  const RelativisticEnergyScreen({super.key});
  @override
  State<RelativisticEnergyScreen> createState() => _RelativisticEnergyScreenState();
}

class _RelativisticEnergyScreenState extends State<RelativisticEnergyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _velocity = 0.5;
  
  double _gammaVal = 1.0, _keRel = 0.0, _keClass = 0.0;

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
      _gammaVal = 1.0 / math.sqrt(1 - _velocity * _velocity);
      _keRel = (_gammaVal - 1);
      _keClass = 0.5 * _velocity * _velocity;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _velocity = 0.5;
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
          Text('상대성이론 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('상대론적 운동 에너지', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '상대론적 운동 에너지',
          formula: 'E = γmc² - mc²',
          formulaDescription: '상대론적 운동 에너지와 고전적 운동 에너지를 비교합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _RelativisticEnergyScreenPainter(
                time: _time,
                velocity: _velocity,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '속도 (c)',
                value: _velocity,
                min: 0,
                max: 0.99,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2) + ' c',
                onChanged: (v) => setState(() => _velocity = v),
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
          _V('γ', _gammaVal.toStringAsFixed(3)),
          _V('상대론적', _keRel.toStringAsFixed(3) + ' mc²'),
          _V('고전적', _keClass.toStringAsFixed(3) + ' mc²'),
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

class _RelativisticEnergyScreenPainter extends CustomPainter {
  final double time;
  final double velocity;

  _RelativisticEnergyScreenPainter({
    required this.time,
    required this.velocity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    const pad = 48.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final originX = pad;
    final originY = pad + h;

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 10; i++) {
      final x = originX + w * i / 10;
      canvas.drawLine(Offset(x, pad), Offset(x, originY), gridPaint);
      final y = originY - h * i / 10;
      canvas.drawLine(Offset(originX, y), Offset(originX + w, y), gridPaint);
    }

    // Axes
    final axisPaint = Paint()
      ..color = const Color(0xFF5A8A9A)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(originX, originY), Offset(originX + w, originY), axisPaint);
    canvas.drawLine(Offset(originX, originY), Offset(originX, pad), axisPaint);

    // Axis labels
    void drawText(String txt, Offset pos, {Color color = const Color(0xFF5A8A9A), double fs = 9}) {
      final tp = TextPainter(
        text: TextSpan(text: txt, style: TextStyle(color: color, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    drawText('v/c', Offset(originX + w - 12, originY + 4));
    drawText('E/mc²', Offset(2, pad - 2));
    for (int i = 0; i <= 5; i++) {
      final v = i * 0.2;
      final x = originX + w * v / 1.0;
      drawText(v.toStringAsFixed(1), Offset(x - 8, originY + 4));
      final eVal = i * 2.0;
      final y = originY - h * eVal / 10.0;
      if (i > 0) drawText(eVal.toStringAsFixed(0), Offset(2, y - 5));
    }

    // Rest energy E₀ = mc² = 1 (muted horizontal line)
    final restY = originY - h * 1.0 / 10.0;
    final mutedPaint = Paint()
      ..color = const Color(0xFF5A8A9A)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final mutedPath = Path();
    mutedPath.moveTo(originX, restY);
    for (double t = 0; t <= 1.0; t += 0.02) {
      mutedPath.lineTo(originX + w * t, restY);
    }
    canvas.drawPath(mutedPath, mutedPaint);
    drawText('E₀=mc²', Offset(originX + 4, restY - 11), color: const Color(0xFF5A8A9A), fs: 8);

    // Classical KE: K = ½mv² (orange dashed)
    final classPath = Path();
    bool classFirst = true;
    for (int i = 0; i <= 200; i++) {
      final v = i / 200.0 * 0.999;
      final ke = 1.0 + 0.5 * v * v; // E₀ + ½mv²
      final ex = originX + w * v / 1.0;
      final ey = originY - h * ke / 10.0;
      if (ey < pad - 5) break;
      if (classFirst) { classPath.moveTo(ex, ey); classFirst = false; }
      else classPath.lineTo(ex, ey);
    }
    final dashedPaint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    // Draw as dashed
    canvas.drawPath(classPath, dashedPaint..color = const Color(0xFFFF6B35).withValues(alpha: 0.6));

    // Relativistic total energy: E = γmc² (cyan curve)
    final relPath = Path();
    bool relFirst = true;
    for (int i = 0; i <= 400; i++) {
      final v = i / 400.0 * 0.999;
      final gamma = 1.0 / math.sqrt(1 - v * v);
      final e = gamma; // in units mc²
      final ex = originX + w * v / 1.0;
      final ey = originY - h * e / 10.0;
      if (ey < pad - 5) break;
      if (relFirst) { relPath.moveTo(ex, ey); relFirst = false; }
      else relPath.lineTo(ex, ey);
    }
    final relPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(relPath, relPaint);

    // Light speed asymptote (vertical dashed line at v=c)
    final asymX = originX + w * 0.999;
    final asymPaint = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final asymPath = Path();
    asymPath.moveTo(asymX, pad);
    for (double y2 = pad; y2 <= originY; y2 += 6) {
      asymPath.moveTo(asymX, y2);
      asymPath.lineTo(asymX, y2 + 3);
    }
    canvas.drawPath(asymPath, asymPaint);
    drawText('v=c', Offset(asymX - 12, pad + 2), color: const Color(0xFFFF6B35), fs: 8);

    // Current velocity marker
    final vCur = velocity.clamp(0.001, 0.999);
    final gammaCur = 1.0 / math.sqrt(1 - vCur * vCur);
    final eCur = gammaCur;
    final curX = originX + w * vCur;
    final curY = originY - h * eCur / 10.0;

    // Vertical dashed line at current v
    final dottedPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    final dotPath = Path();
    for (double y2 = curY; y2 <= originY; y2 += 6) {
      dotPath.moveTo(curX, y2);
      dotPath.lineTo(curX, y2 + 3);
    }
    canvas.drawPath(dotPath, dottedPaint);

    // Current point on relativistic curve
    if (curY >= pad) {
      canvas.drawCircle(Offset(curX, curY), 5,
          Paint()..color = const Color(0xFF00D4FF));
      canvas.drawCircle(Offset(curX, curY), 5,
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 3);
    }

    // Momentum p = γmv (green small indicator)
    final p = gammaCur * vCur;
    final pY = originY - h * p / 10.0;
    if (pY >= pad) {
      canvas.drawCircle(Offset(curX, pY), 3,
          Paint()..color = const Color(0xFF64FF8C));
    }

    // γ label
    drawText('γ=${gammaCur.toStringAsFixed(2)}', Offset(curX + 4, curY.clamp(pad, originY - 20).toDouble() - 14),
        color: const Color(0xFF00D4FF), fs: 9);

    // Legend
    canvas.drawLine(Offset(originX + 8, pad + 8), Offset(originX + 24, pad + 8),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2);
    drawText('상대론적 E=γmc²', Offset(originX + 26, pad + 3), color: const Color(0xFF00D4FF), fs: 8);
    canvas.drawLine(Offset(originX + 8, pad + 20), Offset(originX + 24, pad + 20),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.8)..strokeWidth = 1.5);
    drawText('고전적 E₀+½mv²', Offset(originX + 26, pad + 15), color: const Color(0xFFFF6B35), fs: 8);
    canvas.drawCircle(Offset(originX + 16, pad + 32), 3, Paint()..color = const Color(0xFF64FF8C));
    drawText('운동량 p=γmv', Offset(originX + 26, pad + 27), color: const Color(0xFF64FF8C), fs: 8);
  }

  @override
  bool shouldRepaint(covariant _RelativisticEnergyScreenPainter oldDelegate) => true;
}
