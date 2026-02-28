import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class MagneticInductionScreen extends StatefulWidget {
  const MagneticInductionScreen({super.key});
  @override
  State<MagneticInductionScreen> createState() => _MagneticInductionScreenState();
}

class _MagneticInductionScreenState extends State<MagneticInductionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _mutualM = 0.5;
  double _dIdt = 10;
  double _emf = 5.0;

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
      _emf = _mutualM * _dIdt;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _mutualM = 0.5; _dIdt = 10.0;
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
          Text('물리 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('상호 유도', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '상호 유도',
          formula: 'EMF = -M(dI/dt)',
          formulaDescription: '상호 유도에 의한 기전력을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _MagneticInductionScreenPainter(
                time: _time,
                mutualM: _mutualM,
                dIdt: _dIdt,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '상호 인덕턴스 (H)',
                value: _mutualM,
                min: 0.01,
                max: 2,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2) + ' H',
                onChanged: (v) => setState(() => _mutualM = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'dI/dt (A/s)',
                value: _dIdt,
                min: 1,
                max: 100,
                step: 1,
                defaultValue: 10,
                formatValue: (v) => v.toStringAsFixed(0) + ' A/s',
                onChanged: (v) => setState(() => _dIdt = v),
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
          _V('EMF', _emf.toStringAsFixed(1) + ' V'),
          _V('M', _mutualM.toStringAsFixed(2) + ' H'),
          _V('dI/dt', _dIdt.toStringAsFixed(0) + ' A/s'),
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

class _MagneticInductionScreenPainter extends CustomPainter {
  final double time;
  final double mutualM;
  final double dIdt;

  _MagneticInductionScreenPainter({
    required this.time,
    required this.mutualM,
    required this.dIdt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Magnet oscillates left-right: position 0..1
    final magnetPhase = (math.sin(time * 1.2) * 0.5 + 0.5); // 0..1
    final velocity = math.cos(time * 1.2); // positive = approaching

    // Layout: coil on left third, magnet on right
    final coilCx = w * 0.28;
    final coilCy = h * 0.45;
    final magnetX = w * 0.55 + magnetPhase * w * 0.18;
    final magnetCy = h * 0.45;
    final distance = magnetX - coilCx;
    final fieldStrength = math.max(0.05, mutualM / (distance / w * 3 + 0.5));

    final accentPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final orangePaint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final gridPaint = Paint()
      ..color = const Color(0xFF1A3040).withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    // Grid
    for (double x = 0; x < w; x += 30) { canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint); }
    for (double y = 0; y < h; y += 30) { canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint); }

    // --- Coil (solenoid cross-section) ---
    final coilW = w * 0.14;
    final coilH = h * 0.38;
    final numRings = 7;
    final coilPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    // Outer coil box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(coilCx, coilCy), width: coilW, height: coilH),
        const Radius.circular(4),
      ),
      coilPaint..color = const Color(0xFF00D4FF).withValues(alpha: 0.4),
    );
    // Ring lines (cross-section of solenoid)
    for (int i = 0; i < numRings; i++) {
      final ry = coilCy - coilH / 2 + (i + 0.5) * coilH / numRings;
      canvas.drawLine(
        Offset(coilCx - coilW / 2, ry),
        Offset(coilCx + coilW / 2, ry),
        coilPaint..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)..strokeWidth = 1,
      );
      // Ring ellipses at edges
      canvas.drawOval(
        Rect.fromCenter(center: Offset(coilCx - coilW / 2, ry), width: 6, height: coilH / numRings * 0.7),
        coilPaint..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)..strokeWidth = 1.5,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(coilCx + coilW / 2, ry), width: 6, height: coilH / numRings * 0.7),
        coilPaint..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)..strokeWidth = 1.5,
      );
    }

    // --- B-field lines inside coil (density proportional to fieldStrength) ---
    final numFieldLines = (3 + fieldStrength * 4).round().clamp(3, 8);
    for (int i = 0; i < numFieldLines; i++) {
      final fy = coilCy - coilH / 2 + 8 + i * (coilH - 16) / (numFieldLines - 1);
      final arrowP = Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.6 * fieldStrength.clamp(0.2, 1.0))
        ..strokeWidth = 1;
      canvas.drawLine(Offset(coilCx - coilW / 2 + 4, fy), Offset(coilCx + coilW / 2 - 4, fy), arrowP);
      // Arrowhead
      canvas.drawLine(Offset(coilCx + coilW / 2 - 10, fy - 3), Offset(coilCx + coilW / 2 - 4, fy), arrowP);
      canvas.drawLine(Offset(coilCx + coilW / 2 - 10, fy + 3), Offset(coilCx + coilW / 2 - 4, fy), arrowP);
    }

    // --- Bar magnet ---
    final magW = w * 0.10;
    final magH = h * 0.28;
    // N half (red/orange)
    canvas.drawRect(
      Rect.fromLTWH(magnetX - magW / 2, magnetCy - magH / 2, magW / 2, magH),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.85),
    );
    // S half (muted blue)
    canvas.drawRect(
      Rect.fromLTWH(magnetX, magnetCy - magH / 2, magW / 2, magH),
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.85),
    );
    canvas.drawRect(
      Rect.fromLTWH(magnetX - magW / 2, magnetCy - magH / 2, magW, magH),
      orangePaint..color = const Color(0xFFFF6B35)..strokeWidth = 1.5,
    );
    // N / S labels
    _drawLabel(canvas, 'N', Offset(magnetX - magW / 4, magnetCy), const Color(0xFFFF6B35), 11);
    _drawLabel(canvas, 'S', Offset(magnetX + magW / 4, magnetCy), const Color(0xFFE0F4FF), 11);

    // --- Magnetic field lines from magnet to coil ---
    final numCurves = 4;
    for (int i = 0; i < numCurves; i++) {
      final t = (i - (numCurves - 1) / 2) / (numCurves - 1) * 2; // -1..1
      final startY = magnetCy + t * magH * 0.4;
      final endY = coilCy + t * coilH * 0.3;
      final ctrlX = (magnetX - magW / 2 + coilCx + coilW / 2) / 2;
      final ctrlY = startY - math.sin(t * math.pi) * h * 0.15;
      final path = Path()
        ..moveTo(magnetX - magW / 2, startY)
        ..quadraticBezierTo(ctrlX, ctrlY, coilCx + coilW / 2, endY);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: 0.25)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }

    // --- Induced current dots in coil (animated when magnet moves) ---
    final emf = mutualM * dIdt * velocity.abs();
    if (emf > 0.1) {
      final numDots = 6;
      for (int i = 0; i < numDots; i++) {
        final phase = (time * 1.5 + i / numDots) % 1.0;
        // Dots travel around the coil perimeter
        double dotX, dotY;
        if (phase < 0.25) {
          dotX = coilCx - coilW / 2 + phase * 4 * coilW;
          dotY = coilCy - coilH / 2;
        } else if (phase < 0.5) {
          dotX = coilCx + coilW / 2;
          dotY = coilCy - coilH / 2 + (phase - 0.25) * 4 * coilH;
        } else if (phase < 0.75) {
          dotX = coilCx + coilW / 2 - (phase - 0.5) * 4 * coilW;
          dotY = coilCy + coilH / 2;
        } else {
          dotX = coilCx - coilW / 2;
          dotY = coilCy + coilH / 2 - (phase - 0.75) * 4 * coilH;
        }
        canvas.drawCircle(
          Offset(dotX, dotY),
          2.5,
          Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.9),
        );
      }
    }

    // --- Voltmeter gauge ---
    final vmCx = w * 0.13;
    final vmCy = h * 0.82;
    final vmR = h * 0.08;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(vmCx, vmCy), width: vmR * 2, height: vmR * 2),
      math.pi, math.pi,
      false,
      accentPaint..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)..strokeWidth = 1.5,
    );
    // Needle deflects with EMF
    final needleAngle = math.pi + (emf / (mutualM * dIdt + 0.001)).clamp(0.0, 1.0) * math.pi;
    canvas.drawLine(
      Offset(vmCx, vmCy),
      Offset(vmCx + vmR * 0.8 * math.cos(needleAngle), vmCy + vmR * 0.8 * math.sin(needleAngle)),
      Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2,
    );
    canvas.drawCircle(Offset(vmCx, vmCy), 2, Paint()..color = const Color(0xFF00D4FF));
    _drawLabel(canvas, 'V', Offset(vmCx, vmCy + vmR + 8), const Color(0xFF5A8A9A), 9);

    // --- EMF value label ---
    final emfVal = (mutualM * dIdt).toStringAsFixed(1);
    _drawLabel(canvas, 'ε = ${emfVal}V', Offset(w * 0.5, h * 0.88), const Color(0xFF00D4FF), 11);

    // --- Title ---
    _drawLabel(canvas, '전자기 유도 (패러데이)', Offset(w / 2, 14), const Color(0xFF00D4FF), 12, bold: true);
  }

  void _drawLabel(Canvas canvas, String text, Offset center, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MagneticInductionScreenPainter oldDelegate) => true;
}
