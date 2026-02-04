import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Plate Tectonics Simulation
class PlateTectonicsScreen extends StatefulWidget {
  const PlateTectonicsScreen({super.key});

  @override
  State<PlateTectonicsScreen> createState() => _PlateTectonicsScreenState();
}

class _PlateTectonicsScreenState extends State<PlateTectonicsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _time = 0.0;
  double _plateSpeed = 1.0; // cm/year scale
  bool _isAnimating = true;
  int _boundaryType = 0; // 0: divergent, 1: convergent, 2: transform
  bool _showConvection = true;
  bool _showLabels = true;
  bool _isKorean = true;

  final List<String> _boundaryNames = ['Divergent', 'Convergent', 'Transform'];
  final List<String> _boundaryNamesKr = ['발산형', '수렴형', '변환형'];

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
      _time += 0.02 * _plateSpeed;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _plateSpeed = 1.0;
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
              _isKorean ? '지구과학 시뮬레이션' : 'EARTH SCIENCE SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '판 구조론' : 'Plate Tectonics',
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
          category: _isKorean ? '지구과학 시뮬레이션' : 'EARTH SCIENCE SIMULATION',
          title: _isKorean ? '판 구조론' : 'Plate Tectonics',
          formula: 'v ≈ 1-10 cm/year',
          formulaDescription: _isKorean
              ? '지구의 암석권은 여러 개의 판으로 나뉘어 맨틀 대류 위에서 움직입니다. 판의 경계에서 지진, 화산, 산맥 형성이 일어납니다.'
              : 'Earth\'s lithosphere is divided into plates moving on mantle convection. Earthquakes, volcanoes, and mountains form at plate boundaries.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: PlateTectonicsPainter(
                time: _time,
                boundaryType: _boundaryType,
                showConvection: _showConvection,
                showLabels: _showLabels,
                isKorean: _isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PresetGroup(
                label: _isKorean ? '경계 유형' : 'Boundary Type',
                presets: List.generate(3, (index) {
                  return PresetButton(
                    label: _isKorean ? _boundaryNamesKr[index] : _boundaryNames[index],
                    isSelected: _boundaryType == index,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _boundaryType = index);
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '판 이동 속도' : 'Plate Speed',
                  value: _plateSpeed,
                  min: 0.5,
                  max: 3.0,
                  defaultValue: 1.0,
                  formatValue: (v) => '${(v * 5).toStringAsFixed(1)} cm/yr',
                  onChanged: (v) => setState(() => _plateSpeed = v),
                ),
                advancedControls: [
                  SimToggle(
                    label: _isKorean ? '맨틀 대류' : 'Mantle Convection',
                    value: _showConvection,
                    onChanged: (v) => setState(() => _showConvection = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '라벨 표시' : 'Show Labels',
                    value: _showLabels,
                    onChanged: (v) => setState(() => _showLabels = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(boundaryType: _boundaryType, isKorean: _isKorean),
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
  final int boundaryType;
  final bool isKorean;

  const _InfoCard({required this.boundaryType, required this.isKorean});

  @override
  Widget build(BuildContext context) {
    final descriptions = isKorean
        ? [
            '발산형: 판이 멀어지며 새 지각 생성 (예: 대서양 중앙 해령)',
            '수렴형: 판이 충돌하며 섭입대/산맥 형성 (예: 히말라야)',
            '변환형: 판이 옆으로 미끄러짐 (예: 산안드레아스 단층)',
          ]
        : [
            'Divergent: Plates move apart, new crust forms (e.g., Mid-Atlantic Ridge)',
            'Convergent: Plates collide, subduction/mountains (e.g., Himalayas)',
            'Transform: Plates slide past each other (e.g., San Andreas Fault)',
          ];

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
              Icon(Icons.terrain, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '경계 특징' : 'Boundary Features',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descriptions[boundaryType],
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class PlateTectonicsPainter extends CustomPainter {
  final double time;
  final int boundaryType;
  final bool showConvection;
  final bool showLabels;
  final bool isKorean;

  PlateTectonicsPainter({
    required this.time,
    required this.boundaryType,
    required this.showConvection,
    required this.showLabels,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background - Earth cross-section
    _drawBackground(canvas, size);

    // Mantle convection
    if (showConvection) {
      _drawMantleConvection(canvas, size);
    }

    // Draw appropriate boundary type
    switch (boundaryType) {
      case 0:
        _drawDivergentBoundary(canvas, size);
        break;
      case 1:
        _drawConvergentBoundary(canvas, size);
        break;
      case 2:
        _drawTransformBoundary(canvas, size);
        break;
    }

    // Labels
    if (showLabels) {
      _drawLabels(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    // Atmosphere
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.15),
      Paint()..color = const Color(0xFF87CEEB).withValues(alpha: 0.3),
    );

    // Ocean
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.15, size.width, size.height * 0.1),
      Paint()..color = const Color(0xFF1E90FF).withValues(alpha: 0.5),
    );

    // Lithosphere (crust + upper mantle)
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.25, size.width, size.height * 0.15),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF8B4513),
            const Color(0xFFA0522D),
          ],
        ).createShader(Rect.fromLTWH(0, size.height * 0.25, size.width, size.height * 0.15)),
    );

    // Asthenosphere
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.25),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFF4500),
            const Color(0xFFFF6347),
          ],
        ).createShader(Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.25)),
    );

    // Lower mantle
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.65, size.width, size.height * 0.35),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFDC143C),
            const Color(0xFF8B0000),
          ],
        ).createShader(Rect.fromLTWH(0, size.height * 0.65, size.width, size.height * 0.35)),
    );
  }

  void _drawMantleConvection(Canvas canvas, Size size) {
    final convectionPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Left convection cell
    _drawConvectionCell(canvas, size.width * 0.25, size.height * 0.6, 80, -1, convectionPaint);

    // Right convection cell
    _drawConvectionCell(canvas, size.width * 0.75, size.height * 0.6, 80, 1, convectionPaint);
  }

  void _drawConvectionCell(Canvas canvas, double cx, double cy, double radius, int direction, Paint paint) {
    // Draw convection arrows
    for (double t = 0; t < 2 * math.pi; t += math.pi / 4) {
      final angle = t + time * 0.5 * direction;
      final x = cx + radius * 0.7 * math.cos(angle);
      final y = cy + radius * 0.5 * math.sin(angle);

      // Arrow
      final arrowAngle = angle + math.pi / 2 * direction;
      final arrowLength = 15.0;
      final ax = x + arrowLength * math.cos(arrowAngle);
      final ay = y + arrowLength * math.sin(arrowAngle);

      canvas.drawLine(Offset(x, y), Offset(ax, ay), paint);

      // Arrow head
      final headAngle1 = arrowAngle + 2.5;
      final headAngle2 = arrowAngle - 2.5;
      canvas.drawLine(
        Offset(ax, ay),
        Offset(ax - 8 * math.cos(headAngle1), ay - 8 * math.sin(headAngle1)),
        paint,
      );
      canvas.drawLine(
        Offset(ax, ay),
        Offset(ax - 8 * math.cos(headAngle2), ay - 8 * math.sin(headAngle2)),
        paint,
      );
    }
  }

  void _drawDivergentBoundary(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final crustTop = size.height * 0.25;
    final crustBottom = size.height * 0.4;

    // Gap between plates
    final gapWidth = 20 + math.sin(time) * 5;

    // Left plate
    final leftPlatePath = Path()
      ..moveTo(0, crustTop)
      ..lineTo(centerX - gapWidth / 2, crustTop)
      ..lineTo(centerX - gapWidth / 2, crustBottom)
      ..lineTo(0, crustBottom)
      ..close();
    canvas.drawPath(leftPlatePath, Paint()..color = const Color(0xFF8B4513));

    // Right plate
    final rightPlatePath = Path()
      ..moveTo(centerX + gapWidth / 2, crustTop)
      ..lineTo(size.width, crustTop)
      ..lineTo(size.width, crustBottom)
      ..lineTo(centerX + gapWidth / 2, crustBottom)
      ..close();
    canvas.drawPath(rightPlatePath, Paint()..color = const Color(0xFFA0522D));

    // Rising magma
    final magmaPath = Path()
      ..moveTo(centerX - gapWidth / 2, crustBottom)
      ..lineTo(centerX, crustTop + 20)
      ..lineTo(centerX + gapWidth / 2, crustBottom)
      ..close();

    canvas.drawPath(
      magmaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFFFF4500),
            const Color(0xFFFFD700),
          ],
        ).createShader(Rect.fromLTWH(centerX - gapWidth / 2, crustTop, gapWidth, crustBottom - crustTop)),
    );

    // New oceanic crust forming
    for (double y = crustTop + 30; y < crustBottom; y += 10) {
      final layerWidth = (crustBottom - y) / (crustBottom - crustTop - 30) * gapWidth * 0.8;
      canvas.drawLine(
        Offset(centerX - layerWidth / 2, y),
        Offset(centerX + layerWidth / 2, y),
        Paint()
          ..color = const Color(0xFF2F4F4F)
          ..strokeWidth = 3,
      );
    }

    // Movement arrows
    _drawArrow(canvas, centerX - 60, crustTop + 30, -30, 0, Colors.white);
    _drawArrow(canvas, centerX + 60, crustTop + 30, 30, 0, Colors.white);
  }

  void _drawConvergentBoundary(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final crustTop = size.height * 0.25;

    // Subducting oceanic plate (left, going under)
    final subductionPath = Path()
      ..moveTo(0, crustTop)
      ..lineTo(centerX - 20, crustTop)
      ..quadraticBezierTo(centerX, crustTop + 30, centerX + 30, size.height * 0.7)
      ..lineTo(0, size.height * 0.7)
      ..close();

    canvas.drawPath(
      subductionPath,
      Paint()..color = const Color(0xFF2F4F4F).withValues(alpha: 0.8),
    );

    // Overriding continental plate (right)
    final continentPath = Path()
      ..moveTo(centerX - 30, crustTop - 20)
      ..lineTo(size.width, crustTop)
      ..lineTo(size.width, size.height * 0.4)
      ..lineTo(centerX, size.height * 0.4)
      ..quadraticBezierTo(centerX - 20, crustTop + 20, centerX - 30, crustTop - 20);

    canvas.drawPath(continentPath, Paint()..color = const Color(0xFF8B4513));

    // Mountain range
    final mountainPath = Path()
      ..moveTo(centerX - 40, crustTop - 20);

    for (double x = centerX - 40; x < centerX + 80; x += 20) {
      final peakHeight = 30 + math.sin((x - centerX) * 0.1 + time) * 10;
      mountainPath.lineTo(x + 10, crustTop - 20 - peakHeight);
      mountainPath.lineTo(x + 20, crustTop - 20);
    }
    mountainPath.close();

    canvas.drawPath(mountainPath, Paint()..color = const Color(0xFF696969));

    // Snow caps
    for (double x = centerX - 30; x < centerX + 70; x += 20) {
      final peakHeight = 30 + math.sin((x - centerX) * 0.1 + time) * 10;
      canvas.drawCircle(
        Offset(x + 10, crustTop - 20 - peakHeight),
        8,
        Paint()..color = Colors.white,
      );
    }

    // Volcanic activity
    if ((time * 10).toInt() % 20 < 10) {
      final volcanoX = centerX + 40;
      final volcanoY = crustTop - 50;

      // Smoke
      for (int i = 0; i < 5; i++) {
        final smokeY = volcanoY - i * 15 - (time * 20) % 30;
        final smokeX = volcanoX + math.sin(smokeY * 0.1) * 10;
        canvas.drawCircle(
          Offset(smokeX, smokeY),
          8 - i.toDouble(),
          Paint()..color = Colors.grey.withValues(alpha: 0.5 - i * 0.1),
        );
      }
    }

    // Movement arrows
    _drawArrow(canvas, 80, crustTop + 30, 30, 0, Colors.white);
    _drawArrow(canvas, size.width - 80, crustTop + 30, -30, 0, Colors.white);
  }

  void _drawTransformBoundary(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final crustTop = size.height * 0.25;
    final crustBottom = size.height * 0.4;

    // Left plate (moving down in the view)
    final leftOffset = math.sin(time) * 10;
    canvas.drawRect(
      Rect.fromLTWH(0, crustTop + leftOffset, centerX - 5, crustBottom - crustTop),
      Paint()..color = const Color(0xFF8B4513),
    );

    // Right plate (moving up in the view)
    final rightOffset = -math.sin(time) * 10;
    canvas.drawRect(
      Rect.fromLTWH(centerX + 5, crustTop + rightOffset, centerX - 5, crustBottom - crustTop),
      Paint()..color = const Color(0xFFA0522D),
    );

    // Fault line
    canvas.drawLine(
      Offset(centerX, crustTop - 20),
      Offset(centerX, crustBottom + 20),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 3,
    );

    // Earthquake indicators
    for (int i = 0; i < 3; i++) {
      final quakeY = crustTop + 30 + i * 30;
      final quakeRadius = 5 + math.sin(time * 5 + i) * 3;
      canvas.drawCircle(
        Offset(centerX, quakeY),
        quakeRadius,
        Paint()
          ..color = Colors.yellow.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Movement arrows (opposite directions)
    _drawArrow(canvas, centerX - 60, crustTop + 30, 0, 20, Colors.white);
    _drawArrow(canvas, centerX + 60, crustTop + 30, 0, -20, Colors.white);
  }

  void _drawArrow(Canvas canvas, double x, double y, double dx, double dy, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y + dy), paint);

    // Arrow head
    final angle = math.atan2(dy, dx);
    final headLength = 8.0;
    canvas.drawLine(
      Offset(x + dx, y + dy),
      Offset(x + dx - headLength * math.cos(angle - 0.5), y + dy - headLength * math.sin(angle - 0.5)),
      paint,
    );
    canvas.drawLine(
      Offset(x + dx, y + dy),
      Offset(x + dx - headLength * math.cos(angle + 0.5), y + dy - headLength * math.sin(angle + 0.5)),
      paint,
    );
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Layer labels
    final labels = isKorean
        ? ['대기', '해양', '암석권', '연약권', '하부 맨틀']
        : ['Atmosphere', 'Ocean', 'Lithosphere', 'Asthenosphere', 'Lower Mantle'];

    final yPositions = [
      size.height * 0.07,
      size.height * 0.2,
      size.height * 0.32,
      size.height * 0.52,
      size.height * 0.8,
    ];

    for (int i = 0; i < labels.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.white, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, yPositions[i]));
    }
  }

  @override
  bool shouldRepaint(covariant PlateTectonicsPainter oldDelegate) {
    return time != oldDelegate.time ||
        boundaryType != oldDelegate.boundaryType ||
        showConvection != oldDelegate.showConvection ||
        showLabels != oldDelegate.showLabels;
  }
}
