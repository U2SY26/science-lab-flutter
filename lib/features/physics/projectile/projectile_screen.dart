import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 발사체 운동 화면
class ProjectileScreen extends StatefulWidget {
  const ProjectileScreen({super.key});

  @override
  State<ProjectileScreen> createState() => _ProjectileScreenState();
}

class _ProjectileScreenState extends State<ProjectileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 기본값
  static const double _defaultVelocity = 30;
  static const double _defaultAngle = 45;
  static const double _defaultGravity = 9.8;

  // 파라미터
  double _velocity = _defaultVelocity; // m/s
  double _angle = _defaultAngle; // degrees
  double _gravity = _defaultGravity; // m/s²
  bool _isRunning = false;
  bool _showTrajectory = true;

  // 상태
  double _time = 0;
  double _x = 0;
  double _y = 0;
  List<Offset> _trail = [];

  // 프리셋
  String? _selectedPreset;

  // 계산된 값
  double get _vx => _velocity * math.cos(_angle * math.pi / 180);
  double get _vy => _velocity * math.sin(_angle * math.pi / 180);
  double get _maxHeight => (_vy * _vy) / (2 * _gravity);
  double get _flightTime => (2 * _vy) / _gravity;
  double get _range => _vx * _flightTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_update);
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      _time += 0.016; // ~60fps
      _x = _vx * _time;
      _y = _vy * _time - 0.5 * _gravity * _time * _time;

      if (_y >= 0) {
        _trail.add(Offset(_x, _y));
        if (_trail.length > 500) _trail.removeAt(0);
      } else {
        // 착지
        _isRunning = false;
        _controller.stop();
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _launch() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _x = 0;
      _y = 0;
      _trail.clear();
      _isRunning = true;
    });
    _controller.repeat();
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _time = 0;
      _x = 0;
      _y = 0;
      _trail.clear();
      _isRunning = false;
    });
    _controller.stop();
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    _reset();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'cannon':
          _velocity = 50;
          _angle = 45;
          _gravity = 9.8;
          break;
        case 'basketball':
          _velocity = 8;
          _angle = 55;
          _gravity = 9.8;
          break;
        case 'moon':
          _velocity = 30;
          _angle = 45;
          _gravity = 1.62;
          break;
        case 'mars':
          _velocity = 30;
          _angle = 45;
          _gravity = 3.72;
          break;
        case 'optimal':
          _velocity = 30;
          _angle = 45;
          _gravity = 9.8;
          break;
        case 'high':
          _velocity = 30;
          _angle = 75;
          _gravity = 9.8;
          break;
      }
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
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '역학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '발사체 운동',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '역학',
          title: '발사체 운동',
          formula: 'x = v₀cosθ·t, y = v₀sinθ·t - ½gt²',
          formulaDescription: '중력장에서 물체의 포물선 운동',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: ProjectilePainter(
                x: _x,
                y: _y,
                trail: _trail,
                maxRange: _range * 1.2,
                maxHeight: _maxHeight * 1.5,
                showTrajectory: _showTrajectory,
                angle: _angle,
                velocity: _velocity,
                gravity: _gravity,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 환경 프리셋
              PresetGroup(
                label: '환경 설정',
                presets: [
                  PresetButton(
                    label: '지구',
                    isSelected: _selectedPreset == 'optimal',
                    onPressed: () => _applyPreset('optimal'),
                  ),
                  PresetButton(
                    label: '달',
                    isSelected: _selectedPreset == 'moon',
                    onPressed: () => _applyPreset('moon'),
                  ),
                  PresetButton(
                    label: '화성',
                    isSelected: _selectedPreset == 'mars',
                    onPressed: () => _applyPreset('mars'),
                  ),
                  PresetButton(
                    label: '대포',
                    isSelected: _selectedPreset == 'cannon',
                    onPressed: () => _applyPreset('cannon'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 운동 정보
              _ProjectileInfo(
                velocity: _velocity,
                angle: _angle,
                vx: _vx,
                vy: _vy,
                maxHeight: _maxHeight,
                range: _range,
                flightTime: _flightTime,
                currentX: _x,
                currentY: _y,
                time: _time,
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '발사 각도',
                  value: _angle,
                  min: 5,
                  max: 85,
                  defaultValue: _defaultAngle,
                  formatValue: (v) => '${v.toStringAsFixed(0)}°',
                  onChanged: (v) {
                    _reset();
                    setState(() {
                      _angle = v;
                      _selectedPreset = null;
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '초기 속도',
                    value: _velocity,
                    min: 5,
                    max: 100,
                    defaultValue: _defaultVelocity,
                    formatValue: (v) => '${v.toStringAsFixed(0)} m/s',
                    onChanged: (v) {
                      _reset();
                      setState(() {
                        _velocity = v;
                        _selectedPreset = null;
                      });
                    },
                  ),
                  SimSlider(
                    label: '중력 가속도',
                    value: _gravity,
                    min: 0.5,
                    max: 20,
                    defaultValue: _defaultGravity,
                    formatValue: (v) => '${v.toStringAsFixed(1)} m/s²',
                    onChanged: (v) {
                      _reset();
                      setState(() {
                        _gravity = v;
                        _selectedPreset = null;
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
                label: _isRunning ? '정지' : '발사',
                icon: _isRunning ? Icons.stop : Icons.rocket_launch,
                isPrimary: true,
                onPressed: _isRunning ? _reset : _launch,
              ),
              SimButton(
                label: '리셋',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
              SimButton(
                label: _showTrajectory ? '궤적 숨김' : '궤적 표시',
                icon: Icons.timeline,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showTrajectory = !_showTrajectory);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 발사체 정보 위젯
class _ProjectileInfo extends StatelessWidget {
  final double velocity;
  final double angle;
  final double vx;
  final double vy;
  final double maxHeight;
  final double range;
  final double flightTime;
  final double currentX;
  final double currentY;
  final double time;

  const _ProjectileInfo({
    required this.velocity,
    required this.angle,
    required this.vx,
    required this.vy,
    required this.maxHeight,
    required this.range,
    required this.flightTime,
    required this.currentX,
    required this.currentY,
    required this.time,
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
          // 초기 조건
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: 'V₀',
                  value: '${velocity.toStringAsFixed(0)} m/s',
                  icon: Icons.speed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: 'θ',
                  value: '${angle.toStringAsFixed(0)}°',
                  icon: Icons.rotate_right,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: 'Vx',
                  value: '${vx.toStringAsFixed(1)}',
                  icon: Icons.arrow_forward,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: 'Vy',
                  value: '${vy.toStringAsFixed(1)}',
                  icon: Icons.arrow_upward,
                  color: AppColors.accent2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 8),
          // 예측값
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: '최대 높이',
                  value: '${maxHeight.toStringAsFixed(1)} m',
                  icon: Icons.height,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: '도달 거리',
                  value: '${range.toStringAsFixed(1)} m',
                  icon: Icons.straighten,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: '비행 시간',
                  value: '${flightTime.toStringAsFixed(1)} s',
                  icon: Icons.timer,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          if (time > 0) ...[
            const SizedBox(height: 8),
            const Divider(color: AppColors.cardBorder),
            const SizedBox(height: 8),
            // 현재 상태
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    label: 't',
                    value: '${time.toStringAsFixed(2)} s',
                    icon: Icons.access_time,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoChip(
                    label: 'x',
                    value: '${currentX.toStringAsFixed(1)} m',
                    icon: Icons.arrow_right_alt,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoChip(
                    label: 'y',
                    value: '${currentY.toStringAsFixed(1)} m',
                    icon: Icons.arrow_upward,
                    color: AppColors.accent2,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.muted;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: chipColor),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  color: chipColor.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: chipColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// 발사체 운동 페인터
class ProjectilePainter extends CustomPainter {
  final double x;
  final double y;
  final List<Offset> trail;
  final double maxRange;
  final double maxHeight;
  final bool showTrajectory;
  final double angle;
  final double velocity;
  final double gravity;

  ProjectilePainter({
    required this.x,
    required this.y,
    required this.trail,
    required this.maxRange,
    required this.maxHeight,
    required this.showTrajectory,
    required this.angle,
    required this.velocity,
    required this.gravity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // 스케일 계산
    final scaleX = graphWidth / (maxRange > 0 ? maxRange : 100);
    final scaleY = graphHeight / (maxHeight > 0 ? maxHeight : 50);
    final scale = math.min(scaleX, scaleY);

    Offset toScreen(double px, double py) {
      return Offset(
        padding + px * scale,
        size.height - padding - py * scale,
      );
    }

    // 그리드
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 10; i++) {
      final px = padding + i * graphWidth / 10;
      final py = padding + i * graphHeight / 10;
      canvas.drawLine(Offset(px, padding), Offset(px, size.height - padding), gridPaint);
      canvas.drawLine(Offset(padding, py), Offset(size.width - padding, py), gridPaint);
    }

    // 지면
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      Paint()
        ..color = Colors.brown.withValues(alpha: 0.5)
        ..strokeWidth = 3,
    );

    // 예상 궤적 (점선)
    if (showTrajectory) {
      final trajPath = Path();
      final vx = velocity * math.cos(angle * math.pi / 180);
      final vy = velocity * math.sin(angle * math.pi / 180);
      bool started = false;

      for (double t = 0; t < 20; t += 0.05) {
        final px = vx * t;
        final py = vy * t - 0.5 * gravity * t * t;
        if (py < 0) break;

        final screen = toScreen(px, py);
        if (screen.dx < size.width - padding && screen.dy > padding) {
          if (!started) {
            trajPath.moveTo(screen.dx, screen.dy);
            started = true;
          } else {
            trajPath.lineTo(screen.dx, screen.dy);
          }
        }
      }

      // 점선 효과
      canvas.drawPath(
        trajPath,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.2)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // 실제 궤적 (글로우)
    if (trail.length > 1) {
      final trailPath = Path();
      trailPath.moveTo(toScreen(trail[0].dx, trail[0].dy).dx, toScreen(trail[0].dx, trail[0].dy).dy);

      for (int i = 1; i < trail.length; i++) {
        final p = toScreen(trail[i].dx, trail[i].dy);
        trailPath.lineTo(p.dx, p.dy);
      }

      // 글로우
      canvas.drawPath(
        trailPath,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.3)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // 메인 라인
      canvas.drawPath(
        trailPath,
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // 발사체 위치
    if (y >= 0) {
      final pos = toScreen(x, y);

      // 글로우
      canvas.drawCircle(
        pos,
        15,
        Paint()..color = AppColors.accent2.withValues(alpha: 0.3),
      );

      // 발사체
      canvas.drawCircle(
        pos,
        8,
        Paint()..color = AppColors.accent2,
      );

      // 속도 벡터
      final currentVy = velocity * math.sin(angle * math.pi / 180) - gravity * (trail.length * 0.016);
      final currentVx = velocity * math.cos(angle * math.pi / 180);
      final vLength = 20.0;
      final vScale = vLength / math.sqrt(currentVx * currentVx + currentVy * currentVy);

      canvas.drawLine(
        pos,
        Offset(pos.dx + currentVx * vScale, pos.dy - currentVy * vScale),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // 발사대
    final launcherPos = toScreen(0, 0);
    final launcherEnd = Offset(
      launcherPos.dx + 30 * math.cos(-angle * math.pi / 180),
      launcherPos.dy + 30 * math.sin(-angle * math.pi / 180),
    );

    canvas.drawLine(
      launcherPos,
      launcherEnd,
      Paint()
        ..color = Colors.grey
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // 축 레이블
    _drawText(canvas, 'x (m)', Offset(size.width - padding - 20, size.height - padding + 20));
    _drawText(canvas, 'y (m)', Offset(padding - 30, padding - 5));
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant ProjectilePainter oldDelegate) => true;
}
