import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 로렌츠 어트랙터 화면 - 결정론적 카오스의 대표적 예시
class LorenzScreen extends StatefulWidget {
  const LorenzScreen({super.key});

  @override
  State<LorenzScreen> createState() => _LorenzScreenState();
}

class _LorenzScreenState extends State<LorenzScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 로렌츠 기본 파라미터
  static const double _defaultSigma = 10;
  static const double _defaultRho = 28;
  static const double _defaultBeta = 8 / 3;

  // 로렌츠 파라미터
  double sigma = _defaultSigma;
  double rho = _defaultRho;
  double beta = _defaultBeta;
  bool isRunning = true;

  // 상태
  double x = 0.1;
  double y = 0;
  double z = 0;
  List<List<double>> trail = [];

  // 회전 및 뷰
  double rotationX = 0.5;
  double rotationY = 0.5;
  double scale = 8;
  Offset? _lastPanPosition;
  String _viewMode = 'xz'; // 'xz', 'xy', 'yz', '3d'

  // 프리셋
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    _controller.repeat();
  }

  void _updatePhysics() {
    if (!isRunning) return;

    setState(() {
      const dt = 0.01;
      final dx = sigma * (y - x) * dt;
      final dy = (x * (rho - z) - y) * dt;
      final dz = (x * y - beta * z) * dt;

      x += dx;
      y += dy;
      z += dz;

      trail.add([x, y, z]);
      if (trail.length > 3000) trail.removeAt(0);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      x = 0.1;
      y = 0;
      z = 0;
      trail.clear();
      _selectedPreset = null;
    });
  }

  void _perturbInitial() {
    HapticFeedback.lightImpact();
    setState(() {
      x += 0.0001; // 아주 작은 변화로 카오스 시연
      trail.clear();
    });
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      trail.clear();
      x = 0.1;
      y = 0;
      z = 0;

      switch (preset) {
        case 'classic':
          sigma = 10;
          rho = 28;
          beta = 8 / 3;
          break;
        case 'periodic':
          sigma = 10;
          rho = 13;
          beta = 8 / 3;
          break;
        case 'transient':
          sigma = 10;
          rho = 21;
          beta = 8 / 3;
          break;
        case 'wild':
          sigma = 16;
          rho = 45.92;
          beta = 4;
          break;
      }
    });
  }

  Offset _project(double px, double py, double pz, Size size) {
    switch (_viewMode) {
      case 'xy':
        return Offset(
          size.width / 2 + px * scale,
          size.height / 2 - py * scale,
        );
      case 'xz':
        return Offset(
          size.width / 2 + px * scale,
          size.height / 2 - (pz - 25) * scale,
        );
      case 'yz':
        return Offset(
          size.width / 2 + py * scale,
          size.height / 2 - (pz - 25) * scale,
        );
      case '3d':
      default:
        // 3D to 2D projection with rotation
        final cosX = math.cos(rotationX);
        final sinX = math.sin(rotationX);
        final cosY = math.cos(rotationY);
        final sinY = math.sin(rotationY);

        // Rotate around Y axis
        final x1 = px * cosY - pz * sinY;
        final z1 = px * sinY + pz * cosY;

        // Rotate around X axis
        final y1 = py * cosX - z1 * sinX;

        return Offset(
          size.width / 2 + x1 * scale,
          size.height / 2 - y1 * scale,
        );
    }
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
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '혼돈 이론',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '로렌츠 어트랙터',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          // 뷰 모드 선택
          PopupMenuButton<String>(
            icon: const Icon(Icons.view_in_ar),
            tooltip: '뷰 모드',
            onSelected: (mode) {
              HapticFeedback.selectionClick();
              setState(() => _viewMode = mode);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '3d', child: Text('3D 회전')),
              const PopupMenuItem(value: 'xz', child: Text('X-Z 평면')),
              const PopupMenuItem(value: 'xy', child: Text('X-Y 평면')),
              const PopupMenuItem(value: 'yz', child: Text('Y-Z 평면')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '혼돈 이론',
          title: '로렌츠 어트랙터',
          formula: 'dx/dt = σ(y-x), dy/dt = x(ρ-z)-y, dz/dt = xy-βz',
          formulaDescription: '대기 대류 모델에서 발견된 결정론적 비주기 흐름',
          simulation: GestureDetector(
            onScaleStart: (details) {
              _lastPanPosition = details.focalPoint;
            },
            onScaleUpdate: (details) {
              setState(() {
                // 줌 (핀치 제스처)
                if (details.scale != 1.0) {
                  scale = (scale * details.scale).clamp(2.0, 20.0);
                }
                // 회전 (드래그 제스처, 3D 모드에서만)
                if (_lastPanPosition != null && _viewMode == '3d') {
                  rotationY += (details.focalPoint.dx - _lastPanPosition!.dx) * 0.01;
                  rotationX += (details.focalPoint.dy - _lastPanPosition!.dy) * 0.01;
                }
                _lastPanPosition = details.focalPoint;
              });
            },
            child: SizedBox(
              height: 350,
              child: CustomPaint(
                painter: LorenzPainter(
                  trail: trail,
                  project: _project,
                  viewMode: _viewMode,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋
              PresetGroup(
                label: '시스템 상태',
                presets: [
                  PresetButton(
                    label: '클래식',
                    isSelected: _selectedPreset == 'classic',
                    onPressed: () => _applyPreset('classic'),
                  ),
                  PresetButton(
                    label: '주기적',
                    isSelected: _selectedPreset == 'periodic',
                    onPressed: () => _applyPreset('periodic'),
                  ),
                  PresetButton(
                    label: '과도기',
                    isSelected: _selectedPreset == 'transient',
                    onPressed: () => _applyPreset('transient'),
                  ),
                  PresetButton(
                    label: '혼돈',
                    isSelected: _selectedPreset == 'wild',
                    onPressed: () => _applyPreset('wild'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 상태 정보
              _StateInfo(x: x, y: y, z: z, pointCount: trail.length),
              const SizedBox(height: 16),
              // 파라미터 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: 'σ (sigma) - 프란틀 수',
                  value: sigma,
                  min: 0,
                  max: 20,
                  defaultValue: _defaultSigma,
                  formatValue: (v) => v.toStringAsFixed(1),
                  onChanged: (v) => setState(() {
                    sigma = v;
                    _selectedPreset = null;
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: 'ρ (rho) - 레일리 수',
                    value: rho,
                    min: 0,
                    max: 50,
                    defaultValue: _defaultRho,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() {
                      rho = v;
                      _selectedPreset = null;
                    }),
                  ),
                  SimSlider(
                    label: 'β (beta) - 기하학적 계수',
                    value: beta,
                    min: 0,
                    max: 10,
                    defaultValue: _defaultBeta,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() {
                      beta = v;
                      _selectedPreset = null;
                    }),
                  ),
                  SimSlider(
                    label: '확대/축소',
                    value: scale,
                    min: 2,
                    max: 20,
                    defaultValue: 8,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() => scale = v),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning ? '정지' : '재생',
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => isRunning = !isRunning);
                },
              ),
              SimButton(
                label: '섭동',
                icon: Icons.waves,
                onPressed: _perturbInitial,
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

/// 상태 정보 위젯
class _StateInfo extends StatelessWidget {
  final double x, y, z;
  final int pointCount;

  const _StateInfo({
    required this.x,
    required this.y,
    required this.z,
    required this.pointCount,
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
      child: Row(
        children: [
          _InfoItem(label: 'X', value: x.toStringAsFixed(2), color: AppColors.accent),
          _InfoItem(label: 'Y', value: y.toStringAsFixed(2), color: AppColors.accent),
          _InfoItem(label: 'Z', value: z.toStringAsFixed(2), color: AppColors.accent2),
          _InfoItem(label: 'Points', value: pointCount.toString(), color: AppColors.muted),
        ],
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
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
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

/// 로렌츠 어트랙터 페인터
class LorenzPainter extends CustomPainter {
  final List<List<double>> trail;
  final Offset Function(double, double, double, Size) project;
  final String viewMode;

  LorenzPainter({
    required this.trail,
    required this.project,
    required this.viewMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    // 그리드
    _drawGrid(canvas, size);

    if (trail.length < 2) return;

    // 궤적 그리기 (색상 그라데이션)
    for (int i = 1; i < trail.length; i++) {
      final t = i / trail.length;
      final color = Color.lerp(
        AppColors.accent,
        AppColors.accent2,
        t,
      )!.withValues(alpha: 0.3 + t * 0.6);

      final p1 = project(trail[i - 1][0], trail[i - 1][1], trail[i - 1][2], size);
      final p2 = project(trail[i][0], trail[i][1], trail[i][2], size);

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = color
          ..strokeWidth = 0.5 + t * 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // 현재 위치 표시
    if (trail.isNotEmpty) {
      final last = trail.last;
      final p = project(last[0], last[1], last[2], size);

      // 글로우
      canvas.drawCircle(
        p,
        8,
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      );
      canvas.drawCircle(
        p,
        4,
        Paint()..color = Colors.white,
      );
    }

    // 뷰 모드 표시
    _drawViewMode(canvas, size);
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

  void _drawViewMode(Canvas canvas, Size size) {
    String modeText;
    switch (viewMode) {
      case 'xy':
        modeText = 'X-Y 평면';
        break;
      case 'xz':
        modeText = 'X-Z 평면';
        break;
      case 'yz':
        modeText = 'Y-Z 평면';
        break;
      default:
        modeText = '3D (드래그: 회전)';
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: modeText,
        style: TextStyle(
          color: AppColors.muted.withValues(alpha: 0.7),
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(covariant LorenzPainter oldDelegate) => true;
}
