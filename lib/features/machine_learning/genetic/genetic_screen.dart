import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 유전 알고리즘 시뮬레이션
class GeneticScreen extends StatefulWidget {
  const GeneticScreen({super.key});

  @override
  State<GeneticScreen> createState() => _GeneticScreenState();
}

class _GeneticScreenState extends State<GeneticScreen> {
  final _random = math.Random();
  List<_Individual> _population = [];
  int _generation = 0;
  int _populationSize = 20;
  double _mutationRate = 0.1;
  bool _isRunning = false;

  // 목표: x^2 최대화 (0 ~ 31)
  String _targetBinary = '11111'; // 31
  int get _targetValue => 31;

  @override
  void initState() {
    super.initState();
    _initPopulation();
  }

  void _initPopulation() {
    _population = List.generate(_populationSize, (i) {
      final genes = List.generate(5, (j) => _random.nextBool() ? 1 : 0);
      return _Individual(genes);
    });
    _generation = 0;
    _sortByFitness();
  }

  int _decode(List<int> genes) {
    int value = 0;
    for (int i = 0; i < genes.length; i++) {
      value = value * 2 + genes[i];
    }
    return value;
  }

  double _fitness(_Individual ind) {
    final x = _decode(ind.genes);
    return (x * x).toDouble(); // f(x) = x^2
  }

  void _sortByFitness() {
    _population.sort((a, b) => _fitness(b).compareTo(_fitness(a)));
  }

  _Individual _crossover(_Individual a, _Individual b) {
    final crossPoint = _random.nextInt(5);
    final childGenes = <int>[];
    for (int i = 0; i < 5; i++) {
      childGenes.add(i < crossPoint ? a.genes[i] : b.genes[i]);
    }
    return _Individual(childGenes);
  }

  void _mutate(_Individual ind) {
    for (int i = 0; i < ind.genes.length; i++) {
      if (_random.nextDouble() < _mutationRate) {
        ind.genes[i] = 1 - ind.genes[i];
      }
    }
  }

  void _evolve() {
    // 선택 (상위 50% 유지)
    final survivors = _population.take(_populationSize ~/ 2).toList();

    // 교차 및 돌연변이로 새 개체 생성
    final newPopulation = <_Individual>[...survivors];
    while (newPopulation.length < _populationSize) {
      final parent1 = survivors[_random.nextInt(survivors.length)];
      final parent2 = survivors[_random.nextInt(survivors.length)];
      final child = _crossover(parent1, parent2);
      _mutate(child);
      newPopulation.add(child);
    }

    _population = newPopulation;
    _sortByFitness();
    _generation++;
  }

  void _startEvolution() async {
    _isRunning = true;
    for (int i = 0; i < 50 && _isRunning; i++) {
      _evolve();
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 200));

      // 최적해 도달 시 종료
      if (_decode(_population.first.genes) == _targetValue) {
        break;
      }
    }
    _isRunning = false;
    setState(() {});
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _isRunning = false;
    _initPopulation();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bestIndividual = _population.isNotEmpty ? _population.first : null;
    final bestValue = bestIndividual != null ? _decode(bestIndividual.genes) : 0;
    final bestFitness = bestIndividual != null ? _fitness(bestIndividual) : 0;

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
              'AI/ML',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '유전 알고리즘',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML',
          title: '유전 알고리즘',
          formula: 'f(x) = x² 최대화',
          formulaDescription: '자연선택과 돌연변이로 최적해를 찾는 진화 알고리즘',
          simulation: SizedBox(
            height: 280,
            child: CustomPaint(
              painter: _GeneticPainter(
                population: _population,
                decode: _decode,
                fitness: _fitness,
                targetValue: _targetValue,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bestValue == _targetValue ? Colors.green.withValues(alpha: 0.1) : AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: bestValue == _targetValue ? Colors.green : AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    if (bestValue == _targetValue)
                      const Text('🎉 최적해 발견!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '세대', value: '$_generation', color: Colors.blue),
                        _InfoItem(label: '최고 적합도', value: bestFitness.toStringAsFixed(0), color: AppColors.accent),
                        _InfoItem(label: '최고 값', value: '$bestValue / $_targetValue', color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (bestIndividual != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('최고 유전자: ', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                          ...bestIndividual.genes.map((g) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: g == 1 ? AppColors.accent : AppColors.card,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('$g', style: TextStyle(color: g == 1 ? Colors.white : AppColors.muted, fontSize: 12)),
                              )),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '돌연변이율',
                  value: _mutationRate,
                  min: 0,
                  max: 0.5,
                  defaultValue: 0.1,
                  formatValue: (v) => '${(v * 100).toInt()}%',
                  onChanged: (v) => setState(() => _mutationRate = v),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning ? '진화 중...' : '진화 시작',
                icon: Icons.play_arrow,
                isPrimary: true,
                onPressed: _isRunning ? null : () {
                  HapticFeedback.selectionClick();
                  _startEvolution();
                },
              ),
              SimButton(
                label: '1 세대',
                icon: Icons.skip_next,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _evolve();
                  setState(() {});
                },
              ),
              SimButton(
                label: '리셋',
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

class _Individual {
  List<int> genes;
  _Individual(this.genes);
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
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _GeneticPainter extends CustomPainter {
  final List<_Individual> population;
  final int Function(List<int>) decode;
  final double Function(_Individual) fitness;
  final int targetValue;

  _GeneticPainter({
    required this.population,
    required this.decode,
    required this.fitness,
    required this.targetValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 30.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;
    final maxFitness = (targetValue * targetValue).toDouble();

    // 축
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      Paint()..color = AppColors.muted.withValues(alpha: 0.5),
    );

    // f(x) = x^2 곡선
    final curvePath = Path();
    for (int x = 0; x <= 31; x++) {
      final px = padding + (x / 31) * graphWidth;
      final py = size.height - padding - (x * x / maxFitness) * graphHeight;
      if (x == 0) {
        curvePath.moveTo(px, py);
      } else {
        curvePath.lineTo(px, py);
      }
    }
    canvas.drawPath(
      curvePath,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 개체들
    for (int i = 0; i < population.length; i++) {
      final ind = population[i];
      final x = decode(ind.genes);
      final f = fitness(ind);

      final px = padding + (x / 31) * graphWidth;
      final py = size.height - padding - (f / maxFitness) * graphHeight;

      final isTop = i < 3;
      final color = isTop ? Colors.green : Colors.blue.withValues(alpha: 0.5);
      final radius = isTop ? 8.0 : 5.0;

      canvas.drawCircle(Offset(px, py), radius, Paint()..color = color);

      if (isTop) {
        canvas.drawCircle(
          Offset(px, py),
          radius,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // 라벨
    _drawText(canvas, 'x', Offset(size.width - padding + 5, size.height - padding + 5), AppColors.muted);
    _drawText(canvas, 'f(x)=x²', Offset(padding + 5, padding - 15), AppColors.muted);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _GeneticPainter oldDelegate) => true;
}
