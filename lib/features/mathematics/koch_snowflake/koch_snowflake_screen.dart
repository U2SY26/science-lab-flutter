import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Koch Snowflake Visualization
/// 코흐 눈송이 시각화
class KochSnowflakeScreen extends StatefulWidget {
  const KochSnowflakeScreen({super.key});

  @override
  State<KochSnowflakeScreen> createState() => _KochSnowflakeScreenState();
}

class _KochSnowflakeScreenState extends State<KochSnowflakeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int iterations = 4;
  bool showIntermediate = false;
  bool isAnimating = false;
  double animationProgress = 1.0;
  int shapeType = 0; // 0: snowflake, 1: single edge, 2: anti-snowflake
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addListener(() {
        setState(() {
          animationProgress = _controller.value;
        });
      });
  }

  void _animate() {
    HapticFeedback.mediumImpact();
    _controller.reset();
    setState(() => isAnimating = true);
    _controller.forward().then((_) {
      setState(() => isAnimating = false);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      iterations = 4;
      animationProgress = 1.0;
      isAnimating = false;
    });
  }

  // Fractal dimension: log(4)/log(3) ≈ 1.2619
  double get _fractalDimension => math.log(4) / math.log(3);

  // Number of line segments
  int get _segmentCount => math.pow(4, iterations).toInt() * (shapeType == 1 ? 1 : 3);

  // Perimeter grows by 4/3 each iteration
  double get _perimeterRatio => math.pow(4 / 3, iterations).toDouble();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              isKorean ? '프랙탈' : 'FRACTALS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '코흐 눈송이' : 'Koch Snowflake',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => isKorean = !isKorean),
            tooltip: isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '프랙탈' : 'FRACTALS',
          title: isKorean ? '코흐 눈송이' : 'Koch Snowflake',
          formula: 'D = log(4)/log(3) ≈ 1.262',
          formulaDescription: isKorean
              ? '코흐 곡선은 각 선분을 1/3 지점에서 삼각형 꼭지를 만드는 과정을 반복합니다. 무한한 둘레를 가지지만 유한한 면적입니다.'
              : 'The Koch curve replaces each segment with a triangular bump at 1/3 points. It has infinite perimeter but finite area.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: KochSnowflakePainter(
                iterations: iterations,
                showIntermediate: showIntermediate,
                animationProgress: animationProgress,
                shapeType: shapeType,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _InfoItem(
                      label: isKorean ? '프랙탈 차원' : 'Fractal Dim',
                      value: _fractalDimension.toStringAsFixed(3),
                      color: AppColors.accent,
                    ),
                    _InfoItem(
                      label: isKorean ? '선분 수' : 'Segments',
                      value: '$_segmentCount',
                    ),
                    _InfoItem(
                      label: isKorean ? '둘레 비율' : 'Perimeter ×',
                      value: _perimeterRatio.toStringAsFixed(2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Shape type
              PresetGroup(
                label: isKorean ? '도형 종류' : 'Shape Type',
                presets: [
                  PresetButton(
                    label: isKorean ? '눈송이' : 'Snowflake',
                    isSelected: shapeType == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => shapeType = 0);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '단일 변' : 'Single Edge',
                    isSelected: shapeType == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => shapeType = 1);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '안티 눈송이' : 'Anti-snowflake',
                    isSelected: shapeType == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => shapeType = 2);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SimSlider(
                label: isKorean ? '반복 횟수' : 'Iterations',
                value: iterations.toDouble(),
                min: 0,
                max: 6,
                defaultValue: 4,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) => setState(() => iterations = v.toInt()),
              ),
              const SizedBox(height: 12),

              // Paradox info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKorean ? '코흐 눈송이 역설:' : 'Koch Snowflake Paradox:',
                      style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isKorean
                          ? '둘레는 무한대로 발산하지만 면적은 원래 삼각형의 8/5배로 수렴합니다!'
                          : 'Perimeter diverges to infinity while area converges to 8/5 of the original triangle!',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '애니메이션' : 'Animate',
                icon: Icons.play_arrow,
                isPrimary: true,
                isLoading: isAnimating,
                onPressed: isAnimating ? null : _animate,
              ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class KochSnowflakePainter extends CustomPainter {
  final int iterations;
  final bool showIntermediate;
  final double animationProgress;
  final int shapeType;

  KochSnowflakePainter({
    required this.iterations,
    required this.showIntermediate,
    required this.animationProgress,
    required this.shapeType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) / 2 - 30;

    List<Offset> points;

    if (shapeType == 1) {
      // Single edge
      points = [
        Offset(centerX - radius, centerY),
        Offset(centerX + radius, centerY),
      ];
    } else {
      // Triangle (snowflake or anti-snowflake)
      points = [];
      for (int i = 0; i < 3; i++) {
        final angle = -math.pi / 2 + i * 2 * math.pi / 3;
        points.add(Offset(
          centerX + radius * math.cos(angle),
          centerY + radius * math.sin(angle),
        ));
      }
      points.add(points[0]); // Close the triangle
    }

    // Apply Koch iterations
    final effectiveIterations = (iterations * animationProgress).floor();
    for (int iter = 0; iter < effectiveIterations; iter++) {
      points = _kochIteration(points, shapeType == 2);
    }

    // Draw the curve
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Fill for snowflake
    if (shapeType != 1) {
      canvas.drawPath(
        path,
        Paint()..color = AppColors.accent.withValues(alpha: 0.2),
      );
    }

    // Draw outline
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  List<Offset> _kochIteration(List<Offset> points, bool inward) {
    final newPoints = <Offset>[];

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // Divide segment into thirds
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;

      final a = p1;
      final b = Offset(p1.dx + dx / 3, p1.dy + dy / 3);
      final d = Offset(p1.dx + 2 * dx / 3, p1.dy + 2 * dy / 3);

      // Calculate peak point (c) - equilateral triangle
      final midX = (b.dx + d.dx) / 2;
      final midY = (b.dy + d.dy) / 2;
      final length = math.sqrt(math.pow(d.dx - b.dx, 2) + math.pow(d.dy - b.dy, 2));
      final height = length * math.sqrt(3) / 2;

      // Perpendicular direction
      final perpX = -(d.dy - b.dy) / length;
      final perpY = (d.dx - b.dx) / length;

      final direction = inward ? -1.0 : 1.0;
      final c = Offset(
        midX + perpX * height * direction,
        midY + perpY * height * direction,
      );

      newPoints.add(a);
      newPoints.add(b);
      newPoints.add(c);
      newPoints.add(d);
    }
    newPoints.add(points.last);

    return newPoints;
  }

  @override
  bool shouldRepaint(covariant KochSnowflakePainter oldDelegate) =>
      iterations != oldDelegate.iterations ||
      showIntermediate != oldDelegate.showIntermediate ||
      animationProgress != oldDelegate.animationProgress ||
      shapeType != oldDelegate.shapeType;
}
