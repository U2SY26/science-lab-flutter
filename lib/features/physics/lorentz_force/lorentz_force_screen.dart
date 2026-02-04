import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Lorentz Force simulation: F = q(E + v×B)
class LorentzForceScreen extends StatefulWidget {
  const LorentzForceScreen({super.key});
  @override
  State<LorentzForceScreen> createState() => _LorentzForceScreenState();
}

class _LorentzForceScreenState extends State<LorentzForceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double charge = 1.0; // e (elementary charge units)
  double velocity = 1000.0; // m/s
  double magneticField = 0.01; // T
  double electricField = 0.0; // V/m
  double particleX = 0.0, particleY = 0.0, particleVx = 0.0, particleVy = 0.0;
  List<Offset> trail = [];
  bool isKorean = true;

  double get magneticForce => charge * 1.6e-19 * velocity * magneticField;
  double get electricForce => charge * 1.6e-19 * electricField;
  double get radius => (9.1e-31 * velocity) / (charge * 1.6e-19 * magneticField);

  @override
  void initState() {
    super.initState();
    _resetParticle();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_updateParticle)..repeat();
  }

  void _resetParticle() {
    particleX = 50; particleY = 150; particleVx = velocity / 500; particleVy = 0; trail.clear();
  }

  void _updateParticle() {
    setState(() {
      final q = charge * 1.6e-19;
      final m = 9.1e-31;
      final B = magneticField;
      final E = electricField;

      // Lorentz force: F = q(E + v×B)
      final ax = (q * E + q * particleVy * B) / m * 1e-20;
      final ay = (-q * particleVx * B) / m * 1e-20;

      particleVx += ax;
      particleVy += ay;
      particleX += particleVx;
      particleY += particleVy;

      trail.add(Offset(particleX, particleY));
      if (trail.length > 200) trail.removeAt(0);

      if (particleX < 0 || particleX > 350 || particleY < 0 || particleY > 300) _resetParticle();
    });
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
          Text(isKorean ? '로렌츠 힘' : 'Lorentz Force', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '로렌츠 힘' : 'Lorentz Force',
          formula: 'F = q(E + v×B)',
          formulaDescription: isKorean ? '하전입자가 전기장과 자기장에서 받는 힘입니다.' : 'Force on a charged particle in electric and magnetic fields.',
          simulation: CustomPaint(painter: _LorentzForcePainter(particleX: particleX, particleY: particleY, trail: trail, magneticField: magneticField, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '자기장 (B)' : 'Magnetic Field (B)', value: magneticField * 1000, min: 1, max: 50, defaultValue: 10, formatValue: (v) => '${v.toStringAsFixed(0)} mT', onChanged: (v) { setState(() => magneticField = v / 1000); _resetParticle(); }),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '속력 (v)' : 'Velocity (v)', value: velocity, min: 100, max: 5000, defaultValue: 1000, formatValue: (v) => '${v.toStringAsFixed(0)} m/s', onChanged: (v) { setState(() => velocity = v); _resetParticle(); }),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '전기장 (E)' : 'Electric Field (E)', value: electricField, min: -1000, max: 1000, defaultValue: 0, formatValue: (v) => '${v.toStringAsFixed(0)} V/m', onChanged: (v) { setState(() => electricField = v); _resetParticle(); }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Row(children: [
                Expanded(child: Column(children: [Text('F_B', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(magneticForce * 1e15).toStringAsFixed(2)} fN', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace'))])),
                Expanded(child: Column(children: [Text('F_E', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(electricForce * 1e15).toStringAsFixed(2)} fN', style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace'))])),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LorentzForcePainter extends CustomPainter {
  final double particleX, particleY, magneticField;
  final List<Offset> trail;
  final bool isKorean;

  _LorentzForcePainter({required this.particleX, required this.particleY, required this.trail, required this.magneticField, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Magnetic field indicators (into page)
    for (double x = 40; x < size.width - 40; x += 40) {
      for (double y = 40; y < size.height - 60; y += 40) {
        canvas.drawCircle(Offset(x, y), 8, Paint()..color = AppColors.muted.withValues(alpha: 0.3)..style = PaintingStyle.stroke);
        canvas.drawCircle(Offset(x, y), 2, Paint()..color = AppColors.muted.withValues(alpha: 0.3));
      }
    }

    // Trail
    for (int i = 1; i < trail.length; i++) {
      final alpha = i / trail.length;
      canvas.drawLine(trail[i - 1], trail[i], Paint()..color = AppColors.accent.withValues(alpha: alpha * 0.7)..strokeWidth = 2);
    }

    // Particle
    canvas.drawCircle(Offset(particleX, particleY), 8, Paint()..color = Colors.red);
    canvas.drawCircle(Offset(particleX, particleY), 8, Paint()..color = AppColors.ink..style = PaintingStyle.stroke..strokeWidth = 2);

    // Labels
    _drawText(canvas, 'B ⊗ (${isKorean ? "지면으로" : "into page"})', Offset(20, size.height - 40), AppColors.muted, 10);
    _drawText(canvas, isKorean ? '전자 궤적' : 'Electron Path', Offset(20, 15), AppColors.accent, 11);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _LorentzForcePainter oldDelegate) => true;
}
