import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class DensityMatrixScreen extends StatefulWidget {
  const DensityMatrixScreen({super.key});
  @override
  State<DensityMatrixScreen> createState() => _DensityMatrixScreenState();
}

class _DensityMatrixScreenState extends State<DensityMatrixScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _purity = 1;
  
  double _entropy = 0.0, _rho00 = 1.0, _rho11 = 0.0;

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
      _rho00 = 0.5 + 0.5 * math.sqrt(2 * _purity - 1);
      _rho11 = 1.0 - _rho00;
      _entropy = _purity >= 0.999 ? 0.0 : -(_rho00 * math.log(_rho00) + _rho11 * math.log(_rho11)) / math.ln2;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _purity = 1.0;
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
          const Text('밀도 행렬', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '밀도 행렬',
          formula: 'ρ = Σ p_i |ψ_i⟩⟨ψ_i|',
          formulaDescription: '양자 혼합 상태를 밀도 행렬로 표현합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DensityMatrixScreenPainter(
                time: _time,
                purity: _purity,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '순도 (Tr(ρ²))',
                value: _purity,
                min: 0.5,
                max: 1,
                step: 0.01,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _purity = v),
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
          _V('순도', _purity.toStringAsFixed(2)),
          _V('엔트로피', _entropy.toStringAsFixed(3)),
          _V('ρ₀₀', _rho00.toStringAsFixed(3)),
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

class _DensityMatrixScreenPainter extends CustomPainter {
  final double time;
  final double purity;

  _DensityMatrixScreenPainter({
    required this.time,
    required this.purity,
  });

