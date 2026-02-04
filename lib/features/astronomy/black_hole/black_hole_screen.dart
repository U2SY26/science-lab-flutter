import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Black Hole Simulation
class BlackHoleScreen extends StatefulWidget {
  const BlackHoleScreen({super.key});

  @override
  State<BlackHoleScreen> createState() => _BlackHoleScreenState();
}

class _BlackHoleScreenState extends State<BlackHoleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _blackHoleMass = 10.0; // Solar masses
  double _accretionRate = 0.5;
  double _viewAngle = 0.0; // Viewing angle
  double _time = 0.0;
  bool _isAnimating = true;
  double _animationSpeed = 1.0;
  bool _showEventHorizon = true;
  bool _showPhotonSphere = true;
  bool _showAccretionDisk = true;
  bool _isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _updateAnimation() {
    if (!_isAnimating) return;
    setState(() {
      _time += 0.02 * _animationSpeed;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _blackHoleMass = 10.0;
      _accretionRate = 0.5;
      _viewAngle = 0.0;
      _time = 0;
      _isAnimating = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate Schwarzschild radius (in km for display)
    final schwarzschildRadius = 2.95 * _blackHoleMass; // Rs = 2GM/c^2

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKorean ? '천문학 시뮬레이션' : 'ASTRONOMY SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '블랙홀' : 'Black Hole',
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
            onPressed: () => setState(() => _isKorean = !_isKorean),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: _isKorean ? '천문학 시뮬레이션' : 'ASTRONOMY SIMULATION',
          title: _isKorean ? '블랙홀' : 'Black Hole',
          formula: 'Rs = 2GM/c²',
          formulaDescription: _isKorean
              ? '슈바르츠실트 반경: 블랙홀의 사건의 지평선 크기입니다. 이 경계 안에서는 빛조차 탈출할 수 없습니다. 광자구는 Rs의 1.5배 거리에 있습니다.'
              : 'Schwarzschild Radius: The event horizon size. Nothing, not even light, can escape from within. The photon sphere is at 1.5 Rs.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: BlackHolePainter(
                blackHoleMass: _blackHoleMass,
                accretionRate: _accretionRate,
                viewAngle: _viewAngle,
                time: _time,
                showEventHorizon: _showEventHorizon,
                showPhotonSphere: _showPhotonSphere,
                showAccretionDisk: _showAccretionDisk,
                isKorean: _isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: _isKorean ? '블랙홀 질량' : 'Black Hole Mass',
                  value: _blackHoleMass,
                  min: 3,
                  max: 50,
                  defaultValue: 10,
                  formatValue: (v) => '${v.toStringAsFixed(0)} M☉',
                  onChanged: (v) => setState(() => _blackHoleMass = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '강착률' : 'Accretion Rate',
                    value: _accretionRate,
                    min: 0.1,
                    max: 1.0,
                    defaultValue: 0.5,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _accretionRate = v),
                  ),
                  SimSlider(
                    label: _isKorean ? '시야각' : 'View Angle',
                    value: _viewAngle,
                    min: 0,
                    max: 80,
                    defaultValue: 0,
                    formatValue: (v) => '${v.toStringAsFixed(0)}°',
                    onChanged: (v) => setState(() => _viewAngle = v),
                  ),
                  SimSlider(
                    label: _isKorean ? '애니메이션 속도' : 'Animation Speed',
                    value: _animationSpeed,
                    min: 0.5,
                    max: 3.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() => _animationSpeed = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '사건의 지평선' : 'Event Horizon',
                    value: _showEventHorizon,
                    onChanged: (v) => setState(() => _showEventHorizon = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '광자구' : 'Photon Sphere',
                    value: _showPhotonSphere,
                    onChanged: (v) => setState(() => _showPhotonSphere = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '강착 원반' : 'Accretion Disk',
                    value: _showAccretionDisk,
                    onChanged: (v) => setState(() => _showAccretionDisk = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                schwarzschildRadius: schwarzschildRadius,
                isKorean: _isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isAnimating
                    ? (_isKorean ? '정지' : 'Pause')
                    : (_isKorean ? '재생' : 'Play'),
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isAnimating = !_isAnimating);
                },
              ),
              SimButton(
                label: _isKorean ? '리셋' : 'Reset',
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

class _InfoCard extends StatelessWidget {
  final double schwarzschildRadius;
  final bool isKorean;

  const _InfoCard({required this.schwarzschildRadius, required this.isKorean});

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
              const Icon(Icons.radio_button_unchecked, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                isKorean ? '슈바르츠실트 반경' : 'Schwarzschild Radius',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Rs = ${schwarzschildRadius.toStringAsFixed(1)} km',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.circle_outlined, size: 16, color: Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              Text(
                isKorean ? '광자구 반경' : 'Photon Sphere',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Rph = ${(schwarzschildRadius * 1.5).toStringAsFixed(1)} km',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BlackHolePainter extends CustomPainter {
  final double blackHoleMass;
  final double accretionRate;
  final double viewAngle;
  final double time;
  final bool showEventHorizon;
  final bool showPhotonSphere;
  final bool showAccretionDisk;
  final bool isKorean;

  BlackHolePainter({
    required this.blackHoleMass,
    required this.accretionRate,
    required this.viewAngle,
    required this.time,
    required this.showEventHorizon,
    required this.showPhotonSphere,
    required this.showAccretionDisk,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = math.min(size.width, size.height) / 400;
    final eventHorizonRadius = 30 * scale * math.sqrt(blackHoleMass / 10);

    // Background - deep space
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF020208),
    );

    // Distant stars (more affected near black hole)
    _drawDistortedStars(canvas, size, centerX, centerY, eventHorizonRadius);

    // Accretion disk (behind black hole portion)
    if (showAccretionDisk) {
      _drawAccretionDisk(canvas, centerX, centerY, eventHorizonRadius, true);
    }

    // Black hole shadow
    _drawBlackHole(canvas, centerX, centerY, eventHorizonRadius);

    // Photon sphere
    if (showPhotonSphere) {
      _drawPhotonSphere(canvas, centerX, centerY, eventHorizonRadius * 1.5);
    }

    // Event horizon indicator
    if (showEventHorizon) {
      _drawEventHorizon(canvas, centerX, centerY, eventHorizonRadius);
    }

    // Accretion disk (in front of black hole portion)
    if (showAccretionDisk) {
      _drawAccretionDisk(canvas, centerX, centerY, eventHorizonRadius, false);
    }

    // Relativistic jets
    _drawRelativisticJets(canvas, centerX, centerY, eventHorizonRadius);

    // Labels
    _drawLabels(canvas, size, centerX, centerY, eventHorizonRadius);
  }

  void _drawDistortedStars(Canvas canvas, Size size, double cx, double cy, double radius) {
    final random = math.Random(42);
    for (int i = 0; i < 150; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;

      // Calculate distance from center
      final dx = x - cx;
      final dy = y - cy;
      final dist = math.sqrt(dx * dx + dy * dy);

      // Stars closer to black hole are dimmer and more distorted
      if (dist < radius * 1.5) continue;

      final distFactor = math.min(1.0, (dist - radius * 1.5) / (size.width * 0.3));
      final alpha = random.nextDouble() * 0.5 * distFactor + 0.1;
      final starRadius = (random.nextDouble() * 1.2 + 0.3) * distFactor;

      canvas.drawCircle(
        Offset(x, y),
        starRadius,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }

  void _drawBlackHole(Canvas canvas, double cx, double cy, double radius) {
    // Black hole shadow (perfect black)
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()..color = Colors.black,
    );

    // Subtle edge glow from bent light
    final edgeGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0xFFFF6B35).withValues(alpha: 0.3),
          Colors.transparent,
        ],
        stops: const [0.8, 0.95, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius * 1.2));
    canvas.drawCircle(Offset(cx, cy), radius * 1.2, edgeGlow);
  }

  void _drawEventHorizon(Canvas canvas, double cx, double cy, double radius) {
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = Colors.red.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawPhotonSphere(Canvas canvas, double cx, double cy, double radius) {
    // Photon sphere glow
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = const Color(0xFFFF6B35).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Orbiting photons
    for (int i = 0; i < 8; i++) {
      final angle = time * 2 + i * math.pi / 4;
      final px = cx + radius * math.cos(angle);
      final py = cy + radius * math.sin(angle);
      canvas.drawCircle(
        Offset(px, py),
        2,
        Paint()..color = const Color(0xFFFFD700),
      );
    }
  }

  void _drawAccretionDisk(Canvas canvas, double cx, double cy, double radius, bool behind) {
    final diskInnerRadius = radius * 2;
    final diskOuterRadius = radius * 5;
    final tilt = math.cos(viewAngle * math.pi / 180);

    // Draw multiple rings
    for (double r = diskInnerRadius; r <= diskOuterRadius; r += 3) {
      final distFactor = (r - diskInnerRadius) / (diskOuterRadius - diskInnerRadius);
      final temp = 1.0 - distFactor * 0.7; // Hotter closer to black hole

      // Determine color based on temperature
      Color diskColor;
      if (temp > 0.8) {
        diskColor = Color.lerp(const Color(0xFFFFFFFF), const Color(0xFFFFD700), (1 - temp) * 5)!;
      } else if (temp > 0.5) {
        diskColor = Color.lerp(const Color(0xFFFFD700), const Color(0xFFFF6B35), (0.8 - temp) * 3.33)!;
      } else {
        diskColor = Color.lerp(const Color(0xFFFF6B35), const Color(0xFFFF4500), (0.5 - temp) * 2)!;
      }

      diskColor = diskColor.withValues(alpha: accretionRate * (1 - distFactor * 0.5));

      // Doppler effect: brighter approaching side, dimmer receding
      final rotationAngle = time * (1.5 - distFactor);

      // Draw disk segments
      final path = Path();
      for (double angle = behind ? math.pi : 0; angle < (behind ? 2 * math.pi : math.pi); angle += 0.05) {
        final x = cx + r * math.cos(angle + rotationAngle);
        final y = cy + r * math.sin(angle + rotationAngle) * tilt;

        if (angle == (behind ? math.pi : 0)) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = diskColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawRelativisticJets(Canvas canvas, double cx, double cy, double radius) {
    final jetLength = radius * 4;
    final jetWidth = radius * 0.5;

    // Top jet
    final topJetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF00BFFF).withValues(alpha: 0.8 * accretionRate),
          const Color(0xFF00BFFF).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(cx - jetWidth, cy - jetLength, jetWidth * 2, jetLength));

    final topJetPath = Path()
      ..moveTo(cx - jetWidth * 0.3, cy - radius * 0.5)
      ..lineTo(cx - jetWidth, cy - jetLength)
      ..lineTo(cx + jetWidth, cy - jetLength)
      ..lineTo(cx + jetWidth * 0.3, cy - radius * 0.5)
      ..close();
    canvas.drawPath(topJetPath, topJetPaint);

    // Bottom jet
    final bottomJetPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00BFFF).withValues(alpha: 0.8 * accretionRate),
          const Color(0xFF00BFFF).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(cx - jetWidth, cy, jetWidth * 2, jetLength));

    final bottomJetPath = Path()
      ..moveTo(cx - jetWidth * 0.3, cy + radius * 0.5)
      ..lineTo(cx - jetWidth, cy + jetLength)
      ..lineTo(cx + jetWidth, cy + jetLength)
      ..lineTo(cx + jetWidth * 0.3, cy + radius * 0.5)
      ..close();
    canvas.drawPath(bottomJetPath, bottomJetPaint);
  }

  void _drawLabels(Canvas canvas, Size size, double cx, double cy, double radius) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Event horizon label
    textPainter.text = TextSpan(
      text: isKorean ? '사건의 지평선' : 'Event Horizon',
      style: const TextStyle(color: Colors.red, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + radius + 10, cy - 5));

    // Photon sphere label
    textPainter.text = TextSpan(
      text: isKorean ? '광자구' : 'Photon Sphere',
      style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx + radius * 1.5 + 10, cy - 20));
  }

  @override
  bool shouldRepaint(covariant BlackHolePainter oldDelegate) {
    return blackHoleMass != oldDelegate.blackHoleMass ||
        accretionRate != oldDelegate.accretionRate ||
        viewAngle != oldDelegate.viewAngle ||
        time != oldDelegate.time ||
        showEventHorizon != oldDelegate.showEventHorizon ||
        showPhotonSphere != oldDelegate.showPhotonSphere ||
        showAccretionDisk != oldDelegate.showAccretionDisk;
  }
}
