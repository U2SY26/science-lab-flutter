import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Compton Scattering Simulation
/// 콤프턴 산란 시뮬레이션
class ComptonScreen extends StatefulWidget {
  const ComptonScreen({super.key});

  @override
  State<ComptonScreen> createState() => _ComptonScreenState();
}

class _ComptonScreenState extends State<ComptonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const double _defaultScatterAngle = 90.0;
  static const double _defaultPhotonEnergy = 500.0; // keV

  double scatterAngle = _defaultScatterAngle;
  double photonEnergy = _defaultPhotonEnergy;
  bool isRunning = true;

  double time = 0;
  bool isKorean = true;

  // Compton wavelength of electron in pm
  static const double comptonWavelength = 2.43; // pm
  static const double electronMassEnergy = 511.0; // keV (mc²)

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
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      scatterAngle = _defaultScatterAngle;
      photonEnergy = _defaultPhotonEnergy;
    });
  }

  void _scatter() {
    HapticFeedback.heavyImpact();
    setState(() {
      time = 0;
    });
  }

  double get wavelengthShift {
    // Δλ = λc(1 - cos θ)
    final thetaRad = scatterAngle * math.pi / 180;
    return comptonWavelength * (1 - math.cos(thetaRad));
  }

  double get scatteredPhotonEnergy {
    // E' = E / (1 + (E/mc²)(1 - cos θ))
    final thetaRad = scatterAngle * math.pi / 180;
    return photonEnergy / (1 + (photonEnergy / electronMassEnergy) * (1 - math.cos(thetaRad)));
  }

  double get electronKineticEnergy {
    return photonEnergy - scatteredPhotonEnergy;
  }

  double get electronAngle {
    // cot φ = (1 + E/mc²) tan(θ/2)
    final thetaRad = scatterAngle * math.pi / 180;
    final cotPhi = (1 + photonEnergy / electronMassEnergy) * math.tan(thetaRad / 2);
    return math.atan(1 / cotPhi) * 180 / math.pi;
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
              isKorean ? '양자역학 시뮬레이션' : 'QUANTUM MECHANICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '콤프턴 산란' : 'Compton Scattering',
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
          title: isKorean ? '콤프턴 산란' : 'Compton Scattering',
          formula: 'Δλ = λc(1 - cos θ)',
          formulaDescription: isKorean
              ? '광자가 전자와 충돌할 때 파장이 증가합니다. 이는 빛의 입자성을 보여주는 '
                  '대표적인 현상입니다. λc는 콤프턴 파장(2.43pm)입니다.'
              : 'When a photon collides with an electron, its wavelength increases. '
                  'This demonstrates the particle nature of light. λc is the Compton wavelength (2.43pm).',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: ComptonPainter(
                time: time,
                scatterAngle: scatterAngle,
                photonEnergy: photonEnergy,
                scatteredEnergy: scatteredPhotonEnergy,
                electronAngle: electronAngle,
                electronEnergy: electronKineticEnergy,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '산란 각도 θ (도)' : 'Scatter Angle θ (deg)',
                  value: scatterAngle,
                  min: 0,
                  max: 180,
                  defaultValue: _defaultScatterAngle,
                  formatValue: (v) => '${v.toInt()}°',
                  onChanged: (v) => setState(() => scatterAngle = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '광자 에너지 (keV)' : 'Photon Energy (keV)',
                    value: photonEnergy,
                    min: 100,
                    max: 1000,
                    defaultValue: _defaultPhotonEnergy,
                    formatValue: (v) => '${v.toInt()} keV',
                    onChanged: (v) => setState(() => photonEnergy = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                wavelengthShift: wavelengthShift,
                scatteredEnergy: scatteredPhotonEnergy,
                electronEnergy: electronKineticEnergy,
                electronAngle: electronAngle,
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
                label: isKorean ? '산란' : 'Scatter',
                icon: Icons.scatter_plot,
                onPressed: _scatter,
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
  final double wavelengthShift;
  final double scatteredEnergy;
  final double electronEnergy;
  final double electronAngle;
  final bool isKorean;

  const _PhysicsInfo({
    required this.wavelengthShift,
    required this.scatteredEnergy,
    required this.electronEnergy,
    required this.electronAngle,
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
                label: 'Δλ',
                value: '${wavelengthShift.toStringAsFixed(2)} pm',
              ),
              _InfoItem(
                label: isKorean ? '산란 광자' : 'Scattered γ',
                value: '${scatteredEnergy.toInt()} keV',
              ),
              _InfoItem(
                label: isKorean ? '전자 에너지' : 'e⁻ Energy',
                value: '${electronEnergy.toInt()} keV',
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

class ComptonPainter extends CustomPainter {
  final double time;
  final double scatterAngle;
  final double photonEnergy;
  final double scatteredEnergy;
  final double electronAngle;
  final double electronEnergy;

  ComptonPainter({
    required this.time,
    required this.scatterAngle,
    required this.photonEnergy,
    required this.scatteredEnergy,
    required this.electronAngle,
    required this.electronEnergy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawElectron(canvas, size);
    _drawIncomingPhoton(canvas, size);
    _drawScatteredPhoton(canvas, size);
    _drawRecoilElectron(canvas, size);
    _drawAngleIndicators(canvas, size);
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

  void _drawElectron(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final centerY = size.height * 0.45;
    final radius = 25.0;

    // Electron glow
    final glowGradient = RadialGradient(
      colors: [
        const Color(0xFF63B3ED).withValues(alpha: 0.6),
        const Color(0xFF63B3ED).withValues(alpha: 0.2),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 2));

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius * 2,
      Paint()..shader = glowGradient,
    );

    // Main electron
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()..color = const Color(0xFF63B3ED),
    );

    // e⁻ label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'e⁻',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX - 8, centerY - 8));
  }

  void _drawIncomingPhoton(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final centerY = size.height * 0.45;

    // Photon position based on time
    final photonProgress = (time * 2) % 3;
    final photonX = 30 + photonProgress * (centerX - 60);

    if (photonProgress < 1) {
      // Draw incoming photon
      _drawPhoton(canvas, photonX, centerY, photonEnergy, const Color(0xFFFFD700));

      // Draw incoming wave
      final wavePaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final wavePath = Path();
      wavePath.moveTo(30, centerY);
      for (double x = 30; x < photonX; x += 3) {
        final y = centerY + 10 * math.sin((x - time * 100) * 0.15);
        wavePath.lineTo(x, y);
      }
      canvas.drawPath(wavePath, wavePaint);
    }
  }

  void _drawScatteredPhoton(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final centerY = size.height * 0.45;
    final thetaRad = scatterAngle * math.pi / 180;

    final photonProgress = (time * 2) % 3;

    if (photonProgress >= 1 && photonProgress < 2) {
      final scatterProgress = photonProgress - 1;
      final distance = scatterProgress * 150;

      final photonX = centerX + distance * math.cos(-thetaRad);
      final photonY = centerY + distance * math.sin(-thetaRad);

      // Draw scattered photon (redshifted - longer wavelength)
      _drawPhoton(canvas, photonX, photonY, scatteredEnergy, const Color(0xFFFF6B6B));

      // Draw scattered wave
      final wavePaint = Paint()
        ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final wavePath = Path();
      wavePath.moveTo(centerX, centerY);
      for (double d = 0; d < distance; d += 3) {
        final x = centerX + d * math.cos(-thetaRad);
        final baseY = centerY + d * math.sin(-thetaRad);
        // Longer wavelength for scattered photon
        final waveOffset = 12 * math.sin((d - time * 80) * 0.12);
        final perpX = -math.sin(-thetaRad) * waveOffset;
        final perpY = math.cos(-thetaRad) * waveOffset;
        wavePath.lineTo(x + perpX, baseY + perpY);
      }
      canvas.drawPath(wavePath, wavePaint);
    }
  }

  void _drawRecoilElectron(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final centerY = size.height * 0.45;
    final phiRad = electronAngle * math.pi / 180;

    final photonProgress = (time * 2) % 3;

    if (photonProgress >= 1 && photonProgress < 2) {
      final recoilProgress = photonProgress - 1;
      // Recoil distance proportional to energy transfer
      final distance = recoilProgress * 100 * (electronEnergy / photonEnergy);

      final electronX = centerX + distance * math.cos(phiRad);
      final electronY = centerY + distance * math.sin(phiRad);

      // Recoil electron
      final electronGradient = RadialGradient(
        colors: [
          const Color(0xFF63B3ED).withValues(alpha: 0.8),
          const Color(0xFF63B3ED).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(
          Rect.fromCircle(center: Offset(electronX, electronY), radius: 30));

      canvas.drawCircle(
        Offset(electronX, electronY),
        30,
        Paint()..shader = electronGradient,
      );

      canvas.drawCircle(
        Offset(electronX, electronY),
        15,
        Paint()..color = const Color(0xFF63B3ED),
      );

      // Trail
      for (int i = 1; i <= 5; i++) {
        final trailDist = distance - i * 10;
        if (trailDist > 0) {
          final trailX = centerX + trailDist * math.cos(phiRad);
          final trailY = centerY + trailDist * math.sin(phiRad);
          canvas.drawCircle(
            Offset(trailX, trailY),
            8 - i.toDouble(),
            Paint()..color = const Color(0xFF63B3ED).withValues(alpha: 0.3 - i * 0.05),
          );
        }
      }
    }
  }

  void _drawPhoton(Canvas canvas, double x, double y, double energy, Color color) {
    final radius = 8.0 + energy / 100;

    // Photon glow
    final glowGradient = RadialGradient(
      colors: [
        color,
        color.withValues(alpha: 0.3),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius * 2));

    canvas.drawCircle(
      Offset(x, y),
      radius * 2,
      Paint()..shader = glowGradient,
    );

    // Photon core
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()..color = color,
    );
  }

  void _drawAngleIndicators(Canvas canvas, Size size) {
    final centerX = size.width * 0.4;
    final centerY = size.height * 0.45;
    final thetaRad = scatterAngle * math.pi / 180;
    final phiRad = electronAngle * math.pi / 180;

    // Scatter angle arc
    final anglePaint = Paint()
      ..color = const Color(0xFFFF6B6B).withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: 50),
      0,
      -thetaRad,
      false,
      anglePaint,
    );

    // Electron angle arc
    final electronAnglePaint = Paint()
      ..color = const Color(0xFF63B3ED).withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: 40),
      0,
      phiRad,
      false,
      electronAnglePaint,
    );

    // Angle labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: 'θ=${scatterAngle.toInt()}°',
      style: TextStyle(
        color: const Color(0xFFFF6B6B),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + 55, centerY - 30));

    textPainter.text = TextSpan(
      text: 'φ=${electronAngle.toInt()}°',
      style: TextStyle(
        color: const Color(0xFF63B3ED),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + 45, centerY + 15));
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Incoming photon label
    textPainter.text = TextSpan(
      text: 'γ (${photonEnergy.toInt()} keV)',
      style: TextStyle(
        color: const Color(0xFFFFD700),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(40, size.height * 0.3));

    // Scattered photon label
    textPainter.text = TextSpan(
      text: "γ' (${scatteredEnergy.toInt()} keV)",
      style: TextStyle(
        color: const Color(0xFFFF6B6B),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.65, size.height * 0.15));

    // Energy conservation
    textPainter.text = TextSpan(
      text: 'E_γ = E\'_γ + K_e',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.85));

    // Momentum conservation note
    textPainter.text = TextSpan(
      text: 'Momentum & Energy Conserved',
      style: TextStyle(
        color: AppColors.muted.withValues(alpha: 0.7),
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.92));
  }

  @override
  bool shouldRepaint(covariant ComptonPainter oldDelegate) =>
      time != oldDelegate.time ||
      scatterAngle != oldDelegate.scatterAngle ||
      photonEnergy != oldDelegate.photonEnergy;
}
