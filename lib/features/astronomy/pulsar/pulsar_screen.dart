import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class PulsarScreen extends StatefulWidget {
  const PulsarScreen({super.key});
  @override
  State<PulsarScreen> createState() => _PulsarScreenState();
}

class _PulsarScreenState extends State<PulsarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _pulsarPeriod = 33;
  double _magneticField = 3.8;
  double _spindownRate = 0, _charAge = 0;

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
      _spindownRate = _magneticField * _magneticField / (_pulsarPeriod * 1e6);
      _charAge = _pulsarPeriod / (2 * _spindownRate * 1e6);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _pulsarPeriod = 33; _magneticField = 3.8;
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
          Text('천문학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('펄서 타이밍', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '펄서 타이밍',
          formula: 'P = 2πI/(μB sin α)',
          formulaDescription: '펄서 타이밍과 그 응용을 분석합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PulsarScreenPainter(
                time: _time,
                pulsarPeriod: _pulsarPeriod,
                magneticField: _magneticField,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '주기 (ms)',
                value: _pulsarPeriod,
                min: 1,
                max: 1000,
                step: 10,
                defaultValue: 33,
                formatValue: (v) => '${v.toStringAsFixed(0)} ms',
                onChanged: (v) => setState(() => _pulsarPeriod = v),
              ),
              advancedControls: [
            SimSlider(
                label: '자기장 (10¹² G)',
                value: _magneticField,
                min: 0.1,
                max: 100,
                step: 1,
                defaultValue: 3.8,
                formatValue: (v) => '${v.toStringAsFixed(1)} ×10¹² G',
                onChanged: (v) => setState(() => _magneticField = v),
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
          _V('주기', '${_pulsarPeriod.toStringAsFixed(0)} ms'),
          _V('Ṗ', _spindownRate.toStringAsExponential(2)),
          _V('특성 나이', '${_charAge.toStringAsFixed(1)} kyr'),
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

class _PulsarScreenPainter extends CustomPainter {
  final double time;
  final double pulsarPeriod;
  final double magneticField;

  _PulsarScreenPainter({
    required this.time,
    required this.pulsarPeriod,
    required this.magneticField,
  });

  void _label(Canvas canvas, String text, Offset pos, {double fs = 8, Color col = const Color(0xFF5A8A9A), bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // --- Left panel: rotating neutron star + beams ---
    final starPanelW = w * 0.44;
    final starCx = starPanelW / 2;
    final starCy = h * 0.38;
    final starR = 16.0;

    // Background stars
    final rng = math.Random(13);
    for (int i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * starPanelW, rng.nextDouble() * h * 0.75),
        rng.nextDouble() * 1.2 + 0.2,
        Paint()..color = const Color(0xFFE0F4FF).withValues(alpha: rng.nextDouble() * 0.4 + 0.1),
      );
    }

    // Magnetic field lines (dipole ovals)
    final rotAngle = time * 2 * math.pi / (pulsarPeriod / 1000.0).clamp(0.001, 2.0);
    final fieldPaint = Paint()..color = const Color(0xFF3355AA).withValues(alpha: 0.5)..strokeWidth = 1..style = PaintingStyle.stroke;
    for (int fl = 0; fl < 3; fl++) {
      final scale = 1.0 + fl * 0.6;
      final fieldRect = Rect.fromCenter(
        center: Offset(
          starCx + math.sin(rotAngle) * starR * 0.5 * fl * 0.3,
          starCy,
        ),
        width: starR * 2 * scale,
        height: starR * 4 * scale,
      );
      canvas.drawOval(fieldRect, fieldPaint);
    }

    // Neutron star body
    canvas.drawCircle(Offset(starCx, starCy), starR,
        Paint()..color = const Color(0xFFAABBFF)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(starCx, starCy), starR,
        Paint()..color = const Color(0xFF8899FF));
    canvas.drawCircle(Offset(starCx, starCy), starR,
        Paint()..color = const Color(0xFFCCDDFF)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Magnetic poles (rotate with star)
    final poleOffset = Offset(math.sin(rotAngle), math.cos(rotAngle)) * (starR + 4);
    canvas.drawCircle(Offset(starCx + poleOffset.dx, starCy - poleOffset.dy), 4,
        Paint()..color = const Color(0xFF00D4FF));
    canvas.drawCircle(Offset(starCx - poleOffset.dx, starCy + poleOffset.dy), 4,
        Paint()..color = const Color(0xFFFF6B35));

    // Radio beams (cones from magnetic poles)
    final beamLen = math.min(starPanelW, h) * 0.42;
    final beamDir1 = Offset(math.sin(rotAngle), -math.cos(rotAngle));
    final beamDir2 = Offset(-math.sin(rotAngle), math.cos(rotAngle));
    final beamColor = const Color(0xFF00D4FF);

    void drawBeam(Offset dir) {
      final beamPath = Path();
      beamPath.moveTo(starCx + dir.dx * starR, starCy + dir.dy * starR);
      final perpDir = Offset(-dir.dy, dir.dx);
      final tip = Offset(starCx + dir.dx * beamLen, starCy + dir.dy * beamLen);
      final spread = beamLen * 0.18;
      beamPath.lineTo(tip.dx + perpDir.dx * spread, tip.dy + perpDir.dy * spread);
      beamPath.lineTo(tip.dx - perpDir.dx * spread, tip.dy - perpDir.dy * spread);
      beamPath.close();
      canvas.drawPath(beamPath, Paint()..color = beamColor.withValues(alpha: 0.18));
      canvas.drawLine(
        Offset(starCx + dir.dx * starR, starCy + dir.dy * starR),
        Offset(starCx + dir.dx * beamLen, starCy + dir.dy * beamLen),
        Paint()..color = beamColor.withValues(alpha: 0.7)..strokeWidth = 1.5,
      );
    }
    drawBeam(beamDir1);
    drawBeam(beamDir2);

    // Observer direction marker (right side)
    final obsX = starPanelW - 12.0;
    final obsY = starCy;
    canvas.drawCircle(Offset(obsX, obsY), 5, Paint()..color = const Color(0xFF64FF8C));
    _label(canvas, '관측자', Offset(obsX - 16, obsY + 7), fs: 7, col: const Color(0xFF64FF8C));

    // Pulse flash: when beam points toward observer
    final beamAngleToObs = math.atan2(obsX - starCx, 0);
    final beamAngle = rotAngle % (2 * math.pi);
    final angleDiff = ((beamAngle - beamAngleToObs) % (math.pi)).abs();
    final pulseIntensity = math.exp(-angleDiff * angleDiff * 3);
    if (pulseIntensity > 0.1) {
      canvas.drawCircle(Offset(obsX, obsY), 5 + pulseIntensity * 8,
          Paint()..color = const Color(0xFF64FF8C).withValues(alpha: pulseIntensity * 0.5));
    }

    _label(canvas, 'P=${pulsarPeriod.toStringAsFixed(0)}ms', Offset(4, 8), fs: 8, col: const Color(0xFF00D4FF));
    _label(canvas, 'B=${magneticField.toStringAsFixed(1)}×10¹²G', Offset(4, 19), fs: 7, col: const Color(0xFF5A8A9A));

    // Divider
    canvas.drawLine(Offset(starPanelW + 2, 4), Offset(starPanelW + 2, h * 0.75),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    // --- Right panel: pulse timing diagram ---
    final tsLeft = starPanelW + 10;
    final tsRight = w - 8;
    final tsTop = 14.0;
    final tsH = h * 0.38;
    final tsBot = tsTop + tsH;
    final tsW = tsRight - tsLeft;

    canvas.drawLine(Offset(tsLeft, tsBot), Offset(tsRight, tsBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _label(canvas, '신호', Offset(tsLeft - 4, tsTop), fs: 7);
    _label(canvas, '시간 →', Offset(tsRight - 24, tsBot + 2), fs: 7);

    // Period in pixels
    final periodPx = (pulsarPeriod / 1000.0 * 60).clamp(8.0, tsW / 2);
    final numPulses = (tsW / periodPx).floor() + 1;
    final scrollOffset = (time * 40) % periodPx;

    for (int i = 0; i < numPulses; i++) {
      final px = tsLeft + i * periodPx - scrollOffset;
      if (px < tsLeft || px > tsRight) continue;
      // Gaussian pulse shape
      final pulseH = tsH * 0.7;
      final pulsePath = Path();
      const pw = 8;
      for (int pp = -pw; pp <= pw; pp++) {
        final gx = px + pp;
        if (gx < tsLeft || gx > tsRight) continue;
        final t = pp / pw.toDouble();
        final y = tsBot - pulseH * math.exp(-t * t * 4);
        if (pp == -pw) {
          pulsePath.moveTo(gx, y);
        } else {
          pulsePath.lineTo(gx, y);
        }
      }
      canvas.drawPath(pulsePath,
          Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    }

    // Period markers
    final p1X = tsLeft + periodPx * 0.5 - scrollOffset % periodPx;
    if (p1X > tsLeft && p1X + periodPx < tsRight) {
      canvas.drawLine(Offset(p1X, tsBot - 4), Offset(p1X, tsBot + 4),
          Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
      canvas.drawLine(Offset(p1X + periodPx, tsBot - 4), Offset(p1X + periodPx, tsBot + 4),
          Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
      canvas.drawLine(Offset(p1X, tsBot + 2), Offset(p1X + periodPx, tsBot + 2),
          Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
      _label(canvas, 'P', Offset((p1X + p1X + periodPx) / 2, tsBot + 4), fs: 8, col: const Color(0xFFE0F4FF), center: true);
    }

    // --- Pulse profile (average) ---
    final profTop = tsBot + 20;
    final profH = h * 0.22;
    final profBot = profTop + profH;
    if (profTop < h - 10) {
      canvas.drawLine(Offset(tsLeft, profTop), Offset(tsLeft, profBot),
          Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
      canvas.drawLine(Offset(tsLeft, profBot), Offset(tsRight, profBot),
          Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
      _label(canvas, '평균 펄스 프로파일', Offset((tsLeft + tsRight) / 2, profTop - 2), fs: 7, col: const Color(0xFF5A8A9A), center: true);

      final profPath = Path();
      for (int px = 0; px <= (tsRight - tsLeft).toInt(); px++) {
        final t = px / (tsRight - tsLeft);
        // Double-peaked profile typical of pulsars
        final g1 = math.exp(-math.pow((t - 0.3), 2) * 40);
        final g2 = math.exp(-math.pow((t - 0.7), 2) * 80) * 0.6;
        final y = profBot - (g1 + g2) * profH * 0.85;
        final x = tsLeft + px;
        if (px == 0) {
          profPath.moveTo(x, y);
        } else {
          profPath.lineTo(x, y);
        }
      }
      canvas.drawPath(profPath,
          Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    }

    // PTA label at bottom
    _label(canvas, 'PTA: 펄서 타이밍 배열 → 중력파 검출', Offset(8, h - 12), fs: 7, col: const Color(0xFF5A8A9A));
  }

  @override
  bool shouldRepaint(covariant _PulsarScreenPainter oldDelegate) => true;
}
