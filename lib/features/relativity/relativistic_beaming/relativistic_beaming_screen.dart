import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class RelativisticBeamingScreen extends StatefulWidget {
  const RelativisticBeamingScreen({super.key});
  @override
  State<RelativisticBeamingScreen> createState() => _RelativisticBeamingScreenState();
}

class _RelativisticBeamingScreenState extends State<RelativisticBeamingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _beamSpeed = 0.8;
  double _dopplerFactor = 0, _gamma = 0;

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
      _gamma = 1.0 / math.sqrt(1.0 - _beamSpeed * _beamSpeed);
      _dopplerFactor = 1.0 / (_gamma * (1 - _beamSpeed));
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _beamSpeed = 0.8;
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
          const Text('상대론적 빔 집중', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '상대론적 빔 집중',
          formula: 'D = 1/(γ(1-β cos θ))',
          formulaDescription: '운동 방향으로의 빛 집중을 관찰합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _RelativisticBeamingScreenPainter(
                time: _time,
                beamSpeed: _beamSpeed,
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
                value: _beamSpeed,
                min: 0,
                max: 0.99,
                step: 0.01,
                defaultValue: 0.8,
                formatValue: (v) => '${v.toStringAsFixed(2)} c',
                onChanged: (v) => setState(() => _beamSpeed = v),
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
          _V('γ', _gamma.toStringAsFixed(2)),
          _V('D (전방)', _dopplerFactor.toStringAsFixed(2)),
          _V('β', _beamSpeed.toStringAsFixed(2)),
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

class _RelativisticBeamingScreenPainter extends CustomPainter {
  final double time;
  final double beamSpeed; // v/c = β

  _RelativisticBeamingScreenPainter({
    required this.time,
    required this.beamSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final beta = beamSpeed.clamp(0.001, 0.999);
    final gamma = 1.0 / math.sqrt(1.0 - beta * beta);

    // --- Left polar plot: REST FRAME (isotropic) ---
    final leftCx = w * 0.28;
    final rightCx = w * 0.72;
    final plotCy = h * 0.46;
    final plotR = math.min(w * 0.19, h * 0.30);

    _drawPolarPlot(canvas, Offset(leftCx, plotCy), plotR, 1.0, 1.0,
        '정지 프레임\n(등방성)', false);

    // --- Right polar plot: MOVING FRAME (beamed) ---
    _drawPolarPlot(canvas, Offset(rightCx, plotCy), plotR, beta, gamma,
        '운동 프레임\n(β=${beta.toStringAsFixed(2)})', true);

    // --- Half-angle annotation ---
    final halfAngleDeg = (1.0 / gamma) * 180.0 / math.pi;
    _drawLabel(canvas, '반각 ≈ 1/γ = ${halfAngleDeg.toStringAsFixed(1)}°',
        Offset(rightCx - 44, plotCy + plotR + 22), 9, const Color(0xFF64FF8C));

    // --- Jet particles animated ---
    for (int i = 0; i < 10; i++) {
      final phase = (time * 0.5 + i * 0.1) % 1.0;
      // In moving frame all jets cluster forward (right)
      final halfAngle = 1.0 / gamma;
      final ang = (i / 9.0 - 0.5) * halfAngle * 2;
      final pr = plotR * 0.5 + phase * plotR * 0.5;
      final px = rightCx + pr * math.cos(ang);
      final py = plotCy + pr * math.sin(ang);
      final alpha = 1.0 - phase;
      canvas.drawCircle(Offset(px, py), 2.5,
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: alpha * 0.9));
    }

    // --- Velocity arrow ---
    final arrowY = h * 0.86;
    final arrowLen = w * 0.18 * beta;
    canvas.drawLine(
      Offset(rightCx - arrowLen / 2, arrowY),
      Offset(rightCx + arrowLen / 2, arrowY),
      Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 2.0,
    );
    _drawArrowHead(canvas, Offset(rightCx + arrowLen / 2, arrowY), 0, const Color(0xFF64FF8C));

    // --- Labels ---
    _drawLabel(canvas, 'β = ${beta.toStringAsFixed(2)}   γ = ${gamma.toStringAsFixed(2)}',
        Offset(w * 0.34, arrowY + 5), 10, AppColors.muted);
    _drawLabel(canvas, 'D(θ=0) = ${(gamma * (1 + beta)).toStringAsFixed(1)}×',
        Offset(rightCx - 28, plotCy - plotR - 16), 9, const Color(0xFFFF6B35));
    _drawLabel(canvas, '상대론적 빔 집중', Offset(w / 2 - 34, 8), 11, AppColors.accent);
    _drawLabel(canvas, 'AGN 제트 / 펄사', Offset(w * 0.38, h * 0.93), 9, AppColors.muted);
  }

  void _drawPolarPlot(Canvas canvas, Offset center, double R, double beta,
      double gamma, String label, bool isMoving) {
    // Background circle
    canvas.drawCircle(center, R,
        Paint()..color = const Color(0xFF0A1520));
    canvas.drawCircle(center, R,
        Paint()
          ..color = const Color(0xFF1A3040)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    // Polar grid rings
    for (int r = 1; r <= 3; r++) {
      canvas.drawCircle(center, R * r / 3,
          Paint()
            ..color = const Color(0xFF1A3040)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5);
    }

    // Intensity distribution I(θ) = 1/(γ(1-β cosθ))^4
    // Plot as polar curve
    final Path polePath = Path();
    const int N = 120;
    for (int i = 0; i <= N; i++) {
      final theta = i / N * math.pi * 2;
      double intensity;
      if (isMoving) {
        final denom = gamma * (1.0 - beta * math.cos(theta));
        intensity = 1.0 / math.pow(denom, 4);
      } else {
        intensity = 1.0;
      }
      // Normalize: max intensity → R*0.9
      final maxI = isMoving ? math.pow(gamma * (1.0 + beta), 4).toDouble() : 1.0;
      final r = (intensity / maxI).clamp(0.0, 1.0) * R * 0.88;
      final px = center.dx + r * math.cos(theta);
      final py = center.dy + r * math.sin(theta);
      if (i == 0) {
        polePath.moveTo(px, py);
      } else {
        polePath.lineTo(px, py);
      }
    }
    polePath.close();
    canvas.drawPath(polePath,
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: 0.25)
          ..style = PaintingStyle.fill);
    canvas.drawPath(polePath,
        Paint()
          ..color = const Color(0xFF00D4FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Axis line (forward direction)
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + R, center.dy),
      Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.4)..strokeWidth = 0.8,
    );

    // Label
    final lines = label.split('\n');
    for (int i = 0; i < lines.length; i++) {
      _drawLabel(canvas, lines[i],
          Offset(center.dx - 24, center.dy + R + 5 + i * 13), 9,
          isMoving ? AppColors.accent : AppColors.muted);
    }
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
  bool shouldRepaint(covariant _RelativisticBeamingScreenPainter oldDelegate) => true;
}
