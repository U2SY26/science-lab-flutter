import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 달의 위상 시뮬레이션 화면 (Moon Phases)
class MoonPhasesScreen extends StatefulWidget {
  const MoonPhasesScreen({super.key});

  @override
  State<MoonPhasesScreen> createState() => _MoonPhasesScreenState();
}

class _MoonPhasesScreenState extends State<MoonPhasesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 시뮬레이션 파라미터
  double _dayOfMonth = 0; // 0-29.5 (한 달의 위상 주기)
  bool _isAnimating = false;
  double _animationSpeed = 1.0;
  bool _showOrbits = true;
  bool _showLabels = true;

  // 달의 위상 이름과 설명
  static const List<Map<String, String>> _phases = [
    {'name': '새달 (New Moon)', 'korean': '삭', 'description': '달이 태양과 지구 사이에 위치'},
    {'name': '초승달', 'korean': '초승달', 'description': '오른쪽이 밝은 초승달'},
    {'name': '상현달 (First Quarter)', 'korean': '상현', 'description': '오른쪽 절반이 밝음'},
    {'name': '차오르는 볼록달', 'korean': '상현망간', 'description': '오른쪽이 더 밝음'},
    {'name': '보름달 (Full Moon)', 'korean': '망', 'description': '지구가 태양과 달 사이에 위치'},
    {'name': '이지러지는 볼록달', 'korean': '망하간', 'description': '왼쪽이 더 밝음'},
    {'name': '하현달 (Last Quarter)', 'korean': '하현', 'description': '왼쪽 절반이 밝음'},
    {'name': '그믐달', 'korean': '그믐', 'description': '왼쪽이 밝은 그믐달'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _updateAnimation() {
    if (!_isAnimating) return;

    setState(() {
      _dayOfMonth += 0.05 * _animationSpeed;
      if (_dayOfMonth >= 29.5) {
        _dayOfMonth = 0;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _dayOfMonth = 0;
      _isAnimating = false;
    });
  }

  void _selectPhase(int phaseIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      _dayOfMonth = phaseIndex * (29.5 / 8);
    });
  }

  // 현재 위상 인덱스 계산 (0-7)
  int get _currentPhaseIndex {
    return ((_dayOfMonth / 29.5) * 8).floor() % 8;
  }

  // 달의 조도 계산 (0-1, 0=새달, 1=보름달)
  double get _illumination {
    final phase = _dayOfMonth / 29.5;
    // 코사인 함수를 사용하여 조도 계산
    return (1 - math.cos(phase * 2 * math.pi)) / 2;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPhase = _phases[_currentPhaseIndex];

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
              '달의 위상 (Moon Phases)',
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
              _showLabels ? Icons.label : Icons.label_off,
              color: _showLabels ? AppColors.accent : AppColors.muted,
            ),
            onPressed: () => setState(() => _showLabels = !_showLabels),
            tooltip: '라벨 표시',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '달의 위상 (Moon Phases)',
          formula: 'P = 29.53 days (삭망월)',
          formulaDescription:
              '달이 지구 주위를 공전하면서 태양 빛을 받는 부분이 변화합니다. 삭망월(synodic month)은 같은 위상으로 돌아오는 데 걸리는 시간으로 약 29.53일입니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: MoonPhasesPainter(
                dayOfMonth: _dayOfMonth,
                showOrbits: _showOrbits,
                showLabels: _showLabels,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 위상 프리셋 버튼
              PresetGroup(
                label: '위상 선택',
                presets: List.generate(8, (index) {
                  return PresetButton(
                    label: _phases[index]['korean']!,
                    isSelected: _currentPhaseIndex == index,
                    onPressed: () => _selectPhase(index),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // 날짜 슬라이더
              ControlGroup(
                primaryControl: SimSlider(
                  label: '날짜 (Day)',
                  value: _dayOfMonth,
                  min: 0,
                  max: 29.5,
                  defaultValue: 0,
                  formatValue: (v) => '${v.toStringAsFixed(1)}일',
                  onChanged: (v) => setState(() => _dayOfMonth = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '애니메이션 속도',
                    value: _animationSpeed,
                    min: 0.5,
                    max: 3.0,
                    step: 0.5,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() => _animationSpeed = v),
                  ),
                  SimToggle(
                    label: '궤도 표시',
                    value: _showOrbits,
                    onChanged: (v) => setState(() => _showOrbits = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 현재 위상 정보
              _PhaseInfo(
                phaseName: currentPhase['name']!,
                description: currentPhase['description']!,
                illumination: _illumination,
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

/// 위상 정보 위젯
class _PhaseInfo extends StatelessWidget {
  final String phaseName;
  final String description;
  final double illumination;

  const _PhaseInfo({
    required this.phaseName,
    required this.description,
    required this.illumination,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.brightness_3,
                size: 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  phaseName,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(illumination * 100).toStringAsFixed(0)}% 밝음',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// 달 위상 페인터
class MoonPhasesPainter extends CustomPainter {
  final double dayOfMonth;
  final bool showOrbits;
  final bool showLabels;

  MoonPhasesPainter({
    required this.dayOfMonth,
    required this.showOrbits,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);

    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050510),
    );

    // 별 그리기
    _drawStars(canvas, size);

    // 태양 광선 (왼쪽에서 오른쪽으로)
    _drawSunRays(canvas, size);

    // 지구 궤도 (선택적)
    if (showOrbits) {
      _drawOrbit(canvas, center, size.width * 0.35);
    }

    // 지구 그리기
    _drawEarth(canvas, center);

    // 달의 위치 계산
    final phase = dayOfMonth / 29.5;
    final moonOrbitRadius = size.width * 0.35;
    final moonAngle = phase * 2 * math.pi - math.pi / 2; // 위에서 시작
    final moonX = centerX + moonOrbitRadius * math.cos(moonAngle);
    final moonY = centerY + moonOrbitRadius * math.sin(moonAngle);
    final moonPos = Offset(moonX, moonY);

    // 달 그리기 (위상 표시)
    _drawMoon(canvas, moonPos, phase);

    // 큰 달 미리보기 (오른쪽 상단)
    _drawMoonPreview(canvas, size, phase);

    // 라벨
    if (showLabels) {
      _drawLabels(canvas, size, center, moonPos);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);
    final starPaint = Paint()..color = Colors.white;

    for (int i = 0; i < 80; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;
      final alpha = random.nextDouble() * 0.5 + 0.3;
      starPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  void _drawSunRays(Canvas canvas, Size size) {
    // 태양 광선 그라데이션 (왼쪽에서)
    final rayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.center,
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.5, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.5, size.height),
      rayPaint,
    );

    // 태양 아이콘 (왼쪽 가장자리)
    final sunCenter = Offset(-20, size.height / 2);
    final sunGradient = RadialGradient(
      colors: [
        const Color(0xFFFFD700),
        const Color(0xFFFF8C00),
        const Color(0xFFFF4500).withValues(alpha: 0.5),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    ).createShader(Rect.fromCircle(center: sunCenter, radius: 60));

    canvas.drawCircle(sunCenter, 60, Paint()..shader = sunGradient);
  }

  void _drawOrbit(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawEarth(Canvas canvas, Offset center) {
    const earthRadius = 25.0;

    // 지구 그림자
    canvas.drawCircle(
      center + const Offset(2, 2),
      earthRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // 지구 본체 (바다색)
    final earthGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        const Color(0xFF4169E1),
        const Color(0xFF1E3A8A),
        const Color(0xFF0F172A),
      ],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: earthRadius));

    canvas.drawCircle(center, earthRadius, Paint()..shader = earthGradient);

    // 대륙 (간단히 녹색 점으로 표현)
    final landPaint = Paint()..color = const Color(0xFF228B22).withValues(alpha: 0.6);
    canvas.drawCircle(center + const Offset(-8, -5), 6, landPaint);
    canvas.drawCircle(center + const Offset(5, 8), 8, landPaint);
    canvas.drawCircle(center + const Offset(10, -8), 5, landPaint);

    // 지구 하이라이트
    canvas.drawCircle(
      center + const Offset(-8, -8),
      5,
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
  }

  void _drawMoon(Canvas canvas, Offset center, double phase) {
    const moonRadius = 15.0;

    // 달 그림자
    canvas.drawCircle(
      center + const Offset(1, 1),
      moonRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // 달 본체 (회색)
    final moonBasePaint = Paint()..color = const Color(0xFF888888);
    canvas.drawCircle(center, moonRadius, moonBasePaint);

    // 달 표면 텍스처 (크레이터)
    final craterPaint = Paint()..color = const Color(0xFF666666);
    canvas.drawCircle(center + const Offset(-4, -3), 3, craterPaint);
    canvas.drawCircle(center + const Offset(5, 2), 2.5, craterPaint);
    canvas.drawCircle(center + const Offset(-2, 5), 2, craterPaint);

    // 위상에 따른 그림자
    _drawMoonPhase(canvas, center, moonRadius, phase);
  }

  void _drawMoonPhase(Canvas canvas, Offset center, double radius, double phase) {
    // phase: 0 = 새달, 0.5 = 보름달, 1 = 새달
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    final shadowPaint = Paint()..color = const Color(0xFF1a1a1a);

    if (phase < 0.5) {
      // 새달에서 보름달로
      final shadowWidth = radius * 2 * (1 - phase * 2);
      final shadowRect = Rect.fromLTWH(
        center.dx + radius - shadowWidth,
        center.dy - radius,
        shadowWidth,
        radius * 2,
      );
      canvas.drawOval(shadowRect, shadowPaint);
    } else {
      // 보름달에서 새달로
      final shadowWidth = radius * 2 * ((phase - 0.5) * 2);
      final shadowRect = Rect.fromLTWH(
        center.dx - radius,
        center.dy - radius,
        shadowWidth,
        radius * 2,
      );
      canvas.drawOval(shadowRect, shadowPaint);
    }

    canvas.restore();
  }

  void _drawMoonPreview(Canvas canvas, Size size, double phase) {
    final previewCenter = Offset(size.width - 50, 50);
    const previewRadius = 35.0;

    // 배경 원
    canvas.drawCircle(
      previewCenter,
      previewRadius + 5,
      Paint()..color = const Color(0xFF1a2030),
    );

    // 달 본체
    canvas.drawCircle(
      previewCenter,
      previewRadius,
      Paint()..color = const Color(0xFFD4D4D4),
    );

    // 크레이터
    final craterPaint = Paint()..color = const Color(0xFFAAAAAA);
    canvas.drawCircle(previewCenter + const Offset(-10, -8), 6, craterPaint);
    canvas.drawCircle(previewCenter + const Offset(12, 5), 5, craterPaint);
    canvas.drawCircle(previewCenter + const Offset(-5, 12), 4, craterPaint);
    canvas.drawCircle(previewCenter + const Offset(8, -12), 3, craterPaint);

    // 위상 그림자
    _drawMoonPhase(canvas, previewCenter, previewRadius, phase);

    // 테두리
    canvas.drawCircle(
      previewCenter,
      previewRadius,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawLabels(Canvas canvas, Size size, Offset earthPos, Offset moonPos) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 지구 라벨
    textPainter.text = TextSpan(
      text: '지구',
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, earthPos + Offset(-textPainter.width / 2, 30));

    // 달 라벨
    textPainter.text = TextSpan(
      text: '달',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 11,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, moonPos + Offset(-textPainter.width / 2, 20));

    // 태양 방향 표시
    textPainter.text = TextSpan(
      text: '태양 방향',
      style: TextStyle(
        color: const Color(0xFFFFD700),
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height / 2 - 30));

    // 화살표
    final arrowPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(10, size.height / 2 - 10),
      Offset(50, size.height / 2 - 10),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(40, size.height / 2 - 15),
      Offset(50, size.height / 2 - 10),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(40, size.height / 2 - 5),
      Offset(50, size.height / 2 - 10),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant MoonPhasesPainter oldDelegate) {
    return dayOfMonth != oldDelegate.dayOfMonth ||
        showOrbits != oldDelegate.showOrbits ||
        showLabels != oldDelegate.showLabels;
  }
}
