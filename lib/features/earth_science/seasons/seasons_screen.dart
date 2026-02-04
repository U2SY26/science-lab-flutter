import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 계절 시뮬레이션 화면 (Earth's Seasons)
class SeasonsScreen extends StatefulWidget {
  const SeasonsScreen({super.key});

  @override
  State<SeasonsScreen> createState() => _SeasonsScreenState();
}

class _SeasonsScreenState extends State<SeasonsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 시뮬레이션 파라미터
  double _dayOfYear = 172; // 0-365 (여름 하지부터 시작)
  double _axialTilt = 23.5; // 지축 기울기 (도)
  bool _isAnimating = false;
  double _animationSpeed = 1.0;
  bool _showSunRays = true;
  bool _showLabels = true;
  String _selectedHemisphere = 'north'; // 'north' or 'south'

  // 계절 데이터
  static const List<Map<String, dynamic>> _seasons = [
    {
      'name': '춘분 (Spring Equinox)',
      'day': 80,
      'north': '봄',
      'south': '가을',
      'description': '낮과 밤의 길이가 같음 (3월 21일경)',
    },
    {
      'name': '하지 (Summer Solstice)',
      'day': 172,
      'north': '여름',
      'south': '겨울',
      'description': '북반구: 낮이 가장 긴 날 (6월 21일경)',
    },
    {
      'name': '추분 (Autumn Equinox)',
      'day': 266,
      'north': '가을',
      'south': '봄',
      'description': '낮과 밤의 길이가 같음 (9월 23일경)',
    },
    {
      'name': '동지 (Winter Solstice)',
      'day': 356,
      'north': '겨울',
      'south': '여름',
      'description': '북반구: 밤이 가장 긴 날 (12월 22일경)',
    },
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
      _dayOfYear += 0.5 * _animationSpeed;
      if (_dayOfYear >= 365) {
        _dayOfYear = 0;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _dayOfYear = 172;
      _axialTilt = 23.5;
      _isAnimating = false;
    });
  }

  void _selectSeason(int seasonIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      _dayOfYear = _seasons[seasonIndex]['day'].toDouble();
    });
  }

  // 현재 계절 인덱스 계산
  int get _currentSeasonIndex {
    if (_dayOfYear < 80) return 3; // 동지 ~ 춘분
    if (_dayOfYear < 172) return 0; // 춘분 ~ 하지
    if (_dayOfYear < 266) return 1; // 하지 ~ 추분
    if (_dayOfYear < 356) return 2; // 추분 ~ 동지
    return 3; // 동지 ~ 연말
  }

  // 현재 반구 계절
  String get _currentSeason {
    final season = _seasons[_currentSeasonIndex];
    return _selectedHemisphere == 'north' ? season['north'] : season['south'];
  }

  // 낮의 길이 계산 (시간)
  double get _daylightHours {
    final tiltRad = _axialTilt * math.pi / 180;
    final dayAngle = (_dayOfYear / 365) * 2 * math.pi;
    final declination = tiltRad * math.sin(dayAngle - math.pi / 2);

    // 위도 45도 기준 계산
    const latitude = 45.0 * math.pi / 180;
    final factor = _selectedHemisphere == 'north' ? 1 : -1;
    final hourAngle = math.acos(-math.tan(latitude) * math.tan(declination * factor));
    final daylight = (hourAngle / math.pi) * 24;
    return daylight.clamp(0.0, 24.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSeasonData = _seasons[_currentSeasonIndex];

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
              '계절 (Earth Seasons)',
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
          title: '계절 (Earth Seasons)',
          formula: '지축 기울기: 23.5',
          formulaDescription:
              '지구의 자전축은 공전궤도면에 대해 약 23.5도 기울어져 있습니다. 이 기울기로 인해 일년 동안 태양 고도와 낮의 길이가 변화하며 계절이 발생합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: SeasonsPainter(
                dayOfYear: _dayOfYear,
                axialTilt: _axialTilt,
                showSunRays: _showSunRays,
                showLabels: _showLabels,
                selectedHemisphere: _selectedHemisphere,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 반구 선택
              SimSegment<String>(
                label: '기준 반구',
                options: const {
                  'north': '북반구',
                  'south': '남반구',
                },
                selected: _selectedHemisphere,
                onChanged: (v) => setState(() => _selectedHemisphere = v),
              ),
              const SizedBox(height: 16),
              // 계절 프리셋 버튼
              PresetGroup(
                label: '계절 선택',
                presets: List.generate(4, (index) {
                  final season = _seasons[index];
                  return PresetButton(
                    label: _selectedHemisphere == 'north'
                        ? season['north']
                        : season['south'],
                    isSelected: _currentSeasonIndex == index,
                    onPressed: () => _selectSeason(index),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // 날짜 슬라이더
              ControlGroup(
                primaryControl: SimSlider(
                  label: '연중 일수 (Day of Year)',
                  value: _dayOfYear,
                  min: 0,
                  max: 365,
                  defaultValue: 172,
                  formatValue: (v) => '${v.toInt()}일',
                  onChanged: (v) => setState(() => _dayOfYear = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '지축 기울기',
                    value: _axialTilt,
                    min: 0,
                    max: 45,
                    step: 0.5,
                    defaultValue: 23.5,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _axialTilt = v),
                  ),
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
                    label: '태양 광선 표시',
                    value: _showSunRays,
                    onChanged: (v) => setState(() => _showSunRays = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 현재 계절 정보
              _SeasonInfo(
                seasonName: currentSeasonData['name'],
                currentSeason: _currentSeason,
                daylightHours: _daylightHours,
                description: currentSeasonData['description'],
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

/// 계절 정보 위젯
class _SeasonInfo extends StatelessWidget {
  final String seasonName;
  final String currentSeason;
  final double daylightHours;
  final String description;

  const _SeasonInfo({
    required this.seasonName,
    required this.currentSeason,
    required this.daylightHours,
    required this.description,
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
              _getSeasonIcon(currentSeason),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      seasonName,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      currentSeason,
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '낮의 길이',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${daylightHours.toStringAsFixed(1)}시간',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 14,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSeasonIcon(String season) {
    IconData icon;
    Color color;

    switch (season) {
      case '봄':
        icon = Icons.local_florist;
        color = const Color(0xFF90EE90);
        break;
      case '여름':
        icon = Icons.wb_sunny;
        color = const Color(0xFFFFD700);
        break;
      case '가을':
        icon = Icons.eco;
        color = const Color(0xFFFF8C00);
        break;
      case '겨울':
        icon = Icons.ac_unit;
        color = const Color(0xFF87CEEB);
        break;
      default:
        icon = Icons.public;
        color = AppColors.accent;
    }

    return Icon(icon, size: 24, color: color);
  }
}

/// 계절 페인터
class SeasonsPainter extends CustomPainter {
  final double dayOfYear;
  final double axialTilt;
  final bool showSunRays;
  final bool showLabels;
  final String selectedHemisphere;

  SeasonsPainter({
    required this.dayOfYear,
    required this.axialTilt,
    required this.showSunRays,
    required this.showLabels,
    required this.selectedHemisphere,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF050510),
    );

    // 별 그리기
    _drawStars(canvas, size);

    // 태양 (중앙)
    _drawSun(canvas, Offset(centerX, centerY));

    // 지구 궤도
    _drawOrbit(canvas, Offset(centerX, centerY), size.width * 0.38);

    // 지구 위치 계산
    final orbitRadius = size.width * 0.38;
    final earthAngle = (dayOfYear / 365) * 2 * math.pi - math.pi / 2;
    final earthX = centerX + orbitRadius * math.cos(earthAngle);
    final earthY = centerY + orbitRadius * math.sin(earthAngle);
    final earthPos = Offset(earthX, earthY);

    // 태양 광선
    if (showSunRays) {
      _drawSunRays(canvas, Offset(centerX, centerY), earthPos);
    }

    // 지구 그리기 (기울기 포함)
    _drawEarth(canvas, earthPos, earthAngle);

    // 4계절 위치 표시
    _drawSeasonMarkers(canvas, Offset(centerX, centerY), orbitRadius);

    // 라벨
    if (showLabels) {
      _drawLabels(canvas, size, Offset(centerX, centerY), earthPos);
    }
  }

  void _drawStars(Canvas canvas, Size size) {
    final random = math.Random(42);
    final starPaint = Paint()..color = Colors.white;

    for (int i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.2 + 0.3;
      final alpha = random.nextDouble() * 0.4 + 0.2;
      starPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  void _drawSun(Canvas canvas, Offset center) {
    const sunRadius = 30.0;

    // 태양 글로우
    final glowGradient = RadialGradient(
      colors: [
        const Color(0xFFFFD700),
        const Color(0xFFFF8C00),
        const Color(0xFFFF4500).withValues(alpha: 0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: sunRadius * 2));

    canvas.drawCircle(center, sunRadius * 2, Paint()..shader = glowGradient);

    // 태양 본체
    final sunGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        const Color(0xFFFFFACD),
        const Color(0xFFFFD700),
        const Color(0xFFFF8C00),
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: sunRadius));

    canvas.drawCircle(center, sunRadius, Paint()..shader = sunGradient);
  }

  void _drawOrbit(Canvas canvas, Offset center, double radius) {
    // 약간의 타원형 궤도
    final rect = Rect.fromCenter(
      center: center,
      width: radius * 2,
      height: radius * 1.9,
    );

    canvas.drawOval(
      rect,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawSunRays(Canvas canvas, Offset sunPos, Offset earthPos) {
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.2)
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(sunPos, earthPos, rayPaint);

    // 평행 광선 (지구에 도달하는 빛)
    final direction = (earthPos - sunPos);
    final normalizedDir = direction / direction.distance;
    final perpendicular = Offset(-normalizedDir.dy, normalizedDir.dx);

    final thinRayPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (int i = -3; i <= 3; i++) {
      final offset = perpendicular * (i * 15.0);
      final start = sunPos + offset + normalizedDir * 50;
      final end = earthPos + offset - normalizedDir * 30;
      canvas.drawLine(start, end, thinRayPaint);
    }
  }

  void _drawEarth(Canvas canvas, Offset center, double orbitAngle) {
    const earthRadius = 18.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // 지축 기울기 적용
    final tiltRad = axialTilt * math.pi / 180;
    canvas.rotate(tiltRad);

    // 지구 그림자
    canvas.drawCircle(
      const Offset(1, 1),
      earthRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // 지구 본체
    final earthGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        const Color(0xFF4169E1),
        const Color(0xFF1E3A8A),
        const Color(0xFF0F172A),
      ],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: earthRadius));

    canvas.drawCircle(Offset.zero, earthRadius, Paint()..shader = earthGradient);

    // 대륙
    final landPaint = Paint()..color = const Color(0xFF228B22).withValues(alpha: 0.5);
    canvas.drawCircle(const Offset(-5, -3), 4, landPaint);
    canvas.drawCircle(const Offset(4, 6), 5, landPaint);
    canvas.drawCircle(const Offset(7, -5), 3, landPaint);

    // 지축 표시
    final axisPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      const Offset(0, -earthRadius - 10),
      const Offset(0, earthRadius + 10),
      axisPaint,
    );

    // 북극점 표시
    canvas.drawCircle(
      const Offset(0, -earthRadius - 10),
      3,
      Paint()..color = AppColors.accent,
    );

    // 적도선
    canvas.drawLine(
      Offset(-earthRadius, 0),
      Offset(earthRadius, 0),
      Paint()
        ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // 북반구/남반구 강조
    if (selectedHemisphere == 'north') {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: earthRadius - 2),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
      );
    } else {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: earthRadius - 2),
        0,
        math.pi,
        false,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
      );
    }

    canvas.restore();
  }

  void _drawSeasonMarkers(Canvas canvas, Offset center, double radius) {
    final positions = [
      {'angle': -math.pi / 2, 'label': '하지', 'color': const Color(0xFFFFD700)},
      {'angle': 0.0, 'label': '추분', 'color': const Color(0xFFFF8C00)},
      {'angle': math.pi / 2, 'label': '동지', 'color': const Color(0xFF87CEEB)},
      {'angle': math.pi, 'label': '춘분', 'color': const Color(0xFF90EE90)},
    ];

    for (final pos in positions) {
      final angle = pos['angle'] as double;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = (pos['color'] as Color).withValues(alpha: 0.5),
      );

      // 라벨
      final textPainter = TextPainter(
        text: TextSpan(
          text: pos['label'] as String,
          style: TextStyle(
            color: (pos['color'] as Color).withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final labelOffset = Offset(
        x - textPainter.width / 2 + (angle == 0 ? 20 : angle == math.pi ? -20 : 0),
        y - textPainter.height / 2 + (angle == -math.pi / 2 ? -15 : angle == math.pi / 2 ? 15 : 0),
      );
      textPainter.paint(canvas, labelOffset);
    }
  }

  void _drawLabels(Canvas canvas, Size size, Offset sunPos, Offset earthPos) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 태양 라벨
    textPainter.text = TextSpan(
      text: '태양',
      style: TextStyle(
        color: const Color(0xFFFFD700),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, sunPos + Offset(-textPainter.width / 2, 40));

    // 지구 라벨
    textPainter.text = TextSpan(
      text: '지구',
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 11,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, earthPos + Offset(-textPainter.width / 2, 30));

    // 기울기 설명
    textPainter.text = TextSpan(
      text: '지축 기울기: ${axialTilt.toStringAsFixed(1)}',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height - 25));
  }

  @override
  bool shouldRepaint(covariant SeasonsPainter oldDelegate) {
    return dayOfYear != oldDelegate.dayOfYear ||
        axialTilt != oldDelegate.axialTilt ||
        showSunRays != oldDelegate.showSunRays ||
        showLabels != oldDelegate.showLabels ||
        selectedHemisphere != oldDelegate.selectedHemisphere;
  }
}
