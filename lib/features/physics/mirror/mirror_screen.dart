import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Curved Mirrors simulation
class MirrorScreen extends StatefulWidget {
  const MirrorScreen({super.key});
  @override
  State<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends State<MirrorScreen> {
  double objectDistance = 150; // mm
  double focalLength = 50; // mm
  bool isConcave = true; // true = concave, false = convex
  bool isKorean = true;

  double get f => isConcave ? focalLength : -focalLength;
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
          Text(isKorean ? '곡면 거울' : 'Curved Mirrors', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '광학' : 'Optics',
          title: isKorean ? '곡면 거울' : 'Curved Mirrors',
          formula: '1/f = 1/do + 1/di',
          formulaDescription: isKorean ? '거울 공식: 오목 거울은 빛을 모으고, 볼록 거울은 빛을 발산시킵니다.' : 'Mirror equation: Concave mirrors converge light, convex mirrors diverge light.',
          simulation: CustomPaint(painter: _MirrorPainter(objectDistance: objectDistance, focalLength: focalLength, imageDistance: imageDistance, magnification: magnification, isConcave: isConcave, isRealImage: isRealImage, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSegment<bool>(label: isKorean ? '거울 유형' : 'Mirror Type', options: {true: isKorean ? '오목 (수렴)' : 'Concave', false: isKorean ? '볼록 (발산)' : 'Convex'}, selected: isConcave, onChanged: (v) => setState(() => isConcave = v)),
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
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MirrorPainter extends CustomPainter {
  final double objectDistance, focalLength, imageDistance, magnification;
  final bool isConcave, isRealImage, isKorean;

  _MirrorPainter({required this.objectDistance, required this.focalLength, required this.imageDistance, required this.magnification, required this.isConcave, required this.isRealImage, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final mirrorX = size.width * 0.75;
    final centerY = size.height * 0.45;
    final scale = 0.7;

    // Optical axis
    canvas.drawLine(Offset(20, centerY), Offset(mirrorX, centerY), Paint()..color = AppColors.muted..strokeWidth = 1);

    // Mirror
    final mirrorHeight = 120.0;
    if (isConcave) {
      final mirrorPath = Path();
      mirrorPath.moveTo(mirrorX, centerY - mirrorHeight / 2);
      mirrorPath.quadraticBezierTo(mirrorX - 30, centerY, mirrorX, centerY + mirrorHeight / 2);
      canvas.drawPath(mirrorPath, Paint()..color = Colors.grey[400]!..style = PaintingStyle.stroke..strokeWidth = 8);
    } else {
      final mirrorPath = Path();
      mirrorPath.moveTo(mirrorX, centerY - mirrorHeight / 2);
      mirrorPath.quadraticBezierTo(mirrorX + 30, centerY, mirrorX, centerY + mirrorHeight / 2);
      canvas.drawPath(mirrorPath, Paint()..color = Colors.grey[400]!..style = PaintingStyle.stroke..strokeWidth = 8);
    }

    // Center of curvature (C) and focal point (F)
    final focalX = mirrorX - focalLength * scale;
    final centerCurvatureX = mirrorX - 2 * focalLength * scale;

    canvas.drawCircle(Offset(focalX, centerY), 4, Paint()..color = Colors.orange);
    _drawText(canvas, 'F', Offset(focalX - 5, centerY + 10), Colors.orange, 10);

    if (isConcave) {
      canvas.drawCircle(Offset(centerCurvatureX, centerY), 4, Paint()..color = Colors.purple);
      _drawText(canvas, 'C', Offset(centerCurvatureX - 5, centerY + 10), Colors.purple, 10);
    }

    // Object
    final objectX = mirrorX - objectDistance * scale;
    final objectHeight = 35.0;
    canvas.drawLine(Offset(objectX, centerY), Offset(objectX, centerY - objectHeight), Paint()..color = Colors.green..strokeWidth = 3);
    _drawArrow(canvas, Offset(objectX, centerY), Offset(objectX, centerY - objectHeight), Colors.green);
    _drawText(canvas, isKorean ? '물체' : 'Object', Offset(objectX - 15, centerY - objectHeight - 15), Colors.green, 10);

    // Image
    final imageX = mirrorX - imageDistance * scale;
    final imageHeight = objectHeight * magnification.abs();
    final imageTop = isConcave ? (isRealImage ? centerY + imageHeight : centerY - imageHeight) : centerY - imageHeight;

    if (imageDistance.abs() < 500 && imageX > 20 && imageX < mirrorX) {
      if (isRealImage) {
        canvas.drawLine(Offset(imageX, centerY), Offset(imageX, imageTop), Paint()..color = Colors.red..strokeWidth = 3);
        _drawArrow(canvas, Offset(imageX, centerY), Offset(imageX, imageTop), Colors.red);
      } else {
        // Virtual image behind mirror (dashed)
        for (double y = centerY; y > imageTop; y -= 8) {
          canvas.drawLine(Offset(imageX, y), Offset(imageX, math.max(y - 4, imageTop)), Paint()..color = Colors.red..strokeWidth = 3);
        }
      }
      _drawText(canvas, isKorean ? '상' : 'Image', Offset(imageX - 10, imageTop - 15), Colors.red, 10);
    }

    // Ray tracing (simplified)
    final rayColor = Colors.yellow;

    // Ray 1: Parallel to axis, reflects through F
    canvas.drawLine(Offset(objectX, centerY - objectHeight), Offset(mirrorX - 5, centerY - objectHeight), Paint()..color = rayColor..strokeWidth = 1.5);
    if (isConcave && isRealImage && imageX > 20) {
      canvas.drawLine(Offset(mirrorX - 5, centerY - objectHeight), Offset(imageX, imageTop), Paint()..color = rayColor..strokeWidth = 1.5);
    } else if (isConcave && !isRealImage) {
      // Diverging ray for virtual image
      canvas.drawLine(Offset(mirrorX - 5, centerY - objectHeight), Offset(20, centerY - objectHeight - (mirrorX - 25) * objectHeight / (focalLength * scale)), Paint()..color = rayColor..strokeWidth = 1.5);
    }

    // Ray 2: Through center
    if (isConcave && imageX > 20 && imageX < mirrorX) {
      canvas.drawLine(Offset(objectX, centerY - objectHeight), Offset(imageX, imageTop), Paint()..color = Colors.cyan..strokeWidth = 1.5);
    }
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
  bool shouldRepaint(covariant _MirrorPainter oldDelegate) => true;
}
