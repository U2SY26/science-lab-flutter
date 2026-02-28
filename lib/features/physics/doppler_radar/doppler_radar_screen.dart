import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DopplerRadarScreen extends StatefulWidget {
  const DopplerRadarScreen({super.key});
  @override
  State<DopplerRadarScreen> createState() => _DopplerRadarScreenState();
}

class _DopplerRadarScreenState extends State<DopplerRadarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _targetSpeed = 30;
  double _radarFreq = 10;
  double _freqShift = 0;

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
      _freqShift = 2 * _targetSpeed * _radarFreq * 1e9 / 3e8;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _targetSpeed = 30; _radarFreq = 10;
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
          const Text('도플러 레이더', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '도플러 레이더',
          formula: 'Δf = 2vf₀/c',
          formulaDescription: '도플러 주파수 이동으로 속도를 측정합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DopplerRadarScreenPainter(
                time: _time,
                targetSpeed: _targetSpeed,
                radarFreq: _radarFreq,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '목표 속도 (m/s)',
                value: _targetSpeed,
                min: 0,
                max: 100,
                step: 1,
                defaultValue: 30,
                formatValue: (v) => '${v.toStringAsFixed(0)} m/s',
                onChanged: (v) => setState(() => _targetSpeed = v),
              ),
              advancedControls: [
            SimSlider(
                label: '레이더 주파수 (GHz)',
                value: _radarFreq,
                min: 1,
                max: 30,
                step: 1,
                defaultValue: 10,
                formatValue: (v) => '${v.toStringAsFixed(0)} GHz',
                onChanged: (v) => setState(() => _radarFreq = v),
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
          _V('주파수 이동', '${_freqShift.toStringAsFixed(1)} Hz'),
          _V('속도', '${_targetSpeed.toStringAsFixed(0)} m/s'),
          _V('주파수', '${_radarFreq.toStringAsFixed(0)} GHz'),
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

class _DopplerRadarScreenPainter extends CustomPainter {
  final double time;
  final double targetSpeed;
  final double radarFreq;

  _DopplerRadarScreenPainter({
    required this.time,
    required this.targetSpeed,
    required this.radarFreq,
  });

  void _label(Canvas canvas, String text, Offset pos, Color color, double sz,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: sz,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;

    // ----- Layout -----
    // Top 58%: main radar scene
    // Bottom 38%: wave comparison panel
    final sceneH = h * 0.58;
    final waveY = sceneH + 6;
    final waveH = h - waveY - 6;

    // === RADAR SCENE ===
    final radarX = w * 0.12;
    final radarY = sceneH * 0.45;

    // Target moves from right side, looping
    final speedNorm = targetSpeed / 100.0;
    final targetX = w * 0.85 - ((time * speedNorm * w * 0.4) % (w * 0.7));
    final targetY = sceneH * 0.45;

    // Pulse expand phase: 0..1 repeating at ~1.5Hz
    final pulsePhase = (time * 1.5) % 1.0;

    // Draw outgoing pulses (3 rings from radar, cyan)
    for (int i = 0; i < 3; i++) {
      final phase = (pulsePhase + i / 3.0) % 1.0;
      final dist = (targetX - radarX);
      final maxR = dist * 0.9;
      final r = phase * maxR;
      if (r > 4) {
        canvas.drawCircle(
            Offset(radarX, radarY),
            r,
            Paint()
              ..color = const Color(0xFF00D4FF).withValues(alpha: (1 - phase) * 0.5)
              ..strokeWidth = 1.2
              ..style = PaintingStyle.stroke);
      }
    }

    // Reflected pulses (smaller, denser from target back to radar, orange)
    final reflPhase = (time * 1.5 * (1 + speedNorm * 0.5)) % 1.0;
    for (int i = 0; i < 3; i++) {
      final phase = (reflPhase + i / 3.0) % 1.0;
      final dist = (targetX - radarX);
      final maxR = dist * 0.85;
      final r = phase * maxR;
      if (r > 4) {
        canvas.drawCircle(
            Offset(targetX, targetY),
            r,
            Paint()
              ..color = const Color(0xFFFF6B35).withValues(alpha: (1 - phase) * 0.45)
              ..strokeWidth = 1.0
              ..style = PaintingStyle.stroke);
      }
    }

    // Ground line
    canvas.drawLine(
        Offset(0, sceneH * 0.65),
        Offset(w, sceneH * 0.65),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    // Radar dish (triangle)
    final rp = Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.fill;
    final radarPath = Path()
      ..moveTo(radarX, radarY - 12)
      ..lineTo(radarX - 10, radarY + 8)
      ..lineTo(radarX + 10, radarY + 8)
      ..close();
    canvas.drawPath(radarPath, rp);
    canvas.drawRect(Rect.fromLTWH(radarX - 3, radarY + 8, 6, 10),
        Paint()..color = const Color(0xFF5A8A9A));
    _label(canvas, '레이더', Offset(radarX - 14, radarY + 20),
        const Color(0xFF00D4FF), 8);

    // Target (simple car shape)
    final tx = targetX;
    final ty = targetY;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(tx - 18, ty - 8, 36, 14), const Radius.circular(3)),
        Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(tx - 10, ty + 6), 4,
        Paint()..color = const Color(0xFF5A8A9A));
    canvas.drawCircle(Offset(tx + 10, ty + 6), 4,
        Paint()..color = const Color(0xFF5A8A9A));
    _label(canvas, '▶ ${targetSpeed.toStringAsFixed(0)} m/s',
        Offset(tx - 20, ty - 20), const Color(0xFFFF6B35), 8);

    // Frequency shift label
    final freqShift = 2 * targetSpeed * radarFreq * 1e9 / 3e8;
    _label(canvas, 'Δf = ${freqShift.toStringAsFixed(1)} Hz',
        Offset(w / 2 - 30, 6), const Color(0xFFE0F4FF), 10, bold: true);
    _label(canvas, 'Δf = 2vf₀/c',
        Offset(w / 2 - 22, 18), const Color(0xFF5A8A9A), 8);

    // === WAVE COMPARISON PANEL ===
    canvas.drawRect(Rect.fromLTWH(0, waveY, w, waveH),
        Paint()..color = const Color(0xFF0A0A0F));
    canvas.drawLine(Offset(0, waveY), Offset(w, waveY),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    _label(canvas, '송신파 (낮은 주파수)', Offset(6, waveY + 2),
        const Color(0xFF00D4FF), 8);
    _label(canvas, '반사파 (높은 주파수)', Offset(w / 2 + 4, waveY + 2),
        const Color(0xFFFF6B35), 8);

    final wBaseline = waveY + waveH * 0.6;
    final wAmp = waveH * 0.32;

    // Outgoing wave (wider cycles = lower freq)
    final outFreq = 6.0;
    final outPath = Path();
    for (int px = 0; px < (w / 2 - 4).toInt(); px++) {
      final t = px / (w / 2) * math.pi * outFreq;
      final y = wBaseline - math.sin(t) * wAmp;
      if (px == 0) { outPath.moveTo(px.toDouble(), y); } else { outPath.lineTo(px.toDouble(), y); }
    }
    canvas.drawPath(outPath, Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);

    // Reflected wave (narrower cycles = higher freq due to Doppler)
    final reflFreq = outFreq * (1 + speedNorm * 1.5);
    final reflPath = Path();
    final startX = w / 2 + 4;
    for (int px = 0; px < (w / 2 - 4).toInt(); px++) {
      final t = px / (w / 2) * math.pi * reflFreq;
      final y = wBaseline - math.sin(t) * wAmp;
      if (px == 0) { reflPath.moveTo(startX + px, y); } else { reflPath.lineTo(startX + px, y); }
    }
    canvas.drawPath(reflPath, Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);

    // Divider
    canvas.drawLine(Offset(w / 2, waveY + 2), Offset(w / 2, waveY + waveH - 2),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _DopplerRadarScreenPainter oldDelegate) => true;
}
