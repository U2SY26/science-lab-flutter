import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Light Reflection simulation
class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});
  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  double incidentAngle = 45; // degrees
  bool showNormal = true;
  bool showAngles = true;
  int surfaceType = 0; // 0 = smooth, 1 = rough
  bool isKorean = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '광학' : 'OPTICS', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '빛의 반사' : 'Light Reflection', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '광학' : 'Optics',
          title: isKorean ? '빛의 반사' : 'Light Reflection',
          formula: 'θᵢ = θᵣ',
          formulaDescription: isKorean ? '반사 법칙: 입사각과 반사각은 항상 같습니다.' : 'Law of Reflection: Incident angle equals reflected angle.',
          simulation: CustomPaint(painter: _ReflectionPainter(incidentAngle: incidentAngle, showNormal: showNormal, showAngles: showAngles, surfaceType: surfaceType, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '입사각 (θᵢ)' : 'Incident Angle (θᵢ)', value: incidentAngle, min: 5, max: 85, defaultValue: 45, formatValue: (v) => '${v.toStringAsFixed(0)}°', onChanged: (v) => setState(() => incidentAngle = v)),
            const SizedBox(height: 16),
            SimSegment<int>(label: isKorean ? '표면 유형' : 'Surface Type', options: {0: isKorean ? '매끄러운 면' : 'Smooth', 1: isKorean ? '거친 면' : 'Rough'}, selected: surfaceType, onChanged: (v) => setState(() => surfaceType = v)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: CheckboxListTile(title: Text(isKorean ? '법선 표시' : 'Show Normal', style: TextStyle(fontSize: 12)), value: showNormal, onChanged: (v) => setState(() => showNormal = v!), dense: true, contentPadding: EdgeInsets.zero)),
              Expanded(child: CheckboxListTile(title: Text(isKorean ? '각도 표시' : 'Show Angles', style: TextStyle(fontSize: 12)), value: showAngles, onChanged: (v) => setState(() => showAngles = v!), dense: true, contentPadding: EdgeInsets.zero)),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('θᵢ', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${incidentAngle.toStringAsFixed(1)}°', style: TextStyle(color: Colors.yellow, fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Text('=', style: TextStyle(color: AppColors.ink, fontSize: 20)),
                  Expanded(child: Column(children: [Text('θᵣ', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${incidentAngle.toStringAsFixed(1)}°', style: TextStyle(color: Colors.red, fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
                const SizedBox(height: 8),
                Text(
                  surfaceType == 0
                    ? (isKorean ? '정반사: 평행 광선은 평행하게 반사됩니다.' : 'Specular: Parallel rays reflect parallel.')
                    : (isKorean ? '난반사: 평행 광선이 여러 방향으로 흩어집니다.' : 'Diffuse: Parallel rays scatter in many directions.'),
                  style: TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ReflectionPainter extends CustomPainter {
  final double incidentAngle;
  final bool showNormal, showAngles;
  final int surfaceType;
  final bool isKorean;

  _ReflectionPainter({required this.incidentAngle, required this.showNormal, required this.showAngles, required this.surfaceType, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final mirrorY = size.height * 0.6;
    final rayLength = 100.0;

    // Mirror surface
    if (surfaceType == 0) {
      // Smooth mirror
      canvas.drawRect(Rect.fromLTWH(30, mirrorY, size.width - 60, 15), Paint()..color = Colors.grey[400]!);
      canvas.drawRect(Rect.fromLTWH(30, mirrorY, size.width - 60, 5), Paint()..color = Colors.grey[300]!);
    } else {
      // Rough surface
      final roughPath = Path()..moveTo(30, mirrorY);
      for (double x = 30; x < size.width - 30; x += 8) {
        roughPath.lineTo(x + 4, mirrorY + (x.toInt() % 16 == 0 ? -5 : 5));
      }
      roughPath.lineTo(size.width - 30, mirrorY);
      roughPath.lineTo(size.width - 30, mirrorY + 15);
      roughPath.lineTo(30, mirrorY + 15);
      roughPath.close();
      canvas.drawPath(roughPath, Paint()..color = Colors.brown[300]!);
    }

    // Normal line
    if (showNormal) {
      for (double y = mirrorY - 80; y < mirrorY; y += 8) {
        canvas.drawLine(Offset(centerX, y), Offset(centerX, y + 4), Paint()..color = AppColors.muted..strokeWidth = 1);
      }
      _drawText(canvas, isKorean ? '법선' : 'Normal', Offset(centerX + 5, mirrorY - 85), AppColors.muted, 10);
    }

    final incidentRad = incidentAngle * math.pi / 180;

    if (surfaceType == 0) {
      // Specular reflection - single ray
      // Incident ray
      final incidentStartX = centerX - rayLength * math.sin(incidentRad);
      final incidentStartY = mirrorY - rayLength * math.cos(incidentRad);
      canvas.drawLine(Offset(incidentStartX, incidentStartY), Offset(centerX, mirrorY), Paint()..color = Colors.yellow..strokeWidth = 3);
      _drawArrow(canvas, Offset(incidentStartX, incidentStartY), Offset(centerX, mirrorY), Colors.yellow);

      // Reflected ray
      final reflectedEndX = centerX + rayLength * math.sin(incidentRad);
      final reflectedEndY = mirrorY - rayLength * math.cos(incidentRad);
      canvas.drawLine(Offset(centerX, mirrorY), Offset(reflectedEndX, reflectedEndY), Paint()..color = Colors.red..strokeWidth = 3);
      _drawArrow(canvas, Offset(centerX, mirrorY), Offset(reflectedEndX, reflectedEndY), Colors.red);

      // Angle arcs
      if (showAngles) {
        canvas.drawArc(Rect.fromCenter(center: Offset(centerX, mirrorY), width: 50, height: 50), -math.pi / 2, -incidentRad, false, Paint()..color = Colors.yellow.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
        canvas.drawArc(Rect.fromCenter(center: Offset(centerX, mirrorY), width: 60, height: 60), -math.pi / 2, incidentRad, false, Paint()..color = Colors.red.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
        _drawText(canvas, 'θᵢ', Offset(centerX - 40, mirrorY - 45), Colors.yellow, 12);
        _drawText(canvas, 'θᵣ', Offset(centerX + 30, mirrorY - 45), Colors.red, 12);
      }

      // Labels
      _drawText(canvas, isKorean ? '입사광' : 'Incident', Offset(incidentStartX - 20, incidentStartY - 15), Colors.yellow, 10);
      _drawText(canvas, isKorean ? '반사광' : 'Reflected', Offset(reflectedEndX - 10, reflectedEndY - 15), Colors.red, 10);
    } else {
      // Diffuse reflection - multiple rays
      // Multiple incident rays (parallel)
      for (int i = -2; i <= 2; i++) {
        final offsetX = i * 30.0;
        final startX = centerX + offsetX - rayLength * math.sin(incidentRad);
        final startY = mirrorY - rayLength * math.cos(incidentRad);
        final hitX = centerX + offsetX;

        canvas.drawLine(Offset(startX, startY), Offset(hitX, mirrorY), Paint()..color = Colors.yellow..strokeWidth = 2);
        _drawArrow(canvas, Offset(startX, startY), Offset(hitX, mirrorY), Colors.yellow);

        // Scattered reflections
        final scatterAngle = (i * 15 + incidentAngle) * math.pi / 180;
        final reflectedEndX = hitX + 60 * math.sin(scatterAngle);
        final reflectedEndY = mirrorY - 60 * math.cos(scatterAngle);
        canvas.drawLine(Offset(hitX, mirrorY), Offset(reflectedEndX, reflectedEndY), Paint()..color = Colors.red.withValues(alpha: 0.7)..strokeWidth = 2);
        _drawArrow(canvas, Offset(hitX, mirrorY), Offset(reflectedEndX, reflectedEndY), Colors.red.withValues(alpha: 0.7));
      }

      _drawText(canvas, isKorean ? '평행 입사광' : 'Parallel Incident', Offset(20, 30), Colors.yellow, 10);
      _drawText(canvas, isKorean ? '산란 반사광' : 'Scattered Reflected', Offset(size.width - 120, 30), Colors.red, 10);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final arrowLength = 8.0;
    canvas.drawLine(to, Offset(to.dx - arrowLength * math.cos(angle - 0.4), to.dy - arrowLength * math.sin(angle - 0.4)), Paint()..color = color..strokeWidth = 2);
    canvas.drawLine(to, Offset(to.dx - arrowLength * math.cos(angle + 0.4), to.dy - arrowLength * math.sin(angle + 0.4)), Paint()..color = color..strokeWidth = 2);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _ReflectionPainter oldDelegate) => true;
}
