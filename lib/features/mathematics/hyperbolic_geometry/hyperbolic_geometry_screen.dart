import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Hyperbolic Geometry Visualization (Poincare Disk Model)
/// 쌍곡 기하학 시각화 (푸앵카레 원판 모델)
class HyperbolicGeometryScreen extends StatefulWidget {
  const HyperbolicGeometryScreen({super.key});

  @override
  State<HyperbolicGeometryScreen> createState() => _HyperbolicGeometryScreenState();
}

class _HyperbolicGeometryScreenState extends State<HyperbolicGeometryScreen> {
  int tessellationP = 5; // p-gons
  int tessellationQ = 4; // q meeting at each vertex
  bool showGeodesics = true;
  bool showTiling = true;
  int tilingDepth = 3;
  bool isKorean = true;

  // For (p, q) to form hyperbolic tessellation: (p-2)(q-2) > 4
  bool get _isHyperbolic => (tessellationP - 2) * (tessellationQ - 2) > 4;

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      tessellationP = 5;
      tessellationQ = 4;
      tilingDepth = 3;
    });
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
              isKorean ? '비유클리드 기하학' : 'NON-EUCLIDEAN',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '쌍곡 기하학' : 'Hyperbolic Geometry',
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
          category: isKorean ? '비유클리드 기하학' : 'NON-EUCLIDEAN',
          title: isKorean ? '쌍곡 기하학' : 'Hyperbolic Geometry',
          formula: 'K = -1 (negative curvature)',
          formulaDescription: isKorean
              ? '쌍곡 평면에서 삼각형의 내각의 합은 180°보다 작습니다. 푸앵카레 원판은 무한한 쌍곡 평면을 원 안에 담습니다.'
              : 'In hyperbolic plane, triangle angles sum to less than 180°. The Poincare disk maps the infinite hyperbolic plane into a circle.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: HyperbolicGeometryPainter(
                tessellationP: tessellationP,
                tessellationQ: tessellationQ,
                showGeodesics: showGeodesics,
                showTiling: showTiling,
                tilingDepth: tilingDepth,
                isHyperbolic: _isHyperbolic,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tessellation info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isHyperbolic
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isHyperbolic ? Colors.green : Colors.orange,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _InfoItem(
                          label: 'p (${isKorean ? '다각형' : 'polygon'})',
                          value: '$tessellationP${isKorean ? '각형' : '-gon'}',
                        ),
                        _InfoItem(
                          label: 'q (${isKorean ? '꼭짓점' : 'vertex'})',
                          value: '$tessellationQ',
                        ),
                        _InfoItem(
                          label: isKorean ? '표기' : 'Notation',
                          value: '{$tessellationP, $tessellationQ}',
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isHyperbolic
                          ? (isKorean ? '쌍곡 타일링 (유효)' : 'Hyperbolic tiling (valid)')
                          : (isKorean ? '유클리드 또는 구면 (쌍곡 아님)' : 'Euclidean or spherical (not hyperbolic)'),
                      style: TextStyle(
                        color: _isHyperbolic ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '(p-2)(q-2) = ${(tessellationP - 2) * (tessellationQ - 2)} ${_isHyperbolic ? '> 4' : '≤ 4'}',
                      style: TextStyle(
                        color: _isHyperbolic ? Colors.green : Colors.orange,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Preset tilings
              PresetGroup(
                label: isKorean ? '유명한 타일링' : 'Famous Tilings',
                presets: [
                  PresetButton(
                    label: '{5,4}',
                    isSelected: tessellationP == 5 && tessellationQ == 4,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        tessellationP = 5;
                        tessellationQ = 4;
                      });
                    },
                  ),
                  PresetButton(
                    label: '{4,5}',
                    isSelected: tessellationP == 4 && tessellationQ == 5,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        tessellationP = 4;
                        tessellationQ = 5;
                      });
                    },
                  ),
                  PresetButton(
                    label: '{7,3}',
                    isSelected: tessellationP == 7 && tessellationQ == 3,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        tessellationP = 7;
                        tessellationQ = 3;
                      });
                    },
                  ),
                  PresetButton(
                    label: '{3,7}',
                    isSelected: tessellationP == 3 && tessellationQ == 7,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        tessellationP = 3;
                        tessellationQ = 7;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: 'p (${isKorean ? '다각형 변의 수' : 'polygon sides'})',
                  value: tessellationP.toDouble(),
                  min: 3,
                  max: 12,
                  defaultValue: 5,
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) => setState(() => tessellationP = v.toInt()),
                ),
                advancedControls: [
                  SimSlider(
                    label: 'q (${isKorean ? '꼭짓점에서 만나는 수' : 'polygons at vertex'})',
                    value: tessellationQ.toDouble(),
                    min: 3,
                    max: 12,
                    defaultValue: 4,
                    formatValue: (v) => '${v.toInt()}',
                    onChanged: (v) => setState(() => tessellationQ = v.toInt()),
                  ),
                  SimSlider(
                    label: isKorean ? '타일링 깊이' : 'Tiling Depth',
                    value: tilingDepth.toDouble(),
                    min: 1,
                    max: 5,
                    defaultValue: 3,
                    formatValue: (v) => '${v.toInt()}',
                    onChanged: (v) => setState(() => tilingDepth = v.toInt()),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '타일링 표시' : 'Show Tiling',
                      value: showTiling,
                      onChanged: (v) => setState(() => showTiling = v),
                    ),
                  ),
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '측지선 표시' : 'Geodesics',
                      value: showGeodesics,
                      onChanged: (v) => setState(() => showGeodesics = v),
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
            style: TextStyle(
              color: color ?? AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class HyperbolicGeometryPainter extends CustomPainter {
  final int tessellationP;
  final int tessellationQ;
  final bool showGeodesics;
  final bool showTiling;
  final int tilingDepth;
  final bool isHyperbolic;

  HyperbolicGeometryPainter({
    required this.tessellationP,
    required this.tessellationQ,
    required this.showGeodesics,
    required this.showTiling,
    required this.tilingDepth,
    required this.isHyperbolic,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = math.min(size.width, size.height) / 2 - 20;

    // Draw Poincare disk boundary
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Fill disk background
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );

    if (!isHyperbolic) {
      _drawText(
        canvas,
        'Not hyperbolic',
        Offset(centerX, centerY),
        Colors.orange,
        fontSize: 16,
      );
      return;
    }

    // Draw hyperbolic tiling
    if (showTiling) {
      _drawHyperbolicTiling(canvas, centerX, centerY, radius);
    }

    // Draw some geodesics
    if (showGeodesics) {
      _drawGeodesics(canvas, centerX, centerY, radius);
    }

    // Label
    _drawText(
      canvas,
      'Poincare Disk',
      Offset(centerX, centerY + radius + 10),
      AppColors.muted,
      fontSize: 10,
    );
  }

  void _drawHyperbolicTiling(Canvas canvas, double cx, double cy, double radius) {
    // Simplified hyperbolic tiling using recursive approach
    // Draw central polygon and recurse
    final p = tessellationP;
    final q = tessellationQ;

    // Calculate the edge length and angles for {p,q} tiling
    final angleP = math.pi / p;
    final angleQ = math.pi / q;

    // For hyperbolic: cos(π/p)cos(π/q) < cos(π/2)
    // Edge length in hyperbolic space
    final coshEdge = math.cos(angleP) * math.cos(angleQ) / (math.sin(angleP) * math.sin(angleQ));
    if (coshEdge <= 1) return;

    // Radius of inscribed circle of central polygon (in Poincare disk)
    final r = 0.3 * radius; // Simplified

    // Draw central polygon
    _drawHyperbolicPolygon(canvas, cx, cy, radius, 0, 0, r, 0, 0);

    // Draw neighboring polygons recursively
    for (int i = 0; i < p; i++) {
      final angle = 2 * math.pi * i / p;
      _drawTilingRecursive(canvas, cx, cy, radius, r * 1.8, angle, 1);
    }
  }

  void _drawTilingRecursive(Canvas canvas, double cx, double cy, double radius,
      double dist, double angle, int depth) {
    if (depth > tilingDepth) return;
    if (dist > radius * 0.95) return;

    final x = cx + dist * math.cos(angle);
    final y = cy + dist * math.sin(angle);

    // Size decreases as we approach boundary (hyperbolic effect)
    final sizeFactor = 1 - dist / radius;
    final polyRadius = 0.15 * radius * sizeFactor;

    if (polyRadius < 3) return;

    _drawHyperbolicPolygon(canvas, cx, cy, radius, x - cx, y - cy, polyRadius, depth, angle);

    // Recurse to neighbors
    final p = tessellationP;
    for (int i = 0; i < p; i++) {
      final nextAngle = angle + 2 * math.pi * i / p + math.pi / p;
      final nextDist = dist + polyRadius * 1.5;
      _drawTilingRecursive(canvas, cx, cy, radius, nextDist, nextAngle, depth + 1);
    }
  }

  void _drawHyperbolicPolygon(Canvas canvas, double cx, double cy, double radius,
      double offsetX, double offsetY, double polyRadius, int depth, double baseAngle) {
    final p = tessellationP;
    final path = Path();

    // Generate polygon vertices
    for (int i = 0; i <= p; i++) {
      final angle = baseAngle + 2 * math.pi * i / p;
      final x = cx + offsetX + polyRadius * math.cos(angle);
      final y = cy + offsetY + polyRadius * math.sin(angle);

      // Clip to disk
      final dx = x - cx;
      final dy = y - cy;
      final d = math.sqrt(dx * dx + dy * dy);
      final clippedX = d > radius * 0.98 ? cx + dx * radius * 0.98 / d : x;
      final clippedY = d > radius * 0.98 ? cy + dy * radius * 0.98 / d : y;

      if (i == 0) {
        path.moveTo(clippedX, clippedY);
      } else {
        path.lineTo(clippedX, clippedY);
      }
    }
    path.close();

    // Color based on depth
    final hue = (depth * 60.0) % 360;
    final color = HSVColor.fromAHSV(0.6, hue, 0.5, 0.9).toColor();

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawGeodesics(Canvas canvas, double cx, double cy, double radius) {
    // Draw geodesics (arcs in Poincare disk)
    final geodesicPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Geodesics through center are straight lines
    for (int i = 0; i < 3; i++) {
      final angle = math.pi * i / 3;
      canvas.drawLine(
        Offset(cx + radius * 0.95 * math.cos(angle), cy + radius * 0.95 * math.sin(angle)),
        Offset(cx - radius * 0.95 * math.cos(angle), cy - radius * 0.95 * math.sin(angle)),
        geodesicPaint,
      );
    }

    // Non-diameter geodesics are circular arcs
    // Draw a few sample arcs
    for (int i = 0; i < 4; i++) {
      final startAngle = math.pi * i / 2;
      final arcCenterDist = radius * 1.5;
      final arcRadius = math.sqrt(arcCenterDist * arcCenterDist - radius * radius);

      final arcCx = cx + arcCenterDist * math.cos(startAngle);
      final arcCy = cy + arcCenterDist * math.sin(startAngle);

      // Draw arc that intersects disk orthogonally
      final path = Path();
      final sweepAngle = 2 * math.asin(radius / arcCenterDist);

      path.addArc(
        Rect.fromCircle(center: Offset(arcCx, arcCy), radius: arcRadius),
        startAngle + math.pi - sweepAngle / 2,
        sweepAngle,
      );

      canvas.drawPath(path, geodesicPaint);
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant HyperbolicGeometryPainter oldDelegate) =>
      tessellationP != oldDelegate.tessellationP ||
      tessellationQ != oldDelegate.tessellationQ ||
      showGeodesics != oldDelegate.showGeodesics ||
      showTiling != oldDelegate.showTiling ||
      tilingDepth != oldDelegate.tilingDepth;
}
