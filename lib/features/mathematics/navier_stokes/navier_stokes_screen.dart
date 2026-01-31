import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 나비에-스토크스 방정식 유체 시뮬레이션
class NavierStokesScreen extends StatefulWidget {
  const NavierStokesScreen({super.key});

  @override
  State<NavierStokesScreen> createState() => _NavierStokesScreenState();
}

class _NavierStokesScreenState extends State<NavierStokesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const int gridSize = 64;
  late Float32List _density;
  late Float32List _densityPrev;
  late Float32List _velocityX;
  late Float32List _velocityY;
  late Float32List _velocityXPrev;
  late Float32List _velocityYPrev;

  double _viscosity = 0.0001;
  double _diffusion = 0.0001;
  String _visualization = 'density';
  Offset? _lastTouch;
  bool _isRunning = true;

  @override
  void initState() {
    super.initState();
    _initFluid();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
    _controller.repeat();
  }

  void _initFluid() {
    final size = (gridSize + 2) * (gridSize + 2);
    _density = Float32List(size);
    _densityPrev = Float32List(size);
    _velocityX = Float32List(size);
    _velocityY = Float32List(size);
    _velocityXPrev = Float32List(size);
    _velocityYPrev = Float32List(size);
  }

  int _idx(int x, int y) => x + (gridSize + 2) * y;

  void _update() {
    if (!_isRunning) return;

    // 이전 값 저장
    _velocityXPrev.setAll(0, _velocityX);
    _velocityYPrev.setAll(0, _velocityY);
    _densityPrev.setAll(0, _density);

    // 속도 단계
    _diffuse(1, _velocityX, _velocityXPrev, _viscosity);
    _diffuse(2, _velocityY, _velocityYPrev, _viscosity);
    _project(_velocityX, _velocityY, _velocityXPrev, _velocityYPrev);

    _advect(1, _velocityXPrev, _velocityX, _velocityX, _velocityY);
    _advect(2, _velocityYPrev, _velocityY, _velocityX, _velocityY);
    _velocityX.setAll(0, _velocityXPrev);
    _velocityY.setAll(0, _velocityYPrev);
    _project(_velocityX, _velocityY, _velocityXPrev, _velocityYPrev);

    // 밀도 단계
    _diffuse(0, _densityPrev, _density, _diffusion);
    _advect(0, _density, _densityPrev, _velocityX, _velocityY);

    setState(() {});
  }

  void _diffuse(int b, Float32List x, Float32List x0, double diff) {
    final a = 0.016 * diff * gridSize * gridSize;
    final c = 1 + 4 * a;

    for (int k = 0; k < 20; k++) {
      for (int i = 1; i <= gridSize; i++) {
        for (int j = 1; j <= gridSize; j++) {
          x[_idx(i, j)] = (x0[_idx(i, j)] +
              a * (x[_idx(i - 1, j)] + x[_idx(i + 1, j)] +
                  x[_idx(i, j - 1)] + x[_idx(i, j + 1)])) / c;
        }
      }
      _setBnd(b, x);
    }
  }

  void _advect(int b, Float32List d, Float32List d0, Float32List u, Float32List v) {
    final dt0 = 0.016 * gridSize;

    for (int i = 1; i <= gridSize; i++) {
      for (int j = 1; j <= gridSize; j++) {
        var x = i - dt0 * u[_idx(i, j)];
        var y = j - dt0 * v[_idx(i, j)];

        x = x.clamp(0.5, gridSize + 0.5);
        y = y.clamp(0.5, gridSize + 0.5);

        final i0 = x.floor();
        final i1 = i0 + 1;
        final j0 = y.floor();
        final j1 = j0 + 1;

        final s1 = x - i0;
        final s0 = 1 - s1;
        final t1 = y - j0;
        final t0 = 1 - t1;

        d[_idx(i, j)] = s0 * (t0 * d0[_idx(i0, j0)] + t1 * d0[_idx(i0, j1)]) +
            s1 * (t0 * d0[_idx(i1, j0)] + t1 * d0[_idx(i1, j1)]);
      }
    }
    _setBnd(b, d);
  }

  void _project(Float32List u, Float32List v, Float32List p, Float32List div) {
    final h = 1.0 / gridSize;

    for (int i = 1; i <= gridSize; i++) {
      for (int j = 1; j <= gridSize; j++) {
        div[_idx(i, j)] = -0.5 * h * (u[_idx(i + 1, j)] - u[_idx(i - 1, j)] +
            v[_idx(i, j + 1)] - v[_idx(i, j - 1)]);
        p[_idx(i, j)] = 0;
      }
    }
    _setBnd(0, div);
    _setBnd(0, p);

    for (int k = 0; k < 20; k++) {
      for (int i = 1; i <= gridSize; i++) {
        for (int j = 1; j <= gridSize; j++) {
          p[_idx(i, j)] = (div[_idx(i, j)] +
              p[_idx(i - 1, j)] + p[_idx(i + 1, j)] +
              p[_idx(i, j - 1)] + p[_idx(i, j + 1)]) / 4;
        }
      }
      _setBnd(0, p);
    }

    for (int i = 1; i <= gridSize; i++) {
      for (int j = 1; j <= gridSize; j++) {
        u[_idx(i, j)] -= 0.5 * (p[_idx(i + 1, j)] - p[_idx(i - 1, j)]) / h;
        v[_idx(i, j)] -= 0.5 * (p[_idx(i, j + 1)] - p[_idx(i, j - 1)]) / h;
      }
    }
    _setBnd(1, u);
    _setBnd(2, v);
  }

  void _setBnd(int b, Float32List x) {
    for (int i = 1; i <= gridSize; i++) {
      x[_idx(0, i)] = b == 1 ? -x[_idx(1, i)] : x[_idx(1, i)];
      x[_idx(gridSize + 1, i)] = b == 1 ? -x[_idx(gridSize, i)] : x[_idx(gridSize, i)];
      x[_idx(i, 0)] = b == 2 ? -x[_idx(i, 1)] : x[_idx(i, 1)];
      x[_idx(i, gridSize + 1)] = b == 2 ? -x[_idx(i, gridSize)] : x[_idx(i, gridSize)];
    }
    x[_idx(0, 0)] = 0.5 * (x[_idx(1, 0)] + x[_idx(0, 1)]);
    x[_idx(0, gridSize + 1)] = 0.5 * (x[_idx(1, gridSize + 1)] + x[_idx(0, gridSize)]);
    x[_idx(gridSize + 1, 0)] = 0.5 * (x[_idx(gridSize, 0)] + x[_idx(gridSize + 1, 1)]);
    x[_idx(gridSize + 1, gridSize + 1)] = 0.5 * (x[_idx(gridSize, gridSize + 1)] + x[_idx(gridSize + 1, gridSize)]);
  }

  void _addSource(Offset position, Size size) {
    final x = ((position.dx / size.width) * gridSize).clamp(1, gridSize).toInt();
    final y = ((position.dy / size.height) * gridSize).clamp(1, gridSize).toInt();

    _density[_idx(x, y)] += 100;

    if (_lastTouch != null) {
      final dx = position.dx - _lastTouch!.dx;
      final dy = position.dy - _lastTouch!.dy;
      _velocityX[_idx(x, y)] += dx * 5;
      _velocityY[_idx(x, y)] += dy * 5;
    }

    _lastTouch = position;
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _initFluid();
    setState(() {});
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
              '밀레니엄 난제',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '나비에-스토크스',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '밀레니엄 난제',
          title: '나비에-스토크스 방정식',
          formula: '∂u/∂t + (u·∇)u = -∇p/ρ + ν∇²u',
          formulaDescription: '유체 흐름을 기술하는 편미분방정식의 해 존재성 문제',
          simulation: SizedBox(
            height: 300,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanStart: (d) {
                    _lastTouch = null;
                    _addSource(d.localPosition, constraints.biggest);
                  },
                  onPanUpdate: (d) => _addSource(d.localPosition, constraints.biggest),
                  onPanEnd: (_) => _lastTouch = null,
                  child: CustomPaint(
                    painter: _FluidPainter(
                      density: _density,
                      velocityX: _velocityX,
                      velocityY: _velocityY,
                      gridSize: gridSize,
                      visualization: _visualization,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 설명
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '상금: \$1,000,000',
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '3차원에서 나비에-스토크스 방정식의 부드러운 해가 항상 존재하는지, '
                      '그리고 유한 시간 내에 특이점(폭발)이 발생할 수 있는지 증명하는 문제입니다.\n\n'
                      '화면을 드래그하여 유체를 저어보세요!',
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
                    label: '밀도',
                    isSelected: _visualization == 'density',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _visualization = 'density');
                    },
                  ),
                  PresetButton(
                    label: '속도장',
                    isSelected: _visualization == 'velocity',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _visualization = 'velocity');
                    },
                  ),
                  PresetButton(
                    label: '와도',
                    isSelected: _visualization == 'vorticity',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _visualization = 'vorticity');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '점성 (ν)',
                  value: _viscosity * 10000,
                  min: 0,
                  max: 10,
                  defaultValue: 1,
                  formatValue: (v) => '${(v / 10000).toStringAsFixed(4)}',
                  onChanged: (v) => setState(() => _viscosity = v / 10000),
                ),
                advancedControls: [
                  SimSlider(
                    label: '확산 계수',
                    value: _diffusion * 10000,
                    min: 0,
                    max: 10,
                    defaultValue: 1,
                    formatValue: (v) => '${(v / 10000).toStringAsFixed(4)}',
                    onChanged: (v) => setState(() => _diffusion = v / 10000),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning ? '정지' : '재생',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _isRunning = !_isRunning;
                    if (_isRunning) {
                      _controller.repeat();
                    } else {
                      _controller.stop();
                    }
                  });
                },
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

