import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 이중슬릿 실험 시뮬레이션 화면
/// Double-slit experiment simulation
class DoubleSlitScreen extends StatefulWidget {
  const DoubleSlitScreen({super.key});

  @override
  State<DoubleSlitScreen> createState() => _DoubleSlitScreenState();
}

class _DoubleSlitScreenState extends State<DoubleSlitScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 물리 파라미터 (기본값)
  static const double _defaultSlitDistance = 40.0;
  static const double _defaultWavelength = 20.0;
  static const double _defaultSlitWidth = 10.0;

  double slitDistance = _defaultSlitDistance;
  double wavelength = _defaultWavelength;
  double slitWidth = _defaultSlitWidth;
  bool isRunning = true;
  bool isParticleMode = false; // true: 입자, false: 파동

  // 애니메이션 상태
  double time = 0;
  List<Particle> particles = [];
  List<double> intensityPattern = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    _controller.repeat();
    _initializeIntensityPattern();
  }

  void _initializeIntensityPattern() {
    intensityPattern = List.generate(200, (i) => 0.0);
  }

  void _updatePhysics() {
    if (!isRunning) return;

    setState(() {
      time += 0.05;

      if (isParticleMode) {
        // 입자 모드: 확률적 입자 생성
        if (_random.nextDouble() < 0.3) {
          _emitParticle();
        }

        // 입자 업데이트
        particles = particles.where((p) {
          p.x += p.vx;
          if (p.x > 300) {
            // 스크린에 도달 - 간섭 패턴에 따라 위치 결정
            final screenY = p.y.clamp(0, 199).toInt();
            intensityPattern[screenY] += 0.02;
            return false;
          }
          return true;
        }).toList();

        // 오래된 패턴 감쇠
        for (int i = 0; i < intensityPattern.length; i++) {
          intensityPattern[i] *= 0.999;
        }
      }
    });
  }

  void _emitParticle() {
    // 슬릿을 통과하는 입자 생성 (확률적)
    final centerY = 100.0;
    final halfDist = slitDistance / 2;

    // 슬릿 1 또는 슬릿 2를 통과
    final throughSlit1 = _random.nextBool();
    final slitY = throughSlit1
        ? centerY - halfDist
        : centerY + halfDist;

    // 슬릿을 통과한 후 회절
    final diffraction = (_random.nextDouble() - 0.5) * slitWidth * 2;

    // 간섭 패턴 계산
    final targetY = _calculateInterferenceY(slitY + diffraction);

    particles.add(Particle(
      x: 100,
      y: slitY + diffraction,
      vx: 3,
      vy: (targetY - (slitY + diffraction)) * 0.02,
    ));
  }

  double _calculateInterferenceY(double startY) {
    // 간섭 패턴에 기반한 목표 y 위치 계산
    final phase = (startY - 100) * math.pi / slitDistance;
    final interference = math.cos(phase * wavelength / 10).abs();
    return startY + (interference - 0.5) * slitDistance * 2;
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      particles.clear();
      _initializeIntensityPattern();
    });
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    setState(() {
      isParticleMode = !isParticleMode;
      particles.clear();
      _initializeIntensityPattern();
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
              '양자역학 시뮬레이션',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '이중슬릿 실험',
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
              isParticleMode ? Icons.blur_on : Icons.waves,
              color: AppColors.accent,
            ),
            onPressed: _toggleMode,
            tooltip: isParticleMode ? '파동 모드' : '입자 모드',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '이중슬릿 실험 (Double-Slit)',
          formula: 'd sin(θ) = nλ',
          formulaDescription:
              '보강 간섭 조건: 슬릿 간격 d, 파장 λ, 정수 n에 대해 밝은 무늬가 형성됩니다. '
              '파동-입자 이중성: 입자 하나하나가 두 슬릿을 동시에 통과하며 간섭 패턴을 만듭니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: DoubleSlitPainter(
                time: time,
                slitDistance: slitDistance,
                wavelength: wavelength,
                slitWidth: slitWidth,
                isParticleMode: isParticleMode,
                particles: particles,
                intensityPattern: intensityPattern,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 모드 선택
              SimSegment<bool>(
                label: '관측 모드',
                options: const {
                  false: '파동 (Wave)',
                  true: '입자 (Particle)',
                },
                selected: isParticleMode,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    isParticleMode = v;
                    particles.clear();
                    _initializeIntensityPattern();
                  });
                },
              ),
              const SizedBox(height: 16),
              // 컨트롤 그룹
              ControlGroup(
                primaryControl: SimSlider(
                  label: '슬릿 간격 (d)',
                  value: slitDistance,
                  min: 20,
                  max: 80,
                  defaultValue: _defaultSlitDistance,
                  formatValue: (v) => '${v.toInt()} px',
                  onChanged: (v) => setState(() => slitDistance = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '파장 (λ)',
                    value: wavelength,
                    min: 10,
                    max: 40,
                    defaultValue: _defaultWavelength,
                    formatValue: (v) => '${v.toInt()} px',
                    onChanged: (v) => setState(() => wavelength = v),
                  ),
                  SimSlider(
                    label: '슬릿 폭',
                    value: slitWidth,
                    min: 5,
                    max: 20,
                    defaultValue: _defaultSlitWidth,
                    formatValue: (v) => '${v.toInt()} px',
                    onChanged: (v) => setState(() => slitWidth = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 물리량 표시
              _PhysicsInfo(
                slitDistance: slitDistance,
                wavelength: wavelength,
                particleCount: particles.length,
                isParticleMode: isParticleMode,
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
                label: isParticleMode ? '파동' : '입자',
                icon: isParticleMode ? Icons.waves : Icons.blur_on,
                onPressed: _toggleMode,
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

/// 입자 클래스
class Particle {
  double x;
  double y;
  double vx;
  double vy;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });
}

/// 물리량 정보 위젯
class _PhysicsInfo extends StatelessWidget {
  final double slitDistance;
  final double wavelength;
  final int particleCount;
  final bool isParticleMode;

  const _PhysicsInfo({
    required this.slitDistance,
    required this.wavelength,
    required this.particleCount,
    required this.isParticleMode,
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
      child: Row(
        children: [
          _InfoItem(
            label: '슬릿 간격',
            value: '${slitDistance.toInt()} px',
          ),
          _InfoItem(
            label: '파장',
            value: '${wavelength.toInt()} px',
          ),
          _InfoItem(
            label: isParticleMode ? '입자 수' : '모드',
            value: isParticleMode ? '$particleCount' : '파동',
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

/// 이중슬릿 페인터
class DoubleSlitPainter extends CustomPainter {
  final double time;
  final double slitDistance;
  final double wavelength;
  final double slitWidth;
  final bool isParticleMode;
  final List<Particle> particles;
  final List<double> intensityPattern;

  DoubleSlitPainter({
    required this.time,
    required this.slitDistance,
    required this.wavelength,
    required this.slitWidth,
    required this.isParticleMode,
    required this.particles,
    required this.intensityPattern,
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

    final centerY = size.height / 2;
    final barrierX = size.width * 0.3;
    final screenX = size.width * 0.85;

    // 슬릿 장벽 그리기
    _drawBarrier(canvas, size, barrierX, centerY);

    if (isParticleMode) {
      // 입자 모드
      _drawParticles(canvas, size);
      _drawIntensityScreen(canvas, size, screenX, centerY);
    } else {
      // 파동 모드
      _drawWaveInterference(canvas, size, barrierX, centerY);
      _drawInterferencePattern(canvas, size, screenX, centerY);
    }

    // 광원 표시
    _drawSource(canvas, size);
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

  void _drawBarrier(Canvas canvas, Size size, double barrierX, double centerY) {
    final barrierPaint = Paint()
      ..color = const Color(0xFF4A5568)
      ..style = PaintingStyle.fill;

    final halfDist = slitDistance / 2;
    final halfWidth = slitWidth / 2;

    // 상단 장벽
    canvas.drawRect(
      Rect.fromLTRB(barrierX - 5, 0, barrierX + 5, centerY - halfDist - halfWidth),
      barrierPaint,
    );

    // 중간 장벽
    canvas.drawRect(
      Rect.fromLTRB(
        barrierX - 5,
        centerY - halfDist + halfWidth,
        barrierX + 5,
        centerY + halfDist - halfWidth,
      ),
      barrierPaint,
    );

    // 하단 장벽
    canvas.drawRect(
      Rect.fromLTRB(barrierX - 5, centerY + halfDist + halfWidth, barrierX + 5, size.height),
      barrierPaint,
    );

    // 슬릿 하이라이트
    final slitGlow = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(
        barrierX - 2,
        centerY - halfDist - halfWidth,
        barrierX + 2,
        centerY - halfDist + halfWidth,
      ),
      slitGlow,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        barrierX - 2,
        centerY + halfDist - halfWidth,
        barrierX + 2,
        centerY + halfDist + halfWidth,
      ),
      slitGlow,
    );
  }

  void _drawWaveInterference(Canvas canvas, Size size, double barrierX, double centerY) {
    final halfDist = slitDistance / 2;
    final slit1Y = centerY - halfDist;
    final slit2Y = centerY + halfDist;

    // 파동 그리기
    for (double x = barrierX + 10; x < size.width - 20; x += 3) {
      for (double y = 10; y < size.height - 10; y += 3) {
        // 두 슬릿에서의 거리
        final r1 = math.sqrt(math.pow(x - barrierX, 2) + math.pow(y - slit1Y, 2));
        final r2 = math.sqrt(math.pow(x - barrierX, 2) + math.pow(y - slit2Y, 2));

        // 파동 함수 (간섭)
        final phase1 = r1 / wavelength * 2 * math.pi - time * 3;
        final phase2 = r2 / wavelength * 2 * math.pi - time * 3;

        final wave1 = math.sin(phase1);
        final wave2 = math.sin(phase2);
        final amplitude = (wave1 + wave2) / 2;

        // 색상 매핑
        final intensity = (amplitude + 1) / 2;
        final color = Color.lerp(
          AppColors.simBg,
          AppColors.accent,
          intensity,
        )!;

        canvas.drawCircle(
          Offset(x, y),
          1.5,
          Paint()..color = color.withValues(alpha: intensity * 0.8),
        );
      }
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        3,
        paint,
      );

      // 입자 글로우
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        6,
        Paint()..color = AppColors.accent.withValues(alpha: 0.3),
      );
    }
  }

  void _drawIntensityScreen(Canvas canvas, Size size, double screenX, double centerY) {
    // 검출 스크린
    final screenPaint = Paint()
      ..color = const Color(0xFF2D3748)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(screenX, 0, screenX + 15, size.height),
      screenPaint,
    );

    // 강도 패턴
    final patternHeight = size.height / intensityPattern.length;
    for (int i = 0; i < intensityPattern.length; i++) {
      final intensity = intensityPattern[i].clamp(0.0, 1.0);
      if (intensity > 0.01) {
        canvas.drawRect(
          Rect.fromLTRB(
            screenX,
            i * patternHeight,
            screenX + 15,
            (i + 1) * patternHeight,
          ),
          Paint()..color = AppColors.accent.withValues(alpha: intensity),
        );
      }
    }
  }

  void _drawInterferencePattern(Canvas canvas, Size size, double screenX, double centerY) {
    // 간섭 패턴 스크린
    final screenPaint = Paint()
      ..color = const Color(0xFF2D3748)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(screenX, 0, screenX + 15, size.height),
      screenPaint,
    );

    // 이론적 간섭 패턴
    for (double y = 0; y < size.height; y += 2) {
      final theta = math.atan2(y - centerY, screenX - size.width * 0.3);
      final pathDiff = slitDistance * math.sin(theta);
      final phase = pathDiff / wavelength * 2 * math.pi;
      final intensity = math.pow(math.cos(phase / 2), 2);

      canvas.drawRect(
        Rect.fromLTRB(screenX, y, screenX + 15, y + 2),
        Paint()..color = AppColors.accent.withValues(alpha: intensity * 0.9),
      );
    }
  }

  void _drawSource(Canvas canvas, Size size) {
    final sourceX = 30.0;
    final sourceY = size.height / 2;

    // 광원 글로우
    final gradient = RadialGradient(
      colors: [
        AppColors.accent,
        AppColors.accent.withValues(alpha: 0.3),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(sourceX, sourceY), radius: 20));

    canvas.drawCircle(
      Offset(sourceX, sourceY),
      20,
      Paint()..shader = gradient,
    );

    // 광원 중심
    canvas.drawCircle(
      Offset(sourceX, sourceY),
      8,
      Paint()..color = AppColors.accent,
    );
  }

  @override
  bool shouldRepaint(covariant DoubleSlitPainter oldDelegate) => true;
}
