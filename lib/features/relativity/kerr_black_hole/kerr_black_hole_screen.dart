import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class KerrBlackHoleScreen extends StatefulWidget {
  const KerrBlackHoleScreen({super.key});
  @override
  State<KerrBlackHoleScreen> createState() => _KerrBlackHoleScreenState();
}

class _KerrBlackHoleScreenState extends State<KerrBlackHoleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _spin = 0.5;
  
  double _rPlus = 1.87, _rMinus = 0.13;

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
      _rPlus = 1 + math.sqrt(1 - _spin * _spin);
      _rMinus = 1 - math.sqrt(1 - _spin * _spin);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _spin = 0.5;
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
          const Text('커 블랙홀', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '커 블랙홀',
          formula: 'r± = M ± √(M² - a²)',
          formulaDescription: '회전하는 커 블랙홀의 에르고구와 사건의 지평선을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _KerrBlackHoleScreenPainter(
                time: _time,
                spin: _spin,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '스핀 매개변수 (a/M)',
                value: _spin,
                min: 0,
                max: 0.998,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(3),
                onChanged: (v) => setState(() => _spin = v),
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
          _V('r+', _rPlus.toStringAsFixed(3) + ' M'),
          _V('r-', _rMinus.toStringAsFixed(3) + ' M'),
          _V('a', _spin.toStringAsFixed(3)),
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

class _KerrBlackHoleScreenPainter extends CustomPainter {
  final double time;
  final double spin;

  _KerrBlackHoleScreenPainter({
    required this.time,
    required this.spin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Kerr radii (M=1 units)
    final a = spin.clamp(0.0, 0.998);
    final rPlus = 1.0 + math.sqrt(1.0 - a * a);   // outer event horizon
    final ergoEq = 2.0;                              // equatorial ergo radius
    final rISCO = _iscoRadius(a);

    // Scale: rPlus outer horizon maps to ~30px radius
    final scale = size.height * 0.13;

    // --- Frame-dragging swirl grid ---
    final swirlPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    const int swirlLines = 12;
    for (int i = 0; i < swirlLines; i++) {
      final baseAngle = (i / swirlLines) * math.pi * 2;
      final path = Path();
      for (int j = 0; j <= 60; j++) {
        final r = ergoEq * scale * (1.2 + j * 0.06);
        // Angular offset increases with 1/r^2 (frame dragging)
        final omega = a * 0.4 / math.max(0.1, (r / scale) * (r / scale));
        final ang = baseAngle + omega * 8 + time * a * 0.3;
        final px = cx + r * math.cos(ang);
        final py = cy + r * math.sin(ang);
        if (j == 0) { path.moveTo(px, py); } else { path.lineTo(px, py); }
      }
      canvas.drawPath(path, swirlPaint);
    }

    // --- Accretion disk (thin ring, tilted perspective) ---
    // Draw disk as multiple concentric ellipses (foreshortened)
    for (int d = 0; d < 5; d++) {
      final rDisk = rISCO * scale * (1.3 + d * 0.35);
      final alpha = 0.7 - d * 0.13;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rDisk * 2, height: rDisk * 0.55),
        Paint()
          ..color = Color.fromARGB((alpha * 200).toInt(), 255, 150, 50)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 - d * 0.7,
      );
    }

    // --- ISCO label ---
    _drawLabel(canvas, 'ISCO', Offset(cx + rISCO * scale + 4, cy - 6), 9, const Color(0xFFFF6B35));
    canvas.drawCircle(
      Offset(cx, cy),
      rISCO * scale,
      Paint()
        ..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeJoin = StrokeJoin.round,
    );

    // --- Ergosphere (oblate at equator) ---
    final ergoA = ergoEq * scale;     // equatorial semi-axis
    final ergoB = (1.0 + math.sqrt(1.0 - a * a * 0.0)) * scale; // polar (simplified)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: ergoA * 2, height: ergoB * 1.3),
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: ergoA * 2, height: ergoB * 1.3),
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    _drawLabel(canvas, '에르고스피어', Offset(cx + ergoA + 3, cy - 8), 9, AppColors.accent);

    // --- Outer event horizon (r+) ---
    final rPlusR = rPlus * scale;
    canvas.drawCircle(
      Offset(cx, cy),
      rPlusR,
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      rPlusR,
      Paint()
        ..color = const Color(0xFF00D4FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // --- Black hole shadow (event horizon interior) ---
    canvas.drawCircle(
      Offset(cx, cy),
      rPlusR * 0.95,
      Paint()..color = Colors.black,
    );

    // --- Spin arrow ---
    final arrowR = rPlusR * 0.62;
    final arrowAngle = -math.pi / 2 + time * a * 1.5;
    final ax = cx + arrowR * math.cos(arrowAngle);
    final ay = cy + arrowR * math.sin(arrowAngle);
    canvas.drawCircle(Offset(ax, ay), 3, Paint()..color = const Color(0xFF64FF8C));
    _drawLabel(canvas, 'a=${spin.toStringAsFixed(2)}', Offset(cx - 18, cy + rPlusR + 6), 9, AppColors.muted);

    // --- Hawking radiation particles ---
    final rng = math.Random(77);
    for (int i = 0; i < 8; i++) {
      final baseAngle = rng.nextDouble() * math.pi * 2;
      final t2 = (time * 0.6 + i * 0.7) % 1.0;
      final pr = rPlusR + t2 * 30;
      final px = cx + pr * math.cos(baseAngle);
      final py = cy + pr * math.sin(baseAngle);
      canvas.drawCircle(
        Offset(px, py),
        1.5 * (1 - t2 * 0.6),
        Paint()..color = Color.fromARGB(((1 - t2) * 200).toInt(), 100, 255, 140),
      );
    }

    // --- Labels ---
    _drawLabel(canvas, 'r+=${rPlus.toStringAsFixed(2)}M', Offset(cx + rPlusR + 3, cy + 4), 9, AppColors.accent);
    _drawLabel(canvas, '호킹 복사', Offset(cx - 22, cy - rPlusR - 14), 9, const Color(0xFF64FF8C));
    _drawLabel(canvas, '커 블랙홀', Offset(cx - 28, 8), 11, AppColors.accent);
  }

  // ISCO radius for Kerr (prograde)
  double _iscoRadius(double a) {
    final z1 = 1 + math.pow(1 - a * a, 1 / 3.0) *
        (math.pow(1 + a, 1 / 3.0) + math.pow(1 - a, 1 / 3.0));
    final z2 = math.sqrt(3 * a * a + z1 * z1);
    return 3 + z2 - math.sqrt((3 - z1) * (3 + z1 + 2 * z2));
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _KerrBlackHoleScreenPainter oldDelegate) => true;
}
