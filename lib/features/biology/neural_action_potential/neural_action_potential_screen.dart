import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Action Potential (Hodgkin-Huxley) Simulation
class NeuralActionPotentialScreen extends ConsumerStatefulWidget {
  const NeuralActionPotentialScreen({super.key});

  @override
  ConsumerState<NeuralActionPotentialScreen> createState() => _NeuralActionPotentialScreenState();
}

class _NeuralActionPotentialScreenState extends ConsumerState<NeuralActionPotentialScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Hodgkin-Huxley parameters
  double _stimulus = 10.0; // Applied current (uA/cm^2)
  double _gNa = 120.0; // Sodium conductance
  double _gK = 36.0; // Potassium conductance
  double _gL = 0.3; // Leak conductance

  // Reversal potentials (mV)
  static const double _eNa = 50.0;
  static const double _eK = -77.0;
  static const double _eL = -54.4;
  static const double _cm = 1.0; // Membrane capacitance

  // State variables
  double _v = -65.0; // Membrane potential (mV)
  double _m = 0.05; // Na activation
  double _h = 0.6; // Na inactivation
  double _n = 0.32; // K activation
  double _time = 0.0;
  bool _isRunning = false;
  bool _stimulusOn = false;

  // History for graph
  final List<double> _vHistory = [];
  final List<double> _timeHistory = [];
  final List<double> _naCurrentHistory = [];
  final List<double> _kCurrentHistory = [];

  @override
  void initState() {
    super.initState();
    _initializeHistory();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updatePotential);
  }

  void _initializeHistory() {
    _vHistory.clear();
    _timeHistory.clear();
    _naCurrentHistory.clear();
    _kCurrentHistory.clear();
    _vHistory.add(_v);
    _timeHistory.add(0);
    _naCurrentHistory.add(0);
    _kCurrentHistory.add(0);
  }

  // Alpha and beta rate functions
  double _alphaM(double v) => 0.1 * (v + 40) / (1 - math.exp(-(v + 40) / 10));
  double _betaM(double v) => 4.0 * math.exp(-(v + 65) / 18);
  double _alphaH(double v) => 0.07 * math.exp(-(v + 65) / 20);
  double _betaH(double v) => 1.0 / (1 + math.exp(-(v + 35) / 10));
  double _alphaN(double v) => 0.01 * (v + 55) / (1 - math.exp(-(v + 55) / 10));
  double _betaN(double v) => 0.125 * math.exp(-(v + 65) / 80);

  void _updatePotential() {
    if (!_isRunning) return;

    setState(() {
      const dt = 0.05; // Time step (ms)
      _time += dt;

      // Applied stimulus
      final iApp = _stimulusOn ? _stimulus : 0.0;

      // Ionic currents
      final iNa = _gNa * math.pow(_m, 3) * _h * (_v - _eNa);
      final iK = _gK * math.pow(_n, 4) * (_v - _eK);
      final iL = _gL * (_v - _eL);

      // Membrane potential derivative
      final dV = (iApp - iNa - iK - iL) / _cm * dt;
      _v += dV;

      // Gating variable derivatives
      final dM = (_alphaM(_v) * (1 - _m) - _betaM(_v) * _m) * dt;
      final dH = (_alphaH(_v) * (1 - _h) - _betaH(_v) * _h) * dt;
      final dN = (_alphaN(_v) * (1 - _n) - _betaN(_v) * _n) * dt;

      _m = (_m + dM).clamp(0.0, 1.0);
      _h = (_h + dH).clamp(0.0, 1.0);
      _n = (_n + dN).clamp(0.0, 1.0);

      // Record history
      _vHistory.add(_v);
      _timeHistory.add(_time);
      _naCurrentHistory.add(-iNa);
      _kCurrentHistory.add(-iK);

      // Limit history size
      if (_vHistory.length > 500) {
        _vHistory.removeAt(0);
        _timeHistory.removeAt(0);
        _naCurrentHistory.removeAt(0);
        _kCurrentHistory.removeAt(0);
      }
    });
  }

  void _toggleRunning() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _applyStimulus() {
    HapticFeedback.heavyImpact();
    setState(() {
      _stimulusOn = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _stimulusOn = false);
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _controller.stop();
      _v = -65.0;
      _m = 0.05;
      _h = 0.6;
      _n = 0.32;
      _time = 0.0;
      _stimulusOn = false;
      _initializeHistory();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);

    // Determine current phase
    String phase;
    Color phaseColor;
    if (_v < -55) {
      phase = isKorean ? '휴지 상태' : 'Resting';
      phaseColor = Colors.blue;
    } else if (_v < 0 && _vHistory.length > 1 && _v > _vHistory[_vHistory.length - 2]) {
      phase = isKorean ? '탈분극' : 'Depolarization';
      phaseColor = Colors.red;
    } else if (_v > 0) {
      phase = isKorean ? '오버슈트' : 'Overshoot';
      phaseColor = Colors.orange;
    } else {
      phase = isKorean ? '재분극' : 'Repolarization';
      phaseColor = Colors.green;
    }

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
              isKorean ? '활동 전위' : 'Action Potential',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '생물학' : 'Biology',
          title: isKorean ? '활동 전위 (Hodgkin-Huxley)' : 'Action Potential (Hodgkin-Huxley)',
          formula: 'C(dV/dt) = I - gNa*m^3*h*(V-ENa) - gK*n^4*(V-EK) - gL*(V-EL)',
          formulaDescription: isKorean
              ? 'Hodgkin-Huxley 모델은 신경세포막의 이온 채널을 통한 전류 흐름을 설명합니다.'
              : 'The Hodgkin-Huxley model describes ionic currents through nerve cell membrane channels.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ActionPotentialPainter(
                vHistory: _vHistory,
                timeHistory: _timeHistory,
                naCurrentHistory: _naCurrentHistory,
                kCurrentHistory: _kCurrentHistory,
                currentV: _v,
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
                          label: isKorean ? '막전위 (mV)' : 'Membrane V',
                          value: '${_v.toStringAsFixed(1)} mV',
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: isKorean ? '단계' : 'Phase',
                          value: phase,
                          color: phaseColor,
                        ),
                        _InfoItem(
                          label: isKorean ? '시간 (ms)' : 'Time (ms)',
                          value: _time.toStringAsFixed(1),
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _GatingItem(label: 'm', value: _m, color: Colors.red),
                        _GatingItem(label: 'h', value: _h, color: Colors.orange),
                        _GatingItem(label: 'n', value: _n, color: Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stimulus indicator
              if (_stimulusOn)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.yellow, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isKorean ? '자극 적용 중...' : 'Stimulus applied...',
                        style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              if (_stimulusOn) const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '자극 강도 (uA/cm2)' : 'Stimulus (uA/cm2)',
                  value: _stimulus,
                  min: 0,
                  max: 50,
                  defaultValue: 10,
                  formatValue: (v) => v.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _stimulus = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? 'Na+ 전도도' : 'Na+ Conductance',
                    value: _gNa,
                    min: 0,
                    max: 200,
                    defaultValue: 120,
                    formatValue: (v) => v.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _gNa = v),
                  ),
                  SimSlider(
                    label: isKorean ? 'K+ 전도도' : 'K+ Conductance',
                    value: _gK,
                    min: 0,
                    max: 100,
                    defaultValue: 36,
                    formatValue: (v) => v.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _gK = v),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning
                    ? (isKorean ? '일시정지' : 'Pause')
                    : (isKorean ? '시작' : 'Start'),
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleRunning,
              ),
              SimButton(
                label: isKorean ? '자극' : 'Stimulate',
                icon: Icons.bolt,
                onPressed: _applyStimulus,
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

class _GatingItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _GatingItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.cardBorder,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(value.toStringAsFixed(2), style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }
}

