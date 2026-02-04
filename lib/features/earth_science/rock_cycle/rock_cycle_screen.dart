import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Rock Cycle Simulation
class RockCycleScreen extends StatefulWidget {
  const RockCycleScreen({super.key});

  @override
  State<RockCycleScreen> createState() => _RockCycleScreenState();
}

class _RockCycleScreenState extends State<RockCycleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _time = 0.0;
  bool _isAnimating = true;
  int _selectedRockType = -1; // -1: none, 0: igneous, 1: sedimentary, 2: metamorphic
  bool _showProcesses = true;
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
      _time += 0.02;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _selectedRockType = -1;
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
              _isKorean ? '암석의 순환' : 'Rock Cycle',
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
          title: _isKorean ? '암석의 순환' : 'Rock Cycle',
          formula: _isKorean ? '화성암 ↔ 퇴적암 ↔ 변성암' : 'Igneous ↔ Sedimentary ↔ Metamorphic',
          formulaDescription: _isKorean
              ? '암석은 풍화, 침식, 퇴적, 압축, 열과 압력, 용융 등의 과정을 통해 끊임없이 순환합니다. 이 과정은 수백만 년에 걸쳐 일어납니다.'
              : 'Rocks continuously transform through weathering, erosion, deposition, compaction, heat/pressure, and melting. This process takes millions of years.',
          simulation: SizedBox(
            height: 350,
            child: GestureDetector(
              onTapDown: (details) => _handleTap(details, context),
              child: CustomPaint(
                painter: RockCyclePainter(
                  time: _time,
                  selectedRockType: _selectedRockType,
                  showProcesses: _showProcesses,
                  isKorean: _isKorean,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PresetGroup(
                label: _isKorean ? '암석 종류' : 'Rock Type',
                presets: [
                  PresetButton(
                    label: _isKorean ? '화성암' : 'Igneous',
                    isSelected: _selectedRockType == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedRockType = _selectedRockType == 0 ? -1 : 0);
                    },
                  ),
                  PresetButton(
                    label: _isKorean ? '퇴적암' : 'Sedimentary',
                    isSelected: _selectedRockType == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedRockType = _selectedRockType == 1 ? -1 : 1);
                    },
                  ),
                  PresetButton(
                    label: _isKorean ? '변성암' : 'Metamorphic',
                    isSelected: _selectedRockType == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedRockType = _selectedRockType == 2 ? -1 : 2);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimToggle(
                  label: _isKorean ? '과정 표시' : 'Show Processes',
                  value: _showProcesses,
                  onChanged: (v) => setState(() => _showProcesses = v),
                ),
              ),
              const SizedBox(height: 12),
              _InfoCard(selectedRockType: _selectedRockType, isKorean: _isKorean),
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

  void _handleTap(TapDownDetails details, BuildContext context) {
    // Could be used for interactive rock selection
  }
}

class _InfoCard extends StatelessWidget {
  final int selectedRockType;
  final bool isKorean;

  const _InfoCard({required this.selectedRockType, required this.isKorean});

