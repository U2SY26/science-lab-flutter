import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 부력 시뮬레이션 화면 (아르키메데스 원리)
class BuoyancyScreen extends StatefulWidget {
  const BuoyancyScreen({super.key});

  @override
  State<BuoyancyScreen> createState() => _BuoyancyScreenState();
}

class _BuoyancyScreenState extends State<BuoyancyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 기본값
  static const double _defaultObjectDensity = 500; // 물체 밀도 (kg/m³)
  static const double _defaultFluidDensity = 1000; // 유체 밀도 (kg/m³) - 물
  static const double _defaultObjectVolume = 0.1; // 물체 부피 (m³)
  static const double _defaultGravity = 9.8;

  // 파라미터
  double _objectDensity = _defaultObjectDensity;
  double _fluidDensity = _defaultFluidDensity;
  double _objectVolume = _defaultObjectVolume;
  double _gravity = _defaultGravity;
  bool _isRunning = true;

  // 물리 상태
  double _objectY = 0; // 물체 Y 위치 (0 = 수면, 음수 = 물속)
  double _velocity = 0;

  // 프리셋
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _objectY = -0.3; // 초기 위치: 약간 수면 위
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
      const damping = 0.98; // 유체 저항

      // 물체 질량
      final mass = _objectDensity * _objectVolume;

      // 중력
      final gravityForce = mass * _gravity;

      // 부력 계산: F_b = ρVg
      // 잠긴 부피 비율 계산
      final objectHeight = math.pow(_objectVolume, 1 / 3).toDouble(); // 근사적 높이
      double submergedRatio = 0;

      if (_objectY >= 0) {
        // 완전히 물속
        submergedRatio = 1;
      } else if (_objectY <= -objectHeight) {
        // 완전히 물 위
        submergedRatio = 0;
      } else {
        // 부분적으로 잠김
        submergedRatio = (_objectY + objectHeight) / objectHeight;
        submergedRatio = submergedRatio.clamp(0, 1);
      }

      final submergedVolume = _objectVolume * submergedRatio;
      final buoyancyForce = _fluidDensity * submergedVolume * _gravity;

      // 순 힘 (양수 = 위로, 음수 = 아래로)
      final netForce = buoyancyForce - gravityForce;

      // 가속도
      final acceleration = netForce / mass;

      // 속도와 위치 업데이트
      _velocity += acceleration * dt;
      _velocity *= damping; // 유체 저항
      _objectY += _velocity * dt;

      // 경계 조건
      if (_objectY < -0.5) {
        _objectY = -0.5;
        _velocity = 0;
      }
      if (_objectY > 0.5) {
        _objectY = 0.5;
        _velocity = 0;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _objectY = -0.3;
      _velocity = 0;
    });
  }

  void _drop() {
    HapticFeedback.lightImpact();
    setState(() {
      _objectY = -0.4; // 수면 위에서 떨어뜨림
      _velocity = 0;
      _isRunning = true;
    });
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'wood':
          _objectDensity = 600; // 나무
          _fluidDensity = 1000; // 물
          break;
        case 'ice':
          _objectDensity = 917; // 얼음
          _fluidDensity = 1000; // 물
          break;
        case 'iron':
          _objectDensity = 7874; // 철
          _fluidDensity = 1000; // 물
          break;
        case 'oil':
          _objectDensity = 800;
          _fluidDensity = 850; // 기름
          break;
        case 'mercury':
          _objectDensity = 7874; // 철
          _fluidDensity = 13600; // 수은
          break;
        case 'balloon':
          _objectDensity = 100; // 풍선 (공기 포함)
          _fluidDensity = 1000;
          break;
      }
      _reset();
    });
  }

  // 부력 계산
  double get _buoyancyForce => _fluidDensity * _objectVolume * _gravity;

  // 중력 계산
  double get _gravityForce => _objectDensity * _objectVolume * _gravity;

  // 뜨는지 가라앉는지
  String get _floatStatus {
    if (_objectDensity < _fluidDensity) return '뜸';
    if (_objectDensity > _fluidDensity) return '가라앉음';
    return '중립';
  }

  // 평형 시 잠기는 비율
  double get _equilibriumSubmergedRatio {
    if (_objectDensity >= _fluidDensity) return 1.0;
    return _objectDensity / _fluidDensity;
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
              '유체역학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '부력 (아르키메데스 원리)',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '유체역학',
          title: '부력 (아르키메데스 원리)',
          formula: 'F\u2082 = \u03C1Vg',
          formulaDescription:
              '부력(F\u2082)은 유체의 밀도(\u03C1), 잠긴 부피(V), '
              '중력가속도(g)의 곱입니다. '
              '물체가 뜨려면 물체 밀도 < 유체 밀도여야 합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: BuoyancyPainter(
                objectY: _objectY,
                objectDensity: _objectDensity,
                fluidDensity: _fluidDensity,
                objectVolume: _objectVolume,
                equilibriumRatio: _equilibriumSubmergedRatio,
                buoyancyForce: _buoyancyForce,
                gravityForce: _gravityForce,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋
              PresetGroup(
                label: '물질 프리셋',
                presets: [
                  PresetButton(
                    label: '나무/물',
                    isSelected: _selectedPreset == 'wood',
                    onPressed: () => _applyPreset('wood'),
                  ),
                  PresetButton(
                    label: '얼음/물',
                    isSelected: _selectedPreset == 'ice',
                    onPressed: () => _applyPreset('ice'),
                  ),
                  PresetButton(
                    label: '철/물',
                    isSelected: _selectedPreset == 'iron',
                    onPressed: () => _applyPreset('iron'),
                  ),
                  PresetButton(
                    label: '철/수은',
                    isSelected: _selectedPreset == 'mercury',
                    onPressed: () => _applyPreset('mercury'),
                  ),
                  PresetButton(
                    label: '풍선',
                    isSelected: _selectedPreset == 'balloon',
                    onPressed: () => _applyPreset('balloon'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 물리량 정보
              _PhysicsInfo(
                objectDensity: _objectDensity,
                fluidDensity: _fluidDensity,
                buoyancyForce: _buoyancyForce,
                gravityForce: _gravityForce,
                floatStatus: _floatStatus,
                equilibriumRatio: _equilibriumSubmergedRatio,
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '물체 밀도 (\u03C1\u2092)',
                  value: _objectDensity,
                  min: 50,
                  max: 10000,
                  defaultValue: _defaultObjectDensity,
                  formatValue: (v) => '${v.toStringAsFixed(0)} kg/m\u00B3',
                  onChanged: (v) {
                    setState(() {
                      _objectDensity = v;
                      _selectedPreset = null;
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '유체 밀도 (\u03C1\u1DA0)',
                    value: _fluidDensity,
                    min: 500,
                    max: 15000,
                    defaultValue: _defaultFluidDensity,
                    formatValue: (v) => '${v.toStringAsFixed(0)} kg/m\u00B3',
                    onChanged: (v) {
                      setState(() {
                        _fluidDensity = v;
                        _selectedPreset = null;
                      });
                    },
                  ),
                  SimSlider(
                    label: '물체 부피 (V)',
                    value: _objectVolume,
                    min: 0.01,
                    max: 0.5,
                    step: 0.01,
                    defaultValue: _defaultObjectVolume,
                    formatValue: (v) => '${v.toStringAsFixed(2)} m\u00B3',
                    onChanged: (v) {
                      setState(() {
                        _objectVolume = v;
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
                label: _isRunning ? '정지' : '재생',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isRunning = !_isRunning);
                },
              ),
              SimButton(
                label: '떨어뜨리기',
                icon: Icons.arrow_downward,
                onPressed: _drop,
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
  final double objectDensity;
  final double fluidDensity;
  final double buoyancyForce;
  final double gravityForce;
  final String floatStatus;
  final double equilibriumRatio;

  const _PhysicsInfo({
    required this.objectDensity,
    required this.fluidDensity,
    required this.buoyancyForce,
    required this.gravityForce,
    required this.floatStatus,
    required this.equilibriumRatio,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = floatStatus == '뜸'
        ? Colors.green
        : floatStatus == '가라앉음'
            ? Colors.red
            : Colors.orange;

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
                label: '물체 밀도',
                value: '${objectDensity.toStringAsFixed(0)} kg/m\u00B3',
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: '유체 밀도',
                value: '${fluidDensity.toStringAsFixed(0)} kg/m\u00B3',
                color: AppColors.accent,
              ),
              _InfoItem(
                label: '상태',
                value: floatStatus,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: '부력 (F\u2082)',
                value: '${buoyancyForce.toStringAsFixed(1)} N',
                color: Colors.blue,
              ),
              _InfoItem(
                label: '중력 (W)',
                value: '${gravityForce.toStringAsFixed(1)} N',
                color: Colors.yellow.shade700,
              ),
              _InfoItem(
                label: '잠김 비율',
                value: '${(equilibriumRatio * 100).toStringAsFixed(0)}%',
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

/// 부력 페인터
class BuoyancyPainter extends CustomPainter {
  final double objectY;
  final double objectDensity;
  final double fluidDensity;
  final double objectVolume;
  final double equilibriumRatio;
  final double buoyancyForce;
  final double gravityForce;

  BuoyancyPainter({
    required this.objectY,
    required this.objectDensity,
    required this.fluidDensity,
    required this.objectVolume,
    required this.equilibriumRatio,
    required this.buoyancyForce,
    required this.gravityForce,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경 (하늘)
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF1A2A3A),
    );

    final waterLevel = size.height * 0.4;

    // 물 그리기
    _drawWater(canvas, size, waterLevel);

    // 물체 그리기
    _drawObject(canvas, size, waterLevel);

    // 힘 벡터 그리기
    _drawForceVectors(canvas, size, waterLevel);

    // 수면 표시
    _drawWaterLevelIndicator(canvas, size, waterLevel);

    // 밀도 비교 표시
    _drawDensityComparison(canvas, size);
  }

  void _drawWater(Canvas canvas, Size size, double waterLevel) {
    // 물 그라데이션
    final waterGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF1E90FF).withValues(alpha: 0.6),
        const Color(0xFF0066CC).withValues(alpha: 0.8),
        const Color(0xFF003366).withValues(alpha: 0.9),
      ],
    ).createShader(Rect.fromLTWH(0, waterLevel, size.width, size.height - waterLevel));

    canvas.drawRect(
      Rect.fromLTWH(0, waterLevel, size.width, size.height - waterLevel),
      Paint()..shader = waterGradient,
    );

    // 물결 효과
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final wavePath = Path();
    wavePath.moveTo(0, waterLevel);
    for (double x = 0; x <= size.width; x += 20) {
      wavePath.quadraticBezierTo(
        x + 10,
        waterLevel - 3,
        x + 20,
        waterLevel,
      );
    }
    canvas.drawPath(wavePath, wavePaint);
  }

  void _drawObject(Canvas canvas, Size size, double waterLevel) {
    final objectSize = 60 + objectVolume * 100; // 부피에 따른 크기
    final centerX = size.width / 2;

    // objectY: -0.5(위) ~ 0.5(아래)
    // 수면(waterLevel)을 기준으로 변환
    final objectCenterY = waterLevel + objectY * 200;

    // 물체 색상 (밀도에 따라)
    final objectColor = objectDensity < 500
        ? const Color(0xFFFFEB3B) // 가벼움 - 노랑
        : objectDensity < 1000
            ? const Color(0xFF8B4513) // 중간 - 나무색
            : objectDensity < 5000
                ? const Color(0xFF607D8B) // 무거움 - 회색
                : const Color(0xFF424242); // 매우 무거움 - 어두운 회색

    // 물체 그림자 (물속에서)
    if (objectCenterY > waterLevel - objectSize / 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(centerX + 5, objectCenterY + 5),
            width: objectSize,
            height: objectSize,
          ),
          const Radius.circular(8),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.3),
      );
    }

    // 물체 본체
    final objectRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, objectCenterY),
        width: objectSize,
        height: objectSize,
      ),
      const Radius.circular(8),
    );

    // 그라데이션
    final objectGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        objectColor.withValues(alpha: 1),
        HSLColor.fromColor(objectColor).withLightness(0.3).toColor(),
      ],
    ).createShader(objectRect.outerRect);

    canvas.drawRRect(objectRect, Paint()..shader = objectGradient);

    // 테두리
    canvas.drawRRect(
      objectRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 잠긴 부분 표시
    if (objectCenterY + objectSize / 2 > waterLevel) {
      final submergedTop = math.max(waterLevel, objectCenterY - objectSize / 2);
      final submergedBottom = objectCenterY + objectSize / 2;
      final submergedHeight = submergedBottom - submergedTop;

      if (submergedHeight > 0) {
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(
          centerX - objectSize / 2,
          submergedTop,
          objectSize,
          submergedHeight,
        ));

        canvas.drawRRect(
          objectRect,
          Paint()..color = Colors.blue.withValues(alpha: 0.3),
        );
        canvas.restore();
      }
    }

    // 밀도 표시
    _drawText(
      canvas,
      '\u03C1=${objectDensity.toStringAsFixed(0)}',
      Offset(centerX - 25, objectCenterY - 8),
      color: Colors.white,
      fontSize: 10,
    );
  }

  void _drawForceVectors(Canvas canvas, Size size, double waterLevel) {
    final centerX = size.width / 2;
    final objectCenterY = waterLevel + objectY * 200;
    final scale = 0.3;

    // 중력 (아래 방향)
    final gravityLength = gravityForce * scale;
    _drawArrow(
      canvas,
      Offset(centerX - 30, objectCenterY),
      Offset(centerX - 30, objectCenterY + gravityLength),
      Colors.yellow,
      'W',
    );

    // 부력 (위 방향)
    final buoyancyLength = buoyancyForce * scale;
    _drawArrow(
      canvas,
      Offset(centerX + 30, objectCenterY),
      Offset(centerX + 30, objectCenterY - buoyancyLength),
      Colors.cyan,
      'F\u2082',
    );
  }

  void _drawArrow(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    String label,
  ) {
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, arrowPaint);

    // 화살표 머리
    final arrowAngle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowHeadLength = 12.0;
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
    _drawText(
      canvas,
      label,
      Offset(end.dx + 5, end.dy - 15),
      color: color,
      fontSize: 12,
    );
  }

  void _drawWaterLevelIndicator(Canvas canvas, Size size, double waterLevel) {
    // 수면 선
    canvas.drawLine(
      Offset(0, waterLevel),
      Offset(size.width, waterLevel),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // 수면 라벨
    _drawText(
      canvas,
      '수면',
      Offset(10, waterLevel - 20),
      color: Colors.white.withValues(alpha: 0.7),
    );

    // 유체 밀도 표시
    _drawText(
      canvas,
      '\u03C1\u1DA0 = ${fluidDensity.toStringAsFixed(0)} kg/m\u00B3',
      Offset(10, waterLevel + 20),
      color: Colors.cyan.withValues(alpha: 0.8),
    );
  }

  void _drawDensityComparison(Canvas canvas, Size size) {
    final ratio = objectDensity / fluidDensity;
    String status;
    Color statusColor;

    if (ratio < 1) {
      status = '\u03C1\u2092 < \u03C1\u1DA0: 뜸';
      statusColor = Colors.green;
    } else if (ratio > 1) {
      status = '\u03C1\u2092 > \u03C1\u1DA0: 가라앉음';
      statusColor = Colors.red;
    } else {
      status = '\u03C1\u2092 = \u03C1\u1DA0: 중립';
      statusColor = Colors.orange;
    }

    _drawText(
      canvas,
      status,
      Offset(size.width / 2 - 50, 20),
      color: statusColor,
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
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant BuoyancyPainter oldDelegate) => true;
}
