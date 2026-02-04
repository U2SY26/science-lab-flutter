import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Mobius Strip Visualization
/// 뫼비우스 띠 시각화
class MobiusStripScreen extends StatefulWidget {
  const MobiusStripScreen({super.key});

  @override
  State<MobiusStripScreen> createState() => _MobiusStripScreenState();
}

class _MobiusStripScreenState extends State<MobiusStripScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double rotationX = 0.3;
  double rotationY = 0.0;
  double rotationZ = 0.0;
  int segments = 50;
  bool showWireframe = false;
  bool autoRotate = true;
  bool showPath = true;
  double pathPosition = 0.0;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        if (autoRotate) {
          setState(() {
            rotationY = _controller.value * 2 * math.pi;
            pathPosition = (_controller.value * 2) % 1.0;
          });
        }
      });
    _controller.repeat();
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      rotationX = 0.3;
      rotationY = 0.0;
      rotationZ = 0.0;
      segments = 50;
      pathPosition = 0.0;
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
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isKorean ? '위상수학' : 'TOPOLOGY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '뫼비우스 띠' : 'Mobius Strip',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => isKorean = !isKorean),
            tooltip: isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '위상수학' : 'TOPOLOGY',
          title: isKorean ? '뫼비우스 띠' : 'Mobius Strip',
          formula: 'x = (R + s·cos(t/2))cos(t)',
          formulaDescription: isKorean
              ? '뫼비우스 띠는 한 면과 한 변만 가진 비가향 곡면입니다. 한 바퀴 돌면 반대쪽 면에 도착합니다.'
              : 'The Mobius strip is a non-orientable surface with only one side and one edge. One trip around returns you to the opposite side.',
          simulation: SizedBox(
            height: 300,
            child: GestureDetector(
              onPanUpdate: (details) {
                if (!autoRotate) {
                  setState(() {
                    rotationY += details.delta.dx * 0.01;
                    rotationX += details.delta.dy * 0.01;
                  });
                }
              },
              child: CustomPaint(
                painter: MobiusStripPainter(
                  rotationX: rotationX,
                  rotationY: rotationY,
                  rotationZ: rotationZ,
                  segments: segments,
                  showWireframe: showWireframe,
                  showPath: showPath,
                  pathPosition: pathPosition,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _InfoItem(
                      label: isKorean ? '면의 수' : 'Sides',
                      value: '1',
                      color: AppColors.accent,
                    ),
                    _InfoItem(
                      label: isKorean ? '변의 수' : 'Edges',
                      value: '1',
                      color: AppColors.accent,
                    ),
                    _InfoItem(
                      label: isKorean ? '오일러 특성' : 'Euler Char.',
                      value: 'χ = 0',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Path position info
              if (showPath)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isKorean
                              ? '경로 위치: ${(pathPosition * 200).toStringAsFixed(0)}% (한 바퀴 = 200%)'
                              : 'Path position: ${(pathPosition * 200).toStringAsFixed(0)}% (one loop = 200%)',
                          style: const TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Toggles
              Row(
                children: [
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '자동 회전' : 'Auto Rotate',
                      value: autoRotate,
                      onChanged: (v) => setState(() => autoRotate = v),
                    ),
                  ),
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '와이어프레임' : 'Wireframe',
                      value: showWireframe,
                      onChanged: (v) => setState(() => showWireframe = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SimToggle(
                label: isKorean ? '경로 표시' : 'Show Path',
                value: showPath,
                onChanged: (v) => setState(() => showPath = v),
              ),
              const SizedBox(height: 16),

              // Manual controls
              if (!autoRotate)
                ControlGroup(
                  primaryControl: SimSlider(
                    label: isKorean ? 'Y축 회전' : 'Rotation Y',
                    value: rotationY,
                    min: 0,
                    max: 2 * math.pi,
                    defaultValue: 0,
                    formatValue: (v) => '${(v * 180 / math.pi).toStringAsFixed(0)}°',
                    onChanged: (v) => setState(() => rotationY = v),
                  ),
                  advancedControls: [
                    SimSlider(
                      label: isKorean ? 'X축 회전' : 'Rotation X',
                      value: rotationX,
                      min: -math.pi / 2,
                      max: math.pi / 2,
                      defaultValue: 0.3,
                      formatValue: (v) => '${(v * 180 / math.pi).toStringAsFixed(0)}°',
                      onChanged: (v) => setState(() => rotationX = v),
                    ),
                  ],
                ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                isPrimary: true,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class MobiusStripPainter extends CustomPainter {
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final int segments;
  final bool showWireframe;
  final bool showPath;
  final double pathPosition;

  MobiusStripPainter({
    required this.rotationX,
    required this.rotationY,
    required this.rotationZ,
    required this.segments,
    required this.showWireframe,
    required this.showPath,
    required this.pathPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = math.min(size.width, size.height) / 4;

    final R = 1.0; // Major radius
    final w = 0.4; // Half-width of strip

    // Generate Mobius strip vertices
    final vertices = <List<Offset3D>>[];
    final widthSteps = 5;

    for (int i = 0; i <= segments; i++) {
      final t = 2 * math.pi * i / segments;
      final row = <Offset3D>[];

      for (int j = 0; j <= widthSteps; j++) {
        final s = -w + 2 * w * j / widthSteps;

        // Parametric equations for Mobius strip
        final x = (R + s * math.cos(t / 2)) * math.cos(t);
        final y = (R + s * math.cos(t / 2)) * math.sin(t);
        final z = s * math.sin(t / 2);

        row.add(Offset3D(x, y, z));
      }
      vertices.add(row);
    }

    // Apply rotation and project to 2D
    List<List<Offset>> projected = [];
    List<List<double>> depths = [];

    for (final row in vertices) {
      final projRow = <Offset>[];
      final depthRow = <double>[];
      for (final v in row) {
        final rotated = _rotate(v, rotationX, rotationY, rotationZ);
        projRow.add(Offset(
          centerX + rotated.x * scale,
          centerY - rotated.y * scale,
        ));
        depthRow.add(rotated.z);
      }
      projected.add(projRow);
      depths.add(depthRow);
    }

    // Draw faces (back to front sorting would be ideal, but simplified here)
    for (int i = 0; i < segments; i++) {
      for (int j = 0; j < widthSteps; j++) {
        final p1 = projected[i][j];
        final p2 = projected[i][j + 1];
        final p3 = projected[i + 1][j + 1];
        final p4 = projected[i + 1][j];

        final avgDepth = (depths[i][j] + depths[i][j + 1] + depths[i + 1][j + 1] + depths[i + 1][j]) / 4;
        final brightness = 0.3 + 0.7 * (avgDepth + 1) / 2;

        final path = Path();
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(p2.dx, p2.dy);
        path.lineTo(p3.dx, p3.dy);
        path.lineTo(p4.dx, p4.dy);
        path.close();

        if (!showWireframe) {
          // Color based on position (shows the twist)
          final hue = (i / segments) * 180;
          final color = HSVColor.fromAHSV(1, hue, 0.6, brightness).toColor();
          canvas.drawPath(path, Paint()..color = color);
        }

        // Draw edges
        canvas.drawPath(
          path,
          Paint()
            ..color = showWireframe
                ? AppColors.accent.withValues(alpha: 0.8)
                : Colors.black.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = showWireframe ? 1 : 0.5,
        );
      }
    }

    // Draw path on surface
    if (showPath) {
      // The path needs to go around twice to return to start
      final totalT = pathPosition * 4 * math.pi; // 0 to 4π for full journey

      final pathPoints = <Offset>[];
      for (double t = 0; t <= totalT; t += 0.05) {
        final s = 0.0; // Center of strip
        final x = (R + s * math.cos(t / 2)) * math.cos(t);
        final y = (R + s * math.cos(t / 2)) * math.sin(t);
        final z = s * math.sin(t / 2);

        final rotated = _rotate(Offset3D(x, y, z), rotationX, rotationY, rotationZ);
        pathPoints.add(Offset(
          centerX + rotated.x * scale,
          centerY - rotated.y * scale,
        ));
      }

      if (pathPoints.length > 1) {
        final pathPath = Path();
        pathPath.moveTo(pathPoints[0].dx, pathPoints[0].dy);
        for (int i = 1; i < pathPoints.length; i++) {
          pathPath.lineTo(pathPoints[i].dx, pathPoints[i].dy);
        }
        canvas.drawPath(
          pathPath,
          Paint()
            ..color = Colors.orange
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );

        // Draw current position marker
        if (pathPoints.isNotEmpty) {
          canvas.drawCircle(pathPoints.last, 8, Paint()..color = Colors.orange);
          canvas.drawCircle(pathPoints.last, 4, Paint()..color = Colors.white);
        }
      }
    }
  }

  Offset3D _rotate(Offset3D p, double rx, double ry, double rz) {
    // Rotate around X
    var y1 = p.y * math.cos(rx) - p.z * math.sin(rx);
    var z1 = p.y * math.sin(rx) + p.z * math.cos(rx);
    var x1 = p.x;

    // Rotate around Y
    var x2 = x1 * math.cos(ry) + z1 * math.sin(ry);
    var z2 = -x1 * math.sin(ry) + z1 * math.cos(ry);
    var y2 = y1;

    // Rotate around Z
    var x3 = x2 * math.cos(rz) - y2 * math.sin(rz);
    var y3 = x2 * math.sin(rz) + y2 * math.cos(rz);
    var z3 = z2;

    return Offset3D(x3, y3, z3);
  }

  @override
  bool shouldRepaint(covariant MobiusStripPainter oldDelegate) =>
      rotationX != oldDelegate.rotationX ||
      rotationY != oldDelegate.rotationY ||
      showWireframe != oldDelegate.showWireframe ||
      showPath != oldDelegate.showPath ||
      pathPosition != oldDelegate.pathPosition;
}

class Offset3D {
  final double x, y, z;
  Offset3D(this.x, this.y, this.z);
}
