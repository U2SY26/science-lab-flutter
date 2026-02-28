import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class FrameDraggingScreen extends StatefulWidget {
  const FrameDraggingScreen({super.key});
  @override
  State<FrameDraggingScreen> createState() => _FrameDraggingScreenState();
}

class _FrameDraggingScreenState extends State<FrameDraggingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _spinParam = 0.5;
  
  double _omega = 0, _ergosphere = 2.0;

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
      _omega = _spinParam / (2 + 2 * math.sqrt(1 - _spinParam * _spinParam));
      _ergosphere = 1 + math.sqrt(1 - _spinParam * _spinParam);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _spinParam = 0.5;
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
          const Text('프레임 끌림 효과', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '프레임 끌림 효과',
          formula: 'Ω = 2GJ/c²r³',
          formulaDescription: '회전하는 천체에 의한 시공간 끌림 효과를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _FrameDraggingScreenPainter(
                time: _time,
                spinParam: _spinParam,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '스핀 매개변수 (a)',
                value: _spinParam,
                min: 0,
                max: 0.998,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(3),
                onChanged: (v) => setState(() => _spinParam = v),
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
          _V('Ω', _omega.toStringAsFixed(4)),
          _V('에르고구', _ergosphere.toStringAsFixed(3) + ' r_s'),
          _V('a', _spinParam.toStringAsFixed(3)),
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

class _FrameDraggingScreenPainter extends CustomPainter {
  final double time;
  final double spinParam;

  _FrameDraggingScreenPainter({
    required this.time,
    required this.spinParam,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final cx = size.width / 2;
    final cy = size.height / 2 + 10;
    final a = spinParam.clamp(0.0, 0.998); // Kerr spin parameter
    final omega = a / (2.0 + 2.0 * math.sqrt(1.0 - a * a)); // frame-drag angular vel

    // Ergosphere semi-axes (Kerr: r_ergo = 1 + sqrt(1-a^2) in units of r_s/2)
    final ergoOuter = 1.0 + math.sqrt(1.0 - a * a);
    final ergoRx = 80.0 + a * 20.0; // equatorial radius (larger)
    final ergoRy = 80.0 * (ergoOuter - a * 0.3) / ergoOuter; // polar (squashed)

    // Event horizon radius
    final rPlus = 1.0 + math.sqrt(1.0 - a * a);
    final bhRx = ergoRx * (rPlus - a * 0.3) / ergoOuter;
    final bhRy = ergoRy * (rPlus - a * 0.3) / ergoOuter;

    void drawText(String txt, Offset pos,
        {Color color = const Color(0xFF5A8A9A), double fs = 9}) {
      final tp = TextPainter(
        text: TextSpan(text: txt, style: TextStyle(color: color, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    // --- Warped grid (spiral distortion due to frame dragging) ---
    const gridRings = 7;
    const gridSpokes = 16;
    for (int ring = 1; ring <= gridRings; ring++) {
      final r = ergoRx * 0.4 + ring * ergoRx * 0.25;
      final path = Path();
      for (int s = 0; s <= 64; s++) {
        final frac = s / 64.0;
        final baseAngle = frac * 2 * math.pi;
        // Spiral twist: stronger near center, proportional to spin
        final twist = a * 1.5 * math.exp(-r / (ergoRx * 1.5));
        final angle = baseAngle + twist * (1.0 - frac);
        final px = cx + r * math.cos(angle);
        final py = cy + r * 0.55 * math.sin(angle); // squashed to ellipse for perspective
        if (s == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      final alpha = (0.08 + 0.12 * (1.0 - ring / gridRings)).clamp(0.0, 1.0);
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF00D4FF).withValues(alpha: alpha)
            ..strokeWidth = 0.7
            ..style = PaintingStyle.stroke);
    }

    // Radial spokes (also twisted)
    for (int s = 0; s < gridSpokes; s++) {
      final baseAngle = s * 2 * math.pi / gridSpokes;
      final spokePath = Path();
      for (int ri = 0; ri <= 20; ri++) {
        final r = ergoRx * 0.4 + ri * ergoRx * 0.1;
        final twist = a * 1.5 * math.exp(-r / (ergoRx * 1.5));
        final angle = baseAngle + twist;
        final px = cx + r * math.cos(angle);
        final py = cy + r * 0.55 * math.sin(angle);
        if (ri == 0) {
          spokePath.moveTo(px, py);
        } else {
          spokePath.lineTo(px, py);
        }
      }
      canvas.drawPath(
          spokePath,
          Paint()
            ..color = const Color(0xFF1A3040).withValues(alpha: 0.6)
            ..strokeWidth = 0.5
            ..style = PaintingStyle.stroke);
    }

    // --- Ergosphere ellipse (dashed) ---
    final ergoPath = Path();
    for (int i = 0; i <= 72; i++) {
      final angle = i * 2 * math.pi / 72;
      final px = cx + ergoRx * math.cos(angle);
      final py = cy + ergoRy * 0.55 * math.sin(angle);
      if (i == 0) {
        ergoPath.moveTo(px, py);
      } else {
        ergoPath.lineTo(px, py);
      }
    }
    // Draw dashed by segmenting
    canvas.drawPath(
        ergoPath,
        Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // Ergosphere label
    drawText('에르고스피어', Offset(cx + ergoRx + 2, cy - 8),
        color: const Color(0xFFFF6B35), fs: 8);

    // --- Black hole core ---
    // Outer glow
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: bhRx * 2 + 16, height: bhRy * 2 * 0.55 + 10),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.12));
    // Event horizon
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: bhRx * 2, height: bhRy * 2 * 0.55),
        Paint()..color = const Color(0xFF050A0C));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: bhRx * 2, height: bhRy * 2 * 0.55),
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Rotation arrow around black hole
    final arrowR = bhRx + 12.0;
    final arrowAngle = time * (1.0 + a * 2.0) % (2 * math.pi);
    final arrowX = cx + arrowR * math.cos(arrowAngle);
    final arrowY = cy + arrowR * 0.55 * math.sin(arrowAngle);
    canvas.drawCircle(Offset(arrowX, arrowY), 4,
        Paint()..color = const Color(0xFF00D4FF));
    // Arrow direction tangent
    final tangX = -math.sin(arrowAngle) * 8;
    final tangY = math.cos(arrowAngle) * 0.55 * 8;
    canvas.drawLine(
        Offset(arrowX, arrowY),
        Offset(arrowX + tangX, arrowY + tangY),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5);

    // --- Gyroscope precession orbit ---
    final gyroR = ergoRx * 1.3;
    final gyroAngle = time * 0.4 % (2 * math.pi);
    final gyroX = cx + gyroR * math.cos(gyroAngle);
    final gyroY = cy + gyroR * 0.55 * math.sin(gyroAngle);

    // Gyroscope orbit path
    final gyroOrbitPath = Path();
    for (int i = 0; i <= 72; i++) {
      final ang = i * 2 * math.pi / 72;
      final px = cx + gyroR * math.cos(ang);
      final py = cy + gyroR * 0.55 * math.sin(ang);
      if (i == 0) {
        gyroOrbitPath.moveTo(px, py);
      } else {
        gyroOrbitPath.lineTo(px, py);
      }
    }
    canvas.drawPath(
        gyroOrbitPath,
        Paint()
          ..color = const Color(0xFF64FF8C).withValues(alpha: 0.3)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke);

    // Gyroscope at its position
    canvas.drawCircle(Offset(gyroX, gyroY), 5,
        Paint()..color = const Color(0xFF64FF8C));
    // Spin axis (precessing)
    final precessAngle = gyroAngle + omega * 10;
    canvas.drawLine(
        Offset(gyroX, gyroY),
        Offset(gyroX + 10 * math.cos(precessAngle), gyroY + 10 * math.sin(precessAngle)),
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5);
    canvas.drawLine(
        Offset(gyroX, gyroY),
        Offset(gyroX - 10 * math.cos(precessAngle), gyroY - 10 * math.sin(precessAngle)),
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5);

    // --- Labels ---
    drawText('Kerr 시공간', Offset(6, 6), color: const Color(0xFF00D4FF), fs: 9);
    drawText('a=${a.toStringAsFixed(3)}M', Offset(6, 18), color: const Color(0xFF5A8A9A), fs: 8);
    drawText('Ω=${omega.toStringAsFixed(4)}', Offset(6, 29), color: const Color(0xFF5A8A9A), fs: 8);
    drawText('자이로스코프', Offset(gyroX + 7, gyroY - 5), color: const Color(0xFF64FF8C), fs: 7);
    drawText('이벤트 호라이즌', Offset(cx - 38, cy - bhRy * 0.55 - 12),
        color: const Color(0xFF00D4FF), fs: 7);

    // Rotation direction label
    drawText('← 시공간 회전', Offset(cx - 42, cy + ergoRy * 0.55 + 8),
        color: const Color(0xFFFF6B35), fs: 8);
  }

  @override
  bool shouldRepaint(covariant _FrameDraggingScreenPainter oldDelegate) => true;
}
