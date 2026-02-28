import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ShorAlgorithmScreen extends StatefulWidget {
  const ShorAlgorithmScreen({super.key});
  @override
  State<ShorAlgorithmScreen> createState() => _ShorAlgorithmScreenState();
}

class _ShorAlgorithmScreenState extends State<ShorAlgorithmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _number = 15.0;
  double _factor1 = 0, _factor2 = 0;

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
      final n = _number.toInt();
      _factor1 = 0; _factor2 = 0;
      for (int i = 2; i <= math.sqrt(n.toDouble()).toInt(); i++) {
        if (n % i == 0) { _factor1 = i.toDouble(); _factor2 = (n ~/ i).toDouble(); break; }
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _number = 15.0;
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
          const Text('쇼어 소인수분해', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '쇼어 소인수분해',
          formula: 'N = p × q',
          formulaDescription: '양자 푸리에 변환을 이용하여 소인수분해합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ShorAlgorithmScreenPainter(
                time: _time,
                number: _number,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '합성수 N',
                value: _number,
                min: 6.0,
                max: 35.0,
                defaultValue: 15.0,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => _number = v),
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
          _V('N', '${_number.toInt()}'),
          _V('인수 1', '${_factor1.toInt()}'),
          _V('인수 2', '${_factor2.toInt()}'),
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

class _ShorAlgorithmScreenPainter extends CustomPainter {
  final double time;
  final double number;

  _ShorAlgorithmScreenPainter({
    required this.time,
    required this.number,
  });

  void _lbl(Canvas canvas, String text, Offset center, Color color, double sz,
      {FontWeight fw = FontWeight.normal}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: sz, fontFamily: 'monospace', fontWeight: fw)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  // Modular exponentiation: a^x mod n
  int _modPow(int a, int x, int n) {
    int result = 1;
    a = a % n;
    for (int i = 0; i < x; i++) {
      result = (result * a) % n;
    }
    return result;
  }

  // GCD
  int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  // Find period of a^x mod n
  int _findPeriod(int a, int n) {
    int x = 1;
    for (int r = 1; r <= n; r++) {
      x = (x * a) % n;
      if (x == 1) return r;
    }
    return n;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final N = number.toInt().clamp(6, 35);

    // Pick base a (co-prime to N, not 1)
    // Use a=7 for N=15, else find valid a
    int a = 7;
    if (N != 15) {
      for (int candidate = 2; candidate < N; candidate++) {
        if (_gcd(candidate, N) == 1 && candidate != 1) {
          a = candidate;
          break;
        }
      }
    }

    final period = _findPeriod(a, N);

    // Factors via Shor
    int f1 = 0, f2 = 0;
    if (period % 2 == 0) {
      final halfPow = _modPow(a, period ~/ 2, N);
      f1 = _gcd(halfPow - 1, N);
      f2 = _gcd(halfPow + 1, N);
      if (f1 == 1 || f1 == N) { f1 = 0; f2 = 0; }
    }

    _lbl(canvas, '쇼어 알고리즘: N=$N = $f1 × $f2', Offset(w / 2, 13),
        const Color(0xFF00D4FF), 11, fw: FontWeight.bold);

    final axisP = Paint()
      ..color = const Color(0xFF2A4050)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // ======= SECTION 1: f(x) = a^x mod N (top 38%) =======
    final s1Top = 26.0, s1Bot = h * 0.38;
    final s1H = s1Bot - s1Top - 16;
    final s1L = 36.0, s1R = w - 10.0;
    final s1W = s1R - s1L;

    _lbl(canvas, '① f(x)=$a^x mod $N  주기 r=$period', Offset(s1L + s1W / 2, s1Top + 4),
        const Color(0xFF64FF8C), 9);

    // Axes
    canvas.drawLine(Offset(s1L, s1Top + 14), Offset(s1L, s1Bot - 4), axisP);
    canvas.drawLine(Offset(s1L, s1Bot - 4), Offset(s1R, s1Bot - 4), axisP);

    final xCount = (s1W / 10).floor().clamp(8, 30);
    final barW2 = s1W / xCount;

    for (int x = 0; x < xCount; x++) {
      final fx = _modPow(a, x, N);
      final barH2 = (fx / N.toDouble()) * (s1H - 4);
      final bx = s1L + x * barW2;
      final by = s1Bot - 4 - barH2;

      // Highlight period repetitions
      final isPeriodStart = (x > 0) && (x % period == 0);
      final barColor = isPeriodStart
          ? const Color(0xFFFF6B35)
          : const Color(0xFF00D4FF).withValues(alpha: 0.7);

      canvas.drawRect(Rect.fromLTWH(bx + 0.5, by, barW2 - 1, barH2), Paint()..color = barColor);

      if (x % period == 0 && x > 0) {
        // Period marker
        canvas.drawLine(Offset(bx, s1Top + 14), Offset(bx, s1Bot - 4),
            Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.4)..strokeWidth = 0.8..style = PaintingStyle.stroke);
      }
      if (x % (xCount ~/ 4).clamp(1, 8) == 0) {
        _lbl(canvas, '$x', Offset(bx + barW2 / 2, s1Bot + 2), const Color(0xFF5A8A9A), 7);
      }
    }
    // Period brace annotation
    if (period < xCount) {
      final px1 = s1L;
      final px2 = s1L + period * barW2;
      canvas.drawLine(Offset(px1, s1Bot - 18), Offset(px2, s1Bot - 18),
          Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.2..style = PaintingStyle.stroke);
      _lbl(canvas, '← r=$period →', Offset((px1 + px2) / 2, s1Bot - 26),
          const Color(0xFF64FF8C), 8);
    }
    _lbl(canvas, 'x', Offset(s1R, s1Bot), const Color(0xFF5A8A9A), 8);
    _lbl(canvas, 'f(x)', Offset(s1L - 12, (s1Top + s1Bot) / 2), const Color(0xFF5A8A9A), 8);

    // ======= SECTION 2: QFT spectrum (middle 30%) =======
    final s2Top = s1Bot + 10;
    final s2Bot = h * 0.70;
    final s2H = s2Bot - s2Top - 14;
    final s2L = s1L, s2R = s1R, s2W = s2R - s2L;

    _lbl(canvas, '② QFT 스펙트럼 |QFT(f)|²  피크 간격 1/r', Offset(s2L + s2W / 2, s2Top + 4),
        const Color(0xFFFF6B35), 9);

    canvas.drawLine(Offset(s2L, s2Top + 14), Offset(s2L, s2Bot - 4), axisP);
    canvas.drawLine(Offset(s2L, s2Bot - 4), Offset(s2R, s2Bot - 4), axisP);

    // QFT peaks at multiples of N/r
    final peakSpacing = N ~/ period;
    for (int k = 0; k < N; k++) {
      final isPeak = k % peakSpacing == 0;
      final amp = isPeak ? 1.0 : 0.08 + 0.05 * math.sin(k * 0.7 + time * 0.5).abs();
      final bH = amp * (s2H - 4);
      final bx = s2L + (k / N) * s2W;
      final by = s2Bot - 4 - bH;
      final barColor = isPeak
          ? const Color(0xFFFF6B35)
          : const Color(0xFF5A8A9A).withValues(alpha: 0.4);
      canvas.drawRect(Rect.fromLTWH(bx, by, s2W / N - 0.5, bH), Paint()..color = barColor);
    }
    // Animated QFT wave overlay
    for (int k = 0; k < N; k++) {
      if (k % peakSpacing == 0) {
        final bx = s2L + (k / N) * s2W;
        final pulse = (math.sin(time * 3 - k * 0.5) * 0.5 + 0.5) * 0.3;
        canvas.drawRect(
            Rect.fromLTWH(bx, s2Top + 14, s2W / N - 0.5, s2H - 4),
            Paint()..color = const Color(0xFFFF6B35).withValues(alpha: pulse));
      }
    }
    _lbl(canvas, 'k', Offset(s2R, s2Bot), const Color(0xFF5A8A9A), 8);

    // ======= SECTION 3: GCD factoring (bottom 30%) =======
    final s3Top = s2Bot + 8;
    final s3Bot = h - 6.0;
    final s3H = s3Bot - s3Top;

    _lbl(canvas, '③ GCD 계산 → 소인수', Offset(w / 2, s3Top + 8),
        const Color(0xFF64FF8C), 9);

    // Step boxes
    final stepY = s3Top + s3H * 0.55;
    final steps = [
      ('a=$a, r=$period', const Color(0xFF5A8A9A)),
      if (period % 2 == 0)
        ('a^(r/2)=${_modPow(a, period ~/ 2, N)}', const Color(0xFF00D4FF))
      else
        ('r 홀수\n재시도', const Color(0xFFFF6B35)),
      ('gcd(${_modPow(a, period ~/ 2, N)}-1,$N)=$f1', const Color(0xFF64FF8C)),
      ('gcd(${_modPow(a, period ~/ 2, N)}+1,$N)=$f2', const Color(0xFF64FF8C)),
    ];

    final boxW = (w - 16.0) / steps.length;
    for (int i = 0; i < steps.length; i++) {
      final bx = 8.0 + i * boxW;
      final rect = Rect.fromLTWH(bx, stepY - 14, boxW - 4, 28);
      final highlighted = i == ((time * 0.5).toInt() % steps.length);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = highlighted
              ? steps[i].$2.withValues(alpha: 0.2)
              : const Color(0xFF1A3040));
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = steps[i].$2.withValues(alpha: highlighted ? 0.9 : 0.4)
              ..strokeWidth = 1..style = PaintingStyle.stroke);
      _lbl(canvas, steps[i].$1, Offset(bx + (boxW - 4) / 2, stepY), steps[i].$2, 8);

      if (i < steps.length - 1) {
        canvas.drawLine(Offset(bx + boxW - 4, stepY), Offset(bx + boxW, stepY),
            Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
      }
    }

    // Final result
    final resColor = f1 > 1 && f2 > 1 ? const Color(0xFFFF6B35) : const Color(0xFF5A8A9A);
    final resText = f1 > 1 && f2 > 1 ? '$N = $f1 × $f2  ✓' : '$N 인수분해 실패 (a=$a)';
    _lbl(canvas, resText, Offset(w / 2, s3Bot - 4), resColor, 10, fw: FontWeight.bold);
  }

  @override
  bool shouldRepaint(covariant _ShorAlgorithmScreenPainter oldDelegate) => true;
}
