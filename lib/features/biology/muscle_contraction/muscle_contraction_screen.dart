import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class MuscleContractionScreen extends StatefulWidget {
  const MuscleContractionScreen({super.key});
  @override
  State<MuscleContractionScreen> createState() => _MuscleContractionScreenState();
}

class _MuscleContractionScreenState extends State<MuscleContractionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _stimulus = 50;
  
  double _force = 0, _sarcomereLen = 2.5;

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
      _force = _stimulus > 30 ? (_stimulus - 30) * 1.5 : 0;
      _sarcomereLen = 2.5 - _force * 0.01;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _stimulus = 50.0;
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
          const Text('근육 수축', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '근육 수축',
          formula: 'Actin + Myosin + ATP',
          formulaDescription: '근섬유의 활주 메커니즘을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _MuscleContractionScreenPainter(
                time: _time,
                stimulus: _stimulus,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '자극 강도 (mV)',
                value: _stimulus,
                min: 0,
                max: 100,
                step: 1,
                defaultValue: 50,
                formatValue: (v) => v.toStringAsFixed(0) + ' mV',
                onChanged: (v) => setState(() => _stimulus = v),
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
          _V('힘', _force.toStringAsFixed(1) + ' N'),
          _V('근절편', _sarcomereLen.toStringAsFixed(2) + ' μm'),
          _V('자극', _stimulus.toStringAsFixed(0) + ' mV'),
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

class _MuscleContractionScreenPainter extends CustomPainter {
  final double time;
  final double stimulus;

  _MuscleContractionScreenPainter({
    required this.time,
    required this.stimulus,
  });

  void _lbl(Canvas canvas, String text, Offset pos, Color color, double fs) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Contraction factor 0..1 based on stimulus
    final contracting = stimulus > 30;
    final contractFactor = contracting ? ((stimulus - 30) / 70.0).clamp(0.0, 1.0) : 0.0;
    // Animate cross-bridge cycling
    final cyclePhase = contracting ? (time * contractFactor * 1.5) % 1.0 : 0.0;

    // ── Sarcomere diagram (upper 58%) ────────────────────────────────────
    final sarTop = 26.0;
    final sarBottom = h * 0.60;
    final sarCy = (sarTop + sarBottom) / 2;
    final sarH = sarBottom - sarTop;

    // Sarcomere full width and contracted width
    final fullHalfW = w * 0.44;
    final contractedHalfW = fullHalfW * (1.0 - contractFactor * 0.28);
    final sarLeft = cx - contractedHalfW;
    final sarRight = cx + contractedHalfW;

    // Z-lines (dark cyan bars at ends)
    final zPaint = Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 3.5;
    canvas.drawLine(Offset(sarLeft, sarTop + 4), Offset(sarLeft, sarBottom - 4), zPaint);
    canvas.drawLine(Offset(sarRight, sarTop + 4), Offset(sarRight, sarBottom - 4), zPaint);
    _lbl(canvas, 'Z선', Offset(sarLeft, sarTop - 6), const Color(0xFF00D4FF), 7.5);
    _lbl(canvas, 'Z선', Offset(sarRight, sarTop - 6), const Color(0xFF00D4FF), 7.5);

    // Actin filaments (thin, light green) from Z-lines inward
    final actinLen = contractedHalfW * 0.62;
    final actinThick = sarH * 0.12;
    final actinRows = [-sarH * 0.22, sarH * 0.22];
    for (final dy in actinRows) {
      // Left actin
      canvas.drawRect(
        Rect.fromLTWH(sarLeft, sarCy + dy - actinThick / 2, actinLen, actinThick),
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.7),
      );
      // Right actin
      canvas.drawRect(
        Rect.fromLTWH(sarRight - actinLen, sarCy + dy - actinThick / 2, actinLen, actinThick),
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.7),
      );
    }
    _lbl(canvas, '액틴\n(Actin)', Offset(sarLeft + actinLen * 0.35, sarCy + actinRows[0] + actinThick + 7), const Color(0xFF64FF8C), 7);

    // Myosin filament (thick, orange, centered)
    final myoHalfW = contractedHalfW * 0.55;
    final myoThick = sarH * 0.22;
    canvas.drawRect(
      Rect.fromLTWH(cx - myoHalfW, sarCy - myoThick / 2, myoHalfW * 2, myoThick),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.75),
    );
    // M-line
    canvas.drawLine(Offset(cx, sarTop + 4), Offset(cx, sarBottom - 4),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)..strokeWidth = 1.5);
    _lbl(canvas, 'M선', Offset(cx, sarTop - 6), const Color(0xFFFF6B35), 7.5);
    _lbl(canvas, '마이오신\n(Myosin)', Offset(cx, sarCy + myoThick / 2 + 9), const Color(0xFFFF6B35), 7);

    // Myosin heads (cross-bridges) animated
    final headCount = 6;
    for (int i = 0; i < headCount; i++) {
      final side = i < headCount ~/ 2 ? -1.0 : 1.0;
      final idx = i % (headCount ~/ 2);
      final hx = cx + side * (myoHalfW * 0.15 + idx * myoHalfW * 0.26);
      final baseY = sarCy + (side > 0 ? 1 : -1) * myoThick * 0.5;
      // Head swings during cycling
      final swing = math.sin(cyclePhase * 2 * math.pi + idx * 1.2) * 0.4 + 0.5;
      final actinY = sarCy + (side > 0 ? 1 : -1) * actinRows[side > 0 ? 1 : 0].abs() - actinThick * 0.3;
      final headY = baseY + (actinY - baseY) * swing * contractFactor;
      canvas.drawLine(Offset(hx, baseY), Offset(hx, headY),
          Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.75)..strokeWidth = 1.8);
      canvas.drawCircle(Offset(hx, headY), 3.5,
          Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.9));
    }

    // Band labels
    // I-band (left, between Z-line and A-band start)
    final iBandW = contractedHalfW - myoHalfW;
    if (iBandW > 8) {
      _lbl(canvas, 'I대', Offset(sarLeft + iBandW / 2, sarCy), const Color(0xFF5A8A9A), 7.5);
      _lbl(canvas, 'I대', Offset(sarRight - iBandW / 2, sarCy), const Color(0xFF5A8A9A), 7.5);
    }
    _lbl(canvas, 'A대', Offset(cx, sarCy), const Color(0xFF9ECFDE), 7.5);
    // H-zone (center of myosin, shrinks on contraction)
    final hZoneW = (myoHalfW * 2 - actinLen * 2).clamp(0.0, myoHalfW);
    if (hZoneW > 8) {
      _lbl(canvas, 'H대', Offset(cx, sarCy - sarH * 0.07), const Color(0xFF3A8A6A), 7);
    }

    // ATP counter
    final atpUsed = (cyclePhase * 3).toInt();
    _lbl(canvas, 'ATP ×$atpUsed 소모', Offset(cx, sarBottom + 10), const Color(0xFF64FF8C), 8.5);

    // Divider
    canvas.drawLine(Offset(0, sarBottom + 20), Offset(w, sarBottom + 20),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    // ── Cross-bridge cycle diagram (lower) ───────────────────────────────
    final cbTop = sarBottom + 24.0;
    final cbH = h - cbTop - 10;
    final cbCx = w / 2;
    final cbCy = cbTop + cbH / 2;
    final cbR = cbH * 0.34;

    // 4-step cycle nodes
    final stepNames = ['결합\nAttach', 'Power\nStroke', '해리\nDetach', 'ATP\n재충전'];
    final stepColors = [
      const Color(0xFF00D4FF),
      const Color(0xFF64FF8C),
      const Color(0xFFFF6B35),
      const Color(0xFFFFD700),
    ];
    for (int i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final sx = cbCx + cbR * math.cos(a);
      final sy = cbCy + cbR * math.sin(a);
      final active = (cyclePhase * 4).floor() % 4 == i;
      canvas.drawCircle(Offset(sx, sy), 14, Paint()..color = stepColors[i].withValues(alpha: active ? 0.3 : 0.1));
      canvas.drawCircle(Offset(sx, sy), 14, Paint()..color = stepColors[i]..style = PaintingStyle.stroke..strokeWidth = active ? 2 : 1);
      final lines2 = stepNames[i].split('\n');
      for (int l = 0; l < lines2.length; l++) {
        _lbl(canvas, lines2[l], Offset(sx, sy + (l - (lines2.length - 1) / 2) * 8), stepColors[i], 6.5);
      }
      // Arrow to next
      final ax = cbCx + cbR * math.cos(a + math.pi / 4) * 0.95;
      final ay = cbCy + cbR * math.sin(a + math.pi / 4) * 0.95;
      final arrowAngle = a + math.pi / 4 + math.pi / 2;
      final arHead = Path()
        ..moveTo(ax, ay)
        ..lineTo(ax - 6 * math.cos(arrowAngle - 0.4), ay - 6 * math.sin(arrowAngle - 0.4))
        ..lineTo(ax - 6 * math.cos(arrowAngle + 0.4), ay - 6 * math.sin(arrowAngle + 0.4))
        ..close();
      canvas.drawPath(arHead, Paint()..color = stepColors[i].withValues(alpha: 0.6)..style = PaintingStyle.fill);
    }

    // Title
    _lbl(canvas, '근육 수축 (Sliding Filament)', Offset(w / 2, 11), const Color(0xFF00D4FF), 10);
  }

  @override
  bool shouldRepaint(covariant _MuscleContractionScreenPainter oldDelegate) => true;
}
