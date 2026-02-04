import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 지레 시뮬레이션 화면
class LeverScreen extends StatefulWidget {
  const LeverScreen({super.key});

  @override
  State<LeverScreen> createState() => _LeverScreenState();
}

class _LeverScreenState extends State<LeverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 기본값
  static const double _defaultForce1 = 100; // 힘1 (N)
  static const double _defaultDistance1 = 2; // 거리1 (m)
  static const double _defaultForce2 = 50; // 힘2 (N)
  static const double _defaultDistance2 = 4; // 거리2 (m)

  // 파라미터
  double _force1 = _defaultForce1;
  double _distance1 = _defaultDistance1;
  double _force2 = _defaultForce2;
  double _distance2 = _defaultDistance2;
  bool _isRunning = true;

  // 물리 상태
  double _angle = 0; // 지레 기울기 (라디안)
  double _angularVelocity = 0;

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
      const damping = 0.95;
      const momentOfInertia = 100.0; // 관성 모멘트

      // 토크 계산: τ = F × d
      final torque1 = _force1 * _distance1; // 시계 방향 (양수)
      final torque2 = _force2 * _distance2; // 반시계 방향 (음수)

      // 순 토크
      final netTorque = torque1 - torque2;

      // 각가속도
      final angularAcceleration = netTorque / momentOfInertia;

      // 각속도와 각도 업데이트
      _angularVelocity += angularAcceleration * dt * 0.01;
      _angularVelocity *= damping;
      _angle += _angularVelocity * dt;

      // 각도 제한 (-30도 ~ 30도)
      const maxAngle = math.pi / 6;
      if (_angle > maxAngle) {
        _angle = maxAngle;
        _angularVelocity = 0;
      } else if (_angle < -maxAngle) {
        _angle = -maxAngle;
        _angularVelocity = 0;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _angle = 0;
      _angularVelocity = 0;
    });
  }

  void _balance() {
    HapticFeedback.lightImpact();
    setState(() {
      // F1 × d1 = F2 × d2 를 만족하도록 F2 조정
      _force2 = (_force1 * _distance1) / _distance2;
      _selectedPreset = null;
    });
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'balanced':
          _force1 = 100;
          _distance1 = 2;
          _force2 = 100;
          _distance2 = 2;
          break;
        case 'seesaw':
          _force1 = 400; // 무거운 사람
          _distance1 = 1;
          _force2 = 200; // 가벼운 사람
          _distance2 = 2;
          break;
        case 'crowbar':
          _force1 = 50; // 작은 힘
          _distance1 = 5; // 긴 팔
          _force2 = 250; // 큰 저항
          _distance2 = 1; // 짧은 팔
          break;
        case 'wheelbarrow':
          _force1 = 100;
          _distance1 = 1;
          _force2 = 200;
          _distance2 = 0.5;
          break;
        case 'unbalanced':
          _force1 = 150;
          _distance1 = 3;
          _force2 = 50;
          _distance2 = 2;
          break;
      }
      _reset();
    });
  }

  // 토크 계산
  double get _torque1 => _force1 * _distance1;
  double get _torque2 => _force2 * _distance2;
  double get _netTorque => _torque1 - _torque2;

  // 평형 상태 확인
  bool get _isBalanced => (_torque1 - _torque2).abs() < 0.1;

  // 기계적 이득
  double get _mechanicalAdvantage => _distance1 / _distance2;

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
              '지레의 원리',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '역학',
          title: '지레의 원리',
          formula: 'F\u2081 \u00D7 d\u2081 = F\u2082 \u00D7 d\u2082',
          formulaDescription:
              '지레가 평형을 이루려면 양쪽의 토크(힘 \u00D7 거리)가 같아야 합니다. '
              '받침점에서 멀수록 작은 힘으로 큰 저항을 극복할 수 있습니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: LeverPainter(
                angle: _angle,
                force1: _force1,
                distance1: _distance1,
                force2: _force2,
                distance2: _distance2,
                isBalanced: _isBalanced,
                torque1: _torque1,
                torque2: _torque2,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋
              PresetGroup(
                label: '지레 프리셋',
                presets: [
                  PresetButton(
                    label: '평형',
                    isSelected: _selectedPreset == 'balanced',
                    onPressed: () => _applyPreset('balanced'),
                  ),
                  PresetButton(
                    label: '시소',
                    isSelected: _selectedPreset == 'seesaw',
                    onPressed: () => _applyPreset('seesaw'),
                  ),
                  PresetButton(
                    label: '지렛대',
                    isSelected: _selectedPreset == 'crowbar',
                    onPressed: () => _applyPreset('crowbar'),
                  ),
                  PresetButton(
                    label: '외바퀴 수레',
                    isSelected: _selectedPreset == 'wheelbarrow',
                    onPressed: () => _applyPreset('wheelbarrow'),
                  ),
                  PresetButton(
                    label: '불균형',
                    isSelected: _selectedPreset == 'unbalanced',
                    onPressed: () => _applyPreset('unbalanced'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 물리량 정보
              _PhysicsInfo(
                torque1: _torque1,
                torque2: _torque2,
                netTorque: _netTorque,
                isBalanced: _isBalanced,
                mechanicalAdvantage: _mechanicalAdvantage,
                angle: _angle,
              ),
              const SizedBox(height: 16),
              // 왼쪽 컨트롤
              Text(
                '왼쪽 (힘점)',
                style: TextStyle(
                  color: AppColors.accent2,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SimSlider(
                label: '힘 F\u2081',
                value: _force1,
                min: 10,
                max: 500,
                defaultValue: _defaultForce1,
                formatValue: (v) => '${v.toStringAsFixed(0)} N',
                onChanged: (v) {
                  setState(() {
                    _force1 = v;
                    _selectedPreset = null;
                  });
                },
              ),
              SimSlider(
                label: '거리 d\u2081',
                value: _distance1,
                min: 0.5,
                max: 5,
                step: 0.1,
                defaultValue: _defaultDistance1,
                formatValue: (v) => '${v.toStringAsFixed(1)} m',
                onChanged: (v) {
                  setState(() {
                    _distance1 = v;
                    _selectedPreset = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              // 오른쪽 컨트롤
              Text(
                '오른쪽 (작용점)',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SimSlider(
                label: '힘 F\u2082',
                value: _force2,
                min: 10,
                max: 500,
                defaultValue: _defaultForce2,
                formatValue: (v) => '${v.toStringAsFixed(0)} N',
                onChanged: (v) {
                  setState(() {
                    _force2 = v;
                    _selectedPreset = null;
                  });
                },
              ),
              SimSlider(
                label: '거리 d\u2082',
                value: _distance2,
                min: 0.5,
                max: 5,
                step: 0.1,
                defaultValue: _defaultDistance2,
                formatValue: (v) => '${v.toStringAsFixed(1)} m',
                onChanged: (v) {
                  setState(() {
                    _distance2 = v;
                    _selectedPreset = null;
                  });
                },
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
                  HapticFeedback.selectionClick();
                  setState(() => _isRunning = !_isRunning);
                },
              ),
              SimButton(
                label: '균형 맞추기',
                icon: Icons.balance,
                onPressed: _balance,
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
  final double torque1;
  final double torque2;
  final double netTorque;
  final bool isBalanced;
  final double mechanicalAdvantage;
  final double angle;

  const _PhysicsInfo({
    required this.torque1,
    required this.torque2,
    required this.netTorque,
    required this.isBalanced,
    required this.mechanicalAdvantage,
    required this.angle,
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
                label: '\u03C4\u2081 (왼쪽 토크)',
                value: '${torque1.toStringAsFixed(0)} N\u00B7m',
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: '\u03C4\u2082 (오른쪽 토크)',
                value: '${torque2.toStringAsFixed(0)} N\u00B7m',
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: '순 토크',
                value: '${netTorque.toStringAsFixed(0)} N\u00B7m',
                color: netTorque.abs() < 0.1 ? Colors.green : Colors.orange,
              ),
              _InfoItem(
                label: '상태',
                value: isBalanced ? '평형' : (netTorque > 0 ? '왼쪽 하강' : '오른쪽 하강'),
                color: isBalanced ? Colors.green : Colors.orange,
              ),
              _InfoItem(
                label: '기계적 이득',
                value: mechanicalAdvantage.toStringAsFixed(2),
                color: AppColors.accent,
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
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 지레 페인터
class LeverPainter extends CustomPainter {
  final double angle;
  final double force1;
  final double distance1;
  final double force2;
  final double distance2;
  final bool isBalanced;
  final double torque1;
  final double torque2;

  LeverPainter({
    required this.angle,
    required this.force1,
    required this.distance1,
    required this.force2,
    required this.distance2,
    required this.isBalanced,
    required this.torque1,
    required this.torque2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // 그리드
    _drawGrid(canvas, size);

    final centerX = size.width / 2;
    final centerY = size.height * 0.55;
    final leverLength = size.width * 0.8;
    final maxDistance = math.max(distance1, distance2);
    final scale = (leverLength / 2) / maxDistance;

    // 받침점 (삼각형)
    _drawFulcrum(canvas, Offset(centerX, centerY));

    // 지레 막대 그리기
    canvas.save();
    canvas.translate(centerX, centerY - 15);
    canvas.rotate(angle);

    // 지레 막대
    final leverPaint = Paint()
      ..color = const Color(0xFF8B7355)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final leftEnd = Offset(-leverLength / 2, 0);
    final rightEnd = Offset(leverLength / 2, 0);
    canvas.drawLine(leftEnd, rightEnd, leverPaint);

    // 막대 하이라이트
    canvas.drawLine(
      Offset(leftEnd.dx, -3),
      Offset(rightEnd.dx, -3),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 2,
    );

    // 왼쪽 무게추 (힘점)
    final leftWeightX = -distance1 * scale;
    _drawWeight(canvas, Offset(leftWeightX, 0), force1, AppColors.accent2, 'F\u2081');

    // 오른쪽 무게추 (작용점)
    final rightWeightX = distance2 * scale;
    _drawWeight(canvas, Offset(rightWeightX, 0), force2, AppColors.accent, 'F\u2082');

    // 거리 표시
    _drawDistanceMarker(canvas, Offset.zero, Offset(leftWeightX, 0), 'd\u2081', true);
    _drawDistanceMarker(canvas, Offset.zero, Offset(rightWeightX, 0), 'd\u2082', false);

    canvas.restore();

    // 토크 화살표
    _drawTorqueIndicator(canvas, size, centerX, centerY);

    // 상태 표시
    _drawStatusText(canvas, size);

    // 수식 표시
    _drawFormula(canvas, size);
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

  void _drawFulcrum(Canvas canvas, Offset position) {
    final path = Path()
      ..moveTo(position.dx, position.dy)
      ..lineTo(position.dx - 25, position.dy + 40)
      ..lineTo(position.dx + 25, position.dy + 40)
      ..close();

    // 그림자
    canvas.drawPath(
      path.shift(const Offset(3, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // 받침점 본체
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF607D8B),
        const Color(0xFF37474F),
      ],
    ).createShader(Rect.fromLTWH(position.dx - 25, position.dy, 50, 40));

    canvas.drawPath(path, Paint()..shader = gradient);

    // 테두리
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 라벨
    _drawText(
      canvas,
      '받침점',
      Offset(position.dx - 15, position.dy + 45),
      color: AppColors.muted,
      fontSize: 10,
    );
  }

  void _drawWeight(Canvas canvas, Offset position, double force, Color color, String label) {
    final weightSize = 20 + force * 0.08; // 힘에 비례한 크기

    // 연결선
    canvas.drawLine(
      position,
      Offset(position.dx, position.dy + 30),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2,
    );

    // 무게추 그림자
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(position.dx + 3, position.dy + 30 + weightSize / 2 + 3),
          width: weightSize,
          height: weightSize,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // 무게추 본체
    final weightGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color,
        HSLColor.fromColor(color).withLightness(0.3).toColor(),
      ],
    ).createShader(Rect.fromCenter(
      center: Offset(position.dx, position.dy + 30 + weightSize / 2),
      width: weightSize,
      height: weightSize,
    ));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(position.dx, position.dy + 30 + weightSize / 2),
          width: weightSize,
          height: weightSize,
        ),
        const Radius.circular(4),
      ),
      Paint()..shader = weightGradient,
    );

    // 힘 표시
    _drawText(
      canvas,
      label,
      Offset(position.dx - 8, position.dy + 25 + weightSize / 2),
      color: Colors.white,
      fontSize: 11,
    );

    // 힘 값
    _drawText(
      canvas,
      '${force.toStringAsFixed(0)}N',
      Offset(position.dx - 12, position.dy + 40 + weightSize),
      color: color,
      fontSize: 9,
    );
  }

  void _drawDistanceMarker(Canvas canvas, Offset from, Offset to, String label, bool isLeft) {
    final markerY = -25.0;

    // 거리선
    canvas.drawLine(
      Offset(from.dx, markerY),
      Offset(to.dx, markerY),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // 양쪽 끝 표시
    canvas.drawLine(
      Offset(from.dx, markerY - 5),
      Offset(from.dx, markerY + 5),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(to.dx, markerY - 5),
      Offset(to.dx, markerY + 5),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 1,
    );

    // 라벨
    final labelX = (from.dx + to.dx) / 2 - 8;
    _drawText(
      canvas,
      label,
      Offset(labelX, markerY - 15),
      color: isLeft ? AppColors.accent2 : AppColors.accent,
      fontSize: 10,
    );
  }

  void _drawTorqueIndicator(Canvas canvas, Size size, double centerX, double centerY) {
    final radius = 35.0;
    final startAngle = -math.pi / 2;

    // 왼쪽 토크 (시계방향)
    if (torque1 > 0) {
      final sweepAngle = (torque1 / 500).clamp(0.0, math.pi / 2);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY - 15), radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = AppColors.accent2.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // 오른쪽 토크 (반시계방향)
    if (torque2 > 0) {
      final sweepAngle = -(torque2 / 500).clamp(0.0, math.pi / 2);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY - 15), radius: radius),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  void _drawStatusText(Canvas canvas, Size size) {
    String status;
    Color statusColor;

    if (isBalanced) {
      status = '\u2713 평형 상태: \u03C4\u2081 = \u03C4\u2082';
      statusColor = Colors.green;
    } else if (torque1 > torque2) {
      status = '\u2192 왼쪽이 더 무거움 (\u03C4\u2081 > \u03C4\u2082)';
      statusColor = AppColors.accent2;
    } else {
      status = '\u2190 오른쪽이 더 무거움 (\u03C4\u2082 > \u03C4\u2081)';
      statusColor = AppColors.accent;
    }

    _drawText(
      canvas,
      status,
      Offset(size.width / 2 - 80, 15),
      color: statusColor,
      fontSize: 12,
    );
  }

  void _drawFormula(Canvas canvas, Size size) {
    final formula =
        '${force1.toStringAsFixed(0)} \u00D7 ${distance1.toStringAsFixed(1)} = ${torque1.toStringAsFixed(0)} N\u00B7m    |    '
        '${force2.toStringAsFixed(0)} \u00D7 ${distance2.toStringAsFixed(1)} = ${torque2.toStringAsFixed(0)} N\u00B7m';

    _drawText(
      canvas,
      formula,
      Offset(size.width / 2 - 130, size.height - 30),
      color: AppColors.muted,
      fontSize: 10,
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
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant LeverPainter oldDelegate) => true;
}
