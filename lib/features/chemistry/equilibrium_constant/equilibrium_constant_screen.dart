import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class EquilibriumConstantScreen extends StatefulWidget {
  const EquilibriumConstantScreen({super.key});
  @override
  State<EquilibriumConstantScreen> createState() => _EquilibriumConstantScreenState();
}

class _EquilibriumConstantScreenState extends State<EquilibriumConstantScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _kValue = 1;
  
  double _products = 0.5, _reactants = 0.5;

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
      _products = _kValue / (1 + _kValue);
      _reactants = 1 - _products;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _kValue = 1.0;
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
          Text('화학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('평형 상수', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '평형 상수',
          formula: 'K = [Products]/[Reactants]',
          formulaDescription: '화학 평형 상수와 반응 진행도를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _EquilibriumConstantScreenPainter(
                time: _time,
                kValue: _kValue,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'K (평형 상수)',
                value: _kValue,
                min: 0.001,
                max: 1000,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _kValue = v),
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
          _V('생성물', (_products * 100).toStringAsFixed(1) + '%'),
          _V('반응물', (_reactants * 100).toStringAsFixed(1) + '%'),
          _V('K', _kValue.toStringAsFixed(2)),
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

class _EquilibriumConstantScreenPainter extends CustomPainter {
  final double time;
  final double kValue;

  _EquilibriumConstantScreenPainter({
    required this.time,
    required this.kValue,
  });

  void _label(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 10, bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // A <-> B, K = [B]/[A]
    // At equilibrium: [B]eq = K/(1+K), [A]eq = 1/(1+K)
    final eqB = kValue / (1 + kValue);
    final eqA = 1 - eqB;

    // --- TOP HALF: ICE table ---
    const tableTop = 28.0;
    const tableH = 110.0;
    final tableW = w - 20;
    const padL = 10.0;

    // Table background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(padL, tableTop, tableW, tableH), const Radius.circular(6)),
      Paint()..color = const Color(0xFF1A3040),
    );

    // Header
    _label(canvas, 'ICE 테이블  (A ⇌ B)', Offset(padL + 8, tableTop + 6), const Color(0xFF00D4FF), fontSize: 10, bold: true);

    final colW = tableW / 4;
    final rowH = 22.0;
    final rows = [
      ['', 'A', 'B', '비고'],
      ['Initial', '1.00', '0.00', '초기'],
      ['Change', '−${eqA.toStringAsFixed(3)}', '+${eqB.toStringAsFixed(3)}', '변화'],
      ['Equil.', eqA.toStringAsFixed(3), eqB.toStringAsFixed(3), '평형'],
    ];
    final rowColors = [
      const Color(0xFF5A8A9A),
      const Color(0xFFE0F4FF),
      const Color(0xFFFF6B35),
      const Color(0xFF64FF8C),
    ];

    for (int r = 0; r < rows.length; r++) {
      for (int c = 0; c < rows[r].length; c++) {
        final x = padL + c * colW;
        final y = tableTop + 22 + r * rowH;
        if (r > 0 && c > 0 && c < 3) {
          canvas.drawRect(
            Rect.fromLTWH(x + 2, y, colW - 4, rowH - 2),
            Paint()..color = rowColors[r].withValues(alpha: 0.07),
          );
        }
        _label(canvas, rows[r][c], Offset(x + 4, y + 4), rowColors[r], fontSize: 9);
      }
    }

    // --- BOTTOM HALF: Concentration bar chart + Qc vs Kc ---
    const chartTop = tableTop + tableH + 14;
    final chartH = h - chartTop - 14;
    const chartPadL = 45.0;
    final chartW = w - chartPadL - 10;

    // Split: left = bars, right = Qc/Kc
    final barsW = chartW * 0.55;
    final qkW = chartW * 0.40;

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.0;
    canvas.drawLine(Offset(chartPadL, chartTop), Offset(chartPadL, chartTop + chartH), axisPaint);
    canvas.drawLine(Offset(chartPadL, chartTop + chartH), Offset(chartPadL + barsW, chartTop + chartH), axisPaint);
    _label(canvas, '[mol/L]', Offset(2, chartTop - 8), const Color(0xFF5A8A9A), fontSize: 8);

    // Bar helper
    void drawBar(double xStart, double fraction, String lbl, Color color) {
      final barW = barsW * 0.28;
      final barH = fraction * chartH * 0.9;
      final rect = Rect.fromLTWH(xStart, chartTop + chartH - barH, barW, barH);
      canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.2));
      canvas.drawRect(rect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
      _label(canvas, lbl, Offset(xStart + barW / 2 - 4, chartTop + chartH + 4), color, fontSize: 9);
      _label(canvas, fraction.toStringAsFixed(2), Offset(xStart + 2, chartTop + chartH - barH - 12), color, fontSize: 8);
    }

    drawBar(chartPadL + 8, eqA, '[A]', const Color(0xFF00D4FF));
    drawBar(chartPadL + barsW * 0.38, eqB, '[B]', const Color(0xFF64FF8C));

    // Qc vs Kc visual
    final qkLeft = chartPadL + barsW + 8;
    _label(canvas, 'Qc vs Kc', Offset(qkLeft, chartTop - 10), const Color(0xFF5A8A9A), fontSize: 9);
    final qc = eqB / (eqA + 0.0001);
    final kc = kValue;
    final maxVal = math.max(qc, kc) * 1.2 + 0.1;
    final qBarH = (qc / maxVal) * chartH * 0.8;
    final kBarH = (kc / maxVal) * chartH * 0.8;
    final qkBarW = qkW * 0.35;

    canvas.drawRect(
      Rect.fromLTWH(qkLeft, chartTop + chartH - qBarH, qkBarW, qBarH),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.25),
    );
    canvas.drawRect(
      Rect.fromLTWH(qkLeft, chartTop + chartH - qBarH, qkBarW, qBarH),
      Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
    _label(canvas, 'Qc\n${qc.toStringAsFixed(2)}', Offset(qkLeft, chartTop + chartH + 4), const Color(0xFFFF6B35), fontSize: 8);

    final kLeft = qkLeft + qkBarW + 6;
    canvas.drawRect(
      Rect.fromLTWH(kLeft, chartTop + chartH - kBarH, qkBarW, kBarH),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.25),
    );
    canvas.drawRect(
      Rect.fromLTWH(kLeft, chartTop + chartH - kBarH, qkBarW, kBarH),
      Paint()..color = const Color(0xFF00D4FF)..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
    _label(canvas, 'Kc\n${kc.toStringAsFixed(2)}', Offset(kLeft, chartTop + chartH + 4), const Color(0xFF00D4FF), fontSize: 8);

    // Direction arrow
    String dir;
    Color dirCol;
    if (qc < kc * 0.95) {
      dir = '→ 정반응';
      dirCol = const Color(0xFF64FF8C);
    } else if (qc > kc * 1.05) {
      dir = '← 역반응';
      dirCol = const Color(0xFFFF6B35);
    } else {
      dir = '⇌ 평형';
      dirCol = const Color(0xFFFFD700);
    }
    _label(canvas, dir, Offset(qkLeft, chartTop + chartH + 24), dirCol, fontSize: 10, bold: true);

    // Title & K display
    _label(canvas, 'K = ${kValue.toStringAsFixed(2)}', Offset(w - 75, 10), const Color(0xFFFFD700), fontSize: 10, bold: true);
  }

  @override
  bool shouldRepaint(covariant _EquilibriumConstantScreenPainter oldDelegate) => true;
}
