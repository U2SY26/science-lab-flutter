import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ThermohalineScreen extends StatefulWidget {
  const ThermohalineScreen({super.key});
  @override
  State<ThermohalineScreen> createState() => _ThermohalineScreenState();
}

class _ThermohalineScreenState extends State<ThermohalineScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _tempDiff = 20;
  double _salinity = 35;
  double _density = 1025, _flowSpeed = 0.1;

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
      _density = 1025 + _salinity * 0.8 - _tempDiff * 0.2;
      _flowSpeed = (_density - 1020) * 0.01;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _tempDiff = 20.0; _salinity = 35.0;
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
          const Text('열염순환', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '열염순환',
          formula: 'ρ = f(T, S, P)',
          formulaDescription: '해수의 온도와 염도에 의한 열염순환을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ThermohalineScreenPainter(
                time: _time,
                tempDiff: _tempDiff,
                salinity: _salinity,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '온도차 (°C)',
                value: _tempDiff,
                min: 0,
                max: 40,
                step: 1,
                defaultValue: 20,
                formatValue: (v) => v.toStringAsFixed(0) + ' °C',
                onChanged: (v) => setState(() => _tempDiff = v),
              ),
              advancedControls: [
            SimSlider(
                label: '염도 (psu)',
                value: _salinity,
                min: 30,
                max: 40,
                step: 0.5,
                defaultValue: 35,
                formatValue: (v) => v.toStringAsFixed(1) + ' psu',
                onChanged: (v) => setState(() => _salinity = v),
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
          _V('밀도', _density.toStringAsFixed(1) + ' kg/m³'),
          _V('유속', _flowSpeed.toStringAsFixed(3) + ' m/s'),
          _V('염도', _salinity.toStringAsFixed(1) + ' psu'),
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

class _ThermohalineScreenPainter extends CustomPainter {
  final double time;
  final double tempDiff;
  final double salinity;

  _ThermohalineScreenPainter({
    required this.time,
    required this.tempDiff,
    required this.salinity,
  });

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint, {double arrowSize = 7}) {
    canvas.drawLine(from, to, paint);
    final dir = to - from;
    final len = dir.distance;
    if (len < 1) return;
    final u = dir / len;
    final perp = Offset(-u.dy, u.dx);
    final p1 = to - u * arrowSize + perp * arrowSize * 0.4;
    final p2 = to - u * arrowSize - perp * arrowSize * 0.4;
    final path = Path()..moveTo(to.dx, to.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..close();
    final fill = Paint()..color = paint.color..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);
  }

  Offset _pathPoint(List<Offset> pts, double t) {
    final total = pts.length - 1;
    final seg = (t * total).floor().clamp(0, total - 1);
    final localT = (t * total) - seg;
    return Offset.lerp(pts[seg], pts[seg + 1], localT)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final pad = 14.0;

    // === World map outline (simplified rectangle regions) ===
    // Draw ocean background
    final oceanPaint = Paint()..color = const Color(0xFF0A2A3A)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(pad, pad + 14, w - pad, h - pad),
      const Radius.circular(6),
    ), oceanPaint);

    // Land masses (simplified)
    final landPaint = Paint()..color = const Color(0xFF1F3D1A)..style = PaintingStyle.fill;
    // North America
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(pad + 4, pad + 18, w * 0.28, h * 0.52),
      const Radius.circular(4),
    ), landPaint);
    // Europe/Africa
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.38, pad + 18, w * 0.54, h * 0.72),
      const Radius.circular(4),
    ), landPaint);
    // Asia
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.55, pad + 18, w - pad - 4, h * 0.50),
      const Radius.circular(4),
    ), landPaint);
    // Antarctica
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(pad + 4, h * 0.82, w - pad - 4, h - pad - 2),
      const Radius.circular(4),
    ), landPaint);

    // Region labels
    void drawLabel(String text, double x, double y, Color color, double fontSize) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    drawLabel('북대서양', w * 0.30, h * 0.28, const Color(0xFF5A8A9A), 8);
    drawLabel('태평양', w * 0.75, h * 0.65, const Color(0xFF5A8A9A), 8);
    drawLabel('인도양', w * 0.60, h * 0.68, const Color(0xFF5A8A9A), 7);

    // === Warm surface current path (orange/red) ===
    final speedFactor = (tempDiff / 40.0).clamp(0.2, 1.0);
    final warmPath = [
      Offset(w * 0.30, h * 0.58),  // Gulf of Mexico
      Offset(w * 0.32, h * 0.35),  // N Atlantic
      Offset(w * 0.42, h * 0.25),  // Nordic seas
      Offset(w * 0.50, h * 0.30),  // NADW sinking
      Offset(w * 0.60, h * 0.42),  // Indian ocean
      Offset(w * 0.72, h * 0.60),  // Pacific
      Offset(w * 0.55, h * 0.72),  // South pacific
      Offset(w * 0.35, h * 0.72),  // South atlantic
      Offset(w * 0.30, h * 0.58),  // back to start
    ];

    final warmPaint = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw warm path segments with arrows
    for (int i = 0; i < warmPath.length - 1; i++) {
      _drawArrow(canvas, warmPath[i], warmPath[i + 1], warmPaint, arrowSize: 6);
    }

    // === Cold deep current path (cyan/blue) ===
    final coldPath = [
      Offset(w * 0.50, h * 0.30),  // NADW sinking
      Offset(w * 0.48, h * 0.60),  // deep atlantic
      Offset(w * 0.42, h * 0.78),  // circumpolar
      Offset(w * 0.65, h * 0.78),  // deep circumpolar
      Offset(w * 0.72, h * 0.60),  // upwelling pacific
    ];

    final coldPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.9)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < coldPath.length - 1; i++) {
      _drawArrow(canvas, coldPath[i], coldPath[i + 1], coldPaint, arrowSize: 5);
    }

    // === NADW sinking point ===
    final sinkingPaint = Paint()..color = const Color(0xFFFFD700)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.50, h * 0.30), 5, sinkingPaint);
    drawLabel('NADW 침강', w * 0.50, h * 0.22, const Color(0xFFFFD700), 8);

    // === Animated particles along warm current ===
    final particleT = (time * 0.12 * speedFactor) % 1.0;
    for (int i = 0; i < 4; i++) {
      final t = (particleT + i * 0.25) % 1.0;
      final pos = _pathPoint(warmPath, t);
      canvas.drawCircle(pos, 3.5, Paint()..color = const Color(0xFFFF6B35));
    }

    // Animated particles along cold current
    final coldParticleT = (time * 0.08 * speedFactor) % 1.0;
    for (int i = 0; i < 3; i++) {
      final t = (coldParticleT + i * 0.33) % 1.0;
      final pos = _pathPoint(coldPath, t);
      canvas.drawCircle(pos, 3, Paint()..color = const Color(0xFF00D4FF));
    }

    // === Legend ===
    final legX = pad + 6.0;
    final legY = h * 0.53;
    canvas.drawLine(Offset(legX, legY), Offset(legX + 18, legY),
      Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2.5);
    drawLabel('표층류(따뜻)', legX + 36, legY, const Color(0xFFFF6B35), 7.5);
    canvas.drawLine(Offset(legX, legY + 12), Offset(legX + 18, legY + 12),
      Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2);
    drawLabel('심층류(차가움)', legX + 38, legY + 12, const Color(0xFF00D4FF), 7.5);

    // Title
    drawLabel('열염순환 (대양 컨베이어 벨트)', w / 2, pad + 8, const Color(0xFF00D4FF), 10);
  }

  @override
  bool shouldRepaint(covariant _ThermohalineScreenPainter oldDelegate) => true;
}
