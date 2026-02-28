import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class GyroscopeScreen extends StatefulWidget {
  const GyroscopeScreen({super.key});
  @override
  State<GyroscopeScreen> createState() => _GyroscopeScreenState();
}

class _GyroscopeScreenState extends State<GyroscopeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _spinRate = 500.0;
  double _tiltAngle = 0.5;
  double _precessionRate = 0, _precessionAngle = 0;

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
      final spinOmega = _spinRate * 2 * math.pi / 60;
      final I = 0.5 * 1.0 * 0.1 * 0.1;
      final L = I * spinOmega;
      final tau = 1.0 * 9.8 * 0.05 * math.sin(_tiltAngle);
      _precessionRate = tau / L;
      _precessionAngle += _precessionRate * 0.02;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _spinRate = 500.0;
      _tiltAngle = 0.5;
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
          const Text('자이로스코프 세차 운동', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '자이로스코프 세차 운동',
          formula: 'Ω = τ/L = Mgr/(Iω)',
          formulaDescription: '회전하는 물체에 토크가 작용하면 세차 운동이 발생합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GyroscopeScreenPainter(
                time: _time,
                spinRate: _spinRate,
                tiltAngle: _tiltAngle,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '회전 속도 (rpm)',
                value: _spinRate,
                min: 100.0,
                max: 1000.0,
                defaultValue: 500.0,
                formatValue: (v) => '${v.toInt()} rpm',
                onChanged: (v) => setState(() => _spinRate = v),
              ),
              advancedControls: [
            SimSlider(
                label: '기울기 각도',
                value: _tiltAngle,
                min: 0.1,
                max: 1.2,
                step: 0.05,
                defaultValue: 0.5,
                formatValue: (v) => '${(v * 180 / math.pi).toStringAsFixed(0)}°',
                onChanged: (v) => setState(() => _tiltAngle = v),
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
          _V('세차 속도', '${_precessionRate.toStringAsFixed(3)} rad/s'),
          _V('각운동량', '${(_spinRate * 0.001).toStringAsFixed(2)} L'),
          _V('토크', '${(9.8 * 0.05 * math.sin(_tiltAngle)).toStringAsFixed(3)} τ'),
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

class _GyroscopeScreenPainter extends CustomPainter {
  final double time;
  final double spinRate;
  final double tiltAngle;

  _GyroscopeScreenPainter({
    required this.time,
    required this.spinRate,
    required this.tiltAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Physics: precession rate Ω = mgl / (I·ω)
    final spinOmega = spinRate * 2 * math.pi / 60;
    final I = 0.5 * 1.0 * 0.1 * 0.1;
    final L = I * spinOmega;
    final tau = 1.0 * 9.8 * 0.05 * math.sin(tiltAngle);
    final precRate = (L > 0.001) ? tau / L : 0.0;
    final precAngle = precRate * time;

    // ── LEFT PANEL: isometric gyroscope ─────────────────────
    final cx = w * 0.38;
    final cy = h * 0.42;
    final axisLen = h * 0.28;
    const isoAngle = 0.3; // isometric projection angle

    // Pivot point (bottom, fixed support)
    final pivotX = cx;
    final pivotY = cy + axisLen * 0.55;

    // Axis direction in isometric view (tilted by tiltAngle, rotating by precAngle)
    final ax = math.sin(tiltAngle) * math.cos(precAngle);
    final ay = -math.cos(tiltAngle);
    final az = math.sin(tiltAngle) * math.sin(precAngle);

    // Project to 2D (simple isometric)
    final proj2dx = ax - az * math.cos(isoAngle);
    final proj2dy = ay + az * math.sin(isoAngle) * 0.5;

    final axisEndX = pivotX + proj2dx * axisLen;
    final axisEndY = pivotY + proj2dy * axisLen;

    // Support arm (table to pivot)
    canvas.drawLine(Offset(pivotX, pivotY), Offset(pivotX, pivotY + 14),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 3..strokeCap = StrokeCap.round);
    canvas.drawRect(Rect.fromLTWH(pivotX - 14, pivotY + 14, 28, 5),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.6));

    // Spinning disk (ellipse centered on axis midpoint)
    final diskCX = pivotX + proj2dx * axisLen * 0.6;
    final diskCY = pivotY + proj2dy * axisLen * 0.6;
    final diskR = axisLen * 0.22;

    // Disk fill (spin-phase animated)
    final spinPhase = spinOmega * time;
    final diskOval = Rect.fromCenter(
        center: Offset(diskCX, diskCY),
        width: diskR * 2,
        height: diskR * 0.7);
    canvas.drawOval(diskOval, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.22));
    canvas.drawOval(diskOval, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // Rotation markers on disk
    for (int i = 0; i < 4; i++) {
      final a = spinPhase + i * math.pi / 2;
      final rx = diskCX + diskR * math.cos(a) * 0.85;
      final ry = diskCY + diskR * 0.35 * math.sin(a);
      canvas.drawCircle(Offset(rx, ry), 2.5,
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6));
    }

    // Gyro axis line
    canvas.drawLine(Offset(pivotX, pivotY), Offset(axisEndX, axisEndY),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 2.5..strokeCap = StrokeCap.round);

    // Angular momentum vector L (along axis)
    final lScale = 0.6;
    canvas.drawLine(Offset(diskCX, diskCY),
        Offset(diskCX + proj2dx * axisLen * lScale * 0.5,
               diskCY + proj2dy * axisLen * lScale * 0.5),
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 2.0..strokeCap = StrokeCap.round);
    _text(canvas, 'L', Offset(diskCX + proj2dx * axisLen * lScale * 0.5 + 3,
        diskCY + proj2dy * axisLen * lScale * 0.5 - 8),
        const TextStyle(color: Color(0xFF64FF8C), fontSize: 9, fontWeight: FontWeight.bold));

    // Gravity arrow (down from disk)
    canvas.drawLine(Offset(diskCX, diskCY), Offset(diskCX, diskCY + 28),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.8..strokeCap = StrokeCap.round);
    _text(canvas, 'mg', Offset(diskCX + 4, diskCY + 18),
        const TextStyle(color: Color(0xFFFF6B35), fontSize: 8));

    // Precession circle (top view shadow)
    final precR = (axisLen * 0.22).clamp(10.0, 40.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pivotX, pivotY - 8), width: precR * 2.2, height: precR * 0.7),
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.18)..style = PaintingStyle.stroke..strokeWidth = 1.0,
    );
    // Tip of axis tracing precession
    canvas.drawCircle(Offset(axisEndX, axisEndY), 4,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.9));

    _text(canvas, '자이로스코프', Offset(4, 4),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold));

    // ── RIGHT PANEL: info ────────────────────────────────────
    final infoX = w * 0.64;
    final infoY = 20.0;
    final lineH = h * 0.065;

    void infoRow(String label, String val, Color col, double y) {
      _text(canvas, label, Offset(infoX, y),
          const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));
      _text(canvas, val, Offset(infoX, y + lineH * 0.55),
          TextStyle(color: col, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'));
    }

    infoRow('스핀 속도', '${spinRate.toInt()} rpm', const Color(0xFF00D4FF), infoY);
    infoRow('기울기', '${(tiltAngle * 180 / math.pi).toStringAsFixed(1)}°', const Color(0xFFFF6B35), infoY + lineH * 1.4);
    infoRow('각운동량 |L|', L.toStringAsFixed(4), const Color(0xFF64FF8C), infoY + lineH * 2.8);
    infoRow('토크 τ', '${tau.toStringAsFixed(4)} N·m', const Color(0xFFFF6B35), infoY + lineH * 4.2);
    infoRow('세차 속도 Ω', '${precRate.toStringAsFixed(3)} rad/s', const Color(0xFF00D4FF), infoY + lineH * 5.6);

    // Precession angle indicator arc
    final arcCX = infoX + 30;
    final arcCY = infoY + lineH * 8.5;
    final arcR = 24.0;
    canvas.drawArc(Rect.fromCircle(center: Offset(arcCX, arcCY), radius: arcR),
        -math.pi / 2, precAngle % (2 * math.pi), false,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2.0);
    final tipX = arcCX + arcR * math.cos(-math.pi / 2 + precAngle % (2 * math.pi));
    final tipY = arcCY + arcR * math.sin(-math.pi / 2 + precAngle % (2 * math.pi));
    canvas.drawCircle(Offset(tipX, tipY), 3, Paint()..color = const Color(0xFF00D4FF));
    _text(canvas, '세차', Offset(arcCX - 10, arcCY + arcR + 4),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 7));
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _GyroscopeScreenPainter oldDelegate) => true;
}