class _FluidPainter extends CustomPainter {
  final Float32List density;
  final Float32List velocityX;
  final Float32List velocityY;
  final int gridSize;
  final String visualization;

  _FluidPainter({
    required this.density,
    required this.velocityX,
    required this.velocityY,
    required this.gridSize,
    required this.visualization,
  });

  int _idx(int x, int y) => x + (gridSize + 2) * y;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0a0a1a));

    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;

    switch (visualization) {
      case 'density':
        _drawDensity(canvas, size, cellWidth, cellHeight);
        break;
      case 'velocity':
        _drawVelocity(canvas, size, cellWidth, cellHeight);
        break;
      case 'vorticity':
        _drawVorticity(canvas, size, cellWidth, cellHeight);
        break;
    }
  }

  void _drawDensity(Canvas canvas, Size size, double cellWidth, double cellHeight) {
    for (int i = 1; i <= gridSize; i++) {
      for (int j = 1; j <= gridSize; j++) {
        final d = density[_idx(i, j)].clamp(0, 255) / 255;
        if (d > 0.01) {
          final color = Color.lerp(
            const Color(0xFF0a0a1a),
            Colors.cyan,
            d,
          )!;

          canvas.drawRect(
            Rect.fromLTWH((i - 1) * cellWidth, (j - 1) * cellHeight, cellWidth, cellHeight),
            Paint()..color = color,
          );
        }
      }
    }
  }

  void _drawVelocity(Canvas canvas, Size size, double cellWidth, double cellHeight) {
    final step = 4;
    for (int i = 1; i <= gridSize; i += step) {
      for (int j = 1; j <= gridSize; j += step) {
        final vx = velocityX[_idx(i, j)];
        final vy = velocityY[_idx(i, j)];
        final magnitude = math.sqrt(vx * vx + vy * vy);

        if (magnitude > 0.1) {
          final startX = (i - 0.5) * cellWidth;
          final startY = (j - 0.5) * cellHeight;
          final endX = startX + vx * 2;
          final endY = startY + vy * 2;

          final color = Color.lerp(Colors.blue, Colors.red, (magnitude / 20).clamp(0, 1))!;

          canvas.drawLine(
            Offset(startX, startY),
            Offset(endX, endY),
            Paint()
              ..color = color
              ..strokeWidth = 1.5,
          );
        }
      }
    }
  }

  void _drawVorticity(Canvas canvas, Size size, double cellWidth, double cellHeight) {
    for (int i = 2; i < gridSize; i++) {
      for (int j = 2; j < gridSize; j++) {
        // 와도 = ∂vy/∂x - ∂vx/∂y
        final vorticity = (velocityY[_idx(i + 1, j)] - velocityY[_idx(i - 1, j)]) / 2 -
            (velocityX[_idx(i, j + 1)] - velocityX[_idx(i, j - 1)]) / 2;

        final normalizedVort = (vorticity / 5).clamp(-1.0, 1.0);

        Color color;
        if (normalizedVort > 0) {
          color = Color.lerp(const Color(0xFF0a0a1a), Colors.red, normalizedVort)!;
        } else {
          color = Color.lerp(const Color(0xFF0a0a1a), Colors.blue, -normalizedVort)!;
        }

        canvas.drawRect(
          Rect.fromLTWH((i - 1) * cellWidth, (j - 1) * cellHeight, cellWidth, cellHeight),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FluidPainter oldDelegate) => true;
}
