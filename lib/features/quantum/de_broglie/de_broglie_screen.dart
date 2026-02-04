import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// de Broglie Waves Simulation
/// 드브로이 파동 시뮬레이션 (λ = h/p)
class DeBroglieScreen extends StatefulWidget {
  const DeBroglieScreen({super.key});

  @override
  State<DeBroglieScreen> createState() => _DeBroglieScreenState();
}

class _DeBroglieScreenState extends State<DeBroglieScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const double _defaultMass = 1.0; // relative mass (electron = 1)
  static const double _defaultVelocity = 50.0;
  static const int _defaultParticleType = 0;

  double mass = _defaultMass;
  double velocity = _defaultVelocity;
  int particleType = _defaultParticleType; // 0: electron, 1: proton, 2: neutron, 3: custom
  bool isRunning = true;

  double time = 0;
  bool isKorean = true;

  // Mass ratios relative to electron
  static const Map<int, double> massRatios = {
    0: 1.0, // electron
    1: 1836.0, // proton
    2: 1839.0, // neutron
    3: 1.0, // custom
  };

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
      time += 0.03;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      mass = _defaultMass;
      velocity = _defaultVelocity;
      particleType = _defaultParticleType;
    });
  }

  double get effectiveMass {
    if (particleType == 3) return mass;
    return massRatios[particleType] ?? 1.0;
  }

  double get deBroglieWavelength {
    // λ = h/p = h/(mv), scaled for visualization
    const h = 100.0; // Scaled Planck constant
    final p = effectiveMass * velocity;
    return p > 0 ? h / p : 100;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _particleName {
    switch (particleType) {
      case 0:
        return isKorean ? '전자' : 'Electron';
      case 1:
        return isKorean ? '양성자' : 'Proton';
      case 2:
        return isKorean ? '중성자' : 'Neutron';
      case 3:
        return isKorean ? '사용자 정의' : 'Custom';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final wavelength = deBroglieWavelength;
    final momentum = effectiveMass * velocity;

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
              isKorean ? '양자역학 시뮬레이션' : 'QUANTUM MECHANICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '드브로이 파동' : 'de Broglie Waves',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => isKorean = !isKorean),
            tooltip: isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '양자역학 시뮬레이션' : 'QUANTUM MECHANICS',
          title: isKorean ? '드브로이 파동' : 'de Broglie Waves',
          formula: 'λ = h/p = h/mv',
          formulaDescription: isKorean
              ? '모든 물질은 파동성을 가집니다. 드브로이 파장 λ는 플랑크 상수 h를 '
                  '운동량 p로 나눈 값입니다. 질량이 클수록, 속도가 빠를수록 파장이 짧아집니다.'
              : 'All matter exhibits wave-like properties. The de Broglie wavelength λ equals '
                  'Planck\'s constant h divided by momentum p. Higher mass or velocity means shorter wavelength.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: DeBrogliePainter(
                time: time,
                mass: effectiveMass,
                velocity: velocity,
                wavelength: wavelength,
                particleType: particleType,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSegment<int>(
                label: isKorean ? '입자 유형' : 'Particle Type',
                options: {
                  0: isKorean ? '전자' : 'e⁻',
                  1: isKorean ? '양성자' : 'p⁺',
                  2: isKorean ? '중성자' : 'n',
                  3: isKorean ? '사용자' : 'Custom',
                },
                selected: particleType,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    particleType = v;
                    if (v != 3) mass = massRatios[v] ?? 1.0;
                  });
                },
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '속도 (v)' : 'Velocity (v)',
                  value: velocity,
                  min: 10,
                  max: 100,
                  defaultValue: _defaultVelocity,
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) => setState(() => velocity = v),
                ),
                advancedControls: [
                  if (particleType == 3)
                    SimSlider(
                      label: isKorean ? '질량 (m)' : 'Mass (m)',
                      value: mass,
                      min: 0.1,
                      max: 100,
                      defaultValue: _defaultMass,
                      formatValue: (v) => v.toStringAsFixed(1),
                      onChanged: (v) => setState(() => mass = v),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                particleName: _particleName,
                mass: effectiveMass,
                velocity: velocity,
                momentum: momentum,
                wavelength: wavelength,
                isKorean: isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning
                    ? (isKorean ? '정지' : 'Pause')
                    : (isKorean ? '재생' : 'Play'),
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => isRunning = !isRunning);
                },
              ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
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

class _PhysicsInfo extends StatelessWidget {
  final String particleName;
  final double mass;
  final double velocity;
  final double momentum;
  final double wavelength;
  final bool isKorean;

