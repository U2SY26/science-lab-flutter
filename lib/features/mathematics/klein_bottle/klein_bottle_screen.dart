import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Klein Bottle Visualization
/// 클라인 병 시각화
class KleinBottleScreen extends StatefulWidget {
  const KleinBottleScreen({super.key});

  @override
  State<KleinBottleScreen> createState() => _KleinBottleScreenState();
}

class _KleinBottleScreenState extends State<KleinBottleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double rotationX = 0.3;
  double rotationY = 0.0;
  bool autoRotate = true;
  bool showWireframe = true;
  int segments = 30;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..addListener(() {
        if (autoRotate) {
          setState(() {
            rotationY = _controller.value * 2 * math.pi;
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
              isKorean ? '클라인 병' : 'Klein Bottle',
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
          title: isKorean ? '클라인 병' : 'Klein Bottle',
          formula: 'Non-orientable, χ = 0',
          formulaDescription: isKorean
              ? '클라인 병은 안과 밖의 구분이 없는 비가향 곡면입니다. 3차원에서는 자기 교차 없이 표현할 수 없습니다.'
              : 'The Klein bottle is a non-orientable surface with no distinction between inside and outside. It cannot be embedded in 3D without self-intersection.',
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
                painter: KleinBottlePainter(
                  rotationX: rotationX,
                  rotationY: rotationY,
                  segments: segments,
                  showWireframe: showWireframe,
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        _InfoItem(
                          label: isKorean ? '면의 수' : 'Sides',
                          value: '1',
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: isKorean ? '변의 수' : 'Edges',
                          value: '0',
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: isKorean ? '오일러 특성' : 'Euler Char.',
                          value: 'χ = 0',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isKorean
                          ? '클라인 병 = 뫼비우스 띠 2개를 변을 따라 붙인 것'
                          : 'Klein bottle = 2 Mobius strips glued along edges',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Key properties
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKorean ? '주요 특성' : 'Key Properties',
                      style: const TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _PropertyItem(text: isKorean ? '비가향 (Non-orientable)' : 'Non-orientable'),
                    _PropertyItem(text: isKorean ? '닫힌 곡면 (경계 없음)' : 'Closed surface (no boundary)'),
                    _PropertyItem(text: isKorean ? '4차원에서만 자기교차 없이 존재' : 'Exists without self-intersection only in 4D'),
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
              const SizedBox(height: 16),

              // Manual rotation
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

  const _InfoItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          Text(
            value,
            style: TextStyle(color: color ?? AppColors.ink, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PropertyItem extends StatelessWidget {
  final String text;

  const _PropertyItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.purple, size: 14),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: AppColors.ink, fontSize: 11)),
        ],
      ),
    );
  }
}

class KleinBottlePainter extends CustomPainter {
  final double rotationX;
  final double rotationY;
  final int segments;
  final bool showWireframe;

  KleinBottlePainter({
    required this.rotationX,
    required this.rotationY,
    required this.segments,
    required this.showWireframe,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = math.min(size.width, size.height) / 6;

    // Generate Klein bottle vertices using "figure-8" immersion
    final vertices = <List<_Point3D>>[];
    final uSteps = segments;
    final vSteps = segments ~/ 2;

    for (int i = 0; i <= uSteps; i++) {
      final u = 2 * math.pi * i / uSteps;
      final row = <_Point3D>[];

      for (int j = 0; j <= vSteps; j++) {
        final v = 2 * math.pi * j / vSteps;

        // Klein bottle parametric equations (figure-8 immersion)
        final r = 4 * (1 - math.cos(u) / 2);
        double x, y, z;

        if (u < math.pi) {
          x = 6 * math.cos(u) * (1 + math.sin(u)) + r * math.cos(u) * math.cos(v);
          y = 16 * math.sin(u) + r * math.sin(u) * math.cos(v);
        } else {
          x = 6 * math.cos(u) * (1 + math.sin(u)) + r * math.cos(v + math.pi);
          y = 16 * math.sin(u);
        }
        z = r * math.sin(v);

        // Scale down
        x /= 20;
        y /= 20;
        z /= 20;

        row.add(_Point3D(x, y, z));
      }
      vertices.add(row);
    }

    // Apply rotation and project
    List<List<Offset>> projected = [];
    List<List<double>> depths = [];

    for (final row in vertices) {
      final projRow = <Offset>[];
      final depthRow = <double>[];
      for (final v in row) {
        final rotated = _rotate(v, rotationX, rotationY);
        projRow.add(Offset(
          centerX + rotated.x * scale,
          centerY - rotated.y * scale,
        ));
        depthRow.add(rotated.z);
      }
      projected.add(projRow);
      depths.add(depthRow);
    }

    // Collect faces with depth for sorting
    final faces = <_Face>[];
    for (int i = 0; i < uSteps; i++) {
      for (int j = 0; j < vSteps; j++) {
        final avgDepth = (depths[i][j] + depths[i][j + 1] + depths[i + 1][j + 1] + depths[i + 1][j]) / 4;
        faces.add(_Face(
          points: [projected[i][j], projected[i][j + 1], projected[i + 1][j + 1], projected[i + 1][j]],
          depth: avgDepth,
          u: i / uSteps,
        ));
      }
    }

    // Sort by depth (back to front)
    faces.sort((a, b) => a.depth.compareTo(b.depth));

    // Draw faces
    for (final face in faces) {
      final path = Path();
      path.moveTo(face.points[0].dx, face.points[0].dy);
      for (int i = 1; i < face.points.length; i++) {
        path.lineTo(face.points[i].dx, face.points[i].dy);
      }
      path.close();

      if (!showWireframe) {
        final hue = face.u * 270; // Color gradient
        final brightness = 0.4 + 0.6 * (face.depth + 1.5) / 3;
        final color = HSVColor.fromAHSV(0.8, hue, 0.7, brightness.clamp(0.3, 1.0)).toColor();
        canvas.drawPath(path, Paint()..color = color);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = showWireframe
              ? AppColors.accent.withValues(alpha: 0.6)
              : Colors.black.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = showWireframe ? 0.8 : 0.3,
      );
    }
  }

  _Point3D _rotate(_Point3D p, double rx, double ry) {
    // Rotate around X
    var y1 = p.y * math.cos(rx) - p.z * math.sin(rx);
    var z1 = p.y * math.sin(rx) + p.z * math.cos(rx);
    var x1 = p.x;

    // Rotate around Y
    var x2 = x1 * math.cos(ry) + z1 * math.sin(ry);
    var z2 = -x1 * math.sin(ry) + z1 * math.cos(ry);

    return _Point3D(x2, y1, z2);
  }

  @override
  bool shouldRepaint(covariant KleinBottlePainter oldDelegate) =>
      rotationX != oldDelegate.rotationX ||
      rotationY != oldDelegate.rotationY ||
      showWireframe != oldDelegate.showWireframe;
}

class _Point3D {
  final double x, y, z;
  _Point3D(this.x, this.y, this.z);
}

class _Face {
  final List<Offset> points;
  final double depth;
  final double u;

  _Face({required this.points, required this.depth, required this.u});
}
