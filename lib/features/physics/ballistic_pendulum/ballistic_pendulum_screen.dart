import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BallisticPendulumScreen extends StatefulWidget {
  const BallisticPendulumScreen({super.key});
  @override
  State<BallisticPendulumScreen> createState() => _BallisticPendulumScreenState();
}

class _BallisticPendulumScreenState extends State<BallisticPendulumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _projMass = 0.05;
  double _projVel = 200.0;
  double _pendMass = 2.0;
  double _height = 0, _swingAngle = 0; int _phase = 0;

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
      final totalMass = _projMass + _pendMass;
      final vAfter = _projMass * _projVel / totalMass;
      _height = vAfter * vAfter / (2 * 9.8);
      final maxAngle = math.acos(1 - _height / 1.5);
      if (_phase == 0 && _time > 0.5) _phase = 1;
      if (_phase == 1) _swingAngle = maxAngle * math.sin(math.sqrt(9.8 / 1.5) * (_time - 0.5)).abs() * math.exp(-0.1 * (_time - 0.5));
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _projMass = 0.05;
      _projVel = 200.0;
      _pendMass = 2.0;
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
          const Text('탄도 진자', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '탄도 진자',
          formula: 'v = ((m+M)/m)·√(2gh)',
          formulaDescription: '운동량 보존과 에너지 보존을 이용하여 발사체 속도를 측정합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BallisticPendulumScreenPainter(
                time: _time,
                projMass: _projMass,
                projVel: _projVel,
                pendMass: _pendMass,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '탄환 질량 (kg)',
                value: _projMass,
                min: 0.01,
                max: 0.2,
                step: 0.01,
                defaultValue: 0.05,
                formatValue: (v) => '${(v * 1000).toStringAsFixed(0)} g',
                onChanged: (v) => setState(() => _projMass = v),
              ),
              advancedControls: [
            SimSlider(
                label: '탄환 속도 (m/s)',
                value: _projVel,
                min: 50.0,
                max: 500.0,
                defaultValue: 200.0,
                formatValue: (v) => '${v.toInt()} m/s',
                onChanged: (v) => setState(() => _projVel = v),
              ),
            SimSlider(
                label: '진자 질량 (kg)',
                value: _pendMass,
                min: 0.5,
                max: 5.0,
                step: 0.1,
                defaultValue: 2.0,
                formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                onChanged: (v) => setState(() => _pendMass = v),
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
          _V('높이', '${_height.toStringAsFixed(3)} m'),
          _V('운동량', '${(_projMass * _projVel).toStringAsFixed(1)} kg·m/s'),
          _V('에너지', '${(0.5 * _projMass * _projVel * _projVel).toStringAsFixed(0)} J'),
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

class _BallisticPendulumScreenPainter extends CustomPainter {
  final double time;
  final double projMass;
  final double projVel;
  final double pendMass;

  _BallisticPendulumScreenPainter({
    required this.time,
    required this.projMass,
    required this.projVel,
    required this.pendMass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Physics
    final totalMass = projMass + pendMass;
    final vAfter = projMass * projVel / totalMass;
    final heightRise = vAfter * vAfter / (2 * 9.8);
    final g = 9.8;
    final omegaPend = math.sqrt(g / 1.5);
    final maxAngle = math.asin((heightRise / 1.5).clamp(0.0, 1.0));

    // Animation cycle: 0-0.4 bullet flying, 0.4-0.6 collision, 0.6-2.0 swinging
    final cycleT = time % 2.8;
    final phase = cycleT < 0.5 ? 0 : (cycleT < 0.75 ? 1 : 2);
    final swingT = (cycleT - 0.75).clamp(0.0, 2.05);
    final swingAngle = maxAngle * math.cos(omegaPend * swingT) * math.exp(-0.15 * swingT);

    // ── MAIN SCENE ──────────────────────────────────────────
    final pivotX = w * 0.58;
    final pivotY = h * 0.14;
    final rodLen = h * 0.34;

    // Pivot mount
    canvas.drawRect(Rect.fromLTWH(pivotX - 18, pivotY - 8, 36, 8),
        Paint()..color = const Color(0xFF5A8A9A));
    canvas.drawLine(Offset(pivotX, pivotY), Offset(pivotX, pivotY - 8),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 2);

    // Current pendulum angle
    final angle = (phase == 2) ? swingAngle : 0.0;
    final blockX = pivotX + rodLen * math.sin(angle);
    final blockY = pivotY + rodLen * math.cos(angle);

    // Rod
    canvas.drawLine(Offset(pivotX, pivotY), Offset(blockX, blockY),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.8..strokeCap = StrokeCap.round);

    // Block
    const blockH2 = 18.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(blockX, blockY), width: blockH2 * 1.4, height: blockH2),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: phase == 1 ? 0.5 : 0.85),
    );
    _text(canvas, 'M', Offset(blockX - 5, blockY - 6),
        TextStyle(color: const Color(0xFF0D1A20).withValues(alpha: 0.9), fontSize: 8, fontWeight: FontWeight.bold));

    // Bullet
    if (phase == 0) {
      // Flying bullet
      final bulletProgress = cycleT / 0.5;
      final bulletX = w * 0.04 + bulletProgress * (blockX - blockH2 - w * 0.04);
      final bulletY = blockY.toDouble();
      canvas.drawOval(
        Rect.fromCenter(center: Offset(bulletX, bulletY), width: 12, height: 6),
        Paint()..color = const Color(0xFF64FF8C),
      );
      // Speed arrow
      canvas.drawLine(Offset(bulletX + 6, bulletY), Offset(bulletX + 22, bulletY),
          Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5..strokeCap = StrokeCap.round);
      _text(canvas, 'v₀', Offset(bulletX + 24, bulletY - 7),
          const TextStyle(color: Color(0xFF64FF8C), fontSize: 8));
    } else if (phase == 1) {
      // Collision flash
      canvas.drawCircle(Offset(blockX, blockY), 16,
          Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.35));
      _text(canvas, '충돌!', Offset(blockX - 16, blockY - 28),
          const TextStyle(color: Color(0xFFFFD700), fontSize: 9, fontWeight: FontWeight.bold));
    } else {
      // Embedded bullet in block
      canvas.drawOval(
        Rect.fromCenter(center: Offset(blockX - 4, blockY), width: 8, height: 4),
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.7),
      );
    }

    // Height rise indicator
    if (phase == 2 && swingAngle.abs() > 0.01) {
      final topY = blockY - rodLen * (1 - math.cos(swingAngle));
      canvas.drawLine(Offset(blockX + 20, topY), Offset(blockX + 20, blockY),
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..strokeWidth = 1.2);
      _text(canvas, 'h', Offset(blockX + 23, (topY + blockY) / 2 - 5),
          const TextStyle(color: Color(0xFF00D4FF), fontSize: 8));
    }

    // Gun on left
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.02, blockY - 7, 26, 14), const Radius.circular(2)),
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.6),
    );

    _text(canvas, '탄도 진자', Offset(4, 4),
        const TextStyle(color: Color(0xFF00D4FF), fontSize: 10, fontWeight: FontWeight.bold));

    // ── RIGHT PANEL: momentum & energy comparison ────────────
    final panX = w * 0.06;
    final panY = pivotY + rodLen + 22;
    final panH = h - panY - 8;
    // Momentum before/after
    final p0 = projMass * projVel;
    final panelItems = [
      ('탄환 운동량', '${p0.toStringAsFixed(1)} kg·m/s', const Color(0xFF64FF8C)),
      ('충돌 후 속도', '${vAfter.toStringAsFixed(2)} m/s', const Color(0xFF00D4FF)),
      ('상승 높이', '${heightRise.toStringAsFixed(3)} m', const Color(0xFFFF6B35)),
      ('에너지 손실', '${((1 - totalMass * vAfter * vAfter / (projMass * projVel * projVel)) * 100).toStringAsFixed(0)}%', const Color(0xFFFFD700)),
    ];

    final rowH = panH / (panelItems.length + 0.5);
    for (int i = 0; i < panelItems.length; i++) {
      final item = panelItems[i];
      final ry = panY + i * rowH;
      _text(canvas, item.$1, Offset(panX, ry),
          const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));
      _text(canvas, item.$2, Offset(panX, ry + rowH * 0.48),
          TextStyle(color: item.$3, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'));
    }

    // Formula
    _text(canvas, 'v₀ = (m+M)/m · √(2gh)',
        Offset(w / 2 - 60, h - 14),
        const TextStyle(color: Color(0xFF5A8A9A), fontSize: 8));
  }

  void _text(Canvas canvas, String t, Offset o, TextStyle s) {
    final tp = TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant _BallisticPendulumScreenPainter oldDelegate) => true;
}
