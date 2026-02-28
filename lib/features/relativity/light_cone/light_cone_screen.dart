import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class LightConeScreen extends StatefulWidget {
  const LightConeScreen({super.key});
  @override
  State<LightConeScreen> createState() => _LightConeScreenState();
}

class _LightConeScreenState extends State<LightConeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _eventX = 0;
  double _eventT = 0;
  String _region = "현재";

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
      final ds2 = -_eventT * _eventT + _eventX * _eventX;
      _region = ds2 < 0 ? (_eventT > 0 ? "미래 빛원뿔" : "과거 빛원뿔") : "공간적 영역";
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _eventX = 0.0; _eventT = 0.0;
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
          const Text('빛 원뿔 다이어그램', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '빛 원뿔 다이어그램',
          formula: 'ds² = -c²dt² + dx²',
          formulaDescription: '시공간 빛 원뿔과 인과 구조를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _LightConeScreenPainter(
                time: _time,
                eventX: _eventX,
                eventT: _eventT,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '사건 x 좌표',
                value: _eventX,
                min: -5,
                max: 5,
                step: 0.1,
                defaultValue: 0,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _eventX = v),
              ),
              advancedControls: [
            SimSlider(
                label: '사건 t 좌표',
                value: _eventT,
                min: -5,
                max: 5,
                step: 0.1,
                defaultValue: 0,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _eventT = v),
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
          _V('ds²', (-_eventT * _eventT + _eventX * _eventX).toStringAsFixed(2)),
          _V('영역', _region),
          _V('(x,t)', '(${_eventX.toStringAsFixed(1)}, ${_eventT.toStringAsFixed(1)})'),
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

class _LightConeScreenPainter extends CustomPainter {
  final double time;
  final double eventX;
  final double eventT;

  _LightConeScreenPainter({
    required this.time,
    required this.eventX,
    required this.eventT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final cx = size.width / 2;
    final cy = size.height / 2;
    // scale: pixels per unit
    final scl = math.min(size.width, size.height) * 0.38;

    // Clip to canvas bounds
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // --- Fill causal regions ---
    // Future light cone interior (above, |x| < t, t>0) → cyan semi
    final futurePath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - size.width, cy - size.width)
      ..lineTo(cx + size.width, cy - size.width)
      ..close();
    canvas.drawPath(
        futurePath,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.08));

    // Past light cone interior (below) → muted semi
    final pastPath = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - size.width, cy + size.width)
      ..lineTo(cx + size.width, cy + size.width)
      ..close();
    canvas.drawPath(
        pastPath,
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.10));

    // Spacelike regions (left & right) → grey semi
    final slLeft = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx - size.width, cy - size.width)
      ..lineTo(cx - size.width, cy + size.width)
      ..close();
    final slRight = Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + size.width, cy - size.width)
      ..lineTo(cx + size.width, cy + size.width)
      ..close();
    final slPaint = Paint()..color = const Color(0xFF2A3A40).withValues(alpha: 0.5);
    canvas.drawPath(slLeft, slPaint);
    canvas.drawPath(slRight, slPaint);

    // --- Grid lines (coordinate grid) ---
    final gridPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..strokeWidth = 0.5;
    for (int i = -5; i <= 5; i++) {
      final px = cx + i * scl / 2;
      canvas.drawLine(Offset(px, 0), Offset(px, size.height), gridPaint);
      final py = cy + i * scl / 2;
      canvas.drawLine(Offset(0, py), Offset(size.width, py), gridPaint);
    }

    // --- Axes ---
    final axisPaint = Paint()
      ..color = const Color(0xFF5A8A9A)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), axisPaint); // x-axis
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), axisPaint); // ct-axis

    // --- Light cone lines: ct = ±x ---
    final conePaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(cx - size.width, cy + size.width),
        Offset(cx + size.width, cy - size.width),
        conePaint);
    canvas.drawLine(
        Offset(cx - size.width, cy - size.width),
        Offset(cx + size.width, cy + size.width),
        conePaint);

    // --- World line: material particle (subluminal, ~v=0.5c slope) ---
    final worldLinePaint = Paint()
      ..color = const Color(0xFF64FF8C)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(cx - size.width * 0.3, cy + size.height * 0.4),
        Offset(cx + size.width * 0.3, cy - size.height * 0.4),
        worldLinePaint);

    // --- World line: photon (45°) already shown by cone lines, add label ---

    // --- Event point (user-controlled) ---
    // Map eventX/eventT from [-5,5] to canvas
    final evX = cx + eventX * scl / 2;
    final evT = cy - eventT * scl / 2;
    final ds2 = -eventT * eventT + eventX * eventX;
    final evColor = ds2 < 0
        ? (eventT > 0
            ? const Color(0xFF00D4FF)
            : const Color(0xFF5A8A9A))
        : const Color(0xFFFF6B35);

    // Dashed lines from origin to event
    final dashPaint = Paint()
      ..color = evColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final dashPath = Path();
    for (double t2 = 0; t2 <= 1.0; t2 += 0.1) {
      if (t2 % 0.2 < 0.1) {
        dashPath.moveTo(cx + (evX - cx) * t2, cy + (evT - cy) * t2);
        dashPath.lineTo(cx + (evX - cx) * (t2 + 0.08), cy + (evT - cy) * (t2 + 0.08));
      }
    }
    canvas.drawPath(dashPath, dashPaint);

    // Event dot
    canvas.drawCircle(Offset(evX, evT), 6, Paint()..color = evColor);
    canvas.drawCircle(
        Offset(evX, evT),
        8,
        Paint()
          ..color = evColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    // Origin event O
    canvas.drawCircle(
        Offset(cx, cy),
        5,
        Paint()
          ..color = const Color(0xFFE0F4FF)
          ..style = PaintingStyle.fill);
    // Glow
    canvas.drawCircle(
        Offset(cx, cy),
        9,
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: 0.25)
          ..style = PaintingStyle.fill);

    canvas.restore();

    // --- Labels ---
    void drawText(String txt, Offset pos,
        {Color color = const Color(0xFF5A8A9A), double fs = 9}) {
      final tp = TextPainter(
        text: TextSpan(text: txt, style: TextStyle(color: color, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos);
    }

    drawText('ct', Offset(cx + 4, 4), color: const Color(0xFF5A8A9A), fs: 10);
    drawText('x', Offset(size.width - 14, cy + 4), color: const Color(0xFF5A8A9A), fs: 10);
    drawText('미래', Offset(cx + 4, cy - size.height * 0.35), color: const Color(0xFF00D4FF), fs: 9);
    drawText('과거', Offset(cx + 4, cy + size.height * 0.28), color: const Color(0xFF5A8A9A), fs: 9);
    drawText('공간적', Offset(8, cy - 10), color: const Color(0xFFFF6B35), fs: 8);
    drawText('O', Offset(cx + 6, cy - 14), color: const Color(0xFFE0F4FF), fs: 9);
    drawText('세계선', Offset(cx - 48, cy - size.height * 0.3), color: const Color(0xFF64FF8C), fs: 8);
    // Event label
    final regionLabel = ds2 < 0
        ? (eventT > 0 ? '미래 빛원뿔' : '과거 빛원뿔')
        : '공간적 영역';
    final labelX = (evX + 8).clamp(0.0, size.width - 60.0);
    final labelY = (evT - 14).clamp(4.0, size.height - 20.0);
    drawText(regionLabel, Offset(labelX, labelY), color: evColor, fs: 8);
  }

  @override
  bool shouldRepaint(covariant _LightConeScreenPainter oldDelegate) => true;
}
