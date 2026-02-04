import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Prism Dispersion simulation
class PrismScreen extends StatefulWidget {
  const PrismScreen({super.key});
  @override
  State<PrismScreen> createState() => _PrismScreenState();
}

class _PrismScreenState extends State<PrismScreen> {
  double prismAngle = 60; // degrees (apex angle)
  double incidentAngle = 45; // degrees
  double refractiveIndex = 1.52; // Crown glass
  bool isKorean = true;

  // Cauchy's equation approximation for dispersion
  double getRefractiveIndex(double wavelength) {
    // n = A + B/λ² (simplified Cauchy equation)
    final A = refractiveIndex - 0.01;
    final B = 0.01 * 500 * 500; // Calibrated at 500nm
    return A + B / (wavelength * wavelength);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '광학' : 'OPTICS', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '프리즘 분산' : 'Prism Dispersion', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '광학' : 'Optics',
          title: isKorean ? '프리즘 분산' : 'Prism Dispersion',
          formula: 'δ = (n-1)A',
          formulaDescription: isKorean ? '백색광이 프리즘을 통과하면 파장에 따라 굴절률이 달라 무지개 색으로 분리됩니다.' : 'White light separates into rainbow colors as refractive index varies with wavelength.',
          simulation: CustomPaint(painter: _PrismPainter(prismAngle: prismAngle, incidentAngle: incidentAngle, refractiveIndex: refractiveIndex, getRefractiveIndex: getRefractiveIndex, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '입사각' : 'Incident Angle', value: incidentAngle, min: 20, max: 70, defaultValue: 45, formatValue: (v) => '${v.toStringAsFixed(0)}°', onChanged: (v) => setState(() => incidentAngle = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '프리즘 꼭지각' : 'Prism Apex Angle', value: prismAngle, min: 30, max: 90, defaultValue: 60, formatValue: (v) => '${v.toStringAsFixed(0)}°', onChanged: (v) => setState(() => prismAngle = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '굴절률 (n)' : 'Refractive Index (n)', value: refractiveIndex, min: 1.3, max: 1.8, defaultValue: 1.52, formatValue: (v) => v.toStringAsFixed(2), onChanged: (v) => setState(() => refractiveIndex = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text('n (400nm)', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(getRefractiveIndex(400).toStringAsFixed(3), style: TextStyle(color: Colors.purple, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('n (550nm)', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(getRefractiveIndex(550).toStringAsFixed(3), style: TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text('n (700nm)', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text(getRefractiveIndex(700).toStringAsFixed(3), style: TextStyle(color: Colors.red, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
                const SizedBox(height: 8),
                Text(isKorean ? '분산: 짧은 파장(보라)이 더 많이 굴절됩니다' : 'Dispersion: Shorter wavelengths (violet) refract more', style: TextStyle(color: AppColors.muted, fontSize: 10)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PrismPainter extends CustomPainter {
  final double prismAngle, incidentAngle, refractiveIndex;
  final double Function(double) getRefractiveIndex;
  final bool isKorean;

  _PrismPainter({required this.prismAngle, required this.incidentAngle, required this.refractiveIndex, required this.getRefractiveIndex, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height * 0.4;
    final prismSize = 100.0;

    // Draw prism (equilateral triangle)
    final apexAngleRad = prismAngle * math.pi / 180;
    final halfBase = prismSize * math.sin(apexAngleRad / 2);
    final height = prismSize * math.cos(apexAngleRad / 2);

    final apex = Offset(centerX, centerY - height / 2);
    final bottomLeft = Offset(centerX - halfBase, centerY + height / 2);
    final bottomRight = Offset(centerX + halfBase, centerY + height / 2);

    final prismPath = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..close();

    canvas.drawPath(prismPath, Paint()..color = Colors.lightBlue.withValues(alpha: 0.3));
    canvas.drawPath(prismPath, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);

    // Calculate entry point on left face
    final leftFaceAngle = math.atan2(apex.dy - bottomLeft.dy, apex.dx - bottomLeft.dx);
    final entryY = centerY;
    final entryX = bottomLeft.dx + (entryY - bottomLeft.dy) * (apex.dx - bottomLeft.dx) / (apex.dy - bottomLeft.dy);

    // Incident ray (white light)
    final incidentRad = incidentAngle * math.pi / 180;
    final rayStartX = entryX - 100 * math.cos(incidentRad);
    final rayStartY = entryY - 100 * math.sin(incidentRad);
    canvas.drawLine(Offset(rayStartX, rayStartY), Offset(entryX, entryY), Paint()..color = Colors.white..strokeWidth = 3);

    // Draw dispersed rays for different wavelengths
    final wavelengths = [400.0, 450.0, 500.0, 550.0, 600.0, 650.0, 700.0];
    final colors = [Colors.purple, Colors.indigo, Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.red];

    for (int i = 0; i < wavelengths.length; i++) {
      final wl = wavelengths[i];
      final color = colors[i];
      final n = getRefractiveIndex(wl);

      // Snell's law at entry
      final normalAngle1 = leftFaceAngle + math.pi / 2;
      final theta1 = incidentRad - (normalAngle1 - math.pi);
      final sinTheta2 = math.sin(theta1) / n;
      if (sinTheta2.abs() > 1) continue;
      final theta2 = math.asin(sinTheta2);

      // Ray inside prism
      final internalAngle = normalAngle1 - math.pi + theta2;
      final internalLength = 80.0;
      final internalEndX = entryX + internalLength * math.cos(internalAngle);
      final internalEndY = entryY + internalLength * math.sin(internalAngle);

      // Exit through right face
      final rightFaceAngle = math.atan2(apex.dy - bottomRight.dy, apex.dx - bottomRight.dx);
      final normalAngle2 = rightFaceAngle - math.pi / 2;

      // Snell's law at exit
      final theta3 = internalAngle - normalAngle2;
      final sinTheta4 = n * math.sin(theta3);
      if (sinTheta4.abs() > 1) continue;
      final theta4 = math.asin(sinTheta4);

      final exitAngle = normalAngle2 + theta4;
      final exitLength = 120.0;
      final exitEndX = internalEndX + exitLength * math.cos(exitAngle);
      final exitEndY = internalEndY + exitLength * math.sin(exitAngle);

      // Draw internal ray (faint)
      canvas.drawLine(Offset(entryX, entryY), Offset(internalEndX, internalEndY), Paint()..color = color.withValues(alpha: 0.3)..strokeWidth = 2);

      // Draw exit ray
      canvas.drawLine(Offset(internalEndX, internalEndY), Offset(exitEndX, exitEndY), Paint()..color = color..strokeWidth = 2);
    }

    // Labels
    _drawText(canvas, isKorean ? '백색광' : 'White Light', Offset(rayStartX - 10, rayStartY - 20), Colors.white, 10);
    _drawText(canvas, isKorean ? '프리즘' : 'Prism', Offset(centerX - 20, centerY + height / 2 + 15), AppColors.muted, 11);

    // Spectrum labels
    _drawText(canvas, isKorean ? '보라 (단파장)' : 'Violet (short λ)', Offset(size.width - 100, centerY - 60), Colors.purple, 9);
    _drawText(canvas, isKorean ? '빨강 (장파장)' : 'Red (long λ)', Offset(size.width - 90, centerY + 40), Colors.red, 9);

    // Spectrum bar at bottom
    final spectrumY = size.height * 0.85;
    final spectrumWidth = size.width - 60;
    for (double x = 0; x < spectrumWidth; x++) {
      final wl = 400 + (x / spectrumWidth) * 300;
      canvas.drawLine(Offset(30 + x, spectrumY - 10), Offset(30 + x, spectrumY + 10), Paint()..color = _getColorForWavelength(wl));
    }
    _drawText(canvas, '400nm', Offset(25, spectrumY + 15), AppColors.muted, 9);
    _drawText(canvas, '700nm', Offset(size.width - 55, spectrumY + 15), AppColors.muted, 9);
    _drawText(canvas, isKorean ? '가시광선 스펙트럼' : 'Visible Spectrum', Offset(centerX - 50, spectrumY + 15), AppColors.muted, 10);
  }

  Color _getColorForWavelength(double wl) {
    if (wl < 450) return Color.lerp(Colors.purple, Colors.blue, (wl - 400) / 50)!;
    if (wl < 500) return Color.lerp(Colors.blue, Colors.cyan, (wl - 450) / 50)!;
    if (wl < 550) return Color.lerp(Colors.cyan, Colors.green, (wl - 500) / 50)!;
    if (wl < 600) return Color.lerp(Colors.green, Colors.yellow, (wl - 550) / 50)!;
    if (wl < 650) return Color.lerp(Colors.yellow, Colors.orange, (wl - 600) / 50)!;
    return Color.lerp(Colors.orange, Colors.red, (wl - 650) / 50)!;
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _PrismPainter oldDelegate) => true;
}