class _ActionPotentialPainter extends CustomPainter {
  final List<double> vHistory;
  final List<double> timeHistory;
  final List<double> naCurrentHistory;
  final List<double> kCurrentHistory;
  final double currentV;
  final bool isKorean;

  _ActionPotentialPainter({
    required this.vHistory,
    required this.timeHistory,
    required this.naCurrentHistory,
    required this.kCurrentHistory,
    required this.currentV,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Draw membrane potential graph (top)
    _drawVoltageGraph(canvas, Rect.fromLTWH(0, 0, size.width, size.height * 0.6));

    // Draw ionic currents graph (bottom)
    _drawCurrentGraph(canvas, Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4));
  }

  void _drawVoltageGraph(Canvas canvas, Rect bounds) {
    final padding = 50.0;
    final graphWidth = bounds.width - padding * 2;
    final graphHeight = bounds.height - padding - 20;

    // Title
    _drawText(canvas, isKorean ? '막전위' : 'Membrane Potential',
        Offset(bounds.left + padding, bounds.top + 5), AppColors.accent, 11, fontWeight: FontWeight.bold);

    // Axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(bounds.left + padding, bounds.top + 20),
      Offset(bounds.left + padding, bounds.bottom - 10),
      axisPaint,
    );
    canvas.drawLine(
      Offset(bounds.left + padding, bounds.bottom - 10),
      Offset(bounds.right - 10, bounds.bottom - 10),
      axisPaint,
    );

    // Y-axis labels
    final voltageRange = 150.0; // -100 to +50 mV
    for (final v in [-100.0, -50.0, 0.0, 50.0]) {
      final y = bounds.top + 20 + graphHeight * (1 - (v + 100) / voltageRange);
      canvas.drawLine(
        Offset(bounds.left + padding - 5, y),
        Offset(bounds.left + padding, y),
        axisPaint,
      );
      _drawText(canvas, '${v.toInt()}', Offset(bounds.left + padding - 35, y - 5), AppColors.muted, 9);
    }
    _drawText(canvas, 'mV', Offset(bounds.left + 5, bounds.top + 30), AppColors.muted, 9);

