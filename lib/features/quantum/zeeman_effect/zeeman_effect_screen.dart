import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ZeemanEffectScreen extends StatefulWidget {
  const ZeemanEffectScreen({super.key});
  @override
  State<ZeemanEffectScreen> createState() => _ZeemanEffectScreenState();
}

class _ZeemanEffectScreenState extends State<ZeemanEffectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _bField = 1;
  
  double _splitting = 0, _numLines = 3;

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
      _splitting = 5.79e-5 * _bField;
      _numLines = 3;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _bField = 1.0;
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
          Text('양자역학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('제만 효과', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '제만 효과',
          formula: 'ΔE = m_lμ_BB',
          formulaDescription: '외부 자기장에 의한 스펙트럼 분리를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ZeemanEffectScreenPainter(
                time: _time,
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
                label: '자기장 (T)',
                value: _bField,
                min: 0,
                max: 10,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' T',
                onChanged: (v) => setState(() => _bField = v),
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
          _V('ΔE', _splitting.toStringAsFixed(4) + ' eV'),
          _V('선 수', _numLines.toInt().toString()),
          _V('B', _bField.toStringAsFixed(1) + ' T'),
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

class _ZeemanEffectScreenPainter extends CustomPainter {
  final double time;
  final double bField;

  _ZeemanEffectScreenPainter({
    required this.time,
    required this.bField,
  });

  void _drawLabel(Canvas canvas, String text, Offset offset,
      {double fontSize = 10, Color color = const Color(0xFF5A8A9A)}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Layout: left half = energy levels, right half = spectrum
    final midX = w * 0.5;
    final muB = 5.79e-5; // eV/T
    final deltaE = muB * bField;

    // ---- LEFT: Energy level diagram ----
    final levelAreaLeft = 16.0;
    final levelAreaRight = midX - 16;
    final levelCx = (levelAreaLeft + levelAreaRight) / 2;

    // Base energy positions
    final eBaseY = h * 0.35; // base excited state (p orbital, L=1)
    final gBaseY = h * 0.78; // ground state (s orbital, L=0)

    // splitPx: pixel separation between Zeeman sub-levels
    final splitPx = (deltaE * 1e4).clamp(0.0, h * 0.12);

    final levelPaint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Ground state: single level (no splitting, mL=0)
    levelPaint.color = const Color(0xFF00D4FF);
    final gLineW = (levelAreaRight - levelAreaLeft) * 0.5;
    final gCenterX = levelCx;
    canvas.drawLine(
      Offset(gCenterX - gLineW / 2, gBaseY),
      Offset(gCenterX + gLineW / 2, gBaseY),
      levelPaint,
    );
    _drawLabel(canvas, 'L=0 (s)', Offset(levelAreaLeft, gBaseY - 14), color: const Color(0xFF00D4FF), fontSize: 9);

    // Excited state: L=1, splits into mL=-1,0,+1
    final mLValues = [-1, 0, 1];
    final mLColors = [
      const Color(0xFFFF6B35), // sigma-
      const Color(0xFF00D4FF), // pi
      const Color(0xFF64FF8C), // sigma+
    ];
    final mLLabels = ['m=-1 (σ⁻)', 'm=0 (π)', 'm=+1 (σ⁺)'];
    final mLTransLabels = ['σ⁻', 'π', 'σ⁺'];
    final lineW = (levelAreaRight - levelAreaLeft) * 0.5;

    for (int i = 0; i < 3; i++) {
      final mL = mLValues[i];
      final yOff = bField > 0.01 ? mL * splitPx : 0.0;
      final ly = eBaseY + yOff;
      levelPaint.color = mLColors[i];
      canvas.drawLine(
        Offset(gCenterX - lineW / 2, ly),
        Offset(gCenterX + lineW / 2, ly),
        levelPaint,
      );
      _drawLabel(canvas, mLLabels[i], Offset(levelAreaLeft - 4, ly - 8),
          color: mLColors[i], fontSize: 8);
    }
    _drawLabel(canvas, 'L=1 (p)', Offset(levelAreaLeft, eBaseY - splitPx - 14),
        color: const Color(0xFF5A8A9A), fontSize: 9);

    // Draw transition arrows + labels
    for (int i = 0; i < 3; i++) {
      final mL = mLValues[i];
      final yOff = bField > 0.01 ? mL * splitPx : 0.0;
      final startY = eBaseY + yOff;
      final endY = gBaseY;
      final arrowX = levelAreaLeft + lineW * (0.25 + i * 0.25);

      final arrowPaint = Paint()
        ..color = mLColors[i].withValues(alpha: 0.7)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(arrowX, startY), Offset(arrowX, endY - 6), arrowPaint);
      // arrowhead
      final arrowFill = Paint()..color = mLColors[i].withValues(alpha: 0.7);
      final arrowPath = Path()
        ..moveTo(arrowX, endY)
        ..lineTo(arrowX - 3, endY - 7)
        ..lineTo(arrowX + 3, endY - 7)
        ..close();
      canvas.drawPath(arrowPath, arrowFill);
      _drawLabel(canvas, mLTransLabels[i], Offset(arrowX + 4, (startY + endY) / 2 - 5),
          color: mLColors[i], fontSize: 8);
    }

    // Section label
    _drawLabel(canvas, '에너지 준위', Offset(levelAreaLeft, 8),
        color: const Color(0xFF5A8A9A), fontSize: 9);

    // Divider
    final divPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(midX, 0), Offset(midX, h), divPaint);

    // ---- RIGHT: Spectrum lines ----
    final specLeft = midX + 16;
    final specRight = w - 16.0;
    final specCx = (specLeft + specRight) / 2;
    final specH = h * 0.55;
    final specTop = h * 0.15;
    final specBottom = specTop + specH;

    _drawLabel(canvas, '스펙트럼', Offset(specLeft, 8),
        color: const Color(0xFF5A8A9A), fontSize: 9);

    // No-field label
    _drawLabel(canvas, 'B=0', Offset(specLeft, specTop - 2),
        color: const Color(0xFF5A8A9A), fontSize: 9);

    // Single line without field (leftmost)
    final singleX = specLeft + (specRight - specLeft) * 0.25;
    final noFieldPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(singleX, specTop + 4), Offset(singleX, specBottom), noFieldPaint);

    // With field label
    _drawLabel(canvas, 'B=${bField.toStringAsFixed(1)}T',
        Offset(specLeft + (specRight - specLeft) * 0.5, specTop - 2),
        color: const Color(0xFF5A8A9A), fontSize: 9);

    // Three split lines
    final splitOffsets = [-splitPx * 0.15, 0.0, splitPx * 0.15];
    final baseSplitX = specLeft + (specRight - specLeft) * 0.72;
    for (int i = 0; i < 3; i++) {
      final sx = baseSplitX + splitOffsets[i];
      final linePaint = Paint()
        ..color = mLColors[i]
        ..strokeWidth = bField > 0.01 ? 2.0 : 2.5;
      canvas.drawLine(Offset(sx, specTop + 4), Offset(sx, specBottom), linePaint);
    }

    // Wavelength axis
    final axisPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(specLeft, specBottom), Offset(specRight, specBottom), axisPaint);
    _drawLabel(canvas, 'λ (파장)', Offset(specCx - 20, specBottom + 4),
        color: const Color(0xFF5A8A9A), fontSize: 9);

    // DeltaE label
    if (bField > 0.1) {
      final deStr = 'ΔE=${(deltaE * 1e3).toStringAsFixed(3)}meV';
      _drawLabel(canvas, deStr, Offset(specLeft, specBottom + 18),
          color: const Color(0xFF64FF8C), fontSize: 9);
    }

    // B field arrow (right side indicator)
    final bArrowX = w - 12.0;
    final bArrowTop = h * 0.2;
    final bArrowBot = h * 0.8;
    final bStrength = (bField / 10.0).clamp(0.0, 1.0);
    final bPaint = Paint()
      ..color = const Color(0xFFFF6B35).withValues(alpha: 0.5 + 0.5 * bStrength)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(bArrowX, bArrowBot), Offset(bArrowX, bArrowTop + 8), bPaint);
    final bHeadPath = Path()
      ..moveTo(bArrowX, bArrowTop)
      ..lineTo(bArrowX - 3, bArrowTop + 8)
      ..lineTo(bArrowX + 3, bArrowTop + 8)
      ..close();
    canvas.drawPath(bHeadPath, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7));
    _drawLabel(canvas, 'B', Offset(bArrowX - 4, bArrowTop - 12),
        color: const Color(0xFFFF6B35), fontSize: 10);
  }

  @override
  bool shouldRepaint(covariant _ZeemanEffectScreenPainter oldDelegate) => true;
}
