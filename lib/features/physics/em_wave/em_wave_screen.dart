import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Electromagnetic Wave simulation
class EmWaveScreen extends StatefulWidget {
  const EmWaveScreen({super.key});
  @override
  State<EmWaveScreen> createState() => _EmWaveScreenState();
}

class _EmWaveScreenState extends State<EmWaveScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double wavelength = 500; // nm (visible light)
  double amplitude = 1.0;
  double time = 0;
  bool isRunning = true;
  bool showE = true;
  bool showB = true;
  bool isKorean = true;

  double get frequency => 3e8 / (wavelength * 1e-9); // c = fλ
  double get energy => 6.626e-34 * frequency; // E = hf (Planck's equation)

  Color get waveColor {
    if (wavelength < 380) return Colors.purple;
    if (wavelength < 450) return Colors.indigo;
    if (wavelength < 495) return Colors.blue;
    if (wavelength < 570) return Colors.green;
    if (wavelength < 590) return Colors.yellow;
    if (wavelength < 620) return Colors.orange;
    if (wavelength < 750) return Colors.red;
    return Colors.red.shade900;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(() { if (isRunning) setState(() => time += 0.05); })..repeat();
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
          Text(isKorean ? '전자기파' : 'EM Wave', style: const TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
        actions: [IconButton(icon: Text(isKorean ? 'EN' : '한', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 14)), onPressed: () => setState(() => isKorean = !isKorean))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '전자기학' : 'Electromagnetism',
          title: isKorean ? '전자기파' : 'Electromagnetic Wave',
          formula: 'c = fλ, E = hf',
          formulaDescription: isKorean ? '전기장(E)과 자기장(B)이 수직으로 진동하며 전파됩니다.' : 'Electric (E) and magnetic (B) fields oscillate perpendicular to propagation.',
          simulation: CustomPaint(painter: _EmWavePainter(time: time, wavelength: wavelength, amplitude: amplitude, showE: showE, showB: showB, waveColor: waveColor, isKorean: isKorean), size: Size.infinite),
          controls: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SimSlider(label: isKorean ? '파장 (λ)' : 'Wavelength (λ)', value: wavelength, min: 380, max: 750, defaultValue: 500, formatValue: (v) => '${v.toStringAsFixed(0)} nm', onChanged: (v) => setState(() => wavelength = v)),
            const SizedBox(height: 12),
            SimSlider(label: isKorean ? '진폭' : 'Amplitude', value: amplitude, min: 0.2, max: 2.0, defaultValue: 1.0, formatValue: (v) => v.toStringAsFixed(1), onChanged: (v) => setState(() => amplitude = v)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: CheckboxListTile(title: Text(isKorean ? '전기장 (E)' : 'E Field', style: TextStyle(color: Colors.red, fontSize: 12)), value: showE, onChanged: (v) => setState(() => showE = v!), dense: true, contentPadding: EdgeInsets.zero)),
              Expanded(child: CheckboxListTile(title: Text(isKorean ? '자기장 (B)' : 'B Field', style: TextStyle(color: Colors.blue, fontSize: 12)), value: showB, onChanged: (v) => setState(() => showB = v!), dense: true, contentPadding: EdgeInsets.zero)),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.simBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.cardBorder)),
              child: Column(children: [
                Row(children: [
                  Expanded(child: Column(children: [Text(isKorean ? '주파수' : 'Frequency', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(frequency / 1e12).toStringAsFixed(1)} THz', style: TextStyle(color: AppColors.accent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                  Expanded(child: Column(children: [Text(isKorean ? '광자 에너지' : 'Photon Energy', style: const TextStyle(color: AppColors.muted, fontSize: 10)), Text('${(energy / 1.6e-19).toStringAsFixed(2)} eV', style: TextStyle(color: AppColors.accent2, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600))])),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Text(isKorean ? '색상: ' : 'Color: ', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                  Container(width: 20, height: 20, decoration: BoxDecoration(color: waveColor, borderRadius: BorderRadius.circular(4))),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            SimButtonGroup(expanded: true, buttons: [
              SimButton(label: isRunning ? (isKorean ? '정지' : 'Stop') : (isKorean ? '시작' : 'Start'), icon: isRunning ? Icons.pause : Icons.play_arrow, isPrimary: true, onPressed: () => setState(() => isRunning = !isRunning)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _EmWavePainter extends CustomPainter {
  final double time, wavelength, amplitude;
  final bool showE, showB, isKorean;
  final Color waveColor;

  _EmWavePainter({required this.time, required this.wavelength, required this.amplitude, required this.showE, required this.showB, required this.waveColor, required this.isKorean});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerY = size.height * 0.4;
    final waveWidth = size.width - 40;
    final waveAmplitude = 50.0 * amplitude;
    final k = 2 * math.pi / 80; // wave number (scaled for display)
    final omega = 2 * math.pi * 0.5; // angular frequency (scaled)

    // Propagation direction axis
    canvas.drawLine(Offset(20, centerY), Offset(size.width - 20, centerY), Paint()..color = AppColors.muted..strokeWidth = 1);
    _drawArrow(canvas, Offset(size.width - 30, centerY), Offset(size.width - 20, centerY), AppColors.muted);
    _drawText(canvas, 'z', Offset(size.width - 25, centerY + 10), AppColors.muted, 12);

    // E field (vertical oscillation - red)
    if (showE) {
      final ePath = Path();
      for (double x = 0; x <= waveWidth; x += 2) {
        final z = x;
        final e = waveAmplitude * math.sin(k * z - omega * time);
        final screenX = 20 + x;
        final screenY = centerY - e;
        if (x == 0) ePath.moveTo(screenX, screenY); else ePath.lineTo(screenX, screenY);
      }
      canvas.drawPath(ePath, Paint()..color = Colors.red..style = PaintingStyle.stroke..strokeWidth = 2);

      // E field arrows
      for (double x = 0; x <= waveWidth; x += 40) {
        final z = x;
        final e = waveAmplitude * math.sin(k * z - omega * time);
        final screenX = 20 + x;
        if (e.abs() > 5) {
          canvas.drawLine(Offset(screenX, centerY), Offset(screenX, centerY - e), Paint()..color = Colors.red.withValues(alpha: 0.5)..strokeWidth = 1);
        }
      }
      _drawText(canvas, 'E', Offset(25, centerY - waveAmplitude - 15), Colors.red, 14);
    }

    // B field (horizontal oscillation - blue, 90° out of phase spatially)
    if (showB) {
      final bPath = Path();
      for (double x = 0; x <= waveWidth; x += 2) {
        final z = x;
        final b = waveAmplitude * 0.6 * math.sin(k * z - omega * time);
        final screenX = 20 + x;
        final screenY = centerY + 80 + b * 0.5; // Draw below E field
        if (x == 0) bPath.moveTo(screenX, screenY); else bPath.lineTo(screenX, screenY);
      }

      // Draw B field axis
      canvas.drawLine(Offset(20, centerY + 80), Offset(size.width - 20, centerY + 80), Paint()..color = AppColors.muted.withValues(alpha: 0.3)..strokeWidth = 1);
      canvas.drawPath(bPath, Paint()..color = Colors.blue..style = PaintingStyle.stroke..strokeWidth = 2);
      _drawText(canvas, 'B', Offset(25, centerY + 80 - waveAmplitude * 0.6 - 15), Colors.blue, 14);
    }

    // Spectrum bar
    final spectrumY = size.height * 0.85;
    final spectrumWidth = size.width - 60;
    for (double x = 0; x < spectrumWidth; x++) {
      final wl = 380 + (x / spectrumWidth) * (750 - 380);
      canvas.drawLine(Offset(30 + x, spectrumY - 10), Offset(30 + x, spectrumY + 10), Paint()..color = _getColorForWavelength(wl));
    }

    // Current wavelength marker
    final markerX = 30 + ((wavelength - 380) / (750 - 380)) * spectrumWidth;
    canvas.drawLine(Offset(markerX, spectrumY - 15), Offset(markerX, spectrumY + 15), Paint()..color = AppColors.ink..strokeWidth = 2);

    _drawText(canvas, '380nm', Offset(25, spectrumY + 15), AppColors.muted, 9);
    _drawText(canvas, '750nm', Offset(size.width - 55, spectrumY + 15), AppColors.muted, 9);
    _drawText(canvas, isKorean ? '가시광선 스펙트럼' : 'Visible Spectrum', Offset(size.width / 2 - 50, spectrumY + 15), AppColors.muted, 10);
  }

  Color _getColorForWavelength(double wl) {
    if (wl < 380) return Colors.purple;
    if (wl < 450) return Color.lerp(Colors.purple, Colors.blue, (wl - 380) / 70)!;
    if (wl < 495) return Color.lerp(Colors.blue, Colors.cyan, (wl - 450) / 45)!;
    if (wl < 570) return Color.lerp(Colors.cyan, Colors.green, (wl - 495) / 75)!;
    if (wl < 590) return Color.lerp(Colors.green, Colors.yellow, (wl - 570) / 20)!;
    if (wl < 620) return Color.lerp(Colors.yellow, Colors.orange, (wl - 590) / 30)!;
    if (wl < 750) return Color.lerp(Colors.orange, Colors.red, (wl - 620) / 130)!;
    return Colors.red.shade900;
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    canvas.drawLine(from, to, Paint()..color = color..strokeWidth = 2);
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    canvas.drawLine(to, Offset(to.dx - 8 * math.cos(angle - 0.5), to.dy - 8 * math.sin(angle - 0.5)), Paint()..color = color..strokeWidth = 2);
    canvas.drawLine(to, Offset(to.dx - 8 * math.cos(angle + 0.5), to.dy - 8 * math.sin(angle + 0.5)), Paint()..color = color..strokeWidth = 2);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _EmWavePainter oldDelegate) => true;
}
