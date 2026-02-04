import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 쌍둥이 역설 시뮬레이션 화면 (Twin Paradox)
/// 특수 상대성 이론의 쌍둥이 역설을 시각화합니다.
class TwinParadoxScreen extends StatefulWidget {
  const TwinParadoxScreen({super.key});

  @override
  State<TwinParadoxScreen> createState() => _TwinParadoxScreenState();
}

class _TwinParadoxScreenState extends State<TwinParadoxScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 물리 파라미터
  static const double _defaultVelocity = 0.8; // c의 비율
  static const double _defaultTravelYears = 10.0; // 지구 시간 기준 여행 년수

  double velocity = _defaultVelocity;
  double travelYears = _defaultTravelYears; // 지구 기준 왕복 여행 시간 (년)
  bool isRunning = false;
  bool journeyComplete = false;

  // 여행 상태
  double journeyProgress = 0; // 0 ~ 1 (여행 진행도)
  double earthTwinAge = 30; // 지구에 남은 쌍둥이 나이
  double spaceTwinAge = 30; // 우주 여행하는 쌍둥이 나이
  static const double startAge = 30; // 시작 나이

  // 우주선 위치
  double spaceshipX = 0;
  bool isOutbound = true; // 출발 중인지 귀환 중인지

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
    if (!isRunning || journeyComplete) return;

    setState(() {
      // 여행 진행 (실제 1초 = 시뮬레이션에서 1년)
      const dt = 1 / 60 / 2; // 60fps, 2초에 1년
      journeyProgress += dt / travelYears;

      if (journeyProgress >= 1) {
        journeyProgress = 1;
        journeyComplete = true;
        isRunning = false;
      }

      // 로렌츠 인자 계산
      final gamma = _calculateLorentzFactor(velocity);

      // 나이 계산
      earthTwinAge = startAge + journeyProgress * travelYears;
      // 우주 쌍둥이는 시간 지연으로 인해 더 적게 나이 먹음
      spaceTwinAge = startAge + journeyProgress * travelYears / gamma;

      // 우주선 위치 (왕복)
      if (journeyProgress < 0.5) {
        // 출발
        isOutbound = true;
        spaceshipX = journeyProgress * 2;
      } else {
        // 귀환
        isOutbound = false;
        spaceshipX = (1 - journeyProgress) * 2;
      }
    });
  }

  double _calculateLorentzFactor(double v) {
    if (v >= 1) return double.infinity;
    return 1 / math.sqrt(1 - v * v);
  }

  double get lorentzFactor => _calculateLorentzFactor(velocity);

  // 우주 쌍둥이의 경과 시간 (고유 시간)
  double get spaceTwinElapsedTime => travelYears / lorentzFactor;

  // 나이 차이
  double get ageDifference => travelYears - spaceTwinElapsedTime;

  void _startJourney() {
    HapticFeedback.mediumImpact();
    setState(() {
      isRunning = true;
      journeyComplete = false;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      journeyProgress = 0;
      earthTwinAge = startAge;
      spaceTwinAge = startAge;
      spaceshipX = 0;
      isOutbound = true;
      isRunning = false;
      journeyComplete = false;
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
              '상대성 이론',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '쌍둥이 역설 (Twin Paradox)',
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
          title: '쌍둥이 역설 (Twin Paradox)',
          formula: "Delta_t' = Delta_t / gamma",
          formulaDescription:
              '쌍둥이 중 한 명이 광속에 가까운 속도로 우주 여행을 하고 돌아오면, '
              '지구에 남아있던 쌍둥이보다 더 젊습니다. '
              '이는 특수 상대성 이론의 시간 지연 효과 때문입니다. '
              '여행하는 쌍둥이의 고유 시간이 더 적게 흐릅니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: TwinParadoxPainter(
                velocity: velocity,
                journeyProgress: journeyProgress,
                earthTwinAge: earthTwinAge,
                spaceTwinAge: spaceTwinAge,
                spaceshipX: spaceshipX,
                isOutbound: isOutbound,
                journeyComplete: journeyComplete,
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
                label: '우주선 속도',
                presets: [
                  PresetButton(
                    label: '0.5c',
                    isSelected: velocity == 0.5,
                    onPressed: () {
                      if (!isRunning) setState(() => velocity = 0.5);
                    },
                  ),
                  PresetButton(
                    label: '0.8c',
                    isSelected: velocity == 0.8,
                    onPressed: () {
                      if (!isRunning) setState(() => velocity = 0.8);
                    },
                  ),
                  PresetButton(
                    label: '0.9c',
                    isSelected: velocity == 0.9,
                    onPressed: () {
                      if (!isRunning) setState(() => velocity = 0.9);
                    },
                  ),
                  PresetButton(
                    label: '0.95c',
                    isSelected: velocity == 0.95,
                    onPressed: () {
                      if (!isRunning) setState(() => velocity = 0.95);
                    },
                  ),
                  PresetButton(
                    label: '0.99c',
                    isSelected: velocity == 0.99,
                    onPressed: () {
                      if (!isRunning) setState(() => velocity = 0.99);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 컨트롤 그룹
              ControlGroup(
                primaryControl: SimSlider(
                  label: '우주선 속도 (v/c)',
                  value: velocity,
                  min: 0.1,
                  max: 0.99,
                  step: 0.01,
                  defaultValue: _defaultVelocity,
                  formatValue: (v) => '${(v * 100).toStringAsFixed(0)}% c',
                  onChanged: isRunning
                      ? (_) {}
                      : (v) => setState(() => velocity = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '여행 시간 (지구 기준)',
                    value: travelYears,
                    min: 5,
                    max: 50,
                    step: 5,
                    defaultValue: _defaultTravelYears,
                    formatValue: (v) => '${v.toInt()}년',
                    onChanged: isRunning
                        ? (_) {}
                        : (v) => setState(() => travelYears = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 물리량 표시
              _PhysicsInfo(
                lorentzFactor: lorentzFactor,
                earthTwinAge: earthTwinAge,
                spaceTwinAge: spaceTwinAge,
                ageDifference: earthTwinAge - spaceTwinAge,
                journeyProgress: journeyProgress,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: journeyComplete
                    ? '여행 완료'
                    : (isRunning ? '여행 중...' : '여행 시작'),
                icon: journeyComplete
                    ? Icons.check_circle
                    : (isRunning ? Icons.rocket_launch : Icons.flight_takeoff),
                isPrimary: true,
                onPressed: journeyComplete || isRunning ? null : _startJourney,
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
  final double earthTwinAge;
  final double spaceTwinAge;
  final double ageDifference;
  final double journeyProgress;

  const _PhysicsInfo({
    required this.lorentzFactor,
    required this.earthTwinAge,
    required this.spaceTwinAge,
    required this.ageDifference,
    required this.journeyProgress,
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
                label: '여행 진행도',
                value: '${(journeyProgress * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: '지구 쌍둥이 나이',
                value: '${earthTwinAge.toStringAsFixed(1)}세',
                highlight: false,
              ),
              _InfoItem(
                label: '우주 쌍둥이 나이',
                value: '${spaceTwinAge.toStringAsFixed(1)}세',
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent2.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.accent2.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.accent2,
                ),
                const SizedBox(width: 8),
                Text(
                  '나이 차이: ${ageDifference.toStringAsFixed(1)}년',
                  style: TextStyle(
                    color: AppColors.accent2,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _InfoItem({
    required this.label,
    required this.value,
    this.highlight = false,
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
              color: highlight ? AppColors.accent2 : AppColors.accent,
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

/// 쌍둥이 역설 시뮬레이션 페인터
class TwinParadoxPainter extends CustomPainter {
  final double velocity;
  final double journeyProgress;
  final double earthTwinAge;
  final double spaceTwinAge;
  final double spaceshipX;
  final bool isOutbound;
  final bool journeyComplete;
  final double lorentzFactor;

  TwinParadoxPainter({
    required this.velocity,
    required this.journeyProgress,
    required this.earthTwinAge,
    required this.spaceTwinAge,
    required this.spaceshipX,
    required this.isOutbound,
    required this.journeyComplete,
    required this.lorentzFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경 (우주)
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    // 별 그리기
    _drawStars(canvas, size);

    // 지구 그리기
    _drawEarth(canvas, size);

    // 목적지 (별) 그리기
    _drawDestination(canvas, size);

    // 우주선 경로
    _drawPath(canvas, size);

    // 우주선 그리기
    if (!journeyComplete || spaceshipX > 0.01) {
      _drawSpaceship(canvas, size);
    }

    // 쌍둥이 그리기
    _drawTwins(canvas, size);

    // 정보 표시
    _drawInfo(canvas, size);
  }

  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42); // 고정 시드로 일관된 별 패턴
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  void _drawEarth(Canvas canvas, Size size) {
    final earthCenter = Offset(size.width * 0.15, size.height * 0.5);
    const earthRadius = 35.0;

    // 지구 본체
    final earthGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        const Color(0xFF4A90D9),
        const Color(0xFF1E5AA8),
        const Color(0xFF0D3A6E),
      ],
    ).createShader(Rect.fromCircle(center: earthCenter, radius: earthRadius));

    canvas.drawCircle(earthCenter, earthRadius, Paint()..shader = earthGradient);

    // 대륙 (간단한 표현)
    final landPaint = Paint()..color = const Color(0xFF2E8B57).withValues(alpha: 0.7);
    canvas.drawCircle(earthCenter + const Offset(-10, -5), 12, landPaint);
    canvas.drawCircle(earthCenter + const Offset(8, 10), 8, landPaint);

    // 테두리
    canvas.drawCircle(
      earthCenter,
      earthRadius,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 라벨
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '지구 (Earth)',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      earthCenter + Offset(-textPainter.width / 2, earthRadius + 10),
    );
  }

  void _drawDestination(Canvas canvas, Size size) {
    final destCenter = Offset(size.width * 0.85, size.height * 0.5);
    const destRadius = 20.0;

    // 목적지 별
    final starPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.yellow,
          Colors.orange,
          Colors.red.withValues(alpha: 0.5),
        ],
      ).createShader(Rect.fromCircle(center: destCenter, radius: destRadius));

    canvas.drawCircle(destCenter, destRadius, starPaint);

    // 광선 효과
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final start = destCenter + Offset(
        destRadius * math.cos(angle),
        destRadius * math.sin(angle),
      );
      final end = destCenter + Offset(
        (destRadius + 15) * math.cos(angle),
        (destRadius + 15) * math.sin(angle),
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Colors.yellow.withValues(alpha: 0.5)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // 라벨
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '목적지 (Destination)',
        style: TextStyle(
          color: AppColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      destCenter + Offset(-textPainter.width / 2, destRadius + 10),
    );
  }

  void _drawPath(Canvas canvas, Size size) {
    final startX = size.width * 0.15 + 40;
    final endX = size.width * 0.85 - 25;
    final y = size.height * 0.5;

    // 경로 라인 (점선)
    final pathPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 점선 효과
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    double distance = 0;
    final totalDistance = endX - startX;

    while (distance < totalDistance) {
      canvas.drawLine(
        Offset(startX + distance, y),
        Offset(startX + math.min(distance + dashWidth, totalDistance), y),
        pathPaint,
      );
      distance += dashWidth + dashSpace;
    }

    // 현재 진행된 경로 (실선)
    final progressX = startX + spaceshipX * (endX - startX);
    if (journeyProgress > 0) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(progressX, y),
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.5)
          ..strokeWidth = 2,
      );
    }
  }

  void _drawSpaceship(Canvas canvas, Size size) {
    final startX = size.width * 0.15 + 40;
    final endX = size.width * 0.85 - 25;
    final y = size.height * 0.5;

    final shipX = startX + spaceshipX * (endX - startX);
    final shipCenter = Offset(shipX, y - 30);

    // 우주선 본체
    final shipPath = Path();
    if (isOutbound) {
      // 오른쪽을 향함
      shipPath.moveTo(shipCenter.dx + 20, shipCenter.dy);
      shipPath.lineTo(shipCenter.dx - 15, shipCenter.dy - 10);
      shipPath.lineTo(shipCenter.dx - 15, shipCenter.dy + 10);
      shipPath.close();
    } else {
      // 왼쪽을 향함 (귀환)
      shipPath.moveTo(shipCenter.dx - 20, shipCenter.dy);
      shipPath.lineTo(shipCenter.dx + 15, shipCenter.dy - 10);
      shipPath.lineTo(shipCenter.dx + 15, shipCenter.dy + 10);
      shipPath.close();
    }

    // 우주선 그라데이션
    final shipGradient = LinearGradient(
      colors: [
        AppColors.accent,
        AppColors.accent.withValues(alpha: 0.6),
      ],
    ).createShader(Rect.fromCenter(center: shipCenter, width: 40, height: 20));

    canvas.drawPath(shipPath, Paint()..shader = shipGradient);
    canvas.drawPath(
      shipPath,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 엔진 불꽃
    if (journeyProgress > 0 && journeyProgress < 1) {
      final flameX = isOutbound ? shipCenter.dx - 20 : shipCenter.dx + 20;
      final flameDir = isOutbound ? -1.0 : 1.0;

      for (int i = 0; i < 3; i++) {
        final flameLength = 10.0 + i * 5;
        canvas.drawLine(
          Offset(flameX, shipCenter.dy),
          Offset(flameX + flameDir * flameLength, shipCenter.dy + (i - 1) * 3),
          Paint()
            ..color = Colors.orange.withValues(alpha: 0.8 - i * 0.2)
            ..strokeWidth = 3 - i * 0.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // 속도 표시
    final velocityText = '${(velocity * 100).toStringAsFixed(0)}% c';
    final textPainter = TextPainter(
      text: TextSpan(
        text: velocityText,
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(shipCenter.dx - textPainter.width / 2, shipCenter.dy - 25),
    );
  }

  void _drawTwins(Canvas canvas, Size size) {
    // 지구 쌍둥이 (지구 근처)
    _drawPerson(
      canvas,
      Offset(size.width * 0.15, size.height * 0.82),
      earthTwinAge,
      '지구 쌍둥이',
      AppColors.accent,
    );

    // 우주 쌍둥이 (우주선 또는 지구)
    final spaceX = journeyComplete
        ? size.width * 0.25
        : size.width * 0.15 + 40 + spaceshipX * (size.width * 0.7 - 65);
    _drawPerson(
      canvas,
      Offset(journeyComplete ? spaceX : size.width * 0.25, size.height * 0.82),
      spaceTwinAge,
      '우주 쌍둥이',
      AppColors.accent2,
    );
  }

  void _drawPerson(
    Canvas canvas,
    Offset position,
    double age,
    String label,
    Color color,
  ) {
    // 머리
    canvas.drawCircle(
      position + const Offset(0, -25),
      10,
      Paint()..color = color,
    );

    // 몸
    canvas.drawLine(
      position + const Offset(0, -15),
      position + const Offset(0, 5),
      Paint()
        ..color = color
        ..strokeWidth = 3,
    );

    // 팔
    canvas.drawLine(
      position + const Offset(-12, -10),
      position + const Offset(12, -10),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );

    // 다리
    canvas.drawLine(
      position + const Offset(0, 5),
      position + const Offset(-8, 20),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      position + const Offset(0, 5),
      position + const Offset(8, 20),
      Paint()
        ..color = color
        ..strokeWidth = 2,
    );

    // 나이 표시
    final ageText = '${age.toStringAsFixed(1)}세';
    final agePainter = TextPainter(
      text: TextSpan(
        text: ageText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    agePainter.paint(
      canvas,
      position + Offset(-agePainter.width / 2, 25),
    );

    // 라벨
    final labelPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color.withValues(alpha: 0.7),
          fontSize: 9,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPainter.paint(
      canvas,
      position + Offset(-labelPainter.width / 2, 40),
    );
  }

  void _drawInfo(Canvas canvas, Size size) {
    // 상단 정보 패널
    final infoRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.3, 10, size.width * 0.4, 35),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      infoRect,
      Paint()..color = AppColors.card.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      infoRect,
      Paint()
        ..color = AppColors.cardBorder
        ..style = PaintingStyle.stroke,
    );

    // 여행 상태 텍스트
    String statusText;
    if (journeyComplete) {
      statusText = '여행 완료! 나이 차이: ${(earthTwinAge - spaceTwinAge).toStringAsFixed(1)}년';
    } else if (journeyProgress > 0) {
      statusText = isOutbound ? '목적지로 이동 중...' : '지구로 귀환 중...';
    } else {
      statusText = '여행 준비 완료';
    }

    final statusPainter = TextPainter(
      text: TextSpan(
        text: statusText,
        style: TextStyle(
          color: journeyComplete ? AppColors.accent2 : AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    statusPainter.paint(
      canvas,
      Offset(size.width / 2 - statusPainter.width / 2, 20),
    );
  }

  @override
  bool shouldRepaint(covariant TwinParadoxPainter oldDelegate) => true;
}