    // Resting potential line
    final restingY = bounds.top + 20 + graphHeight * (1 - (-65 + 100) / voltageRange);
    canvas.drawLine(
      Offset(bounds.left + padding, restingY),
      Offset(bounds.right - 10, restingY),
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // Threshold line
    final thresholdY = bounds.top + 20 + graphHeight * (1 - (-55 + 100) / voltageRange);
    canvas.drawLine(
      Offset(bounds.left + padding, thresholdY),
      Offset(bounds.right - 10, thresholdY),
      Paint()
        ..color = Colors.red.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
    _drawText(canvas, isKorean ? '역치' : 'Threshold', Offset(bounds.right - 50, thresholdY - 12), Colors.red, 8);

    if (vHistory.isEmpty) return;

    final maxTime = timeHistory.isNotEmpty ? math.max(timeHistory.last, 10.0) : 10.0;

    // Draw voltage trace
    final path = Path();
    for (int i = 0; i < vHistory.length; i++) {
      final x = bounds.left + padding + (timeHistory[i] / maxTime) * graphWidth;
      final y = bounds.top + 20 + graphHeight * (1 - (vHistory[i] + 100) / voltageRange);

      if (i == 0) {
        path.moveTo(x, y.clamp(bounds.top + 20, bounds.bottom - 10));
      } else {
        path.lineTo(x, y.clamp(bounds.top + 20, bounds.bottom - 10));
      }
    }

    canvas.drawPath(path, Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);

    // Current point
    if (vHistory.isNotEmpty) {
      final lastX = bounds.left + padding + (timeHistory.last / maxTime) * graphWidth;
      final lastY = bounds.top + 20 + graphHeight * (1 - (vHistory.last + 100) / voltageRange);
      canvas.drawCircle(
        Offset(lastX, lastY.clamp(bounds.top + 20, bounds.bottom - 10)),
        4,
        Paint()..color = AppColors.accent,
      );
    }
  }

  void _drawCurrentGraph(Canvas canvas, Rect bounds) {
    final padding = 50.0;
    final graphWidth = bounds.width - padding * 2;
    final graphHeight = bounds.height - 30;

    // Separator
    canvas.drawLine(
      Offset(bounds.left + padding, bounds.top),
      Offset(bounds.right - 10, bounds.top),
      Paint()..color = AppColors.cardBorder,
    );

    // Title
    _drawText(canvas, isKorean ? '이온 전류' : 'Ionic Currents',
        Offset(bounds.left + padding, bounds.top + 5), AppColors.accent, 10);

    if (naCurrentHistory.isEmpty) return;

    final maxTime = timeHistory.isNotEmpty ? math.max(timeHistory.last, 10.0) : 10.0;
    final maxCurrent = math.max(
      naCurrentHistory.map((e) => e.abs()).reduce(math.max),
      kCurrentHistory.map((e) => e.abs()).reduce(math.max),
    );
    final currentScale = maxCurrent > 0 ? maxCurrent : 1;

    // Draw Na+ current
    final naPath = Path();
    for (int i = 0; i < naCurrentHistory.length; i++) {
      final x = bounds.left + padding + (timeHistory[i] / maxTime) * graphWidth;
      final y = bounds.top + 20 + graphHeight / 2 - (naCurrentHistory[i] / currentScale) * graphHeight * 0.4;

      if (i == 0) {
        naPath.moveTo(x, y);
      } else {
        naPath.lineTo(x, y);
      }
    }
    canvas.drawPath(naPath, Paint()
      ..color = Colors.red
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);

    // Draw K+ current
    final kPath = Path();
    for (int i = 0; i < kCurrentHistory.length; i++) {
      final x = bounds.left + padding + (timeHistory[i] / maxTime) * graphWidth;
      final y = bounds.top + 20 + graphHeight / 2 - (kCurrentHistory[i] / currentScale) * graphHeight * 0.4;

      if (i == 0) {
        kPath.moveTo(x, y);
      } else {
        kPath.lineTo(x, y);
      }
    }
    canvas.drawPath(kPath, Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);

    // Legend
    canvas.drawLine(
      Offset(bounds.right - 100, bounds.top + 10),
      Offset(bounds.right - 85, bounds.top + 10),
      Paint()..color = Colors.red..strokeWidth = 2,
    );
    _drawText(canvas, 'Na+', Offset(bounds.right - 80, bounds.top + 5), Colors.red, 9);

    canvas.drawLine(
      Offset(bounds.right - 55, bounds.top + 10),
      Offset(bounds.right - 40, bounds.top + 10),
      Paint()..color = Colors.blue..strokeWidth = 2,
    );
    _drawText(canvas, 'K+', Offset(bounds.right - 35, bounds.top + 5), Colors.blue, 9);
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
  bool shouldRepaint(covariant _ActionPotentialPainter oldDelegate) => true;
}
