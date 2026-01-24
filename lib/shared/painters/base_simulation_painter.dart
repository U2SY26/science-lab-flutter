import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// 기본 시뮬레이션 페인터
/// 모든 CustomPainter의 기본 클래스
abstract class BaseSimulationPainter extends CustomPainter {
  final Color backgroundColor;
  final Color gridColor;
  final Color accentColor;

  BaseSimulationPainter({
    this.backgroundColor = AppColors.simBg,
    this.gridColor = AppColors.simGrid,
    this.accentColor = AppColors.accent,
  });

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  /// 배경 그리기 (페이드 효과)
  void drawBackground(Canvas canvas, Size size, {double opacity = 0.15}) {
    final paint = Paint()..color = backgroundColor.withValues(alpha: opacity);
    canvas.drawRect(Offset.zero & size, paint);
  }

  /// 그리드 그리기
  void drawGrid(Canvas canvas, Size size, {int divisions = 20}) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final stepX = size.width / divisions;
    final stepY = size.height / divisions;

    for (int i = 0; i <= divisions; i++) {
      canvas.drawLine(
        Offset(i * stepX, 0),
        Offset(i * stepX, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, i * stepY),
        Offset(size.width, i * stepY),
        paint,
      );
    }
  }

  /// 궤적 그리기
  void drawTrail(
    Canvas canvas,
    List<Offset> trail,
    Color color, {
    double lineWidth = 2,
  }) {
    if (trail.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(trail.first.dx, trail.first.dy);
    for (int i = 1; i < trail.length; i++) {
      path.lineTo(trail[i].dx, trail[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  /// 정보 텍스트 그리기
  void drawInfoText(
    Canvas canvas,
    String text,
    Offset position, {
    double fontSize = 12,
    Color color = Colors.white70,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }
}
