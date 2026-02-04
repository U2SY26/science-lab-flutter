import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Rossler Attractor Simulation
class RosslerAttractorScreen extends ConsumerStatefulWidget {
  const RosslerAttractorScreen({super.key});

  @override
  ConsumerState<RosslerAttractorScreen> createState() => _RosslerAttractorScreenState();
}

class _RosslerAttractorScreenState extends ConsumerState<RosslerAttractorScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Rossler parameters
  double _a = 0.2;
  double _b = 0.2;
  double _c = 5.7;

  // State
  double _x = 0.1;
  double _y = 0.1;
  double _z = 0.1;
  bool _isRunning = true;

  // Trail
  final List<List<double>> _trail = [];
  static const int _maxTrail = 5000;

  // View
  double _rotationX = 0.3;
  double _rotationY = 0.5;
  double _scale = 8.0;
  Offset? _lastPanPosition;
  String _viewMode = '3d';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateSystem);
    _controller.repeat();
  }

  void _updateSystem() {
    if (!_isRunning) return;

    setState(() {
      const dt = 0.02;

      // Rossler equations:
      // dx/dt = -y - z
      // dy/dt = x + a*y
      // dz/dt = b + z*(x - c)
      final dx = (-_y - _z) * dt;
      final dy = (_x + _a * _y) * dt;
      final dz = (_b + _z * (_x - _c)) * dt;

      _x += dx;
      _y += dy;
      _z += dz;

      _trail.add([_x, _y, _z]);
      if (_trail.length > _maxTrail) {
        _trail.removeAt(0);
      }
    });
  }

  Offset _project(double px, double py, double pz, Size size) {
    switch (_viewMode) {
      case 'xy':
        return Offset(
          size.width / 2 + px * _scale,
          size.height / 2 - py * _scale,
        );
      case 'xz':
        return Offset(
          size.width / 2 + px * _scale,
          size.height / 2 - pz * _scale,
        );
      case 'yz':
        return Offset(
          size.width / 2 + py * _scale,
          size.height / 2 - pz * _scale,
        );
      default:
        // 3D projection with rotation
        final cosX = math.cos(_rotationX);
        final sinX = math.sin(_rotationX);
        final cosY = math.cos(_rotationY);
        final sinY = math.sin(_rotationY);

        final x1 = px * cosY - pz * sinY;
        final z1 = px * sinY + pz * cosY;
        final y1 = py * cosX - z1 * sinX;

        return Offset(
          size.width / 2 + x1 * _scale,
          size.height / 2 - y1 * _scale,
        );
    }
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
      _z = 0.1;
      _trail.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(languageProvider.notifier).isKorean;

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
              isKorean ? '뢰슬러 어트랙터' : 'Rossler Attractor',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_in_ar),
            tooltip: isKorean ? '뷰 모드' : 'View Mode',
            onSelected: (mode) {
              HapticFeedback.selectionClick();
              setState(() => _viewMode = mode);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: '3d', child: Text(isKorean ? '3D 회전' : '3D Rotation')),
              const PopupMenuItem(value: 'xy', child: Text('X-Y')),
              const PopupMenuItem(value: 'xz', child: Text('X-Z')),
              const PopupMenuItem(value: 'yz', child: Text('Y-Z')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '혼돈 이론' : 'Chaos Theory',
          title: isKorean ? '뢰슬러 어트랙터' : 'Rossler Attractor',
          formula: 'dx/dt = -y-z, dy/dt = x+ay, dz/dt = b+z(x-c)',
          formulaDescription: isKorean
              ? 'Otto Rossler가 발견한 연속 시간 동역학계. 로렌츠 어트랙터보다 단순하지만 유사한 카오스 특성을 보입니다.'
              : 'A continuous-time dynamical system discovered by Otto Rossler. Simpler than Lorenz but shows similar chaotic properties.',
          simulation: GestureDetector(
            onScaleStart: (details) {
              _lastPanPosition = details.focalPoint;
            },
            onScaleUpdate: (details) {
              setState(() {
                if (details.scale != 1.0) {
                  _scale = (_scale * details.scale).clamp(2.0, 30.0);
                }
                if (_lastPanPosition != null && _viewMode == '3d') {
                  _rotationY += (details.focalPoint.dx - _lastPanPosition!.dx) * 0.01;
                  _rotationX += (details.focalPoint.dy - _lastPanPosition!.dy) * 0.01;
                }
                _lastPanPosition = details.focalPoint;
              });
            },
            child: SizedBox(
              height: 350,
              child: CustomPaint(
                painter: _RosslerAttractorPainter(
                  trail: _trail,
                  project: _project,
                  viewMode: _viewMode,
                  isKorean: isKorean,
                ),
                size: Size.infinite,
              ),
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
                    _InfoItem(label: 'x', value: _x.toStringAsFixed(2), color: AppColors.accent),
                    _InfoItem(label: 'y', value: _y.toStringAsFixed(2), color: AppColors.accent),
                    _InfoItem(label: 'z', value: _z.toStringAsFixed(2), color: AppColors.accent2),
                    _InfoItem(label: isKorean ? '점' : 'Pts', value: '${_trail.length}', color: AppColors.muted),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: 'a',
                  value: _a,
                  min: 0.1,
                  max: 0.5,
                  defaultValue: 0.2,
                  formatValue: (v) => v.toStringAsFixed(2),
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
                    min: 0.1,
                    max: 0.5,
                    defaultValue: 0.2,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) {
                      setState(() {
                        _b = v;
                        _reset();
                      });
                    },
                  ),
                  SimSlider(
                    label: 'c',
                    value: _c,
                    min: 2.0,
                    max: 10.0,
                    defaultValue: 5.7,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) {
                      setState(() {
                        _c = v;
                        _reset();
                      });
                    },
                  ),
                  SimSlider(
                    label: isKorean ? '확대' : 'Zoom',
                    value: _scale,
                    min: 2,
                    max: 30,
                    defaultValue: 8,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() => _scale = v),
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
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _RosslerAttractorPainter extends CustomPainter {
  final List<List<double>> trail;
  final Offset Function(double, double, double, Size) project;
  final String viewMode;
  final bool isKorean;

  _RosslerAttractorPainter({
    required this.trail,
    required this.project,
    required this.viewMode,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Grid
    _drawGrid(canvas, size);

    if (trail.length < 2) return;

    // Draw trail with gradient
    for (int i = 1; i < trail.length; i++) {
      final t = i / trail.length;
      final color = Color.lerp(
        AppColors.accent.withValues(alpha: 0.2),
        AppColors.accent2,
        t,
      )!;

      final p1 = project(trail[i - 1][0], trail[i - 1][1], trail[i - 1][2], size);
      final p2 = project(trail[i][0], trail[i][1], trail[i][2], size);

      canvas.drawLine(
        p1, p2,
        Paint()
          ..color = color
          ..strokeWidth = 0.5 + t * 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Current position
    if (trail.isNotEmpty) {
      final last = trail.last;
      final p = project(last[0], last[1], last[2], size);

      canvas.drawCircle(p, 8, Paint()..color = Colors.white.withValues(alpha: 0.3));
      canvas.drawCircle(p, 4, Paint()..color = Colors.white);
    }

    // View mode label
    String modeLabel;
    switch (viewMode) {
      case 'xy': modeLabel = 'X-Y'; break;
      case 'xz': modeLabel = 'X-Z'; break;
      case 'yz': modeLabel = 'Y-Z'; break;
      default: modeLabel = isKorean ? '3D (드래그: 회전)' : '3D (Drag to rotate)';
    }
    _drawText(canvas, modeLabel, const Offset(10, 10), AppColors.muted, 11);
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

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _RosslerAttractorPainter oldDelegate) => true;
}
