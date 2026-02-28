import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ConvolutionScreen extends StatefulWidget {
  const ConvolutionScreen({super.key});
  @override
  State<ConvolutionScreen> createState() => _ConvolutionScreenState();
}

class _ConvolutionScreenState extends State<ConvolutionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _shift = 0;
  
  double _convVal = 0.0;

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
      _convVal = math.exp(-_shift * _shift / 2);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _shift = 0.0;
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
          const Text('합성곱', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '합성곱',
          formula: '(f*g)(t) = ∫f(τ)g(t-τ)dτ',
          formulaDescription: '두 함수의 합성곱 연산을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ConvolutionScreenPainter(
                time: _time,
                shift: _shift,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '이동 (t)',
                value: _shift,
                min: -5,
                max: 5,
                step: 0.1,
                defaultValue: 0,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _shift = v),
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
          _V('(f*g)(t)', _convVal.toStringAsFixed(3)),
          _V('t', _shift.toStringAsFixed(1)),
          _V('유형', 'Gaussian'),
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

class _ConvolutionScreenPainter extends CustomPainter {
  final double time;
  final double shift;

  _ConvolutionScreenPainter({
    required this.time,
    required this.shift,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 9}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  // f[n]: box function (1 for n=0..4)
  double _f(int n) => (n >= 0 && n <= 4) ? 1.0 : 0.0;

  // g[n]: Gaussian kernel
  double _g(int n) => math.exp(-n * n / 3.0);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    const nMin = -3, nMax = 14;
    const nRange = nMax - nMin;
    final padL = 12.0, padR = 12.0;
    final plotW = size.width - padL - padR;
    final barW  = plotW / nRange;

    // Three rows
    final rowH  = size.height / 3.2;
    final row0y = rowH * 0.5;         // f[n] center
    final row1y = rowH * 1.5;         // g[n] center
    final row2y = rowH * 2.65;        // (f*g)[n] center
    final ampScale = rowH * 0.38;

    // Animated kernel shift: auto-animate if time running, clamp to range
    final autoShift = (time * 1.2) % (nRange + 6.0) - 3.0;
    final kShift = shift == 0 ? autoShift.round() : shift.round().clamp(nMin - 2, nMax + 2);

    void drawStemRow(int rowCy, Color color, String label, double Function(int) fn, {bool isKernel = false, int? kernelShift}) {
      final cy = rowCy.toDouble();
      canvas.drawLine(Offset(padL, cy), Offset(size.width - padR, cy),
        Paint()..color = AppColors.muted.withValues(alpha: 0.35)..strokeWidth = 0.7);

      for (int n = nMin; n < nMax; n++) {
        final val = isKernel ? fn(n - (kernelShift ?? 0)) : fn(n);
        if (val.abs() < 0.005) continue;
        final px = padL + (n - nMin) * barW + barW / 2;
        final barH = val * ampScale;

        // Highlight overlap region
        final inOverlap = isKernel && (n - (kernelShift ?? 0) >= -2) && (n - (kernelShift ?? 0) <= 2);
        final drawColor = inOverlap
            ? AppColors.accent2.withValues(alpha: 0.9)
            : color.withValues(alpha: 0.8);

        canvas.drawLine(Offset(px, cy), Offset(px, cy - barH),
          Paint()..color = drawColor..strokeWidth = barW * 0.55..strokeCap = StrokeCap.butt);
        canvas.drawCircle(Offset(px, cy - barH), 2.5, Paint()..color = drawColor);
      }
      _drawLabel(canvas, label, Offset(padL, cy - ampScale - 14), color, fontSize: 9);
    }

    // Top: f[n] (cyan)
    drawStemRow(row0y.round(), AppColors.accent, 'f[n]  입력 신호', _f);

    // Middle: g[n] kernel sliding
    drawStemRow(row1y.round(), AppColors.accent2, 'g[n]  커널 (이동 중)', _g, isKernel: true, kernelShift: kShift);

    // Kernel position indicator
    final kernPx = padL + (kShift - nMin) * barW + barW / 2;
    if (kernPx > padL && kernPx < size.width - padR) {
      canvas.drawLine(Offset(kernPx, row1y - ampScale - 4), Offset(kernPx, row2y + ampScale + 4),
        Paint()..color = AppColors.accent2.withValues(alpha: 0.25)..strokeWidth = 1);
    }

    // Bottom: output (f*g)[n] building up
    final cy2 = row2y;
    canvas.drawLine(Offset(padL, cy2), Offset(size.width - padR, cy2),
      Paint()..color = AppColors.muted.withValues(alpha: 0.35)..strokeWidth = 0.7);

    for (int n = nMin; n < nMax; n++) {
      // Only draw output up to current kernel position
      if (n > kShift + 2) break;
      double conv = 0;
      for (int k = nMin; k < nMax; k++) {
        conv += _f(k) * _g(n - k);
      }
      if (conv.abs() < 0.005) continue;
      final px = padL + (n - nMin) * barW + barW / 2;
      final barH = conv * ampScale * 0.7;
      final c = const Color(0xFF64FF8C).withValues(alpha: 0.85);
      canvas.drawLine(Offset(px, cy2), Offset(px, cy2 - barH),
        Paint()..color = c..strokeWidth = barW * 0.55..strokeCap = StrokeCap.butt);
      canvas.drawCircle(Offset(px, cy2 - barH), 2.5, Paint()..color = c);
    }
    _drawLabel(canvas, '(f*g)[n]  출력 합성곱', Offset(padL, cy2 - ampScale - 14), const Color(0xFF64FF8C), fontSize: 9);
  }

  @override
  bool shouldRepaint(covariant _ConvolutionScreenPainter oldDelegate) => true;
}
