import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Epidemic SIR Model Simulation
class EpidemicSirScreen extends ConsumerStatefulWidget {
  const EpidemicSirScreen({super.key});

  @override
  ConsumerState<EpidemicSirScreen> createState() => _EpidemicSirScreenState();
}

class _EpidemicSirScreenState extends ConsumerState<EpidemicSirScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // SIR parameters
  double _beta = 0.3; // Transmission rate
  double _gamma = 0.1; // Recovery rate
  double _totalPopulation = 1000;

  // Population state (as fractions)
  double _susceptible = 0.99;
  double _infected = 0.01;
  double _recovered = 0.0;
  double _time = 0.0;
  bool _isRunning = false;

  // History for graph
  final List<double> _sHistory = [];
  final List<double> _iHistory = [];
  final List<double> _rHistory = [];
  final List<double> _timeHistory = [];

  double get _r0 => _beta / _gamma; // Basic reproduction number

  @override
  void initState() {
    super.initState();
    _initializeHistory();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateSIR);
  }

  void _initializeHistory() {
    _sHistory.clear();
    _iHistory.clear();
    _rHistory.clear();
    _timeHistory.clear();
    _sHistory.add(_susceptible);
    _iHistory.add(_infected);
    _rHistory.add(_recovered);
    _timeHistory.add(0);
  }

  void _updateSIR() {
    if (!_isRunning) return;

    setState(() {
      const dt = 0.1;
      _time += dt;

      // SIR model differential equations
      // dS/dt = -beta * S * I
      // dI/dt = beta * S * I - gamma * I
      // dR/dt = gamma * I
      final dS = -_beta * _susceptible * _infected * dt;
      final dI = (_beta * _susceptible * _infected - _gamma * _infected) * dt;
      final dR = _gamma * _infected * dt;

      _susceptible = math.max(0, _susceptible + dS);
      _infected = math.max(0, _infected + dI);
      _recovered = math.min(1, _recovered + dR);

      // Normalize to ensure S + I + R = 1
      final total = _susceptible + _infected + _recovered;
      _susceptible /= total;
      _infected /= total;
      _recovered /= total;

      // Record history
      _sHistory.add(_susceptible);
      _iHistory.add(_infected);
      _rHistory.add(_recovered);
      _timeHistory.add(_time);

      // Limit history size
      if (_sHistory.length > 500) {
        _sHistory.removeAt(0);
        _iHistory.removeAt(0);
        _rHistory.removeAt(0);
        _timeHistory.removeAt(0);
      }

      // Stop when infection is very low
      if (_infected < 0.0001) {
        _isRunning = false;
        _controller.stop();
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

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _controller.stop();
      _susceptible = 0.99;
      _infected = 0.01;
      _recovered = 0.0;
      _time = 0.0;
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
    final isKorean = ref.watch(languageProvider.notifier).isKorean;

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
              isKorean ? '전염병 SIR 모델' : 'Epidemic SIR Model',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '생물학' : 'Biology',
          title: isKorean ? '전염병 SIR 모델' : 'Epidemic SIR Model',
          formula: 'dS/dt = -bSI, dI/dt = bSI - gI, dR/dt = gI',
          formulaDescription: isKorean
              ? 'SIR 모델은 감수성(S), 감염(I), 회복(R) 인구를 추적하여 전염병 확산을 모델링합니다.'
              : 'The SIR model tracks Susceptible, Infected, and Recovered populations to model epidemic spread.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _EpidemicSirPainter(
                sHistory: _sHistory,
                iHistory: _iHistory,
                rHistory: _rHistory,
                timeHistory: _timeHistory,
                totalPopulation: _totalPopulation,
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
                          label: isKorean ? '감수성 (S)' : 'Susceptible',
                          value: '${(_susceptible * _totalPopulation).toInt()}',
                          color: Colors.blue,
                        ),
                        _InfoItem(
                          label: isKorean ? '감염 (I)' : 'Infected',
                          value: '${(_infected * _totalPopulation).toInt()}',
                          color: Colors.red,
                        ),
                        _InfoItem(
                          label: isKorean ? '회복 (R)' : 'Recovered',
                          value: '${(_recovered * _totalPopulation).toInt()}',
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _InfoItem(
                          label: isKorean ? '기초재생산수 R0' : 'Basic R0',
                          value: _r0.toStringAsFixed(2),
                          color: _r0 > 1 ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 30),
                        _InfoItem(
                          label: isKorean ? '시간 (일)' : 'Time (days)',
                          value: _time.toStringAsFixed(0),
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // R0 indicator
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _r0 > 1 ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _r0 > 1 ? Colors.red.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _r0 > 1 ? Icons.trending_up : Icons.trending_down,
                      color: _r0 > 1 ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _r0 > 1
                            ? (isKorean ? 'R0 > 1: 전염병 확산 중' : 'R0 > 1: Epidemic spreading')
                            : (isKorean ? 'R0 < 1: 전염병 소멸 중' : 'R0 < 1: Epidemic declining'),
                        style: TextStyle(
                          color: _r0 > 1 ? Colors.red : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? 'b (전파율)' : 'b (Transmission rate)',
                  value: _beta,
                  min: 0.05,
                  max: 1.0,
                  defaultValue: 0.3,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _beta = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? 'g (회복률)' : 'g (Recovery rate)',
                    value: _gamma,
                    min: 0.01,
                    max: 0.5,
                    defaultValue: 0.1,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _gamma = v),
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

class _EpidemicSirPainter extends CustomPainter {
  final List<double> sHistory;
  final List<double> iHistory;
  final List<double> rHistory;
  final List<double> timeHistory;
  final double totalPopulation;
  final bool isKorean;

  _EpidemicSirPainter({
    required this.sHistory,
    required this.iHistory,
    required this.rHistory,
    required this.timeHistory,
    required this.totalPopulation,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 50.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

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

    // Grid
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    for (int i = 1; i <= 4; i++) {
      final y = padding + graphHeight * i / 4;
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);

      final label = '${((4 - i) * 25)}%';
      _drawText(canvas, label, Offset(padding - 35, y - 6), AppColors.muted, 10);
    }

    // Labels
    _drawText(canvas, isKorean ? '인구 비율' : 'Population %',
        Offset(5, padding - 20), AppColors.muted, 10);
    _drawText(canvas, isKorean ? '시간 (일)' : 'Time (days)',
        Offset(size.width - 70, size.height - 20), AppColors.muted, 10);

    if (sHistory.isEmpty) return;

    final maxTime = timeHistory.isNotEmpty ? math.max(timeHistory.last, 1.0) : 1.0;

    // Draw S line (Susceptible - blue)
    _drawLine(canvas, sHistory, timeHistory, maxTime, padding, graphWidth, graphHeight, Colors.blue);

    // Draw I line (Infected - red)
    _drawLine(canvas, iHistory, timeHistory, maxTime, padding, graphWidth, graphHeight, Colors.red);

    // Draw R line (Recovered - green)
    _drawLine(canvas, rHistory, timeHistory, maxTime, padding, graphWidth, graphHeight, Colors.green);

    // Legend
    _drawLegend(canvas, padding);
  }

  void _drawLine(Canvas canvas, List<double> data, List<double> time, double maxTime,
      double padding, double graphWidth, double graphHeight, Color color) {
    if (data.isEmpty) return;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = padding + (time[i] / maxTime) * graphWidth;
      final y = padding + graphHeight * (1 - data[i]);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);

    // Current point
    if (data.isNotEmpty) {
      final lastX = padding + (time.last / maxTime) * graphWidth;
      final lastY = padding + graphHeight * (1 - data.last);
      canvas.drawCircle(Offset(lastX, lastY), 5, Paint()..color = color);
    }
  }

  void _drawLegend(Canvas canvas, double padding) {
    final legends = [
      (isKorean ? '감수성 (S)' : 'Susceptible (S)', Colors.blue),
      (isKorean ? '감염 (I)' : 'Infected (I)', Colors.red),
      (isKorean ? '회복 (R)' : 'Recovered (R)', Colors.green),
    ];

    double x = padding + 10;
    for (final legend in legends) {
      canvas.drawLine(
        Offset(x, padding + 15),
        Offset(x + 20, padding + 15),
        Paint()..color = legend.$2..strokeWidth = 2,
      );
      _drawText(canvas, legend.$1, Offset(x + 25, padding + 8), legend.$2, 10);
      x += 100;
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _EpidemicSirPainter oldDelegate) => true;
}
