import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class SpinChainScreen extends StatefulWidget {
  const SpinChainScreen({super.key});
  @override
  State<SpinChainScreen> createState() => _SpinChainScreenState();
}

class _SpinChainScreenState extends State<SpinChainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _coupling = 1;
  double _chainLength = 8;
  double _groundEnergy = 0, _magnetization = 0;

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
      _groundEnergy = -(_chainLength - 1) * _coupling.abs();
      _magnetization = _coupling > 0 ? 1.0 : 0.0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _coupling = 1.0; _chainLength = 8;
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
          const Text('양자 스핀 체인', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '양자 스핀 체인',
          formula: 'H = -J Σ σ_i·σ_{i+1}',
          formulaDescription: '스핀 체인에서 양자 상관관계를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SpinChainScreenPainter(
                time: _time,
                coupling: _coupling,
                chainLength: _chainLength,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '결합 상수 J',
                value: _coupling,
                min: -2,
                max: 2,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _coupling = v),
              ),
              advancedControls: [
            SimSlider(
                label: '체인 길이',
                value: _chainLength,
                min: 4,
                max: 20,
                step: 1,
                defaultValue: 8,
                formatValue: (v) => '${v.toStringAsFixed(0)} 스핀',
                onChanged: (v) => setState(() => _chainLength = v),
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
          _V('바닥 에너지', _groundEnergy.toStringAsFixed(1)),
          _V('자화', _magnetization.toStringAsFixed(1)),
          _V('J', _coupling.toStringAsFixed(1)),
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

class _SpinChainScreenPainter extends CustomPainter {
  final double time;
  final double coupling;
  final double chainLength;

  _SpinChainScreenPainter({
    required this.time,
    required this.coupling,
    required this.chainLength,
  });

  void _label(Canvas canvas, String text, Offset offset,
      {double fontSize = 9, Color color = const Color(0xFF5A8A9A)}) {
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

    final nSpins = chainLength.round().clamp(4, 16);
    final J = coupling; // positive = ferromagnetic, negative = antiferromagnetic

    // Layout: top 35% = spin chain, middle 35% = correlation heatmap, bottom 30% = magnon dispersion
    final chainTop = h * 0.04;
    final chainBot = h * 0.32;
    final chainCy = (chainTop + chainBot) / 2;

    final heatTop = h * 0.36;

    final dispTop = h * 0.72;
    final dispBot = h * 0.97;

    final padL = 12.0, padR = 12.0;
    final chainW = w - padL - padR;

    // Spin direction: ferromagnetic -> all up, antiferromagnetic -> alternating
    // Superposition glow for J near 0
    final isAFM = J < 0;
    final isMixed = J.abs() < 0.2;

    // ---- TOP: Spin chain sites ----
    final siteSpacing = chainW / (nSpins + 1);
    final siteRadius = math.min(siteSpacing * 0.28, 12.0);
    final arrowLen = (chainBot - chainTop) * 0.32;

    // Draw coupling bonds between sites
    for (int i = 0; i < nSpins - 1; i++) {
      final x1 = padL + (i + 1) * siteSpacing;
      final x2 = padL + (i + 2) * siteSpacing;
      final bondColor = J > 0
          ? const Color(0xFF64FF8C).withValues(alpha: 0.5)
          : J < 0
              ? const Color(0xFFFF6B35).withValues(alpha: 0.5)
              : const Color(0xFF5A8A9A).withValues(alpha: 0.3);
      canvas.drawLine(Offset(x1, chainCy), Offset(x2, chainCy),
          Paint()..color = bondColor..strokeWidth = 2);
    }

    for (int i = 0; i < nSpins; i++) {
      final sx = padL + (i + 1) * siteSpacing;

      // Spin direction: ferromagnetic = all up, AFM = alternating
      final spinUp = isAFM ? (i % 2 == 0) : true;

      // Site circle
      final siteColor = isMixed
          ? const Color(0xFF5A8A9A)
          : spinUp
              ? const Color(0xFF00D4FF)
              : const Color(0xFFFF6B35);
      canvas.drawCircle(Offset(sx, chainCy), siteRadius,
          Paint()..color = siteColor.withValues(alpha: 0.3));
      canvas.drawCircle(Offset(sx, chainCy), siteRadius,
          Paint()
            ..color = siteColor
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke);

      if (isMixed) {
        // Quantum superposition: draw both arrows faded
        _drawArrow(canvas, Offset(sx, chainCy + siteRadius * 0.3),
            Offset(sx, chainCy - arrowLen), const Color(0xFF00D4FF).withValues(alpha: 0.4));
        _drawArrow(canvas, Offset(sx, chainCy - siteRadius * 0.3),
            Offset(sx, chainCy + arrowLen), const Color(0xFFFF6B35).withValues(alpha: 0.4));
      } else {
        // Single arrow
        final arrowColor = spinUp ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35);
        if (spinUp) {
          _drawArrow(canvas, Offset(sx, chainCy + arrowLen * 0.5),
              Offset(sx, chainCy - arrowLen * 0.5), arrowColor);
        } else {
          _drawArrow(canvas, Offset(sx, chainCy - arrowLen * 0.5),
              Offset(sx, chainCy + arrowLen * 0.5), arrowColor);
        }
      }

      // Spin label
      if (nSpins <= 10) {
        _label(canvas, i.toString(), Offset(sx - 4, chainBot - 12),
            color: const Color(0xFF5A8A9A), fontSize: 7);
      }
    }

    // Chain type label
    final chainLabel = isMixed
        ? '양자 중첩 (J≈0)'
        : isAFM
            ? '반강자성 (J=${J.toStringAsFixed(1)})'
            : '강자성 (J=${J.toStringAsFixed(1)})';
    final chainLabelColor = isMixed
        ? const Color(0xFF5A8A9A)
        : isAFM
            ? const Color(0xFFFF6B35)
            : const Color(0xFF64FF8C);
    _label(canvas, chainLabel, Offset(padL, chainTop),
        color: chainLabelColor, fontSize: 9);

    // ---- MIDDLE: Spin correlation heatmap <Si·Sj> ----
    final heatN = math.min(nSpins, 8);
    final heatSize = (w - padL - padR) / heatN;

    for (int i = 0; i < heatN; i++) {
      for (int jj = 0; jj < heatN; jj++) {
        // Correlation: ferromagnetic = positive (same spin), AFM = alternating sign
        final dist = (i - jj).abs();
        double corr;
        if (dist == 0) {
          corr = 1.0;
        } else if (isAFM) {
          corr = math.pow(-1, dist).toDouble() * math.exp(-dist * 0.15);
        } else {
          corr = math.exp(-dist * 0.1);
        }

        final Color cellColor;
        if (corr > 0) {
          cellColor = Color.lerp(
              const Color(0xFF0D1A20), const Color(0xFF00D4FF), corr.clamp(0.0, 1.0))!;
        } else {
          cellColor = Color.lerp(
              const Color(0xFF0D1A20), const Color(0xFFFF6B35), (-corr).clamp(0.0, 1.0))!;
        }

        canvas.drawRect(
          Rect.fromLTWH(
            padL + i * heatSize,
            heatTop + jj * heatSize,
            heatSize - 0.5,
            heatSize - 0.5,
          ),
          Paint()..color = cellColor,
        );
      }
    }

    // Heatmap border
    canvas.drawRect(
      Rect.fromLTWH(padL, heatTop, heatN * heatSize, heatN * heatSize),
      Paint()
        ..color = const Color(0xFF1A3040)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    _label(canvas, '<Si·Sj> 상관 함수', Offset(padL, heatTop - 12),
        color: const Color(0xFF5A8A9A), fontSize: 9);
    _label(canvas, '+ cyan', Offset(padL + heatN * heatSize + 4, heatTop + 2),
        color: const Color(0xFF00D4FF), fontSize: 8);
    _label(canvas, '- orange', Offset(padL + heatN * heatSize + 4, heatTop + 14),
        color: const Color(0xFFFF6B35), fontSize: 8);

    // ---- BOTTOM: Magnon dispersion E(k) = 4|J|sin²(k/2) ----
    final dPadL = padL + 20;
    final dW = w - dPadL - padR;
    final dH = dispBot - dispTop;

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1;
    canvas.drawLine(Offset(dPadL, dispTop), Offset(dPadL, dispBot), axisPaint);
    canvas.drawLine(Offset(dPadL, dispBot), Offset(dPadL + dW, dispBot), axisPaint);
    _label(canvas, 'E(k)', Offset(dPadL - 20, dispTop), fontSize: 8);
    _label(canvas, 'k', Offset(dPadL + dW - 4, dispBot + 2), fontSize: 8);
    _label(canvas, '0', Offset(dPadL - 8, dispBot - 6), fontSize: 7);
    _label(canvas, 'π', Offset(dPadL + dW - 6, dispBot + 2), fontSize: 7);

    // E(k) = 4|J|sin²(k/2)
    final absJ = J.abs().clamp(0.01, 2.0);
    final dispPath = Path();
    bool dispFirst = true;
    for (int i = 0; i <= 100; i++) {
      final kFrac = i / 100.0; // 0..1 maps to 0..pi
      final k = kFrac * math.pi;
      final ek = 4 * absJ * math.pow(math.sin(k / 2), 2);
      final eMax = 4 * absJ;
      final px = dPadL + kFrac * dW;
      final py = dispBot - (ek / eMax) * dH;
      if (dispFirst) {
        dispPath.moveTo(px, py);
        dispFirst = false;
      } else {
        dispPath.lineTo(px, py);
      }
    }
    canvas.drawPath(dispPath,
        Paint()
          ..color = const Color(0xFF64FF8C)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);

    // Fill under dispersion
    final dispFill = Path()..moveTo(dPadL, dispBot);
    for (int i = 0; i <= 100; i++) {
      final kFrac = i / 100.0;
      final k = kFrac * math.pi;
      final ek = 4 * absJ * math.pow(math.sin(k / 2), 2);
      final eMax = 4 * absJ;
      dispFill.lineTo(dPadL + kFrac * dW, dispBot - (ek / eMax) * dH);
    }
    dispFill.lineTo(dPadL + dW, dispBot);
    dispFill.close();
    canvas.drawPath(dispFill,
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.12));

    _label(canvas, 'E(k)=4|J|sin²(k/2)', Offset(dPadL + dW * 0.35, dispTop),
        color: const Color(0xFF64FF8C), fontSize: 8);
    _label(canvas, '|J|=${absJ.toStringAsFixed(1)}', Offset(dPadL + 4, dispTop + 10),
        color: const Color(0xFF5A8A9A), fontSize: 8);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, paint);
    // Arrowhead
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final ux = dx / len, uy = dy / len;
    final headLen = 5.0;
    final p1 = Offset(to.dx - headLen * ux + headLen * 0.4 * uy,
        to.dy - headLen * uy - headLen * 0.4 * ux);
    final p2 = Offset(to.dx - headLen * ux - headLen * 0.4 * uy,
        to.dy - headLen * uy + headLen * 0.4 * ux);
    canvas.drawLine(to, p1, paint);
    canvas.drawLine(to, p2, paint);
  }

  @override
  bool shouldRepaint(covariant _SpinChainScreenPainter oldDelegate) => true;
}
