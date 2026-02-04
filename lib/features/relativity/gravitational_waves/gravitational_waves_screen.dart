import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Gravitational Waves Simulation
class GravitationalWavesScreen extends StatefulWidget {
  const GravitationalWavesScreen({super.key});

  @override
  State<GravitationalWavesScreen> createState() => _GravitationalWavesScreenState();
}

class _GravitationalWavesScreenState extends State<GravitationalWavesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _orbitalFrequency = 1.0;
  double _binaryMass = 30.0; // Solar masses (total)
  double _separation = 0.5; // Normalized separation
  double _time = 0.0;
  bool _isAnimating = true;
  bool _showWaves = true;
  bool _showStrain = true;
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
      _time += 0.05 * _orbitalFrequency;
      // Spiral in (chirp)
      if (_separation > 0.1) {
        _separation -= 0.0001 * _orbitalFrequency;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _orbitalFrequency = 1.0;
      _separation = 0.5;
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
              _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '중력파' : 'Gravitational Waves',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
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
          title: _isKorean ? '중력파' : 'Gravitational Waves',
          formula: 'h ~ (GM/c²r) × (v/c)²',
          formulaDescription: _isKorean
              ? '중력파는 가속하는 질량에 의해 생성되는 시공간의 물결입니다. 2015년 LIGO가 블랙홀 충돌에서 발생한 중력파를 최초로 직접 검출했습니다.'
              : 'Gravitational waves are ripples in spacetime from accelerating masses. In 2015, LIGO made the first direct detection from merging black holes.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: GravitationalWavesPainter(
                time: _time,
                binaryMass: _binaryMass,
                separation: _separation,
                orbitalFrequency: _orbitalFrequency,
                showWaves: _showWaves,
                showStrain: _showStrain,
                isKorean: _isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '궤도 주파수' : 'Orbital Frequency',
                  value: _orbitalFrequency,
                  min: 0.5,
                  max: 3.0,
                  defaultValue: 1.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)}x',
                  onChanged: (v) => setState(() => _orbitalFrequency = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '쌍성 총 질량' : 'Binary Total Mass',
                    value: _binaryMass,
                    min: 10,
                    max: 100,
                    defaultValue: 30,
                    formatValue: (v) => '${v.toStringAsFixed(0)} M☉',
                    onChanged: (v) => setState(() => _binaryMass = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '파동 표시' : 'Show Waves',
                    value: _showWaves,
                    onChanged: (v) => setState(() => _showWaves = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '변형률 그래프' : 'Strain Graph',
                    value: _showStrain,
                    onChanged: (v) => setState(() => _showStrain = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                separation: _separation,
                binaryMass: _binaryMass,
                isKorean: _isKorean,
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

class _InfoCard extends StatelessWidget {
  final double separation;
  final double binaryMass;
  final bool isKorean;

  const _InfoCard({
    required this.separation,
    required this.binaryMass,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    final frequency = 1 / (separation * separation * separation).clamp(0.01, 100);
    final strain = binaryMass / 30 * (1 - separation) * 1e-21;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.waves, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '중력파 주파수' : 'GW Frequency',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '~${(frequency * 100).toStringAsFixed(0)} Hz',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.straighten, size: 14, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                isKorean ? '변형률 h' : 'Strain h',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '~${strain.toStringAsExponential(1)}',
                style: const TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? 'LIGO 감도: ~10⁻²¹ (4km 팔 길이가 양성자 크기의 1/1000만큼 변화)'
                : 'LIGO sensitivity: ~10⁻²¹ (4km arm changes by 1/1000th of a proton)',
            style: TextStyle(color: AppColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class GravitationalWavesPainter extends CustomPainter {
  final double time;
  final double binaryMass;
  final double separation;
  final double orbitalFrequency;
  final bool showWaves;
  final bool showStrain;
  final bool isKorean;

  GravitationalWavesPainter({
    required this.time,
    required this.binaryMass,
    required this.separation,
    required this.orbitalFrequency,
    required this.showWaves,
    required this.showStrain,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = showStrain ? size.height * 0.35 : size.height / 2;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0A0A1A),
    );

    // Draw gravitational waves
    if (showWaves) {
      _drawGravitationalWaves(canvas, centerX, centerY, size);
    }

    // Draw binary system
    _drawBinarySystem(canvas, centerX, centerY);

    // Draw strain waveform
    if (showStrain) {
      _drawStrainGraph(canvas, size);
    }

    // Labels
    _drawLabels(canvas, size, centerX, centerY);
  }

  void _drawGravitationalWaves(Canvas canvas, double cx, double cy, Size size) {
    // Quadrupole pattern
    final maxRadius = math.min(size.width, size.height) * 0.6;
    final wavelength = 50.0 * separation;
    final amplitude = (1 - separation) * 10;

    // Draw expanding wave fronts
    for (int wave = 0; wave < 8; wave++) {
      final baseRadius = (time * 30 + wave * wavelength) % maxRadius;
      if (baseRadius < 30) continue;

      // Quadrupole distortion
      final path = Path();
      for (double angle = 0; angle <= 2 * math.pi; angle += 0.05) {
        // Plus polarization: stretches along one axis, compresses along perpendicular
        final distortion = amplitude * math.cos(2 * (angle + time)) / (baseRadius / 50 + 1);
        final r = baseRadius + distortion;

        final x = cx + r * math.cos(angle);
        final y = cy + r * math.sin(angle);

        if (angle == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      final alpha = (1 - baseRadius / maxRadius) * 0.5;
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.accent.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawBinarySystem(Canvas canvas, double cx, double cy) {
    final orbitRadius = 40 * separation;
    final mass1 = binaryMass * 0.5;
    final mass2 = binaryMass * 0.5;

    // Orbital positions
    final angle = time;
    final x1 = cx + orbitRadius * math.cos(angle);
    final y1 = cy + orbitRadius * math.sin(angle);
    final x2 = cx - orbitRadius * math.cos(angle);
    final y2 = cy - orbitRadius * math.sin(angle);

    // Orbital trail
    final trailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(Offset(cx, cy), orbitRadius, trailPaint);

    // Black hole 1
    final radius1 = 10 * math.sqrt(mass1 / 30);
    canvas.drawCircle(Offset(x1, y1), radius1, Paint()..color = Colors.black);
    canvas.drawCircle(
      Offset(x1, y1),
      radius1,
      Paint()
        ..color = const Color(0xFFFF4500)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Black hole 2
    final radius2 = 10 * math.sqrt(mass2 / 30);
    canvas.drawCircle(Offset(x2, y2), radius2, Paint()..color = Colors.black);
    canvas.drawCircle(
      Offset(x2, y2),
      radius2,
      Paint()
        ..color = const Color(0xFF00BFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Center of mass marker
    canvas.drawCircle(
      Offset(cx, cy),
      3,
      Paint()..color = Colors.white.withValues(alpha: 0.5),
    );
  }

  void _drawStrainGraph(Canvas canvas, Size size) {
    final graphTop = size.height * 0.65;
    final graphBottom = size.height - 30;
    final graphLeft = 40.0;
    final graphRight = size.width - 20;
    final graphHeight = graphBottom - graphTop;
    final graphWidth = graphRight - graphLeft;
    final graphCenterY = graphTop + graphHeight / 2;

    // Background
    canvas.drawRect(
      Rect.fromLTRB(graphLeft, graphTop, graphRight, graphBottom),
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // Center line
    canvas.drawLine(
      Offset(graphLeft, graphCenterY),
      Offset(graphRight, graphCenterY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 1,
    );

    // Strain waveform (chirp signal)
    final strainPath = Path();
    bool first = true;

    for (double t = 0; t <= 1; t += 0.005) {
      final x = graphLeft + t * graphWidth;

      // Chirp: frequency and amplitude increase over time
      final chirpTime = t * 10;
      final localSeparation = 0.5 - t * 0.4;
      final freq = 1 / (localSeparation * localSeparation * localSeparation + 0.1);
      final amp = (1 - localSeparation) * graphHeight * 0.4;

      final phase = chirpTime * freq + time;
      final strain = amp * math.sin(phase);
      final y = graphCenterY - strain;

      if (first) {
        strainPath.moveTo(x, y);
        first = false;
      } else {
        strainPath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      strainPath,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Current time marker
    final currentX = graphLeft + (time % 10) / 10 * graphWidth;
    canvas.drawLine(
      Offset(currentX, graphTop),
      Offset(currentX, graphBottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: isKorean ? '중력파 변형률 (h)' : 'GW Strain (h)',
      style: const TextStyle(color: Colors.white70, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(graphLeft + 5, graphTop + 5));

    textPainter.text = TextSpan(
      text: isKorean ? '시간 →' : 'Time →',
      style: const TextStyle(color: Colors.white54, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(graphRight - textPainter.width - 5, graphBottom + 5));
  }

  void _drawLabels(Canvas canvas, Size size, double cx, double cy) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Binary label
    textPainter.text = TextSpan(
      text: isKorean ? '쌍성 블랙홀' : 'Binary Black Holes',
      style: const TextStyle(color: Colors.white70, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy + 60));

    // Mass labels
    textPainter.text = TextSpan(
      text: '${(binaryMass / 2).toStringAsFixed(0)} M☉',
      style: const TextStyle(color: Color(0xFFFF4500), fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 10));

    textPainter.text = TextSpan(
      text: '${(binaryMass / 2).toStringAsFixed(0)} M☉',
      style: const TextStyle(color: Color(0xFF00BFFF), fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 25));

    // Phase indicator
    String phase;
    if (separation > 0.4) {
      phase = isKorean ? '나선 진입' : 'Inspiral';
    } else if (separation > 0.15) {
      phase = isKorean ? '병합 중' : 'Merger';
    } else {
      phase = isKorean ? '고리 다운' : 'Ringdown';
    }

    textPainter.text = TextSpan(
      text: phase,
      style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 10, 10));
  }

  @override
  bool shouldRepaint(covariant GravitationalWavesPainter oldDelegate) {
    return time != oldDelegate.time ||
        binaryMass != oldDelegate.binaryMass ||
        separation != oldDelegate.separation ||
        showWaves != oldDelegate.showWaves ||
        showStrain != oldDelegate.showStrain;
  }
}
