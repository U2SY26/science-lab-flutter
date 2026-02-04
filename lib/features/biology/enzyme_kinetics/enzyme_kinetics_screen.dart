import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Enzyme Kinetics (Michaelis-Menten) Simulation
class EnzymeKineticsScreen extends ConsumerStatefulWidget {
  const EnzymeKineticsScreen({super.key});

  @override
  ConsumerState<EnzymeKineticsScreen> createState() => _EnzymeKineticsScreenState();
}

class _EnzymeKineticsScreenState extends ConsumerState<EnzymeKineticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Michaelis-Menten parameters
  double _vMax = 100.0; // Maximum reaction velocity
  double _kM = 50.0; // Michaelis constant
  double _substrateConc = 0.0; // Current substrate concentration [S]
  double _inhibitorConc = 0.0; // Inhibitor concentration
  String _inhibitionType = 'none'; // 'none', 'competitive', 'noncompetitive', 'uncompetitive'

  // Animation state
  bool _isAnimating = false;
  double _animationProgress = 0.0;

  // Data for plotting
  final List<Offset> _kineticsData = [];

  @override
  void initState() {
    super.initState();
    _generateKineticsData();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateAnimation);
  }

  void _generateKineticsData() {
    _kineticsData.clear();
    for (double s = 0; s <= 200; s += 2) {
      final v = _calculateVelocity(s);
      _kineticsData.add(Offset(s, v));
    }
  }

  double _calculateVelocity(double substrate) {
    double effectiveVmax = _vMax;
    double effectiveKm = _kM;

    // Apply inhibition effects
    final ki = 50.0; // Inhibitor constant
    switch (_inhibitionType) {
      case 'competitive':
        // Competitive: increases apparent Km
        effectiveKm = _kM * (1 + _inhibitorConc / ki);
        break;
      case 'noncompetitive':
        // Non-competitive: decreases apparent Vmax
        effectiveVmax = _vMax / (1 + _inhibitorConc / ki);
        break;
      case 'uncompetitive':
        // Uncompetitive: decreases both Vmax and Km
        final factor = 1 + _inhibitorConc / ki;
        effectiveVmax = _vMax / factor;
        effectiveKm = _kM / factor;
        break;
    }

    // Michaelis-Menten equation: V = Vmax * [S] / (Km + [S])
    return effectiveVmax * substrate / (effectiveKm + substrate);
  }

  void _updateAnimation() {
    if (!_isAnimating) return;

    setState(() {
      _animationProgress += 0.02;
      _substrateConc = _animationProgress * 200;

      if (_animationProgress >= 1.0) {
        _animationProgress = 1.0;
        _substrateConc = 200;
        _isAnimating = false;
        _controller.stop();
      }
    });
  }

  void _startAnimation() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAnimating = true;
      _animationProgress = 0.0;
      _substrateConc = 0.0;
      _controller.repeat();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAnimating = false;
      _animationProgress = 0.0;
      _substrateConc = 0.0;
      _controller.stop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(languageProvider.notifier).isKorean;

    final currentVelocity = _calculateVelocity(_substrateConc);
    final halfVmax = _vMax / 2;

    // Regenerate data when parameters change
    _generateKineticsData();

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
              isKorean ? '생물학' : 'BIOLOGY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '효소 반응 속도론' : 'Enzyme Kinetics',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '생물학' : 'Biology',
          title: isKorean ? '효소 반응 속도론 (Michaelis-Menten)' : 'Enzyme Kinetics (Michaelis-Menten)',
          formula: 'V = Vmax[S] / (Km + [S])',
          formulaDescription: isKorean
              ? 'Michaelis-Menten 방정식: 기질 농도([S])에 따른 효소 반응 속도(V)를 설명합니다.'
              : 'Michaelis-Menten equation: Describes enzyme reaction velocity (V) as a function of substrate concentration ([S]).',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _EnzymeKineticsPainter(
                kineticsData: _kineticsData,
                vMax: _vMax,
                kM: _kM,
                currentSubstrate: _substrateConc,
                currentVelocity: currentVelocity,
                inhibitionType: _inhibitionType,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(
                          label: '[S]',
                          value: _substrateConc.toStringAsFixed(1),
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: 'V',
                          value: currentVelocity.toStringAsFixed(1),
                          color: Colors.green,
                        ),
                        _InfoItem(
                          label: 'Vmax',
                          value: _vMax.toStringAsFixed(0),
                          color: Colors.orange,
                        ),
                        _InfoItem(
                          label: 'Km',
                          value: _kM.toStringAsFixed(0),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // V/Vmax indicator
                    Row(
                      children: [
                        Text(
                          'V/Vmax: ',
                          style: const TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (currentVelocity / _vMax).clamp(0, 1),
                            backgroundColor: AppColors.cardBorder,
                            valueColor: AlwaysStoppedAnimation(
                              currentVelocity >= halfVmax ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${((currentVelocity / _vMax) * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Inhibition type selection
              PresetGroup(
                label: isKorean ? '저해제 유형' : 'Inhibition Type',
                presets: [
                  PresetButton(
                    label: isKorean ? '없음' : 'None',
                    isSelected: _inhibitionType == 'none',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _inhibitionType = 'none');
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '경쟁적' : 'Competitive',
                    isSelected: _inhibitionType == 'competitive',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _inhibitionType = 'competitive');
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '비경쟁적' : 'Non-comp',
                    isSelected: _inhibitionType == 'noncompetitive',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _inhibitionType = 'noncompetitive');
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '불경쟁적' : 'Uncomp',
                    isSelected: _inhibitionType == 'uncompetitive',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _inhibitionType = 'uncompetitive');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '기질 농도 [S]' : 'Substrate [S]',
                  value: _substrateConc,
                  min: 0,
                  max: 200,
                  defaultValue: 0,
                  formatValue: (v) => v.toStringAsFixed(0),
                  onChanged: (v) => setState(() {
                    _substrateConc = v;
                    _isAnimating = false;
                    _controller.stop();
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: 'Vmax',
                    value: _vMax,
                    min: 10,
                    max: 200,
                    defaultValue: 100,
                    formatValue: (v) => v.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _vMax = v),
                  ),
                  SimSlider(
                    label: 'Km',
                    value: _kM,
                    min: 5,
                    max: 150,
                    defaultValue: 50,
                    formatValue: (v) => v.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _kM = v),
                  ),
                  if (_inhibitionType != 'none')
                    SimSlider(
                      label: isKorean ? '저해제 농도 [I]' : 'Inhibitor [I]',
                      value: _inhibitorConc,
                      min: 0,
                      max: 100,
                      defaultValue: 0,
                      formatValue: (v) => v.toStringAsFixed(0),
                      onChanged: (v) => setState(() => _inhibitorConc = v),
                    ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '애니메이션' : 'Animate',
                icon: Icons.play_arrow,
                isPrimary: true,
                onPressed: _startAnimation,
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

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EnzymeKineticsPainter extends CustomPainter {
  final List<Offset> kineticsData;
  final double vMax;
  final double kM;
  final double currentSubstrate;
  final double currentVelocity;
  final String inhibitionType;
  final bool isKorean;

  _EnzymeKineticsPainter({
    required this.kineticsData,
    required this.vMax,
    required this.kM,
    required this.currentSubstrate,
    required this.currentVelocity,
    required this.inhibitionType,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 50.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    final maxS = 200.0;
    final maxV = vMax * 1.2;

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    for (int i = 1; i <= 4; i++) {
      final y = padding + graphHeight * i / 4;
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
    }

    // Axis labels
    _drawText(canvas, 'V', Offset(padding - 30, padding - 10), AppColors.muted, 12);
    _drawText(canvas, '[S]', Offset(size.width - padding - 10, size.height - padding + 15), AppColors.muted, 12);

    // Vmax line
    final vmaxY = padding + graphHeight * (1 - vMax / maxV);
    canvas.drawLine(
      Offset(padding, vmaxY),
      Offset(size.width - padding, vmaxY),
      Paint()
        ..color = Colors.orange.withValues(alpha: 0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    _drawText(canvas, 'Vmax', Offset(size.width - padding + 5, vmaxY - 6), Colors.orange, 10);

    // Vmax/2 line
    final halfVmaxY = padding + graphHeight * (1 - (vMax / 2) / maxV);
    canvas.drawLine(
      Offset(padding, halfVmaxY),
      Offset(size.width - padding, halfVmaxY),
      Paint()
        ..color = Colors.orange.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
    _drawText(canvas, 'Vmax/2', Offset(size.width - padding + 5, halfVmaxY - 6), Colors.orange.withValues(alpha: 0.7), 9);

    // Km vertical line
    final kmX = padding + (kM / maxS) * graphWidth;
    canvas.drawLine(
      Offset(kmX, padding),
      Offset(kmX, size.height - padding),
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
    _drawText(canvas, 'Km', Offset(kmX - 8, size.height - padding + 5), Colors.blue, 10);

    // Draw Michaelis-Menten curve
    if (kineticsData.isNotEmpty) {
      final path = Path();
      for (int i = 0; i < kineticsData.length; i++) {
        final x = padding + (kineticsData[i].dx / maxS) * graphWidth;
        final y = padding + graphHeight * (1 - kineticsData[i].dy / maxV);

        if (i == 0) {
          path.moveTo(x, y.clamp(padding, size.height - padding));
        } else {
          path.lineTo(x, y.clamp(padding, size.height - padding));
        }
      }

      canvas.drawPath(path, Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round);
    }

    // Current point
    final currentX = padding + (currentSubstrate / maxS) * graphWidth;
    final currentY = padding + graphHeight * (1 - currentVelocity / maxV);

    // Dashed lines to axes
    _drawDashedLine(canvas, Offset(currentX, currentY), Offset(currentX, size.height - padding), Colors.green.withValues(alpha: 0.5));
    _drawDashedLine(canvas, Offset(currentX, currentY), Offset(padding, currentY), Colors.green.withValues(alpha: 0.5));

    // Current point
    canvas.drawCircle(
      Offset(currentX, currentY.clamp(padding, size.height - padding)),
      8,
      Paint()..color = Colors.green.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      Offset(currentX, currentY.clamp(padding, size.height - padding)),
      5,
      Paint()..color = Colors.green,
    );

    // Inhibition type label
    if (inhibitionType != 'none') {
      String inhibLabel;
      switch (inhibitionType) {
        case 'competitive':
          inhibLabel = isKorean ? '경쟁적 저해' : 'Competitive Inhibition';
          break;
        case 'noncompetitive':
          inhibLabel = isKorean ? '비경쟁적 저해' : 'Non-competitive Inhibition';
          break;
        case 'uncompetitive':
          inhibLabel = isKorean ? '불경쟁적 저해' : 'Uncompetitive Inhibition';
          break;
        default:
          inhibLabel = '';
      }
      _drawText(canvas, inhibLabel, Offset(padding + 10, padding + 10), Colors.red, 11, fontWeight: FontWeight.bold);
    }

    // Title
    _drawText(canvas, isKorean ? 'Michaelis-Menten 곡선' : 'Michaelis-Menten Curve',
        Offset(size.width / 2 - 60, padding - 25), AppColors.accent, 12, fontWeight: FontWeight.bold);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final steps = (distance / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < steps; i++) {
      final t1 = i * (dashWidth + dashSpace) / distance;
      final t2 = (i * (dashWidth + dashSpace) + dashWidth) / distance;

      canvas.drawLine(
        Offset(start.dx + dx * t1, start.dy + dy * t1),
        Offset(start.dx + dx * math.min(t2, 1.0), start.dy + dy * math.min(t2, 1.0)),
        paint,
      );
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize,
      {FontWeight fontWeight = FontWeight.normal}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _EnzymeKineticsPainter oldDelegate) => true;
}
