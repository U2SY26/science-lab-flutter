import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// First Law of Thermodynamics simulation: ΔU = Q - W
class FirstLawScreen extends StatefulWidget {
  const FirstLawScreen({super.key});

  @override
  State<FirstLawScreen> createState() => _FirstLawScreenState();
}

class _FirstLawScreenState extends State<FirstLawScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  double heatIn = 100.0; // Q (J)
  double workDone = 40.0; // W (J)
  double internalEnergy = 200.0; // U (J)
  double initialU = 200.0;

  int processType = 0; // 0: general, 1: isothermal, 2: adiabatic, 3: isochoric

  bool isAnimating = false;
  bool isKorean = true;
  double animProgress = 0.0;

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
    if (!isAnimating) return;

    setState(() {
      animProgress += 0.01;
      if (animProgress >= 1.0) {
        animProgress = 1.0;
        isAnimating = false;
        internalEnergy = initialU + deltaU;
      }
    });
  }

  double get deltaU => heatIn - workDone;

  void _applyProcess() {
    HapticFeedback.selectionClick();
    setState(() {
      initialU = internalEnergy;
      animProgress = 0;
      isAnimating = true;
    });
  }

  void _setProcessType(int type) {
    setState(() {
      processType = type;
      switch (type) {
        case 1: // Isothermal: ΔU = 0, Q = W
          heatIn = workDone;
          break;
        case 2: // Adiabatic: Q = 0, ΔU = -W
          heatIn = 0;
          break;
        case 3: // Isochoric: W = 0, ΔU = Q
          workDone = 0;
          break;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      heatIn = 100;
      workDone = 40;
      internalEnergy = 200;
      initialU = 200;
      processType = 0;
      animProgress = 0;
      isAnimating = false;
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
              isKorean ? '열역학' : 'THERMODYNAMICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '열역학 제1법칙' : 'First Law of Thermodynamics',
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
          category: isKorean ? '열역학' : 'Thermodynamics',
          title: isKorean ? '열역학 제1법칙' : 'First Law of Thermodynamics',
          formula: 'ΔU = Q - W',
          formulaDescription: isKorean
              ? '내부에너지 변화(ΔU)는 흡수한 열(Q)에서 한 일(W)을 뺀 것과 같습니다. 에너지 보존 법칙입니다.'
              : 'Change in internal energy (ΔU) equals heat absorbed (Q) minus work done (W). This is energy conservation.',
          simulation: CustomPaint(
            painter: FirstLawPainter(
              heatIn: heatIn,
              workDone: workDone,
              internalEnergy: internalEnergy,
              initialU: initialU,
              deltaU: deltaU,
              animProgress: animProgress,
              processType: processType,
              isKorean: isKorean,
            ),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Process type selection
              PresetGroup(
                label: isKorean ? '열역학 과정' : 'Thermodynamic Process',
                presets: [
                  PresetButton(
                    label: isKorean ? '일반' : 'General',
                    isSelected: processType == 0,
                    onPressed: () => _setProcessType(0),
                  ),
                  PresetButton(
                    label: isKorean ? '등온' : 'Isothermal',
                    isSelected: processType == 1,
                    onPressed: () => _setProcessType(1),
                  ),
                  PresetButton(
                    label: isKorean ? '단열' : 'Adiabatic',
                    isSelected: processType == 2,
                    onPressed: () => _setProcessType(2),
                  ),
                  PresetButton(
                    label: isKorean ? '등적' : 'Isochoric',
                    isSelected: processType == 3,
                    onPressed: () => _setProcessType(3),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '열 (Q)' : 'Heat (Q)',
                  value: heatIn,
                  min: -100,
                  max: 200,
                  defaultValue: 100,
                  formatValue: (v) => '${v.toStringAsFixed(0)} J',
                  onChanged: (v) => setState(() {
                    if (processType != 2) {
                      heatIn = v;
                      if (processType == 1) workDone = v;
                    }
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '일 (W)' : 'Work (W)',
                    value: workDone,
                    min: -100,
                    max: 200,
                    defaultValue: 40,
                    formatValue: (v) => '${v.toStringAsFixed(0)} J',
                    onChanged: (v) => setState(() {
                      if (processType != 3) {
                        workDone = v;
                        if (processType == 1) heatIn = v;
                      }
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _EnergyDisplay(
                heatIn: heatIn,
                workDone: workDone,
                deltaU: deltaU,
                internalEnergy: internalEnergy,
                processType: processType,
                isKorean: isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '과정 적용' : 'Apply Process',
                icon: Icons.play_arrow,
                isPrimary: true,
                onPressed: isAnimating ? null : _applyProcess,
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

class _EnergyDisplay extends StatelessWidget {
  final double heatIn;
  final double workDone;
  final double deltaU;
  final double internalEnergy;
  final int processType;
  final bool isKorean;

  const _EnergyDisplay({
    required this.heatIn,
    required this.workDone,
    required this.deltaU,
    required this.internalEnergy,
    required this.processType,
    required this.isKorean,
  });

  String get processName {
    switch (processType) {
      case 1:
        return isKorean ? '등온 과정: ΔU = 0' : 'Isothermal: ΔU = 0';
      case 2:
        return isKorean ? '단열 과정: Q = 0' : 'Adiabatic: Q = 0';
      case 3:
        return isKorean ? '등적 과정: W = 0' : 'Isochoric: W = 0';
      default:
        return isKorean ? '일반 과정' : 'General Process';
    }
  }

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
                label: isKorean ? '열 (Q)' : 'Heat (Q)',
                value: '${heatIn.toStringAsFixed(0)} J',
                color: heatIn >= 0 ? Colors.red : Colors.blue,
              ),
              _InfoItem(
                label: isKorean ? '일 (W)' : 'Work (W)',
                value: '${workDone.toStringAsFixed(0)} J',
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: 'ΔU',
                value: '${deltaU.toStringAsFixed(0)} J',
                color: deltaU >= 0 ? AppColors.accent : AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Text(
                  processName,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ΔU = ${heatIn.toStringAsFixed(0)} - ${workDone.toStringAsFixed(0)} = ${deltaU.toStringAsFixed(0)} J',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
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

class FirstLawPainter extends CustomPainter {
  final double heatIn;
  final double workDone;
  final double internalEnergy;
  final double initialU;
  final double deltaU;
  final double animProgress;
  final int processType;
  final bool isKorean;

  FirstLawPainter({
    required this.heatIn,
    required this.workDone,
    required this.internalEnergy,
    required this.initialU,
    required this.deltaU,
    required this.animProgress,
    required this.processType,
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
    final centerY = size.height / 2 - 20;

    // Draw system (cylinder/piston)
    _drawSystem(canvas, Offset(centerX, centerY));

    // Draw heat flow arrow (Q)
    if (heatIn.abs() > 1) {
      _drawHeatArrow(canvas, Offset(centerX - 100, centerY), heatIn > 0);
    }

    // Draw work arrow (W)
    if (workDone.abs() > 1) {
      _drawWorkArrow(canvas, Offset(centerX, centerY - 80), workDone > 0);
    }

    // Draw energy bar
    _drawEnergyBar(canvas, Offset(centerX + 80, centerY - 50), 30, 120);

    // Draw equation
    _drawEquation(canvas, Offset(20, size.height - 60));

    // Animation effects
    if (animProgress > 0 && animProgress < 1) {
      _drawAnimationEffects(canvas, Offset(centerX, centerY));
    }
  }

  void _drawSystem(Canvas canvas, Offset center) {
    // Cylinder body
    final cylinderRect = Rect.fromCenter(
      center: center,
      width: 100,
      height: 120,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(cylinderRect, const Radius.circular(10)),
      Paint()..color = AppColors.cardBorder,
    );

    // Gas inside (color based on internal energy)
    final energyColor = Color.lerp(
      Colors.blue.withValues(alpha: 0.3),
      Colors.red.withValues(alpha: 0.3),
      (internalEnergy / 400).clamp(0.0, 1.0),
    )!;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center.translate(0, 10), width: 90, height: 100),
        const Radius.circular(5),
      ),
      Paint()..color = energyColor,
    );

    // Piston
    final pistonY = center.dy - 50 - (workDone > 0 ? animProgress * 10 : 0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, pistonY), width: 95, height: 15),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.muted,
    );

    // Piston rod
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx, pistonY - 20), width: 20, height: 30),
      Paint()..color = AppColors.pivot,
    );

    // Label
    _drawText(canvas, isKorean ? '계 (System)' : 'System',
        Offset(center.dx - 30, center.dy + 70), AppColors.muted, 10);
  }

  void _drawHeatArrow(Canvas canvas, Offset position, bool inward) {
    final arrowLength = 60.0;
    final startX = inward ? position.dx - arrowLength : position.dx;
    final endX = inward ? position.dx : position.dx - arrowLength;

    // Arrow glow
    canvas.drawLine(
      Offset(startX, position.dy),
      Offset(endX, position.dy),
      Paint()
        ..color = (inward ? Colors.red : Colors.blue).withValues(alpha: 0.3)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    // Arrow line
    canvas.drawLine(
      Offset(startX, position.dy),
      Offset(endX, position.dy),
      Paint()
        ..color = inward ? Colors.red : Colors.blue
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Arrow head
    final headX = inward ? endX : startX;
    final direction = inward ? 1 : -1;
    final arrowPath = Path()
      ..moveTo(headX, position.dy)
      ..lineTo(headX - direction * 12, position.dy - 8)
      ..lineTo(headX - direction * 12, position.dy + 8)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = inward ? Colors.red : Colors.blue);

    // Label
    final label = inward
        ? (isKorean ? 'Q (열 흡수)' : 'Q (Heat In)')
        : (isKorean ? 'Q (열 방출)' : 'Q (Heat Out)');
    _drawText(canvas, label, Offset(startX - 20, position.dy - 25), inward ? Colors.red : Colors.blue, 10);
  }

  void _drawWorkArrow(Canvas canvas, Offset position, bool outward) {
    final arrowLength = 50.0;
    final startY = outward ? position.dy : position.dy - arrowLength;
    final endY = outward ? position.dy - arrowLength : position.dy;

    // Arrow line
    canvas.drawLine(
      Offset(position.dx, startY),
      Offset(position.dx, endY),
      Paint()
        ..color = AppColors.accent2
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Arrow head
    final headY = outward ? endY : startY;
    final direction = outward ? -1 : 1;
    final arrowPath = Path()
      ..moveTo(position.dx, headY)
      ..lineTo(position.dx - 8, headY + direction * 12)
      ..lineTo(position.dx + 8, headY + direction * 12)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = AppColors.accent2);

    // Label
    final label = outward
        ? (isKorean ? 'W (일 함)' : 'W (Work Done)')
        : (isKorean ? 'W (일 받음)' : 'W (Work On)');
    _drawText(canvas, label, Offset(position.dx + 10, endY - 10), AppColors.accent2, 10);
  }

  void _drawEnergyBar(Canvas canvas, Offset position, double width, double height) {
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx, position.dy, width, height),
        const Radius.circular(5),
      ),
      Paint()..color = AppColors.cardBorder,
    );

    // Energy fill
    final fillHeight = (internalEnergy / 400 * height).clamp(0.0, height);
    final energyColor = Color.lerp(Colors.blue, Colors.red, (internalEnergy / 400).clamp(0.0, 1.0))!;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx + 3, position.dy + height - fillHeight + 3, width - 6, fillHeight - 6),
        const Radius.circular(3),
      ),
      Paint()..color = energyColor,
    );

    // Delta U indicator
    if (deltaU.abs() > 1 && animProgress > 0) {
      final deltaHeight = (deltaU.abs() / 400 * height).clamp(0.0, height / 2);
      final deltaY = deltaU > 0
          ? position.dy + height - fillHeight - deltaHeight * animProgress
          : position.dy + height - fillHeight + 3;

      canvas.drawRect(
        Rect.fromLTWH(position.dx + 3, deltaY, width - 6, deltaHeight * animProgress),
        Paint()..color = (deltaU > 0 ? Colors.green : Colors.orange).withValues(alpha: 0.5),
      );
    }

    // Labels
    _drawText(canvas, 'U', Offset(position.dx + 8, position.dy - 18), AppColors.ink, 12);
    _drawText(canvas, '${internalEnergy.toStringAsFixed(0)} J',
        Offset(position.dx - 5, position.dy + height + 5), AppColors.ink, 9);
  }

  void _drawEquation(Canvas canvas, Offset position) {
    // Background box
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(position.dx, position.dy, 200, 45),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.card.withValues(alpha: 0.8),
    );

    _drawText(canvas, 'ΔU = Q - W', Offset(position.dx + 10, position.dy + 5), AppColors.ink, 14);
    _drawText(
      canvas,
      '${deltaU.toStringAsFixed(0)} = ${heatIn.toStringAsFixed(0)} - ${workDone.toStringAsFixed(0)}',
      Offset(position.dx + 10, position.dy + 25),
      AppColors.accent,
      12,
    );
  }

  void _drawAnimationEffects(Canvas canvas, Offset center) {
    // Heat particles moving in
    if (heatIn > 0) {
      for (int i = 0; i < 5; i++) {
        final t = (animProgress + i * 0.2) % 1.0;
        final x = center.dx - 100 + t * 80;
        final y = center.dy + math.sin(t * math.pi * 2) * 10;
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()..color = Colors.red.withValues(alpha: 1 - t),
        );
      }
    }

    // Work particles moving out
    if (workDone > 0) {
      for (int i = 0; i < 3; i++) {
        final t = (animProgress + i * 0.3) % 1.0;
        final x = center.dx + math.sin(t * math.pi * 2) * 5;
        final y = center.dy - 60 - t * 40;
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()..color = AppColors.accent2.withValues(alpha: 1 - t),
        );
      }
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
  bool shouldRepaint(covariant FirstLawPainter oldDelegate) => true;
}
