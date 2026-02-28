import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ZTransformScreen extends StatefulWidget {
  const ZTransformScreen({super.key});
  @override
  State<ZTransformScreen> createState() => _ZTransformScreenState();
}

class _ZTransformScreenState extends State<ZTransformScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _pole = 0.5;
  double _poleAngle = 45;
  double _isStable = 1.0;

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
      _isStable = _pole < 1.0 ? 1.0 : 0.0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _pole = 0.5; _poleAngle = 45.0;
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
          const Text('Z-변환', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: 'Z-변환',
          formula: 'X(z) = Σ x[n]z^(-n)',
          formulaDescription: '이산 신호의 Z-변환을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ZTransformScreenPainter(
                time: _time,
                pole: _pole,
                poleAngle: _poleAngle,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '극점 반지름',
                value: _pole,
                min: 0,
                max: 0.99,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _pole = v),
              ),
              advancedControls: [
            SimSlider(
                label: '극점 각도 (°)',
                value: _poleAngle,
                min: 0,
                max: 180,
                step: 1,
                defaultValue: 45,
                formatValue: (v) => v.toStringAsFixed(0) + '°',
                onChanged: (v) => setState(() => _poleAngle = v),
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
          _V('|z|', _pole.toStringAsFixed(2)),
          _V('각도', _poleAngle.toStringAsFixed(0) + '°'),
          _V('안정', _isStable > 0.5 ? '예' : '아니오'),
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

class _ZTransformScreenPainter extends CustomPainter {
  final double time;
  final double pole;
  final double poleAngle;

  _ZTransformScreenPainter({
    required this.time,
    required this.pole,
    required this.poleAngle,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 10}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padT = 26.0;
    // Upper 2/3: z-plane, lower 1/3: stem plot
    final planeH = (size.height - padT) * 0.65;
    final stemH  = (size.height - padT) * 0.30;
    final stemTop = padT + planeH + (size.height - padT) * 0.05;

    final cx = size.width / 2;
    final cy = padT + planeH / 2;
    final unitR = planeH * 0.38;

    // Background grid
    final gridP = Paint()..color = AppColors.simGrid.withValues(alpha: 0.2)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) { canvas.drawLine(Offset(x, padT), Offset(x, padT + planeH), gridP); }
    for (double y = padT; y < padT + planeH; y += 28) { canvas.drawLine(Offset(0, y), Offset(size.width, y), gridP); }

    // ROC regions
    // Inside unit circle = cyan tint (stable), outside = orange tint (unstable)
    canvas.drawCircle(Offset(cx, cy), unitR,
      Paint()..color = AppColors.accent.withValues(alpha: 0.06));
    canvas.drawRect(Rect.fromLTWH(0, padT, size.width, planeH),
      Paint()..color = AppColors.accent2.withValues(alpha: 0.04));
    canvas.drawCircle(Offset(cx, cy), unitR,
      Paint()..color = AppColors.accent.withValues(alpha: 0.10));

    // Axes
    final axP = Paint()..color = AppColors.muted.withValues(alpha: 0.5)..strokeWidth = 0.8;
    canvas.drawLine(Offset(8, cy), Offset(size.width - 8, cy), axP);
    canvas.drawLine(Offset(cx, padT + 4), Offset(cx, padT + planeH - 4), axP);

    // Glowing unit circle
    final pulse = 0.7 + 0.3 * math.sin(time * 1.5);
    for (int i = 3; i >= 1; i--) {
      canvas.drawCircle(Offset(cx, cy), unitR + i * 2.5,
        Paint()..color = AppColors.accent.withValues(alpha: 0.04 * i * pulse)
               ..style = PaintingStyle.stroke..strokeWidth = 1.0);
    }
    canvas.drawCircle(Offset(cx, cy), unitR,
      Paint()..color = AppColors.accent.withValues(alpha: 0.85 * pulse)
             ..style = PaintingStyle.stroke..strokeWidth = 2.0);

    // Pole positions (conjugate pair)
    final angleRad = poleAngle * math.pi / 180;
    final poleR = pole * unitR;
    final polePositions = [
      Offset(cx + poleR * math.cos(angleRad),  cy - poleR * math.sin(angleRad)),
      Offset(cx + poleR * math.cos(-angleRad), cy - poleR * math.sin(-angleRad)),
    ];
    final isStable = pole < 1.0;
    final poleColor = isStable ? AppColors.accent : const Color(0xFFFF4444);

    for (final p in polePositions) {
      // Pulsing glow
      final pulseMag = 0.5 + 0.5 * math.sin(time * 2.5);
      for (int i = 3; i >= 1; i--) {
        canvas.drawCircle(p, 4.0 + i * 3,
          Paint()..color = poleColor.withValues(alpha: 0.08 * i * pulseMag));
      }
      // X mark
      final xP = Paint()..color = poleColor..strokeWidth = 2.2..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(p.dx - 6, p.dy - 6), Offset(p.dx + 6, p.dy + 6), xP);
      canvas.drawLine(Offset(p.dx + 6, p.dy - 6), Offset(p.dx - 6, p.dy + 6), xP);
    }

    // Zero at origin: cyan circle
    canvas.drawCircle(Offset(cx, cy), 5,
      Paint()..color = AppColors.accent..style = PaintingStyle.stroke..strokeWidth = 2);

    // Labels
    _drawLabel(canvas, 'Z-평면', Offset(8, 8), AppColors.ink, fontSize: 11);
    _drawLabel(canvas, '단위원', Offset(cx + unitR + 3, cy - 10), AppColors.accent, fontSize: 9);
    _drawLabel(canvas, isStable ? '안정 (|z|<1)' : '불안정 (|z|>1)',
      Offset(8, padT + 4), isStable ? AppColors.accent : const Color(0xFFFF4444), fontSize: 9);
    _drawLabel(canvas, 'Re', Offset(size.width - 20, cy - 12), AppColors.muted, fontSize: 9);
    _drawLabel(canvas, 'Im', Offset(cx + 4, padT + 4), AppColors.muted, fontSize: 9);

    // ---- STEM PLOT: h[n] causal impulse response ----
    final stemCy = stemTop + stemH / 2;
    final stemLeft = 16.0;
    final stemRight = size.width - 16.0;
    final nCount = 12;
    final stemSpacing = (stemRight - stemLeft) / nCount;

    canvas.drawLine(Offset(stemLeft, stemCy), Offset(stemRight, stemCy),
      Paint()..color = AppColors.muted.withValues(alpha: 0.4)..strokeWidth = 0.8);

    for (int n = 0; n < nCount; n++) {
      final t = n.toDouble();
      final val = math.pow(pole, t) * math.cos(angleRad * t);
      final px = stemLeft + n * stemSpacing + stemSpacing / 2;
      final barH = val * stemH * 0.42;
      final barColor = n == 0 ? AppColors.accent2 : AppColors.accent;
      canvas.drawLine(Offset(px, stemCy), Offset(px, stemCy - barH),
        Paint()..color = barColor.withValues(alpha: 0.85)..strokeWidth = 2);
      canvas.drawCircle(Offset(px, stemCy - barH), 3,
        Paint()..color = barColor);
    }
    _drawLabel(canvas, 'h[n] 임펄스 응답', Offset(stemLeft, stemTop - 2), AppColors.muted, fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _ZTransformScreenPainter oldDelegate) => true;
}
