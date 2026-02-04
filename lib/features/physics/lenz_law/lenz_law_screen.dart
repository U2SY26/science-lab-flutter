import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Lenz's Law simulation
class LenzLawScreen extends StatefulWidget {
  const LenzLawScreen({super.key});
  @override
  State<LenzLawScreen> createState() => _LenzLawScreenState();
}

class _LenzLawScreenState extends State<LenzLawScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double ringY = 0.0;
  double ringVelocity = 0.0;
  bool isDropping = false;
  bool magnetOn = true;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_update)..repeat();
  }

  void _update() {
    if (!isDropping) return;
    setState(() {
      final gravity = 0.3;
      final dampingForce = magnetOn ? 0.15 * ringVelocity : 0;
      ringVelocity += gravity - dampingForce;
      ringY += ringVelocity;
      if (ringY > 250) { ringY = 0; ringVelocity = 0; isDropping = false; }
    });
  }

  void _dropRing() {
    setState(() { ringY = 0; ringVelocity = 0; isDropping = true; });
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
          Text(isKorean ? '렌츠의 법칙' : "Lenz's Law", style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '렌츠의 법칙' : "Lenz's Law",
          formula: 'ε = -dΦ/dt',
          formulaDescription: isKorean ? '유도 전류는 자기 선속 변화를 방해하는 방향으로 흐릅니다.' : 'Induced current opposes the change in magnetic flux that causes it.',
          simulation: CustomPaint(painter: _LenzLawPainter(ringY: ringY, ringVelocity: ringVelocity, magnetOn: magnetOn, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: SimButton(label: isKorean ? '링 떨어뜨리기' : 'Drop Ring', icon: Icons.arrow_downward, isPrimary: true, onPressed: _dropRing)),
              const SizedBox(width: 12),
              Expanded(child: SimButton(label: magnetOn ? (isKorean ? '자석 끄기' : 'Magnet Off') : (isKorean ? '자석 켜기' : 'Magnet On'), icon: magnetOn ? Icons.power_off : Icons.power, onPressed: () => setState(() => magnetOn = !magnetOn))),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isKorean ? '관찰:' : 'Observation:', style: TextStyle(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  magnetOn
                    ? (isKorean ? '• 유도 전류가 자기장 변화를 방해\n• 링의 낙하가 느려짐 (와전류 제동)' : '• Induced current opposes flux change\n• Ring falls slowly (eddy current braking)')
                    : (isKorean ? '• 자석이 꺼져 유도 전류 없음\n• 링이 자유 낙하' : '• No magnet means no induced current\n• Ring falls freely'),
                  style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.5),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LenzLawPainter extends CustomPainter {
  final double ringY, ringVelocity;
  final bool magnetOn, isKorean;

  _LenzLawPainter({required this.ringY, required this.ringVelocity, required this.magnetOn, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;

    // Magnet
    if (magnetOn) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, size.height * 0.7), width: 80, height: 100), const Radius.circular(5)), Paint()..color = Colors.grey[700]!);
      canvas.drawRect(Rect.fromCenter(center: Offset(centerX, size.height * 0.7 - 30), width: 80, height: 40), Paint()..color = Colors.red);
      canvas.drawRect(Rect.fromCenter(center: Offset(centerX, size.height * 0.7 + 30), width: 80, height: 40), Paint()..color = Colors.blue);
      _drawText(canvas, 'N', Offset(centerX - 5, size.height * 0.7 - 38), Colors.white, 14);
      _drawText(canvas, 'S', Offset(centerX - 5, size.height * 0.7 + 22), Colors.white, 14);

      // Field lines
      for (int i = -2; i <= 2; i++) {
        canvas.drawLine(Offset(centerX + i * 15, size.height * 0.7 - 50), Offset(centerX + i * 15, 30), Paint()..color = AppColors.muted.withValues(alpha: 0.2)..strokeWidth = 1);
      }
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(centerX, size.height * 0.7), width: 80, height: 100), const Radius.circular(5)), Paint()..color = Colors.grey[800]!);
      _drawText(canvas, isKorean ? '자석 꺼짐' : 'Magnet Off', Offset(centerX - 30, size.height * 0.7 - 8), AppColors.muted, 11);
    }

    // Conducting ring
    final ringCenterY = 50 + ringY;
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX, ringCenterY), width: 100, height: 30), Paint()..color = AppColors.accent2..style = PaintingStyle.stroke..strokeWidth = 8);
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX, ringCenterY), width: 100, height: 30), Paint()..color = AppColors.ink..style = PaintingStyle.stroke..strokeWidth = 2);

    // Induced current arrows (when moving and magnet on)
    if (magnetOn && ringVelocity.abs() > 0.5) {
      final arrowColor = AppColors.accent.withValues(alpha: 0.7);
      for (int i = 0; i < 4; i++) {
        final angle = i * math.pi / 2 + math.pi / 4;
        final x = centerX + 50 * math.cos(angle);
        final y = ringCenterY + 15 * math.sin(angle);
        final tangent = angle + math.pi / 2;
        canvas.drawLine(Offset(x, y), Offset(x + 15 * math.cos(tangent), y + 5 * math.sin(tangent)), Paint()..color = arrowColor..strokeWidth = 2);
      }
      _drawText(canvas, 'I', Offset(centerX + 55, ringCenterY - 5), AppColors.accent, 12);
    }

    // Labels
    _drawText(canvas, isKorean ? '도체 링' : 'Conducting Ring', Offset(centerX + 55, ringCenterY + 10), AppColors.muted, 10);
    _drawText(canvas, 'v = ${ringVelocity.toStringAsFixed(1)}', Offset(20, ringCenterY), AppColors.ink, 10);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _LenzLawPainter oldDelegate) => true;
}
