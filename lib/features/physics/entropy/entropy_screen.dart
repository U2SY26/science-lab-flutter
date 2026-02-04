import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Entropy simulation: S = kB ln W
class EntropyScreen extends StatefulWidget {
  const EntropyScreen({super.key});

  @override
  State<EntropyScreen> createState() => _EntropyScreenState();
}

class _EntropyScreenState extends State<EntropyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final math.Random _random = math.Random();

  // Parameters
  int numParticles = 20;
  int numCells = 4; // Grid cells
  List<int> particlePositions = [];
  double time = 0;

  bool isRunning = false;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _initParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    _controller.repeat();
  }

  void _initParticles() {
    // Start with all particles in one cell (low entropy)
    particlePositions = List.generate(numParticles, (_) => 0);
  }

  void _updatePhysics() {
    if (!isRunning) return;

    setState(() {
      time += 0.016;

      // Random walk - each particle has a chance to move
      for (int i = 0; i < particlePositions.length; i++) {
        if (_random.nextDouble() < 0.1) {
          // Move to adjacent cell
          final currentCell = particlePositions[i];
          final gridSize = math.sqrt(numCells).toInt();
          final row = currentCell ~/ gridSize;
          final col = currentCell % gridSize;

          final moves = <int>[];
          if (row > 0) moves.add(currentCell - gridSize);
          if (row < gridSize - 1) moves.add(currentCell + gridSize);
          if (col > 0) moves.add(currentCell - 1);
          if (col < gridSize - 1) moves.add(currentCell + 1);

          if (moves.isNotEmpty) {
            particlePositions[i] = moves[_random.nextInt(moves.length)];
          }
        }
      }
    });
  }

  // Calculate number of microstates W
  int get numMicrostates {
    // W = N! / (n1! * n2! * ... * nk!)
    final counts = List.filled(numCells, 0);
    for (var pos in particlePositions) {
      counts[pos]++;
    }

    // Simplified calculation (actual W can be very large)
    double logW = _logFactorial(numParticles);
    for (var count in counts) {
      logW -= _logFactorial(count);
    }
    return math.exp(logW).round().clamp(1, 1000000);
  }

  double _logFactorial(int n) {
    double result = 0;
    for (int i = 2; i <= n; i++) {
      result += math.log(i);
    }
    return result;
  }

  double get entropy {
    // S = kB * ln(W)
    const kB = 1.38e-23;
    return kB * math.log(numMicrostates.toDouble()) * 1e23; // Scaled
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _initParticles();
      time = 0;
      isRunning = false;
    });
  }

  void _randomize() {
    HapticFeedback.selectionClick();
    setState(() {
      particlePositions = List.generate(
        numParticles,
        (_) => _random.nextInt(numCells),
      );
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
              isKorean ? '열역학' : 'THERMODYNAMICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '엔트로피' : 'Entropy',
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
          title: isKorean ? '엔트로피' : 'Entropy',
          formula: 'S = kB ln W',
          formulaDescription: isKorean
              ? '엔트로피(S)는 시스템의 무질서도를 나타냅니다. W는 가능한 미시상태의 수입니다.'
              : 'Entropy (S) measures disorder. W is the number of possible microstates.',
          simulation: CustomPaint(
            painter: _EntropyPainter(
              particlePositions: particlePositions,
              numCells: numCells,
              numMicrostates: numMicrostates,
              entropy: entropy,
              isKorean: isKorean,
            ),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '입자 수 (N)' : 'Particles (N)',
                  value: numParticles.toDouble(),
                  min: 5,
                  max: 50,
                  defaultValue: 20,
                  formatValue: (v) => v.toInt().toString(),
                  onChanged: (v) => setState(() {
                    numParticles = v.toInt();
                    _initParticles();
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '영역 수' : 'Number of Cells',
                    value: numCells.toDouble(),
                    min: 4,
                    max: 16,
                    step: 1,
                    defaultValue: 4,
                    formatValue: (v) => '${v.toInt()} (${math.sqrt(v).toInt()}×${math.sqrt(v).toInt()})',
                    onChanged: (v) {
                      final val = v.toInt();
                      final sqrt = math.sqrt(val).toInt();
                      if (sqrt * sqrt == val) {
                        setState(() {
                          numCells = val;
                          _initParticles();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _EntropyDisplay(
                numMicrostates: numMicrostates,
                entropy: entropy,
                numParticles: numParticles,
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
                    : (isKorean ? '확산 시작' : 'Start Diffusion'),
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleSimulation,
              ),
              SimButton(
                label: isKorean ? '무작위' : 'Randomize',
                icon: Icons.shuffle,
                onPressed: _randomize,
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

class _EntropyDisplay extends StatelessWidget {
  final int numMicrostates;
  final double entropy;
  final int numParticles;
  final bool isKorean;

  const _EntropyDisplay({
    required this.numMicrostates,
    required this.entropy,
    required this.numParticles,
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
                label: isKorean ? '미시상태 수 (W)' : 'Microstates (W)',
                value: numMicrostates > 10000
                    ? '${(numMicrostates / 1000).toStringAsFixed(1)}k'
                    : numMicrostates.toString(),
                color: AppColors.accent,
              ),
              _InfoItem(
                label: isKorean ? '엔트로피 (S)' : 'Entropy (S)',
                value: entropy.toStringAsFixed(2),
                color: AppColors.accent2,
              ),
              _InfoItem(
                label: 'ln W',
                value: math.log(numMicrostates).toStringAsFixed(2),
                color: AppColors.ink,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'S = kB × ln($numMicrostates) = ${entropy.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
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

class _EntropyPainter extends CustomPainter {
  final List<int> particlePositions;
  final int numCells;
  final int numMicrostates;
  final double entropy;
  final bool isKorean;

  _EntropyPainter({
    required this.particlePositions,
    required this.numCells,
    required this.numMicrostates,
    required this.entropy,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    // Draw container grid
    final gridSize = math.sqrt(numCells).toInt();
    final containerSize = math.min(size.width * 0.5, size.height * 0.7);
    final cellSize = containerSize / gridSize;
    final startX = (size.width - containerSize) / 2 - 50;
    final startY = (size.height - containerSize) / 2;

    // Container background
    canvas.drawRect(
      Rect.fromLTWH(startX, startY, containerSize, containerSize),
      Paint()..color = AppColors.card.withValues(alpha: 0.5),
    );

    // Grid lines
    for (int i = 0; i <= gridSize; i++) {
      canvas.drawLine(
        Offset(startX + i * cellSize, startY),
        Offset(startX + i * cellSize, startY + containerSize),
        Paint()
          ..color = AppColors.cardBorder
          ..strokeWidth = 1,
      );
      canvas.drawLine(
        Offset(startX, startY + i * cellSize),
        Offset(startX + containerSize, startY + i * cellSize),
        Paint()
          ..color = AppColors.cardBorder
          ..strokeWidth = 1,
      );
    }

    // Count particles in each cell
    final cellCounts = List.filled(numCells, 0);
    for (var pos in particlePositions) {
      if (pos < numCells) cellCounts[pos]++;
    }

    // Draw cell labels and counts
    for (int i = 0; i < numCells; i++) {
      final row = i ~/ gridSize;
      final col = i % gridSize;
      final cellX = startX + col * cellSize + cellSize / 2;
      final cellY = startY + row * cellSize + cellSize / 2;

      // Cell color based on particle count
      final intensity = (cellCounts[i] / (particlePositions.length / 2)).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(startX + col * cellSize + 1, startY + row * cellSize + 1, cellSize - 2, cellSize - 2),
        Paint()..color = AppColors.accent.withValues(alpha: intensity * 0.3),
      );

      // Count label
      if (cellCounts[i] > 0) {
        _drawText(
          canvas,
          cellCounts[i].toString(),
          Offset(cellX - 5, cellY - 8),
          AppColors.ink,
          14,
        );
      }
    }

    // Draw particles
    final random = math.Random(42); // Fixed seed for consistent positions
    for (int i = 0; i < particlePositions.length; i++) {
      final cellIndex = particlePositions[i];
      if (cellIndex >= numCells) continue;

      final row = cellIndex ~/ gridSize;
      final col = cellIndex % gridSize;

      // Random position within cell
      final offsetX = random.nextDouble() * (cellSize - 20) + 10;
      final offsetY = random.nextDouble() * (cellSize - 20) + 10;

      final x = startX + col * cellSize + offsetX;
      final y = startY + row * cellSize + offsetY;

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = AppColors.accent2,
      );
    }

    // Entropy bar
    _drawEntropyBar(canvas, size, startX + containerSize + 30, startY);

    // Explanation
    _drawExplanation(canvas, size);
  }

  void _drawEntropyBar(Canvas canvas, Size size, double x, double y) {
    final barHeight = size.height * 0.5;
    final barWidth = 30.0;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(5),
      ),
      Paint()..color = AppColors.cardBorder,
    );

    // Fill based on entropy (normalized)
    final maxEntropy = math.log(math.pow(numCells, particlePositions.length).toDouble());
    final normalizedEntropy = (math.log(numMicrostates.toDouble()) / maxEntropy).clamp(0.0, 1.0);
    final fillHeight = barHeight * normalizedEntropy;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 3, y + barHeight - fillHeight + 3, barWidth - 6, fillHeight - 6),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.accent2,
    );

    // Labels
    _drawText(canvas, 'S', Offset(x + 10, y - 18), AppColors.ink, 12);
    _drawText(canvas, isKorean ? '높음' : 'High', Offset(x - 5, y - 5), AppColors.muted, 8);
    _drawText(canvas, isKorean ? '낮음' : 'Low', Offset(x - 5, y + barHeight + 5), AppColors.muted, 8);
  }

  void _drawExplanation(Canvas canvas, Size size) {
    final textY = size.height - 50;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20, textY - 10, size.width - 40, 45),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.card.withValues(alpha: 0.8),
    );

    final explanation = isKorean
        ? '입자가 균등하게 분포할수록 엔트로피가 높아집니다.\n자연은 엔트로피가 증가하는 방향으로 진행합니다.'
        : 'Entropy increases as particles spread out uniformly.\nNature tends toward higher entropy states.';

    _drawText(canvas, explanation, Offset(30, textY), AppColors.muted, 10);
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
  bool shouldRepaint(covariant _EntropyPainter oldDelegate) => true;
}
