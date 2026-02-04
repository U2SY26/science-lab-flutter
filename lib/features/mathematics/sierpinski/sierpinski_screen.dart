import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Sierpinski Triangle Visualization
/// 시에르핀스키 삼각형 시각화
class SierpinskiScreen extends StatefulWidget {
  const SierpinskiScreen({super.key});

  @override
  State<SierpinskiScreen> createState() => _SierpinskiScreenState();
}

class _SierpinskiScreenState extends State<SierpinskiScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int depth = 5;
  int generationMethod = 0; // 0: recursive, 1: chaos game
  bool showAnimation = false;
  int chaosGamePoints = 0;
  final List<Offset> _chaosPoints = [];
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(() {
        if (showAnimation && generationMethod == 1) {
          _addChaosPoint();
        }
      });
  }

  void _addChaosPoint() {
    if (_chaosPoints.isEmpty) {
      _chaosPoints.add(const Offset(0.5, 0.5));
    }

    final random = math.Random();
    final vertices = [
      const Offset(0.5, 0),
      const Offset(0, 1),
      const Offset(1, 1),
    ];

    final lastPoint = _chaosPoints.last;
    final targetVertex = vertices[random.nextInt(3)];
    final newPoint = Offset(
      (lastPoint.dx + targetVertex.dx) / 2,
      (lastPoint.dy + targetVertex.dy) / 2,
    );

    setState(() {
      _chaosPoints.add(newPoint);
      chaosGamePoints = _chaosPoints.length;
    });
  }

  void _toggleAnimation() {
    HapticFeedback.selectionClick();
    setState(() {
      showAnimation = !showAnimation;
      if (showAnimation) {
        if (generationMethod == 1) {
          _chaosPoints.clear();
          chaosGamePoints = 0;
        }
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      depth = 5;
      showAnimation = false;
      _chaosPoints.clear();
      chaosGamePoints = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Calculate fractal dimension
  double get _fractalDimension => math.log(3) / math.log(2); // ~1.585

  // Count triangles at current depth
  int get _triangleCount => math.pow(3, depth).toInt();

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
              isKorean ? '시에르핀스키 삼각형' : 'Sierpinski Triangle',
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
          title: isKorean ? '시에르핀스키 삼각형' : 'Sierpinski Triangle',
          formula: 'D = log(3)/log(2) ≈ 1.585',
          formulaDescription: isKorean
              ? '시에르핀스키 삼각형은 삼각형의 중점을 연결하여 만든 작은 삼각형을 제거하는 과정을 무한 반복하여 만듭니다.'
              : 'The Sierpinski triangle is created by recursively removing the central triangle formed by connecting midpoints.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: SierpinskiPainter(
                depth: depth,
                generationMethod: generationMethod,
                chaosPoints: _chaosPoints,
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
                      label: isKorean ? '깊이' : 'Depth',
                      value: '$depth',
                    ),
                    _InfoItem(
                      label: generationMethod == 0
                          ? (isKorean ? '삼각형 수' : 'Triangles')
                          : (isKorean ? '점 수' : 'Points'),
                      value: generationMethod == 0 ? '$_triangleCount' : '$chaosGamePoints',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Generation method
              PresetGroup(
                label: isKorean ? '생성 방법' : 'Generation Method',
                presets: [
                  PresetButton(
                    label: isKorean ? '재귀적' : 'Recursive',
                    isSelected: generationMethod == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _controller.stop();
                      setState(() {
                        generationMethod = 0;
                        showAnimation = false;
                        _chaosPoints.clear();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '카오스 게임' : 'Chaos Game',
                    isSelected: generationMethod == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        generationMethod = 1;
                        _chaosPoints.clear();
                        chaosGamePoints = 0;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (generationMethod == 0)
                SimSlider(
                  label: isKorean ? '재귀 깊이' : 'Recursion Depth',
                  value: depth.toDouble(),
                  min: 0,
                  max: 8,
                  defaultValue: 5,
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) => setState(() => depth = v.toInt()),
                ),

              if (generationMethod == 1)
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
                        isKorean ? '카오스 게임 규칙:' : 'Chaos Game Rules:',
                        style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isKorean
                            ? '1. 삼각형의 꼭짓점 중 하나를 무작위 선택\n2. 현재 점에서 선택한 꼭짓점의 중점으로 이동\n3. 반복'
                            : '1. Randomly pick a triangle vertex\n2. Move halfway to the chosen vertex\n3. Repeat',
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
              if (generationMethod == 1)
                SimButton(
                  label: showAnimation
                      ? (isKorean ? '정지' : 'Stop')
                      : (isKorean ? '시작' : 'Start'),
                  icon: showAnimation ? Icons.pause : Icons.play_arrow,
                  isPrimary: true,
                  onPressed: _toggleAnimation,
                ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                isPrimary: generationMethod == 0,
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

class SierpinskiPainter extends CustomPainter {
  final int depth;
  final int generationMethod;
  final List<Offset> chaosPoints;

  SierpinskiPainter({
    required this.depth,
    required this.generationMethod,
    required this.chaosPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 20.0;
    final triangleSize = math.min(size.width - padding * 2, size.height - padding * 2);
    final offsetX = (size.width - triangleSize) / 2;
    final offsetY = padding;

    // Triangle vertices
    final top = Offset(offsetX + triangleSize / 2, offsetY);
    final bottomLeft = Offset(offsetX, offsetY + triangleSize * 0.866);
    final bottomRight = Offset(offsetX + triangleSize, offsetY + triangleSize * 0.866);

    if (generationMethod == 0) {
      // Recursive method
      _drawSierpinskiRecursive(canvas, top, bottomLeft, bottomRight, depth);
    } else {
      // Chaos game method
      _drawChaosGame(canvas, size, triangleSize, offsetX, offsetY);
    }

    // Draw outer triangle outline
    final outlinePath = Path();
    outlinePath.moveTo(top.dx, top.dy);
    outlinePath.lineTo(bottomLeft.dx, bottomLeft.dy);
    outlinePath.lineTo(bottomRight.dx, bottomRight.dy);
    outlinePath.close();

    canvas.drawPath(
      outlinePath,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawSierpinskiRecursive(Canvas canvas, Offset p1, Offset p2, Offset p3, int depth) {
    if (depth == 0) {
      final path = Path();
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p3.dx, p3.dy);
      path.close();

      canvas.drawPath(path, Paint()..color = AppColors.accent);
      return;
    }

    // Midpoints
    final m1 = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final m2 = Offset((p2.dx + p3.dx) / 2, (p2.dy + p3.dy) / 2);
    final m3 = Offset((p3.dx + p1.dx) / 2, (p3.dy + p1.dy) / 2);

    // Recurse on three corner triangles
    _drawSierpinskiRecursive(canvas, p1, m1, m3, depth - 1);
    _drawSierpinskiRecursive(canvas, m1, p2, m2, depth - 1);
    _drawSierpinskiRecursive(canvas, m3, m2, p3, depth - 1);
  }

  void _drawChaosGame(Canvas canvas, Size size, double triangleSize, double offsetX, double offsetY) {
    if (chaosPoints.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 1;

    for (final point in chaosPoints) {
      final x = offsetX + point.dx * triangleSize;
      final y = offsetY + point.dy * triangleSize * 0.866;
      canvas.drawCircle(Offset(x, y), 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SierpinskiPainter oldDelegate) =>
      depth != oldDelegate.depth ||
      generationMethod != oldDelegate.generationMethod ||
      chaosPoints.length != oldDelegate.chaosPoints.length;
}
