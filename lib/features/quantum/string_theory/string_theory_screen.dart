import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';
import '../../../shared/painters/projection_3d.dart';

/// String Theory Simulation
class StringTheoryScreen extends StatefulWidget {
  const StringTheoryScreen({super.key});

  @override
  State<StringTheoryScreen> createState() => _StringTheoryScreenState();
}

class _StringTheoryScreenState extends State<StringTheoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _time = 0.0;
  bool _isAnimating = true;
  int _vibrationMode = 2;
  double _tension = 1.0;
  bool _isClosedString = true;
  bool _isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _updateAnimation() {
    if (!_isAnimating) return;
    setState(() {
      _time += 0.022;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _isAnimating = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKorean ? '양자역학 시뮬레이션' : 'QUANTUM SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '초끈이론' : 'String Theory',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => _isKorean = !_isKorean),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: _isKorean ? '양자역학 시뮬레이션' : 'QUANTUM SIMULATION',
          title: _isKorean ? '초끈이론: 진동하는 에너지 끈' : 'String Theory: Vibrating Energy Strings',
          formula: 'M² = (n - a)/α\'',
          formulaDescription: _isKorean
              ? '초끈이론에서 입자는 10~11차원 공간에서 진동하는 1차원 에너지 끈입니다. 진동 모드가 입자의 질량과 스핀을 결정합니다.'
              : 'In string theory, particles are 1D energy strings vibrating in 10-11 dimensions. The vibration mode determines mass and spin.',
          simulation: SizedBox(
            height: 420,
            child: CustomPaint(
              painter: _StringTheoryPainter(
                time: _time,
                vibrationMode: _vibrationMode,
                tension: _tension,
                isClosedString: _isClosedString,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PresetGroup(
                label: _isKorean ? '진동 모드' : 'Vibration Mode',
                presets: List.generate(6, (i) => PresetButton(
                  label: 'n=$i',
                  isSelected: _vibrationMode == i,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _vibrationMode = i);
                  },
                )),
              ),
              const SizedBox(height: 12),
              PresetGroup(
                label: _isKorean ? '끈 유형' : 'String Type',
                presets: [
                  PresetButton(
                    label: _isKorean ? '닫힌 끈' : 'Closed',
                    isSelected: _isClosedString,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isClosedString = true);
                    },
                  ),
                  PresetButton(
                    label: _isKorean ? '열린 끈' : 'Open',
                    isSelected: !_isClosedString,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isClosedString = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '끈 장력 T' : 'String Tension T',
                  value: _tension,
                  min: 0.3,
                  max: 2.0,
                  defaultValue: 1.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)} T_P',
                  onChanged: (v) => setState(() => _tension = v),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isAnimating
                    ? (_isKorean ? '정지' : 'Pause')
                    : (_isKorean ? '재생' : 'Play'),
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isAnimating = !_isAnimating);
                },
              ),
              SimButton(
                label: _isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StringTheoryPainter extends CustomPainter {
  final double time;
  final int vibrationMode;
  final double tension;
  final bool isClosedString;

  _StringTheoryPainter({
    required this.time,
    required this.vibrationMode,
    required this.tension,
    required this.isClosedString,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0D1A20),
    );

    // 3-panel layout
    final topH = size.height * 0.55;
    final bottomH = size.height * 0.45;

    // 1. Main string visualization (top)
    _drawMainString(canvas, size, topH);

    // 2. Calabi-Yau compact dimensions (right side inset)
    _drawCalabiYau(canvas, Offset(size.width - 95, 8), 80.0);

    // 3. Vibration spectrum (bottom)
    _drawSpectrum(canvas, size, topH, bottomH);
  }

  void _drawMainString(Canvas canvas, Size size, double height) {
    final cx = size.width / 2;
    final cy = height / 2;
    final baseRadius = math.min(cx, cy) * 0.62;

    // Draw extra dimensions hint (small circles around string)
    _drawExtraDimensions(canvas, cx, cy, baseRadius);

    if (isClosedString) {
      _drawClosedString(canvas, cx, cy, baseRadius);
    } else {
      _drawOpenString(canvas, cx, cy, baseRadius);
    }

    // Central label
    _drawLabel(canvas, Offset(cx, height - 20),
        isClosedString ? 'Closed String' : 'Open String', 10, const Color(0xFF5A8A9A));
  }

  void _drawExtraDimensions(Canvas canvas, double cx, double cy, double baseRadius) {
    // Kaluza-Klein extra dimensions: tiny circles floating near the string
    const nDims = 7;
    for (int d = 0; d < nDims; d++) {
      final angle = d * 2 * math.pi / nDims + time * 0.3;
      final orbitR = baseRadius * 1.35;
      final dx = orbitR * math.cos(angle);
      final dy = orbitR * math.sin(angle) * 0.4; // flatten orbit
      final dimR = 4.0 + 2.0 * math.sin(time * 1.5 + d);
      final alpha = 0.15 + 0.1 * math.sin(time * 2 + d * 0.9);
      canvas.drawCircle(
        Offset(cx + dx, cy + dy),
        dimR * 1.8,
        Paint()
          ..color = const Color(0xFFBB77FF).withValues(alpha: alpha * 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        Offset(cx + dx, cy + dy),
        dimR,
        Paint()
          ..color = const Color(0xFFBB77FF).withValues(alpha: alpha + 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Label
    _drawLabel(canvas, Offset(cx, cy - baseRadius * 1.8),
        '7 compact dims (Calabi-Yau)', 8, const Color(0xFFBB77FF).withValues(alpha: 0.6));
  }

  void _drawClosedString(Canvas canvas, double cx, double cy, double baseRadius) {
    final n = vibrationMode == 0 ? 1 : vibrationMode;
    const nPoints = 200;
    final path = Path();
    final glowPath = Path();

    for (int i = 0; i <= nPoints; i++) {
      final theta = i * 2 * math.pi / nPoints;
      // Harmonic vibration: r = baseRadius + A*cos(n*theta + phase)
      final amplitude = vibrationMode == 0
          ? 0.0
          : baseRadius * 0.25 * tension * (1.0 / math.sqrt(n.toDouble()));
      final phase = time * (1.5 + tension * 0.4) * (vibrationMode == 0 ? 1 : n / 2.0);
      final r = baseRadius + amplitude * math.cos(n * theta + phase);
      // Add second harmonic for beauty
      final r2 = r + amplitude * 0.3 * math.sin(2 * n * theta + phase * 1.3);

      final px = cx + r2 * math.cos(theta);
      final py = cy + r2 * math.sin(theta) * 0.7; // slight perspective

      if (i == 0) {
        path.moveTo(px, py);
        glowPath.moveTo(px, py);
      } else {
        path.lineTo(px, py);
        glowPath.lineTo(px, py);
      }
    }
    path.close();
    glowPath.close();

    // Multi-layer glow
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.08)
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.2)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Color gradient along string
    final nSegs = 40;
    final pts = <Offset>[];
    for (int i = 0; i <= nSegs; i++) {
      final theta = i * 2 * math.pi / nSegs;
      final amplitude = vibrationMode == 0
          ? 0.0
          : baseRadius * 0.25 * tension * (1.0 / math.sqrt(n.toDouble()));
      final phase = time * (1.5 + tension * 0.4) * (vibrationMode == 0 ? 1 : n / 2.0);
      final r = baseRadius + amplitude * math.cos(n * theta + phase);
      final r2 = r + amplitude * 0.3 * math.sin(2 * n * theta + phase * 1.3);
      pts.add(Offset(cx + r2 * math.cos(theta), cy + r2 * math.sin(theta) * 0.7));
    }
    for (int i = 0; i < pts.length - 1; i++) {
      final t = i / pts.length;
      final hue = (200 + t * 120) % 360;
      canvas.drawLine(
        pts[i], pts[i + 1],
        Paint()
          ..color = HSVColor.fromAHSV(0.9, hue, 0.8, 1.0).toColor()
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Quantum foam particles at string boundary
    final rng = math.Random(7);
    for (int i = 0; i < 12; i++) {
      final theta = rng.nextDouble() * 2 * math.pi;
      final amplitude = vibrationMode == 0
          ? 0.0
          : baseRadius * 0.25 * tension * (1.0 / math.sqrt(n.toDouble()));
      final phase = time * (1.5 + tension * 0.4) * (vibrationMode == 0 ? 1 : n / 2.0);
      final r = baseRadius + amplitude * math.cos(n * theta + phase);
      final r2 = r + amplitude * 0.3 * math.sin(2 * n * theta + phase * 1.3);
      final offset = (rng.nextDouble() - 0.5) * 8;
      final px = cx + (r2 + offset) * math.cos(theta);
      final py = cy + (r2 + offset) * math.sin(theta) * 0.7;
      final spark = 0.4 + 0.6 * math.sin(time * 5 + i * 1.3);
      canvas.drawCircle(
        Offset(px, py),
        1.5,
        Paint()..color = Colors.white.withValues(alpha: spark * 0.7),
      );
    }

    // Mode label
    if (vibrationMode == 0) {
      _drawLabel(canvas, Offset(cx, cy - baseRadius - 10),
          'n=0: Tachyon / Graviton', 9, const Color(0xFF00D4FF));
    } else {
      final particles = ['', 'Photon/Graviton', 'Electron', 'Quark', 'W/Z Boson', 'Higgs'];
      final pName = vibrationMode < particles.length ? particles[vibrationMode] : 'Excited State';
      _drawLabel(canvas, Offset(cx, cy - baseRadius - 10),
          'n=$vibrationMode: $pName', 9, const Color(0xFF00D4FF));
    }
  }

  void _drawOpenString(Canvas canvas, double cx, double cy, double baseRadius) {
    final n = math.max(1, vibrationMode);
    const nPoints = 100;

    // D-brane endpoints
    final braneY1 = cy - baseRadius * 0.8;
    final braneY2 = cy + baseRadius * 0.8;
    final braneX1 = cx - baseRadius * 0.7;
    final braneX2 = cx + baseRadius * 0.7;

    // Draw D-branes
    for (int side = 0; side < 2; side++) {
      final bx = side == 0 ? braneX1 : braneX2;
      canvas.drawLine(
        Offset(bx, braneY1 - 15),
        Offset(bx, braneY2 + 15),
        Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(bx, braneY1 - 15),
        Offset(bx, braneY2 + 15),
        Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: 0.2)
          ..strokeWidth = 10
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      _drawLabel(canvas, Offset(bx, braneY1 - 28), 'D-brane', 8,
          const Color(0xFFFF6B35).withValues(alpha: 0.8));
    }

    // Open string vibration
    final path = Path();
    final pts = <Offset>[];
    for (int i = 0; i <= nPoints; i++) {
      final s = i / nPoints; // 0 to 1 along string
      final phase = time * (2.0 + tension * 0.5);
      // Standing wave: A(s)*sin(n*pi*s)*cos(phase)
      final amplitude = baseRadius * 0.35 * tension / math.sqrt(n.toDouble());
      final transverse = amplitude * math.sin(n * math.pi * s) * math.cos(phase);
      // String lies between the two branes
      final x = braneX1 + s * (braneX2 - braneX1);
      final y = cy + transverse;
      pts.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.15)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Colored string
    for (int i = 0; i < pts.length - 1; i++) {
      final t = i / pts.length;
      final hue = (200 + t * 100) % 360;
      canvas.drawLine(
        pts[i], pts[i + 1],
        Paint()
          ..color = HSVColor.fromAHSV(0.9, hue, 0.8, 1.0).toColor()
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Endpoint dots on D-branes
    for (int side = 0; side < 2; side++) {
      final ep = pts[side == 0 ? 0 : nPoints];
      canvas.drawCircle(ep, 4, Paint()..color = const Color(0xFFFF6B35));
      canvas.drawCircle(
        ep, 8,
        Paint()
          ..color = const Color(0xFFFF6B35).withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    _drawLabel(canvas, Offset(cx, cy - baseRadius - 10),
        'n=$vibrationMode: Open String Mode', 9, const Color(0xFF00D4FF));
  }

  void _drawCalabiYau(Canvas canvas, Offset topLeft, double size) {
    // Calabi-Yau compact dimensions: complex curved lattice
    final cx = topLeft.dx + size / 2;
    final cy = topLeft.dy + size / 2;
    final r = size / 2;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(topLeft.dx, topLeft.dy, size, size), const Radius.circular(8)),
      Paint()..color = const Color(0xFF0D1A20).withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(topLeft.dx, topLeft.dy, size, size), const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFFBB77FF).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Save/clip
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(topLeft.dx + 1, topLeft.dy + 1, size - 2, size - 2), const Radius.circular(7)),
    );

    // Torus-of-torus as Calabi-Yau approximation
    final proj = Projection3D(
      rotX: 0.4 + time * 0.12,
      rotY: time * 0.18,
      scale: r * 0.55,
      center: Offset(cx, cy),
    );
    Projection3D.drawTorus(
      canvas, proj, r * 0.5, r * 0.22,
      Paint()
        ..color = const Color(0xFFBB77FF).withValues(alpha: 0.5)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke,
      uSteps: 16,
      vSteps: 8,
    );
    Projection3D.drawTorus(
      canvas, proj, r * 0.25, r * 0.12,
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.4)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke,
      uSteps: 12,
      vSteps: 6,
    );

    canvas.restore();

    _drawLabel(canvas, Offset(cx, topLeft.dy + size + 12), 'Calabi-Yau', 8,
        const Color(0xFFBB77FF).withValues(alpha: 0.8));
    _drawLabel(canvas, Offset(cx, topLeft.dy + size + 22), '6D compact space', 7,
        const Color(0xFF5A8A9A));
  }

  void _drawSpectrum(Canvas canvas, Size size, double topH, double bottomH) {
    final bY = topH + 8;
    final bH = bottomH - 20;
    final cx = size.width / 2;

    // Background panel
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, bY, size.width - 16, bH),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF0D2030).withValues(alpha: 0.8),
    );

    _drawLabel(canvas, Offset(cx, bY + 8), 'Vibration Spectrum — Mass²(n)', 9, const Color(0xFF5A8A9A));

    const maxN = 5;
    final barW = (size.width - 60) / (maxN + 1);
    final maxBarH = bH - 40;

    final particleNames = ['γ/G', 'e⁻', 'q', 'W/Z', 'H', 'X'];
    final particleColors = [
      const Color(0xFF00D4FF),
      const Color(0xFF64FF8C),
      const Color(0xFFFF6B35),
      const Color(0xFFFFD700),
      const Color(0xFFBB77FF),
      const Color(0xFFFF4488),
    ];

    for (int n = 0; n <= maxN; n++) {
      final barH = n == 0 ? 12.0 : (maxBarH * n * 0.15 * tension).clamp(0.0, maxBarH);
      final bx = 30 + n * barW;
      final barTop = bY + bH - 28 - barH;
      final isSelected = n == vibrationMode;

      final col = particleColors[n];

      // Glow for selected
      if (isSelected) {
        canvas.drawRect(
          Rect.fromLTWH(bx - 2, barTop - 2, barW - 8 + 4, barH + 4),
          Paint()
            ..color = col.withValues(alpha: 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      canvas.drawRect(
        Rect.fromLTWH(bx, barTop, barW - 8, barH),
        Paint()..color = col.withValues(alpha: isSelected ? 0.9 : 0.4),
      );

      // Particle label
      _drawLabel(canvas, Offset(bx + (barW - 8) / 2, barTop - 14),
          particleNames[n], 8, col.withValues(alpha: isSelected ? 1.0 : 0.6));

      // n label at bottom
      _drawLabel(canvas, Offset(bx + (barW - 8) / 2, bY + bH - 20),
          'n=$n', 8, const Color(0xFF5A8A9A));
    }
  }

  void _drawLabel(Canvas canvas, Offset center, String text, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _StringTheoryPainter old) => true;
}
