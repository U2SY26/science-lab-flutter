import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CompetitiveExclusionScreen extends StatefulWidget {
  const CompetitiveExclusionScreen({super.key});
  @override
  State<CompetitiveExclusionScreen> createState() => _CompetitiveExclusionScreenState();
}

class _CompetitiveExclusionScreenState extends State<CompetitiveExclusionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _competitionAlpha = 0.8;
  double _growthR1 = 1;
  double _n1 = 50, _n2 = 50;

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
      final k = 500.0;
      final dN1 = _growthR1 * _n1 * (k - _n1 - _competitionAlpha * _n2) / k * 0.016;
      final dN2 = 0.8 * _n2 * (k - _n2 - _competitionAlpha * _n1) / k * 0.016;
      _n1 = math.max(0, _n1 + dN1);
      _n2 = math.max(0, _n2 + dN2);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _competitionAlpha = 0.8; _growthR1 = 1.0; _n1 = 50; _n2 = 50;
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
          const Text('경쟁 배타 원리', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '경쟁 배타 원리',
          formula: 'dN₁/dt = r₁N₁(K₁-N₁-αN₂)/K₁',
          formulaDescription: '같은 생태적 지위를 두고 경쟁하는 두 종을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CompetitiveExclusionScreenPainter(
                time: _time,
                competitionAlpha: _competitionAlpha,
                growthR1: _growthR1,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '경쟁 계수 α',
                value: _competitionAlpha,
                min: 0.1,
                max: 2,
                step: 0.1,
                defaultValue: 0.8,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _competitionAlpha = v),
              ),
              advancedControls: [
            SimSlider(
                label: '종 1 성장률',
                value: _growthR1,
                min: 0.1,
                max: 2,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _growthR1 = v),
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
          _V('N₁', _n1.toStringAsFixed(0)),
          _V('N₂', _n2.toStringAsFixed(0)),
          _V('α', _competitionAlpha.toStringAsFixed(1)),
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

class _CompetitiveExclusionScreenPainter extends CustomPainter {
  final double time;
  final double competitionAlpha;
  final double growthR1;

  _CompetitiveExclusionScreenPainter({
    required this.time,
    required this.competitionAlpha,
    required this.growthR1,
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
    const k = 500.0;
    final r1 = growthR1;
    const r2 = 0.8;
    final alpha12 = competitionAlpha; // effect of sp2 on sp1
    final alpha21 = competitionAlpha; // symmetric for simplicity

    // --- Upper: N vs time (left panel 60% width) ---
    final chartTop = 18.0;
    final chartH = h * 0.52;
    final chartBot = chartTop + chartH;
    final chartLeft = 44.0;
    final chartRight = w * 0.62;
    final chartW = chartRight - chartLeft;

    // Axes
    canvas.drawLine(Offset(chartLeft, chartTop), Offset(chartLeft, chartBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(chartLeft, chartBot), Offset(chartRight, chartBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _label(canvas, 'N', Offset(2, chartTop), fs: 9, col: const Color(0xFFE0F4FF));
    _label(canvas, '시간', Offset(chartRight - 18, chartBot + 2), fs: 7);
    _label(canvas, 'K=${k.toStringAsFixed(0)}', Offset(2, chartTop + 4), fs: 7);

    // Simulate Lotka-Volterra competition
    final List<double> n1List = [];
    final List<double> n2List = [];
    double n1 = 50.0, n2 = 50.0;
    const dt = 0.05;
    const steps = 300;
    for (int i = 0; i <= steps; i++) {
      n1List.add(n1);
      n2List.add(n2);
      final dn1 = r1 * n1 * (k - n1 - alpha12 * n2) / k * dt;
      final dn2 = r2 * n2 * (k - n2 - alpha21 * n1) / k * dt;
      n1 = math.max(0, n1 + dn1);
      n2 = math.max(0, n2 + dn2);
    }

    // Draw N1 path (cyan)
    final path1 = Path();
    for (int i = 0; i <= steps; i++) {
      final x = chartLeft + (i / steps) * chartW;
      final y = chartBot - (n1List[i] / k).clamp(0.0, 1.05) * chartH;
      if (i == 0) {
        path1.moveTo(x, y);
      } else {
        path1.lineTo(x, y);
      }
    }
    canvas.drawPath(path1, Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2..style = PaintingStyle.stroke);

    // Draw N2 path (orange)
    final path2 = Path();
    for (int i = 0; i <= steps; i++) {
      final x = chartLeft + (i / steps) * chartW;
      final y = chartBot - (n2List[i] / k).clamp(0.0, 1.05) * chartH;
      if (i == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }
    canvas.drawPath(path2, Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2..style = PaintingStyle.stroke);

    // Legend
    canvas.drawLine(Offset(chartLeft + 4, chartTop + 6), Offset(chartLeft + 20, chartTop + 6),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2);
    _label(canvas, '종 1', Offset(chartLeft + 22, chartTop + 2), fs: 7, col: const Color(0xFF00D4FF));
    canvas.drawLine(Offset(chartLeft + 4, chartTop + 16), Offset(chartLeft + 20, chartTop + 16),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 2);
    _label(canvas, '종 2', Offset(chartLeft + 22, chartTop + 12), fs: 7, col: const Color(0xFFFF6B35));

    // Outcome label
    final finalN1 = n1List.last;
    final finalN2 = n2List.last;
    String outcome;
    Color outcomeCol;
    if (finalN1 > finalN2 * 3) {
      outcome = '종 1 승리';
      outcomeCol = const Color(0xFF00D4FF);
    } else if (finalN2 > finalN1 * 3) {
      outcome = '종 2 승리';
      outcomeCol = const Color(0xFFFF6B35);
    } else {
      outcome = '불안정 공존';
      outcomeCol = const Color(0xFF64FF8C);
    }
    _label(canvas, outcome, Offset(chartLeft + chartW / 2, chartBot + 4), fs: 9, col: outcomeCol, center: true);

    // --- Right: Phase plane isocline plot ---
    final ppLeft = w * 0.65;
    final ppRight = w - 8;
    final ppTop = chartTop;
    final ppBot = chartBot;
    final ppW = ppRight - ppLeft;
    final ppH = ppBot - ppTop;

    canvas.drawLine(Offset(ppLeft, ppTop), Offset(ppLeft, ppBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(ppLeft, ppBot), Offset(ppRight, ppBot),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _label(canvas, 'N₁', Offset(ppRight - 10, ppBot + 2), fs: 7, col: const Color(0xFF00D4FF));
    _label(canvas, 'N₂', Offset(ppLeft - 14, ppTop), fs: 7, col: const Color(0xFFFF6B35));

    // Isocline 1: N1 + alpha12*N2 = K → N2 = (K - N1)/alpha12
    final iso1Path = Path();
    iso1Path.moveTo(ppLeft, ppBot - (k / alpha12).clamp(0, k) / k * ppH);
    iso1Path.lineTo(ppLeft + ppW, ppBot - ((k - k) / alpha12).clamp(0, k) / k * ppH);
    canvas.drawPath(iso1Path, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Isocline 2: N2 + alpha21*N1 = K → N2 = K - alpha21*N1
    final iso2Path = Path();
    iso2Path.moveTo(ppLeft, ppBot - k / k * ppH);
    iso2Path.lineTo(ppLeft + (k / alpha21).clamp(0, k) / k * ppW, ppBot);
    canvas.drawPath(iso2Path, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Trajectory in phase plane
    final tPath = Path();
    for (int i = 0; i <= steps; i++) {
      final x = ppLeft + (n1List[i] / k).clamp(0, 1) * ppW;
      final y = ppBot - (n2List[i] / k).clamp(0, 1) * ppH;
      if (i == 0) {
        tPath.moveTo(x, y);
      } else {
        tPath.lineTo(x, y);
      }
    }
    canvas.drawPath(tPath, Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.6)..strokeWidth = 1..style = PaintingStyle.stroke);
    // Current point
    canvas.drawCircle(
      Offset(ppLeft + (n1List.last / k).clamp(0, 1) * ppW, ppBot - (n2List.last / k).clamp(0, 1) * ppH),
      4, Paint()..color = const Color(0xFF64FF8C),
    );
    _label(canvas, '위상 평면', Offset(ppLeft + ppW / 2, ppTop - 2), fs: 7, col: const Color(0xFF5A8A9A), center: true);

    // --- Bottom: niche labels ---
    final bottomY = chartBot + 20;
    _label(canvas, 'α=${competitionAlpha.toStringAsFixed(1)}  r₁=${r1.toStringAsFixed(1)}  r₂=${r2.toStringAsFixed(1)}', Offset(chartLeft, bottomY), fs: 8, col: const Color(0xFF5A8A9A));
    _label(canvas, alpha12 < 1.0 ? '니치 분리 → 공존 가능' : '강한 경쟁 → 배타 발생', Offset(chartLeft, bottomY + 12), fs: 8,
        col: alpha12 < 1.0 ? const Color(0xFF64FF8C) : const Color(0xFFFF6B35));
  }

  @override
  bool shouldRepaint(covariant _CompetitiveExclusionScreenPainter oldDelegate) => true;
}
