import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class MetricTensorScreen extends StatefulWidget {
  const MetricTensorScreen({super.key});
  @override
  State<MetricTensorScreen> createState() => _MetricTensorScreenState();
}

class _MetricTensorScreenState extends State<MetricTensorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _curvature = 0.5;
  
  double _g00 = -1.0, _g11 = 1.0;

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
      _g00 = -(1 - _curvature);
      _g11 = 1.0 / (1 - _curvature).abs().clamp(0.01, 100);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _curvature = 0.5;
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
          const Text('계량 텐서 시각화', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '계량 텐서 시각화',
          formula: 'ds² = g_μν dx^μ dx^ν',
          formulaDescription: '시공간의 계량 텐서를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _MetricTensorScreenPainter(
                time: _time,
                curvature: _curvature,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '곡률',
                value: _curvature,
                min: 0,
                max: 2,
                step: 0.1,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _curvature = v),
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
          _V('g₀₀', _g00.toStringAsFixed(3)),
          _V('g₁₁', _g11.toStringAsFixed(3)),
          _V('곡률', _curvature.toStringAsFixed(1)),
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

class _MetricTensorScreenPainter extends CustomPainter {
  final double time;
  final double curvature;

  _MetricTensorScreenPainter({
    required this.time,
    required this.curvature,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final cx = size.width / 2;
    final cy = size.height / 2;
    // curvature in [0,2]; map to mass strength [0,1)
    final mass = (curvature / 2.0).clamp(0.0, 0.98);

    // --- Draw warped spacetime grid mesh ---
    // Grid spans from -gridN..+gridN in both x,y
    const gridN = 6;
    const cellPx = 28.0; // pixels per grid cell (flat reference)

    // Warp function: radial depression toward center
    // displacement = -mass * strength / (r^2 + softening)
    Offset warp(double gx, double gy) {
      final rx = gx * cellPx;
      final ry = gy * cellPx;
      final r2 = rx * rx + ry * ry + 400.0;
      final strength = mass * 4000.0;
      final dx = -rx * strength / (r2 * math.sqrt(r2));
      final dy = -ry * strength / (r2 * math.sqrt(r2));
      return Offset(cx + rx + dx, cy + ry + dy);
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw horizontal grid lines
    for (int row = -gridN; row <= gridN; row++) {
      final path = Path();
      bool first = true;
      for (int col = -gridN * 4; col <= gridN * 4; col++) {
        final gx = col / 4.0;
        final gy = row.toDouble();
        final pt = warp(gx, gy);
        if (first) {
          path.moveTo(pt.dx, pt.dy);
          first = false;
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      // Color intensity based on distance from center (more curved = brighter)
      final intensity = (1.0 - (row.abs() / gridN)).clamp(0.2, 1.0);
      linePaint.color = const Color(0xFF00D4FF).withValues(alpha: 0.12 + intensity * 0.18 * mass);
      canvas.drawPath(path, linePaint);
    }

    // Draw vertical grid lines
    for (int col = -gridN; col <= gridN; col++) {
      final path = Path();
      bool first = true;
      for (int row = -gridN * 4; row <= gridN * 4; row++) {
        final gx = col.toDouble();
        final gy = row / 4.0;
        final pt = warp(gx, gy);
        if (first) {
          path.moveTo(pt.dx, pt.dy);
          first = false;
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      final intensity = (1.0 - (col.abs() / gridN)).clamp(0.2, 1.0);
      linePaint.color = const Color(0xFF00D4FF).withValues(alpha: 0.12 + intensity * 0.18 * mass);
      canvas.drawPath(path, linePaint);
    }

    // --- Central mass (black hole / heavy object) ---
    final bhR = 8.0 + mass * 14.0;
    // Event horizon glow
    canvas.drawCircle(Offset(cx, cy), bhR + 8,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.15 + mass * 0.2));
    canvas.drawCircle(Offset(cx, cy), bhR + 4,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.3));
    // Mass core
    canvas.drawCircle(Offset(cx, cy), bhR,
        Paint()..color = const Color(0xFF0A0808));
    canvas.drawCircle(
        Offset(cx, cy),
        bhR,
        Paint()
          ..color = const Color(0xFFFF6B35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Schwarzschild radius label
    if (mass > 0.1) {
      final rsLabel = 'r_s';
      final tp = TextPainter(
        text: TextSpan(
            text: rsLabel,
            style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx + bhR + 3, cy - 8));
    }

    // --- Geodesic: light bending curve around mass ---
    if (mass > 0.05) {
      final geodPath = Path();
      bool gFirst = true;
      for (int i = 0; i <= 120; i++) {
        final angle = -math.pi / 2 + i * math.pi * 2 / 120;
        final rOrbit = bhR + 14 + (1 - mass) * 40;
        // Slight spiral due to curvature
        final spiralR = rOrbit + (mass * 20 * math.sin(angle * 2));
        final gx = cx + spiralR * math.cos(angle);
        final gy = cy + spiralR * math.sin(angle);
        if (gFirst) {
          geodPath.moveTo(gx, gy);
          gFirst = false;
        } else {
          geodPath.lineTo(gx, gy);
        }
      }
      canvas.drawPath(
          geodPath,
          Paint()
            ..color = const Color(0xFF64FF8C).withValues(alpha: 0.6)
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke);
    }

    // --- Light cone tilt visualization (2 small cones near mass) ---
    void drawTiltedCone(Offset pos, double tiltFactor) {
      final coneH = 18.0;
      final coneW = 10.0;
      // Future cone (tilted toward mass)
      final tilt = tiltFactor * 8;
      final coneTop = Offset(pos.dx + tilt, pos.dy - coneH);
      final coneL = Offset(pos.dx - coneW + tilt * 0.5, pos.dy);
      final coneR = Offset(pos.dx + coneW + tilt * 0.5, pos.dy);
      final conePath = Path()
        ..moveTo(coneTop.dx, coneTop.dy)
        ..lineTo(coneL.dx, coneL.dy)
        ..lineTo(coneR.dx, coneR.dy)
        ..close();
      canvas.drawPath(
          conePath,
          Paint()
            ..color = const Color(0xFF00D4FF).withValues(alpha: 0.18)
            ..style = PaintingStyle.fill);
      canvas.drawPath(
          conePath,
          Paint()
            ..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8);
    }

    if (mass > 0.15) {
      final dist = bhR + 28 + (1 - mass) * 20;
      drawTiltedCone(Offset(cx + dist, cy), mass * 0.8);
      drawTiltedCone(Offset(cx - dist, cy), -mass * 0.8);
    }

    // --- g_μν matrix display (top-left) ---
    void drawText(String txt, Offset pos,
        {Color color = const Color(0xFF5A8A9A), double fs = 9}) {
      final tp = TextPainter(
        text: TextSpan(text: txt, style: TextStyle(color: color, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    final g00 = -(1.0 - mass * 0.9);
    final g11 = 1.0 / (1.0 - mass * 0.9).abs().clamp(0.01, 100.0);
    drawText('g_μν (슈바르츠실트)', Offset(6, 6), color: const Color(0xFF5A8A9A), fs: 8);
    drawText('g₀₀=${g00.toStringAsFixed(3)}', Offset(6, 17),
        color: const Color(0xFF00D4FF), fs: 8);
    drawText('g₁₁=${g11.toStringAsFixed(3)}', Offset(6, 28),
        color: const Color(0xFFFF6B35), fs: 8);
    drawText('M=${(mass * 10).toStringAsFixed(1)}M☉', Offset(6, 39),
        color: const Color(0xFF64FF8C), fs: 8);

    // ds² formula
    drawText('ds²=g_μν dx^μdx^ν', Offset(size.width - 110, size.height - 14),
        color: const Color(0xFF5A8A9A), fs: 8);
  }

  @override
  bool shouldRepaint(covariant _MetricTensorScreenPainter oldDelegate) => true;
}
