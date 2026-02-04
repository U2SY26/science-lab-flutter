import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Mass-Energy Equivalence (E = mc²) Simulation
class MassEnergyScreen extends StatefulWidget {
  const MassEnergyScreen({super.key});

  @override
  State<MassEnergyScreen> createState() => _MassEnergyScreenState();
}

class _MassEnergyScreenState extends State<MassEnergyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _mass = 1.0; // kg
  double _velocity = 0.0; // v/c
  bool _showComparison = true;
  bool _isKorean = true;

  // Speed of light in m/s
  static const double _c = 299792458;
  static const double _cSquared = _c * _c;

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
    // Animation update if needed
  }

  double get _gamma => _velocity > 0 ? 1 / math.sqrt(1 - _velocity * _velocity) : 1;
  double get _restEnergy => _mass * _cSquared;
  double get _totalEnergy => _gamma * _mass * _cSquared;
  double get _kineticEnergy => (_gamma - 1) * _mass * _cSquared;

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _mass = 1.0;
      _velocity = 0.0;
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
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '질량-에너지 등가' : 'Mass-Energy Equivalence',
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
          category: _isKorean ? '상대성이론 시뮬레이션' : 'RELATIVITY SIMULATION',
          title: _isKorean ? '질량-에너지 등가' : 'Mass-Energy Equivalence',
          formula: 'E = mc²',
          formulaDescription: _isKorean
              ? '아인슈타인의 가장 유명한 공식입니다. 질량과 에너지는 등가이며, 작은 질량도 빛의 속도 제곱을 곱하면 엄청난 에너지가 됩니다. 핵반응의 기초입니다.'
              : "Einstein's most famous equation. Mass and energy are equivalent - even small mass contains enormous energy when multiplied by c². This is the basis of nuclear reactions.",
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: MassEnergyPainter(
                mass: _mass,
                velocity: _velocity,
                gamma: _gamma,
                restEnergy: _restEnergy,
                totalEnergy: _totalEnergy,
                kineticEnergy: _kineticEnergy,
                showComparison: _showComparison,
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
                  label: _isKorean ? '질량' : 'Mass',
                  value: _mass,
                  min: 0.001,
                  max: 10,
                  defaultValue: 1.0,
                  formatValue: (v) => v < 1 ? '${(v * 1000).toStringAsFixed(0)} g' : '${v.toStringAsFixed(2)} kg',
                  onChanged: (v) => setState(() => _mass = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: _isKorean ? '속도 (v/c)' : 'Velocity (v/c)',
                    value: _velocity,
                    min: 0,
                    max: 0.99,
                    defaultValue: 0,
                    formatValue: (v) => '${(v * 100).toStringAsFixed(0)}% c',
                    onChanged: (v) => setState(() => _velocity = v),
                  ),
                  SimToggle(
                    label: _isKorean ? '에너지 비교' : 'Energy Comparison',
                    value: _showComparison,
                    onChanged: (v) => setState(() => _showComparison = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _EnergyInfoCard(
                restEnergy: _restEnergy,
                totalEnergy: _totalEnergy,
                kineticEnergy: _kineticEnergy,
                mass: _mass,
                isKorean: _isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isKorean ? '1g 설정' : 'Set 1g',
                icon: Icons.science,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _mass = 0.001);
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

class _EnergyInfoCard extends StatelessWidget {
  final double restEnergy;
  final double totalEnergy;
  final double kineticEnergy;
  final double mass;
  final bool isKorean;

  const _EnergyInfoCard({
    required this.restEnergy,
    required this.totalEnergy,
    required this.kineticEnergy,
    required this.mass,
    required this.isKorean,
  });

  String _formatEnergy(double joules) {
    if (joules >= 1e18) {
      return '${(joules / 1e18).toStringAsFixed(2)} EJ';
    } else if (joules >= 1e15) {
      return '${(joules / 1e15).toStringAsFixed(2)} PJ';
    } else if (joules >= 1e12) {
      return '${(joules / 1e12).toStringAsFixed(2)} TJ';
    } else if (joules >= 1e9) {
      return '${(joules / 1e9).toStringAsFixed(2)} GJ';
    } else if (joules >= 1e6) {
      return '${(joules / 1e6).toStringAsFixed(2)} MJ';
    } else if (joules >= 1e3) {
      return '${(joules / 1e3).toStringAsFixed(2)} kJ';
    } else {
      return '${joules.toStringAsFixed(2)} J';
    }
  }

  @override
  Widget build(BuildContext context) {
    // TNT equivalent (1 ton TNT = 4.184e9 J)
    final tntEquivalent = restEnergy / 4.184e9;
    // Hiroshima bomb equivalent (15 kilotons = 6.3e13 J)
    final hiroshimaEquivalent = restEnergy / 6.3e13;

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
              Icon(Icons.flash_on, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                isKorean ? '정지 에너지 E₀' : 'Rest Energy E₀',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _formatEnergy(restEnergy),
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          if (kineticEnergy > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.bolt, size: 14, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  isKorean ? '운동 에너지' : 'Kinetic Energy',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  _formatEnergy(kineticEnergy),
                  style: const TextStyle(color: Colors.orange, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.functions, size: 14, color: Colors.cyan),
                const SizedBox(width: 8),
                Text(
                  isKorean ? '총 에너지' : 'Total Energy',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  _formatEnergy(totalEnergy),
                  style: const TextStyle(color: Colors.cyan, fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ],
          const Divider(height: 16),
          Text(
            isKorean
                ? 'TNT 환산: ${tntEquivalent >= 1000 ? '${(tntEquivalent / 1000).toStringAsFixed(1)} 킬로톤' : '${tntEquivalent.toStringAsFixed(0)} 톤'}'
                : 'TNT equivalent: ${tntEquivalent >= 1000 ? '${(tntEquivalent / 1000).toStringAsFixed(1)} kilotons' : '${tntEquivalent.toStringAsFixed(0)} tons'}',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          if (hiroshimaEquivalent >= 0.1)
            Text(
              isKorean
                  ? '히로시마 원폭의 약 ${hiroshimaEquivalent.toStringAsFixed(1)}배'
                  : '≈ ${hiroshimaEquivalent.toStringAsFixed(1)}x Hiroshima bomb',
              style: const TextStyle(color: Colors.redAccent, fontSize: 10),
            ),
        ],
      ),
    );
  }
}

class MassEnergyPainter extends CustomPainter {
  final double mass;
  final double velocity;
  final double gamma;
  final double restEnergy;
  final double totalEnergy;
  final double kineticEnergy;
  final bool showComparison;
  final bool isKorean;

  MassEnergyPainter({
    required this.mass,
    required this.velocity,
    required this.gamma,
    required this.restEnergy,
    required this.totalEnergy,
    required this.kineticEnergy,
    required this.showComparison,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0A0A1A),
    );

    // Draw the famous equation
    _drawEquation(canvas, size);

    // Draw mass representation
    _drawMassVisualization(canvas, centerX, centerY - 30, size);

    // Draw energy bars comparison
    if (showComparison) {
      _drawEnergyBars(canvas, size);
    }

    // Draw energy radiation effect
    _drawEnergyEffect(canvas, centerX, centerY - 30);
  }

  void _drawEquation(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // E = mc²
    textPainter.text = const TextSpan(
      text: 'E = mc²',
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        fontFamily: 'serif',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, 20));

    // Speed of light value
    textPainter.text = const TextSpan(
      text: 'c = 299,792,458 m/s',
      style: TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, 55));
  }

  void _drawMassVisualization(Canvas canvas, double cx, double cy, Size size) {
    // Mass sphere
    final massRadius = 30 + mass * 5;

    // Glow effect representing energy
    final glowRadius = massRadius + 20 + (gamma - 1) * 30;
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withValues(alpha: 0.5),
          AppColors.accent.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowRadius));
    canvas.drawCircle(Offset(cx, cy), glowRadius, glowPaint);

    // Mass body
    final massGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        Colors.white,
        const Color(0xFF4169E1),
        const Color(0xFF1E3A8A),
      ],
      stops: const [0.0, 0.3, 1.0],
    ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: massRadius));

    canvas.drawCircle(Offset(cx, cy), massRadius, Paint()..shader = massGradient);

    // Mass label
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: mass < 1 ? '${(mass * 1000).toStringAsFixed(0)}g' : '${mass.toStringAsFixed(1)}kg',
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height / 2));
  }

  void _drawEnergyEffect(Canvas canvas, double cx, double cy) {
    // Energy rays radiating from mass
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
      ..strokeWidth = 2;

    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final innerRadius = 50 + mass * 5;
      final outerRadius = innerRadius + 30 + gamma * 10;

      canvas.drawLine(
        Offset(cx + innerRadius * math.cos(angle), cy + innerRadius * math.sin(angle)),
        Offset(cx + outerRadius * math.cos(angle), cy + outerRadius * math.sin(angle)),
        rayPaint,
      );
    }
  }

  void _drawEnergyBars(Canvas canvas, Size size) {
    final barLeft = 30.0;
    final barWidth = size.width - 60;
    final barHeight = 20.0;
    final barTop = size.height - 100;

    // Background bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.1),
    );

    // Rest energy portion
    final restPortion = restEnergy / totalEnergy;
    final restWidth = barWidth * restPortion;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barLeft, barTop, restWidth, barHeight),
        const Radius.circular(5),
      ),
      Paint()..color = AppColors.accent,
    );

    // Kinetic energy portion
    if (kineticEnergy > 0) {
      final kineticWidth = barWidth * (1 - restPortion);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barLeft + restWidth, barTop, kineticWidth, barHeight),
          const Radius.circular(5),
        ),
        Paint()..color = Colors.orange,
      );
    }

    // Labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
      text: isKorean ? '정지 에너지 (mc²)' : 'Rest Energy (mc²)',
      style: TextStyle(color: AppColors.accent, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(barLeft, barTop + barHeight + 5));

    if (kineticEnergy > 0) {
      textPainter.text = TextSpan(
        text: isKorean ? '운동 에너지' : 'Kinetic',
        style: const TextStyle(color: Colors.orange, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(barLeft + restWidth + 5, barTop + barHeight + 5));
    }

    // Total energy bar label
    textPainter.text = TextSpan(
      text: 'E = γmc²',
      style: const TextStyle(color: Colors.white54, fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(barLeft + barWidth - textPainter.width, barTop - 15));
  }

  @override
  bool shouldRepaint(covariant MassEnergyPainter oldDelegate) {
    return mass != oldDelegate.mass ||
        velocity != oldDelegate.velocity ||
        showComparison != oldDelegate.showComparison;
  }
}
