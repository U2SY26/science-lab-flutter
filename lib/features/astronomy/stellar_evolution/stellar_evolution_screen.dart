import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Stellar Evolution Simulation
class StellarEvolutionScreen extends StatefulWidget {
  const StellarEvolutionScreen({super.key});

  @override
  State<StellarEvolutionScreen> createState() => _StellarEvolutionScreenState();
}

class _StellarEvolutionScreenState extends State<StellarEvolutionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _stellarMass = 1.0; // Solar masses
  double _evolutionStage = 0.0; // 0-1 representing full life cycle
  bool _isAnimating = false;
  double _animationSpeed = 1.0;
  bool _showHRDiagram = true;
  bool _isKorean = true;

  // Stellar evolution stages
  static const List<Map<String, dynamic>> _stages = [
    {'name': 'Protostar', 'nameKr': '원시별', 'color': 0xFFFF6B6B, 'temp': 3000, 'size': 0.8},
    {'name': 'Main Sequence', 'nameKr': '주계열성', 'color': 0xFFFFD93D, 'temp': 5800, 'size': 1.0},
    {'name': 'Subgiant', 'nameKr': '아거성', 'color': 0xFFFFB347, 'temp': 5000, 'size': 2.0},
    {'name': 'Red Giant', 'nameKr': '적색거성', 'color': 0xFFFF6B35, 'temp': 4000, 'size': 5.0},
    {'name': 'Helium Flash', 'nameKr': '헬륨 섬광', 'color': 0xFFFFFFFF, 'temp': 10000, 'size': 4.0},
    {'name': 'Horizontal Branch', 'nameKr': '수평가지', 'color': 0xFFFFD700, 'temp': 6000, 'size': 3.0},
    {'name': 'AGB Star', 'nameKr': 'AGB 별', 'color': 0xFFFF4500, 'temp': 3500, 'size': 8.0},
    {'name': 'Planetary Nebula', 'nameKr': '행성상 성운', 'color': 0xFF00CED1, 'temp': 30000, 'size': 0.5},
    {'name': 'White Dwarf', 'nameKr': '백색왜성', 'color': 0xFFE6E6FA, 'temp': 25000, 'size': 0.3},
  ];

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
      _evolutionStage += 0.001 * _animationSpeed;
      if (_evolutionStage >= 1.0) {
        _evolutionStage = 0.0;
      }
    });
  }

  int get _currentStageIndex => (_evolutionStage * (_stages.length - 1)).floor().clamp(0, _stages.length - 1);

  Map<String, dynamic> get _currentStage => _stages[_currentStageIndex];

  String get _finalFate {
    if (_stellarMass < 0.5) {
      return _isKorean ? '적색왜성 (매우 긴 수명)' : 'Red Dwarf (Very Long Life)';
    } else if (_stellarMass < 8) {
      return _isKorean ? '백색왜성' : 'White Dwarf';
    } else if (_stellarMass < 25) {
      return _isKorean ? '중성자별 (초신성 폭발)' : 'Neutron Star (Supernova)';
    } else {
      return _isKorean ? '블랙홀 (초신성 폭발)' : 'Black Hole (Supernova)';
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _evolutionStage = 0;
      _isAnimating = false;
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
              _isKorean ? '천문학 시뮬레이션' : 'ASTRONOMY SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '항성 진화' : 'Stellar Evolution',
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
          category: _isKorean ? '천문학 시뮬레이션' : 'ASTRONOMY SIMULATION',
          title: _isKorean ? '항성 진화' : 'Stellar Evolution',
          formula: 'L ∝ M^3.5, τ ∝ M/L ∝ M^-2.5',
          formulaDescription: _isKorean
              ? '별의 광도는 질량의 3.5제곱에 비례합니다. 따라서 무거운 별은 더 밝지만 연료를 빨리 소모하여 수명이 짧습니다.'
              : 'Luminosity scales with mass to the 3.5 power. Massive stars are brighter but burn fuel faster, living shorter lives.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: StellarEvolutionPainter(
                stellarMass: _stellarMass,
                evolutionStage: _evolutionStage,
                showHRDiagram: _showHRDiagram,
                currentStage: _currentStage,
                isKorean: _isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stage selection presets
              PresetGroup(
                label: _isKorean ? '진화 단계' : 'Evolution Stage',
                presets: [0, 2, 4, 6, 8].map((index) {
                  return PresetButton(
                    label: _isKorean ? _stages[index]['nameKr'] : _stages[index]['name'],
                    isSelected: _currentStageIndex == index,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _evolutionStage = index / (_stages.length - 1));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '별의 질량' : 'Stellar Mass',
                  value: _stellarMass,
                  min: 0.3,
                  max: 30,
                  defaultValue: 1.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)} M☉',
                  onChanged: (v) => setState(() => _stellarMass = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '진화 진행' : 'Evolution Progress',
                    value: _evolutionStage,
                    min: 0,
                    max: 1,
                    defaultValue: 0,
                    formatValue: (v) => '${(v * 100).toStringAsFixed(0)}%',
                    onChanged: (v) => setState(() => _evolutionStage = v),
                  ),
                  SimSlider(
                    label: _isKorean ? '애니메이션 속도' : 'Animation Speed',
                    value: _animationSpeed,
                    min: 0.5,
                    max: 3.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() => _animationSpeed = v),
                  ),
                  SimToggle(
                    label: _isKorean ? 'HR 다이어그램' : 'HR Diagram',
                    value: _showHRDiagram,
                    onChanged: (v) => setState(() => _showHRDiagram = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _StageInfoCard(
                stage: _currentStage,
                finalFate: _finalFate,
                stellarMass: _stellarMass,
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

class _StageInfoCard extends StatelessWidget {
  final Map<String, dynamic> stage;
  final String finalFate;
  final double stellarMass;
  final bool isKorean;

  const _StageInfoCard({
    required this.stage,
    required this.finalFate,
    required this.stellarMass,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(stage['color']).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Color(stage['color']),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isKorean ? stage['nameKr'] : stage['name'],
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isKorean
                ? '표면 온도: ${stage['temp']} K, 상대 크기: ${stage['size']}x'
                : 'Surface Temp: ${stage['temp']} K, Relative Size: ${stage['size']}x',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            isKorean ? '최종 운명: $finalFate' : 'Final Fate: $finalFate',
            style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class StellarEvolutionPainter extends CustomPainter {
  final double stellarMass;
  final double evolutionStage;
  final bool showHRDiagram;
  final Map<String, dynamic> currentStage;
  final bool isKorean;

  StellarEvolutionPainter({
    required this.stellarMass,
    required this.evolutionStage,
    required this.showHRDiagram,
    required this.currentStage,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050510),
    );

    // Stars
    _drawStars(canvas, size);

    if (showHRDiagram) {
      _drawHRDiagram(canvas, size);
    } else {
      _drawStar(canvas, size);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);
    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawCircle(
        Offset(x, y),
        random.nextDouble() * 1.0 + 0.3,
        Paint()..color = Colors.white.withValues(alpha: random.nextDouble() * 0.3 + 0.1),
      );
    }
  }

  void _drawStar(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final baseRadius = 40.0;
    final starRadius = baseRadius * currentStage['size'] * math.pow(stellarMass, 0.3);
    final starColor = Color(currentStage['color']);

    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          starColor,
          starColor.withValues(alpha: 0.5),
          starColor.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: starRadius * 2));
    canvas.drawCircle(Offset(centerX, centerY), starRadius * 2, glowPaint);

    // Star body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        colors: [
          Colors.white,
          starColor,
          starColor.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: starRadius));
    canvas.drawCircle(Offset(centerX, centerY), starRadius, bodyPaint);

    // Surface details (convection cells for giant stars)
    if (currentStage['size'] > 2) {
      _drawConvectionCells(canvas, centerX, centerY, starRadius, starColor);
    }
  }

  void _drawConvectionCells(Canvas canvas, double cx, double cy, double radius, Color baseColor) {
    final random = math.Random(123);
    final cellPaint = Paint()..color = baseColor.withValues(alpha: 0.3);

    for (int i = 0; i < 15; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final dist = random.nextDouble() * radius * 0.7;
      final cellRadius = random.nextDouble() * radius * 0.15 + radius * 0.05;

      canvas.drawCircle(
        Offset(cx + dist * math.cos(angle), cy + dist * math.sin(angle)),
        cellRadius,
        cellPaint,
      );
    }
  }

  void _drawHRDiagram(Canvas canvas, Size size) {
    final diagramLeft = size.width * 0.15;
    final diagramRight = size.width * 0.85;
    final diagramTop = size.height * 0.1;
    final diagramBottom = size.height * 0.85;
    final diagramWidth = diagramRight - diagramLeft;
    final diagramHeight = diagramBottom - diagramTop;

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(diagramLeft, diagramBottom), Offset(diagramRight, diagramBottom), axisPaint);
    canvas.drawLine(Offset(diagramLeft, diagramTop), Offset(diagramLeft, diagramBottom), axisPaint);

    // Main sequence band
    final mainSequencePath = Path()
      ..moveTo(diagramLeft + diagramWidth * 0.1, diagramTop + diagramHeight * 0.1)
      ..lineTo(diagramLeft + diagramWidth * 0.15, diagramTop + diagramHeight * 0.15)
      ..lineTo(diagramLeft + diagramWidth * 0.85, diagramTop + diagramHeight * 0.85)
      ..lineTo(diagramLeft + diagramWidth * 0.9, diagramTop + diagramHeight * 0.9)
      ..lineTo(diagramLeft + diagramWidth * 0.8, diagramTop + diagramHeight * 0.95)
      ..lineTo(diagramLeft + diagramWidth * 0.1, diagramTop + diagramHeight * 0.2)
      ..close();

    canvas.drawPath(
      mainSequencePath,
      Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.2),
    );

    // Evolution track
    _drawEvolutionTrack(canvas, diagramLeft, diagramTop, diagramWidth, diagramHeight);

    // Current position
    final temp = currentStage['temp'].toDouble();
    final luminosity = currentStage['size'].toDouble();

    // Map to diagram coordinates (temp decreases left to right, luminosity increases bottom to top)
    final x = diagramLeft + diagramWidth * (1 - (temp - 2000) / 30000);
    final y = diagramBottom - diagramHeight * math.log(luminosity + 1) / math.log(100);

    // Star marker
    canvas.drawCircle(
      Offset(x, y),
      8,
      Paint()..color = Color(currentStage['color']),
    );
    canvas.drawCircle(
      Offset(x, y),
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Labels
    _drawHRLabels(canvas, size, diagramLeft, diagramRight, diagramTop, diagramBottom);
  }

  void _drawEvolutionTrack(Canvas canvas, double left, double top, double width, double height) {
    final trackPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    bool first = true;

    // Plot evolution track based on stages
    final stages = [
      {'temp': 3000.0, 'lum': 0.5},  // Protostar
      {'temp': 5800.0, 'lum': 1.0},  // Main Sequence
      {'temp': 5000.0, 'lum': 3.0},  // Subgiant
      {'temp': 4000.0, 'lum': 20.0}, // Red Giant
      {'temp': 10000.0, 'lum': 15.0}, // Helium Flash
      {'temp': 6000.0, 'lum': 10.0}, // Horizontal Branch
      {'temp': 3500.0, 'lum': 50.0}, // AGB
      {'temp': 30000.0, 'lum': 2.0}, // Planetary Nebula
      {'temp': 25000.0, 'lum': 0.01}, // White Dwarf
    ];

    for (final stage in stages) {
      final x = left + width * (1 - (stage['temp']! - 2000) / 30000);
      final y = top + height - height * math.log(stage['lum']! + 1) / math.log(100);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, trackPaint);
  }

  void _drawHRLabels(Canvas canvas, Size size, double left, double right, double top, double bottom) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Temperature axis label
    textPainter.text = TextSpan(
      text: isKorean ? '온도 (K) →' : 'Temperature (K) →',
      style: const TextStyle(color: Colors.white70, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((left + right) / 2 - textPainter.width / 2, bottom + 10));

    // Luminosity axis label
    canvas.save();
    canvas.translate(left - 20, (top + bottom) / 2);
    canvas.rotate(-math.pi / 2);
    textPainter.text = TextSpan(
      text: isKorean ? '광도 (L☉) →' : 'Luminosity (L☉) →',
      style: const TextStyle(color: Colors.white70, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
    canvas.restore();

    // Hot/Cool labels
    textPainter.text = const TextSpan(
      text: 'Hot',
      style: TextStyle(color: Colors.white54, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(left, bottom + 25));

    textPainter.text = const TextSpan(
      text: 'Cool',
      style: TextStyle(color: Colors.white54, fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(right - textPainter.width, bottom + 25));
  }

  @override
  bool shouldRepaint(covariant StellarEvolutionPainter oldDelegate) {
    return stellarMass != oldDelegate.stellarMass ||
        evolutionStage != oldDelegate.evolutionStage ||
        showHRDiagram != oldDelegate.showHRDiagram;
  }
}
