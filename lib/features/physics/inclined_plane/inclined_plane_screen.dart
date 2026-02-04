import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 경사면 시뮬레이션 화면
class InclinedPlaneScreen extends StatefulWidget {
  const InclinedPlaneScreen({super.key});

  @override
  State<InclinedPlaneScreen> createState() => _InclinedPlaneScreenState();
}

class _InclinedPlaneScreenState extends State<InclinedPlaneScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 기본값
  static const double _defaultAngle = 30; // 경사각 (도)
  static const double _defaultFriction = 0.3; // 마찰계수
  static const double _defaultMass = 2; // 질량 (kg)
  static const double _defaultGravity = 9.8; // 중력가속도

  // 파라미터
  double _angle = _defaultAngle;
  double _friction = _defaultFriction;
  double _mass = _defaultMass;
  double _gravity = _defaultGravity;
  bool _isRunning = false;

  // 물리 상태
  double _position = 0; // 경사면 위 위치 (0~1)
  double _velocity = 0;

  // 프리셋
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      const dt = 0.016;

      // 물리 계산: a = g(sinθ - μcosθ)
      final angleRad = _angle * math.pi / 180;
      final sinTheta = math.sin(angleRad);
      final cosTheta = math.cos(angleRad);

      // 경사면 내려가는 힘 vs 마찰력
      final gravityComponent = _gravity * sinTheta;
      final frictionComponent = _friction * _gravity * cosTheta;

      // 순 가속도 (마찰력이 중력 성분보다 크면 움직이지 않음)
      double acceleration = 0;
      if (_velocity > 0 || gravityComponent > frictionComponent) {
        acceleration = gravityComponent - frictionComponent;
      }

      // 속도와 위치 업데이트
      _velocity += acceleration * dt;
      if (_velocity < 0) _velocity = 0; // 위로 올라가지 않음

      _position += _velocity * dt * 0.02; // 스케일 조정

      // 경사면 끝에 도달하면 정지
      if (_position >= 1) {
        _position = 1;
        _velocity = 0;
        _isRunning = false;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _position = 0;
      _velocity = 0;
      _isRunning = false;
    });
  }

  void _start() {
    HapticFeedback.lightImpact();
    if (_position >= 1) {
      _reset();
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'smooth':
          _angle = 45;
          _friction = 0.1;
          _mass = 2;
          break;
        case 'rough':
          _angle = 45;
          _friction = 0.6;
          _mass = 2;
          break;
        case 'steep':
          _angle = 60;
          _friction = 0.3;
          _mass = 2;
          break;
        case 'gentle':
          _angle = 15;
          _friction = 0.3;
          _mass = 2;
          break;
        case 'critical':
          // 임계각 (마찰력 = 중력 성분)
          _friction = 0.3;
          _angle = math.atan(_friction) * 180 / math.pi;
          _mass = 2;
          break;
      }
      _reset();
    });
  }

  // 임계각 계산 (tanθ = μ)
  double get _criticalAngle => math.atan(_friction) * 180 / math.pi;

  // 가속도 계산
  double get _acceleration {
    final angleRad = _angle * math.pi / 180;
    final accel = _gravity * (math.sin(angleRad) - _friction * math.cos(angleRad));
    return accel > 0 ? accel : 0;
  }

  // 수직 항력
  double get _normalForce {
    final angleRad = _angle * math.pi / 180;
    return _mass * _gravity * math.cos(angleRad);
  }

  // 마찰력
  double get _frictionForce => _friction * _normalForce;

  // 중력 경사 성분
  double get _gravityComponent {
    final angleRad = _angle * math.pi / 180;
    return _mass * _gravity * math.sin(angleRad);
  }

  // 미끄러지는지 여부
  bool get _willSlide => _angle > _criticalAngle;

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
              '역학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '경사면 운동',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '역학',
          title: '경사면 운동',
          formula: 'a = g(sin\u03B8 - \u03BCcos\u03B8)',
          formulaDescription:
              '물체가 경사면을 따라 미끄러질 때의 가속도입니다. '
              '\u03B8는 경사각, \u03BC는 마찰계수, g는 중력가속도입니다. '
              '임계각(\u03B8c = arctan\u03BC)보다 경사가 클 때만 미끄러집니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: InclinedPlanePainter(
                angle: _angle,
                position: _position,
                friction: _friction,
                isRunning: _isRunning,
                willSlide: _willSlide,
                normalForce: _normalForce,
                frictionForce: _frictionForce,
                gravityComponent: _gravityComponent,
                mass: _mass,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋
              PresetGroup(
                label: '경사면 프리셋',
                presets: [
                  PresetButton(
                    label: '매끄러움',
                    isSelected: _selectedPreset == 'smooth',
                    onPressed: () => _applyPreset('smooth'),
                  ),
                  PresetButton(
                    label: '거친 면',
                    isSelected: _selectedPreset == 'rough',
                    onPressed: () => _applyPreset('rough'),
                  ),
                  PresetButton(
                    label: '급경사',
                    isSelected: _selectedPreset == 'steep',
                    onPressed: () => _applyPreset('steep'),
                  ),
                  PresetButton(
                    label: '완경사',
                    isSelected: _selectedPreset == 'gentle',
                    onPressed: () => _applyPreset('gentle'),
                  ),
                  PresetButton(
                    label: '임계각',
                    isSelected: _selectedPreset == 'critical',
                    onPressed: () => _applyPreset('critical'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 물리량 정보
              _PhysicsInfo(
                angle: _angle,
                criticalAngle: _criticalAngle,
                acceleration: _acceleration,
                velocity: _velocity,
                willSlide: _willSlide,
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '경사각 (\u03B8)',
                  value: _angle,
                  min: 5,
                  max: 80,
                  defaultValue: _defaultAngle,
                  formatValue: (v) => '${v.toStringAsFixed(1)}\u00B0',
                  onChanged: (v) {
                    setState(() {
                      _angle = v;
                      _selectedPreset = null;
                    });
                    if (!_isRunning) _reset();
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '마찰계수 (\u03BC)',
                    value: _friction,
                    min: 0,
                    max: 1,
                    step: 0.01,
                    defaultValue: _defaultFriction,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) {
                      setState(() {
                        _friction = v;
                        _selectedPreset = null;
                      });
                      if (!_isRunning) _reset();
                    },
                  ),
                  SimSlider(
                    label: '질량 (m)',
                    value: _mass,
                    min: 0.5,
                    max: 10,
                    step: 0.1,
                    defaultValue: _defaultMass,
                    formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                    onChanged: (v) {
                      setState(() {
                        _mass = v;
                        _selectedPreset = null;
                      });
                    },
                  ),
                  SimSlider(
                    label: '중력가속도 (g)',
                    value: _gravity,
                    min: 1,
                    max: 25,
                    step: 0.1,
                    defaultValue: _defaultGravity,
                    formatValue: (v) => '${v.toStringAsFixed(1)} m/s\u00B2',
                    onChanged: (v) {
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
                label: _isRunning ? '정지' : '시작',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _start,
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

/// 물리량 정보 위젯
class _PhysicsInfo extends StatelessWidget {
  final double angle;
  final double criticalAngle;
  final double acceleration;
  final double velocity;
  final bool willSlide;

  const _PhysicsInfo({
    required this.angle,
    required this.criticalAngle,
    required this.acceleration,
    required this.velocity,
    required this.willSlide,
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
              _InfoItem(
                label: '현재 각도',
                value: '${angle.toStringAsFixed(1)}\u00B0',
                color: AppColors.accent,
              ),
              _InfoItem(
                label: '임계각',
                value: '${criticalAngle.toStringAsFixed(1)}\u00B0',
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: '상태',
                value: willSlide ? '미끄러짐' : '정지',
                color: willSlide ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: '가속도',
                value: '${acceleration.toStringAsFixed(2)} m/s\u00B2',
                color: AppColors.accent,
              ),
              _InfoItem(
                label: '속도',
                value: '${velocity.toStringAsFixed(2)} m/s',
                color: AppColors.accent2,
              ),
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
  final Color color;

  const _InfoItem({
    required this.label,
    required this.value,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
            ),
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

/// 경사면 페인터
class InclinedPlanePainter extends CustomPainter {
  final double angle;
  final double position;
  final double friction;
  final bool isRunning;
  final bool willSlide;
  final double normalForce;
  final double frictionForce;
  final double gravityComponent;
  final double mass;

  InclinedPlanePainter({
    required this.angle,
    required this.position,
    required this.friction,
    required this.isRunning,
    required this.willSlide,
    required this.normalForce,
    required this.frictionForce,
    required this.gravityComponent,
    required this.mass,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // 그리드
    _drawGrid(canvas, size);

    final angleRad = angle * math.pi / 180;
    final centerX = size.width / 2;
    final baseY = size.height - 60;

    // 경사면 크기
    final planeLength = size.width * 0.7;
    final planeHeight = planeLength * math.sin(angleRad);
    final planeBase = planeLength * math.cos(angleRad);

    // 경사면 꼭짓점
    final topLeft = Offset(centerX - planeBase / 2, baseY - planeHeight);
    final bottomLeft = Offset(centerX - planeBase / 2, baseY);
    final bottomRight = Offset(centerX + planeBase / 2, baseY);

    // 경사면 그리기
    final planePath = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..close();

    // 경사면 그림자
    canvas.drawPath(
      planePath.shift(const Offset(4, 4)),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // 경사면 채우기 (마찰 표시)
    final surfaceColor = friction < 0.2
        ? const Color(0xFF2B5278)
        : friction < 0.5
            ? const Color(0xFF4A5D6A)
            : const Color(0xFF6A5D4A);
    canvas.drawPath(planePath, Paint()..color = surfaceColor);

    // 경사면 테두리
    canvas.drawPath(
      planePath,
      Paint()
        ..color = AppColors.muted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 바닥선
    canvas.drawLine(
      Offset(0, baseY),
      Offset(size.width, baseY),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2,
    );

    // 블록 위치 계산
    final blockProgress = position;
    final blockX = topLeft.dx + blockProgress * (bottomRight.dx - topLeft.dx);
    final blockY = topLeft.dy + blockProgress * (bottomRight.dy - topLeft.dy);

    // 블록 그리기
    _drawBlock(canvas, Offset(blockX, blockY), angleRad);

    // 힘 벡터 그리기
    _drawForceVectors(canvas, Offset(blockX, blockY), angleRad);

    // 각도 표시
    _drawAngleArc(canvas, bottomRight, angleRad);

    // 정보 텍스트
    _drawInfoText(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawBlock(Canvas canvas, Offset position, double angleRad) {
    const blockSize = 40.0;

    canvas.save();
    canvas.translate(position.dx, position.dy - blockSize / 2);
    canvas.rotate(-angleRad);

    // 블록 그림자
    canvas.drawRect(
      Rect.fromCenter(
        center: const Offset(3, 3),
        width: blockSize,
        height: blockSize,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // 블록 본체
    final blockGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: willSlide
          ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
          : [const Color(0xFFFF9800), const Color(0xFFE65100)],
    ).createShader(
      Rect.fromCenter(center: Offset.zero, width: blockSize, height: blockSize),
    );

    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: blockSize, height: blockSize),
      Paint()..shader = blockGradient,
    );

    // 블록 테두리
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: blockSize, height: blockSize),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 질량 표시
    _drawText(
      canvas,
      '${mass.toStringAsFixed(1)}kg',
      const Offset(-16, -6),
      color: Colors.white,
      fontSize: 10,
    );

    canvas.restore();
  }

  void _drawForceVectors(Canvas canvas, Offset blockPos, double angleRad) {
    final scale = 1.5; // 힘 벡터 스케일

    // 중력 (아래 방향)
    final gravityLength = mass * 9.8 * scale;
    _drawArrow(
      canvas,
      blockPos,
      Offset(blockPos.dx, blockPos.dy + gravityLength),
      Colors.yellow,
      'mg',
    );

    // 수직 항력 (경사면에 수직)
    final normalLength = normalForce * scale;
    final normalEnd = Offset(
      blockPos.dx - normalLength * math.sin(angleRad),
      blockPos.dy - normalLength * math.cos(angleRad),
    );
    _drawArrow(canvas, blockPos, normalEnd, Colors.blue, 'N');

    // 마찰력 (경사면 위 방향)
    if (willSlide && frictionForce > 0) {
      final frictionLength = frictionForce * scale;
      final frictionEnd = Offset(
        blockPos.dx - frictionLength * math.cos(angleRad),
        blockPos.dy + frictionLength * math.sin(angleRad),
      );
      _drawArrow(canvas, blockPos, frictionEnd, Colors.red, 'f');
    }

    // 중력의 경사 성분 (경사면 아래 방향)
    if (gravityComponent > 0) {
      final gravCompLength = gravityComponent * scale;
      final gravCompEnd = Offset(
        blockPos.dx + gravCompLength * math.cos(angleRad),
        blockPos.dy - gravCompLength * math.sin(angleRad),
      );
      _drawArrow(canvas, blockPos, gravCompEnd, Colors.green, 'mg sin\u03B8');
    }
  }

  void _drawArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    String label,
  ) {
    final arrowPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, arrowPaint);

    // 화살표 머리
    final arrowAngle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowHeadLength = 10.0;
    const arrowHeadAngle = 0.5;

    canvas.drawLine(
      end,
      end -
          Offset(
            arrowHeadLength * math.cos(arrowAngle - arrowHeadAngle),
            arrowHeadLength * math.sin(arrowAngle - arrowHeadAngle),
          ),
      arrowPaint,
    );
    canvas.drawLine(
      end,
      end -
          Offset(
            arrowHeadLength * math.cos(arrowAngle + arrowHeadAngle),
            arrowHeadLength * math.sin(arrowAngle + arrowHeadAngle),
          ),
      arrowPaint,
    );

    // 라벨
    final labelOffset = Offset(
      end.dx + 8 * math.cos(arrowAngle + math.pi / 2),
      end.dy + 8 * math.sin(arrowAngle + math.pi / 2),
    );
    _drawText(canvas, label, labelOffset, color: color, fontSize: 9);
  }

  void _drawAngleArc(Canvas canvas, Offset corner, double angleRad) {
    const arcRadius = 40.0;

    // 각도 호
    canvas.drawArc(
      Rect.fromCircle(center: corner, radius: arcRadius),
      -math.pi,
      angleRad,
      false,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 각도 텍스트
    final textAngle = -math.pi + angleRad / 2;
    final textPos = Offset(
      corner.dx + (arcRadius + 15) * math.cos(textAngle),
      corner.dy + (arcRadius + 15) * math.sin(textAngle),
    );
    _drawText(canvas, '${angle.toStringAsFixed(0)}\u00B0', textPos,
        color: AppColors.accent);
  }

  void _drawInfoText(Canvas canvas, Size size) {
    _drawText(
      canvas,
      willSlide ? '미끄러지는 중...' : '\u03B8 < \u03B8c: 정지 상태',
      Offset(size.width / 2 - 40, 20),
      color: willSlide ? Colors.green : Colors.orange,
      fontSize: 12,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position, {
    Color color = AppColors.muted,
    double fontSize = 11,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant InclinedPlanePainter oldDelegate) => true;
}
