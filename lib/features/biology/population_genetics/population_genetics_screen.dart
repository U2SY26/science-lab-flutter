import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Population Genetics (Hardy-Weinberg) Simulation
class PopulationGeneticsScreen extends ConsumerStatefulWidget {
  const PopulationGeneticsScreen({super.key});

  @override
  ConsumerState<PopulationGeneticsScreen> createState() => _PopulationGeneticsScreenState();
}

class _PopulationGeneticsScreenState extends ConsumerState<PopulationGeneticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  // Hardy-Weinberg parameters
  double _pFreq = 0.5; // Frequency of dominant allele (A)
  int _populationSize = 100;
  double _mutationRate = 0.0;
  double _selectionCoeff = 0.0; // Selection against aa
  bool _enableDrift = true;

  // State
  int _generation = 0;
  bool _isRunning = false;
  double _currentP = 0.5;

  // History
  final List<double> _pHistory = [];
  final List<double> _aaHistory = [];
  final List<double> _AaHistory = [];
  final List<double> _AAHistory = [];

  // Hardy-Weinberg equilibrium values
  double get _qFreq => 1 - _currentP;
  double get _AA => _currentP * _currentP;
  double get _Aa => 2 * _currentP * _qFreq;
  double get _aa => _qFreq * _qFreq;

  @override
  void initState() {
    super.initState();
    _currentP = _pFreq;
    _initializeHistory();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(_updateGeneration);
  }

  void _initializeHistory() {
    _pHistory.clear();
    _aaHistory.clear();
    _AaHistory.clear();
    _AAHistory.clear();
    _pHistory.add(_currentP);
    _AAHistory.add(_AA);
    _AaHistory.add(_Aa);
    _aaHistory.add(_aa);
  }

  void _updateGeneration() {
    if (!_isRunning) return;

    setState(() {
      _generation++;

      // Calculate expected genotype frequencies
      double pNext = _currentP;

      // Selection
      if (_selectionCoeff > 0) {
        final wAA = 1.0;
        final wAa = 1.0;
        final waa = 1.0 - _selectionCoeff;

        final meanFitness = _AA * wAA + _Aa * wAa + _aa * waa;
        pNext = (_currentP * _currentP * wAA + _currentP * _qFreq * wAa) / meanFitness;
      }

      // Mutation (A -> a at rate mu)
      if (_mutationRate > 0) {
        pNext = pNext * (1 - _mutationRate) + (1 - pNext) * _mutationRate * 0.1;
      }

      // Genetic drift (random sampling)
      if (_enableDrift) {
        // Binomial sampling
        int aCount = 0;
        final totalAlleles = _populationSize * 2;
        for (int i = 0; i < totalAlleles; i++) {
          if (_random.nextDouble() < pNext) {
            aCount++;
          }
        }
        pNext = aCount / totalAlleles;
      }

      _currentP = pNext.clamp(0.001, 0.999);

      // Record history
      _pHistory.add(_currentP);
      _AAHistory.add(_AA);
      _AaHistory.add(_Aa);
      _aaHistory.add(_aa);

      // Limit history
      if (_pHistory.length > 200) {
        _pHistory.removeAt(0);
        _AAHistory.removeAt(0);
        _AaHistory.removeAt(0);
        _aaHistory.removeAt(0);
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
      _generation = 0;
      _currentP = _pFreq;
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

    // Check if in equilibrium (no evolution forces)
    final isEquilibrium = _mutationRate == 0 && _selectionCoeff == 0 && !_enableDrift;

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
              isKorean ? '집단 유전학' : 'Population Genetics',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '생물학' : 'Biology',
          title: isKorean ? '집단 유전학 (Hardy-Weinberg)' : 'Population Genetics (Hardy-Weinberg)',
          formula: 'p^2 + 2pq + q^2 = 1',
          formulaDescription: isKorean
              ? 'Hardy-Weinberg 법칙: 진화적 힘이 없으면 대립유전자 빈도가 세대를 거쳐 일정하게 유지됩니다.'
              : 'Hardy-Weinberg law: Allele frequencies remain constant across generations without evolutionary forces.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PopulationGeneticsPainter(
                pHistory: _pHistory,
                AAHistory: _AAHistory,
                AaHistory: _AaHistory,
                aaHistory: _aaHistory,
                currentP: _currentP,
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
                          label: 'p (A)',
                          value: _currentP.toStringAsFixed(3),
                          color: Colors.blue,
                        ),
                        _InfoItem(
                          label: 'q (a)',
                          value: _qFreq.toStringAsFixed(3),
                          color: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _GenotypeItem(label: 'AA', value: _AA, color: Colors.blue),
                        _GenotypeItem(label: 'Aa', value: _Aa, color: Colors.purple),
                        _GenotypeItem(label: 'aa', value: _aa, color: Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Equilibrium indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isEquilibrium
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isEquilibrium
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEquilibrium ? Icons.balance : Icons.trending_up,
                      color: isEquilibrium ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEquilibrium
                            ? (isKorean ? 'Hardy-Weinberg 평형 상태' : 'Hardy-Weinberg Equilibrium')
                            : (isKorean ? '진화 진행 중 (평형 위반)' : 'Evolution occurring (Non-equilibrium)'),
                        style: TextStyle(
                          color: isEquilibrium ? Colors.green : Colors.orange,
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
                  label: isKorean ? '초기 p 빈도' : 'Initial p frequency',
                  value: _pFreq,
                  min: 0.01,
                  max: 0.99,
                  defaultValue: 0.5,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() {
                      _pFreq = v;
                      if (!_isRunning) {
                        _currentP = v;
                        _initializeHistory();
                      }
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '집단 크기' : 'Population Size',
                    value: _populationSize.toDouble(),
                    min: 10,
                    max: 1000,
                    defaultValue: 100,
                    formatValue: (v) => v.toInt().toString(),
                    onChanged: (v) => setState(() => _populationSize = v.toInt()),
                  ),
                  SimSlider(
                    label: isKorean ? '선택 계수 (aa에 대해)' : 'Selection (against aa)',
                    value: _selectionCoeff,
                    min: 0,
                    max: 1.0,
                    defaultValue: 0,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => setState(() => _selectionCoeff = v),
                  ),
                  SimSlider(
                    label: isKorean ? '돌연변이율' : 'Mutation Rate',
                    value: _mutationRate,
                    min: 0,
                    max: 0.1,
                    defaultValue: 0,
                    formatValue: (v) => '${(v * 100).toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() => _mutationRate = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Drift toggle
              Row(
                children: [
                  Switch(
                    value: _enableDrift,
                    onChanged: (v) => setState(() => _enableDrift = v),
                    activeColor: AppColors.accent,
                  ),
                  Text(
                    isKorean ? '유전적 부동' : 'Genetic Drift',
                    style: const TextStyle(color: AppColors.ink),
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

class _GenotypeItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _GenotypeItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.cardBorder,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text('${(value * 100).toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }
}

class _PopulationGeneticsPainter extends CustomPainter {
  final List<double> pHistory;
  final List<double> AAHistory;
  final List<double> AaHistory;
  final List<double> aaHistory;
  final double currentP;
  final bool isKorean;

  _PopulationGeneticsPainter({
    required this.pHistory,
    required this.AAHistory,
    required this.AaHistory,
    required this.aaHistory,
    required this.currentP,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Draw allele frequency graph (top)
    _drawAlleleGraph(canvas, Rect.fromLTWH(0, 0, size.width, size.height * 0.5));

    // Draw genotype frequency graph (bottom)
    _drawGenotypeGraph(canvas, Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.5));
  }

  void _drawAlleleGraph(Canvas canvas, Rect bounds) {
    final padding = 50.0;
    final graphWidth = bounds.width - padding * 2;
    final graphHeight = bounds.height - 40;

    // Title
    _drawText(canvas, isKorean ? '대립유전자 빈도' : 'Allele Frequency',
        Offset(bounds.left + padding, bounds.top + 5), AppColors.accent, 11, fontWeight: FontWeight.bold);

    // Axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(bounds.left + padding, bounds.top + 25),
      Offset(bounds.left + padding, bounds.bottom - 15),
      axisPaint,
    );
    canvas.drawLine(
      Offset(bounds.left + padding, bounds.bottom - 15),
      Offset(bounds.right - 10, bounds.bottom - 15),
      axisPaint,
    );

    // Y-axis labels
    for (final v in [0.0, 0.5, 1.0]) {
      final y = bounds.bottom - 15 - v * graphHeight;
      _drawText(canvas, v.toStringAsFixed(1), Offset(bounds.left + padding - 30, y - 5), AppColors.muted, 9);
    }

    if (pHistory.isEmpty) return;

    // Draw p (A allele) frequency
    final pPath = Path();
    for (int i = 0; i < pHistory.length; i++) {
      final x = bounds.left + padding + (i / math.max(pHistory.length - 1, 1)) * graphWidth;
      final y = bounds.bottom - 15 - pHistory[i] * graphHeight;
      if (i == 0) {
        pPath.moveTo(x, y);
      } else {
        pPath.lineTo(x, y);
      }
    }
    canvas.drawPath(pPath, Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);

    // Draw q (a allele) frequency
    final qPath = Path();
    for (int i = 0; i < pHistory.length; i++) {
      final x = bounds.left + padding + (i / math.max(pHistory.length - 1, 1)) * graphWidth;
      final y = bounds.bottom - 15 - (1 - pHistory[i]) * graphHeight;
      if (i == 0) {
        qPath.moveTo(x, y);
      } else {
        qPath.lineTo(x, y);
      }
    }
    canvas.drawPath(qPath, Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);

    // Legend
    canvas.drawLine(
      Offset(bounds.right - 80, bounds.top + 15),
      Offset(bounds.right - 65, bounds.top + 15),
      Paint()..color = Colors.blue..strokeWidth = 2,
    );
    _drawText(canvas, 'p (A)', Offset(bounds.right - 60, bounds.top + 10), Colors.blue, 10);

    canvas.drawLine(
      Offset(bounds.right - 80, bounds.top + 30),
      Offset(bounds.right - 65, bounds.top + 30),
      Paint()..color = Colors.red..strokeWidth = 2,
    );
    _drawText(canvas, 'q (a)', Offset(bounds.right - 60, bounds.top + 25), Colors.red, 10);
  }

  void _drawGenotypeGraph(Canvas canvas, Rect bounds) {
    final padding = 50.0;
    final graphWidth = bounds.width - padding * 2;
    final graphHeight = bounds.height - 40;

    // Separator
    canvas.drawLine(
      Offset(bounds.left + padding, bounds.top),
      Offset(bounds.right - 10, bounds.top),
      Paint()..color = AppColors.cardBorder,
    );

    // Title
    _drawText(canvas, isKorean ? '유전자형 빈도' : 'Genotype Frequency',
        Offset(bounds.left + padding, bounds.top + 5), AppColors.accent, 11, fontWeight: FontWeight.bold);

    // Axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(bounds.left + padding, bounds.top + 25),
      Offset(bounds.left + padding, bounds.bottom - 15),
      axisPaint,
    );
    canvas.drawLine(
      Offset(bounds.left + padding, bounds.bottom - 15),
      Offset(bounds.right - 10, bounds.bottom - 15),
      axisPaint,
    );

    if (AAHistory.isEmpty) return;

    // Draw stacked area
    for (int i = 1; i < AAHistory.length; i++) {
      final x1 = bounds.left + padding + ((i - 1) / math.max(AAHistory.length - 1, 1)) * graphWidth;
      final x2 = bounds.left + padding + (i / math.max(AAHistory.length - 1, 1)) * graphWidth;

      // AA (bottom)
      final aa1Y = bounds.bottom - 15 - AAHistory[i - 1] * graphHeight;
      final aa2Y = bounds.bottom - 15 - AAHistory[i] * graphHeight;

      // Aa (middle)
      final aA1Y = aa1Y - AaHistory[i - 1] * graphHeight;
      final aA2Y = aa2Y - AaHistory[i] * graphHeight;

      // Draw AA
      final aaPath = Path()
        ..moveTo(x1, bounds.bottom - 15)
        ..lineTo(x1, aa1Y)
        ..lineTo(x2, aa2Y)
        ..lineTo(x2, bounds.bottom - 15)
        ..close();
      canvas.drawPath(aaPath, Paint()..color = Colors.blue.withValues(alpha: 0.5));

      // Draw Aa
      final aAPath = Path()
        ..moveTo(x1, aa1Y)
        ..lineTo(x1, aA1Y)
        ..lineTo(x2, aA2Y)
        ..lineTo(x2, aa2Y)
        ..close();
      canvas.drawPath(aAPath, Paint()..color = Colors.purple.withValues(alpha: 0.5));

      // Draw aa
      final aaTopPath = Path()
        ..moveTo(x1, aA1Y)
        ..lineTo(x1, bounds.top + 25)
        ..lineTo(x2, bounds.top + 25)
        ..lineTo(x2, aA2Y)
        ..close();
      canvas.drawPath(aaTopPath, Paint()..color = Colors.red.withValues(alpha: 0.5));
    }

    // Legend
    final legendY = bounds.top + 15;
    canvas.drawRect(Rect.fromLTWH(bounds.right - 85, legendY, 12, 12), Paint()..color = Colors.blue.withValues(alpha: 0.7));
    _drawText(canvas, 'AA', Offset(bounds.right - 70, legendY), Colors.blue, 10);

    canvas.drawRect(Rect.fromLTWH(bounds.right - 85, legendY + 15, 12, 12), Paint()..color = Colors.purple.withValues(alpha: 0.7));
    _drawText(canvas, 'Aa', Offset(bounds.right - 70, legendY + 15), Colors.purple, 10);

    canvas.drawRect(Rect.fromLTWH(bounds.right - 85, legendY + 30, 12, 12), Paint()..color = Colors.red.withValues(alpha: 0.7));
    _drawText(canvas, 'aa', Offset(bounds.right - 70, legendY + 30), Colors.red, 10);
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
  bool shouldRepaint(covariant _PopulationGeneticsPainter oldDelegate) => true;
}
