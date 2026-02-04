import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 광전효과 시뮬레이션 화면
/// Photoelectric effect simulation
class PhotoelectricScreen extends StatefulWidget {
  const PhotoelectricScreen({super.key});

  @override
  State<PhotoelectricScreen> createState() => _PhotoelectricScreenState();
}

class _PhotoelectricScreenState extends State<PhotoelectricScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 물리 파라미터 (기본값)
  static const double _defaultFrequency = 1.0; // ×10^15 Hz
  static const double _defaultIntensity = 0.5;
  static const double _defaultWorkFunction = 2.0; // eV

  double frequency = _defaultFrequency;
  double intensity = _defaultIntensity;
  double workFunction = _defaultWorkFunction;
  bool isRunning = true;

  // 금속 프리셋
  String? _selectedMetal;
  static const Map<String, double> metalWorkFunctions = {
    'sodium': 2.28,    // 나트륨
    'potassium': 2.30, // 칼륨
    'zinc': 4.33,      // 아연
    'copper': 4.65,    // 구리
    'platinum': 5.65,  // 백금
  };

  // 애니메이션 상태
  double time = 0;
  List<Photon> photons = [];
  List<Electron> electrons = [];
  int photonCount = 0;
  int electronCount = 0;
  final math.Random _random = math.Random();

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
      time += 0.02;

      // 광자 생성 (강도에 비례)
      if (_random.nextDouble() < intensity * 0.3) {
        _emitPhoton();
      }

      // 광자 업데이트
      photons = photons.where((p) {
        p.x += p.vx;

        // 금속 표면에 도달
        if (p.x >= 200) {
          photonCount++;
          // 광전효과 체크
          if (_checkPhotoelectricEffect()) {
            _emitElectron(p.y);
          }
          return false;
        }
        return true;
      }).toList();

      // 전자 업데이트
      electrons = electrons.where((e) {
        e.x += e.vx;
        e.y += e.vy;
        e.vy += 0.05; // 중력 효과 (시각화용)

        // 화면 밖으로 나가면 제거
        if (e.x > 400 || e.y > 400) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  bool _checkPhotoelectricEffect() {
    final photonEnergy = _calculatePhotonEnergy();
    // 광자 에너지가 일함수보다 크면 전자 방출
    return photonEnergy >= workFunction;
  }

  double _calculatePhotonEnergy() {
    // E = hf (플랑크 상수 × 진동수)
    // 단순화된 계산: 진동수를 eV로 직접 변환
    return frequency * 2.5; // 시뮬레이션용 스케일 팩터
  }

  double _calculateElectronKineticEnergy() {
    final photonEnergy = _calculatePhotonEnergy();
    final kineticEnergy = photonEnergy - workFunction;
    return kineticEnergy > 0 ? kineticEnergy : 0;
  }

  void _emitPhoton() {
    final y = 100 + _random.nextDouble() * 150;
    photons.add(Photon(
      x: 20,
      y: y,
      vx: 3 + _random.nextDouble(),
      wavelength: 300 / frequency, // 가시광선 범위로 매핑
    ));
  }

  void _emitElectron(double y) {
    final kineticEnergy = _calculateElectronKineticEnergy();
    final speed = math.sqrt(kineticEnergy) * 2;

    electronCount++;
    electrons.add(Electron(
      x: 205,
      y: y,
      vx: speed * (0.5 + _random.nextDouble() * 0.5),
      vy: (_random.nextDouble() - 0.5) * speed,
    ));
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      photons.clear();
      electrons.clear();
      photonCount = 0;
      electronCount = 0;
    });
  }

  void _applyMetalPreset(String metal) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMetal = metal;
      workFunction = metalWorkFunctions[metal]!;
    });
  }

  // 문턱 주파수 계산
  double get thresholdFrequency => workFunction / 2.5;

  // 색상 계산 (파장에 따른)
  Color _getPhotonColor() {
    // 주파수를 가시광선 파장으로 변환 (대략적)
    if (frequency < 0.5) return Colors.red;
    if (frequency < 0.7) return Colors.orange;
    if (frequency < 0.9) return Colors.yellow;
    if (frequency < 1.1) return Colors.green;
    if (frequency < 1.3) return Colors.blue;
    if (frequency < 1.5) return Colors.indigo;
    return Colors.purple;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photonEnergy = _calculatePhotonEnergy();
    final kineticEnergy = _calculateElectronKineticEnergy();
    final isAboveThreshold = photonEnergy >= workFunction;

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
              '양자역학 시뮬레이션',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '광전효과',
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
          category: '양자역학 시뮬레이션',
          title: '광전효과 (Photoelectric Effect)',
          formula: 'E_k = hf - W',
          formulaDescription:
              '광전자의 최대 운동에너지 E_k는 광자 에너지 hf에서 일함수 W를 뺀 값입니다. '
              '아인슈타인은 이 현상을 설명하여 빛의 입자성을 증명했고, 노벨상을 받았습니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: PhotoelectricPainter(
                time: time,
                frequency: frequency,
                workFunction: workFunction,
                photons: photons,
                electrons: electrons,
                photonColor: _getPhotonColor(),
                isAboveThreshold: isAboveThreshold,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 금속 프리셋
              PresetGroup(
                label: '금속 종류',
                presets: [
                  PresetButton(
                    label: '나트륨 (Na)',
                    isSelected: _selectedMetal == 'sodium',
                    onPressed: () => _applyMetalPreset('sodium'),
                  ),
                  PresetButton(
                    label: '아연 (Zn)',
                    isSelected: _selectedMetal == 'zinc',
                    onPressed: () => _applyMetalPreset('zinc'),
                  ),
                  PresetButton(
                    label: '구리 (Cu)',
                    isSelected: _selectedMetal == 'copper',
                    onPressed: () => _applyMetalPreset('copper'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 컨트롤 그룹
              ControlGroup(
                primaryControl: SimSlider(
                  label: '빛의 진동수 (f)',
                  value: frequency,
                  min: 0.3,
                  max: 2.0,
                  step: 0.1,
                  defaultValue: _defaultFrequency,
                  formatValue: (v) => '${v.toStringAsFixed(1)} ×10¹⁵ Hz',
                  onChanged: (v) => setState(() => frequency = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '빛의 세기',
                    value: intensity,
                    min: 0.1,
                    max: 1.0,
                    step: 0.1,
                    defaultValue: _defaultIntensity,
                    formatValue: (v) => '${(v * 100).toInt()}%',
                    onChanged: (v) => setState(() => intensity = v),
                  ),
                  SimSlider(
                    label: '일함수 (W)',
                    value: workFunction,
                    min: 1.0,
                    max: 6.0,
                    step: 0.1,
                    defaultValue: _defaultWorkFunction,
                    formatValue: (v) => '${v.toStringAsFixed(1)} eV',
                    onChanged: (v) => setState(() {
                      workFunction = v;
                      _selectedMetal = null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 물리량 표시
              _PhysicsInfo(
                photonEnergy: photonEnergy,
                workFunction: workFunction,
                kineticEnergy: kineticEnergy,
                photonCount: photonCount,
                electronCount: electronCount,
                isAboveThreshold: isAboveThreshold,
                thresholdFrequency: thresholdFrequency,
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

/// 광자 클래스
class Photon {
  double x;
  double y;
  double vx;
  double wavelength;

  Photon({
    required this.x,
    required this.y,
    required this.vx,
    required this.wavelength,
  });
}

/// 전자 클래스
class Electron {
  double x;
  double y;
  double vx;
  double vy;

  Electron({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });
}

/// 물리량 정보 위젯
class _PhysicsInfo extends StatelessWidget {
  final double photonEnergy;
  final double workFunction;
  final double kineticEnergy;
  final int photonCount;
  final int electronCount;
  final bool isAboveThreshold;
  final double thresholdFrequency;

  const _PhysicsInfo({
    required this.photonEnergy,
    required this.workFunction,
    required this.kineticEnergy,
    required this.photonCount,
    required this.electronCount,
    required this.isAboveThreshold,
    required this.thresholdFrequency,
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
          // 에너지 비교 바
          _EnergyComparisonBar(
            photonEnergy: photonEnergy,
            workFunction: workFunction,
            isAboveThreshold: isAboveThreshold,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoItem(
                label: '광자 에너지',
                value: '${photonEnergy.toStringAsFixed(2)} eV',
              ),
              _InfoItem(
                label: '일함수',
                value: '${workFunction.toStringAsFixed(2)} eV',
              ),
              _InfoItem(
                label: '운동에너지',
                value: '${kineticEnergy.toStringAsFixed(2)} eV',
                color: isAboveThreshold ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: '입사 광자',
                value: '$photonCount',
              ),
              _InfoItem(
                label: '방출 전자',
                value: '$electronCount',
                color: electronCount > 0 ? Colors.green : AppColors.accent,
              ),
              _InfoItem(
                label: '문턱 진동수',
                value: '${thresholdFrequency.toStringAsFixed(2)}×10¹⁵',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 에너지 비교 바
class _EnergyComparisonBar extends StatelessWidget {
  final double photonEnergy;
  final double workFunction;
  final bool isAboveThreshold;

  const _EnergyComparisonBar({
    required this.photonEnergy,
    required this.workFunction,
    required this.isAboveThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final maxEnergy = math.max(photonEnergy, workFunction) * 1.2;
    final photonWidth = (photonEnergy / maxEnergy).clamp(0.0, 1.0);
    final workFunctionWidth = (workFunction / maxEnergy).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'hf vs W: ',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 10,
              ),
            ),
            Text(
              isAboveThreshold ? '전자 방출!' : '에너지 부족',
              style: TextStyle(
                color: isAboveThreshold ? Colors.green : Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            // 배경
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // 일함수 바
            FractionallySizedBox(
              widthFactor: workFunctionWidth,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // 광자 에너지 바
            FractionallySizedBox(
              widthFactor: photonWidth,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isAboveThreshold
                      ? Colors.green.withValues(alpha: 0.8)
                      : Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoItem({required this.label, required this.value, this.color});

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
              color: color ?? AppColors.accent,
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

/// 광전효과 페인터
class PhotoelectricPainter extends CustomPainter {
  final double time;
  final double frequency;
  final double workFunction;
  final List<Photon> photons;
  final List<Electron> electrons;
  final Color photonColor;
  final bool isAboveThreshold;

  PhotoelectricPainter({
    required this.time,
    required this.frequency,
    required this.workFunction,
    required this.photons,
    required this.electrons,
    required this.photonColor,
    required this.isAboveThreshold,
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

    // 광원
    _drawLightSource(canvas, size);

    // 금속 표면
    _drawMetalSurface(canvas, size);

    // 광자
    _drawPhotons(canvas, size);

    // 전자
    _drawElectrons(canvas, size);

    // 에너지 다이어그램
    _drawEnergyDiagram(canvas, size);
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

  void _drawLightSource(Canvas canvas, Size size) {
    final sourceX = 30.0;
    final sourceY = size.height / 2;

    // 광원 글로우
    final gradient = RadialGradient(
      colors: [
        photonColor,
        photonColor.withValues(alpha: 0.3),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(sourceX, sourceY), radius: 30));

    canvas.drawCircle(
      Offset(sourceX, sourceY),
      30,
      Paint()..shader = gradient,
    );

    // 광원 중심
    canvas.drawCircle(
      Offset(sourceX, sourceY),
      12,
      Paint()..color = photonColor,
    );

    // 광선 효과
    final rayPaint = Paint()
      ..color = photonColor.withValues(alpha: 0.3)
      ..strokeWidth = 2;

    for (int i = 0; i < 5; i++) {
      final angle = (i - 2) * 0.15;
      final endX = 180.0;
      final endY = sourceY + math.tan(angle) * (endX - sourceX);
      canvas.drawLine(
        Offset(sourceX + 15, sourceY),
        Offset(endX, endY),
        rayPaint,
      );
    }

    // 레이블
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Light',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(sourceX - 12, sourceY + 40));
  }

  void _drawMetalSurface(Canvas canvas, Size size) {
    final metalX = 200.0;
    final metalWidth = 30.0;

    // 금속 표면 그라데이션
    final metalGradient = LinearGradient(
      colors: [
        const Color(0xFF71717A),
        const Color(0xFF52525B),
        const Color(0xFF3F3F46),
      ],
    ).createShader(
      Rect.fromLTRB(metalX, 50, metalX + metalWidth, size.height - 50),
    );

    canvas.drawRect(
      Rect.fromLTRB(metalX, 50, metalX + metalWidth, size.height - 50),
      Paint()..shader = metalGradient,
    );

    // 금속 테두리
    canvas.drawRect(
      Rect.fromLTRB(metalX, 50, metalX + metalWidth, size.height - 50),
      Paint()
        ..color = const Color(0xFF8B8B8B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 전자 레벨 표시 (일함수)
    if (isAboveThreshold) {
      // 전자 방출 효과
      for (int i = 0; i < 3; i++) {
        final y = 100 + i * 50.0;
        canvas.drawCircle(
          Offset(metalX + 15, y),
          4 + math.sin(time * 5 + i) * 2,
          Paint()..color = Colors.yellow.withValues(alpha: 0.5 + math.sin(time * 3) * 0.3),
        );
      }
    }

    // 레이블
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Metal',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(metalX + 2, size.height - 40));
  }

  void _drawPhotons(Canvas canvas, Size size) {
    for (final photon in photons) {
      // 광자 파동 패킷
      final wavePath = Path();
      wavePath.moveTo(photon.x - 15, photon.y);

      for (double dx = -15; dx <= 15; dx += 2) {
        final amplitude = 5 * math.exp(-dx * dx / 50) *
            math.sin(dx * 0.5 + time * 10);
        wavePath.lineTo(photon.x + dx, photon.y + amplitude);
      }

      canvas.drawPath(
        wavePath,
        Paint()
          ..color = photonColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // 광자 중심점
      canvas.drawCircle(
        Offset(photon.x, photon.y),
        4,
        Paint()..color = photonColor,
      );

      // 광자 글로우
      canvas.drawCircle(
        Offset(photon.x, photon.y),
        8,
        Paint()..color = photonColor.withValues(alpha: 0.3),
      );
    }
  }

  void _drawElectrons(Canvas canvas, Size size) {
    for (final electron in electrons) {
      // 전자 궤적
      canvas.drawCircle(
        Offset(electron.x, electron.y),
        5,
        Paint()..color = Colors.yellow,
      );

      // 전자 글로우
      canvas.drawCircle(
        Offset(electron.x, electron.y),
        10,
        Paint()..color = Colors.yellow.withValues(alpha: 0.3),
      );

      // 속도 화살표
      final arrowEnd = Offset(
        electron.x + electron.vx * 5,
        electron.y + electron.vy * 5,
      );
      canvas.drawLine(
        Offset(electron.x, electron.y),
        arrowEnd,
        Paint()
          ..color = Colors.yellow.withValues(alpha: 0.5)
          ..strokeWidth = 2,
      );
    }
  }

  void _drawEnergyDiagram(Canvas canvas, Size size) {
    final diagramX = size.width - 100;
    final diagramY = 30.0;
    final diagramHeight = 100.0;

    // 배경
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(diagramX - 10, diagramY - 10, 90, diagramHeight + 40),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.card.withValues(alpha: 0.9),
    );

    // 에너지 축
    canvas.drawLine(
      Offset(diagramX, diagramY + diagramHeight),
      Offset(diagramX, diagramY),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 1,
    );

    // 일함수 레벨
    final workFunctionY = diagramY + diagramHeight * (1 - workFunction / 5);
    canvas.drawLine(
      Offset(diagramX, workFunctionY),
      Offset(diagramX + 60, workFunctionY),
      Paint()
        ..color = Colors.orange
        ..strokeWidth = 2,
    );

    // 광자 에너지 레벨
    final photonEnergy = frequency * 2.5;
    final photonEnergyY = diagramY + diagramHeight * (1 - photonEnergy / 5);
    canvas.drawLine(
      Offset(diagramX, photonEnergyY.clamp(diagramY, diagramY + diagramHeight)),
      Offset(diagramX + 60, photonEnergyY.clamp(diagramY, diagramY + diagramHeight)),
      Paint()
        ..color = photonColor
        ..strokeWidth = 2,
    );

    // 레이블
    final wLabel = TextPainter(
      text: const TextSpan(
        text: 'W',
        style: TextStyle(color: Colors.orange, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    );
    wLabel.layout();
    wLabel.paint(canvas, Offset(diagramX + 65, workFunctionY - 6));

    final hfLabel = TextPainter(
      text: const TextSpan(
        text: 'hf',
        style: TextStyle(color: AppColors.accent, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    );
    hfLabel.layout();
    hfLabel.paint(canvas, Offset(diagramX + 65, photonEnergyY.clamp(diagramY, diagramY + diagramHeight) - 6));

    // 제목
    final title = TextPainter(
      text: const TextSpan(
        text: 'Energy',
        style: TextStyle(color: AppColors.muted, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    );
    title.layout();
    title.paint(canvas, Offset(diagramX + 15, diagramY + diagramHeight + 15));
  }

  @override
  bool shouldRepaint(covariant PhotoelectricPainter oldDelegate) => true;
}
