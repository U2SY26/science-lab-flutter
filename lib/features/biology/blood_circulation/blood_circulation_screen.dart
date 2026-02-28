import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BloodCirculationScreen extends StatefulWidget {
  const BloodCirculationScreen({super.key});
  @override
  State<BloodCirculationScreen> createState() => _BloodCirculationScreenState();
}

class _BloodCirculationScreenState extends State<BloodCirculationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _heartRate = 72;
  
  double _strokeVol = 70, _cardiacOutput = 5.0, _bp = 120;

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
      _strokeVol = 100 - _heartRate * 0.3;
      _cardiacOutput = _heartRate * _strokeVol / 1000;
      _bp = 80 + _cardiacOutput * 8;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _heartRate = 72.0;
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
          Text('생물학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('혈액 순환', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '혈액 순환',
          formula: 'CO = HR × SV',
          formulaDescription: '심장 박출과 혈액 순환 시스템을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BloodCirculationScreenPainter(
                time: _time,
                heartRate: _heartRate,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '심박수 (bpm)',
                value: _heartRate,
                min: 40,
                max: 200,
                step: 1,
                defaultValue: 72,
                formatValue: (v) => v.toStringAsFixed(0) + ' bpm',
                onChanged: (v) => setState(() => _heartRate = v),
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
          _V('CO', _cardiacOutput.toStringAsFixed(1) + ' L/min'),
          _V('SV', _strokeVol.toStringAsFixed(0) + ' mL'),
          _V('BP', _bp.toStringAsFixed(0) + ' mmHg'),
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

class _BloodCirculationScreenPainter extends CustomPainter {
  final double time;
  final double heartRate;

  _BloodCirculationScreenPainter({
    required this.time,
    required this.heartRate,
  });

  void _lbl(Canvas canvas, String text, Offset pos, Color color, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  // Draw a vessel (rounded thick line) between two points
  void _drawVessel(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.length < 2) { return; }
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  // Animate blood cells along a polyline path
  void _animateCells(Canvas canvas, List<Offset> path, double speed, Color color, int count, double phase) {
    if (path.length < 2) { return; }
    // Compute total length
    double totalLen = 0;
    final lengths = <double>[0];
    for (int i = 1; i < path.length; i++) {
      final d = (path[i] - path[i - 1]).distance;
      totalLen += d;
      lengths.add(totalLen);
    }
    for (int c = 0; c < count; c++) {
      final t = (phase * speed + c / count) % 1.0;
      final dist = t * totalLen;
      // Find segment
      int seg = 0;
      for (int i = 1; i < lengths.length; i++) {
        if (lengths[i] >= dist) { seg = i - 1; break; }
      }
      seg = seg.clamp(0, path.length - 2);
      final segLen = lengths[seg + 1] - lengths[seg];
      final segT = segLen > 0 ? (dist - lengths[seg]) / segLen : 0.0;
      final px = path[seg].dx + (path[seg + 1].dx - path[seg].dx) * segT;
      final py = path[seg].dy + (path[seg + 1].dy - path[seg].dy) * segT;
      canvas.drawCircle(Offset(px, py), 3.5, Paint()..color = color.withValues(alpha: 0.85));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2 + 4;

    final speed = heartRate / 60.0;

    // ── Central heart (4 chambers) ──────────────────────────────────────
    final hW = w * 0.18;
    final hH = h * 0.30;

    // Beat pulse
    final beatPhase = (time * speed) % 1.0;
    final pulse = math.sin(beatPhase * math.pi).clamp(0.0, 1.0);
    final hW2 = hW * (1 + pulse * 0.05);
    final hH2 = hH * (1 + pulse * 0.05);

    // LA (top-left) - oxygenated
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - hW2 * 0.28, cy - hH2 * 0.26), width: hW2 * 0.48, height: hH2 * 0.44), const Radius.circular(8)),
      Paint()..color = const Color(0xFFCC2222).withValues(alpha: 0.5),
    );
    // RA (top-right) - deoxygenated
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + hW2 * 0.28, cy - hH2 * 0.26), width: hW2 * 0.48, height: hH2 * 0.44), const Radius.circular(8)),
      Paint()..color = const Color(0xFF2244AA).withValues(alpha: 0.5),
    );
    // LV (bottom-left) - oxygenated
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - hW2 * 0.26, cy + hH2 * 0.22), width: hW2 * 0.46, height: hH2 * 0.48), const Radius.circular(8)),
      Paint()..color = const Color(0xFFDD1111).withValues(alpha: 0.65),
    );
    // RV (bottom-right) - deoxygenated
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + hW2 * 0.26, cy + hH2 * 0.22), width: hW2 * 0.46, height: hH2 * 0.48), const Radius.circular(8)),
      Paint()..color = const Color(0xFF1133BB).withValues(alpha: 0.65),
    );
    // Heart outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: hW2 * 1.1, height: hH2 * 1.05), const Radius.circular(10)),
      Paint()..color = const Color(0xFF9ECFDE).withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );

    _lbl(canvas, 'LA', Offset(cx - hW2 * 0.28, cy - hH2 * 0.26), const Color(0xFFFF8888), 7.5);
    _lbl(canvas, 'RA', Offset(cx + hW2 * 0.28, cy - hH2 * 0.26), const Color(0xFF9EB8FF), 7.5);
    _lbl(canvas, 'LV', Offset(cx - hW2 * 0.26, cy + hH2 * 0.22), const Color(0xFFFF6666), 7.5);
    _lbl(canvas, 'RV', Offset(cx + hW2 * 0.26, cy + hH2 * 0.22), const Color(0xFF6688FF), 7.5);

    // ── Pulmonary circulation (right side) ──────────────────────────────
    // Lung icon (right)
    final lungRx = w * 0.84;
    final lungRy = cy - h * 0.06;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(lungRx, lungRy), width: w * 0.12, height: h * 0.22),
      Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.12),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(lungRx, lungRy), width: w * 0.12, height: h * 0.22),
      Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
    _lbl(canvas, '폐', Offset(lungRx, lungRy), const Color(0xFF64FF8C), 9);
    _lbl(canvas, 'O₂↑ CO₂↓', Offset(lungRx, lungRy + h * 0.06), const Color(0xFF5A8A9A), 7);

    // Pulmonary artery: RV → lung (blue, deoxygenated going TO lung)
    final rvTopRight = Offset(cx + hW2 * 0.55, cy + hH2 * 0.04);
    final paPath = [rvTopRight, Offset(cx + w * 0.22, cy + hH2 * 0.04), Offset(lungRx - w * 0.06, lungRy + h * 0.08)];
    _drawVessel(canvas, paPath, const Color(0xFF3355CC), 5);
    _lbl(canvas, '폐동맥', Offset(cx + w * 0.27, cy + hH2 * 0.10), const Color(0xFF9EB8FF), 6.5);

    // Pulmonary vein: lung → LA (red, oxygenated coming back)
    final laTopRight = Offset(cx - hW2 * 0.55, cy - hH2 * 0.06);
    final pvPath = [Offset(lungRx - w * 0.06, lungRy - h * 0.08), Offset(cx + w * 0.18, cy - hH2 * 0.32), laTopRight];
    _drawVessel(canvas, pvPath, const Color(0xFFCC2222), 5);
    _lbl(canvas, '폐정맥', Offset(cx + w * 0.22, cy - hH2 * 0.30), const Color(0xFFFF8888), 6.5);

    // ── Systemic circulation (left side) ────────────────────────────────
    // Body tissue icon (left)
    final bodyLx = w * 0.14;
    final bodyLy = cy + h * 0.04;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bodyLx, bodyLy), width: w * 0.13, height: h * 0.20), const Radius.circular(6)),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bodyLx, bodyLy), width: w * 0.13, height: h * 0.20), const Radius.circular(6)),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
    _lbl(canvas, '전신', Offset(bodyLx, bodyLy - h * 0.03), const Color(0xFFFF6B35), 9);
    _lbl(canvas, 'O₂↓ CO₂↑', Offset(bodyLx, bodyLy + h * 0.04), const Color(0xFF5A8A9A), 7);

    // Aorta: LV → body (red, oxygenated)
    final lvLeft = Offset(cx - hW2 * 0.55, cy + hH2 * 0.10);
    final aortaPath = [lvLeft, Offset(cx - w * 0.22, cy + hH2 * 0.10), Offset(bodyLx + w * 0.07, bodyLy - h * 0.06)];
    _drawVessel(canvas, aortaPath, const Color(0xFFCC1111), 5);
    _lbl(canvas, '대동맥', Offset(cx - w * 0.26, cy + hH2 * 0.16), const Color(0xFFFF8888), 6.5);

    // Vena cava: body → RA (blue, deoxygenated)
    final raTopLeft = Offset(cx + hW2 * 0.55, cy - hH2 * 0.16);
    final vcPath = [Offset(bodyLx + w * 0.07, bodyLy + h * 0.06), Offset(cx - w * 0.16, cy - hH2 * 0.38), raTopLeft];
    _drawVessel(canvas, vcPath, const Color(0xFF1133BB), 5);
    _lbl(canvas, '대정맥', Offset(cx - w * 0.18, cy - hH2 * 0.38), const Color(0xFF9EB8FF), 6.5);

    // ── Animated blood cells ─────────────────────────────────────────────
    // Systemic artery (red cells, LV→body)
    _animateCells(canvas, aortaPath, speed * 0.6, const Color(0xFFFF4444), 4, time);
    // Systemic vein (blue cells, body→RA)
    _animateCells(canvas, List.from(vcPath.reversed), speed * 0.6, const Color(0xFF4466FF), 4, time + 0.5);
    // Pulmonary artery (blue, RV→lung)
    _animateCells(canvas, paPath, speed * 0.5, const Color(0xFF4466FF), 3, time + 0.25);
    // Pulmonary vein (red, lung→LA)
    _animateCells(canvas, List.from(pvPath.reversed), speed * 0.5, const Color(0xFFFF4444), 3, time + 0.75);

    // ── Blood pressure label ─────────────────────────────────────────────
    final strokeVol = (100 - heartRate * 0.3).clamp(40.0, 90.0);
    final co = heartRate * strokeVol / 1000;
    final bp = 80 + co * 8;
    _lbl(canvas, '혈압 ${bp.toStringAsFixed(0)} mmHg', Offset(cx, h - 18), const Color(0xFF5A8A9A), 8.5);

    // Title
    _lbl(canvas, '혈액 순환 (Blood Circulation)', Offset(w / 2, 11), const Color(0xFF00D4FF), 10);
  }

  @override
  bool shouldRepaint(covariant _BloodCirculationScreenPainter oldDelegate) => true;
}
