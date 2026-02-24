import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Henon Attractor Simulation
class HenonAttractorScreen extends ConsumerStatefulWidget {
  const HenonAttractorScreen({super.key});

  @override
  ConsumerState<HenonAttractorScreen> createState() => _HenonAttractorScreenState();
}

class _HenonAttractorScreenState extends ConsumerState<HenonAttractorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Henon map parameters
  double _a = 1.4;
  double _b = 0.3;

  // State
  double _x = 0.1;
  double _y = 0.1;
  bool _isRunning = true;

  // Points for visualization
  final List<Offset> _points = [];
  static const int _maxPoints = 10000;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateMap);
    _controller.repeat();
  }

  void _updateMap() {
    if (!_isRunning) return;

    setState(() {
      // Generate multiple points per frame for faster visualization
      for (int i = 0; i < 50; i++) {
        // Henon map equations:
        // x_{n+1} = 1 - a*x_n^2 + y_n
        // y_{n+1} = b*x_n
        final xNew = 1 - _a * _x * _x + _y;
        final yNew = _b * _x;

        _x = xNew;
        _y = yNew;

        // Check for divergence
        if (_x.abs() > 10 || _y.abs() > 10 || _x.isNaN || _y.isNaN) {
          _x = 0.1;
          _y = 0.1;
          continue;
        }

        _points.add(Offset(_x, _y));
      }

      // Limit points
      while (_points.length > _maxPoints) {
        _points.removeAt(0);
      }
    });
  }

  void _toggleRunning() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _x = 0.1;
      _y = 0.1;
      _points.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);

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
              isKorean ? '혼돈 이론' : 'CHAOS THEORY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '에농 어트랙터' : 'Henon Attractor',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '혼돈 이론' : 'Chaos Theory',
          title: isKorean ? '에농 어트랙터' : 'Henon Attractor',
          formula: 'xn+1 = 1 - a*xn^2 + yn, yn+1 = b*xn',
          formulaDescription: isKorean
              ? 'Michel Henon이 발견한 이산 시간 동역학계. 단순한 방정식에서 복잡한 카오스 구조가 나타납니다.'
              : 'A discrete-time dynamical system discovered by Michel Henon. Complex chaotic structure emerges from simple equations.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _HenonAttractorPainter(
                points: _points,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoItem(
                      label: 'x',
                      value: _x.toStringAsFixed(4),
                      color: AppColors.accent,
                    ),
                    _InfoItem(
                      label: 'y',
                      value: _y.toStringAsFixed(4),
                      color: AppColors.accent2,
                    ),
                    _InfoItem(
                      label: isKorean ? '점 개수' : 'Points',
                      value: '${_points.length}',
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Presets
              PresetGroup(
                label: isKorean ? '프리셋' : 'Presets',
                presets: [
                  PresetButton(
                    label: isKorean ? '클래식' : 'Classic',
                    isSelected: _a == 1.4 && _b == 0.3,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _a = 1.4;
                        _b = 0.3;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '변형 1' : 'Variant 1',
                    isSelected: _a == 1.2 && _b == 0.4,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _a = 1.2;
                        _b = 0.4;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '변형 2' : 'Variant 2',
                    isSelected: _a == 1.05 && _b == 0.3,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _a = 1.05;
                        _b = 0.3;
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: 'a',
                  value: _a,
                  min: 0.5,
                  max: 1.5,
                  defaultValue: 1.4,
                  formatValue: (v) => v.toStringAsFixed(3),
                  onChanged: (v) {
                    setState(() {
                      _a = v;
                      _reset();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: 'b',
                    value: _b,
                    min: 0.0,
                    max: 0.5,
                    defaultValue: 0.3,
                    formatValue: (v) => v.toStringAsFixed(3),
                    onChanged: (v) {
                      setState(() {
                        _b = v;
                        _reset();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning
                    ? (isKorean ? '일시정지' : 'Pause')
                    : (isKorean ? '시작' : 'Start'),
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleRunning,
              ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
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

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _HenonAttractorPainter extends CustomPainter {
  final List<Offset> points;
  final bool isKorean;

  _HenonAttractorPainter({
    required this.points,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (points.isEmpty) return;

    // Find bounds
    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }

    // Add padding
    final rangeX = (maxX - minX) * 1.1;
    final rangeY = (maxY - minY) * 1.1;
    final centerX = (maxX + minX) / 2;
    final centerY = (maxY + minY) / 2;

    // Scale to fit
    final scale = math.min(size.width / rangeX, size.height / rangeY) * 0.9;

    // Draw grid
    _drawGrid(canvas, size);

    // Draw points with color gradient based on iteration
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final t = i / points.length;

      final x = size.width / 2 + (p.dx - centerX) * scale;
      final y = size.height / 2 - (p.dy - centerY) * scale;

      final color = Color.lerp(
        AppColors.accent.withValues(alpha: 0.3),
        AppColors.accent2,
        t,
      )!;

      canvas.drawCircle(
        Offset(x, y),
        1.0 + t * 0.5,
        Paint()..color = color,
      );
    }

    // Title
    _drawText(canvas, isKorean ? '에농 어트랙터' : 'Henon Attractor',
        const Offset(10, 10), AppColors.accent, 12, fontWeight: FontWeight.bold);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize,
      {FontWeight fontWeight = FontWeight.normal}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _HenonAttractorPainter oldDelegate) => true;
}