  @override
  Widget build(BuildContext context) {
    final rockInfo = isKorean
        ? [
            ['화성암', '마그마/용암이 냉각되어 형성', '예: 화강암, 현무암, 흑요석'],
            ['퇴적암', '퇴적물이 압축되어 형성', '예: 사암, 석회암, 셰일'],
            ['변성암', '열과 압력으로 기존 암석이 변형', '예: 대리암, 편암, 규암'],
          ]
        : [
            ['Igneous', 'Formed from cooled magma/lava', 'Examples: Granite, Basite, Obsidian'],
            ['Sedimentary', 'Formed from compressed sediments', 'Examples: Sandstone, Limestone, Shale'],
            ['Metamorphic', 'Existing rocks transformed by heat/pressure', 'Examples: Marble, Schist, Quartzite'],
          ];

    if (selectedRockType < 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.simBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          isKorean ? '암석 종류를 선택하여 자세한 정보를 확인하세요' : 'Select a rock type to see details',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      );
    }

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
          Text(
            rockInfo[selectedRockType][0],
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rockInfo[selectedRockType][1],
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            rockInfo[selectedRockType][2],
            style: TextStyle(color: AppColors.accent, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class RockCyclePainter extends CustomPainter {
  final double time;
  final int selectedRockType;
  final bool showProcesses;
  final bool isKorean;

  RockCyclePainter({
    required this.time,
    required this.selectedRockType,
    required this.showProcesses,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF1A1A2E),
    );

    // Draw cycle diagram
    _drawCycleDiagram(canvas, centerX, centerY, size);

    // Draw rocks
    _drawRocks(canvas, centerX, centerY, size);

    // Draw processes/arrows
    if (showProcesses) {
      _drawProcesses(canvas, centerX, centerY, size);
    }

    // Draw animated particles
    _drawAnimatedParticles(canvas, centerX, centerY, size);
  }

  void _drawCycleDiagram(Canvas canvas, double cx, double cy, Size size) {
    final radius = math.min(size.width, size.height) * 0.35;

    // Central cycle circle (faint)
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawRocks(Canvas canvas, double cx, double cy, Size size) {
    final radius = math.min(size.width, size.height) * 0.35;

    // Rock positions (triangle arrangement)
    final igneous = Offset(cx, cy - radius); // Top
    final sedimentary = Offset(cx - radius * 0.866, cy + radius * 0.5); // Bottom left
    final metamorphic = Offset(cx + radius * 0.866, cy + radius * 0.5); // Bottom right

    // Draw each rock type
    _drawRockNode(canvas, igneous, 0, isKorean ? '화성암' : 'Igneous', const Color(0xFFFF6347));
    _drawRockNode(canvas, sedimentary, 1, isKorean ? '퇴적암' : 'Sedimentary', const Color(0xFFDEB887));
    _drawRockNode(canvas, metamorphic, 2, isKorean ? '변성암' : 'Metamorphic', const Color(0xFF9370DB));

    // Magma at center bottom
    _drawMagma(canvas, cx, cy + radius * 0.3);
  }

  void _drawRockNode(Canvas canvas, Offset pos, int type, String label, Color color) {
    final isSelected = selectedRockType == type;
    final nodeRadius = isSelected ? 45.0 : 40.0;

    // Glow if selected
    if (isSelected) {
      canvas.drawCircle(
        pos,
        nodeRadius + 10,
        Paint()..color = color.withValues(alpha: 0.3),
      );
    }

    // Rock body (irregular shape)
    final rockPath = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final variation = 0.8 + (math.sin(i * 1.5) * 0.2);
      final r = nodeRadius * variation;
      final x = pos.dx + r * math.cos(angle);
      final y = pos.dy + r * math.sin(angle);
      if (i == 0) {
        rockPath.moveTo(x, y);
      } else {
        rockPath.lineTo(x, y);
      }
    }
    rockPath.close();

    // Rock fill with texture
    final rockGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        color,
        color.withValues(alpha: 0.7),
      ],
    ).createShader(Rect.fromCircle(center: pos, radius: nodeRadius));

    canvas.drawPath(rockPath, Paint()..shader = rockGradient);
    canvas.drawPath(
      rockPath,
      Paint()
        ..color = isSelected ? Colors.white : color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3 : 2,
    );

    // Add texture details
    _addRockTexture(canvas, pos, type, nodeRadius);

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: isSelected ? 12 : 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(pos.dx - textPainter.width / 2, pos.dy + nodeRadius + 8));
  }

  void _addRockTexture(Canvas canvas, Offset pos, int type, double radius) {
    final random = math.Random(type * 100);

    switch (type) {
      case 0: // Igneous - crystalline
        for (int i = 0; i < 8; i++) {
          final x = pos.dx + (random.nextDouble() - 0.5) * radius * 1.2;
          final y = pos.dy + (random.nextDouble() - 0.5) * radius * 1.2;
          canvas.drawRect(
            Rect.fromCenter(center: Offset(x, y), width: 8, height: 8),
            Paint()..color = Colors.white.withValues(alpha: 0.3),
          );
        }
        break;
      case 1: // Sedimentary - layers
        for (int i = -2; i <= 2; i++) {
          canvas.drawLine(
            Offset(pos.dx - radius * 0.6, pos.dy + i * 8),
            Offset(pos.dx + radius * 0.6, pos.dy + i * 8),
            Paint()
              ..color = Colors.brown.withValues(alpha: 0.4)
              ..strokeWidth = 2,
          );
        }
        break;
      case 2: // Metamorphic - foliation
        for (int i = 0; i < 5; i++) {
          final path = Path();
          final startY = pos.dy - radius * 0.5 + i * 12;
          path.moveTo(pos.dx - radius * 0.5, startY);
          path.quadraticBezierTo(
            pos.dx,
            startY + 5,
            pos.dx + radius * 0.5,
            startY,
          );
          canvas.drawPath(
            path,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.2)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
        break;
    }
  }

  void _drawMagma(Canvas canvas, double x, double y) {
    // Magma pool
    final magmaGradient = RadialGradient(
      colors: [
        const Color(0xFFFFD700),
        const Color(0xFFFF4500),
        const Color(0xFFDC143C),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 30));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 60, height: 30),
      Paint()..shader = magmaGradient,
    );

    // Bubbles
    for (int i = 0; i < 3; i++) {
      final bubbleY = y - 10 - (time * 20 + i * 15) % 40;
      final bubbleX = x + math.sin(time * 2 + i) * 15;
      canvas.drawCircle(
        Offset(bubbleX, bubbleY),
        3 + i.toDouble(),
        Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.5),
      );
    }

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: isKorean ? '마그마' : 'Magma',
        style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y + 20));
  }

  void _drawProcesses(Canvas canvas, double cx, double cy, Size size) {
    final radius = math.min(size.width, size.height) * 0.35;

    // Process labels and arrows
    final processes = isKorean
        ? [
            ['냉각', '풍화/침식', '압축/고결'],
            ['용융', '열/압력', '융기/풍화'],
          ]
        : [
            ['Cooling', 'Weathering', 'Compaction'],
            ['Melting', 'Heat/Pressure', 'Uplift'],
          ];

    // Arrow: Igneous -> Sedimentary (weathering)
    _drawProcessArrow(
      canvas,
      Offset(cx - radius * 0.3, cy - radius * 0.6),
      Offset(cx - radius * 0.7, cy + radius * 0.2),
      processes[0][1],
      Colors.cyan,
    );

    // Arrow: Sedimentary -> Metamorphic (heat/pressure)
    _drawProcessArrow(
      canvas,
      Offset(cx, cy + radius * 0.5),
      Offset(cx + radius * 0.5, cy + radius * 0.3),
      processes[1][1],
      Colors.orange,
    );

    // Arrow: Metamorphic -> Igneous (melting)
    _drawProcessArrow(
      canvas,
      Offset(cx + radius * 0.5, cy),
      Offset(cx + radius * 0.2, cy - radius * 0.5),
      processes[1][0],
      Colors.red,
    );

    // Additional processes
    // Igneous can directly become metamorphic
    // Sedimentary can melt to magma
    // etc.
  }

  void _drawProcessArrow(Canvas canvas, Offset start, Offset end, String label, Color color) {
    final arrowPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Curved arrow
    final controlX = (start.dx + end.dx) / 2;
    final controlY = (start.dy + end.dy) / 2 - 20;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(controlX, controlY, end.dx, end.dy);

    canvas.drawPath(path, arrowPaint);

    // Arrow head
    final angle = math.atan2(end.dy - controlY, end.dx - controlX);
    canvas.drawLine(
      end,
      Offset(end.dx - 10 * math.cos(angle - 0.5), end.dy - 10 * math.sin(angle - 0.5)),
      arrowPaint..strokeWidth = 2,
    );
    canvas.drawLine(
      end,
      Offset(end.dx - 10 * math.cos(angle + 0.5), end.dy - 10 * math.sin(angle + 0.5)),
      arrowPaint,
    );

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: color, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(controlX - textPainter.width / 2, controlY - 15));
  }

  void _drawAnimatedParticles(Canvas canvas, double cx, double cy, Size size) {
    final radius = math.min(size.width, size.height) * 0.35;

    // Particles moving along the cycle
    for (int i = 0; i < 6; i++) {
      final progress = (time * 0.3 + i * 0.166) % 1.0;
      final angle = progress * 2 * math.pi - math.pi / 2;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = Colors.white.withValues(alpha: 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RockCyclePainter oldDelegate) {
    return time != oldDelegate.time ||
        selectedRockType != oldDelegate.selectedRockType ||
        showProcesses != oldDelegate.showProcesses;
  }
}
