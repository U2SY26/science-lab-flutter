import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class WignerFunctionScreen extends StatefulWidget {
  const WignerFunctionScreen({super.key});
  @override
  State<WignerFunctionScreen> createState() => _WignerFunctionScreenState();
}

class _WignerFunctionScreenState extends State<WignerFunctionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _quantumN = 0;
  double _squeezeFactor = 1;


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
      
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _quantumN = 0; _squeezeFactor = 1.0;
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
          const Text('위그너 함수', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '위그너 함수',
          formula: 'W(x,p)=1/πℏ ∫ψ*(x+y)ψ(x-y)e^{2ipy/ℏ}dy',
          formulaDescription: '위그너 준확률 분포를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _WignerFunctionScreenPainter(
                time: _time,
                quantumN: _quantumN,
                squeezeFactor: _squeezeFactor,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '양자 수 n',
                value: _quantumN,
                min: 0,
                max: 10,
                step: 1,
                defaultValue: 0,
                formatValue: (v) => 'n = ${v.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => _quantumN = v),
              ),
              advancedControls: [
            SimSlider(
                label: '스퀴즈 인자',
                value: _squeezeFactor,
                min: 0.1,
                max: 3,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _squeezeFactor = v),
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
          _V('양자 수', _quantumN.toStringAsFixed(0)),
          _V('스퀴즈', _squeezeFactor.toStringAsFixed(1)),
          _V('시간', _time.toStringAsFixed(1)),
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

class _WignerFunctionScreenPainter extends CustomPainter {
  final double time;
  final double quantumN;
  final double squeezeFactor;

  _WignerFunctionScreenPainter({
    required this.time,
    required this.quantumN,
    required this.squeezeFactor,
  });

  void _label(Canvas canvas, String text, Offset offset,
      {double fontSize = 9, Color color = const Color(0xFF5A8A9A)}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  // Wigner function for Fock state |n>
  // W_n(x,p) = (-1)^n / pi * exp(-(x²+p²)) * L_n(2(x²+p²))
  // where L_n is Laguerre polynomial
  double _laguerre(int n, double z) {
    if (n == 0) return 1.0;
    if (n == 1) return 1.0 - z;
    double lPrev = 1.0, lCur = 1.0 - z;
    for (int k = 2; k <= n; k++) {
      final lNext = ((2 * k - 1 - z) * lCur - (k - 1) * lPrev) / k;
      lPrev = lCur;
      lCur = lNext;
    }
    return lCur;
  }

  double _wignerFock(int n, double x, double p, double squeeze) {
    final xs = x / squeeze;
    final ps = p * squeeze;
    final r2 = xs * xs + ps * ps;
    final exp = math.exp(-r2);
    final lag = _laguerre(n, 2 * r2);
    final sign = (n % 2 == 0) ? 1.0 : -1.0;
    return sign / math.pi * exp * lag;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final n = quantumN.round().clamp(0, 5);

    // Layout: center square for colormap, right margin for p-projection, bottom margin for x-projection
    final marginR = w * 0.18;
    final marginB = h * 0.18;
    final padL = 28.0, padT = 14.0;

    final mapLeft = padL;
    final mapTop = padT;
    final mapRight = w - marginR - 4;
    final mapBot = h - marginB - 4;
    final mapW = mapRight - mapLeft;
    final mapH = mapBot - mapTop;

    // Phase space range: -3 to +3
    final phaseRange = 3.0;

    double xToMap(double x) => mapLeft + (x + phaseRange) / (2 * phaseRange) * mapW;
    double pToMap(double p) => mapBot - (p + phaseRange) / (2 * phaseRange) * mapH;

    // Compute Wigner function on a grid
    const gridN = 40;
    final cells = <List<double>>[];
    double wMin = 0, wMax = 0;

    for (int ix = 0; ix < gridN; ix++) {
      final row = <double>[];
      for (int ip = 0; ip < gridN; ip++) {
        final xv = -phaseRange + (ix + 0.5) / gridN * 2 * phaseRange;
        final pv = -phaseRange + (ip + 0.5) / gridN * 2 * phaseRange;
        final w0 = _wignerFock(n, xv, pv, squeezeFactor);
        row.add(w0);
        if (w0 < wMin) wMin = w0;
        if (w0 > wMax) wMax = w0;
      }
      cells.add(row);
    }

    final wAbs = math.max(wMax.abs(), wMin.abs()).clamp(0.001, 10.0);
    final cellW = mapW / gridN;
    final cellH = mapH / gridN;

    for (int ix = 0; ix < gridN; ix++) {
      for (int ip = 0; ip < gridN; ip++) {
        final val = cells[ix][ip];
        final t = (val / wAbs).clamp(-1.0, 1.0);
        Color cellColor;
        if (t >= 0) {
          // Positive: dark -> cyan
          cellColor = Color.lerp(
              const Color(0xFF0D1A20), const Color(0xFF00D4FF), t)!;
        } else {
          // Negative: dark -> orange (quantum interference)
          cellColor = Color.lerp(
              const Color(0xFF0D1A20), const Color(0xFFFF6B35), -t)!;
        }
        final cx = mapLeft + ix * cellW;
        final cy = mapBot - (ip + 1) * cellH;
        canvas.drawRect(
          Rect.fromLTWH(cx, cy, cellW + 0.5, cellH + 0.5),
          Paint()..color = cellColor,
        );
      }
    }

    // Axes
    final axisPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1;
    // x-axis (center horizontal)
    final axisY = pToMap(0);
    canvas.drawLine(Offset(mapLeft, axisY), Offset(mapRight, axisY), axisPaint);
    // p-axis (center vertical)
    final axisX = xToMap(0);
    canvas.drawLine(Offset(axisX, mapTop), Offset(axisX, mapBot), axisPaint);

    _label(canvas, 'x', Offset(mapRight - 8, axisY + 2), color: const Color(0xFF5A8A9A));
    _label(canvas, 'p', Offset(axisX + 2, mapTop), color: const Color(0xFF5A8A9A));

    // ---- Right margin: p-marginal distribution ----
    final pMarLeft = mapRight + 6;
    final pMarRight = w - 2.0;
    final pMarW = pMarRight - pMarLeft;

    final pMargPath = Path()..moveTo(pMarLeft, mapBot);
    for (int ip = 0; ip < gridN; ip++) {
      double sum = 0;
      for (int ix = 0; ix < gridN; ix++) {
        sum += cells[ix][ip];
      }
      sum /= gridN;
      final py = mapBot - (ip + 0.5) / gridN * mapH;
      final px = pMarLeft + (sum / wAbs + 1) / 2 * pMarW;
      pMargPath.lineTo(px.clamp(pMarLeft, pMarRight), py);
    }
    pMargPath.lineTo(pMarLeft, mapTop);
    pMargPath.close();
    canvas.drawPath(pMargPath,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.3));
    final pMargStroke = Path()..moveTo(pMarLeft, mapBot);
    for (int ip = 0; ip < gridN; ip++) {
      double sum = 0;
      for (int ix = 0; ix < gridN; ix++) {
        sum += cells[ix][ip];
      }
      sum /= gridN;
      final py = mapBot - (ip + 0.5) / gridN * mapH;
      final px = pMarLeft + (sum / wAbs + 1) / 2 * pMarW;
      pMargStroke.lineTo(px.clamp(pMarLeft, pMarRight), py);
    }
    canvas.drawPath(pMargStroke,
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.2..style = PaintingStyle.stroke);
    _label(canvas, '|p>', Offset(pMarLeft, mapTop - 12), color: const Color(0xFF5A8A9A), fontSize: 8);

    // ---- Bottom margin: x-marginal distribution ----
    final xMarTop = mapBot + 6;
    final xMarBot = h - 2.0;
    final xMarH = xMarBot - xMarTop;

    final xMargPath = Path()..moveTo(mapLeft, xMarTop);
    for (int ix = 0; ix < gridN; ix++) {
      double sum = 0;
      for (int ip = 0; ip < gridN; ip++) {
        sum += cells[ix][ip];
      }
      sum /= gridN;
      final px = mapLeft + (ix + 0.5) / gridN * mapW;
      final py = xMarTop + xMarH / 2 - (sum / wAbs) * xMarH * 0.45;
      xMargPath.lineTo(px, py.clamp(xMarTop, xMarBot));
    }
    xMargPath.lineTo(mapRight, xMarTop + xMarH / 2);
    xMargPath.close();
    canvas.drawPath(xMargPath,
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.3));
    final xMargStroke = Path()..moveTo(mapLeft, xMarTop + xMarH / 2);
    for (int ix = 0; ix < gridN; ix++) {
      double sum = 0;
      for (int ip = 0; ip < gridN; ip++) {
        sum += cells[ix][ip];
      }
      sum /= gridN;
      final px = mapLeft + (ix + 0.5) / gridN * mapW;
      final py = xMarTop + xMarH / 2 - (sum / wAbs) * xMarH * 0.45;
      xMargStroke.lineTo(px, py.clamp(xMarTop, xMarBot));
    }
    canvas.drawPath(xMargStroke,
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.2..style = PaintingStyle.stroke);
    _label(canvas, '<x|', Offset(mapRight + 2, xMarTop), color: const Color(0xFF5A8A9A), fontSize: 8);

    // Legend
    _label(canvas, '+ W(x,p)', Offset(padL, mapTop),
        color: const Color(0xFF00D4FF), fontSize: 8);
    _label(canvas, '- W(x,p)', Offset(padL + 52, mapTop),
        color: const Color(0xFFFF6B35), fontSize: 8);

    // State label
    final stateName = n == 0 ? '|0⟩ 바닥 상태' : '|$n⟩ 포크 상태';
    _label(canvas, stateName, Offset(padL, mapBot + marginB * 0.5),
        color: const Color(0xFF00D4FF), fontSize: 9);
    _label(canvas, 'sq=${squeezeFactor.toStringAsFixed(1)}',
        Offset(padL + mapW * 0.55, mapBot + marginB * 0.5),
        color: const Color(0xFF5A8A9A), fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _WignerFunctionScreenPainter oldDelegate) => true;
}
