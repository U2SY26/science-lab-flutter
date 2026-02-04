import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Julia Set Visualization
/// 줄리아 집합 시각화
class JuliaSetScreen extends StatefulWidget {
  const JuliaSetScreen({super.key});

  @override
  State<JuliaSetScreen> createState() => _JuliaSetScreenState();
}

class _JuliaSetScreenState extends State<JuliaSetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Julia set parameter c = cReal + cImag * i
  double cReal = -0.7;
  double cImag = 0.27015;
  int maxIterations = 100;
  double zoom = 1.0;
  double offsetX = 0.0;
  double offsetY = 0.0;
  int colorScheme = 0;
  bool animateC = false;
  bool isKorean = true;

  final List<(double, double, String)> _presets = [
    (-0.7, 0.27015, 'Classic'),
    (-0.8, 0.156, 'Spiral'),
    (0.285, 0.01, 'Dendrite'),
    (-0.4, 0.6, 'Rabbit'),
    (0.355, 0.355, 'Siegel'),
    (-0.54, 0.54, 'Dragon'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        if (animateC) {
          setState(() {
            final t = _controller.value * 2 * math.pi;
            cReal = 0.7885 * math.cos(t);
            cImag = 0.7885 * math.sin(t);
          });
        }
      });
  }

  void _toggleAnimation() {
    HapticFeedback.selectionClick();
    setState(() {
      animateC = !animateC;
      if (animateC) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _applyPreset(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      cReal = _presets[index].$1;
      cImag = _presets[index].$2;
      zoom = 1.0;
      offsetX = 0;
      offsetY = 0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      cReal = -0.7;
      cImag = 0.27015;
      zoom = 1.0;
      offsetX = 0;
      offsetY = 0;
      animateC = false;
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
              isKorean ? '프랙탈' : 'FRACTALS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '줄리아 집합' : 'Julia Set',
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
          category: isKorean ? '프랙탈' : 'FRACTALS',
          title: isKorean ? '줄리아 집합' : 'Julia Set',
          formula: 'zₙ₊₁ = zₙ² + c',
          formulaDescription: isKorean
              ? '줄리아 집합은 복소수 c에 대해 반복 함수 f(z) = z² + c가 발산하지 않는 점들의 집합입니다.'
              : 'The Julia set is the set of points z where the iteration f(z) = z² + c does not diverge.',
          simulation: SizedBox(
            height: 300,
            child: GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  zoom *= details.scale;
                  zoom = zoom.clamp(0.5, 10.0);
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  offsetX -= details.delta.dx / 100 / zoom;
                  offsetY += details.delta.dy / 100 / zoom;
                });
              },
              child: CustomPaint(
                painter: JuliaSetPainter(
                  cReal: cReal,
                  cImag: cImag,
                  maxIterations: maxIterations,
                  zoom: zoom,
                  offsetX: offsetX,
                  offsetY: offsetY,
                  colorScheme: colorScheme,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Parameter display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      'c = ${cReal.toStringAsFixed(4)} ${cImag >= 0 ? '+' : '-'} ${cImag.abs().toStringAsFixed(4)}i',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoItem(label: isKorean ? '확대' : 'Zoom', value: '${zoom.toStringAsFixed(1)}x'),
                        _InfoItem(label: isKorean ? '반복' : 'Iterations', value: '$maxIterations'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Presets
              PresetGroup(
                label: isKorean ? '유명한 줄리아 집합' : 'Famous Julia Sets',
                presets: List.generate(_presets.length, (i) {
                  return PresetButton(
                    label: _presets[i].$3,
                    isSelected: (cReal - _presets[i].$1).abs() < 0.01 &&
                        (cImag - _presets[i].$2).abs() < 0.01,
                    onPressed: () => _applyPreset(i),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Color scheme
              PresetGroup(
                label: isKorean ? '색상 구성' : 'Color Scheme',
                presets: [
                  PresetButton(
                    label: isKorean ? '무지개' : 'Rainbow',
                    isSelected: colorScheme == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => colorScheme = 0);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '파랑' : 'Blue',
                    isSelected: colorScheme == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => colorScheme = 1);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '불꽃' : 'Fire',
                    isSelected: colorScheme == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => colorScheme = 2);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Parameter controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: 'c (${isKorean ? '실수부' : 'real'})',
                  value: cReal,
                  min: -1.5,
                  max: 1.5,
                  defaultValue: -0.7,
                  formatValue: (v) => v.toStringAsFixed(3),
                  onChanged: (v) {
                    if (!animateC) setState(() => cReal = v);
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: 'c (${isKorean ? '허수부' : 'imag'})',
                    value: cImag,
                    min: -1.5,
                    max: 1.5,
                    defaultValue: 0.27015,
                    formatValue: (v) => v.toStringAsFixed(3),
                    onChanged: (v) {
                      if (!animateC) setState(() => cImag = v);
                    },
                  ),
                  SimSlider(
                    label: isKorean ? '최대 반복 횟수' : 'Max Iterations',
                    value: maxIterations.toDouble(),
                    min: 20,
                    max: 200,
                    defaultValue: 100,
                    formatValue: (v) => '${v.toInt()}',
                    onChanged: (v) => setState(() => maxIterations = v.toInt()),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: animateC
                    ? (isKorean ? '정지' : 'Stop')
                    : (isKorean ? '애니메이션' : 'Animate'),
                icon: animateC ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleAnimation,
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

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class JuliaSetPainter extends CustomPainter {
  final double cReal;
  final double cImag;
  final int maxIterations;
  final double zoom;
  final double offsetX;
  final double offsetY;
  final int colorScheme;

  JuliaSetPainter({
    required this.cReal,
    required this.cImag,
    required this.maxIterations,
    required this.zoom,
    required this.offsetX,
    required this.offsetY,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.toInt();
    final height = size.height.toInt();

    // Use lower resolution for performance
    final scale = 2;
    final renderWidth = width ~/ scale;
    final renderHeight = height ~/ scale;

    for (int py = 0; py < renderHeight; py++) {
      for (int px = 0; px < renderWidth; px++) {
        // Map pixel to complex plane
        final x0 = (px - renderWidth / 2) / (renderWidth / 4) / zoom + offsetX;
        final y0 = (py - renderHeight / 2) / (renderHeight / 4) / zoom + offsetY;

        var x = x0;
        var y = y0;
        int iteration = 0;

        // Julia set iteration
        while (x * x + y * y <= 4 && iteration < maxIterations) {
          final xTemp = x * x - y * y + cReal;
          y = 2 * x * y + cImag;
          x = xTemp;
          iteration++;
        }

        // Color based on iteration count
        Color color;
        if (iteration == maxIterations) {
          color = Colors.black;
        } else {
          color = _getColor(iteration, maxIterations);
        }

        // Draw scaled rectangle
        canvas.drawRect(
          Rect.fromLTWH(
            px * scale.toDouble(),
            py * scale.toDouble(),
            scale.toDouble(),
            scale.toDouble(),
          ),
          Paint()..color = color,
        );
      }
    }
  }

  Color _getColor(int iteration, int maxIter) {
    final t = iteration / maxIter;

    switch (colorScheme) {
      case 1: // Blue
        return Color.lerp(Colors.black, Colors.blue, t) ??
            Color.lerp(Colors.blue, Colors.white, (t - 0.5) * 2) ??
            Colors.white;

      case 2: // Fire
        if (t < 0.33) {
          return Color.lerp(Colors.black, Colors.red, t * 3)!;
        } else if (t < 0.66) {
          return Color.lerp(Colors.red, Colors.orange, (t - 0.33) * 3)!;
        } else {
          return Color.lerp(Colors.orange, Colors.yellow, (t - 0.66) * 3)!;
        }

      default: // Rainbow
        final hue = (t * 360) % 360;
        return HSVColor.fromAHSV(1, hue, 0.8, 0.9).toColor();
    }
  }

  @override
  bool shouldRepaint(covariant JuliaSetPainter oldDelegate) =>
      cReal != oldDelegate.cReal ||
      cImag != oldDelegate.cImag ||
      maxIterations != oldDelegate.maxIterations ||
      zoom != oldDelegate.zoom ||
      offsetX != oldDelegate.offsetX ||
      offsetY != oldDelegate.offsetY ||
      colorScheme != oldDelegate.colorScheme;
}
