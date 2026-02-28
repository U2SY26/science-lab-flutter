import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class RelativisticAberrationScreen extends StatefulWidget {
  const RelativisticAberrationScreen({super.key});
  @override
  State<RelativisticAberrationScreen> createState() => _RelativisticAberrationScreenState();
}

class _RelativisticAberrationScreenState extends State<RelativisticAberrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _velocity = 0.5;
  double _aberrationAngle = 0;

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
      _aberrationAngle = math.atan2(math.sin(math.pi / 4) / (_velocity == 0 ? 1 : (1 / math.sqrt(1 - _velocity * _velocity))), math.cos(math.pi / 4) - _velocity) * 180 / math.pi;
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
          const Text('상대론적 광행차', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '상대론적 광행차',
          formula: 'cos \u03B8\u2032 = (cos \u03B8 - \u03B2)/(1 - \u03B2 cos \u03B8)',
          formulaDescription: '상대론적 속도에서 별 위치가 이동하는 것을 봅니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _RelativisticAberrationScreenPainter(
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
                formatValue: (v) => '${v.toStringAsFixed(2)} c',
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
          _V('속도', '${_velocity.toStringAsFixed(2)} c'),
          _V('광행차 각', '${_aberrationAngle.toStringAsFixed(1)}°'),
          _V('γ', (1 / math.sqrt(1 - _velocity * _velocity)).toStringAsFixed(2)),
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

class _RelativisticAberrationScreenPainter extends CustomPainter {
  final double time;
  final double velocity; // v/c

  _RelativisticAberrationScreenPainter({
    required this.time,
    required this.velocity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final beta = velocity.clamp(0.0, 0.999);
    final gamma = 1.0 / math.sqrt(1.0 - beta * beta);

    // Split view: left = rest frame, right = moving frame
    final divX = w * 0.50;
    final leftCx = w * 0.25;
    final rightCx = w * 0.75;
    final cy = h * 0.50;
    final sphereR = math.min(w * 0.18, h * 0.32);

    // Divider
    canvas.drawLine(
      Offset(divX, 8),
      Offset(divX, h - 8),
      Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1.0,
    );
    _drawLabel(canvas, '정지 관성계', Offset(leftCx - 26, 8), 10, AppColors.muted);
    _drawLabel(canvas, '운동 관성계 (v=${beta.toStringAsFixed(2)}c)',
        Offset(rightCx - 50, 8), 10, AppColors.muted);

    // --- Generate seeded star positions (rest frame) ---
    final rng = math.Random(1234);
    const int nStars = 30;
    final List<double> starAngles = List.generate(nStars, (_) => rng.nextDouble() * math.pi * 2);
    final List<double> starDists = List.generate(nStars, (_) => sphereR * (0.55 + rng.nextDouble() * 0.42));

    // --- Left: REST FRAME – uniform star distribution ---
    _drawSkyCircle(canvas, Offset(leftCx, cy), sphereR, AppColors.muted);
    for (int i = 0; i < nStars; i++) {
      final ang = starAngles[i];
      final d = starDists[i];
      final sx = leftCx + d * math.cos(ang);
      final sy = cy + d * math.sin(ang);
      if (_inCircle(sx - leftCx, sy - cy, sphereR * 0.98)) {
        canvas.drawCircle(Offset(sx, sy), 1.8, Paint()..color = Colors.white.withValues(alpha: 0.85));
      }
    }

    // --- Right: MOVING FRAME – aberrated star positions ---
    _drawSkyCircle(canvas, Offset(rightCx, cy), sphereR, AppColors.accent);

    // Forward direction indicator (right = forward)
    canvas.drawLine(
      Offset(rightCx, cy),
      Offset(rightCx + sphereR + 10, cy),
      Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.6)..strokeWidth = 1.5,
    );
    _drawLabel(canvas, 'v→', Offset(rightCx + sphereR + 4, cy - 7), 10, const Color(0xFF64FF8C));

    // Draw aberrated stars with Doppler color shift
    for (int i = 0; i < nStars; i++) {
      // Original angle in rest frame (0 = right = forward)
      final thetaOrig = starAngles[i];
      // Aberration formula: cos θ' = (cos θ - β) / (1 - β cos θ)
      final cosOrig = math.cos(thetaOrig);
      final cosAb = (cosOrig - beta) / (1.0 - beta * cosOrig);
      final thetaAb = math.acos(cosAb.clamp(-1.0, 1.0));
      final signY = math.sin(thetaOrig) >= 0 ? 1.0 : -1.0;
      final angAb = signY >= 0 ? thetaAb : -thetaAb;

      // Relativistic Doppler factor
      final doppler = math.sqrt((1 + beta * cosOrig) / (1 - beta * cosOrig));
      // Map doppler > 1 → blue, < 1 → red
      Color starColor;
      if (doppler > 1.0) {
        final t = math.min(1.0, (doppler - 1.0) / 2.0);
        starColor = Color.fromARGB(220, (255 - t * 200).toInt(), (255 - t * 100).toInt(), 255);
      } else {
        final t = math.min(1.0, (1.0 - doppler) / 0.8);
        starColor = Color.fromARGB(220, 255, (255 - t * 200).toInt(), (255 - t * 200).toInt());
      }

      final d = starDists[i];
      final sx = rightCx + d * math.cos(angAb);
      final sy = cy + d * math.sin(angAb);
      if (_inCircle(sx - rightCx, sy - cy, sphereR * 0.98)) {
        canvas.drawCircle(Offset(sx, sy), 1.8, Paint()..color = starColor);
      }
    }

    // Forward density highlight
    canvas.drawArc(
      Rect.fromCircle(center: Offset(rightCx, cy), radius: sphereR * 0.95),
      -math.pi / 3,
      math.pi * 2 / 3,
      false,
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );

    // --- Velocity arrow below ---
    final arrowY = h * 0.88;
    canvas.drawLine(
      Offset(divX + 8, arrowY),
      Offset(divX + sphereR * 0.7, arrowY),
      Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 2.0,
    );
    _drawArrowHead(canvas, Offset(divX + sphereR * 0.7, arrowY), 0, const Color(0xFF64FF8C));
    _drawLabel(canvas, 'v = ${beta.toStringAsFixed(3)}c   γ = ${gamma.toStringAsFixed(2)}',
        Offset(w * 0.3, arrowY + 5), 10, AppColors.muted);

    // Headlight label
    if (beta > 0.5) {
      _drawLabel(canvas, '헤드라이트 효과', Offset(rightCx - 30, cy + sphereR + 6), 9, AppColors.accent);
    }

    // Title
    _drawLabel(canvas, '상대론적 광행차', Offset(w / 2 - 30, h * 0.93), 10, AppColors.accent);
  }

  bool _inCircle(double dx, double dy, double r) => dx * dx + dy * dy <= r * r;

  void _drawSkyCircle(Canvas canvas, Offset center, double r, Color borderColor) {
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFF050D14));
    canvas.drawCircle(center, r,
        Paint()
          ..color = borderColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _drawArrowHead(Canvas canvas, Offset tip, double angle, Color color) {
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 8 * math.cos(angle) + 4 * math.sin(angle),
               tip.dy - 8 * math.sin(angle) - 4 * math.cos(angle))
      ..lineTo(tip.dx - 8 * math.cos(angle) - 4 * math.sin(angle),
               tip.dy - 8 * math.sin(angle) + 4 * math.cos(angle))
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _RelativisticAberrationScreenPainter oldDelegate) => true;
}
