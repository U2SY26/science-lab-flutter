import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 시간 지연 시뮬레이션 화면 (Time Dilation)
/// 특수 상대성 이론의 시간 지연 효과를 시각화합니다.
class TimeDilationScreen extends StatefulWidget {
  const TimeDilationScreen({super.key});

  @override
  State<TimeDilationScreen> createState() => _TimeDilationScreenState();
}

class _TimeDilationScreenState extends State<TimeDilationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 물리 파라미터
  static const double _defaultVelocity = 0.0; // c의 비율 (0 ~ 0.99c)
  static const double _speedOfLight = 299792458; // m/s

  double velocity = _defaultVelocity; // v/c 비율
  bool isRunning = true;

  // 시간 추적
  double stationaryTime = 0; // 정지 관찰자의 시간 (초)
  double movingTime = 0; // 이동하는 관찰자의 시간 (초)

  // 시계 각도
  double stationaryClockAngle = 0;
  double movingClockAngle = 0;

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
      // 시간 증가 (60fps 기준, 실제 1초 = 시뮬레이션 1초)
      const dt = 1 / 60;
      stationaryTime += dt;

      // 로렌츠 인자 계산: gamma = 1 / sqrt(1 - v^2/c^2)
      final gamma = _calculateLorentzFactor(velocity);

      // 이동하는 관찰자의 시간은 더 느리게 흐름
      // t' = t / gamma (이동 관찰자 입장에서 더 적은 시간이 흐름)
      movingTime += dt / gamma;

      // 시계 바늘 회전 (초침: 60초에 한 바퀴)
      stationaryClockAngle = (stationaryTime % 60) / 60 * 2 * math.pi;
      movingClockAngle = (movingTime % 60) / 60 * 2 * math.pi;
    });
  }

  double _calculateLorentzFactor(double v) {
    // gamma = 1 / sqrt(1 - v^2/c^2)
    // v는 c의 비율 (0 ~ 1)
    if (v >= 1) return double.infinity;
    return 1 / math.sqrt(1 - v * v);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      stationaryTime = 0;
      movingTime = 0;
      stationaryClockAngle = 0;
      movingClockAngle = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 로렌츠 인자
  double get lorentzFactor => _calculateLorentzFactor(velocity);

  // 실제 속도 (km/s)
  double get actualVelocityKmS => velocity * _speedOfLight / 1000;

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
              '상대성 이론',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '시간 지연 (Time Dilation)',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성 이론',
          title: '시간 지연 (Time Dilation)',
          formula: "t' = t / sqrt(1 - v^2/c^2)",
          formulaDescription:
              '빠르게 움직이는 물체의 시간은 정지한 관찰자에 비해 느리게 흐릅니다. '
              '속도가 광속에 가까워질수록 시간 지연 효과가 커집니다. '
              'gamma(로렌츠 인자)가 클수록 시간이 더 느리게 흐릅니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: TimeDilationPainter(
                velocity: velocity,
                stationaryClockAngle: stationaryClockAngle,
                movingClockAngle: movingClockAngle,
                lorentzFactor: lorentzFactor,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 속도 프리셋
              PresetGroup(
                label: '속도 프리셋',
                presets: [
                  PresetButton(
                    label: '정지',
                    isSelected: velocity == 0,
                    onPressed: () => setState(() => velocity = 0),
                  ),
                  PresetButton(
                    label: '0.5c',
                    isSelected: velocity == 0.5,
                    onPressed: () => setState(() => velocity = 0.5),
                  ),
                  PresetButton(
                    label: '0.8c',
                    isSelected: velocity == 0.8,
                    onPressed: () => setState(() => velocity = 0.8),
                  ),
                  PresetButton(
                    label: '0.9c',
                    isSelected: velocity == 0.9,
                    onPressed: () => setState(() => velocity = 0.9),
                  ),
                  PresetButton(
                    label: '0.99c',
                    isSelected: velocity == 0.99,
                    onPressed: () => setState(() => velocity = 0.99),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 속도 슬라이더
              SimSlider(
                label: '속도 (v/c)',
                value: velocity,
                min: 0,
                max: 0.99,
                step: 0.01,
                defaultValue: _defaultVelocity,
                formatValue: (v) => '${(v * 100).toStringAsFixed(0)}% c',
                onChanged: (v) => setState(() => velocity = v),
              ),
              const SizedBox(height: 12),
              // 물리량 표시
              _PhysicsInfo(
                lorentzFactor: lorentzFactor,
                stationaryTime: stationaryTime,
                movingTime: movingTime,
                velocity: velocity,
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
  final double lorentzFactor;
  final double stationaryTime;
  final double movingTime;
  final double velocity;

  const _PhysicsInfo({
    required this.lorentzFactor,
    required this.stationaryTime,
    required this.movingTime,
    required this.velocity,
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
                label: '로렌츠 인자 (gamma)',
                value: lorentzFactor.toStringAsFixed(3),
              ),
              _InfoItem(
                label: '속도',
                value: '${(velocity * 299792).toStringAsFixed(0)} km/s',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: '정지 관찰자 시간',
                value: '${stationaryTime.toStringAsFixed(1)}s',
              ),
              _InfoItem(
                label: '이동 관찰자 시간',
                value: '${movingTime.toStringAsFixed(1)}s',
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

  const _InfoItem({required this.label, required this.value});

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
            style: const TextStyle(
              color: AppColors.accent,
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

/// 시간 지연 시뮬레이션 페인터
class TimeDilationPainter extends CustomPainter {
  final double velocity;
  final double stationaryClockAngle;
  final double movingClockAngle;
  final double lorentzFactor;

  TimeDilationPainter({
    required this.velocity,
    required this.stationaryClockAngle,
    required this.movingClockAngle,
    required this.lorentzFactor,
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

    // 두 시계 그리기
    final clockRadius = size.width * 0.15;
    final leftClockCenter = Offset(size.width * 0.28, size.height * 0.45);
    final rightClockCenter = Offset(size.width * 0.72, size.height * 0.45);

    // 정지한 관찰자의 시계 (왼쪽)
    _drawClock(
      canvas,
      leftClockCenter,
      clockRadius,
      stationaryClockAngle,
      '정지 관찰자',
      'Stationary Observer',
      AppColors.accent,
    );

    // 이동하는 관찰자의 시계 (오른쪽)
    _drawClock(
      canvas,
      rightClockCenter,
      clockRadius,
      movingClockAngle,
      '이동 관찰자',
      'Moving Observer',
      AppColors.accent2,
    );

    // 속도 표시 (우주선 애니메이션)
    if (velocity > 0) {
      _drawSpaceship(canvas, size, rightClockCenter);
    }

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

  void _drawClock(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    String labelKo,
    String labelEn,
    Color accentColor,
  ) {
    // 시계 배경
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = AppColors.card,
    );

    // 시계 테두리
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = accentColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 시계 눈금
    for (int i = 0; i < 12; i++) {
      final tickAngle = i * math.pi / 6 - math.pi / 2;
      final innerRadius = radius * 0.85;
      final outerRadius = radius * 0.95;
      final start = center + Offset(
        innerRadius * math.cos(tickAngle),
        innerRadius * math.sin(tickAngle),
      );
      final end = center + Offset(
        outerRadius * math.cos(tickAngle),
        outerRadius * math.sin(tickAngle),
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.5)
          ..strokeWidth = 2,
      );
    }

    // 초침
    final handLength = radius * 0.7;
    final handEnd = center + Offset(
      handLength * math.sin(angle),
      -handLength * math.cos(angle),
    );
    canvas.drawLine(
      center,
      handEnd,
      Paint()
        ..color = accentColor
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // 중심점
    canvas.drawCircle(
      center,
      5,
      Paint()..color = accentColor,
    );

    // 라벨 (한국어)
    final textPainterKo = TextPainter(
      text: TextSpan(
        text: labelKo,
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterKo.paint(
      canvas,
      center + Offset(-textPainterKo.width / 2, radius + 15),
    );

    // 라벨 (영어)
    final textPainterEn = TextPainter(
      text: TextSpan(
        text: labelEn,
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainterEn.paint(
      canvas,
      center + Offset(-textPainterEn.width / 2, radius + 32),
    );
  }

  void _drawSpaceship(Canvas canvas, Size size, Offset clockCenter) {
    // 속도에 비례하는 화살표 길이
    final arrowLength = 40 + velocity * 80;
    final arrowMid = Offset(clockCenter.dx, clockCenter.dy - 100);

    // 화살표 몸체
    canvas.drawLine(
      Offset(arrowMid.dx - arrowLength / 2, arrowMid.dy),
      Offset(arrowMid.dx + arrowLength / 2, arrowMid.dy),
      Paint()
        ..color = AppColors.accent2
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // 화살표 머리
    final arrowHeadPath = Path()
      ..moveTo(arrowMid.dx + arrowLength / 2 + 10, arrowMid.dy)
      ..lineTo(arrowMid.dx + arrowLength / 2 - 5, arrowMid.dy - 8)
      ..lineTo(arrowMid.dx + arrowLength / 2 - 5, arrowMid.dy + 8)
      ..close();
    canvas.drawPath(arrowHeadPath, Paint()..color = AppColors.accent2);

    // 속도 텍스트
    final velocityText = '${(velocity * 100).toStringAsFixed(0)}% c';
    final textPainter = TextPainter(
      text: TextSpan(
        text: velocityText,
        style: TextStyle(
          color: AppColors.accent2,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(arrowMid.dx - textPainter.width / 2, arrowMid.dy - 25),
    );
  }

  void _drawFormula(Canvas canvas, Size size) {
    // 하단에 수식 표시
    final formulaText = 'gamma = ${lorentzFactor.toStringAsFixed(3)}';
    final textPainter = TextPainter(
      text: TextSpan(
        text: formulaText,
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height - 40),
    );
  }

  @override
  bool shouldRepaint(covariant TimeDilationPainter oldDelegate) => true;
}
