import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Matrix Transformations Visualization
/// 행렬 변환 시각화
class MatrixTransformScreen extends StatefulWidget {
  const MatrixTransformScreen({super.key});

  @override
  State<MatrixTransformScreen> createState() => _MatrixTransformScreenState();
}

class _MatrixTransformScreenState extends State<MatrixTransformScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Matrix elements [a, b; c, d]
  double a = 1.0, b = 0.0, c = 0.0, d = 1.0;
  int transformType = 0; // 0: custom, 1: rotation, 2: scale, 3: shear, 4: reflection
  double angle = 0.0;
  double scaleX = 1.0, scaleY = 1.0;
  double shearX = 0.0, shearY = 0.0;
  bool showGrid = true;
  bool showBasis = true;
  bool isAnimating = false;
  double animationProgress = 1.0;
  bool isKorean = true;

  // Original matrix for animation
  double _startA = 1, _startB = 0, _startC = 0, _startD = 1;
  double _targetA = 1, _targetB = 0, _targetC = 0, _targetD = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
        setState(() {
          animationProgress = Curves.easeInOut.transform(_controller.value);
          a = _startA + (_targetA - _startA) * animationProgress;
          b = _startB + (_targetB - _startB) * animationProgress;
          c = _startC + (_targetC - _startC) * animationProgress;
          d = _startD + (_targetD - _startD) * animationProgress;
        });
      });
  }

  void _applyTransform(int type) {
    HapticFeedback.selectionClick();
    setState(() {
      transformType = type;
      _startA = a;
      _startB = b;
      _startC = c;
      _startD = d;

      switch (type) {
        case 0: // Identity
          _targetA = 1;
          _targetB = 0;
          _targetC = 0;
          _targetD = 1;
          break;
        case 1: // Rotation
          _targetA = math.cos(angle);
          _targetB = -math.sin(angle);
          _targetC = math.sin(angle);
          _targetD = math.cos(angle);
          break;
        case 2: // Scale
          _targetA = scaleX;
          _targetB = 0;
          _targetC = 0;
          _targetD = scaleY;
          break;
        case 3: // Shear
          _targetA = 1;
          _targetB = shearX;
          _targetC = shearY;
          _targetD = 1;
          break;
        case 4: // Reflection (x-axis)
          _targetA = 1;
          _targetB = 0;
          _targetC = 0;
          _targetD = -1;
          break;
        case 5: // Reflection (y-axis)
          _targetA = -1;
          _targetB = 0;
          _targetC = 0;
          _targetD = 1;
          break;
      }

      _controller.reset();
      isAnimating = true;
      _controller.forward().then((_) {
        setState(() => isAnimating = false);
      });
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      a = 1;
      b = 0;
      c = 0;
      d = 1;
      angle = 0;
      scaleX = 1;
      scaleY = 1;
      shearX = 0;
      shearY = 0;
      transformType = 0;
    });
  }

  double get _determinant => a * d - b * c;

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
              isKorean ? '선형대수학' : 'LINEAR ALGEBRA',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '행렬 변환' : 'Matrix Transformations',
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
          category: isKorean ? '선형대수학' : 'LINEAR ALGEBRA',
          title: isKorean ? '행렬 변환' : 'Matrix Transformations',
          formula: '[x\', y\'] = [a b; c d] × [x, y]',
          formulaDescription: isKorean
              ? '2×2 행렬은 2D 평면의 선형 변환을 나타냅니다. 회전, 스케일, 밀림, 반사 등의 변환이 가능합니다.'
              : 'A 2×2 matrix represents linear transformations in 2D: rotation, scaling, shearing, and reflection.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: MatrixTransformPainter(
                a: a,
                b: b,
                c: c,
                d: d,
                showGrid: showGrid,
                showBasis: showBasis,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Matrix display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '[',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            _MatrixCell(value: a),
                            const SizedBox(width: 12),
                            _MatrixCell(value: b),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _MatrixCell(value: c),
                            const SizedBox(width: 12),
                            _MatrixCell(value: d),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      ']',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        Text(
                          isKorean ? '행렬식' : 'det',
                          style: const TextStyle(color: AppColors.muted, fontSize: 10),
                        ),
                        Text(
                          _determinant.toStringAsFixed(2),
                          style: TextStyle(
                            color: _determinant.abs() < 0.01
                                ? Colors.red
                                : AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Transform presets
              PresetGroup(
                label: isKorean ? '변환 종류' : 'Transform Type',
                presets: [
                  PresetButton(
                    label: isKorean ? '항등' : 'Identity',
                    isSelected: transformType == 0,
                    onPressed: () => _applyTransform(0),
                  ),
                  PresetButton(
                    label: isKorean ? '회전' : 'Rotation',
                    isSelected: transformType == 1,
                    onPressed: () => _applyTransform(1),
                  ),
                  PresetButton(
                    label: isKorean ? '스케일' : 'Scale',
                    isSelected: transformType == 2,
                    onPressed: () => _applyTransform(2),
                  ),
                  PresetButton(
                    label: isKorean ? '밀림' : 'Shear',
                    isSelected: transformType == 3,
                    onPressed: () => _applyTransform(3),
                  ),
                  PresetButton(
                    label: isKorean ? 'X반사' : 'Flip X',
                    isSelected: transformType == 4,
                    onPressed: () => _applyTransform(4),
                  ),
                  PresetButton(
                    label: isKorean ? 'Y반사' : 'Flip Y',
                    isSelected: transformType == 5,
                    onPressed: () => _applyTransform(5),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls based on transform type
              if (transformType == 1) ...[
                SimSlider(
                  label: isKorean ? '회전 각도' : 'Rotation Angle',
                  value: angle,
                  min: -math.pi,
                  max: math.pi,
                  defaultValue: 0,
                  formatValue: (v) => '${(v * 180 / math.pi).toStringAsFixed(0)}°',
                  onChanged: (v) {
                    setState(() => angle = v);
                    _applyTransform(1);
                  },
                ),
              ],
              if (transformType == 2) ...[
                SimSlider(
                  label: isKorean ? 'X 스케일' : 'Scale X',
                  value: scaleX,
                  min: -2,
                  max: 2,
                  defaultValue: 1,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() => scaleX = v);
                    _applyTransform(2);
                  },
                ),
                const SizedBox(height: 8),
                SimSlider(
                  label: isKorean ? 'Y 스케일' : 'Scale Y',
                  value: scaleY,
                  min: -2,
                  max: 2,
                  defaultValue: 1,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() => scaleY = v);
                    _applyTransform(2);
                  },
                ),
              ],
              if (transformType == 3) ...[
                SimSlider(
                  label: isKorean ? 'X 밀림' : 'Shear X',
                  value: shearX,
                  min: -2,
                  max: 2,
                  defaultValue: 0,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() => shearX = v);
                    _applyTransform(3);
                  },
                ),
                const SizedBox(height: 8),
                SimSlider(
                  label: isKorean ? 'Y 밀림' : 'Shear Y',
                  value: shearY,
                  min: -2,
                  max: 2,
                  defaultValue: 0,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() => shearY = v);
                    _applyTransform(3);
                  },
                ),
              ],

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '격자 표시' : 'Show Grid',
                      value: showGrid,
                      onChanged: (v) => setState(() => showGrid = v),
                    ),
                  ),
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '기저 벡터' : 'Basis Vectors',
                      value: showBasis,
                      onChanged: (v) => setState(() => showBasis = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                isPrimary: true,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatrixCell extends StatelessWidget {
  final double value;

  const _MatrixCell({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        value.toStringAsFixed(2),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 14,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class MatrixTransformPainter extends CustomPainter {
  final double a, b, c, d;
  final bool showGrid;
  final bool showBasis;

  MatrixTransformPainter({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
    required this.showGrid,
    required this.showBasis,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 8;

    // Transform point
    Offset transform(double x, double y) {
      final newX = a * x + b * y;
      final newY = c * x + d * y;
      return Offset(centerX + newX * scale, centerY - newY * scale);
    }

    // Original point (no transform)
    Offset original(double x, double y) {
      return Offset(centerX + x * scale, centerY - y * scale);
    }

    // Draw original grid (light)
    if (showGrid) {
      final origGridPaint = Paint()
        ..color = AppColors.simGrid.withValues(alpha: 0.3)
        ..strokeWidth = 0.5;

      for (int i = -3; i <= 3; i++) {
        canvas.drawLine(
          original(i.toDouble(), -3),
          original(i.toDouble(), 3),
          origGridPaint,
        );
        canvas.drawLine(
          original(-3, i.toDouble()),
          original(3, i.toDouble()),
          origGridPaint,
        );
      }
    }

    // Draw transformed grid
    if (showGrid) {
      final gridPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..strokeWidth = 1;

      for (int i = -3; i <= 3; i++) {
        canvas.drawLine(
          transform(i.toDouble(), -3),
          transform(i.toDouble(), 3),
          gridPaint,
        );
        canvas.drawLine(
          transform(-3, i.toDouble()),
          transform(3, i.toDouble()),
          gridPaint,
        );
      }
    }

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      axisPaint,
    );
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      axisPaint,
    );

    // Draw basis vectors
    if (showBasis) {
      // Original basis (dashed)
      final origBasisPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.5)
        ..strokeWidth = 2;

      canvas.drawLine(original(0, 0), original(1, 0), origBasisPaint);
      canvas.drawLine(original(0, 0), original(0, 1), origBasisPaint);

      // Transformed basis
      final xBasisPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 3;

      final yBasisPaint = Paint()
        ..color = Colors.green
        ..strokeWidth = 3;

      // e1 -> [a, c]
      canvas.drawLine(transform(0, 0), transform(1, 0), xBasisPaint);
      _drawArrow(canvas, transform(0, 0), transform(1, 0), Colors.red);

      // e2 -> [b, d]
      canvas.drawLine(transform(0, 0), transform(0, 1), yBasisPaint);
      _drawArrow(canvas, transform(0, 0), transform(0, 1), Colors.green);

      // Labels
      _drawText(canvas, 'e₁', transform(1.1, 0), Colors.red);
      _drawText(canvas, 'e₂', transform(0, 1.1), Colors.green);
    }

    // Draw unit square transformation
    final squarePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final squareOutline = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(transform(0, 0).dx, transform(0, 0).dy);
    path.lineTo(transform(1, 0).dx, transform(1, 0).dy);
    path.lineTo(transform(1, 1).dx, transform(1, 1).dy);
    path.lineTo(transform(0, 1).dx, transform(0, 1).dy);
    path.close();

    canvas.drawPath(path, squarePaint);
    canvas.drawPath(path, squareOutline);

    // Draw origin
    canvas.drawCircle(transform(0, 0), 5, Paint()..color = AppColors.accent);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final direction = (to - from);
    final length = direction.distance;
    if (length < 10) return;

    final unit = direction / length;
    final normal = Offset(-unit.dy, unit.dx);
    final arrowSize = 10.0;

    final tip = to;
    final left = to - unit * arrowSize + normal * arrowSize / 2;
    final right = to - unit * arrowSize - normal * arrowSize / 2;

    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(left.dx, left.dy);
    path.lineTo(right.dx, right.dy);
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant MatrixTransformPainter oldDelegate) =>
      a != oldDelegate.a ||
      b != oldDelegate.b ||
      c != oldDelegate.c ||
      d != oldDelegate.d ||
      showGrid != oldDelegate.showGrid ||
      showBasis != oldDelegate.showBasis;
}
