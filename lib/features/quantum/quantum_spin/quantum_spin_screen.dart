import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Quantum Spin Simulation
/// 양자 스핀 시뮬레이션
class QuantumSpinScreen extends StatefulWidget {
  const QuantumSpinScreen({super.key});

  @override
  State<QuantumSpinScreen> createState() => _QuantumSpinScreenState();
}

class _QuantumSpinScreenState extends State<QuantumSpinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const double _defaultTheta = 45.0; // polar angle
  static const double _defaultPhi = 0.0; // azimuthal angle
  static const double _defaultMagneticField = 50.0;

  double theta = _defaultTheta;
  double phi = _defaultPhi;
  double magneticField = _defaultMagneticField;
  bool isRunning = true;
  int spinType = 0; // 0: spin-1/2, 1: spin-1, 2: spin-3/2

  double time = 0;
  bool isKorean = true;
  bool isSpinUp = true; // Current spin state

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
      // Larmor precession: phi increases with time proportional to magnetic field
      phi = (phi + magneticField * 0.02) % 360;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      theta = _defaultTheta;
      phi = _defaultPhi;
      magneticField = _defaultMagneticField;
    });
  }

  void _measure() {
    HapticFeedback.heavyImpact();
    setState(() {
      // Probability of measuring spin up along z-axis
      final thetaRad = theta * math.pi / 180;
      final probUp = math.pow(math.cos(thetaRad / 2), 2);
      isSpinUp = math.Random().nextDouble() < probUp;

      // Collapse to measured state
      theta = isSpinUp ? 0 : 180;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _spinLabel {
    switch (spinType) {
      case 0:
        return 's = 1/2';
      case 1:
        return 's = 1';
      case 2:
        return 's = 3/2';
      default:
        return 's = 1/2';
    }
  }

  @override
  Widget build(BuildContext context) {
    final thetaRad = theta * math.pi / 180;
    final probUp = math.pow(math.cos(thetaRad / 2), 2).toDouble();
    final probDown = math.pow(math.sin(thetaRad / 2), 2).toDouble();

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
              isKorean ? '양자 스핀' : 'Quantum Spin',
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
          title: isKorean ? '양자 스핀' : 'Quantum Spin',
          formula: '|ψ⟩ = cos(θ/2)|↑⟩ + e^(iφ)sin(θ/2)|↓⟩',
          formulaDescription: isKorean
              ? '양자 스핀은 입자의 고유 각운동량입니다. 스핀-1/2 입자는 |↑⟩(업)과 |↓⟩(다운) '
                  '두 상태의 중첩으로 표현되며, 측정 시 둘 중 하나로 붕괴합니다.'
              : 'Quantum spin is the intrinsic angular momentum of particles. Spin-1/2 particles '
                  'can be in a superposition of |↑⟩(up) and |↓⟩(down) states, collapsing to one upon measurement.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: QuantumSpinPainter(
                time: time,
                theta: theta,
                phi: phi,
                magneticField: magneticField,
                spinType: spinType,
                isSpinUp: isSpinUp,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSegment<int>(
                label: isKorean ? '스핀 유형' : 'Spin Type',
                options: {
                  0: 's=1/2',
                  1: 's=1',
                  2: 's=3/2',
                },
                selected: spinType,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => spinType = v);
                },
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '극각 θ (도)' : 'Polar Angle θ (deg)',
                  value: theta,
                  min: 0,
                  max: 180,
                  defaultValue: _defaultTheta,
                  formatValue: (v) => '${v.toInt()}°',
                  onChanged: (v) => setState(() => theta = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '자기장 세기' : 'Magnetic Field',
                    value: magneticField,
                    min: 10,
                    max: 100,
                    defaultValue: _defaultMagneticField,
                    formatValue: (v) => '${v.toInt()} B',
                    onChanged: (v) => setState(() => magneticField = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                spinLabel: _spinLabel,
                probUp: probUp,
                probDown: probDown,
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
                label: isKorean ? '측정' : 'Measure',
                icon: Icons.radio_button_checked,
                onPressed: _measure,
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
  final String spinLabel;
  final double probUp;
  final double probDown;
  final bool isKorean;

  const _PhysicsInfo({
    required this.spinLabel,
    required this.probUp,
    required this.probDown,
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
      child: Row(
        children: [
          _InfoItem(
            label: isKorean ? '스핀' : 'Spin',
            value: spinLabel,
          ),
          _InfoItem(
            label: 'P(↑)',
            value: '${(probUp * 100).toInt()}%',
          ),
          _InfoItem(
            label: 'P(↓)',
            value: '${(probDown * 100).toInt()}%',
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

class QuantumSpinPainter extends CustomPainter {
  final double time;
  final double theta;
  final double phi;
  final double magneticField;
  final int spinType;
  final bool isSpinUp;

  QuantumSpinPainter({
    required this.time,
    required this.theta,
    required this.phi,
    required this.magneticField,
    required this.spinType,
    required this.isSpinUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawBlochSphere(canvas, size);
    _drawSpinVector(canvas, size);
    _drawProbabilityBars(canvas, size);
    _drawMagneticField(canvas, size);
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

  void _drawBlochSphere(Canvas canvas, Size size) {
    final centerX = size.width * 0.35;
    final centerY = size.height * 0.45;
    final radius = 100.0;

    // Draw sphere outline
    final spherePaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: radius * 2,
        height: radius * 2,
      ),
      spherePaint,
    );

    // Draw equator (ellipse for 3D effect)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: radius * 2,
        height: radius * 0.6,
      ),
      spherePaint,
    );

    // Draw meridian
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: radius * 0.6,
        height: radius * 2,
      ),
      spherePaint,
    );

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // Z axis (vertical)
    canvas.drawLine(
      Offset(centerX, centerY - radius - 20),
      Offset(centerX, centerY + radius + 20),
      axisPaint,
    );

    // X axis
    canvas.drawLine(
      Offset(centerX - radius - 20, centerY),
      Offset(centerX + radius + 20, centerY),
      axisPaint,
    );

    // Draw |↑⟩ and |↓⟩ labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: '|↑⟩',
      style: TextStyle(
        color: const Color(0xFF48BB78),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + 5, centerY - radius - 35));

    textPainter.text = TextSpan(
      text: '|↓⟩',
      style: TextStyle(
        color: const Color(0xFFFC8181),
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + 5, centerY + radius + 15));
  }

  void _drawSpinVector(Canvas canvas, Size size) {
    final centerX = size.width * 0.35;
    final centerY = size.height * 0.45;
    final radius = 100.0;

    final thetaRad = theta * math.pi / 180;
    final phiRad = phi * math.pi / 180;

    // Calculate 3D position on Bloch sphere
    final x = radius * math.sin(thetaRad) * math.cos(phiRad);
    // y component used for depth perception (not directly displayed in 2D projection)
    final z = -radius * math.cos(thetaRad);

    // Project to 2D (simple orthographic projection)
    final screenX = centerX + x;
    final screenY = centerY + z; // z is vertical

    // Draw spin vector
    final vectorPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(screenX, screenY),
      vectorPaint,
    );

    // Draw arrowhead
    final arrowSize = 12.0;
    final angle = math.atan2(screenY - centerY, screenX - centerX);

    final arrowPath = Path()
      ..moveTo(screenX, screenY)
      ..lineTo(
        screenX - arrowSize * math.cos(angle - 0.4),
        screenY - arrowSize * math.sin(angle - 0.4),
      )
      ..moveTo(screenX, screenY)
      ..lineTo(
        screenX - arrowSize * math.cos(angle + 0.4),
        screenY - arrowSize * math.sin(angle + 0.4),
      );

    canvas.drawPath(arrowPath, vectorPaint);

    // Draw point at tip
    canvas.drawCircle(
      Offset(screenX, screenY),
      6,
      Paint()..color = AppColors.accent,
    );

    // Draw glow effect
    canvas.drawCircle(
      Offset(screenX, screenY),
      12,
      Paint()..color = AppColors.accent.withValues(alpha: 0.3),
    );

    // Draw precession trace (dotted circle at current theta)
    if (theta > 5 && theta < 175) {
      final tracePaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      final traceRadius = radius * math.sin(thetaRad);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, centerY + z),
          width: traceRadius * 2,
          height: traceRadius * 0.6, // Perspective
        ),
        tracePaint,
      );
    }
  }

  void _drawProbabilityBars(Canvas canvas, Size size) {
    final thetaRad = theta * math.pi / 180;
    final probUp = math.pow(math.cos(thetaRad / 2), 2);
    final probDown = math.pow(math.sin(thetaRad / 2), 2);

    final barX = size.width * 0.75;
    final barWidth = 40.0;
    final maxHeight = 150.0;
    final barY = size.height * 0.15;

    // Up probability bar
    final upHeight = probUp * maxHeight;
    final upPaint = Paint()
      ..color = const Color(0xFF48BB78).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX - barWidth / 2, barY + maxHeight - upHeight, barWidth, upHeight),
        const Radius.circular(4),
      ),
      upPaint,
    );

    // Down probability bar
    final downHeight = probDown * maxHeight;
    final downPaint = Paint()
      ..color = const Color(0xFFFC8181).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX + barWidth / 2 + 10, barY + maxHeight - downHeight, barWidth, downHeight),
        const Radius.circular(4),
      ),
      downPaint,
    );

    // Labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: '|↑⟩',
      style: TextStyle(color: const Color(0xFF48BB78), fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(barX - barWidth / 2 + 10, barY + maxHeight + 5));

    textPainter.text = TextSpan(
      text: '|↓⟩',
      style: TextStyle(color: const Color(0xFFFC8181), fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(barX + barWidth / 2 + 20, barY + maxHeight + 5));

    // Percentage labels
    textPainter.text = TextSpan(
      text: '${(probUp * 100).toInt()}%',
      style: TextStyle(color: AppColors.ink, fontSize: 10, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(barX - barWidth / 2 + 5, barY + maxHeight - upHeight - 15));

    textPainter.text = TextSpan(
      text: '${(probDown * 100).toInt()}%',
      style: TextStyle(color: AppColors.ink, fontSize: 10, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(barX + barWidth / 2 + 15, barY + maxHeight - downHeight - 15));
  }

  void _drawMagneticField(Canvas canvas, Size size) {
    final centerX = size.width * 0.35;
    final startY = size.height * 0.1;
    final endY = size.height * 0.8;

    // Draw magnetic field lines
    final fieldPaint = Paint()
      ..color = const Color(0xFF805AD5).withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (double offset = -30; offset <= 30; offset += 15) {
      final path = Path();
      path.moveTo(centerX + offset, startY);

      for (double y = startY; y <= endY; y += 5) {
        final wave = math.sin((y - startY) * 0.05 + time) * 3;
        path.lineTo(centerX + offset + wave, y);
      }

      canvas.drawPath(path, fieldPaint);
    }

    // B field label
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: 'B',
      style: TextStyle(
        color: const Color(0xFF805AD5),
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + 50, startY));
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Title
    textPainter.text = TextSpan(
      text: 'Bloch Sphere',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.35 - 35, size.height * 0.9));

    // Probability title
    textPainter.text = TextSpan(
      text: 'Measurement Probability',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 11,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.65, size.height * 0.08));

    // Angle info
    textPainter.text = TextSpan(
      text: 'θ=${theta.toInt()}° φ=${phi.toInt()}°',
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.2, size.height * 0.92));
  }

  @override
  bool shouldRepaint(covariant QuantumSpinPainter oldDelegate) =>
      time != oldDelegate.time ||
      theta != oldDelegate.theta ||
      phi != oldDelegate.phi ||
      spinType != oldDelegate.spinType;
}
