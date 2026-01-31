import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 중력장 시뮬레이션
class GravityFieldScreen extends StatefulWidget {
  const GravityFieldScreen({super.key});

  @override
  State<GravityFieldScreen> createState() => _GravityFieldScreenState();
}

class _GravityFieldScreenState extends State<GravityFieldScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  List<_MassObject> _masses = [];
  String _visualization = 'field';
  bool _showVectors = true;
  bool _showEquipotential = false;
  double _testMass = 1.0;
  Offset? _testPosition;

  static const double G = 6.674e-11;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // 기본 질량 배치
    _masses = [
      _MassObject(position: const Offset(0.3, 0.5), mass: 5e12, color: Colors.orange),
      _MassObject(position: const Offset(0.7, 0.5), mass: 3e12, color: Colors.blue),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addMass(Offset position) {
    if (_masses.length < 5) {
      HapticFeedback.mediumImpact();
      setState(() {
        _masses.add(_MassObject(
          position: position,
          mass: 2e12 + math.Random().nextDouble() * 3e12,
          color: [Colors.red, Colors.green, Colors.purple, Colors.teal][_masses.length % 4],
        ));
      });
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _masses = [
        _MassObject(position: const Offset(0.3, 0.5), mass: 5e12, color: Colors.orange),
        _MassObject(position: const Offset(0.7, 0.5), mass: 3e12, color: Colors.blue),
      ];
      _testPosition = null;
    });
  }

  Offset _calculateFieldAt(Offset point, Size size) {
    double fx = 0, fy = 0;

    for (var mass in _masses) {
      final massPos = Offset(mass.position.dx * size.width, mass.position.dy * size.height);
      final dx = massPos.dx - point.dx;
      final dy = massPos.dy - point.dy;
      final r = math.sqrt(dx * dx + dy * dy);

      if (r > 10) {
        final fieldMagnitude = G * mass.mass / (r * r);
        fx += fieldMagnitude * dx / r;
        fy += fieldMagnitude * dy / r;
      }
    }

    return Offset(fx, fy);
  }

  double _calculatePotentialAt(Offset point, Size size) {
    double potential = 0;

    for (var mass in _masses) {
      final massPos = Offset(mass.position.dx * size.width, mass.position.dy * size.height);
      final dx = massPos.dx - point.dx;
      final dy = massPos.dy - point.dy;
      final r = math.sqrt(dx * dx + dy * dy);

      if (r > 10) {
        potential -= G * mass.mass / r;
      }
    }

    return potential;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '물리학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '중력장',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '중력장 시뮬레이션',
          formula: 'g = GM/r²',
          formulaDescription: '질량이 주변 공간에 만드는 중력장을 시각화',
          simulation: SizedBox(
            height: 300,
            child: GestureDetector(
              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final size = box.size;
                final normalized = Offset(
                  localPosition.dx / size.width,
                  (localPosition.dy - 100) / 300,
                );
                if (normalized.dy >= 0 && normalized.dy <= 1) {
                  if (_visualization == 'test') {
                    setState(() => _testPosition = normalized);
                  } else {
                    _addMass(normalized);
                  }
                }
              },
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _GravityFieldPainter(
                      masses: _masses,
                      visualization: _visualization,
                      showVectors: _showVectors,
                      showEquipotential: _showEquipotential,
                      testPosition: _testPosition,
                      testMass: _testMass,
                      animation: _controller.value,
                      calculateFieldAt: _calculateFieldAt,
                      calculatePotentialAt: _calculatePotentialAt,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 정보
              Container(
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
                      '질량 수: ${_masses.length}/5',
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '화면을 탭하여 질량 추가\n중력장은 질량에서 멀어질수록 약해집니다',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 시각화 모드
              PresetGroup(
                label: '시각화',
                presets: [
                  PresetButton(
                    label: '벡터장',
                    isSelected: _visualization == 'field',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _visualization = 'field');
                    },
                  ),
                  PresetButton(
                    label: '등전위선',
                    isSelected: _visualization == 'potential',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _visualization = 'potential');
                    },
                  ),
                  PresetButton(
                    label: '테스트 질량',
                    isSelected: _visualization == 'test',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _visualization = 'test');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 옵션
              Row(
                children: [
                  Expanded(
                    child: _OptionChip(
                      label: '벡터 표시',
                      isSelected: _showVectors,
                      onTap: () => setState(() => _showVectors = !_showVectors),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OptionChip(
                      label: '등전위선',
                      isSelected: _showEquipotential,
                      onTap: () => setState(() => _showEquipotential = !_showEquipotential),
                    ),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '리셋',
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

class _MassObject {
  final Offset position;
  final double mass;
  final Color color;

  _MassObject({required this.position, required this.mass, required this.color});
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : AppColors.simBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.accent : AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: isSelected ? AppColors.accent : AppColors.muted, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _GravityFieldPainter extends CustomPainter {
  final List<_MassObject> masses;
  final String visualization;
  final bool showVectors;
  final bool showEquipotential;
  final Offset? testPosition;
  final double testMass;
  final double animation;
  final Offset Function(Offset, Size) calculateFieldAt;
  final double Function(Offset, Size) calculatePotentialAt;

  _GravityFieldPainter({
    required this.masses,
    required this.visualization,
    required this.showVectors,
    required this.showEquipotential,
    required this.testPosition,
    required this.testMass,
    required this.animation,
    required this.calculateFieldAt,
    required this.calculatePotentialAt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0a0a1a));

    // 등전위선 또는 필드 강도 색상맵
    if (visualization == 'potential' || showEquipotential) {
      _drawPotentialField(canvas, size);
    }

    // 벡터장
    if (showVectors || visualization == 'field') {
      _drawVectorField(canvas, size);
    }

    // 질량 객체
    for (var mass in masses) {
      final pos = Offset(mass.position.dx * size.width, mass.position.dy * size.height);
      final radius = 8 + (mass.mass / 1e12) * 3;

      // 글로우 효과
      for (int i = 3; i > 0; i--) {
        canvas.drawCircle(
          pos,
          radius + i * 5,
          Paint()..color = mass.color.withValues(alpha: 0.1),
        );
      }

      canvas.drawCircle(pos, radius, Paint()..color = mass.color);
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // 테스트 질량
    if (visualization == 'test' && testPosition != null) {
      final testPos = Offset(testPosition!.dx * size.width, testPosition!.dy * size.height);
      final field = calculateFieldAt(testPos, size);
      final fieldMagnitude = math.sqrt(field.dx * field.dx + field.dy * field.dy);

      // 테스트 질량
      canvas.drawCircle(testPos, 6, Paint()..color = Colors.white);

      // 힘 벡터
      if (fieldMagnitude > 0) {
        final scale = 5000;
        final endPoint = Offset(
          testPos.dx + field.dx * scale,
          testPos.dy + field.dy * scale,
        );

        canvas.drawLine(
          testPos,
          endPoint,
          Paint()
            ..color = Colors.yellow
            ..strokeWidth = 3,
        );

        // 화살표
        final angle = math.atan2(field.dy, field.dx);
        final arrowSize = 10.0;
        final arrowPath = Path()
          ..moveTo(endPoint.dx, endPoint.dy)
          ..lineTo(
            endPoint.dx - arrowSize * math.cos(angle - 0.4),
            endPoint.dy - arrowSize * math.sin(angle - 0.4),
          )
          ..lineTo(
            endPoint.dx - arrowSize * math.cos(angle + 0.4),
            endPoint.dy - arrowSize * math.sin(angle + 0.4),
          )
          ..close();

        canvas.drawPath(arrowPath, Paint()..color = Colors.yellow);
      }

      // 힘 정보
      _drawText(
        canvas,
        'F = ${(fieldMagnitude * testMass * 1e15).toStringAsFixed(2)} N',
        Offset(10, size.height - 25),
        Colors.yellow,
      );
    }
  }

  void _drawVectorField(Canvas canvas, Size size) {
    final gridSize = 20;
    final stepX = size.width / gridSize;
    final stepY = size.height / gridSize;

    for (int i = 1; i < gridSize; i++) {
      for (int j = 1; j < gridSize; j++) {
        final point = Offset(i * stepX, j * stepY);
        final field = calculateFieldAt(point, size);
        final magnitude = math.sqrt(field.dx * field.dx + field.dy * field.dy);

        if (magnitude > 1e-15) {
          final normalizedLength = math.min(magnitude * 1e12, 15.0);
          final angle = math.atan2(field.dy, field.dx);

          final endPoint = Offset(
            point.dx + normalizedLength * math.cos(angle),
            point.dy + normalizedLength * math.sin(angle),
          );

          final color = Color.lerp(
            Colors.blue.withValues(alpha: 0.3),
            Colors.red.withValues(alpha: 0.8),
            (magnitude * 1e13).clamp(0, 1),
          )!;

          canvas.drawLine(
            point,
            endPoint,
            Paint()
              ..color = color
              ..strokeWidth = 1.5,
          );
        }
      }
    }
  }

  void _drawPotentialField(Canvas canvas, Size size) {
    final resolution = 40;
    final cellWidth = size.width / resolution;
    final cellHeight = size.height / resolution;

    for (int i = 0; i < resolution; i++) {
      for (int j = 0; j < resolution; j++) {
        final point = Offset((i + 0.5) * cellWidth, (j + 0.5) * cellHeight);
        final potential = calculatePotentialAt(point, size);

        final normalizedPotential = (-potential * 1e10).clamp(0.0, 1.0);
        final color = Color.lerp(
          const Color(0xFF0a0a2a),
          Colors.purple.withValues(alpha: 0.5),
          normalizedPotential,
        )!;

        canvas.drawRect(
          Rect.fromLTWH(i * cellWidth, j * cellHeight, cellWidth, cellHeight),
          Paint()..color = color,
        );
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _GravityFieldPainter oldDelegate) => true;
}
