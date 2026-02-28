import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class MagneticReversalScreen extends StatefulWidget {
  const MagneticReversalScreen({super.key});
  @override
  State<MagneticReversalScreen> createState() => _MagneticReversalScreenState();
}

class _MagneticReversalScreenState extends State<MagneticReversalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _fieldStrength = 50;
  double _reversalRate = 1;
  double _currentPolarity = 1;

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
      _currentPolarity = math.cos(_time * _reversalRate) > 0 ? 1 : -1;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _fieldStrength = 50; _reversalRate = 1.0;
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
          const Text('자기장 역전', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '자기장 역전',
          formula: 'B = B₀ cos(ωt)',
          formulaDescription: '지질학적 시간에 걸친 지구 자기장 역전을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _MagneticReversalScreenPainter(
                time: _time,
                fieldStrength: _fieldStrength,
                reversalRate: _reversalRate,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '자기장 세기 (μT)',
                value: _fieldStrength,
                min: 10,
                max: 80,
                step: 5,
                defaultValue: 50,
                formatValue: (v) => '${v.toStringAsFixed(0)} μT',
                onChanged: (v) => setState(() => _fieldStrength = v),
              ),
              advancedControls: [
            SimSlider(
                label: '역전 빈도 (Myr⁻¹)',
                value: _reversalRate,
                min: 0.1,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => '${v.toStringAsFixed(1)} /Myr',
                onChanged: (v) => setState(() => _reversalRate = v),
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
          _V('세기', '${_fieldStrength.toStringAsFixed(0)} μT'),
          _V('극성', _currentPolarity > 0 ? '정상' : '역전'),
          _V('빈도', '${_reversalRate.toStringAsFixed(1)} /Myr'),
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

class _MagneticReversalScreenPainter extends CustomPainter {
  final double time;
  final double fieldStrength;
  final double reversalRate;

  _MagneticReversalScreenPainter({
    required this.time,
    required this.fieldStrength,
    required this.reversalRate,
  });

  void _drawLabel(Canvas canvas, String text, Offset offset, {double fontSize = 9, Color color = const Color(0xFF5A8A9A)}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Phase: 0=normal, transitioning around reversalRate cycle
    final phase = (time * reversalRate * 0.3) % (math.pi * 2);
    // polarity goes from 1 to -1 smoothly
    final polarity = math.cos(phase);
    final chaos = (1 - polarity.abs()).clamp(0.0, 1.0); // 0=ordered, 1=chaotic

    final cx = size.width / 2;
    // Earth cross-section in upper portion
    final earthCy = size.height * 0.38;
    final earthR = size.height * 0.24;

    // --- Earth layers ---
    // Mantle
    final mantlePaint = Paint()..color = const Color(0xFF8B4513).withValues(alpha: 0.85)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, earthCy), earthR, mantlePaint);
    // Outer core (liquid)
    final outerCorePaint = Paint()..color = const Color(0xFFFF6B00).withValues(alpha: 0.9)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, earthCy), earthR * 0.55, outerCorePaint);
    // Inner core (solid)
    final innerCorePaint = Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.95)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, earthCy), earthR * 0.25, innerCorePaint);
    // Earth outline
    canvas.drawCircle(Offset(cx, earthCy), earthR, Paint()..color = const Color(0xFF5A8A9A)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Layer labels
    _drawLabel(canvas, '내핵', Offset(cx - 10, earthCy - 6), fontSize: 8, color: const Color(0xFF0D1A20));
    _drawLabel(canvas, '외핵', Offset(cx + earthR * 0.3, earthCy - 6), fontSize: 8, color: const Color(0xFF0D1A20));

    // --- Magnetic field lines ---
    final fieldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Draw 6 dipole field lines. polarity determines N/S direction.
    final fieldColor = polarity > 0 ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35);
    final fieldColorMixed = Color.lerp(const Color(0xFF00D4FF), const Color(0xFFFF6B35), chaos * 0.8)!;

    for (int i = 0; i < 6; i++) {
      final t = i / 6.0;
      final baseAngle = t * math.pi; // 0 to pi (left hemisphere lines)
      // Offset angle for chaos
      final chaosOffset = chaos * (math.sin(time * 2.3 + i * 1.7) * 0.5);
      final effectivePolarity = polarity + chaosOffset;

      // Draw a field line as arc. For dipole, lines loop from one pole to the other.
      final path = Path();
      final numPoints = 30;
      final lineScale = 0.5 + 0.5 * (i / 5.0); // inner to outer lines
      final lineR = earthR * (1.1 + lineScale * 1.2);

      // Parametric dipole field line: r = L*cos²(λ) in spherical, approximate as ellipse
      bool first = true;
      for (int j = 0; j <= numPoints; j++) {
        final lambda = -math.pi / 2 + (j / numPoints) * math.pi; // latitude -90 to +90
        final r = lineR * math.cos(lambda) * math.cos(lambda);
        // Determine direction based on polarity
        final directionAngle = effectivePolarity >= 0 ? baseAngle + chaosOffset * 0.3 : math.pi - baseAngle - chaosOffset * 0.3;
        final fieldLineAngle = lambda + math.pi / 2; // convert to canvas angle
        final x = cx + r * math.sin(fieldLineAngle) * math.cos(directionAngle + i * 0.2);
        final y = earthCy - r * math.cos(fieldLineAngle);
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }

      // Chaos blends colors
      fieldPaint.color = Color.lerp(fieldColor, fieldColorMixed, chaos)!.withValues(alpha: 0.7 - chaos * 0.2);
      canvas.drawPath(path, fieldPaint);
    }

    // N/S pole indicators
    final northPole = polarity >= 0;
    final nColor = northPole ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35);
    final sColor = northPole ? const Color(0xFFFF6B35) : const Color(0xFF00D4FF);
    _drawLabel(canvas, northPole ? 'N' : 'S', Offset(cx - 6, earthCy - earthR - 16), fontSize: 11, color: nColor);
    _drawLabel(canvas, northPole ? 'S' : 'N', Offset(cx - 6, earthCy + earthR + 4), fontSize: 11, color: sColor);

    // --- Geomagnetic time scale (bottom bar) ---
    final barY = size.height * 0.81;
    final barH = 10.0;
    final barW = size.width * 0.85;
    final barX = (size.width - barW) / 2;

    // Draw alternating normal/reversed epochs
    final epochs = [
      // [start_frac, end_frac, isNormal] — simplified Brunhes-Matuyama-Gauss
      [0.0, 0.35, 1], // Brunhes (normal, 0-780kyr)
      [0.35, 0.55, 0], // Matuyama (reversed)
      [0.55, 0.70, 1], // Gauss (normal)
      [0.70, 0.85, 0], // Gilbert (reversed)
      [0.85, 1.0, 1], // older normal
    ];
    for (final epoch in epochs) {
      final ex = barX + epoch[0] * barW;
      final ew = (epoch[1] - epoch[0]) * barW;
      final col = epoch[2] == 1 ? const Color(0xFF00D4FF).withValues(alpha: 0.8) : const Color(0xFF1A3040);
      canvas.drawRect(Rect.fromLTWH(ex, barY, ew, barH), Paint()..color = col);
      canvas.drawRect(Rect.fromLTWH(ex, barY, ew, barH), Paint()..color = const Color(0xFF5A8A9A)..style = PaintingStyle.stroke..strokeWidth = 0.5);
    }
    _drawLabel(canvas, '현재', Offset(barX - 2, barY - 13), fontSize: 8, color: const Color(0xFF00D4FF));
    _drawLabel(canvas, '5 Myr', Offset(barX + barW - 24, barY - 13), fontSize: 8);
    _drawLabel(canvas, '정상  역전  정상  역전  정상', Offset(barX + 4, barY + 12), fontSize: 7, color: const Color(0xFF5A8A9A));
    // Brunhes-Matuyama label
    _drawLabel(canvas, 'B-M 역전 (0.78Ma)', Offset(barX + barW * 0.35 - 20, barY - 13), fontSize: 7, color: const Color(0xFFFF6B35));

    // Status label
    final statusText = chaos < 0.3 ? (polarity > 0 ? '정상 극성' : '역전 극성') : '전환 중...';
    final statusColor = chaos < 0.3 ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35);
    _drawLabel(canvas, statusText, Offset(cx - 24, size.height * 0.73), fontSize: 10, color: statusColor);
    _drawLabel(canvas, '세기: ${fieldStrength.toStringAsFixed(0)} μT', Offset(8, 8), fontSize: 8, color: const Color(0xFF5A8A9A));
  }

  @override
  bool shouldRepaint(covariant _MagneticReversalScreenPainter oldDelegate) => true;
}
