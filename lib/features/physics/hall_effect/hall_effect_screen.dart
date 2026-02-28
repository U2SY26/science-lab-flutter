import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class HallEffectScreen extends StatefulWidget {
  const HallEffectScreen({super.key});
  @override
  State<HallEffectScreen> createState() => _HallEffectScreenState();
}

class _HallEffectScreenState extends State<HallEffectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _currentVal = 1;
  double _bField = 0.5;
  double _hallV = 0.0;

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
      _hallV = _currentVal * _bField / (8.5e28 * 1.6e-19 * 0.001) * 1e6;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _currentVal = 1.0; _bField = 0.5;
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
          const Text('홀 효과', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '홀 효과',
          formula: 'V_H = IB/nqt',
          formulaDescription: '자기장에서의 홀 효과와 홀 전압을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _HallEffectScreenPainter(
                time: _time,
                currentVal: _currentVal,
                bField: _bField,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '전류 (A)',
                value: _currentVal,
                min: 0.1,
                max: 10,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' A',
                onChanged: (v) => setState(() => _currentVal = v),
              ),
              advancedControls: [
            SimSlider(
                label: '자기장 (T)',
                value: _bField,
                min: 0.01,
                max: 2,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2) + ' T',
                onChanged: (v) => setState(() => _bField = v),
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
          _V('V_H', _hallV.toStringAsFixed(3) + ' μV'),
          _V('I', _currentVal.toStringAsFixed(1) + ' A'),
          _V('B', _bField.toStringAsFixed(2) + ' T'),
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

class _HallEffectScreenPainter extends CustomPainter {
  final double time;
  final double currentVal;
  final double bField;

  _HallEffectScreenPainter({
    required this.time,
    required this.currentVal,
    required this.bField,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Grid
    final gridPaint = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.4)..strokeWidth = 0.5;
    for (double x = 0; x < w; x += 30) { canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint); }
    for (double y = 0; y < h; y += 30) { canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint); }

    // --- Rectangular conductor ---
    final condLeft = w * 0.12;
    final condTop = h * 0.28;
    final condW = w * 0.76;
    final condH = h * 0.38;
    final condRight = condLeft + condW;
    final condBottom = condTop + condH;
    final condCy = condTop + condH / 2;

    canvas.drawRect(
      Rect.fromLTWH(condLeft, condTop, condW, condH),
      Paint()..color = const Color(0xFF1A2535),
    );
    canvas.drawRect(
      Rect.fromLTWH(condLeft, condTop, condW, condH),
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke,
    );

    // --- B field symbols (into screen = X, or out = dots) ---
    // B field out of screen (dots)
    final bRows = 3, bCols = 5;
    for (int r = 0; r < bRows; r++) {
      for (int c = 0; c < bCols; c++) {
        final bx = condLeft + (c + 0.5) * condW / bCols;
        final by = condTop + (r + 0.5) * condH / bRows;
        canvas.drawCircle(
          Offset(bx, by),
          3.5,
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.25 + bField * 0.15),
        );
        canvas.drawCircle(
          Offset(bx, by),
          1.2,
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6 + bField * 0.2),
        );
      }
    }

    // B field label
    _drawLabel(canvas, 'B (지면 밖)', Offset(w * 0.5, condTop - 16), const Color(0xFF00D4FF), 9);

    // --- Current flow (left → right) animated dots ---
    final numCurrentDots = (currentVal * 3 + 3).round().clamp(3, 12);
    for (int i = 0; i < numCurrentDots; i++) {
      final phase = (time * 0.8 + i / numCurrentDots) % 1.0;
      final dx = condLeft + phase * condW;
      final dy = condCy + (i % 3 - 1) * condH * 0.18;
      canvas.drawCircle(
        Offset(dx, dy),
        3,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.85),
      );
    }
    // Current arrows
    canvas.drawLine(Offset(condLeft - 22, condCy), Offset(condLeft, condCy), Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
    canvas.drawLine(Offset(condLeft - 8, condCy - 5), Offset(condLeft, condCy), Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
    canvas.drawLine(Offset(condLeft - 8, condCy + 5), Offset(condLeft, condCy), Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
    _drawLabel(canvas, 'I', Offset(condLeft - 30, condCy), const Color(0xFFFF6B35), 10);

    canvas.drawLine(Offset(condRight, condCy), Offset(condRight + 22, condCy), Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
    canvas.drawLine(Offset(condRight + 16, condCy - 5), Offset(condRight + 22, condCy), Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
    canvas.drawLine(Offset(condRight + 16, condCy + 5), Offset(condRight + 22, condCy), Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);

    // --- Hall voltage charge accumulation ---
    // Positive charges accumulate at bottom (for electrons in n-type with B out of screen)
    final hallV = currentVal * bField / (8.5e28 * 1.6e-19 * 0.001) * 1e6;
    final chargeAlpha = (hallV / 150.0).clamp(0.1, 0.8);
    // Bottom: + charges
    canvas.drawRect(
      Rect.fromLTWH(condLeft, condBottom - 6, condW, 6),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: chargeAlpha),
    );
    // Top: - charges
    canvas.drawRect(
      Rect.fromLTWH(condLeft, condTop, condW, 6),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: chargeAlpha),
    );

    // Charge symbols
    for (int i = 0; i < 5; i++) {
      final cx2 = condLeft + (i + 0.5) * condW / 5;
      _drawLabel(canvas, '+', Offset(cx2, condBottom - 3), const Color(0xFFFF6B35), 10);
      _drawLabel(canvas, '−', Offset(cx2, condTop + 4), const Color(0xFF00D4FF), 10);
    }

    // --- Hall voltage measurement (voltmeter) ---
    // Vertical measurement lines
    canvas.drawLine(Offset(w * 0.85, condTop), Offset(w * 0.85, condTop - 20), Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5);
    canvas.drawLine(Offset(w * 0.85, condBottom), Offset(w * 0.85, condBottom + 20), Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5);
    canvas.drawLine(Offset(w * 0.85, condTop - 20), Offset(w * 0.92, condTop - 20), Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5);
    canvas.drawLine(Offset(w * 0.85, condBottom + 20), Offset(w * 0.92, condBottom + 20), Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.5);
    // Voltmeter symbol
    canvas.drawCircle(Offset(w * 0.94, condCy), 12, Paint()..color = const Color(0xFF0D1A20));
    canvas.drawCircle(Offset(w * 0.94, condCy), 12, Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    _drawLabel(canvas, 'V', Offset(w * 0.94, condCy), const Color(0xFF64FF8C), 9);

    canvas.drawLine(Offset(w * 0.92, condTop - 20), Offset(w * 0.94, condCy - 12), Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1);
    canvas.drawLine(Offset(w * 0.92, condBottom + 20), Offset(w * 0.94, condCy + 12), Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1);

    // V_H label
    _drawLabel(canvas, 'V_H', Offset(condLeft - 28, condCy - condH * 0.3), const Color(0xFF64FF8C), 9);
    // Vertical double-arrow
    canvas.drawLine(Offset(condLeft - 28, condTop + 8), Offset(condLeft - 28, condBottom - 8), Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.5)..strokeWidth = 1);

    // --- Lorentz force arrows on carriers ---
    canvas.drawLine(Offset(w * 0.5, condCy), Offset(w * 0.5, condBottom - 8),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..strokeWidth = 1.5);
    canvas.drawLine(Offset(w * 0.5 - 4, condBottom - 16), Offset(w * 0.5, condBottom - 8), Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..strokeWidth = 1.5);
    canvas.drawLine(Offset(w * 0.5 + 4, condBottom - 16), Offset(w * 0.5, condBottom - 8), Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..strokeWidth = 1.5);
    _drawLabel(canvas, 'F=qv×B', Offset(w * 0.5, condCy + 6), const Color(0xFFFF6B35), 8);

    // --- Equation & values ---
    _drawLabel(canvas, 'V_H = IB/(nqt)', Offset(w * 0.35, h * 0.80), const Color(0xFFE0F4FF), 10);
    _drawLabel(canvas, '= ${hallV.toStringAsFixed(2)} μV', Offset(w * 0.35, h * 0.88), const Color(0xFF00D4FF), 10);
    _drawLabel(canvas, 'I=${currentVal.toStringAsFixed(1)}A  B=${bField.toStringAsFixed(2)}T', Offset(w * 0.70, h * 0.84), const Color(0xFF5A8A9A), 9);

    // Title
    _drawLabel(canvas, '홀 효과', Offset(w / 2, 14), const Color(0xFF00D4FF), 12, bold: true);
  }

  void _drawLabel(Canvas canvas, String text, Offset center, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _HallEffectScreenPainter oldDelegate) => true;
}
