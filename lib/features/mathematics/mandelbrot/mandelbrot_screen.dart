import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 만델브로트 집합 시뮬레이션
class MandelbrotScreen extends StatefulWidget {
  const MandelbrotScreen({super.key});

  @override
  State<MandelbrotScreen> createState() => _MandelbrotScreenState();
}

class _MandelbrotScreenState extends State<MandelbrotScreen> {
  // 기본값
  static const double _defaultCenterX = -0.5;
  static const double _defaultCenterY = 0;
  static const double _defaultZoom = 1;
  static const int _defaultMaxIterations = 100;

  double centerX = _defaultCenterX;
  double centerY = _defaultCenterY;
  double zoom = _defaultZoom;
  int maxIterations = _defaultMaxIterations;
  bool _isRendering = false;

  // 프리셋
  String? _selectedPreset;

  // 컬러맵
  String _colorScheme = 'classic';

  @override
  void initState() {
    super.initState();
    _renderMandelbrot();
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;

      switch (preset) {
        case 'overview':
          centerX = -0.5;
          centerY = 0;
          zoom = 1;
          break;
        case 'seahorse':
          centerX = -0.745;
          centerY = 0.113;
          zoom = 50;
          break;
        case 'spiral':
          centerX = -0.761574;
          centerY = -0.0847596;
          zoom = 500;
          break;
        case 'mini':
          centerX = -1.749;
          centerY = 0.0;
          zoom = 100;
          break;
        case 'elephant':
          centerX = 0.275;
          centerY = 0.0;
          zoom = 20;
          break;
      }

      maxIterations = zoom > 100 ? 300 : 100;
    });
    _renderMandelbrot();
  }

  Future<void> _renderMandelbrot() async {
    if (_isRendering) return;
    setState(() => _isRendering = true);

    const width = 400;
    const height = 300;
    final pixels = Uint8List(width * height * 4);

    final scale = 3.0 / zoom;
    final xMin = centerX - scale;
    final xMax = centerX + scale;
    final yMin = centerY - scale * height / width;
    final yMax = centerY + scale * height / width;

    for (int py = 0; py < height; py++) {
      for (int px = 0; px < width; px++) {
        final x0 = xMin + (xMax - xMin) * px / width;
        final y0 = yMin + (yMax - yMin) * py / height;

        double x = 0;
        double y = 0;
        int iteration = 0;

        while (x * x + y * y <= 4 && iteration < maxIterations) {
          final xTemp = x * x - y * y + x0;
          y = 2 * x * y + y0;
          x = xTemp;
          iteration++;
        }

        final idx = (py * width + px) * 4;
        if (iteration == maxIterations) {
          pixels[idx] = 0;
          pixels[idx + 1] = 0;
          pixels[idx + 2] = 0;
          pixels[idx + 3] = 255;
        } else {
          final t = iteration / maxIterations;
          final color = _getColor(t);
          pixels[idx] = color.red;
          pixels[idx + 1] = color.green;
          pixels[idx + 2] = color.blue;
          pixels[idx + 3] = 255;
        }
      }
    }

    setState(() {
      _isRendering = false;
    });
  }

  Color _getColor(double t) {
    switch (_colorScheme) {
      case 'fire':
        return HSLColor.fromAHSL(1.0, t * 60, 1.0, 0.5).toColor();
      case 'ocean':
        return HSLColor.fromAHSL(1.0, 180 + t * 60, 0.8, 0.3 + t * 0.4).toColor();
      case 'rainbow':
        return HSLColor.fromAHSL(1.0, t * 360, 0.9, 0.5).toColor();
      case 'classic':
      default:
        return HSLColor.fromAHSL(1.0, (t * 360 + 200) % 360, 0.8, 0.5).toColor();
    }
  }

  void _zoomIn() {
    HapticFeedback.lightImpact();
    setState(() {
      zoom *= 1.5;
      _selectedPreset = null;
    });
    _renderMandelbrot();
  }

  void _zoomOut() {
    HapticFeedback.lightImpact();
    setState(() {
      zoom /= 1.5;
      _selectedPreset = null;
    });
    _renderMandelbrot();
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      centerX = _defaultCenterX;
      centerY = _defaultCenterY;
      zoom = _defaultZoom;
      maxIterations = _defaultMaxIterations;
      _selectedPreset = null;
    });
    _renderMandelbrot();
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
              '프랙탈',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              'Mandelbrot 집합',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '프랙탈',
          title: 'Mandelbrot 집합',
          formula: 'zₙ₊₁ = zₙ² + c',
          formulaDescription: '복소 평면에서 발산하지 않는 점들의 집합 - 무한한 자기유사성',
          simulation: GestureDetector(
            onTapDown: (details) {
              HapticFeedback.lightImpact();
              final RenderBox box = context.findRenderObject() as RenderBox;
              final size = box.size;
              final scale = 3.0 / zoom;
              final tapX = details.localPosition.dx / size.width;
              final tapY = details.localPosition.dy / 350;
              setState(() {
                centerX = centerX - scale + tapX * scale * 2;
                centerY = centerY - scale * 350 / size.width + tapY * scale * 2 * 350 / size.width;
                zoom *= 2;
                _selectedPreset = null;
              });
              _renderMandelbrot();
            },
            child: SizedBox(
              height: 350,
              child: Stack(
                children: [
                  CustomPaint(
                    painter: MandelbrotPainter(
                      centerX: centerX,
                      centerY: centerY,
                      zoom: zoom,
                      maxIterations: maxIterations,
                      colorScheme: _colorScheme,
                    ),
                    size: Size.infinite,
                  ),
                  if (_isRendering)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bg.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.accent),
                            SizedBox(height: 8),
                            Text(
                              '렌더링 중...',
                              style: TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // 좌표 오버레이
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bg.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '탭하여 확대',
                        style: TextStyle(
                          color: AppColors.muted.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 명소 프리셋
              PresetGroup(
                label: '유명 위치',
                presets: [
                  PresetButton(
                    label: '전체',
                    isSelected: _selectedPreset == 'overview',
                    onPressed: () => _applyPreset('overview'),
                  ),
                  PresetButton(
                    label: '해마 계곡',
                    isSelected: _selectedPreset == 'seahorse',
                    onPressed: () => _applyPreset('seahorse'),
                  ),
                  PresetButton(
                    label: '나선',
                    isSelected: _selectedPreset == 'spiral',
                    onPressed: () => _applyPreset('spiral'),
                  ),
                  PresetButton(
                    label: '미니',
                    isSelected: _selectedPreset == 'mini',
                    onPressed: () => _applyPreset('mini'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 좌표 정보
              _CoordinateInfo(
                centerX: centerX,
                centerY: centerY,
                zoom: zoom,
                maxIterations: maxIterations,
              ),
              const SizedBox(height: 16),
              // 컬러 스킴
              PresetGroup(
                label: '색상 테마',
                presets: [
                  PresetButton(
                    label: '클래식',
                    isSelected: _colorScheme == 'classic',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _colorScheme = 'classic');
                      _renderMandelbrot();
                    },
                  ),
                  PresetButton(
                    label: '불꽃',
                    isSelected: _colorScheme == 'fire',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _colorScheme = 'fire');
                      _renderMandelbrot();
                    },
                  ),
                  PresetButton(
                    label: '바다',
                    isSelected: _colorScheme == 'ocean',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _colorScheme = 'ocean');
                      _renderMandelbrot();
                    },
                  ),
                  PresetButton(
                    label: '무지개',
                    isSelected: _colorScheme == 'rainbow',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _colorScheme = 'rainbow');
                      _renderMandelbrot();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 반복 횟수 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '반복 횟수 (정밀도)',
                  value: maxIterations.toDouble(),
                  min: 50,
                  max: 500,
                  defaultValue: _defaultMaxIterations.toDouble(),
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) {
                    setState(() => maxIterations = v.toInt());
                    _renderMandelbrot();
                  },
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '확대',
                icon: Icons.zoom_in,
                isPrimary: true,
                onPressed: _zoomIn,
              ),
              SimButton(
                label: '축소',
                icon: Icons.zoom_out,
                onPressed: _zoomOut,
              ),
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

/// 좌표 정보 위젯
class _CoordinateInfo extends StatelessWidget {
  final double centerX;
  final double centerY;
  final double zoom;
  final int maxIterations;

  const _CoordinateInfo({
    required this.centerX,
    required this.centerY,
    required this.zoom,
    required this.maxIterations,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              _InfoItem(label: 'Re(c)', value: centerX.toStringAsFixed(6)),
              _InfoItem(label: 'Im(c)', value: centerY.toStringAsFixed(6)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(label: '확대', value: '${zoom.toStringAsFixed(1)}x'),
              _InfoItem(label: '반복', value: '$maxIterations'),
            ],
          ),
        ],
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
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class MandelbrotPainter extends CustomPainter {
  final double centerX;
  final double centerY;
  final double zoom;
  final int maxIterations;
  final String colorScheme;

  MandelbrotPainter({
    required this.centerX,
    required this.centerY,
    required this.zoom,
    required this.maxIterations,
    required this.colorScheme,
  });

  Color _getColor(double t) {
    switch (colorScheme) {
      case 'fire':
        return HSLColor.fromAHSL(1.0, t * 60, 1.0, 0.5).toColor();
      case 'ocean':
        return HSLColor.fromAHSL(1.0, 180 + t * 60, 0.8, 0.3 + t * 0.4).toColor();
      case 'rainbow':
        return HSLColor.fromAHSL(1.0, t * 360, 0.9, 0.5).toColor();
      case 'classic':
      default:
        return HSLColor.fromAHSL(1.0, (t * 360 + 200) % 360, 0.8, 0.5).toColor();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = 3.0 / zoom;
    final xMin = centerX - scale;
    final xMax = centerX + scale;
    final yMin = centerY - scale * size.height / size.width;
    final yMax = centerY + scale * size.height / size.width;

    // 저해상도 렌더링 (빠른 미리보기)
    const step = 4;
    for (double py = 0; py < size.height; py += step) {
      for (double px = 0; px < size.width; px += step) {
        final x0 = xMin + (xMax - xMin) * px / size.width;
        final y0 = yMin + (yMax - yMin) * py / size.height;

        double x = 0;
        double y = 0;
        int iteration = 0;

        while (x * x + y * y <= 4 && iteration < maxIterations) {
          final xTemp = x * x - y * y + x0;
          y = 2 * x * y + y0;
          x = xTemp;
          iteration++;
        }

        Color color;
        if (iteration == maxIterations) {
          color = Colors.black;
        } else {
          final t = iteration / maxIterations;
          color = _getColor(t);
        }

        canvas.drawRect(
          Rect.fromLTWH(px, py, step.toDouble(), step.toDouble()),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant MandelbrotPainter oldDelegate) =>
      centerX != oldDelegate.centerX ||
      centerY != oldDelegate.centerY ||
      zoom != oldDelegate.zoom ||
      maxIterations != oldDelegate.maxIterations ||
      colorScheme != oldDelegate.colorScheme;
}
