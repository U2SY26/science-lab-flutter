import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Ulam Spiral (Prime Spiral) Visualization
/// 울람 나선 (소수 나선) 시각화
class PrimeSpiralScreen extends StatefulWidget {
  const PrimeSpiralScreen({super.key});

  @override
  State<PrimeSpiralScreen> createState() => _PrimeSpiralScreenState();
}

class _PrimeSpiralScreenState extends State<PrimeSpiralScreen> {
  int gridSize = 101; // Odd number for center
  bool showNumbers = false;
  bool showDiagonals = true;
  int colorMode = 0; // 0: binary, 1: gradient by value, 2: twin primes
  bool isKorean = true;

  // Sieve of Eratosthenes
  late List<bool> _isPrime;
  late int _maxN;

  @override
  void initState() {
    super.initState();
    _generatePrimes();
  }

  void _generatePrimes() {
    _maxN = gridSize * gridSize;
    _isPrime = List.filled(_maxN + 1, true);
    _isPrime[0] = false;
    _isPrime[1] = false;

    for (int i = 2; i * i <= _maxN; i++) {
      if (_isPrime[i]) {
        for (int j = i * i; j <= _maxN; j += i) {
          _isPrime[j] = false;
        }
      }
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      gridSize = 101;
      showNumbers = false;
      colorMode = 0;
    });
    _generatePrimes();
  }

  int _countPrimes() {
    int count = 0;
    for (int i = 2; i <= _maxN; i++) {
      if (_isPrime[i]) count++;
    }
    return count;
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
              isKorean ? '수론' : 'NUMBER THEORY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '울람 나선' : 'Ulam Spiral',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => isKorean = !isKorean),
            tooltip: isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '수론' : 'NUMBER THEORY',
          title: isKorean ? '울람 나선 (소수 나선)' : 'Ulam Spiral (Prime Spiral)',
          formula: 'n → (x, y) spiral mapping',
          formulaDescription: isKorean
              ? '자연수를 나선 형태로 배열하면 소수들이 대각선 패턴을 형성합니다. 이 미스터리한 패턴은 아직 완전히 설명되지 않았습니다.'
              : 'When natural numbers are arranged in a spiral, primes form diagonal patterns. This mysterious pattern is still not fully explained.',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: PrimeSpiralPainter(
                gridSize: gridSize,
                isPrime: _isPrime,
                showNumbers: showNumbers,
                showDiagonals: showDiagonals,
                colorMode: colorMode,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    _InfoItem(
                      label: isKorean ? '격자 크기' : 'Grid Size',
                      value: '$gridSize × $gridSize',
                    ),
                    _InfoItem(
                      label: isKorean ? '총 숫자' : 'Total Numbers',
                      value: '${gridSize * gridSize}',
                    ),
                    _InfoItem(
                      label: isKorean ? '소수 개수' : 'Prime Count',
                      value: '${_countPrimes()}',
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Color mode selection
              PresetGroup(
                label: isKorean ? '색상 모드' : 'Color Mode',
                presets: [
                  PresetButton(
                    label: isKorean ? '이진' : 'Binary',
                    isSelected: colorMode == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => colorMode = 0);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '그라데이션' : 'Gradient',
                    isSelected: colorMode == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => colorMode = 1);
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '쌍둥이 소수' : 'Twin Primes',
                    isSelected: colorMode == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => colorMode = 2);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Grid size slider
              SimSlider(
                label: isKorean ? '격자 크기' : 'Grid Size',
                value: gridSize.toDouble(),
                min: 21,
                max: 201,
                step: 20,
                defaultValue: 101,
                formatValue: (v) => '${v.toInt()}',
                onChanged: (v) {
                  final newSize = (v.toInt() ~/ 2) * 2 + 1; // Ensure odd
                  setState(() {
                    gridSize = newSize;
                  });
                  _generatePrimes();
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: SimToggle(
                      label: isKorean ? '대각선 표시' : 'Show Diagonals',
                      value: showDiagonals,
                      onChanged: (v) => setState(() => showDiagonals = v),
                    ),
                  ),
                  if (gridSize <= 31)
                    Expanded(
                      child: SimToggle(
                        label: isKorean ? '숫자 표시' : 'Show Numbers',
                        value: showNumbers,
                        onChanged: (v) => setState(() => showNumbers = v),
                      ),
                    ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                isPrimary: true,
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
  final Color? color;

  const _InfoItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.ink,
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

class PrimeSpiralPainter extends CustomPainter {
  final int gridSize;
  final List<bool> isPrime;
  final bool showNumbers;
  final bool showDiagonals;
  final int colorMode;

  PrimeSpiralPainter({
    required this.gridSize,
    required this.isPrime,
    required this.showNumbers,
    required this.showDiagonals,
    required this.colorMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final cellSize = math.min(size.width, size.height) / gridSize;
    final offsetX = (size.width - gridSize * cellSize) / 2;
    final offsetY = (size.height - gridSize * cellSize) / 2;

    // Draw diagonal guidelines
    if (showDiagonals) {
      final diagPaint = Paint()
        ..color = Colors.purple.withValues(alpha: 0.1)
        ..strokeWidth = 1;

      // Main diagonals
      canvas.drawLine(
        Offset(offsetX, offsetY),
        Offset(offsetX + gridSize * cellSize, offsetY + gridSize * cellSize),
        diagPaint,
      );
      canvas.drawLine(
        Offset(offsetX + gridSize * cellSize, offsetY),
        Offset(offsetX, offsetY + gridSize * cellSize),
        diagPaint,
      );
    }

    // Generate spiral coordinates
    final coords = _generateSpiralCoords();
    final maxN = gridSize * gridSize;

    // Draw cells
    for (int n = 1; n <= maxN && n < isPrime.length; n++) {
      final coord = coords[n];
      if (coord == null) continue;

      final x = offsetX + coord.$1 * cellSize;
      final y = offsetY + coord.$2 * cellSize;

      if (isPrime[n]) {
        Color color;
        switch (colorMode) {
          case 1: // Gradient by value
            final hue = (n / maxN) * 270; // Purple to red
            color = HSVColor.fromAHSV(1, hue, 0.8, 0.9).toColor();
            break;
          case 2: // Twin primes
            final isTwin = (n > 2 && isPrime[n - 2]) || (n + 2 < isPrime.length && isPrime[n + 2]);
            color = isTwin ? Colors.red : AppColors.accent;
            break;
          default: // Binary
            color = AppColors.accent;
        }

        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          Paint()..color = color,
        );
      }

      // Draw numbers for small grids
      if (showNumbers && gridSize <= 31) {
        _drawText(
          canvas,
          '$n',
          Offset(x + cellSize / 2, y + cellSize / 2),
          isPrime[n] ? Colors.white : AppColors.muted.withValues(alpha: 0.5),
          fontSize: cellSize * 0.4,
        );
      }
    }

    // Draw center marker
    final centerX = offsetX + (gridSize ~/ 2) * cellSize + cellSize / 2;
    final centerY = offsetY + (gridSize ~/ 2) * cellSize + cellSize / 2;
    canvas.drawCircle(
      Offset(centerX, centerY),
      cellSize * 0.3,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Map<int, (int, int)> _generateSpiralCoords() {
    final coords = <int, (int, int)>{};
    final center = gridSize ~/ 2;

    int x = center, y = center;
    int n = 1;
    int direction = 0; // 0: right, 1: up, 2: left, 3: down
    int stepsInDirection = 1;
    int stepsTaken = 0;
    int directionChanges = 0;

    coords[n] = (x, y);

    final dx = [1, 0, -1, 0];
    final dy = [0, -1, 0, 1];

    while (n < gridSize * gridSize) {
      x += dx[direction];
      y += dy[direction];
      n++;
      stepsTaken++;

      if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
        coords[n] = (x, y);
      }

      if (stepsTaken == stepsInDirection) {
        stepsTaken = 0;
        direction = (direction + 1) % 4;
        directionChanges++;
        if (directionChanges % 2 == 0) {
          stepsInDirection++;
        }
      }
    }

    return coords;
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant PrimeSpiralPainter oldDelegate) =>
      gridSize != oldDelegate.gridSize ||
      showNumbers != oldDelegate.showNumbers ||
      showDiagonals != oldDelegate.showDiagonals ||
      colorMode != oldDelegate.colorMode;
}
