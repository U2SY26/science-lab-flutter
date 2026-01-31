import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 리만 가설 시각화
class RiemannHypothesisScreen extends StatefulWidget {
  const RiemannHypothesisScreen({super.key});

  @override
  State<RiemannHypothesisScreen> createState() => _RiemannHypothesisScreenState();
}

class _RiemannHypothesisScreenState extends State<RiemannHypothesisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  String _mode = 'zeros';
  double _imaginaryRange = 50;
  int _terms = 50;

  // 알려진 리만 제타 함수의 처음 몇 개 영점 (허수부)
  final List<double> _knownZeros = [
    14.134725,
    21.022040,
    25.010858,
    30.424876,
    32.935062,
    37.586178,
    40.918719,
    43.327073,
    48.005151,
    49.773832,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 리만 제타 함수 근사 (s = sigma + it)
  List<double> _zeta(double sigma, double t) {
    double realSum = 0;
    double imagSum = 0;

    for (int n = 1; n <= _terms; n++) {
      final logN = math.log(n);
      final nPowSigma = math.pow(n, -sigma);
      final angle = -t * logN;
      realSum += nPowSigma * math.cos(angle);
      imagSum += nPowSigma * math.sin(angle);
    }

    return [realSum, imagSum];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '밀레니엄 난제',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '리만 가설',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '밀레니엄 난제',
          title: '리만 가설 (Riemann Hypothesis)',
          formula: 'ζ(s) = Σ 1/nˢ',
          formulaDescription: '모든 비자명 영점이 Re(s)=½ 위에 존재한다는 추측',
          simulation: SizedBox(
            height: 300,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RiemannPainter(
                    mode: _mode,
                    imaginaryRange: _imaginaryRange,
                    terms: _terms,
                    knownZeros: _knownZeros,
                    animation: _controller.value,
                    zeta: _zeta,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 설명
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '상금: \$1,000,000',
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '리만 제타 함수의 모든 비자명 영점의 실수부가 ½이라는 가설입니다. '
                      '소수의 분포와 깊은 연관이 있으며, 1859년 이래 미해결입니다.',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 시각화 모드
              PresetGroup(
                label: '시각화',
                presets: [
                  PresetButton(
                    label: '영점 분포',
                    isSelected: _mode == 'zeros',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _mode = 'zeros');
                    },
                  ),
                  PresetButton(
                    label: '임계선',
                    isSelected: _mode == 'critical',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _mode = 'critical');
                    },
                  ),
                  PresetButton(
                    label: '|ζ(s)| 히트맵',
                    isSelected: _mode == 'heatmap',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _mode = 'heatmap');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '허수부 범위',
                  value: _imaginaryRange,
                  min: 20,
                  max: 100,
                  defaultValue: 50,
                  formatValue: (v) => '0 ~ ${v.toInt()}',
                  onChanged: (v) => setState(() => _imaginaryRange = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '급수 항 수',
                    value: _terms.toDouble(),
                    min: 20,
                    max: 100,
                    defaultValue: 50,
                    formatValue: (v) => '${v.toInt()}항',
                    onChanged: (v) => setState(() => _terms = v.toInt()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RiemannPainter extends CustomPainter {
  final String mode;
  final double imaginaryRange;
  final int terms;
  final List<double> knownZeros;
  final double animation;
  final List<double> Function(double, double) zeta;

  _RiemannPainter({
    required this.mode,
    required this.imaginaryRange,
    required this.terms,
    required this.knownZeros,
    required this.animation,
    required this.zeta,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0a0a1a));

    switch (mode) {
      case 'zeros':
        _drawZerosDistribution(canvas, size);
        break;
      case 'critical':
        _drawCriticalLine(canvas, size);
        break;
      case 'heatmap':
        _drawHeatmap(canvas, size);
        break;
    }
  }

  void _drawZerosDistribution(Canvas canvas, Size size) {
    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 임계선 (Re(s) = 0.5)
    final criticalX = padding + graphWidth / 2;
    canvas.drawLine(
      Offset(criticalX, padding),
      Offset(criticalX, size.height - padding),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );

    // 임계선 레이블
    _drawText(canvas, 'Re(s) = ½', Offset(criticalX - 25, 15), Colors.red, fontSize: 10);

    // 축
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      Paint()..color = AppColors.muted,
    );
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      Paint()..color = AppColors.muted,
    );

    // 레이블
    _drawText(canvas, 'Re(s)', Offset(size.width - padding - 30, size.height - padding + 10), AppColors.muted, fontSize: 10);
    _drawText(canvas, 'Im(s)', Offset(padding - 30, padding - 10), AppColors.muted, fontSize: 10);

    // 알려진 영점 표시
    for (int i = 0; i < knownZeros.length; i++) {
      final t = knownZeros[i];
      if (t > imaginaryRange) continue;

      final x = criticalX; // Re(s) = 0.5
      final y = size.height - padding - (t / imaginaryRange) * graphHeight;

      // 애니메이션된 펄스 효과
      final pulse = math.sin((animation * 2 * math.pi) + i * 0.5) * 0.3 + 0.7;

      // 글로우
      canvas.drawCircle(
        Offset(x, y),
        12 * pulse,
        Paint()..color = Colors.cyan.withValues(alpha: 0.3 * pulse),
      );

      // 영점 점
      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = Colors.cyan,
      );

      // 허수부 값
      _drawText(canvas, 't≈${t.toStringAsFixed(1)}', Offset(x + 10, y - 5), Colors.cyan, fontSize: 8);
    }

    // 정보
    _drawText(
      canvas,
      '처음 ${knownZeros.where((z) => z <= imaginaryRange).length}개 영점',
      Offset(size.width - 100, 40),
      Colors.cyan,
      fontSize: 10,
    );
  }

  void _drawCriticalLine(Canvas canvas, Size size) {
    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;
    final centerY = size.height / 2;

    // 축
    canvas.drawLine(
      Offset(padding, centerY),
      Offset(size.width - padding, centerY),
      Paint()..color = AppColors.muted,
    );

    // |ζ(0.5 + it)| 그래프
    final path = Path();
    bool started = false;

    for (double px = 0; px <= graphWidth; px += 2) {
      final t = (px / graphWidth) * imaginaryRange;
      final z = zeta(0.5, t);
      final magnitude = math.sqrt(z[0] * z[0] + z[1] * z[1]);

      final screenX = padding + px;
      final screenY = centerY - (magnitude / 5) * (graphHeight / 2);

      if (!started) {
        path.moveTo(screenX, screenY.clamp(padding, size.height - padding));
        started = true;
      } else {
        path.lineTo(screenX, screenY.clamp(padding, size.height - padding));
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 영점 위치 마커
    for (final t in knownZeros) {
      if (t > imaginaryRange) continue;
      final x = padding + (t / imaginaryRange) * graphWidth;
      canvas.drawLine(
        Offset(x, centerY - 10),
        Offset(x, centerY + 10),
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2,
      );
    }

    // 레이블
    _drawText(canvas, '|ζ(½+it)|', Offset(10, 20), Colors.blue, fontSize: 11);
    _drawText(canvas, 't = 0', Offset(padding, size.height - 20), AppColors.muted, fontSize: 9);
    _drawText(canvas, 't = ${imaginaryRange.toInt()}', Offset(size.width - padding - 30, size.height - 20), AppColors.muted, fontSize: 9);
  }

  void _drawHeatmap(Canvas canvas, Size size) {
    final resolution = 50;
    final cellWidth = size.width / resolution;
    final cellHeight = size.height / resolution;

    for (int i = 0; i < resolution; i++) {
      for (int j = 0; j < resolution; j++) {
        // s = sigma + it
        final sigma = (i / resolution) * 2; // 0 to 2
        final t = (j / resolution) * imaginaryRange;

        final z = zeta(sigma, t);
        final magnitude = math.sqrt(z[0] * z[0] + z[1] * z[1]);

        // 크기에 따른 색상
        final normalizedMag = (1 / (1 + magnitude)).clamp(0.0, 1.0);
        final color = Color.lerp(
          const Color(0xFF1a0030),
          Colors.yellow,
          normalizedMag,
        )!;

        canvas.drawRect(
          Rect.fromLTWH(i * cellWidth, (resolution - 1 - j) * cellHeight, cellWidth, cellHeight),
          Paint()..color = color,
        );
      }
    }

    // 임계선 표시
    final criticalX = (0.5 / 2) * size.width;
    canvas.drawLine(
      Offset(criticalX, 0),
      Offset(criticalX, size.height),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.8)
        ..strokeWidth = 2,
    );

    // 레이블
    _drawText(canvas, 'Re(s)=0', Offset(5, size.height - 15), AppColors.muted, fontSize: 9);
    _drawText(canvas, 'Re(s)=2', Offset(size.width - 45, size.height - 15), AppColors.muted, fontSize: 9);
    _drawText(canvas, '영점 = 밝은 영역', Offset(size.width - 90, 10), Colors.yellow, fontSize: 9);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _RiemannPainter oldDelegate) => true;
}
