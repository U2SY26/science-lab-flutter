import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class LaplaceTransformScreen extends StatefulWidget {
  const LaplaceTransformScreen({super.key});
  @override
  State<LaplaceTransformScreen> createState() => _LaplaceTransformScreenState();
}

class _LaplaceTransformScreenState extends State<LaplaceTransformScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _sReal = 1;
  double _frequency = 1;
  double _magnitude = 1.0, _phase = 0.0;

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
      final omega = 2 * math.pi * _frequency;
      _magnitude = 1.0 / math.sqrt(_sReal * _sReal + omega * omega);
      _phase = -math.atan2(omega, _sReal) * 180 / math.pi;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _sReal = 1.0; _frequency = 1.0;
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
          Text('수학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('라플라스 변환', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '라플라스 변환',
          formula: 'F(s) = ∫₀∞ f(t)e^(-st)dt',
          formulaDescription: '시간 영역 함수를 s-영역으로 변환합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _LaplaceTransformScreenPainter(
                time: _time,
                sReal: _sReal,
                frequency: _frequency,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 's (실수부)',
                value: _sReal,
                min: 0.1,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _sReal = v),
              ),
              advancedControls: [
            SimSlider(
                label: '주파수 (Hz)',
                value: _frequency,
                min: 0.1,
                max: 10,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' Hz',
                onChanged: (v) => setState(() => _frequency = v),
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
          _V('|F(s)|', _magnitude.toStringAsFixed(3)),
          _V('위상', _phase.toStringAsFixed(1) + '°'),
          _V('s', _sReal.toStringAsFixed(1)),
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

class _LaplaceTransformScreenPainter extends CustomPainter {
  final double time;
  final double sReal;
  final double frequency;

  _LaplaceTransformScreenPainter({
    required this.time,
    required this.sReal,
    required this.frequency,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final halfW = size.width / 2;
    final padT = 26.0, padB = 10.0;
    final plotH = size.height - padT - padB;

    // ---- LEFT PANEL: time-domain signal ----
    final leftRect = Rect.fromLTWH(8, padT, halfW - 14, plotH);
    canvas.drawRRect(RRect.fromRectAndRadius(leftRect, const Radius.circular(6)),
      Paint()..color = AppColors.simGrid.withValues(alpha: 0.18));

    final lCy = leftRect.top + leftRect.height / 2;

    // Axes
    final axP = Paint()..color = AppColors.muted.withValues(alpha: 0.5)..strokeWidth = 0.8;
    canvas.drawLine(Offset(leftRect.left + 4, lCy), Offset(leftRect.right - 4, lCy), axP);
    canvas.drawLine(Offset(leftRect.left + 20, leftRect.top + 4), Offset(leftRect.left + 20, leftRect.bottom - 4), axP);

    // Scan line (moving) — animate transform "happening"
    final scanX = leftRect.left + 20 + (leftRect.width - 24) * ((time * 0.25) % 1.0);
    canvas.drawLine(Offset(scanX, leftRect.top + 4), Offset(scanX, leftRect.bottom - 4),
      Paint()..color = AppColors.accent2.withValues(alpha: 0.5)..strokeWidth = 1.5);

    // Plot f(t) = e^(-a*t)*cos(w*t)
    final a = sReal.clamp(0.1, 5.0);
    final omega = 2 * math.pi * frequency;
    final tScale = leftRect.width - 24;
    final ampScale = leftRect.height * 0.38;
    final path = Path();
    bool first = true;
    for (int i = 0; i <= 200; i++) {
      final t = i / 200.0 * 5.0;
      final val = math.exp(-a * t) * math.cos(omega * t);
      final px = leftRect.left + 20 + (t / 5.0) * tScale;
      final py = lCy - val * ampScale;
      if (first) { path.moveTo(px, py); first = false; }
      else { path.lineTo(px, py); }
    }
    canvas.drawPath(path, Paint()..color = AppColors.accent..strokeWidth = 1.8..style = PaintingStyle.stroke);

    // ---- RIGHT PANEL: s-plane ----
    final rightRect = Rect.fromLTWH(halfW + 6, padT, halfW - 14, plotH);
    canvas.drawRRect(RRect.fromRectAndRadius(rightRect, const Radius.circular(6)),
      Paint()..color = AppColors.simGrid.withValues(alpha: 0.18));

    final rCx = rightRect.left + rightRect.width * 0.45;
    final rCy = rightRect.top + rightRect.height / 2;
    final scale = math.min(rightRect.width, rightRect.height) * 0.12;

    // ROC: shaded green region (Re(s) > -a)
    final rocX = rCx - a * scale;
    canvas.drawRect(Rect.fromLTRB(rocX, rightRect.top + 4, rightRect.right - 4, rightRect.bottom - 4),
      Paint()..color = const Color(0xFF00FF88).withValues(alpha: 0.07));

    // Axes
    canvas.drawLine(Offset(rightRect.left + 4, rCy), Offset(rightRect.right - 4, rCy), axP);
    canvas.drawLine(Offset(rCx, rightRect.top + 4), Offset(rCx, rightRect.bottom - 4), axP);

    // Grid lines on s-plane
    final sGridP = Paint()..color = AppColors.simGrid.withValues(alpha: 0.25)..strokeWidth = 0.5;
    for (int i = -3; i <= 3; i++) {
      if (i == 0) continue;
      final gx = rCx + i * scale;
      final gy = rCy + i * scale;
      canvas.drawLine(Offset(gx, rightRect.top + 4), Offset(gx, rightRect.bottom - 4), sGridP);
      canvas.drawLine(Offset(rightRect.left + 4, gy), Offset(rightRect.right - 4, gy), sGridP);
    }

    // Poles: red X at s = -a ± jω
    final polePositions = [
      Offset(rCx - a * scale, rCy - (omega / (2 * math.pi)) * scale),
      Offset(rCx - a * scale, rCy + (omega / (2 * math.pi)) * scale),
    ];
    final polePaint = Paint()..color = const Color(0xFFFF4444)..strokeWidth = 2.2..strokeCap = StrokeCap.round;
    for (final p in polePositions) {
      if (!rightRect.contains(p)) continue;
      canvas.drawLine(Offset(p.dx - 5, p.dy - 5), Offset(p.dx + 5, p.dy + 5), polePaint);
      canvas.drawLine(Offset(p.dx + 5, p.dy - 5), Offset(p.dx - 5, p.dy + 5), polePaint);
    }

    // Zero: cyan circle at s = 0 (origin)
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(Offset(rCx, rCy), 4.0 + i * 1.5,
        Paint()..color = AppColors.accent.withValues(alpha: 0.1 * i)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    }
    canvas.drawCircle(Offset(rCx, rCy), 4,
      Paint()..color = AppColors.accent..style = PaintingStyle.stroke..strokeWidth = 2);

    // Labels
    _drawLabel(canvas, 'f(t) 시간 영역', Offset(leftRect.left + 4, leftRect.top + 2), AppColors.ink, fontSize: 9);
    _drawLabel(canvas, 's-평면 (ROC 녹색)', Offset(rightRect.left + 4, rightRect.top + 2), AppColors.ink, fontSize: 9);
    _drawLabel(canvas, 'σ', Offset(rightRect.right - 12, rCy - 12), AppColors.muted, fontSize: 9);
    _drawLabel(canvas, 'jω', Offset(rCx + 3, rightRect.top + 4), AppColors.muted, fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _LaplaceTransformScreenPainter oldDelegate) => true;
}
