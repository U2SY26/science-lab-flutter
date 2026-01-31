import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 피타고라스 정리 증명 시뮬레이션
class PythagoreanScreen extends StatefulWidget {
  const PythagoreanScreen({super.key});

  @override
  State<PythagoreanScreen> createState() => _PythagoreanScreenState();
}

class _PythagoreanScreenState extends State<PythagoreanScreen> {
  String _proof = 'squares';
  double _a = 3;
  double _b = 4;

  double get _c => math.sqrt(_a * _a + _b * _b);

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
              '수학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '피타고라스 정리',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '피타고라스 정리',
          formula: 'a² + b² = c²',
          formulaDescription: '직각삼각형의 빗변 길이 관계',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _PythagoreanPainter(
                proof: _proof,
                a: _a,
                b: _b,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 값 표시
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: 'a', value: _a.toStringAsFixed(1), color: Colors.red),
                        _InfoItem(label: 'b', value: _b.toStringAsFixed(1), color: Colors.green),
                        _InfoItem(label: 'c', value: _c.toStringAsFixed(2), color: Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${(_a * _a).toStringAsFixed(1)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        const Text(' + ', style: TextStyle(color: AppColors.muted)),
                        Text('${(_b * _b).toStringAsFixed(1)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        const Text(' = ', style: TextStyle(color: AppColors.muted)),
                        Text('${(_c * _c).toStringAsFixed(1)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'a² + b² = c²',
                      style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 증명 방법 선택
              PresetGroup(
                label: '증명 방법',
                presets: [
                  PresetButton(
                    label: '정사각형',
                    isSelected: _proof == 'squares',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _proof = 'squares');
                    },
                  ),
                  PresetButton(
                    label: '재배열',
                    isSelected: _proof == 'rearrange',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _proof = 'rearrange');
                    },
                  ),
                  PresetButton(
                    label: '유클리드',
                    isSelected: _proof == 'euclid',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _proof = 'euclid');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: 'a 값',
                  value: _a,
                  min: 1,
                  max: 5,
                  defaultValue: 3,
                  formatValue: (v) => v.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _a = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: 'b 값',
                    value: _b,
                    min: 1,
                    max: 5,
                    defaultValue: 4,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _b = v),
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

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _PythagoreanPainter extends CustomPainter {
  final String proof;
  final double a, b;

  _PythagoreanPainter({required this.proof, required this.a, required this.b});

  double get c => math.sqrt(a * a + b * b);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    switch (proof) {
      case 'squares':
        _drawSquaresProof(canvas, size);
        break;
      case 'rearrange':
        _drawRearrangeProof(canvas, size);
        break;
      case 'euclid':
        _drawEuclidProof(canvas, size);
        break;
    }
  }

  void _drawSquaresProof(Canvas canvas, Size size) {
    final scale = size.width / 12;
    final offsetX = size.width / 2 - (a + b) * scale / 2;
    final offsetY = size.height / 2 - (a + b) * scale / 2;

    // 삼각형
    final triPath = Path()
      ..moveTo(offsetX, offsetY + a * scale)
      ..lineTo(offsetX + b * scale, offsetY + a * scale)
      ..lineTo(offsetX, offsetY)
      ..close();

    canvas.drawPath(triPath, Paint()..color = Colors.purple.withValues(alpha: 0.3));
    canvas.drawPath(
      triPath,
      Paint()
        ..color = Colors.purple
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // a² 정사각형
    canvas.drawRect(
      Rect.fromLTWH(offsetX - a * scale, offsetY, a * scale, a * scale),
      Paint()..color = Colors.red.withValues(alpha: 0.3),
    );
    canvas.drawRect(
      Rect.fromLTWH(offsetX - a * scale, offsetY, a * scale, a * scale),
      Paint()..color = Colors.red..strokeWidth = 2..style = PaintingStyle.stroke,
    );

    // b² 정사각형
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY + a * scale, b * scale, b * scale),
      Paint()..color = Colors.green.withValues(alpha: 0.3),
    );
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY + a * scale, b * scale, b * scale),
      Paint()..color = Colors.green..strokeWidth = 2..style = PaintingStyle.stroke,
    );

    // c² 정사각형 (회전된 상태)
    final cx = offsetX + b * scale + c * scale * 0.7;
    final cy = offsetY + a * scale / 2;
    final angle = math.atan2(a, b);

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(-angle);
    canvas.drawRect(
      Rect.fromLTWH(-c * scale / 2, -c * scale / 2, c * scale, c * scale),
      Paint()..color = Colors.blue.withValues(alpha: 0.3),
    );
    canvas.drawRect(
      Rect.fromLTWH(-c * scale / 2, -c * scale / 2, c * scale, c * scale),
      Paint()..color = Colors.blue..strokeWidth = 2..style = PaintingStyle.stroke,
    );
    canvas.restore();

    // 레이블
    _drawText(canvas, 'a²', Offset(offsetX - a * scale / 2 - 8, offsetY + a * scale / 2 - 8), Colors.red, fontSize: 14);
    _drawText(canvas, 'b²', Offset(offsetX + b * scale / 2 - 8, offsetY + a * scale + b * scale / 2 - 8), Colors.green, fontSize: 14);
    _drawText(canvas, 'c²', Offset(cx - 8, cy - 8), Colors.blue, fontSize: 14);
  }

  void _drawRearrangeProof(Canvas canvas, Size size) {
    final scale = size.width / 14;
    final side = a + b;

    // 왼쪽: 큰 정사각형 안에 4개 삼각형 + c² 정사각형
    final leftX = size.width / 4 - side * scale / 2;
    final leftY = size.height / 2 - side * scale / 2;

    canvas.drawRect(
      Rect.fromLTWH(leftX, leftY, side * scale, side * scale),
      Paint()..color = AppColors.muted..strokeWidth = 2..style = PaintingStyle.stroke,
    );

    // 4개의 삼각형
    _drawTriangle(canvas, leftX, leftY, a * scale, b * scale, Colors.purple);
    _drawTriangle(canvas, leftX + b * scale, leftY, a * scale, b * scale, Colors.purple, rotated: 1);
    _drawTriangle(canvas, leftX + side * scale, leftY + a * scale, a * scale, b * scale, Colors.purple, rotated: 2);
    _drawTriangle(canvas, leftX + a * scale, leftY + side * scale, a * scale, b * scale, Colors.purple, rotated: 3);

    // 중앙 c² 정사각형
    final cSquarePath = Path()
      ..moveTo(leftX + b * scale, leftY)
      ..lineTo(leftX + side * scale, leftY + a * scale)
      ..lineTo(leftX + a * scale, leftY + side * scale)
      ..lineTo(leftX, leftY + b * scale)
      ..close();

    canvas.drawPath(cSquarePath, Paint()..color = Colors.blue.withValues(alpha: 0.3));
    canvas.drawPath(cSquarePath, Paint()..color = Colors.blue..strokeWidth = 2..style = PaintingStyle.stroke);

    // 오른쪽: a² + b² 정사각형
    final rightX = 3 * size.width / 4 - side * scale / 2;
    final rightY = size.height / 2 - side * scale / 2;

    canvas.drawRect(
      Rect.fromLTWH(rightX, rightY, side * scale, side * scale),
      Paint()..color = AppColors.muted..strokeWidth = 2..style = PaintingStyle.stroke,
    );

    // a²
    canvas.drawRect(
      Rect.fromLTWH(rightX, rightY, a * scale, a * scale),
      Paint()..color = Colors.red.withValues(alpha: 0.3),
    );
    canvas.drawRect(
      Rect.fromLTWH(rightX, rightY, a * scale, a * scale),
      Paint()..color = Colors.red..strokeWidth = 2..style = PaintingStyle.stroke,
    );

    // b²
    canvas.drawRect(
      Rect.fromLTWH(rightX + a * scale, rightY + a * scale, b * scale, b * scale),
      Paint()..color = Colors.green.withValues(alpha: 0.3),
    );
    canvas.drawRect(
      Rect.fromLTWH(rightX + a * scale, rightY + a * scale, b * scale, b * scale),
      Paint()..color = Colors.green..strokeWidth = 2..style = PaintingStyle.stroke,
    );

    // 4개의 삼각형 (같은 위치)
    _drawTriangle(canvas, rightX + a * scale, rightY, a * scale, b * scale, Colors.purple);
    _drawTriangle(canvas, rightX, rightY + a * scale, a * scale, b * scale, Colors.purple, rotated: 3);

    // = 표시
    _drawText(canvas, '=', Offset(size.width / 2 - 10, size.height / 2 - 15), AppColors.ink, fontSize: 30);
    _drawText(canvas, 'c²', Offset(leftX + side * scale / 2 - 8, leftY + side * scale + 10), Colors.blue, fontSize: 12);
    _drawText(canvas, 'a² + b²', Offset(rightX + side * scale / 2 - 20, rightY + side * scale + 10), AppColors.ink, fontSize: 12);
  }

  void _drawTriangle(Canvas canvas, double x, double y, double aLen, double bLen, Color color, {int rotated = 0}) {
    final path = Path();
    switch (rotated) {
      case 0:
        path.moveTo(x, y);
        path.lineTo(x + bLen, y);
        path.lineTo(x, y + aLen);
        break;
      case 1:
        path.moveTo(x, y);
        path.lineTo(x + aLen, y);
        path.lineTo(x + aLen, y + bLen);
        break;
      case 2:
        path.moveTo(x, y);
        path.lineTo(x, y + bLen);
        path.lineTo(x - aLen, y + bLen);
        break;
      case 3:
        path.moveTo(x, y);
        path.lineTo(x, y - aLen);
        path.lineTo(x + bLen, y);
        break;
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.3));
    canvas.drawPath(path, Paint()..color = color..strokeWidth = 1..style = PaintingStyle.stroke);
  }

  void _drawEuclidProof(Canvas canvas, Size size) {
    final scale = size.width / 10;
    final offsetX = size.width / 2 - b * scale / 2;
    final offsetY = size.height / 2;

    // 직각삼각형
    final A = Offset(offsetX, offsetY);
    final B = Offset(offsetX + b * scale, offsetY);
    final C = Offset(offsetX, offsetY - a * scale);

    final triPath = Path()..moveTo(A.dx, A.dy)..lineTo(B.dx, B.dy)..lineTo(C.dx, C.dy)..close();
    canvas.drawPath(triPath, Paint()..color = Colors.purple.withValues(alpha: 0.2));
    canvas.drawPath(triPath, Paint()..color = Colors.purple..strokeWidth = 2..style = PaintingStyle.stroke);

    // 빗변 위의 정사각형
    final angle = math.atan2(a, b);
    final dx = c * scale * math.cos(angle + math.pi / 2);
    final dy = c * scale * math.sin(angle + math.pi / 2);

    final cSquare = Path()
      ..moveTo(C.dx, C.dy)
      ..lineTo(B.dx, B.dy)
      ..lineTo(B.dx + dx, B.dy - dy)
      ..lineTo(C.dx + dx, C.dy - dy)
      ..close();

    canvas.drawPath(cSquare, Paint()..color = Colors.blue.withValues(alpha: 0.2));
    canvas.drawPath(cSquare, Paint()..color = Colors.blue..strokeWidth = 2..style = PaintingStyle.stroke);

    // 수선
    final h = a * b / c;
    final footX = A.dx + (b * b / (c * c)) * (B.dx - A.dx) + (a * b / (c * c)) * (C.dx - A.dx);
    final footY = A.dy + (b * b / (c * c)) * (B.dy - A.dy) + (a * b / (c * c)) * (C.dy - A.dy);

    // 빗변에서 꼭짓점으로 수선
    canvas.drawLine(
      A,
      Offset(A.dx + (C.dx - A.dx) * (a / c) + (B.dx - A.dx) * (b / c), A.dy - h * scale * 0.8),
      Paint()..color = Colors.orange..strokeWidth = 1.5..style = PaintingStyle.stroke,
    );

    // 점 표시
    canvas.drawCircle(A, 5, Paint()..color = Colors.red);
    canvas.drawCircle(B, 5, Paint()..color = Colors.red);
    canvas.drawCircle(C, 5, Paint()..color = Colors.red);

    _drawText(canvas, 'A', A + const Offset(-15, 5), Colors.red);
    _drawText(canvas, 'B', B + const Offset(5, 5), Colors.red);
    _drawText(canvas, 'C', C + const Offset(-15, -5), Colors.red);
    _drawText(canvas, 'c²', Offset((C.dx + B.dx) / 2 + dx / 2 - 10, (C.dy + B.dy) / 2 - dy / 2), Colors.blue);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _PythagoreanPainter oldDelegate) => true;
}
