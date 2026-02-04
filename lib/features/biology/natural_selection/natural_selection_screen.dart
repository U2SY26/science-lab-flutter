import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Natural Selection Simulation
class NaturalSelectionScreen extends ConsumerStatefulWidget {
  const NaturalSelectionScreen({super.key});

  @override
  ConsumerState<NaturalSelectionScreen> createState() => _NaturalSelectionScreenState();
}

class _NaturalSelectionScreenState extends ConsumerState<NaturalSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  // Selection parameters
  double _selectionPressure = 0.5; // 0 = no selection, 1 = strong selection
  double _mutationRate = 0.01;
  String _environmentType = 'light'; // 'light' or 'dark'

  // Organism population
  List<Organism> _organisms = [];
  int _generation = 0;
  bool _isRunning = false;

  // Statistics
  final List<double> _avgFitnessHistory = [];
  final List<double> _lightColorHistory = [];
  final List<double> _darkColorHistory = [];

  @override
  void initState() {
    super.initState();
    _initializePopulation();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(_updateGeneration);
  }

  void _initializePopulation() {
    _organisms = List.generate(50, (i) {
      final color = _random.nextDouble(); // 0 = white, 1 = black
      return Organism(
        color: color,
        x: _random.nextDouble(),
        y: _random.nextDouble(),
      );
    });
    _generation = 0;
    _avgFitnessHistory.clear();
    _lightColorHistory.clear();
    _darkColorHistory.clear();
    _recordStats();
  }

  void _recordStats() {
    if (_organisms.isEmpty) return;

    double totalFitness = 0;
    int lightCount = 0;
    int darkCount = 0;

    for (final org in _organisms) {
      totalFitness += _calculateFitness(org);
      if (org.color < 0.5) {
        lightCount++;
      } else {
        darkCount++;
      }
    }

    _avgFitnessHistory.add(totalFitness / _organisms.length);
    _lightColorHistory.add(lightCount / _organisms.length);
    _darkColorHistory.add(darkCount / _organisms.length);

    // Limit history
    if (_avgFitnessHistory.length > 100) {
      _avgFitnessHistory.removeAt(0);
      _lightColorHistory.removeAt(0);
      _darkColorHistory.removeAt(0);
    }
  }

  double _calculateFitness(Organism org) {
    // Fitness based on camouflage
    // In light environment, light colors have higher fitness
    // In dark environment, dark colors have higher fitness
    final idealColor = _environmentType == 'light' ? 0.0 : 1.0;
    final colorDiff = (org.color - idealColor).abs();
    final baseFitness = 1.0 - colorDiff;

    // Apply selection pressure
    return math.pow(baseFitness, _selectionPressure * 3 + 1).toDouble();
  }

  void _updateGeneration() {
    if (!_isRunning) return;

    setState(() {
      _generation++;

      // Selection: survival based on fitness
      final survivors = <Organism>[];
      for (final org in _organisms) {
        final fitness = _calculateFitness(org);
        if (_random.nextDouble() < fitness) {
          survivors.add(org);
        }
      }

      // If too few survivors, keep at least some
      if (survivors.length < 5) {
        survivors.addAll(_organisms.take(5 - survivors.length));
      }

      // Reproduction with mutation
      final newPopulation = <Organism>[];
      while (newPopulation.length < 50) {
        final parent = survivors[_random.nextInt(survivors.length)];

        // Mutation
        double newColor = parent.color;
        if (_random.nextDouble() < _mutationRate) {
          newColor += (_random.nextDouble() - 0.5) * 0.2;
          newColor = newColor.clamp(0.0, 1.0);
        }

        newPopulation.add(Organism(
          color: newColor,
          x: _random.nextDouble(),
          y: _random.nextDouble(),
        ));
      }

      _organisms = newPopulation;
      _recordStats();
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
      _initializePopulation();
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

    // Calculate current statistics
    int lightCount = _organisms.where((o) => o.color < 0.5).length;
    int darkCount = _organisms.length - lightCount;
    double avgColor = _organisms.isEmpty ? 0.5 : _organisms.map((o) => o.color).reduce((a, b) => a + b) / _organisms.length;

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
              isKorean ? '자연 선택' : 'Natural Selection',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '생물학' : 'Biology',
          title: isKorean ? '자연 선택' : 'Natural Selection',
          formula: 'W = 1 - s(p - p*)',
          formulaDescription: isKorean
              ? '적응도(W)가 높은 개체가 더 많이 생존하고 번식합니다. 환경에 적합한 형질이 세대를 거쳐 증가합니다.'
              : 'Individuals with higher fitness (W) survive and reproduce more. Traits suited to the environment increase over generations.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _NaturalSelectionPainter(
                organisms: _organisms,
                environmentType: _environmentType,
                lightColorHistory: _lightColorHistory,
                darkColorHistory: _darkColorHistory,
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
                          label: isKorean ? '세대' : 'Generation',
                          value: '$_generation',
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: isKorean ? '밝은 색' : 'Light',
                          value: '$lightCount',
                          color: Colors.amber,
                        ),
                        _InfoItem(
                          label: isKorean ? '어두운 색' : 'Dark',
                          value: '$darkCount',
                          color: Colors.brown,
                        ),
                        _InfoItem(
                          label: isKorean ? '평균 색상' : 'Avg Color',
                          value: avgColor.toStringAsFixed(2),
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Environment selection
              PresetGroup(
                label: isKorean ? '환경' : 'Environment',
                presets: [
                  PresetButton(
                    label: isKorean ? '밝은 환경' : 'Light',
                    isSelected: _environmentType == 'light',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _environmentType = 'light');
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '어두운 환경' : 'Dark',
                    isSelected: _environmentType == 'dark',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _environmentType = 'dark');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '선택압' : 'Selection Pressure',
                  value: _selectionPressure,
                  min: 0.0,
                  max: 1.0,
                  defaultValue: 0.5,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _selectionPressure = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '돌연변이율' : 'Mutation Rate',
                    value: _mutationRate,
                    min: 0.0,
                    max: 0.1,
                    defaultValue: 0.01,
                    formatValue: (v) => '${(v * 100).toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() => _mutationRate = v),
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

class Organism {
  final double color; // 0 = white, 1 = black
  final double x;
  final double y;

  Organism({required this.color, required this.x, required this.y});
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

class _NaturalSelectionPainter extends CustomPainter {
  final List<Organism> organisms;
  final String environmentType;
  final List<double> lightColorHistory;
  final List<double> darkColorHistory;
  final bool isKorean;

  _NaturalSelectionPainter({
    required this.organisms,
    required this.environmentType,
    required this.lightColorHistory,
    required this.darkColorHistory,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw environment background
    final envRect = Rect.fromLTWH(0, 0, size.width * 0.5, size.height * 0.6);
    final envColor = environmentType == 'light' ? Colors.amber[100]! : Colors.brown[700]!;
    canvas.drawRect(envRect, Paint()..color = envColor);

    // Environment label
    _drawText(canvas, isKorean ? '환경' : 'Environment',
        const Offset(10, 10), AppColors.ink, 12, fontWeight: FontWeight.bold);

    // Draw organisms
    for (final org in organisms) {
      final x = envRect.left + org.x * envRect.width * 0.9 + 10;
      final y = envRect.top + org.y * envRect.height * 0.9 + 30;

      final orgColor = Color.lerp(Colors.white, Colors.black, org.color)!;

      // Organism body
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = orgColor,
      );

      // Outline for visibility
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()
          ..color = AppColors.muted
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Draw frequency graph
    _drawFrequencyGraph(canvas, Rect.fromLTWH(size.width * 0.55, 0, size.width * 0.45, size.height * 0.6));

    // Draw color distribution histogram
    _drawHistogram(canvas, Rect.fromLTWH(0, size.height * 0.65, size.width, size.height * 0.35));
  }

  void _drawFrequencyGraph(Canvas canvas, Rect bounds) {
    final padding = 30.0;
    final graphWidth = bounds.width - padding * 2;
    final graphHeight = bounds.height - padding * 2;

    // Background
    canvas.drawRect(bounds, Paint()..color = AppColors.simBg);

    // Title
    _drawText(canvas, isKorean ? '표현형 빈도' : 'Phenotype Frequency',
        Offset(bounds.left + 10, bounds.top + 5), AppColors.accent, 11, fontWeight: FontWeight.bold);

    // Axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(bounds.left + padding, bounds.top + padding),
      Offset(bounds.left + padding, bounds.bottom - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(bounds.left + padding, bounds.bottom - padding),
      Offset(bounds.right - padding, bounds.bottom - padding),
      axisPaint,
    );

    if (lightColorHistory.isEmpty) return;

    // Draw light color line
    final lightPath = Path();
    for (int i = 0; i < lightColorHistory.length; i++) {
      final x = bounds.left + padding + (i / math.max(lightColorHistory.length - 1, 1)) * graphWidth;
      final y = bounds.bottom - padding - lightColorHistory[i] * graphHeight;
      if (i == 0) {
        lightPath.moveTo(x, y);
      } else {
        lightPath.lineTo(x, y);
      }
    }
    canvas.drawPath(lightPath, Paint()
      ..color = Colors.amber
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);

    // Draw dark color line
    final darkPath = Path();
    for (int i = 0; i < darkColorHistory.length; i++) {
      final x = bounds.left + padding + (i / math.max(darkColorHistory.length - 1, 1)) * graphWidth;
      final y = bounds.bottom - padding - darkColorHistory[i] * graphHeight;
      if (i == 0) {
        darkPath.moveTo(x, y);
      } else {
        darkPath.lineTo(x, y);
      }
    }
    canvas.drawPath(darkPath, Paint()
      ..color = Colors.brown
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);

    // Legend
    canvas.drawLine(
      Offset(bounds.left + padding + 5, bounds.top + 25),
      Offset(bounds.left + padding + 20, bounds.top + 25),
      Paint()..color = Colors.amber..strokeWidth = 2,
    );
    _drawText(canvas, isKorean ? '밝은색' : 'Light',
        Offset(bounds.left + padding + 25, bounds.top + 20), Colors.amber, 9);

    canvas.drawLine(
      Offset(bounds.left + padding + 65, bounds.top + 25),
      Offset(bounds.left + padding + 80, bounds.top + 25),
      Paint()..color = Colors.brown..strokeWidth = 2,
    );
    _drawText(canvas, isKorean ? '어두운색' : 'Dark',
        Offset(bounds.left + padding + 85, bounds.top + 20), Colors.brown, 9);
  }

  void _drawHistogram(Canvas canvas, Rect bounds) {
    final padding = 30.0;

    // Background
    canvas.drawRect(bounds, Paint()..color = AppColors.simBg.withValues(alpha: 0.5));

    // Title
    _drawText(canvas, isKorean ? '색상 분포' : 'Color Distribution',
        Offset(bounds.left + 10, bounds.top + 5), AppColors.accent, 11, fontWeight: FontWeight.bold);

    // Create histogram bins
    final bins = List.filled(10, 0);
    for (final org in organisms) {
      final binIndex = (org.color * 9.99).floor().clamp(0, 9);
      bins[binIndex]++;
    }

    final maxCount = bins.reduce(math.max);
    if (maxCount == 0) return;

    final binWidth = (bounds.width - padding * 2) / 10;
    final maxHeight = bounds.height - padding * 2;

    for (int i = 0; i < 10; i++) {
      final height = (bins[i] / maxCount) * maxHeight;
      final x = bounds.left + padding + i * binWidth;
      final y = bounds.bottom - padding - height;

      final binColor = Color.lerp(Colors.white, Colors.black, i / 9)!;

      canvas.drawRect(
        Rect.fromLTWH(x + 2, y, binWidth - 4, height),
        Paint()..color = binColor,
      );

      canvas.drawRect(
        Rect.fromLTWH(x + 2, y, binWidth - 4, height),
        Paint()
          ..color = AppColors.muted
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // X-axis labels
    _drawText(canvas, isKorean ? '밝음' : 'Light', Offset(bounds.left + padding, bounds.bottom - 15), AppColors.muted, 9);
    _drawText(canvas, isKorean ? '어두움' : 'Dark', Offset(bounds.right - padding - 30, bounds.bottom - 15), AppColors.muted, 9);
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
  bool shouldRepaint(covariant _NaturalSelectionPainter oldDelegate) => true;
}
