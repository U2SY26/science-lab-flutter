import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Cell Division (Mitosis/Meiosis) Simulation
class CellDivisionScreen extends ConsumerStatefulWidget {
  const CellDivisionScreen({super.key});

  @override
  ConsumerState<CellDivisionScreen> createState() => _CellDivisionScreenState();
}

class _CellDivisionScreenState extends ConsumerState<CellDivisionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Division parameters
  String _divisionType = 'mitosis'; // 'mitosis' or 'meiosis'
  double _animationSpeed = 1.0;
  double _phase = 0.0; // 0-1 for each phase
  int _currentPhase = 0;
  bool _isRunning = false;

  // Mitosis phases: Interphase, Prophase, Metaphase, Anaphase, Telophase, Cytokinesis
  // Meiosis: Meiosis I (Prophase I, Metaphase I, Anaphase I, Telophase I) + Meiosis II

  final List<String> _mitosisPhases = [
    'interphase', 'prophase', 'metaphase', 'anaphase', 'telophase', 'cytokinesis'
  ];

  final List<String> _meiosisPhases = [
    'interphase', 'prophase-i', 'metaphase-i', 'anaphase-i', 'telophase-i',
    'prophase-ii', 'metaphase-ii', 'anaphase-ii', 'telophase-ii', 'cytokinesis'
  ];

  List<String> get _phases => _divisionType == 'mitosis' ? _mitosisPhases : _meiosisPhases;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updatePhase);
  }

  void _updatePhase() {
    if (!_isRunning) return;

    setState(() {
      _phase += 0.005 * _animationSpeed;

      if (_phase >= 1.0) {
        _phase = 0.0;
        _currentPhase++;

        if (_currentPhase >= _phases.length) {
          _currentPhase = 0;
          _isRunning = false;
          _controller.stop();
        }
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

  void _nextPhase() {
    HapticFeedback.lightImpact();
    setState(() {
      _phase = 0.0;
      _currentPhase = (_currentPhase + 1) % _phases.length;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _controller.stop();
      _phase = 0.0;
      _currentPhase = 0;
    });
  }

  String _getPhaseName(String phase, bool isKorean) {
    final names = {
      'interphase': isKorean ? '간기' : 'Interphase',
      'prophase': isKorean ? '전기' : 'Prophase',
      'metaphase': isKorean ? '중기' : 'Metaphase',
      'anaphase': isKorean ? '후기' : 'Anaphase',
      'telophase': isKorean ? '말기' : 'Telophase',
      'cytokinesis': isKorean ? '세포질 분열' : 'Cytokinesis',
      'prophase-i': isKorean ? '전기 I' : 'Prophase I',
      'metaphase-i': isKorean ? '중기 I' : 'Metaphase I',
      'anaphase-i': isKorean ? '후기 I' : 'Anaphase I',
      'telophase-i': isKorean ? '말기 I' : 'Telophase I',
      'prophase-ii': isKorean ? '전기 II' : 'Prophase II',
      'metaphase-ii': isKorean ? '중기 II' : 'Metaphase II',
      'anaphase-ii': isKorean ? '후기 II' : 'Anaphase II',
      'telophase-ii': isKorean ? '말기 II' : 'Telophase II',
    };
    return names[phase] ?? phase;
  }

  String _getPhaseDescription(String phase, bool isKorean) {
    final descriptions = {
      'interphase': isKorean ? 'DNA 복제, 세포 성장' : 'DNA replication, cell growth',
      'prophase': isKorean ? '염색체 응축, 방추사 형성' : 'Chromosome condensation, spindle formation',
      'metaphase': isKorean ? '염색체가 적도판에 배열' : 'Chromosomes align at metaphase plate',
      'anaphase': isKorean ? '자매 염색분체 분리' : 'Sister chromatids separate',
      'telophase': isKorean ? '핵막 재형성, 염색체 이완' : 'Nuclear envelope reforms, chromosomes decondense',
      'cytokinesis': isKorean ? '세포질 분열' : 'Cytoplasm divides',
      'prophase-i': isKorean ? '상동 염색체 짝짓기, 교차' : 'Homologous pairing, crossing over',
      'metaphase-i': isKorean ? '2가 염색체가 적도판에 배열' : 'Bivalents align at metaphase plate',
      'anaphase-i': isKorean ? '상동 염색체 분리' : 'Homologous chromosomes separate',
      'telophase-i': isKorean ? '반수체 세포 형성' : 'Haploid cells form',
      'prophase-ii': isKorean ? '제2분열 시작' : 'Second division begins',
      'metaphase-ii': isKorean ? '염색체가 적도판에 배열' : 'Chromosomes align',
      'anaphase-ii': isKorean ? '자매 염색분체 분리' : 'Sister chromatids separate',
      'telophase-ii': isKorean ? '4개의 반수체 세포' : 'Four haploid cells',
    };
    return descriptions[phase] ?? '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);
    final currentPhaseName = _phases[_currentPhase];

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
              isKorean ? '세포 분열' : 'Cell Division',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '생물학' : 'Biology',
          title: isKorean ? '세포 분열' : 'Cell Division',
          formula: _divisionType == 'mitosis' ? '2n -> 2n (2 cells)' : '2n -> n (4 cells)',
          formulaDescription: isKorean
              ? _divisionType == 'mitosis'
                  ? '유사분열: 체세포 분열, 동일한 유전 정보를 가진 2개의 딸세포 생성'
                  : '감수분열: 생식세포 분열, 유전적 다양성을 가진 4개의 반수체 생성'
              : _divisionType == 'mitosis'
                  ? 'Mitosis: Somatic cell division, produces 2 identical daughter cells'
                  : 'Meiosis: Gamete formation, produces 4 genetically diverse haploid cells',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CellDivisionPainter(
                divisionType: _divisionType,
                currentPhase: currentPhaseName,
                phase: _phase,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current phase info
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getPhaseName(currentPhaseName, isKorean),
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_currentPhase + 1}/${_phases.length}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPhaseDescription(currentPhaseName, isKorean),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    // Phase progress
                    LinearProgressIndicator(
                      value: _phase,
                      backgroundColor: AppColors.cardBorder,
                      valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Division type selection
              PresetGroup(
                label: isKorean ? '분열 유형' : 'Division Type',
                presets: [
                  PresetButton(
                    label: isKorean ? '유사분열' : 'Mitosis',
                    isSelected: _divisionType == 'mitosis',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _divisionType = 'mitosis';
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '감수분열' : 'Meiosis',
                    isSelected: _divisionType == 'meiosis',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _divisionType = 'meiosis';
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Speed control
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '애니메이션 속도' : 'Animation Speed',
                  value: _animationSpeed,
                  min: 0.2,
                  max: 3.0,
                  defaultValue: 1.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)}x',
                  onChanged: (v) => setState(() => _animationSpeed = v),
                ),
              ),

              // Phase indicators
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_phases.length, (index) {
                  final isActive = index == _currentPhase;
                  final isCompleted = index < _currentPhase;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.accent.withValues(alpha: 0.2)
                          : isCompleted
                              ? Colors.green.withValues(alpha: 0.2)
                              : AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isActive ? AppColors.accent : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      _getPhaseName(_phases[index], isKorean),
                      style: TextStyle(
                        color: isActive
                            ? AppColors.accent
                            : isCompleted
                                ? Colors.green
                                : AppColors.muted,
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning
                    ? (isKorean ? '일시정지' : 'Pause')
                    : (isKorean ? '재생' : 'Play'),
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleRunning,
              ),
              SimButton(
                label: isKorean ? '다음' : 'Next',
                icon: Icons.skip_next,
                onPressed: _nextPhase,
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

class _CellDivisionPainter extends CustomPainter {
  final String divisionType;
  final String currentPhase;
  final double phase;
  final bool isKorean;

  _CellDivisionPainter({
    required this.divisionType,
    required this.currentPhase,
    required this.phase,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final cellRadius = math.min(size.width, size.height) * 0.25;

    // Draw based on current phase
    switch (currentPhase) {
      case 'interphase':
        _drawInterphase(canvas, centerX, centerY, cellRadius);
        break;
      case 'prophase':
      case 'prophase-i':
      case 'prophase-ii':
        _drawProphase(canvas, centerX, centerY, cellRadius, currentPhase == 'prophase-i');
        break;
      case 'metaphase':
      case 'metaphase-i':
      case 'metaphase-ii':
        _drawMetaphase(canvas, centerX, centerY, cellRadius, currentPhase.contains('-i'));
        break;
      case 'anaphase':
      case 'anaphase-i':
      case 'anaphase-ii':
        _drawAnaphase(canvas, centerX, centerY, cellRadius, phase, currentPhase.contains('-i'));
        break;
      case 'telophase':
      case 'telophase-i':
      case 'telophase-ii':
        _drawTelophase(canvas, centerX, centerY, cellRadius, phase);
        break;
      case 'cytokinesis':
        _drawCytokinesis(canvas, centerX, centerY, cellRadius, phase, divisionType == 'meiosis');
        break;
    }

    // Phase label
    _drawText(canvas, currentPhase.toUpperCase().replaceAll('-', ' '),
        Offset(10, 10), AppColors.accent, 14, fontWeight: FontWeight.bold);
  }

  void _drawInterphase(Canvas canvas, double cx, double cy, double radius) {
    // Cell membrane
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = Colors.lightBlue.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Nucleus
    canvas.drawCircle(
      Offset(cx, cy),
      radius * 0.5,
      Paint()
        ..color = Colors.purple.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      radius * 0.5,
      Paint()
        ..color = Colors.purple
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Chromatin (diffuse DNA)
    final random = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final r = random.nextDouble() * radius * 0.4;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = Colors.red.withValues(alpha: 0.5),
      );
    }

    // Centrosomes
    canvas.drawCircle(Offset(cx - radius * 0.7, cy), 5, Paint()..color = Colors.green);
    canvas.drawCircle(Offset(cx + radius * 0.7, cy), 5, Paint()..color = Colors.green);
  }

  void _drawProphase(Canvas canvas, double cx, double cy, double radius, bool isMeiosis) {
    // Cell membrane
    canvas.drawCircle(Offset(cx, cy), radius, Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(cx, cy), radius, Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);

    // Condensing chromosomes
    final chromosomes = isMeiosis ? 4 : 4; // pairs
    for (int i = 0; i < chromosomes; i++) {
      final angle = (i / chromosomes) * 2 * math.pi + math.pi / 4;
      final r = radius * 0.3;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);

      // X-shaped chromosome
      _drawChromosome(canvas, x, y, 15, Colors.red);
      if (isMeiosis) {
        // Homologous pair nearby
        _drawChromosome(canvas, x + 10, y + 5, 15, Colors.blue);
      }
    }

    // Spindle fibers forming
    final spindlePaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(cx - radius * 0.8, cy), Offset(cx, cy), spindlePaint);
    canvas.drawLine(Offset(cx + radius * 0.8, cy), Offset(cx, cy), spindlePaint);

    // Centrosomes at poles
    canvas.drawCircle(Offset(cx - radius * 0.8, cy), 6, Paint()..color = Colors.green);
    canvas.drawCircle(Offset(cx + radius * 0.8, cy), 6, Paint()..color = Colors.green);
  }

  void _drawMetaphase(Canvas canvas, double cx, double cy, double radius, bool isMeiosis) {
    // Cell membrane
    canvas.drawCircle(Offset(cx, cy), radius, Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(cx, cy), radius, Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);

    // Spindle fibers
    final spindlePaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final yOffset = (i - 3.5) * 15;
      canvas.drawLine(Offset(cx - radius * 0.8, cy), Offset(cx, cy + yOffset), spindlePaint);
      canvas.drawLine(Offset(cx + radius * 0.8, cy), Offset(cx, cy + yOffset), spindlePaint);
    }

    // Chromosomes aligned at metaphase plate
    for (int i = 0; i < 4; i++) {
      final y = cy + (i - 1.5) * 25;
      _drawChromosome(canvas, cx - 5, y, 12, Colors.red);
      if (isMeiosis) {
        _drawChromosome(canvas, cx + 5, y, 12, Colors.blue);
      }
    }

    // Centrosomes
    canvas.drawCircle(Offset(cx - radius * 0.8, cy), 6, Paint()..color = Colors.green);
    canvas.drawCircle(Offset(cx + radius * 0.8, cy), 6, Paint()..color = Colors.green);

    // Metaphase plate line
    canvas.drawLine(
      Offset(cx, cy - radius * 0.6),
      Offset(cx, cy + radius * 0.6),
      Paint()
        ..color = Colors.orange.withValues(alpha: 0.3)
        ..strokeWidth = 2,
    );
  }

  void _drawAnaphase(Canvas canvas, double cx, double cy, double radius, double progress, bool isMeiosis) {
    // Cell membrane (slightly elongated)
    final stretch = 1.0 + progress * 0.3;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: radius * 2 * stretch, height: radius * 2 / stretch),
      Paint()..color = Colors.lightBlue.withValues(alpha: 0.3),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: radius * 2 * stretch, height: radius * 2 / stretch),
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Chromosomes moving to poles
    final separation = progress * radius * 0.5;

    for (int i = 0; i < 4; i++) {
      final y = cy + (i - 1.5) * 20;

      // Left-moving chromosomes
      _drawChromosome(canvas, cx - separation - 10, y, 10, Colors.red, isHalf: !isMeiosis);

      // Right-moving chromosomes
      _drawChromosome(canvas, cx + separation + 10, y, 10, isMeiosis ? Colors.blue : Colors.red, isHalf: !isMeiosis);
    }

    // Spindle fibers
    final spindlePaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = cy + (i - 1.5) * 20;
      canvas.drawLine(Offset(cx - radius * stretch * 0.8, cy), Offset(cx - separation - 10, y), spindlePaint);
      canvas.drawLine(Offset(cx + radius * stretch * 0.8, cy), Offset(cx + separation + 10, y), spindlePaint);
    }

    // Centrosomes
    canvas.drawCircle(Offset(cx - radius * stretch * 0.8, cy), 6, Paint()..color = Colors.green);
    canvas.drawCircle(Offset(cx + radius * stretch * 0.8, cy), 6, Paint()..color = Colors.green);
  }

  void _drawTelophase(Canvas canvas, double cx, double cy, double radius, double progress) {
    // Two forming cells
    final separation = radius * 0.6;

    // Left cell
    canvas.drawCircle(Offset(cx - separation, cy), radius * 0.7, Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(cx - separation, cy), radius * 0.7, Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);

    // Left nucleus reforming
    canvas.drawCircle(Offset(cx - separation, cy), radius * 0.3 * progress, Paint()
      ..color = Colors.purple.withValues(alpha: 0.3 * progress));

    // Right cell
    canvas.drawCircle(Offset(cx + separation, cy), radius * 0.7, Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(cx + separation, cy), radius * 0.7, Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);

    // Right nucleus reforming
    canvas.drawCircle(Offset(cx + separation, cy), radius * 0.3 * progress, Paint()
      ..color = Colors.purple.withValues(alpha: 0.3 * progress));

    // Decondensing chromosomes
    for (int i = 0; i < 4; i++) {
      final y = cy + (i - 1.5) * 15;
      _drawChromosome(canvas, cx - separation, y, 8 * (1 - progress * 0.5), Colors.red);
      _drawChromosome(canvas, cx + separation, y, 8 * (1 - progress * 0.5), Colors.red);
    }
  }

  void _drawCytokinesis(Canvas canvas, double cx, double cy, double radius, double progress, bool isMeiosis) {
    final separation = radius * (0.6 + progress * 0.4);

    if (isMeiosis) {
      // Four cells for meiosis
      final positions = [
        Offset(cx - separation, cy - radius * 0.4),
        Offset(cx + separation, cy - radius * 0.4),
        Offset(cx - separation, cy + radius * 0.4),
        Offset(cx + separation, cy + radius * 0.4),
      ];

      for (final pos in positions) {
        canvas.drawCircle(pos, radius * 0.4, Paint()
          ..color = Colors.lightBlue.withValues(alpha: 0.3));
        canvas.drawCircle(pos, radius * 0.4, Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
        canvas.drawCircle(pos, radius * 0.15, Paint()
          ..color = Colors.purple.withValues(alpha: 0.3));
      }
    } else {
      // Two cells for mitosis
      // Left cell
      canvas.drawCircle(Offset(cx - separation, cy), radius * 0.6, Paint()
        ..color = Colors.lightBlue.withValues(alpha: 0.3));
      canvas.drawCircle(Offset(cx - separation, cy), radius * 0.6, Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
      canvas.drawCircle(Offset(cx - separation, cy), radius * 0.25, Paint()
        ..color = Colors.purple.withValues(alpha: 0.3));

      // Right cell
      canvas.drawCircle(Offset(cx + separation, cy), radius * 0.6, Paint()
        ..color = Colors.lightBlue.withValues(alpha: 0.3));
      canvas.drawCircle(Offset(cx + separation, cy), radius * 0.6, Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
      canvas.drawCircle(Offset(cx + separation, cy), radius * 0.25, Paint()
        ..color = Colors.purple.withValues(alpha: 0.3));
    }
  }

  void _drawChromosome(Canvas canvas, double cx, double cy, double size, Color color, {bool isHalf = false}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (isHalf) {
      // Single chromatid (after separation)
      canvas.drawLine(
        Offset(cx - size * 0.3, cy - size * 0.5),
        Offset(cx + size * 0.3, cy + size * 0.5),
        paint,
      );
    } else {
      // X-shaped chromosome (sister chromatids)
      canvas.drawLine(
        Offset(cx - size * 0.5, cy - size * 0.5),
        Offset(cx + size * 0.5, cy + size * 0.5),
        paint,
      );
      canvas.drawLine(
        Offset(cx + size * 0.5, cy - size * 0.5),
        Offset(cx - size * 0.5, cy + size * 0.5),
        paint,
      );

      // Centromere
      canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = color);
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
  bool shouldRepaint(covariant _CellDivisionPainter oldDelegate) => true;
}
