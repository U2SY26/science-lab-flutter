import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';
import '../../../shared/painters/projection_3d.dart';

/// Wormhole (Einstein-Rosen Bridge) Simulation
class WormholeScreen extends StatefulWidget {
  const WormholeScreen({super.key});

  @override
  State<WormholeScreen> createState() => _WormholeScreenState();
}

class _WormholeScreenState extends State<WormholeScreen>
    with SingleTickerProviderStateMixin, Rotation3DController {
  late AnimationController _controller;

  double _time = 0.0;
  bool _isAnimating = true;
  double _throatRadius = 1.0;
  double _funnelDepth = 2.5;
  bool _isKorean = true;

  @override
  void initState() {
    super.initState();
    rotX = 0.35;
    rotY = 0.5;
    scale3d = 55.0;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _updateAnimation() {
    if (!_isAnimating) return;
    setState(() {
      _time += 0.018;
      rotY += 0.006;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      rotX = 0.35;
      rotY = 0.5;
      scale3d = 55.0;
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
              _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '웜홀' : 'Wormhole',
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
          category: _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
          title: _isKorean ? '아인슈타인-로젠 다리 (웜홀)' : 'Einstein-Rosen Bridge (Wormhole)',
          formula: 'ds² = -dt² + dr²/(1 - b(r)/r) + r²dΩ²',
          formulaDescription: _isKorean
              ? '웜홀은 두 개의 다른 시공간 영역을 연결하는 위상학적 구조입니다. 모리스-소른 통과 가능한 웜홀의 임베딩 다이어그램을 보여줍니다.'
              : 'A wormhole connects two separate spacetime regions. Visualizes the Morris-Thorne traversable wormhole embedding diagram.',
          simulation: SizedBox(
            height: 380,
            child: GestureDetector(
              onPanStart: handlePanStart,
              onPanUpdate: (d) => handlePanUpdate(d, setState),
              child: CustomPaint(
                painter: _WormholePainter(
                  time: _time,
                  throatRadius: _throatRadius,
                  funnelDepth: _funnelDepth,
                  rotX: rotX,
                  rotY: rotY,
                  scale: scale3d,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '목 반경 r₀' : 'Throat Radius r₀',
                  value: _throatRadius,
                  min: 0.4,
                  max: 2.0,
                  defaultValue: 1.0,
                  formatValue: (v) => '${v.toStringAsFixed(2)} r_s',
                  onChanged: (v) => setState(() => _throatRadius = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '깔때기 깊이' : 'Funnel Depth',
                    value: _funnelDepth,
                    min: 1.0,
                    max: 4.0,
                    defaultValue: 2.5,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _funnelDepth = v),
                  ),
                ],
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

class _WormholePainter extends CustomPainter {
  final double time;
  final double throatRadius;
  final double funnelDepth;
  final double rotX;
  final double rotY;
  final double scale;

  _WormholePainter({
    required this.time,
    required this.throatRadius,
    required this.funnelDepth,
    required this.rotX,
    required this.rotY,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0D1A20),
    );

    final center = Offset(size.width / 2, size.height / 2);
    final proj = Projection3D(
      rotX: rotX,
      rotY: rotY,
      scale: scale * (size.width / 320),
      center: center,
    );

    // Draw background stars (seeded)
    _drawStars(canvas, size);

    // Draw gravitational lensing grid (warped spacetime around wormhole)
    _drawSpacetimeGrid(canvas, proj, size);

    // Draw wormhole funnel structure
    _drawWormholeFunnels(canvas, proj);

    // Draw photon particles traveling through wormhole
    _drawPhotons(canvas, proj);

    // Draw info panel
    _drawInfoPanel(canvas, size);
  }

  void _drawStars(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final wormholeCenterX = size.width / 2;
    final wormholeCenterY = size.height / 2;
    for (int i = 0; i < 60; i++) {
      double sx = rng.nextDouble() * size.width;
      double sy = rng.nextDouble() * size.height;
      final dx = sx - wormholeCenterX;
      final dy = sy - wormholeCenterY;
      final dist = math.sqrt(dx * dx + dy * dy);
      // Gravitational lensing distortion: pull stars toward wormhole
      if (dist > 20 && dist < 200) {
        final warpStrength = 800.0 / (dist * dist + 1);
        sx += dx * warpStrength * (-1.0 / dist);
        sy += dy * warpStrength * (-1.0 / dist);
      }
      final radius = rng.nextDouble() * 1.5 + 0.3;
      final brightness = rng.nextDouble() * 0.6 + 0.2;
      // Twinkling
      final twinkle = 0.7 + 0.3 * math.sin(time * (rng.nextDouble() * 2 + 1) + i);
      canvas.drawCircle(
        Offset(sx, sy),
        radius,
        Paint()..color = Colors.white.withValues(alpha: brightness * twinkle),
      );
    }
  }

  void _drawSpacetimeGrid(Canvas canvas, Projection3D proj, Size size) {
    // Draw a flat grid warped by the wormhole in the XZ plane
    const gridSize = 4.5;
    const gridDivs = 14;
    final step = gridSize / gridDivs;

    for (int i = 0; i <= gridDivs; i++) {
      final t = -gridSize / 2 + i * step;
      // X direction lines (along Z)
      final pathX = Path();
      bool movedX = false;
      for (int j = 0; j <= 40; j++) {
        final z = -gridSize / 2 + j * (gridSize / 40);
        final r2d = math.sqrt(t * t + z * z);
        // Warp y based on distance (gravity well)
        final warpY = -0.4 * throatRadius / (r2d + 0.3);
        final p = proj.project(t, warpY, z);
        if (!movedX) {
          pathX.moveTo(p.dx, p.dy);
          movedX = true;
        } else {
          pathX.lineTo(p.dx, p.dy);
        }
      }
      final alphaX = (0.15 + 0.08 * math.sin(time * 0.3 + i * 0.5)).clamp(0.0, 1.0);
      canvas.drawPath(
        pathX,
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: alphaX)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke,
      );

      // Z direction lines (along X)
      final pathZ = Path();
      bool movedZ = false;
      for (int j = 0; j <= 40; j++) {
        final x = -gridSize / 2 + j * (gridSize / 40);
        final r2d = math.sqrt(x * x + t * t);
        final warpY = -0.4 * throatRadius / (r2d + 0.3);
        final p = proj.project(x, warpY, t);
        if (!movedZ) {
          pathZ.moveTo(p.dx, p.dy);
          movedZ = true;
        } else {
          pathZ.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        pathZ,
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: alphaX * 0.7)
          ..strokeWidth = 0.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawWormholeFunnels(Canvas canvas, Projection3D proj) {
    // Wormhole embedding: r(l) = sqrt(r0^2 + l^2), where l is proper distance along throat
    // Two funnels: upper (positive l) and lower (negative l)
    const latSteps = 18;
    const lonSteps = 24;
    const maxL = 3.5;

    for (int upper = 0; upper < 2; upper++) {
      final sign = upper == 0 ? 1.0 : -1.0;

      for (int li = 0; li <= latSteps; li++) {
        // l goes from 0 (throat) outward
        final lFrac = li / latSteps;
        final l = lFrac * maxL * funnelDepth / 2.5;
        // Embedding radius
        final r = throatRadius * math.sqrt(1.0 + (l / throatRadius) * (l / throatRadius));
        // Height in embedding space
        // Integrate: z(l) = integral sqrt(1 - (r0/r)^2) ... approximate with l * compression
        final embeddingZ = sign * l * 0.85;

        // Depth factor for coloring (0 = throat, 1 = outer edge)
        final depthFactor = lFrac;

        // Color: throat = bright cyan with glow, outer = dark purple
        final cyanR = (0.0 + 0.0 * depthFactor).clamp(0.0, 1.0);
        final cyanG = (0.83 - 0.83 * depthFactor).clamp(0.0, 1.0);
        final cyanB = (1.0 - 0.3 * depthFactor).clamp(0.0, 1.0);
        final alpha = (0.7 - 0.45 * depthFactor).clamp(0.0, 1.0);
        final color = Color.fromARGB(
          (alpha * 255).toInt(),
          (cyanR * 255).toInt(),
          (cyanG * 255).toInt(),
          (cyanB * 255).toInt(),
        );

        // Draw longitude circle at this depth
        final path = Path();
        for (int loni = 0; loni <= lonSteps; loni++) {
          final phi = loni * 2 * math.pi / lonSteps;
          final x = r * math.cos(phi);
          final z = r * math.sin(phi);
          final p = proj.project(x, embeddingZ, z);
          if (loni == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        final sw = li == 0 ? 2.5 : 1.0;
        final paint = Paint()
          ..color = color
          ..strokeWidth = sw
          ..style = PaintingStyle.stroke;

        // Throat glow
        if (li == 0) {
          final glowPulse = 0.5 + 0.5 * math.sin(time * 2.5);
          canvas.drawPath(
            path,
            Paint()
              ..color = const Color(0xFF00D4FF).withValues(alpha: 0.25 + 0.15 * glowPulse)
              ..strokeWidth = 8.0
              ..style = PaintingStyle.stroke
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
        }
        canvas.drawPath(path, paint);
      }

      // Meridian lines (longitude lines)
      for (int loni = 0; loni < lonSteps; loni++) {
        final phi = loni * 2 * math.pi / lonSteps;
        final path = Path();
        for (int li = 0; li <= latSteps; li++) {
          final lFrac = li / latSteps;
          final l = lFrac * maxL * funnelDepth / 2.5;
          final r = throatRadius * math.sqrt(1.0 + (l / throatRadius) * (l / throatRadius));
          final embeddingZ = sign * l * 0.85;
          final x = r * math.cos(phi);
          final z = r * math.sin(phi);
          final p = proj.project(x, embeddingZ, z);
          if (li == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        final meridianAlpha = 0.2 + 0.1 * math.cos(phi * 3 + time * 0.3);
        canvas.drawPath(
          path,
          Paint()
            ..color = Color.lerp(
              const Color(0xFF00D4FF),
              const Color(0xFF7B2FBE),
              0.4,
            )!.withValues(alpha: meridianAlpha.clamp(0.0, 1.0))
            ..strokeWidth = 0.8
            ..style = PaintingStyle.stroke,
        );
      }
    }
  }

  void _drawPhotons(Canvas canvas, Projection3D proj) {
    const nPhotons = 5;
    for (int i = 0; i < nPhotons; i++) {
      final phase = time * 0.55 + i * 2 * math.pi / nPhotons;
      // Photon travels from upper universe through throat to lower
      // l goes from +maxL to -maxL
      final lNorm = math.sin(phase); // -1 to +1
      final l = lNorm * 2.8 * funnelDepth / 2.5;
      final r = throatRadius * math.sqrt(1.0 + (l / throatRadius) * (l / throatRadius));
      final embeddingZ = l * 0.85;
      // Spiral phi
      final phi = phase * 2.5 + i * 1.3;
      final x = r * math.cos(phi);
      final z = r * math.sin(phi);
      final p = proj.project(x, embeddingZ, z);

      // Glow
      final brightness = 0.8 + 0.2 * math.sin(time * 4 + i * 1.7);
      // Near throat: brightest
      final throatProximity = 1.0 - (l.abs() / (2.8 * funnelDepth / 2.5)).clamp(0.0, 1.0);
      final glowRadius = 3.0 + 5.0 * throatProximity;
      canvas.drawCircle(
        p,
        glowRadius * 2,
        Paint()
          ..color = const Color(0xFF00D4FF).withValues(alpha: 0.15 * brightness * throatProximity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        p,
        glowRadius,
        Paint()
          ..color = const Color(0xFF00FFFF).withValues(alpha: 0.5 * brightness)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(
        p,
        2.5,
        Paint()..color = Colors.white.withValues(alpha: brightness),
      );
    }
  }

  void _drawInfoPanel(Canvas canvas, Size size) {
    final panelPaint = Paint()
      ..color = const Color(0xFF0D1A20).withValues(alpha: 0.85);
    final panelRect = Rect.fromLTWH(size.width - 140, size.height - 80, 130, 70);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(8)),
      panelPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    void drawText(String text, Offset offset, double fontSize, Color color) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontFamily: 'monospace')),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, offset);
    }

    drawText('Einstein-Rosen Bridge', Offset(panelRect.left + 6, panelRect.top + 6), 8, const Color(0xFF00D4FF));
    drawText('r₀ = ${throatRadius.toStringAsFixed(2)} r_s', Offset(panelRect.left + 6, panelRect.top + 22), 10, const Color(0xFFE0F4FF));
    drawText('b(r) = r₀²/r', Offset(panelRect.left + 6, panelRect.top + 38), 10, const Color(0xFF5A8A9A));
    drawText('Traversable: YES', Offset(panelRect.left + 6, panelRect.top + 54), 9,
        const Color(0xFF64FF8C));
  }

  @override
  bool shouldRepaint(covariant _WormholePainter old) => true;
}
