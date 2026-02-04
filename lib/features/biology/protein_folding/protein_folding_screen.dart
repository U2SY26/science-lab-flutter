import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Protein Folding Simulation
class ProteinFoldingScreen extends ConsumerStatefulWidget {
  const ProteinFoldingScreen({super.key});

  @override
  ConsumerState<ProteinFoldingScreen> createState() => _ProteinFoldingScreenState();
}

class _ProteinFoldingScreenState extends ConsumerState<ProteinFoldingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  // Folding parameters
  double _temperature = 310; // Body temperature in K
  double _foldingProgress = 0.0;
  bool _isRunning = false;
  String _selectedProtein = 'alpha-helix';

  // Amino acid chain
  List<AminoAcid> _aminoAcids = [];
  double _energy = 100.0;
  double _minEnergy = 100.0;

  // Structure types
  final Map<String, List<String>> _proteinSequences = {
    'alpha-helix': ['A', 'L', 'E', 'K', 'A', 'L', 'E', 'K', 'A', 'L'],
    'beta-sheet': ['V', 'I', 'Y', 'V', 'I', 'Y', 'V', 'I', 'Y', 'V'],
    'random-coil': ['G', 'P', 'S', 'G', 'P', 'S', 'G', 'P', 'S', 'G'],
  };

  @override
  void initState() {
    super.initState();
    _initializeChain();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateFolding);
  }

  void _initializeChain() {
    final sequence = _proteinSequences[_selectedProtein]!;
    _aminoAcids = List.generate(sequence.length, (i) {
      return AminoAcid(
        type: sequence[i],
        position: Offset(50.0 + i * 30, 150),
        angle: 0,
      );
    });
    _energy = 100.0;
    _minEnergy = 100.0;
    _foldingProgress = 0.0;
  }

  void _updateFolding() {
    if (!_isRunning) return;

    setState(() {
      // Simulated annealing-like folding
      final kT = _temperature / 310; // Normalized temperature

      for (int i = 1; i < _aminoAcids.length; i++) {
        final aa = _aminoAcids[i];
        final prev = _aminoAcids[i - 1];

        // Calculate target position based on structure type
        Offset targetPos;
        double targetAngle;

        switch (_selectedProtein) {
          case 'alpha-helix':
            // Helical arrangement
            final helixAngle = i * 100 * math.pi / 180;
            final radius = 40.0;
            targetPos = Offset(
              150 + i * 15 + radius * math.cos(helixAngle),
              150 + radius * math.sin(helixAngle),
            );
            targetAngle = helixAngle;
            break;
          case 'beta-sheet':
            // Zigzag arrangement
            final row = i ~/ 5;
            final col = i % 5;
            final direction = row % 2 == 0 ? 1 : -1;
            targetPos = Offset(
              80 + col * 40 * direction + (row % 2 == 1 ? 160 : 0),
              100 + row * 50,
            );
            targetAngle = row % 2 == 0 ? 0 : math.pi;
            break;
          default:
            // Random coil - more random movement
            targetPos = Offset(
              prev.position.dx + 25 * math.cos(_random.nextDouble() * 2 * math.pi),
              prev.position.dy + 25 * math.sin(_random.nextDouble() * 2 * math.pi),
            ).clamp(const Offset(30, 30), const Offset(320, 270));
            targetAngle = _random.nextDouble() * 2 * math.pi;
        }

        // Gradual movement with temperature-dependent randomness
        final noise = kT * 5;
        final dx = (targetPos.dx - aa.position.dx) * 0.05 + (_random.nextDouble() - 0.5) * noise;
        final dy = (targetPos.dy - aa.position.dy) * 0.05 + (_random.nextDouble() - 0.5) * noise;
        final dAngle = (targetAngle - aa.angle) * 0.05;

        _aminoAcids[i] = AminoAcid(
          type: aa.type,
          position: Offset(
            (aa.position.dx + dx).clamp(30, 320),
            (aa.position.dy + dy).clamp(30, 270),
          ),
          angle: aa.angle + dAngle,
        );
      }

      // Calculate energy (simplified)
      _energy = _calculateEnergy();
      if (_energy < _minEnergy) {
        _minEnergy = _energy;
      }

      // Update folding progress
      _foldingProgress = (100 - _energy) / 100;
      _foldingProgress = _foldingProgress.clamp(0.0, 1.0);
    });
  }

  double _calculateEnergy() {
    double energy = 100.0;

    // Bond angles contribute to energy
    for (int i = 1; i < _aminoAcids.length - 1; i++) {
      final a = _aminoAcids[i - 1].position;
      final b = _aminoAcids[i].position;
      final c = _aminoAcids[i + 1].position;

      final angle = _calculateAngle(a, b, c);

      // Ideal angles depend on structure
      double idealAngle;
      switch (_selectedProtein) {
        case 'alpha-helix':
          idealAngle = 100 * math.pi / 180;
          break;
        case 'beta-sheet':
          idealAngle = 120 * math.pi / 180;
          break;
        default:
          idealAngle = math.pi;
      }

      energy -= (1 - (angle - idealAngle).abs() / math.pi) * 5;
    }

    // Hydrophobic interactions
    for (int i = 0; i < _aminoAcids.length; i++) {
      for (int j = i + 2; j < _aminoAcids.length; j++) {
        final dist = (_aminoAcids[i].position - _aminoAcids[j].position).distance;
        if (dist < 50 && _isHydrophobic(_aminoAcids[i].type) && _isHydrophobic(_aminoAcids[j].type)) {
          energy -= 5;
        }
      }
    }

    return energy.clamp(0, 100);
  }

  double _calculateAngle(Offset a, Offset b, Offset c) {
    final ba = a - b;
    final bc = c - b;
    final dot = ba.dx * bc.dx + ba.dy * bc.dy;
    final cross = ba.dx * bc.dy - ba.dy * bc.dx;
    return math.atan2(cross, dot).abs();
  }

  bool _isHydrophobic(String aa) {
    return ['A', 'V', 'I', 'L', 'M', 'F', 'Y', 'W'].contains(aa);
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
      _initializeChain();
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
              isKorean ? '단백질 접힘' : 'Protein Folding',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '생물학' : 'Biology',
          title: isKorean ? '단백질 접힘' : 'Protein Folding',
          formula: 'G = H - TS',
          formulaDescription: isKorean
              ? '단백질은 자유 에너지(G)를 최소화하는 방향으로 접힙니다. 엔탈피(H)와 엔트로피(S)의 균형이 중요합니다.'
              : 'Proteins fold to minimize free energy (G). The balance between enthalpy (H) and entropy (S) is crucial.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _ProteinFoldingPainter(
                aminoAcids: _aminoAcids,
                selectedProtein: _selectedProtein,
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
                          label: isKorean ? '접힘 진행' : 'Folding',
                          value: '${(_foldingProgress * 100).toStringAsFixed(1)}%',
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: isKorean ? '에너지' : 'Energy',
                          value: _energy.toStringAsFixed(1),
                          color: Colors.orange,
                        ),
                        _InfoItem(
                          label: isKorean ? '최저 에너지' : 'Min Energy',
                          value: _minEnergy.toStringAsFixed(1),
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Structure selection
              PresetGroup(
                label: isKorean ? '2차 구조' : 'Secondary Structure',
                presets: [
                  PresetButton(
                    label: isKorean ? '알파 나선' : 'Alpha Helix',
                    isSelected: _selectedProtein == 'alpha-helix',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedProtein = 'alpha-helix';
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '베타 시트' : 'Beta Sheet',
                    isSelected: _selectedProtein == 'beta-sheet',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedProtein = 'beta-sheet';
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '무작위 코일' : 'Random Coil',
                    isSelected: _selectedProtein == 'random-coil',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedProtein = 'random-coil';
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '온도 (K)' : 'Temperature (K)',
                  value: _temperature,
                  min: 273,
                  max: 373,
                  defaultValue: 310,
                  formatValue: (v) => '${v.toInt()} K',
                  onChanged: (v) => setState(() => _temperature = v),
                ),
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

class AminoAcid {
  final String type;
  final Offset position;
  final double angle;

  AminoAcid({required this.type, required this.position, required this.angle});
}

extension OffsetClamp on Offset {
  Offset clamp(Offset min, Offset max) {
    return Offset(
      dx.clamp(min.dx, max.dx),
      dy.clamp(min.dy, max.dy),
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

class _ProteinFoldingPainter extends CustomPainter {
  final List<AminoAcid> aminoAcids;
  final String selectedProtein;
  final bool isKorean;

  _ProteinFoldingPainter({
    required this.aminoAcids,
    required this.selectedProtein,
    required this.isKorean,
  });

  Color _getAminoAcidColor(String type) {
    // Color by property
    if (['A', 'V', 'I', 'L', 'M', 'F', 'Y', 'W'].contains(type)) {
      return Colors.orange; // Hydrophobic
    } else if (['K', 'R', 'H'].contains(type)) {
      return Colors.blue; // Basic
    } else if (['D', 'E'].contains(type)) {
      return Colors.red; // Acidic
    } else if (['S', 'T', 'N', 'Q'].contains(type)) {
      return Colors.green; // Polar
    } else if (['C', 'G', 'P'].contains(type)) {
      return Colors.purple; // Special
    }
    return AppColors.muted;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (aminoAcids.isEmpty) return;

    // Draw backbone
    final backbonePaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final backbonePath = Path();
    backbonePath.moveTo(aminoAcids[0].position.dx, aminoAcids[0].position.dy);
    for (int i = 1; i < aminoAcids.length; i++) {
      backbonePath.lineTo(aminoAcids[i].position.dx, aminoAcids[i].position.dy);
    }
    canvas.drawPath(backbonePath, backbonePaint);

    // Draw hydrogen bonds for alpha helix
    if (selectedProtein == 'alpha-helix') {
      final hBondPaint = Paint()
        ..color = Colors.cyan.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < aminoAcids.length - 4; i++) {
        canvas.drawLine(
          aminoAcids[i].position,
          aminoAcids[i + 4].position,
          hBondPaint,
        );
      }
    }

    // Draw beta sheet hydrogen bonds
    if (selectedProtein == 'beta-sheet') {
      final hBondPaint = Paint()
        ..color = Colors.cyan.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < aminoAcids.length - 5; i++) {
        if (i % 5 < 4) {
          final j = (i ~/ 5 + 1) * 5 + (4 - i % 5);
          if (j < aminoAcids.length) {
            canvas.drawLine(
              aminoAcids[i].position,
              aminoAcids[j].position,
              hBondPaint,
            );
          }
        }
      }
    }

    // Draw amino acids
    for (int i = 0; i < aminoAcids.length; i++) {
      final aa = aminoAcids[i];
      final color = _getAminoAcidColor(aa.type);

      // Amino acid circle
      canvas.drawCircle(
        aa.position,
        12,
        Paint()..color = color,
      );

      // Border
      canvas.drawCircle(
        aa.position,
        12,
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Label
      _drawText(canvas, aa.type, Offset(aa.position.dx - 4, aa.position.dy - 6),
          Colors.white, 10, fontWeight: FontWeight.bold);

      // Index
      _drawText(canvas, '${i + 1}', Offset(aa.position.dx - 3, aa.position.dy + 14),
          AppColors.muted, 8);
    }

    // Legend
    _drawLegend(canvas, size);

    // Structure label
    String structureLabel;
    switch (selectedProtein) {
      case 'alpha-helix':
        structureLabel = isKorean ? '알파 나선 구조' : 'Alpha Helix Structure';
        break;
      case 'beta-sheet':
        structureLabel = isKorean ? '베타 시트 구조' : 'Beta Sheet Structure';
        break;
      default:
        structureLabel = isKorean ? '무작위 코일' : 'Random Coil';
    }
    _drawText(canvas, structureLabel, const Offset(10, 10), AppColors.accent, 12,
        fontWeight: FontWeight.bold);
  }

  void _drawLegend(Canvas canvas, Size size) {
    final legendItems = [
      (isKorean ? '소수성' : 'Hydrophobic', Colors.orange),
      (isKorean ? '염기성' : 'Basic', Colors.blue),
      (isKorean ? '산성' : 'Acidic', Colors.red),
      (isKorean ? '극성' : 'Polar', Colors.green),
    ];

    double x = 10;
    final y = size.height - 20;

    for (final item in legendItems) {
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = item.$2);
      _drawText(canvas, item.$1, Offset(x + 8, y - 5), AppColors.muted, 9);
      x += 70;
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
  bool shouldRepaint(covariant _ProteinFoldingPainter oldDelegate) => true;
}
