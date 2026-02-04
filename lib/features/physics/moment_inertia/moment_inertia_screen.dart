import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Moment of Inertia simulation: I = Σmr²
class MomentInertiaScreen extends StatefulWidget {
  const MomentInertiaScreen({super.key});

  @override
  State<MomentInertiaScreen> createState() => _MomentInertiaScreenState();
}

class _MomentInertiaScreenState extends State<MomentInertiaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  int shapeType = 0; // 0: point mass, 1: rod, 2: disk, 3: ring
  double mass = 2.0; // kg
  double radius = 0.3; // m
  double rotation = 0.0;
  double angularVelocity = 0.0;
  double appliedTorque = 10.0; // N·m

  bool isRunning = false;
  bool isKorean = true;

  final List<String> shapeNames = ['Point Mass', 'Rod', 'Disk', 'Ring'];
  final List<String> shapeNamesKr = ['점질량', '막대', '원판', '고리'];

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
      final dt = 0.016;
      final I = momentOfInertia;
      final angularAcceleration = appliedTorque / I;

      angularVelocity += angularAcceleration * dt;
      angularVelocity *= 0.998; // small damping
      rotation += angularVelocity * dt;
    });
  }

  double get momentOfInertia {
    switch (shapeType) {
      case 0: // Point mass: I = mr²
        return mass * radius * radius;
      case 1: // Rod (about center): I = (1/12)mL²
        return (1 / 12) * mass * (2 * radius) * (2 * radius);
      case 2: // Disk: I = (1/2)mr²
        return 0.5 * mass * radius * radius;
      case 3: // Ring: I = mr²
        return mass * radius * radius;
      default:
        return mass * radius * radius;
    }
  }

  String get inertiaFormula {
    switch (shapeType) {
      case 0:
        return 'I = mr²';
      case 1:
        return 'I = (1/12)mL²';
      case 2:
        return 'I = (1/2)mr²';
      case 3:
        return 'I = mr²';
      default:
        return 'I = mr²';
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      rotation = 0;
      angularVelocity = 0;
      isRunning = false;
    });
  }

  void _toggleSimulation() {
    HapticFeedback.selectionClick();
    setState(() => isRunning = !isRunning);
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
              isKorean ? '회전 역학' : 'ROTATIONAL MECHANICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '관성 모멘트' : 'Moment of Inertia',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Text(
              isKorean ? 'EN' : '한',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => setState(() => isKorean = !isKorean),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '회전 역학' : 'Rotational Mechanics',
          title: isKorean ? '관성 모멘트' : 'Moment of Inertia',
          formula: inertiaFormula,
          formulaDescription: isKorean
              ? '관성 모멘트(I)는 회전에 대한 물체의 저항을 나타내며, 질량 분포에 따라 달라집니다.'
              : 'Moment of inertia (I) measures resistance to rotational motion, depending on mass distribution.',
          simulation: CustomPaint(
            painter: MomentInertiaPainter(
              shapeType: shapeType,
              mass: mass,
              radius: radius,
              rotation: rotation,
              momentOfInertia: momentOfInertia,
              angularVelocity: angularVelocity,
              isKorean: isKorean,
            ),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shape selection
              PresetGroup(
                label: isKorean ? '물체 모양' : 'Shape',
                presets: List.generate(4, (i) => PresetButton(
                  label: isKorean ? shapeNamesKr[i] : shapeNames[i],
                  isSelected: shapeType == i,
                  onPressed: () => setState(() {
                    shapeType = i;
                    _reset();
                  }),
                )),
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '토크 (τ)' : 'Torque (τ)',
                  value: appliedTorque,
                  min: 1,
                  max: 50,
                  defaultValue: 10,
                  formatValue: (v) => '${v.toStringAsFixed(0)} N·m',
                  onChanged: (v) => setState(() => appliedTorque = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '질량 (m)' : 'Mass (m)',
                    value: mass,
                    min: 0.5,
                    max: 10,
                    defaultValue: 2,
                    formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                    onChanged: (v) => setState(() => mass = v),
                  ),
                  SimSlider(
                    label: isKorean ? '반지름/길이 (r)' : 'Radius/Length (r)',
                    value: radius,
                    min: 0.1,
                    max: 1.0,
                    step: 0.05,
                    defaultValue: 0.3,
                    formatValue: (v) => '${v.toStringAsFixed(2)} m',
                    onChanged: (v) => setState(() => radius = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InertiaDisplay(
                momentOfInertia: momentOfInertia,
                angularVelocity: angularVelocity,
                angularAcceleration: appliedTorque / momentOfInertia,
                rotation: rotation,
                formula: inertiaFormula,
                isKorean: isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning
                    ? (isKorean ? '정지' : 'Stop')
                    : (isKorean ? '회전' : 'Rotate'),
                icon: isRunning ? Icons.pause : Icons.rotate_right,
                isPrimary: true,
                onPressed: _toggleSimulation,
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

class _InertiaDisplay extends StatelessWidget {
  final double momentOfInertia;
  final double angularVelocity;
  final double angularAcceleration;
  final double rotation;
  final String formula;
  final bool isKorean;

  const _InertiaDisplay({
    required this.momentOfInertia,
    required this.angularVelocity,
    required this.angularAcceleration,
    required this.rotation,
    required this.formula,
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
                label: isKorean ? '관성 모멘트 (I)' : 'Moment of Inertia',
                value: '${momentOfInertia.toStringAsFixed(3)} kg·m²',
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: isKorean ? '각속도 (ω)' : 'Angular Velocity',
                value: '${angularVelocity.toStringAsFixed(2)} rad/s',
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: isKorean ? '각가속도 (α)' : 'Angular Accel.',
                value: '${angularAcceleration.toStringAsFixed(2)} rad/s²',
                color: AppColors.ink,
              ),
              _InfoItem(
                label: isKorean ? '회전 에너지' : 'Rotational KE',
                value: '${(0.5 * momentOfInertia * angularVelocity * angularVelocity).toStringAsFixed(2)} J',
                color: AppColors.muted,
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
  final Color color;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.color,
  });

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
              color: color,
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

class MomentInertiaPainter extends CustomPainter {
  final int shapeType;
  final double mass;
  final double radius;
  final double rotation;
  final double momentOfInertia;
  final double angularVelocity;
  final bool isKorean;

  MomentInertiaPainter({
    required this.shapeType,
    required this.mass,
    required this.radius,
    required this.rotation,
    required this.momentOfInertia,
    required this.angularVelocity,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final displayRadius = radius * 150;

    canvas.save();
    canvas.translate(centerX, centerY);
    canvas.rotate(rotation);

    // Draw shape based on type
    switch (shapeType) {
      case 0: // Point mass
        _drawPointMass(canvas, displayRadius);
        break;
      case 1: // Rod
        _drawRod(canvas, displayRadius);
        break;
      case 2: // Disk
        _drawDisk(canvas, displayRadius);
        break;
      case 3: // Ring
        _drawRing(canvas, displayRadius);
        break;
    }

    canvas.restore();

    // Draw rotation axis indicator
    canvas.drawCircle(
      Offset(centerX, centerY),
      5,
      Paint()..color = AppColors.accent,
    );

    // Draw angular velocity arc
    if (angularVelocity.abs() > 0.1) {
      final arcRadius = displayRadius + 20;
      final sweepAngle = (angularVelocity / 5).clamp(-math.pi, math.pi);

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: arcRadius),
        -math.pi / 4,
        sweepAngle,
        false,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // Formula and values
    _drawText(canvas, _getFormulaText(), Offset(20, 20), AppColors.ink, 14);
    _drawText(canvas, 'I = ${momentOfInertia.toStringAsFixed(3)} kg·m²', Offset(20, 45), AppColors.accent2, 12);

    // Shape comparison (small diagrams)
    _drawShapeComparison(canvas, size);
  }

  String _getFormulaText() {
    switch (shapeType) {
      case 0:
        return isKorean ? '점질량: I = mr²' : 'Point Mass: I = mr²';
      case 1:
        return isKorean ? '막대 (중심): I = (1/12)mL²' : 'Rod (center): I = (1/12)mL²';
      case 2:
        return isKorean ? '원판: I = (1/2)mr²' : 'Disk: I = (1/2)mr²';
      case 3:
        return isKorean ? '고리: I = mr²' : 'Ring: I = mr²';
      default:
        return '';
    }
  }

  void _drawPointMass(Canvas canvas, double r) {
    // Rod to the point mass
    canvas.drawLine(
      Offset.zero,
      Offset(r, 0),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2,
    );

    // Point mass
    canvas.drawCircle(
      Offset(r, 0),
      15 + mass * 2,
      Paint()..color = AppColors.accent2,
    );
    canvas.drawCircle(
      Offset(r, 0),
      15 + mass * 2,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Radius label
    _drawText(canvas, 'r', Offset(r / 2 - 5, -20), AppColors.accent, 12);
  }

  void _drawRod(Canvas canvas, double r) {
    final rodLength = r * 2;
    final rodWidth = 12.0 + mass;

    final rodRect = Rect.fromCenter(
      center: Offset.zero,
      width: rodLength,
      height: rodWidth,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rodRect, Radius.circular(rodWidth / 2)),
      Paint()..color = AppColors.accent.withValues(alpha: 0.8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rodRect, Radius.circular(rodWidth / 2)),
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Length markers
    canvas.drawLine(
      Offset(-rodLength / 2, rodWidth / 2 + 10),
      Offset(rodLength / 2, rodWidth / 2 + 10),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 1,
    );
    _drawText(canvas, 'L', Offset(-5, rodWidth / 2 + 15), AppColors.accent, 12);
  }

  void _drawDisk(Canvas canvas, double r) {
    // Disk with gradient
    final diskGradient = RadialGradient(
      colors: [
        AppColors.accent,
        AppColors.accent.withValues(alpha: 0.6),
      ],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));

    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..shader = diskGradient,
    );
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Radius line
    canvas.drawLine(
      Offset.zero,
      Offset(r, 0),
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = 2,
    );
    _drawText(canvas, 'r', Offset(r / 2 - 5, -15), AppColors.ink, 12);

    // Spokes for rotation visualization
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      canvas.drawLine(
        Offset.zero,
        Offset(r * 0.8 * math.cos(angle), r * 0.8 * math.sin(angle)),
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );
    }
  }

  void _drawRing(Canvas canvas, double r) {
    final ringWidth = 8.0 + mass;

    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = AppColors.accent2
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth,
    );
    canvas.drawCircle(
      Offset.zero,
      r - ringWidth / 2,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset.zero,
      r + ringWidth / 2,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Radius line
    canvas.drawLine(
      Offset.zero,
      Offset(r, 0),
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = 2,
    );
    _drawText(canvas, 'r', Offset(r / 2 - 5, -15), AppColors.ink, 12);
  }

  void _drawShapeComparison(Canvas canvas, Size size) {
    final startX = size.width - 100;
    final startY = 20.0;
    final spacing = 50.0;
    final iconSize = 15.0;

    final coefficients = ['1', '1/12', '1/2', '1'];

    for (int i = 0; i < 4; i++) {
      final y = startY + i * spacing;
      final isSelected = i == shapeType;

      // Mini shape icon
      canvas.save();
      canvas.translate(startX + iconSize, y + iconSize);

      final paint = Paint()
        ..color = isSelected ? AppColors.accent : AppColors.muted.withValues(alpha: 0.5)
        ..style = i == 3 ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = 3;

      switch (i) {
        case 0:
          canvas.drawCircle(Offset.zero, 5, paint);
          break;
        case 1:
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 25, height: 6), paint);
          break;
        case 2:
          canvas.drawCircle(Offset.zero, iconSize, paint);
          break;
        case 3:
          canvas.drawCircle(Offset.zero, iconSize, paint);
          break;
      }

      canvas.restore();

      // Coefficient
      _drawText(
        canvas,
        '${coefficients[i]}mr²',
        Offset(startX + 40, y + iconSize - 5),
        isSelected ? AppColors.accent : AppColors.muted,
        10,
      );
    }
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

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant MomentInertiaPainter oldDelegate) => true;
}
