import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CosmicDistanceLadderScreen extends StatefulWidget {
  const CosmicDistanceLadderScreen({super.key});
  @override
  State<CosmicDistanceLadderScreen> createState() => _CosmicDistanceLadderScreenState();
}

class _CosmicDistanceLadderScreenState extends State<CosmicDistanceLadderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _distancePc = 100;
  double _absMagnitude = -1.5;
  double _appMagnitude = 0, _distModulus = 0;

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
      _distModulus = 5 * (math.log(_distancePc / 10) / math.ln10);
      _appMagnitude = _absMagnitude + _distModulus;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _distancePc = 100; _absMagnitude = -1.5;
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
          Text('천문학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('우주 거리 사다리', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '천문학 시뮬레이션',
          title: '우주 거리 사다리',
          formula: 'm - M = 5 log₁₀(d/10pc)',
          formulaDescription: '우주 거리를 측정하는 방법의 연쇄를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CosmicDistanceLadderScreenPainter(
                time: _time,
                distancePc: _distancePc,
                absMagnitude: _absMagnitude,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '거리 (pc)',
                value: _distancePc,
                min: 1,
                max: 10000,
                step: 100,
                defaultValue: 100,
                formatValue: (v) => '${v.toStringAsFixed(0)} pc',
                onChanged: (v) => setState(() => _distancePc = v),
              ),
              advancedControls: [
            SimSlider(
                label: '절대 등급 M',
                value: _absMagnitude,
                min: -10,
                max: 15,
                step: 0.5,
                defaultValue: -1.5,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _absMagnitude = v),
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
          _V('겉보기 등급', _appMagnitude.toStringAsFixed(1)),
          _V('거리 지수', _distModulus.toStringAsFixed(1)),
          _V('거리', '${_distancePc.toStringAsFixed(0)} pc'),
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

class _CosmicDistanceLadderScreenPainter extends CustomPainter {
  final double time;
  final double distancePc;
  final double absMagnitude;

  _CosmicDistanceLadderScreenPainter({
    required this.time,
    required this.distancePc,
    required this.absMagnitude,
  });

  void _label(Canvas canvas, String text, Offset pos, {double fs = 8, Color col = const Color(0xFF5A8A9A), bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // === Ladder rungs (vertical structure, left side) ===
    // 6 methods, bottom=near, top=far (log scale)
    const rungs = [
      ('레이더 거리', '<50 AU', Color(0xFF64FF8C)),
      ('연주 시차', '<1 kpc', Color(0xFF00D4FF)),
      ('주계열 맞춤', '<30 kpc', Color(0xFF44BBFF)),
      ('세페이드 변광성', '<30 Mpc', Color(0xFFFF6B35)),
      ('Ia형 초신성', '<1 Gpc', Color(0xFFFF4444)),
      ('허블 법칙', '전 우주', Color(0xFFFF88AA)),
    ];

    final ladderLeft = 10.0;
    final ladderRight = w * 0.52;
    final ladderW = ladderRight - ladderLeft;
    final ladderTop = 10.0;
    final ladderBot = h * 0.88;
    final ladderH = ladderBot - ladderTop;
    final rungH = ladderH / rungs.length;

    // Vertical posts
    final postX1 = ladderLeft + ladderW * 0.12;
    final postX2 = ladderLeft + ladderW * 0.38;
    canvas.drawLine(Offset(postX1, ladderTop + 4), Offset(postX1, ladderBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 2);
    canvas.drawLine(Offset(postX2, ladderTop + 4), Offset(postX2, ladderBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 2);

    // Determine which rung is active based on distancePc
    // Radar <0.001 pc, Parallax <1000 pc, Main seq <30000 pc, Cepheid <30M pc (~3e7), SN <1G pc (~3e8), Hubble > all
    final logDist = math.log(distancePc.clamp(0.001, 1e12)) / math.ln10;
    // log ranges: radar<-2.3, parallax<3, mainseq<4.5, cepheid<7.5, snia<8.5, hubble=all
    final logBounds = [-2.3, 3.0, 4.5, 7.5, 8.5, 12.0];
    int activeRung = 0;
    for (int i = 0; i < logBounds.length; i++) {
      if (logDist <= logBounds[i]) {
        activeRung = i;
        break;
      }
      activeRung = i;
    }

    for (int i = 0; i < rungs.length; i++) {
      final rung = rungs[i];
      // Rungs drawn bottom-up, so rung 0 is at bottom
      final rungIdx = rungs.length - 1 - i;
      final ry = ladderTop + rungIdx * rungH + rungH * 0.3;
      final isActive = (rungs.length - 1 - rungIdx) == activeRung;
      final alpha = isActive ? 1.0 : 0.45;

      // Rung bar
      canvas.drawLine(Offset(postX1, ry), Offset(postX2, ry),
          Paint()..color = rung.$3.withValues(alpha: alpha)..strokeWidth = isActive ? 3.0 : 1.5);

      // Active glow
      if (isActive) {
        canvas.drawLine(Offset(postX1, ry), Offset(postX2, ry),
            Paint()..color = rung.$3.withValues(alpha: 0.3)..strokeWidth = 8);
      }

      // Labels
      _label(canvas, rung.$1, Offset(postX2 + 6, ry - 8), fs: isActive ? 9.0 : 7.5,
          col: rung.$3.withValues(alpha: alpha));
      _label(canvas, rung.$2, Offset(postX2 + 6, ry + 2), fs: 7,
          col: const Color(0xFF5A8A9A).withValues(alpha: alpha));

      // Step numbering on left
      _label(canvas, '${i + 1}', Offset(ladderLeft + 2, ry - 6), fs: 8,
          col: rung.$3.withValues(alpha: alpha));
    }

    // Current distance marker
    final distNorm = (logDist - (-2.3)) / (12.0 - (-2.3));
    final markerY = ladderBot - distNorm.clamp(0.0, 1.0) * ladderH;
    canvas.drawLine(Offset(postX1 - 6, markerY), Offset(postX2 + 6, markerY),
        Paint()..color = const Color(0xFFFFDD44)..strokeWidth = 2);
    canvas.drawCircle(Offset(postX1 - 6, markerY), 4, Paint()..color = const Color(0xFFFFDD44));
    _label(canvas, '← ${distancePc.toStringAsFixed(0)} pc', Offset(postX2 + 8, markerY - 5), fs: 7,
        col: const Color(0xFFFFDD44));

    // Overlap region highlights (calibration)
    // e.g., Cepheid + MainSeq overlap zone
    final overlapRung = rungs.length - 1 - 2; // between main seq and cepheid
    final ov1Y = ladderTop + overlapRung * rungH + rungH * 0.3;
    final ov2Y = ladderTop + (overlapRung - 1) * rungH + rungH * 0.3;
    canvas.drawRect(
      Rect.fromLTRB(postX1, math.min(ov1Y, ov2Y) - 2, postX2, math.max(ov1Y, ov2Y) + 2),
      Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.08),
    );

    // === Right panel: magnitude-distance diagram ===
    final chartLeft = w * 0.56;
    final chartRight = w - 8;
    final chartTop2 = 14.0;
    final chartBot2 = h * 0.72;
    final chartW = chartRight - chartLeft;
    final chartH = chartBot2 - chartTop2;

    canvas.drawLine(Offset(chartLeft, chartTop2), Offset(chartLeft, chartBot2),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(chartLeft, chartBot2), Offset(chartRight, chartBot2),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _label(canvas, 'm\n(등급)', Offset(chartLeft - 14, chartTop2), fs: 7);
    _label(canvas, 'log d', Offset(chartRight - 20, chartBot2 + 2), fs: 7);

    // Distance modulus: m - M = 5 log10(d/10)
    final distModulus = 5 * (math.log(distancePc / 10) / math.ln10);
    final appMag = absMagnitude + distModulus;

    // Line: m = M + 5*log(d/10) — linear on log scale
    final linePath = Path();
    for (int px = 0; px <= chartW.toInt(); px++) {
      final logD = 0 + (px / chartW) * 9; // log d from 0 to 9
      final m = absMagnitude + 5 * (logD - 1);
      // Map m: -5 at top to +30 at bottom
      final normM = ((m - (-5)) / (30 - (-5))).clamp(0.0, 1.0);
      final y = chartTop2 + normM * chartH;
      final x = chartLeft + px.toDouble();
      if (px == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(linePath,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Current point
    final logD = math.log(distancePc) / math.ln10;
    final normLogD = ((logD - 0) / 9).clamp(0.0, 1.0);
    final normM2 = ((appMag - (-5)) / 35).clamp(0.0, 1.0);
    final ptX = chartLeft + normLogD * chartW;
    final ptY = chartTop2 + normM2 * chartH;
    canvas.drawCircle(Offset(ptX, ptY), 5, Paint()..color = const Color(0xFFFF6B35));
    canvas.drawLine(Offset(ptX, chartTop2), Offset(ptX, ptY),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.3)..strokeWidth = 1);
    canvas.drawLine(Offset(chartLeft, ptY), Offset(ptX, ptY),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.3)..strokeWidth = 1);

    _label(canvas, 'm=${appMag.toStringAsFixed(1)}', Offset(ptX + 4, ptY - 10), fs: 8, col: const Color(0xFFFF6B35));
    _label(canvas, 'm-M=${distModulus.toStringAsFixed(1)}', Offset(chartLeft + 4, chartTop2 + 2), fs: 7, col: const Color(0xFF5A8A9A));
    _label(canvas, '거리 지수', Offset((chartLeft + chartRight) / 2, chartBot2 + 4), fs: 7, center: true);

    // === Bottom: log distance scale bar ===
    final scaleY = h * 0.78;
    _label(canvas, '거리 척도 (로그)', Offset(8, scaleY - 12), fs: 7, col: const Color(0xFF5A8A9A));
    final scaleLabels = ['1 AU', '1 pc', '1 kpc', '1 Mpc', '1 Gpc'];
    final scalePcs = [4.85e-6, 1.0, 1e3, 1e6, 1e9];
    final scaleLeft2 = 10.0;
    final scaleW = w - 20;
    for (int i = 0; i < scaleLabels.length; i++) {
      final lpc = math.log(scalePcs[i]) / math.ln10;
      final nx = scaleLeft2 + (lpc + 5) / 14.0 * scaleW;
      if (nx < scaleLeft2 || nx > scaleLeft2 + scaleW) continue;
      canvas.drawLine(Offset(nx, scaleY), Offset(nx, scaleY + 6),
          Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
      _label(canvas, scaleLabels[i], Offset(nx, scaleY + 8), fs: 6, col: const Color(0xFF5A8A9A), center: true);
    }
    canvas.drawLine(Offset(scaleLeft2, scaleY), Offset(scaleLeft2 + scaleW, scaleY),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);

    // Current distance on scale
    final curLogPc = math.log(distancePc.clamp(1e-6, 1e12)) / math.ln10;
    final curScaleX = scaleLeft2 + (curLogPc + 5) / 14.0 * scaleW;
    if (curScaleX >= scaleLeft2 && curScaleX <= scaleLeft2 + scaleW) {
      canvas.drawCircle(Offset(curScaleX, scaleY), 4, Paint()..color = const Color(0xFFFFDD44));
    }

    _label(canvas, '허블 상수 H₀ = 70 km/s/Mpc', Offset(8, h - 10), fs: 7, col: const Color(0xFF5A8A9A));
  }

  @override
  bool shouldRepaint(covariant _CosmicDistanceLadderScreenPainter oldDelegate) => true;
}
