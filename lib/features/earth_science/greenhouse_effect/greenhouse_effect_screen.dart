import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 온실효과 시뮬레이션 화면 (Greenhouse Effect)
class GreenhouseEffectScreen extends StatefulWidget {
  const GreenhouseEffectScreen({super.key});

  @override
  State<GreenhouseEffectScreen> createState() => _GreenhouseEffectScreenState();
}

class _GreenhouseEffectScreenState extends State<GreenhouseEffectScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 시뮬레이션 파라미터
  double _co2Level = 420; // ppm (현재 수준)
  double _methaneLevel = 1.9; // ppm
  bool _isAnimating = true;
  bool _showInfrared = true;
  bool _showLabels = true;
  double _animationTime = 0;

  // CO2 농도별 시나리오
  static const List<Map<String, dynamic>> _scenarios = [
    {'name': '산업혁명 이전', 'co2': 280.0, 'temp': 14.0},
    {'name': '현재 (2024)', 'co2': 420.0, 'temp': 15.1},
    {'name': '2050 예측', 'co2': 550.0, 'temp': 16.5},
    {'name': '최악 시나리오', 'co2': 800.0, 'temp': 18.5},
  ];

  // 온실가스 분자들 (애니메이션용)
  final List<GasMolecule> _molecules = [];

  @override
  void initState() {
    super.initState();
    _initMolecules();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _initMolecules() {
    final random = math.Random();
    _molecules.clear();

    // CO2 분자 수는 CO2 레벨에 비례
    final numMolecules = ((_co2Level - 200) / 20).round().clamp(5, 40);

    for (int i = 0; i < numMolecules; i++) {
      _molecules.add(GasMolecule(
        x: random.nextDouble(),
        y: 0.3 + random.nextDouble() * 0.4, // 대기 영역
        vx: (random.nextDouble() - 0.5) * 0.002,
        vy: (random.nextDouble() - 0.5) * 0.001,
        type: random.nextDouble() > 0.3 ? 'CO2' : 'CH4',
      ));
    }
  }

  void _updateAnimation() {
    if (!_isAnimating) return;

    setState(() {
      _animationTime += 0.016;

      // 분자 이동
      for (final molecule in _molecules) {
        molecule.x += molecule.vx;
        molecule.y += molecule.vy;

        // 경계 반사
        if (molecule.x < 0 || molecule.x > 1) molecule.vx *= -1;
        if (molecule.y < 0.25 || molecule.y > 0.75) molecule.vy *= -1;

        molecule.x = molecule.x.clamp(0.0, 1.0);
        molecule.y = molecule.y.clamp(0.25, 0.75);
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _co2Level = 420;
      _methaneLevel = 1.9;
      _initMolecules();
    });
  }

  void _selectScenario(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _co2Level = _scenarios[index]['co2'];
      _initMolecules();
    });
  }

  // 온도 계산 (간단한 모델)
  double get _temperature {
    // 기본 온도 + CO2 영향 + 메탄 영향
    const baseTemp = 14.0; // 산업혁명 이전 평균 온도
    final co2Effect = (_co2Level - 280) * 0.004; // CO2 2배 증가 시 약 2-3도 상승
    final methaneEffect = (_methaneLevel - 0.7) * 0.3;
    return baseTemp + co2Effect + methaneEffect;
  }

  // 반사율 (온실가스 농도에 따른 적외선 흡수율)
  double get _absorptionRate {
    return ((_co2Level - 200) / 800).clamp(0.3, 0.95);
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
              '지구과학 시뮬레이션',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '온실효과 (Greenhouse Effect)',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showInfrared ? Icons.waves : Icons.waves_outlined,
              color: _showInfrared ? AppColors.accent2 : AppColors.muted,
            ),
            onPressed: () => setState(() => _showInfrared = !_showInfrared),
            tooltip: '적외선 표시',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '온실효과 (Greenhouse Effect)',
          formula: 'T = T0 + k * ln(CO2/CO2_0)',
          formulaDescription:
              '온실가스(CO2, CH4 등)는 태양 복사열은 통과시키지만 지표면에서 방출되는 적외선을 흡수하여 대기 온도를 높입니다. CO2 농도가 2배 증가하면 약 2-3C 상승합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: GreenhouseEffectPainter(
                co2Level: _co2Level,
                temperature: _temperature,
                absorptionRate: _absorptionRate,
                molecules: _molecules,
                animationTime: _animationTime,
                showInfrared: _showInfrared,
                showLabels: _showLabels,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 시나리오 프리셋 버튼
              PresetGroup(
                label: '시나리오 선택',
                presets: List.generate(_scenarios.length, (index) {
                  final scenario = _scenarios[index];
                  final isSelected = (_co2Level - scenario['co2']).abs() < 10;
                  return PresetButton(
                    label: scenario['name'],
                    isSelected: isSelected,
                    onPressed: () => _selectScenario(index),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // CO2 농도 슬라이더
              ControlGroup(
                primaryControl: SimSlider(
                  label: 'CO2 농도',
                  value: _co2Level,
                  min: 200,
                  max: 1000,
                  defaultValue: 420,
                  formatValue: (v) => '${v.toInt()} ppm',
                  onChanged: (v) {
                    setState(() {
                      _co2Level = v;
                      _initMolecules();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '메탄 (CH4) 농도',
                    value: _methaneLevel,
                    min: 0.7,
                    max: 5.0,
                    step: 0.1,
                    defaultValue: 1.9,
                    formatValue: (v) => '${v.toStringAsFixed(1)} ppm',
                    onChanged: (v) => setState(() => _methaneLevel = v),
                  ),
                  SimToggle(
                    label: '라벨 표시',
                    value: _showLabels,
                    onChanged: (v) => setState(() => _showLabels = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 온도 정보
              _TemperatureInfo(
                co2Level: _co2Level,
                temperature: _temperature,
                absorptionRate: _absorptionRate,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isAnimating ? '정지' : '재생',
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isAnimating = !_isAnimating);
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

/// 온실가스 분자 데이터
class GasMolecule {
  double x;
  double y;
  double vx;
  double vy;
  String type;

  GasMolecule({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.type,
  });
}

/// 온도 정보 위젯
class _TemperatureInfo extends StatelessWidget {
  final double co2Level;
  final double temperature;
  final double absorptionRate;

  const _TemperatureInfo({
    required this.co2Level,
    required this.temperature,
    required this.absorptionRate,
  });

  @override
  Widget build(BuildContext context) {
    // 온도 변화에 따른 색상
    Color tempColor;
    if (temperature < 15) {
      tempColor = const Color(0xFF4169E1);
    } else if (temperature < 16) {
      tempColor = const Color(0xFFFFD700);
    } else if (temperature < 17) {
      tempColor = const Color(0xFFFF8C00);
    } else {
      tempColor = const Color(0xFFFF4500);
    }

    final tempChange = temperature - 14.0;

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
              Expanded(
                child: _InfoColumn(
                  label: '지구 평균 온도',
                  value: '${temperature.toStringAsFixed(1)}C',
                  subValue: '(+${tempChange.toStringAsFixed(1)}C)',
                  valueColor: tempColor,
                ),
              ),
              Expanded(
                child: _InfoColumn(
                  label: 'CO2 농도',
                  value: '${co2Level.toInt()} ppm',
                  subValue: co2Level > 420 ? '위험' : '안전',
                  valueColor: co2Level > 500 ? Colors.red : AppColors.accent,
                ),
              ),
              Expanded(
                child: _InfoColumn(
                  label: '적외선 흡수율',
                  value: '${(absorptionRate * 100).toInt()}%',
                  subValue: '',
                  valueColor: AppColors.accent2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 경고 메시지
          if (temperature > 16)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    temperature > 17
                        ? '심각한 기후 위기 상황!'
                        : '기후 변화 경고 수준',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color valueColor;

  const _InfoColumn({
    required this.label,
    required this.value,
    required this.subValue,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subValue.isNotEmpty)
          Text(
            subValue,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 9,
            ),
          ),
      ],
    );
  }
}

/// 온실효과 페인터
class GreenhouseEffectPainter extends CustomPainter {
  final double co2Level;
  final double temperature;
  final double absorptionRate;
  final List<GasMolecule> molecules;
  final double animationTime;
  final bool showInfrared;
  final bool showLabels;

  GreenhouseEffectPainter({
    required this.co2Level,
    required this.temperature,
    required this.absorptionRate,
    required this.molecules,
    required this.animationTime,
    required this.showInfrared,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 우주 배경
    _drawSpace(canvas, size);

    // 태양 광선 (가시광선)
    _drawSunlight(canvas, size);

    // 대기층
    _drawAtmosphere(canvas, size);

    // 지표면
    _drawGround(canvas, size);

    // 적외선 방출
    if (showInfrared) {
      _drawInfraredRadiation(canvas, size);
    }

    // 온실가스 분자
    _drawMolecules(canvas, size);

    // 태양
    _drawSun(canvas, size);

    // 라벨
    if (showLabels) {
      _drawLabels(canvas, size);
    }

    // 온도계
    _drawThermometer(canvas, size);
  }

  void _drawSpace(Canvas canvas, Size size) {
    // 우주 배경 그라데이션
    final spaceGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF000010),
        const Color(0xFF000820),
        const Color(0xFF001030),
      ],
      stops: const [0.0, 0.3, 0.5],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.5),
      Paint()..shader = spaceGradient,
    );

    // 별
    final random = math.Random(42);
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.3;
      final radius = random.nextDouble() * 1.0 + 0.3;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: random.nextDouble() * 0.5 + 0.3),
      );
    }
  }

  void _drawSun(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.85, size.height * 0.1);
    const sunRadius = 25.0;

    // 태양 글로우
    final glowGradient = RadialGradient(
      colors: [
        const Color(0xFFFFD700),
        const Color(0xFFFF8C00).withValues(alpha: 0.5),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius * 2));

    canvas.drawCircle(sunCenter, sunRadius * 2, Paint()..shader = glowGradient);

    // 태양 본체
    canvas.drawCircle(
      sunCenter,
      sunRadius,
      Paint()..color = const Color(0xFFFFD700),
    );
  }

  void _drawSunlight(Canvas canvas, Size size) {
    // 태양에서 지표로 향하는 가시광선
    final sunCenter = Offset(size.width * 0.85, size.height * 0.1);
    final groundCenter = Offset(size.width * 0.5, size.height * 0.75);

    // 여러 개의 광선
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
      ..strokeWidth = 3;

    for (int i = -2; i <= 2; i++) {
      final offset = i * 30.0;
      final startX = sunCenter.dx + offset * 0.3;
      final endX = groundCenter.dx + offset;

      // 광선이 지표면까지 도달
      canvas.drawLine(
        Offset(startX, sunCenter.dy + 30),
        Offset(endX, size.height * 0.75),
        rayPaint,
      );

      // 화살표
      _drawArrow(
        canvas,
        Offset(endX, size.height * 0.6),
        Offset(endX, size.height * 0.75),
        const Color(0xFFFFD700).withValues(alpha: 0.5),
      );
    }
  }

  void _drawAtmosphere(Canvas canvas, Size size) {
    // 대기층 (온실가스 농도에 따라 색상 변화)
    final atmosphereOpacity = (absorptionRate * 0.4).clamp(0.1, 0.5);

    final atmosphereGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        const Color(0xFF4169E1).withValues(alpha: atmosphereOpacity * 0.5),
        const Color(0xFF87CEEB).withValues(alpha: atmosphereOpacity),
        const Color(0xFF87CEEB).withValues(alpha: atmosphereOpacity * 0.7),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, size.height * 0.25, size.width, size.height * 0.5));

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.25, size.width, size.height * 0.5),
      Paint()..shader = atmosphereGradient,
    );

    // 대기층 경계선
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
  }

  void _drawGround(Canvas canvas, Size size) {
    // 지표면
    final groundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF228B22),
        const Color(0xFF2E8B57),
        const Color(0xFF1E5128),
      ],
    ).createShader(Rect.fromLTWH(0, size.height * 0.75, size.width, size.height * 0.25));

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.75, size.width, size.height * 0.25),
      Paint()..shader = groundGradient,
    );

    // 지표면 열 표시 (온도에 따라)
    if (temperature > 15) {
      final heatIntensity = ((temperature - 15) / 5).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.73, size.width, size.height * 0.04),
        Paint()..color = Colors.red.withValues(alpha: heatIntensity * 0.3),
      );
    }
  }

  void _drawInfraredRadiation(Canvas canvas, Size size) {
    // 지표면에서 방출되는 적외선
    final infraredColor = const Color(0xFFFF4500);
    final groundY = size.height * 0.75;
    final atmosphereTop = size.height * 0.35;

    for (int i = 0; i < 5; i++) {
      final x = size.width * (0.2 + i * 0.15);
      final waveOffset = math.sin(animationTime * 3 + i) * 5;

      // 지표에서 올라가는 적외선
      final path = Path();
      path.moveTo(x, groundY);

      // 파동 형태로 올라감
      for (double y = groundY; y > atmosphereTop; y -= 10) {
        final wave = math.sin((groundY - y) * 0.1 + animationTime * 5) * 8;
        path.lineTo(x + wave + waveOffset, y);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = infraredColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // 일부는 흡수되어 다시 지표로
      if (i % 2 == 0) {
        final absorbY = size.height * (0.4 + (1 - absorptionRate) * 0.2);
        final returnPath = Path();
        returnPath.moveTo(x + 15, absorbY);

        for (double y = absorbY; y < groundY; y += 10) {
          final wave = math.sin((y - absorbY) * 0.1 + animationTime * 4) * 6;
          returnPath.lineTo(x + 15 + wave, y);
        }

        canvas.drawPath(
          returnPath,
          Paint()
            ..color = infraredColor.withValues(alpha: 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );

        // 분자에서 흡수/재방출 표시
        canvas.drawCircle(
          Offset(x + 10, absorbY),
          5 + math.sin(animationTime * 5) * 2,
          Paint()..color = infraredColor.withValues(alpha: 0.3),
        );
      }
    }

    // 일부는 우주로 탈출
    final escapeRate = 1 - absorptionRate;
    if (escapeRate > 0.1) {
      for (int i = 0; i < 2; i++) {
        final x = size.width * (0.35 + i * 0.3);
        final path = Path();
        path.moveTo(x, atmosphereTop);

        for (double y = atmosphereTop; y > 20; y -= 10) {
          final wave = math.sin((atmosphereTop - y) * 0.1 + animationTime * 3) * 5;
          path.lineTo(x + wave, y);
        }

        canvas.drawPath(
          path,
          Paint()
            ..color = infraredColor.withValues(alpha: escapeRate * 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _drawMolecules(Canvas canvas, Size size) {
    for (final molecule in molecules) {
      final x = molecule.x * size.width;
      final y = molecule.y * size.height;

      if (molecule.type == 'CO2') {
        _drawCO2Molecule(canvas, Offset(x, y));
      } else {
        _drawCH4Molecule(canvas, Offset(x, y));
      }
    }
  }

  void _drawCO2Molecule(Canvas canvas, Offset center) {
    // CO2 분자 (O=C=O 구조)
    const radius = 5.0;

    // 탄소 (검은색)
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFF333333),
    );

    // 산소 (빨간색) - 양쪽
    canvas.drawCircle(
      center + const Offset(-10, 0),
      radius * 0.8,
      Paint()..color = const Color(0xFFFF4444),
    );
    canvas.drawCircle(
      center + const Offset(10, 0),
      radius * 0.8,
      Paint()..color = const Color(0xFFFF4444),
    );

    // 결합선
    canvas.drawLine(
      center + const Offset(-5, 0),
      center + const Offset(-8, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      center + const Offset(5, 0),
      center + const Offset(8, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );
  }

  void _drawCH4Molecule(Canvas canvas, Offset center) {
    // CH4 분자 (메탄)
    const radius = 5.0;

    // 탄소 (검은색)
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFF333333),
    );

    // 수소 (흰색) - 4개
    final hydrogenPositions = [
      const Offset(-7, -7),
      const Offset(7, -7),
      const Offset(-7, 7),
      const Offset(7, 7),
    ];

    for (final pos in hydrogenPositions) {
      canvas.drawCircle(
        center + pos,
        radius * 0.5,
        Paint()..color = const Color(0xFFDDDDDD),
      );
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(from, to, paint);

    // 화살표 머리
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowLength = 8.0;
    const arrowAngle = 0.5;

    canvas.drawLine(
      to,
      to - Offset(
        arrowLength * math.cos(angle - arrowAngle),
        arrowLength * math.sin(angle - arrowAngle),
      ),
      paint,
    );
    canvas.drawLine(
      to,
      to - Offset(
        arrowLength * math.cos(angle + arrowAngle),
        arrowLength * math.sin(angle + arrowAngle),
      ),
      paint,
    );
  }

  void _drawThermometer(Canvas canvas, Size size) {
    // 온도계 (오른쪽 하단)
    final thermX = size.width - 30;
    final thermTop = size.height * 0.4;
    final thermBottom = size.height * 0.7;
    final thermHeight = thermBottom - thermTop;

    // 온도계 배경
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(thermX - 8, thermTop, 16, thermHeight),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );

    // 온도 표시 (14도 ~ 20도 범위)
    final tempNormalized = ((temperature - 14) / 6).clamp(0.0, 1.0);
    final fillHeight = thermHeight * tempNormalized;

    // 온도 색상
    Color tempColor;
    if (temperature < 15) {
      tempColor = const Color(0xFF4169E1);
    } else if (temperature < 16) {
      tempColor = const Color(0xFFFFD700);
    } else if (temperature < 17) {
      tempColor = const Color(0xFFFF8C00);
    } else {
      tempColor = const Color(0xFFFF4500);
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(thermX - 6, thermBottom - fillHeight, 12, fillHeight),
        const Radius.circular(6),
      ),
      Paint()..color = tempColor,
    );

    // 온도 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${temperature.toStringAsFixed(1)}C',
        style: TextStyle(
          color: tempColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(thermX - textPainter.width / 2, thermBottom + 5));
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 우주 라벨
    textPainter.text = TextSpan(
      text: '우주 (Space)',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 10));

    // 대기 라벨
    textPainter.text = TextSpan(
      text: '대기 (Atmosphere)',
      style: TextStyle(
        color: AppColors.accent.withValues(alpha: 0.8),
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height * 0.4));

    // 지표 라벨
    textPainter.text = TextSpan(
      text: '지표면 (Surface)',
      style: TextStyle(
        color: const Color(0xFF90EE90),
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height * 0.78));

    // CO2 분자 범례
    textPainter.text = TextSpan(
      text: 'CO2: ${co2Level.toInt()} ppm',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 9,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height * 0.52));

    // 적외선 범례
    if (showInfrared) {
      textPainter.text = TextSpan(
        text: '적외선 (IR)',
        style: TextStyle(
          color: const Color(0xFFFF4500).withValues(alpha: 0.7),
          fontSize: 9,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, size.height * 0.58));
    }
  }

  @override
  bool shouldRepaint(covariant GreenhouseEffectPainter oldDelegate) {
    return co2Level != oldDelegate.co2Level ||
        temperature != oldDelegate.temperature ||
        animationTime != oldDelegate.animationTime ||
        showInfrared != oldDelegate.showInfrared ||
        showLabels != oldDelegate.showLabels;
  }
}
