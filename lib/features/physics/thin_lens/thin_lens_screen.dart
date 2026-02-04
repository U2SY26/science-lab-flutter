import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Thin Lens simulation: 1/f = 1/do + 1/di
class ThinLensScreen extends StatefulWidget {
  const ThinLensScreen({super.key});
  @override
  State<ThinLensScreen> createState() => _ThinLensScreenState();
}

class _ThinLensScreenState extends State<ThinLensScreen> {
  double objectDistance = 150; // mm
  double focalLength = 50; // mm
  bool isConverging = true; // true = convex, false = concave
  bool isKorean = true;

  double get f => isConverging ? focalLength : -focalLength;
  double get imageDistance => (objectDistance * f) / (objectDistance - f);
  double get magnification => -imageDistance / objectDistance;
  bool get isRealImage => imageDistance > 0;
  bool get isUpright => magnification > 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '광학' : 'OPTICS', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '얇은 렌즈' : 'Thin Lens', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '광학' : 'Optics',
          title: isKorean ? '얇은 렌즈' : 'Thin Lens',
          formula: '1/f = 1/do + 1/di',
          formulaDescription: isKorean ? '렌즈 공식: 초점거리, 물체거리, 상거리의 관계' : 'Lens equation: Relationship between focal length, object and image distances',
          simulation: CustomPaint(painter: _ThinLensPainter(objectDistance: objectDistance, focalLength: focalLength, imageDistance: imageDistance, magnification: magnification, isConverging: isConverging, isRealImage: isRealImage, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSegment<bool>(label: isKorean ? '렌즈 유형' : 'Lens Type', options: {true: isKorean ? '볼록 (수렴)' : 'Convex', false: isKorean ? '오목 (발산)' : 'Concave'}, selected: isConverging, onChanged: (v) => setState(() => isConverging = v)),
            const SizedBox(height: 16),
            SimSlider(label: isKorean ? '물체 거리 (do)' : 'Object Distance (do)', value: objectDistance, min: 20, max: 300, defaultValue: 150, formatValue: (v) => '${v.toStringAsFixed(0)} mm', onChanged: (v) => setState(() => objectDistance = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '초점 거리 (|f|)' : 'Focal Length (|f|)', value: focalLength, min: 20, max: 100, defaultValue: 50, formatValue: (v) => '${v.toStringAsFixed(0)} mm', onChanged: (v) => setState(() => focalLength = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('di', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${imageDistance.toStringAsFixed(1)} mm', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('M', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${magnification.toStringAsFixed(2)}x', style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: isRealImage ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(isRealImage ? (isKorean ? '실상' : 'Real') : (isKorean ? '허상' : 'Virtual'), textAlign: TextAlign.center, style: TextStyle(color: isRealImage ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: isUpright ? Colors.blue.withValues(alpha: 0.2) : Colors.purple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(isUpright ? (isKorean ? '정립' : 'Upright') : (isKorean ? '도립' : 'Inverted'), textAlign: TextAlign.center, style: TextStyle(color: isUpright ? Colors.blue : Colors.purple, fontSize: 10, fontWeight: FontWeight.w600)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: magnification.abs() > 1 ? Colors.red.withValues(alpha: 0.2) : Colors.cyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text(magnification.abs() > 1 ? (isKorean ? '확대' : 'Enlarged') : (isKorean ? '축소' : 'Reduced'), textAlign: TextAlign.center, style: TextStyle(color: magnification.abs() > 1 ? Colors.red : Colors.cyan, fontSize: 10, fontWeight: FontWeight.w600)),
                  )),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ThinLensPainter extends CustomPainter {
  final double objectDistance, focalLength, imageDistance, magnification;
  final bool isConverging, isRealImage, isKorean;

  _ThinLensPainter({required this.objectDistance, required this.focalLength, required this.imageDistance, required this.magnification, required this.isConverging, required this.isRealImage, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height * 0.45;
    final scale = 0.8; // pixels per mm

    // Optical axis
    canvas.drawLine(Offset(20, centerY), Offset(size.width - 20, centerY), Paint()..color = AppColors.muted..strokeWidth = 1);

    // Lens
    if (isConverging) {
      // Convex lens
      final lensPath = Path();
      lensPath.moveTo(centerX, centerY - 60);
      lensPath.quadraticBezierTo(centerX + 15, centerY, centerX, centerY + 60);
      lensPath.quadraticBezierTo(centerX - 15, centerY, centerX, centerY - 60);
      canvas.drawPath(lensPath, Paint()..color = Colors.lightBlue.withValues(alpha: 0.5));
      canvas.drawPath(lensPath, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);
    } else {
      // Concave lens
      final lensPath = Path();
      lensPath.moveTo(centerX - 5, centerY - 60);
      lensPath.quadraticBezierTo(centerX + 10, centerY, centerX - 5, centerY + 60);
      lensPath.lineTo(centerX + 5, centerY + 60);
      lensPath.quadraticBezierTo(centerX - 10, centerY, centerX + 5, centerY - 60);
      lensPath.close();
      canvas.drawPath(lensPath, Paint()..color = Colors.lightBlue.withValues(alpha: 0.3));
      canvas.drawPath(lensPath, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    // Focal points
    final focalX = focalLength * scale;
    canvas.drawCircle(Offset(centerX - focalX, centerY), 4, Paint()..color = Colors.orange);
    canvas.drawCircle(Offset(centerX + focalX, centerY), 4, Paint()..color = Colors.orange);
    _drawText(canvas, 'F', Offset(centerX - focalX - 5, centerY + 10), Colors.orange, 10);
    _drawText(canvas, "F'", Offset(centerX + focalX - 5, centerY + 10), Colors.orange, 10);

    // Object
    final objectX = centerX - objectDistance * scale;
    final objectHeight = 40.0;
    canvas.drawLine(Offset(objectX, centerY), Offset(objectX, centerY - objectHeight), Paint()..color = Colors.green..strokeWidth = 3);
    _drawArrow(canvas, Offset(objectX, centerY), Offset(objectX, centerY - objectHeight), Colors.green);
    _drawText(canvas, isKorean ? '물체' : 'Object', Offset(objectX - 15, centerY - objectHeight - 15), Colors.green, 10);

    // Image
    final imageX = centerX + imageDistance * scale;
    final imageHeight = objectHeight * magnification.abs();
    final imageY = isRealImage ? centerY + (magnification > 0 ? -imageHeight : imageHeight) : centerY - imageHeight;

    if (imageDistance.abs() < 500) { // Only draw if image is within reasonable bounds
      if (isRealImage) {
        canvas.drawLine(Offset(imageX, centerY), Offset(imageX, imageY), Paint()..color = Colors.red..strokeWidth = 3);
        _drawArrow(canvas, Offset(imageX, centerY), Offset(imageX, imageY), Colors.red);
      } else {
        // Virtual image (dashed)
        for (double y = centerY; y > imageY; y -= 8) {
          canvas.drawLine(Offset(imageX, y), Offset(imageX, math.max(y - 4, imageY)), Paint()..color = Colors.red..strokeWidth = 3);
        }
      }
      _drawText(canvas, isKorean ? '상' : 'Image', Offset(imageX - 10, imageY - 15), Colors.red, 10);
    }

    // Ray tracing
    final rayColor = Colors.yellow;

    // Ray 1: Parallel to axis, through focal point
    canvas.drawLine(Offset(objectX, centerY - objectHeight), Offset(centerX, centerY - objectHeight), Paint()..color = rayColor..strokeWidth = 1.5);
    if (isConverging) {
      if (isRealImage) {
        canvas.drawLine(Offset(centerX, centerY - objectHeight), Offset(imageX, imageY), Paint()..color = rayColor..strokeWidth = 1.5);
      } else {
        canvas.drawLine(Offset(centerX, centerY - objectHeight), Offset(size.width - 20, centerY - objectHeight + (size.width - 20 - centerX) * objectHeight / focalX), Paint()..color = rayColor..strokeWidth = 1.5);
        // Virtual ray extension
        canvas.drawLine(Offset(centerX, centerY - objectHeight), Offset(imageX, imageY), Paint()..color = rayColor.withValues(alpha: 0.3)..strokeWidth = 1);
      }
    } else {
      canvas.drawLine(Offset(centerX, centerY - objectHeight), Offset(size.width - 20, centerY - objectHeight - (size.width - 20 - centerX) * objectHeight / focalX), Paint()..color = rayColor..strokeWidth = 1.5);
    }

    // Ray 2: Through center of lens
    if (imageDistance.abs() < 500) {
      canvas.drawLine(Offset(objectX, centerY - objectHeight), Offset(imageX, imageY), Paint()..color = Colors.cyan..strokeWidth = 1.5);
    }

    // Labels
    _drawText(canvas, 'do = ${objectDistance.toStringAsFixed(0)}mm', Offset(20, size.height - 40), AppColors.muted, 10);
    _drawText(canvas, 'di = ${imageDistance.toStringAsFixed(0)}mm', Offset(size.width - 100, size.height - 40), AppColors.muted, 10);
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final arrowLength = 8.0;
    canvas.drawLine(to, Offset(to.dx - arrowLength * math.cos(angle - 0.5), to.dy - arrowLength * math.sin(angle - 0.5)), Paint()..color = color..strokeWidth = 3);
    canvas.drawLine(to, Offset(to.dx - arrowLength * math.cos(angle + 0.5), to.dy - arrowLength * math.sin(angle + 0.5)), Paint()..color = color..strokeWidth = 3);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _ThinLensPainter oldDelegate) => true;
}
