import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class PhotodiodeScreen extends StatefulWidget {
  const PhotodiodeScreen({super.key});
  @override
  State<PhotodiodeScreen> createState() => _PhotodiodeScreenState();
}

class _PhotodiodeScreenState extends State<PhotodiodeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _power = 100;
  double _wavelength = 850;
  double _current = 0, _responsivity = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;
    setState(() {
      _time += 0.016;
      _responsivity = 0.8 * _wavelength / 1240;
      _current = _responsivity * _power;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _power = 100.0; _wavelength = 850.0;
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
          Text('물리 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('포토다이오드', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '포토다이오드',
          formula: 'I = ηeP/hf',
          formulaDescription: '포토다이오드의 광전류 생성을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PhotodiodeScreenPainter(
                time: _time,
                power: _power,
                wavelength: _wavelength,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '광출력 (μW)',
                value: _power,
                min: 1,
                max: 1000,
                step: 10,
                defaultValue: 100,
                formatValue: (v) => v.toStringAsFixed(0) + ' μW',
                onChanged: (v) => setState(() => _power = v),
              ),
              advancedControls: [
            SimSlider(
                label: '파장 (nm)',
                value: _wavelength,
                min: 400,
                max: 1100,
                step: 10,
                defaultValue: 850,
                formatValue: (v) => v.toStringAsFixed(0) + ' nm',
                onChanged: (v) => setState(() => _wavelength = v),
              ),
              ],
            ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(children: [
          _V('전류', _current.toStringAsFixed(1) + ' μA'),
          _V('응답도', _responsivity.toStringAsFixed(3) + ' A/W'),
          _V('λ', _wavelength.toStringAsFixed(0) + ' nm'),
                ]),
              ),
            ],
          ),
          buttons: SimButtonGroup(expanded: true, buttons: [
            SimButton(
              label: _isRunning ? '정지' : '재생',
              icon: _isRunning ? Icons.pause : Icons.play_arrow,
              isPrimary: true,
              onPressed: () { HapticFeedback.selectionClick(); setState(() => _isRunning = !_isRunning); },
            ),
            SimButton(label: '리셋', icon: Icons.refresh, onPressed: _reset),
          ]),
        ),
      ),
    );
  }
}

class _V extends StatelessWidget {
  final String label, value;
  const _V(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
  ]));
}

class _PhotodiodeScreenPainter extends CustomPainter {
  final double time;
  final double power;
  final double wavelength;

  _PhotodiodeScreenPainter({
    required this.time,
    required this.power,
    required this.wavelength,
  });