  void _drawText(Canvas canvas, String text, Offset offset,
      {double fontSize = 10, Color color = const Color(0xFFE0F4FF), bool bold = false, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    double dx = offset.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Compute density matrix elements
    // Pure state |ψ⟩ = cos(θ/2)|0⟩ + e^(iφ)sin(θ/2)|1⟩
    // θ, φ from time animation
    final theta = math.pi / 3 + 0.3 * math.sin(time * 0.4);
    final phi = time * 0.6;
    // For mixed state: ρ = purity*|ψ⟩⟨ψ| + (1-purity)*I/2
    final rho00 = purity * math.pow(math.cos(theta / 2), 2) + (1 - purity) * 0.5;
    final rho11 = 1.0 - rho00;
    // off-diagonal: ρ01 = purity * cos(θ/2)*sin(θ/2) * e^(-iφ)
    final offMag = purity * math.cos(theta / 2) * math.sin(theta / 2);
    final rho01Re = offMag * math.cos(phi);
    final rho01Im = -offMag * math.sin(phi);

    // --- Layout: left=matrix, right=Bloch sphere ---
    final matLeft = 16.0;
    final matSize = math.min(w * 0.42, h * 0.55);
    final blochCx = matLeft + matSize + (w - matLeft - matSize) / 2;
    final blochCy = h * 0.42;
    final blochR = math.min((w - matLeft - matSize) * 0.38, h * 0.3);

    // ===== 2x2 Density Matrix =====
    _drawText(canvas, 'ρ (밀도 행렬)', Offset(matLeft + matSize / 2, 8),
        fontSize: 10, color: const Color(0xFF00D4FF), bold: true, align: TextAlign.center);

    final cellSize = matSize / 2.5;
    final matTop = 28.0;
    final matGridLeft = matLeft + (matSize - cellSize * 2) / 2;

    // Row/col labels
    _drawText(canvas, '|0⟩', Offset(matGridLeft + cellSize * 0.5, matTop - 14),
        fontSize: 9, color: const Color(0xFF5A8A9A), align: TextAlign.center);
    _drawText(canvas, '|1⟩', Offset(matGridLeft + cellSize * 1.5, matTop - 14),
        fontSize: 9, color: const Color(0xFF5A8A9A), align: TextAlign.center);
    _drawText(canvas, '⟨0|', Offset(matGridLeft - 20, matTop + cellSize * 0.3),
        fontSize: 9, color: const Color(0xFF5A8A9A));
    _drawText(canvas, '⟨1|', Offset(matGridLeft - 20, matTop + cellSize + cellSize * 0.3),
        fontSize: 9, color: const Color(0xFF5A8A9A));

    final elements = [
      [rho00, 0.0],       // (0,0)
      [rho01Re, rho01Im], // (0,1)
      [rho01Re, -rho01Im],// (1,0)
      [rho11, 0.0],       // (1,1)
    ];
    final labels = ['ρ₀₀', 'ρ₀₁', 'ρ₁₀', 'ρ₁₁'];
    final isDiag = [true, false, false, true];

    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 2; c++) {
        final idx = r * 2 + c;
        final re = elements[idx][0];
        final im = elements[idx][1];
        final cx = matGridLeft + c * cellSize;
        final cy = matTop + r * cellSize;
        final rect = Rect.fromLTWH(cx, cy, cellSize - 4, cellSize - 4);

        // Cell background: cyan for diagonal, orange for off-diagonal
        final bgColor = isDiag[idx]
            ? const Color(0xFF00D4FF).withValues(alpha: re.clamp(0.0, 1.0) * 0.35 + 0.05)
            : const Color(0xFFFF6B35).withValues(alpha: offMag.clamp(0.0, 1.0) * 0.35 + 0.05);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            Paint()..color = bgColor);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            Paint()
              ..color = (isDiag[idx] ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35)).withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);

        // Label
        _drawText(canvas, labels[idx], Offset(cx + (cellSize - 4) / 2, cy + 5),
            fontSize: 8, color: const Color(0xFF5A8A9A), align: TextAlign.center);
        // Value
        final valStr = im.abs() < 0.001
            ? re.toStringAsFixed(2)
            : '${re.toStringAsFixed(2)}${im >= 0 ? '+' : ''}${im.toStringAsFixed(2)}i';
        _drawText(canvas, valStr, Offset(cx + (cellSize - 4) / 2, cy + cellSize * 0.52),
            fontSize: 8,
            color: isDiag[idx] ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35),
            align: TextAlign.center);

        // Phase circle for off-diagonal
        if (!isDiag[idx] && offMag > 0.01) {
          final phaseCx = cx + (cellSize - 4) / 2;
          final phaseCy = cy + cellSize * 0.82;
          final phaseR = 6.0;
          canvas.drawCircle(Offset(phaseCx, phaseCy), phaseR,
              Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.2)..style = PaintingStyle.fill);
          canvas.drawCircle(Offset(phaseCx, phaseCy), phaseR,
              Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 0.8);
          final phaseAngle = math.atan2(im, re);
          canvas.drawLine(
            Offset(phaseCx, phaseCy),
            Offset(phaseCx + phaseR * math.cos(phaseAngle), phaseCy + phaseR * math.sin(phaseAngle)),
            Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5,
          );
        }
      }
    }

    // Tr(ρ)=1 and purity label
    _drawText(canvas, 'Tr(ρ)=1  Tr(ρ²)=${purity.toStringAsFixed(2)}',
        Offset(matLeft + matSize / 2, matTop + cellSize * 2 + 6),
        fontSize: 8, color: const Color(0xFF5A8A9A), align: TextAlign.center);

    // ===== Bloch Sphere =====
    _drawText(canvas, '블로흐 구', Offset(blochCx, 8),
        fontSize: 10, color: const Color(0xFF00D4FF), bold: true, align: TextAlign.center);

    // Sphere outline
    canvas.drawCircle(Offset(blochCx, blochCy), blochR,
        Paint()..color = const Color(0xFF1A3040)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(blochCx, blochCy), blochR,
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = 1);
    // Equator ellipse
    canvas.drawOval(
      Rect.fromCenter(center: Offset(blochCx, blochCy), width: blochR * 2, height: blochR * 0.5),
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 0.8,
    );

    // Axes
    final axPaint = Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.6)..strokeWidth = 1;
    canvas.drawLine(Offset(blochCx, blochCy - blochR), Offset(blochCx, blochCy + blochR), axPaint); // Z
    canvas.drawLine(Offset(blochCx - blochR, blochCy), Offset(blochCx + blochR, blochCy), axPaint); // X
    // Axis labels
    _drawText(canvas, '|0⟩', Offset(blochCx, blochCy - blochR - 12),
        fontSize: 8, color: const Color(0xFF5A8A9A), align: TextAlign.center);
    _drawText(canvas, '|1⟩', Offset(blochCx, blochCy + blochR + 2),
        fontSize: 8, color: const Color(0xFF5A8A9A), align: TextAlign.center);

    // Bloch vector: length = purity (shrinks for mixed state)
    final bx = blochCx + blochR * purity * math.sin(theta) * math.cos(phi);
    final by = blochCy - blochR * purity * math.cos(theta);
    canvas.drawLine(Offset(blochCx, blochCy), Offset(bx, by),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2);
    canvas.drawCircle(Offset(bx, by), 5,
        Paint()..color = const Color(0xFF00D4FF));
    // Dashed projection to equator
    final dashPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(bx, by), Offset(bx, blochCy), dashPaint);
    canvas.drawLine(Offset(blochCx, blochCy), Offset(bx, blochCy), dashPaint);

    // State label
    _drawText(canvas, purity >= 0.99 ? '순수 상태' : '혼합 상태',
        Offset(blochCx, blochCy + blochR + 18),
        fontSize: 9,
        color: purity >= 0.99 ? const Color(0xFF64FF8C) : const Color(0xFFFF6B35),
        align: TextAlign.center);

    // Population/Coherence labels below
    final infoY = h - 28.0;
    _drawText(canvas, '대각(Population)', Offset(w * 0.25, infoY),
        fontSize: 8, color: const Color(0xFF00D4FF), align: TextAlign.center);
    _drawText(canvas, 'ρ₀₀=${rho00.toStringAsFixed(2)}  ρ₁₁=${rho11.toStringAsFixed(2)}',
        Offset(w * 0.25, infoY + 12),
        fontSize: 8, color: const Color(0xFFE0F4FF), align: TextAlign.center);
    _drawText(canvas, '비대각(Coherence)', Offset(w * 0.75, infoY),
        fontSize: 8, color: const Color(0xFFFF6B35), align: TextAlign.center);
    _drawText(canvas, '|ρ₀₁|=${offMag.toStringAsFixed(2)}',
        Offset(w * 0.75, infoY + 12),
        fontSize: 8, color: const Color(0xFFE0F4FF), align: TextAlign.center);
  }

  @override
  bool shouldRepaint(covariant _DensityMatrixScreenPainter oldDelegate) => true;
}
