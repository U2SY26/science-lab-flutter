import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Faraday's Law simulation: EMF = -dΦ/dt
class FaradayLawScreen extends StatefulWidget {
  const FaradayLawScreen({super.key});
  @override
  State<FaradayLawScreen> createState() => _FaradayLawScreenState();
}

class _FaradayLawScreenState extends State<FaradayLawScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double magnetPosition = 0.0;
  double magnetVelocity = 0.0;
  double coilTurns = 100;
  double coilArea = 0.01; // m²
  double magnetStrength = 0.5; // T
  bool isDragging = false;
  bool isKorean = true;

  double get flux => magnetStrength * coilArea * math.cos(magnetPosition * 0.1);
  double get emf => -coilTurns * magnetStrength * coilArea * 0.1 * math.sin(magnetPosition * 0.1) * magnetVelocity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_update)..repeat();
  }

  void _update() {
    if (!isDragging) {
      setState(() {
        magnetVelocity *= 0.98;
        magnetPosition += magnetVelocity;
        if (magnetPosition.abs() > 100) magnetVelocity = -magnetVelocity * 0.8;
      });
    }
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isKorean ? '전자기학' : 'ELECTROMAGNETISM', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          Text(isKorean ? '패러데이 법칙' : "Faraday's Law", style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '패러데이 법칙' : "Faraday's Law",
          formula: 'EMF = -N(dΦ/dt)',
          formulaDescription: isKorean ? '유도 기전력은 자기 선속의 시간 변화율에 비례합니다.' : 'Induced EMF is proportional to rate of change of magnetic flux.',
          simulation: GestureDetector(
            onPanStart: (_) => isDragging = true,
            onPanUpdate: (d) => setState(() { magnetVelocity = d.delta.dx * 0.5; magnetPosition += magnetVelocity; }),
            onPanEnd: (_) => isDragging = false,
            child: CustomPaint(painter: _FaradayLawPainter(magnetPosition: magnetPosition, emf: emf, flux: flux, isKorean: isKorean), size: Size.infinite),
          ),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '코일 감은 수 (N)' : 'Coil Turns (N)', value: coilTurns, min: 10, max: 500, defaultValue: 100, formatValue: (v) => v.toInt().toString(), onChanged: (v) => setState(() => coilTurns = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '자석 세기 (B)' : 'Magnet Strength (B)', value: magnetStrength, min: 0.1, max: 2, step: 0.1, defaultValue: 0.5, formatValue: (v) => '${v.toStringAsFixed(1)} T', onChanged: (v) => setState(() => magnetStrength = v)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Row(children: [
                Expanded(child: Column(children: [Text(isKorean ? '자기 선속 (Φ)' : 'Flux (Φ)', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(flux * 1000).toStringAsFixed(2)} mWb', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace'))])),
                Expanded(child: Column(children: [Text('EMF', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(emf * 1000).toStringAsFixed(1)} mV', style: TextStyle(color: emf.abs() > 1 ? AppColors.accent2 : AppColors.muted, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
              ]),
            ),
            const SizedBox(height: 8),
            Text(isKorean ? '자석을 드래그하여 움직이세요' : 'Drag the magnet to move it', style: TextStyle(color: AppColors.muted, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

class _FaradayLawPainter extends CustomPainter {
  final double magnetPosition, emf, flux;
  final bool isKorean;

  _FaradayLawPainter({required this.magnetPosition, required this.emf, required this.flux, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Coil
    for (int i = 0; i < 8; i++) {
      final y = centerY - 40 + i * 10;
      canvas.drawOval(Rect.fromCenter(center: Offset(centerX, y), width: 80, height: 20), Paint()..color = AppColors.accent2.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 3);
    }

    // Magnet
    final magnetX = centerX + magnetPosition;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(magnetX, centerY - 80), width: 60, height: 30), const Radius.circular(5)), Paint()..color = Colors.red);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(magnetX, centerY - 50), width: 60, height: 30), const Radius.circular(5)), Paint()..color = Colors.blue);
    _drawText(canvas, 'N', Offset(magnetX - 5, centerY - 88), Colors.white, 14);
    _drawText(canvas, 'S', Offset(magnetX - 5, centerY - 58), Colors.white, 14);

    // Field lines
    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(Offset(magnetX + i * 10, centerY - 35), Offset(magnetX + i * 10, centerY + 40), Paint()..color = AppColors.muted.withValues(alpha: 0.3)..strokeWidth = 1);
    }

    // EMF indicator (galvanometer)
    final needleAngle = (emf * 10).clamp(-math.pi / 3, math.pi / 3);
    canvas.drawCircle(Offset(centerX, centerY + 100), 30, Paint()..color = AppColors.cardBorder..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawLine(Offset(centerX, centerY + 100), Offset(centerX + 25 * math.sin(needleAngle), centerY + 100 - 25 * math.cos(needleAngle)), Paint()..color = AppColors.accent..strokeWidth = 2);
    _drawText(canvas, 'EMF', Offset(centerX - 12, centerY + 135), AppColors.muted, 10);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _FaradayLawPainter oldDelegate) => true;
}