  // Convert wavelength (nm) to approximate RGB color
  Color _wavelengthToColor(double nm) {
    if (nm < 380) return const Color(0xFF8800FF);
    if (nm < 440) return Color.fromARGB(255, (0 + (440 - nm) / 60 * 130).round(), 0, 255);
    if (nm < 490) return Color.fromARGB(255, 0, ((nm - 440) / 50 * 255).round(), 255);
    if (nm < 510) return Color.fromARGB(255, 0, 255, (255 - (nm - 490) / 20 * 255).round());
    if (nm < 580) return Color.fromARGB(255, ((nm - 510) / 70 * 255).round(), 255, 0);
    if (nm < 645) return Color.fromARGB(255, 255, (255 - (nm - 580) / 65 * 255).round(), 0);
    return Color.fromARGB(255, 255, (0 + (700 - nm) / 55 * 60).round().clamp(0, 60), 0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final photonColor = _wavelengthToColor(wavelength);

    // Grid
    final gridPaint = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.4)..strokeWidth = 0.5;
    for (double x = 0; x < w; x += 30) { canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint); }
    for (double y = 0; y < h; y += 30) { canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint); }

    // --- p-n Junction (center) ---
    final jLeft = w * 0.22;
    final jTop = h * 0.18;
    final jW = w * 0.56;
    final jH = h * 0.42;
    final jMid = jLeft + jW / 2;

    // p-side (left, warm tint)
    canvas.drawRect(
      Rect.fromLTWH(jLeft, jTop, jW / 2, jH),
      Paint()..color = const Color(0xFF1A2030),
    );
    // n-side (right, cool tint)
    canvas.drawRect(
      Rect.fromLTWH(jMid, jTop, jW / 2, jH),
      Paint()..color = const Color(0xFF0D1A28),
    );
    // Border
    canvas.drawRect(
      Rect.fromLTWH(jLeft, jTop, jW, jH),
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.6)..strokeWidth = 1.5..style = PaintingStyle.stroke,
    );
    // Depletion region center line
    canvas.drawLine(
      Offset(jMid, jTop),
      Offset(jMid, jTop + jH),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.4)..strokeWidth = 1.5,
    );
    // Depletion region shading
    canvas.drawRect(
      Rect.fromLTWH(jMid - 8, jTop, 16, jH),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.07),
    );

    _drawLabel(canvas, 'p형', Offset(jLeft + jW * 0.25, jTop + 10), const Color(0xFFFF6B35), 10);
    _drawLabel(canvas, 'n형', Offset(jLeft + jW * 0.75, jTop + 10), const Color(0xFF00D4FF), 10);
    _drawLabel(canvas, '공핍층', Offset(jMid, jTop + jH + 10), const Color(0xFF5A8A9A), 9);

    // --- Photons arriving (left side, animated) ---
    final numPhotons = (power / 200 * 5 + 2).round().clamp(2, 7);
    final rng = math.Random(42);
    for (int i = 0; i < numPhotons; i++) {
      final baseY = jTop + jH * 0.1 + rng.nextDouble() * jH * 0.8;
      final phase = (time * 1.2 + i * 0.7) % 1.0;
      final px = jLeft - 40 + phase * (jW * 0.5 + 40);
      // Photon as small circle with wavelength color
      canvas.drawCircle(
        Offset(px, baseY),
        3.5,
        Paint()..color = photonColor.withValues(alpha: 0.85),
      );
      // Wave trailing lines
      for (int w2 = 1; w2 <= 3; w2++) {
        canvas.drawCircle(
          Offset(px - w2 * 5, baseY),
          1.5,
          Paint()..color = photonColor.withValues(alpha: 0.3 - w2 * 0.08),
        );
      }
    }

    // Arrow showing photon direction
    canvas.drawLine(
      Offset(jLeft - 38, jTop + jH * 0.5),
      Offset(jLeft - 12, jTop + jH * 0.5),
      Paint()..color = photonColor.withValues(alpha: 0.5)..strokeWidth = 1.5,
    );
    canvas.drawLine(Offset(jLeft - 18, jTop + jH * 0.5 - 4), Offset(jLeft - 12, jTop + jH * 0.5), Paint()..color = photonColor.withValues(alpha: 0.5)..strokeWidth = 1.5);
    canvas.drawLine(Offset(jLeft - 18, jTop + jH * 0.5 + 4), Offset(jLeft - 12, jTop + jH * 0.5), Paint()..color = photonColor.withValues(alpha: 0.5)..strokeWidth = 1.5);
    _drawLabel(canvas, 'hν', Offset(jLeft - 25, jTop + jH * 0.5 - 14), photonColor, 9);

    // --- Electron-hole pairs in junction (generated when photon hits) ---
    final numPairs = (power / 300 * 4 + 1).round().clamp(1, 5);
    final pairRng = math.Random(7);
    for (int i = 0; i < numPairs; i++) {
      final ey = jTop + jH * 0.15 + pairRng.nextDouble() * jH * 0.7;
      final ex = jMid - 5 + pairRng.nextDouble() * 10;
      // Electron drifts to n-side
      final eOffset = (time * 30 + i * 20) % (jW * 0.45);
      canvas.drawCircle(
        Offset(ex + eOffset, ey),
        4,
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.85),
      );
      _drawLabel(canvas, 'e⁻', Offset(ex + eOffset, ey), const Color(0xFF0A0A0F), 6);
      // Hole drifts to p-side
      final hOffset = (time * 30 + i * 20) % (jW * 0.45);
      canvas.drawCircle(
        Offset(ex - hOffset, ey),
        4,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.85),
      );
      _drawLabel(canvas, 'h⁺', Offset(ex - hOffset, ey), const Color(0xFF0A0A0F), 6);
    }

    // --- External circuit (current flow) ---
    final wirePaint = Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.7)..strokeWidth = 1.5;
    // Top wire
    canvas.drawLine(Offset(jLeft, jTop), Offset(jLeft, jTop - 22), wirePaint);
    canvas.drawLine(Offset(jLeft, jTop - 22), Offset(jLeft + jW, jTop - 22), wirePaint);
    canvas.drawLine(Offset(jLeft + jW, jTop - 22), Offset(jLeft + jW, jTop), wirePaint);
    // Animated current dots on wire
    final dotPhase = (time * 0.8) % 1.0;
    for (int i = 0; i < 4; i++) {
      final dp = (dotPhase + i * 0.25) % 1.0;
      double dx, dy;
      if (dp < 0.33) {
        dx = jLeft;
        dy = jTop - dp * 3 * 22;
      } else if (dp < 0.66) {
        dx = jLeft + (dp - 0.33) * 3 * jW;
        dy = jTop - 22;
      } else {
        dx = jLeft + jW;
        dy = jTop - 22 + (dp - 0.66) * 3 * 22;
      }
      canvas.drawCircle(Offset(dx, dy), 2.5, Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.85));
    }
    _drawLabel(canvas, 'I (광전류)', Offset(w * 0.5, jTop - 30), const Color(0xFF64FF8C), 9);

    // --- I-V characteristic curve (bottom) ---
    final cvLeft = w * 0.06;
    final cvBottom = h * 0.97;
    final cvW = w * 0.42;
    final cvH = h * 0.22;
    final cvTop2 = cvBottom - cvH;
    final cvMidX = cvLeft + cvW * 0.45;
    final cvMidY = cvBottom - cvH * 0.65;

    // Axes
    canvas.drawLine(Offset(cvLeft, cvBottom), Offset(cvLeft + cvW, cvBottom), Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    canvas.drawLine(Offset(cvMidX, cvTop2), Offset(cvMidX, cvBottom), Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    _drawLabel(canvas, 'V', Offset(cvLeft + cvW + 6, cvBottom - 4), const Color(0xFF5A8A9A), 8);
    _drawLabel(canvas, 'I', Offset(cvMidX + 4, cvTop2 + 4), const Color(0xFF5A8A9A), 8);

    // Dark current curve
    final darkPath = Path()..moveTo(cvLeft, cvMidY + 4);
    for (double x2 = 0; x2 <= cvW * 0.55; x2 += 2) {
      final vNorm = (x2 / (cvW * 0.55)) * 4 - 2;
      final iNorm = (math.exp(vNorm * 0.7) - 1) * 0.08;
      darkPath.lineTo(cvLeft + x2 + cvW * 0.45, cvMidY - iNorm * cvH * 0.5);
    }
    canvas.drawPath(darkPath, Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..strokeWidth = 1..style = PaintingStyle.stroke);

    // Light current curve (shifted down by photocurrent)
    final photoShift = (power / 1000 * cvH * 0.5).clamp(4.0, cvH * 0.5);
    final lightPath = Path()..moveTo(cvLeft, cvMidY + 4 + photoShift);
    for (double x2 = 0; x2 <= cvW * 0.55; x2 += 2) {
      final vNorm = (x2 / (cvW * 0.55)) * 4 - 2;
      final iNorm = (math.exp(vNorm * 0.7) - 1) * 0.08;
      lightPath.lineTo(cvLeft + x2 + cvW * 0.45, cvMidY - iNorm * cvH * 0.5 + photoShift);
    }
    canvas.drawPath(lightPath, Paint()..color = photonColor.withValues(alpha: 0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    _drawLabel(canvas, '암전류', Offset(cvLeft + cvW * 0.2, cvMidY - 4), const Color(0xFF5A8A9A), 8);
    _drawLabel(canvas, '광전류', Offset(cvLeft + cvW * 0.2, cvMidY + photoShift + 4), photonColor, 8);

    // I-V label
    final responsivity = 0.8 * wavelength / 1240;
    final current = responsivity * power;
    _drawLabel(canvas, 'I=${current.toStringAsFixed(0)}μA  λ=${wavelength.toStringAsFixed(0)}nm', Offset(w * 0.73, h * 0.92), const Color(0xFFE0F4FF), 9);

    // Title
    _drawLabel(canvas, '광전 효과 (포토다이오드)', Offset(w / 2, 14), const Color(0xFF00D4FF), 12, bold: true);
  }

  void _drawLabel(Canvas canvas, String text, Offset center, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PhotodiodeScreenPainter oldDelegate) => true;
}