  const _PhysicsInfo({
    required this.particleName,
    required this.mass,
    required this.velocity,
    required this.momentum,
    required this.wavelength,
    required this.isKorean,
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
                label: isKorean ? '입자' : 'Particle',
                value: particleName,
              ),
              _InfoItem(
                label: 'p = mv',
                value: momentum.toStringAsFixed(1),
              ),
              _InfoItem(
                label: 'λ',
                value: wavelength.toStringAsFixed(2),
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

class DeBrogliePainter extends CustomPainter {
  final double time;
  final double mass;
  final double velocity;
  final double wavelength;
  final int particleType;

  DeBrogliePainter({
    required this.time,
    required this.mass,
    required this.velocity,
    required this.wavelength,
    required this.particleType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawParticle(canvas, size);
    _drawWave(canvas, size);
    _drawWavelengthMarker(canvas, size);
    _drawLabels(canvas, size);
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

  void _drawParticle(Canvas canvas, Size size) {
    final particleX = 50 + (time * velocity * 0.5) % (size.width - 100);
    final particleY = size.height * 0.3;
    final particleRadius = 15.0 + math.min(mass, 10) * 2;

    // Particle color based on type
    final particleColor = _getParticleColor();

    // Motion trail
    for (int i = 0; i < 5; i++) {
      final trailX = particleX - i * 15;
      if (trailX > 30) {
        canvas.drawCircle(
          Offset(trailX, particleY),
          particleRadius * (1 - i * 0.15),
          Paint()..color = particleColor.withValues(alpha: 0.3 - i * 0.05),
        );
      }
    }

    // Outer glow
    final glowGradient = RadialGradient(
      colors: [
        particleColor.withValues(alpha: 0.6),
        particleColor.withValues(alpha: 0.2),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(
        center: Offset(particleX, particleY), radius: particleRadius * 2));

    canvas.drawCircle(
      Offset(particleX, particleY),
      particleRadius * 2,
      Paint()..shader = glowGradient,
    );

    // Main particle
    canvas.drawCircle(
      Offset(particleX, particleY),
      particleRadius,
      Paint()..color = particleColor,
    );

    // Velocity arrow
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(particleX + particleRadius + 5, particleY),
      Offset(particleX + particleRadius + 25, particleY),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(particleX + particleRadius + 25, particleY),
      Offset(particleX + particleRadius + 18, particleY - 5),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(particleX + particleRadius + 25, particleY),
      Offset(particleX + particleRadius + 18, particleY + 5),
      arrowPaint,
    );
  }

  Color _getParticleColor() {
    switch (particleType) {
      case 0:
        return const Color(0xFF63B3ED); // electron - blue
      case 1:
        return const Color(0xFFFC8181); // proton - red
      case 2:
        return const Color(0xFF68D391); // neutron - green
      default:
        return AppColors.accent;
    }
  }

  void _drawWave(Canvas canvas, Size size) {
    final waveY = size.height * 0.65;
    final amplitude = 40.0;
    final k = 2 * math.pi / wavelength.clamp(10, 200);
    final omega = velocity * k * 0.1;

    final wavePath = Path();
    bool started = false;

    for (double x = 30; x < size.width - 30; x += 2) {
      final phase = k * x - omega * time;
      final y = waveY - amplitude * math.sin(phase);

      if (!started) {
        wavePath.moveTo(x, y);
        started = true;
      } else {
        wavePath.lineTo(x, y);
      }
    }

    // Wave glow
    for (int i = 3; i >= 1; i--) {
      canvas.drawPath(
        wavePath,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.1 * i)
          ..strokeWidth = 2.0 + i * 2
          ..style = PaintingStyle.stroke,
      );
    }

    // Main wave
    canvas.drawPath(
      wavePath,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Wave probability density (|ψ|²)
    final probPath = Path();
    probPath.moveTo(30, waveY + amplitude + 10);

    for (double x = 30; x < size.width - 30; x += 2) {
      final phase = k * x - omega * time;
      final psi = math.sin(phase);
      final prob = psi * psi * amplitude * 0.5;
      probPath.lineTo(x, waveY + amplitude + 10 - prob);
    }

    probPath.lineTo(size.width - 30, waveY + amplitude + 10);
    probPath.close();

    canvas.drawPath(
      probPath,
      Paint()..color = const Color(0xFF805AD5).withValues(alpha: 0.3),
    );
  }

  void _drawWavelengthMarker(Canvas canvas, Size size) {
    final waveY = size.height * 0.65;
    final clampedWavelength = wavelength.clamp(10.0, 200.0);
    final startX = size.width / 2 - clampedWavelength / 2;
    final endX = size.width / 2 + clampedWavelength / 2;

    // Wavelength bracket
    final markerPaint = Paint()
      ..color = const Color(0xFF48BB78)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final bracketY = waveY - 60;
    canvas.drawLine(
      Offset(startX, bracketY),
      Offset(endX, bracketY),
      markerPaint,
    );
    canvas.drawLine(
      Offset(startX, bracketY - 5),
      Offset(startX, bracketY + 5),
      markerPaint,
    );
    canvas.drawLine(
      Offset(endX, bracketY - 5),
      Offset(endX, bracketY + 5),
      markerPaint,
    );

    // Lambda label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'λ = ${wavelength.toStringAsFixed(1)}',
        style: TextStyle(
          color: const Color(0xFF48BB78),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset((startX + endX) / 2 - textPainter.width / 2, bracketY - 20));
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Particle section label
    textPainter.text = TextSpan(
      text: 'Particle (matter)',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 11,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(30, size.height * 0.08));

    // Wave section label
    textPainter.text = TextSpan(
      text: 'de Broglie Wave (ψ)',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 11,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(30, size.height * 0.48));

    // Probability density label
    textPainter.text = TextSpan(
      text: '|ψ|²',
      style: TextStyle(
        color: const Color(0xFF805AD5),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - 50, size.height * 0.82));

    // Formula reminder
    textPainter.text = TextSpan(
      text: 'λ = h/p = h/mv',
      style: TextStyle(
        color: AppColors.accent.withValues(alpha: 0.7),
        fontSize: 12,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(
        canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.92));
  }

  @override
  bool shouldRepaint(covariant DeBrogliePainter oldDelegate) =>
      time != oldDelegate.time ||
      mass != oldDelegate.mass ||
      velocity != oldDelegate.velocity ||
      wavelength != oldDelegate.wavelength;
}
