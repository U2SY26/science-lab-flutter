import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Pauli Exclusion Principle Simulation
/// 파울리 배타 원리 시뮬레이션
class PauliExclusionScreen extends StatefulWidget {
  const PauliExclusionScreen({super.key});

  @override
  State<PauliExclusionScreen> createState() => _PauliExclusionScreenState();
}

class _PauliExclusionScreenState extends State<PauliExclusionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  static const int _defaultElectronCount = 6;

  int electronCount = _defaultElectronCount;
  bool isRunning = true;
  int viewMode = 0; // 0: energy levels, 1: atomic orbitals, 2: fermi gas

  double time = 0;
  bool isKorean = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    _controller.repeat();
  }

  void _updatePhysics() {
    if (!isRunning) return;
    setState(() {
      time += 0.02;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      electronCount = _defaultElectronCount;
    });
  }

  void _addElectron() {
    if (electronCount < 20) {
      HapticFeedback.selectionClick();
      setState(() => electronCount++);
    }
  }

  void _removeElectron() {
    if (electronCount > 1) {
      HapticFeedback.selectionClick();
      setState(() => electronCount--);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _electronConfig {
    if (electronCount <= 2) return '1s${_superscript(electronCount)}';
    if (electronCount <= 10) {
      return '1s² 2s${_superscript(math.min(2, electronCount - 2))}${electronCount > 4 ? " 2p${_superscript(electronCount - 4)}" : ""}';
    }
    return '1s² 2s² 2p⁶ 3s${_superscript(math.min(2, electronCount - 10))}${electronCount > 12 ? " 3p${_superscript(electronCount - 12)}" : ""}';
  }

  String _superscript(int n) {
    const superscripts = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹'];
    if (n < 10) return superscripts[n];
    return superscripts[n ~/ 10] + superscripts[n % 10];
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
              isKorean ? '양자역학 시뮬레이션' : 'QUANTUM MECHANICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '파울리 배타 원리' : 'Pauli Exclusion Principle',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
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
          category: isKorean ? '양자역학 시뮬레이션' : 'QUANTUM MECHANICS',
          title: isKorean ? '파울리 배타 원리' : 'Pauli Exclusion Principle',
          formula: 'ψ(1,2) = -ψ(2,1)',
          formulaDescription: isKorean
              ? '두 개의 동일한 페르미온(전자 등)은 같은 양자 상태를 공유할 수 없습니다. '
                  '각 오비탈에는 스핀이 반대인 전자 2개만 들어갈 수 있습니다.'
              : 'No two identical fermions (like electrons) can occupy the same quantum state. '
                  'Each orbital can hold at most 2 electrons with opposite spins.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: PauliExclusionPainter(
                time: time,
                electronCount: electronCount,
                viewMode: viewMode,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SimSegment<int>(
                label: isKorean ? '표시 모드' : 'View Mode',
                options: {
                  0: isKorean ? '에너지 준위' : 'Energy Levels',
                  1: isKorean ? '원자 오비탈' : 'Orbitals',
                  2: isKorean ? '페르미 기체' : 'Fermi Gas',
                },
                selected: viewMode,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => viewMode = v);
                },
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '전자 수' : 'Number of Electrons',
                  value: electronCount.toDouble(),
                  min: 1,
                  max: 20,
                  defaultValue: _defaultElectronCount.toDouble(),
                  formatValue: (v) => '${v.toInt()} e⁻',
                  onChanged: (v) => setState(() => electronCount = v.toInt()),
                ),
                advancedControls: const [],
              ),
              const SizedBox(height: 12),
              _PhysicsInfo(
                electronCount: electronCount,
                electronConfig: _electronConfig,
                isKorean: isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning
                    ? (isKorean ? '정지' : 'Pause')
                    : (isKorean ? '재생' : 'Play'),
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => isRunning = !isRunning);
                },
              ),
              SimButton(
                label: '+e⁻',
                icon: Icons.add,
                onPressed: _addElectron,
              ),
              SimButton(
                label: '-e⁻',
                icon: Icons.remove,
                onPressed: _removeElectron,
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

class _PhysicsInfo extends StatelessWidget {
  final int electronCount;
  final String electronConfig;
  final bool isKorean;

  const _PhysicsInfo({
    required this.electronCount,
    required this.electronConfig,
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
      child: Row(
        children: [
          _InfoItem(
            label: isKorean ? '전자 수' : 'Electrons',
            value: '$electronCount',
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(
                  isKorean ? '전자 배치' : 'Configuration',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  electronConfig,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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

  const _InfoItem({required this.label, required this.value});

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
            style: const TextStyle(
              color: AppColors.accent,
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

class PauliExclusionPainter extends CustomPainter {
  final double time;
  final int electronCount;
  final int viewMode;

  PauliExclusionPainter({
    required this.time,
    required this.electronCount,
    required this.viewMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    switch (viewMode) {
      case 0:
        _drawEnergyLevels(canvas, size);
        break;
      case 1:
        _drawAtomicOrbitals(canvas, size);
        break;
      case 2:
        _drawFermiGas(canvas, size);
        break;
    }

    _drawLabels(canvas, size);
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

  void _drawEnergyLevels(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bottomY = size.height * 0.85;
    final topY = size.height * 0.1;

    // Define energy levels: (name, capacity, energy level)
    final levels = [
      ('1s', 2, 0.9),
      ('2s', 2, 0.7),
      ('2p', 6, 0.65),
      ('3s', 2, 0.5),
      ('3p', 6, 0.45),
      ('3d', 10, 0.35),
    ];

    int electronsPlaced = 0;
    final totalHeight = bottomY - topY;

    for (final level in levels) {
      if (electronsPlaced >= electronCount) break;

      final levelName = level.$1;
      final capacity = level.$2;
      final energyRatio = level.$3;

      final levelY = topY + (1 - energyRatio) * totalHeight;
      final electronsInLevel = math.min(capacity, electronCount - electronsPlaced);

      // Draw level line
      final levelWidth = capacity * 25.0 + 20;
      canvas.drawLine(
        Offset(centerX - levelWidth / 2, levelY),
        Offset(centerX + levelWidth / 2, levelY),
        Paint()
          ..color = AppColors.muted.withValues(alpha: 0.5)
          ..strokeWidth = 2,
      );

      // Draw electrons as pairs with opposite spins
      final orbitalCount = capacity ~/ 2;
      final orbitalSpacing = levelWidth / (orbitalCount + 1);

      for (int orbital = 0; orbital < orbitalCount; orbital++) {
        final orbitalX = centerX - levelWidth / 2 + (orbital + 1) * orbitalSpacing;
        final electronsInOrbital = math.min(2, electronsInLevel - orbital * 2);

        if (electronsInOrbital > 0) {
          // First electron (spin up)
          _drawElectron(canvas, orbitalX - 8, levelY - 15, true, time);
        }
        if (electronsInOrbital > 1) {
          // Second electron (spin down)
          _drawElectron(canvas, orbitalX + 8, levelY - 15, false, time);
        }
      }

      // Level label
      final textPainter = TextPainter(
        text: TextSpan(
          text: levelName,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerX + levelWidth / 2 + 10, levelY - 7));

      electronsPlaced += electronsInLevel;
    }

    // Energy axis
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(50, topY),
      Offset(50, bottomY),
      axisPaint,
    );

    // Arrow
    canvas.drawLine(Offset(50, topY), Offset(45, topY + 10), axisPaint);
    canvas.drawLine(Offset(50, topY), Offset(55, topY + 10), axisPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'E',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(45, topY - 20));
  }

  void _drawElectron(Canvas canvas, double x, double y, bool spinUp, double time) {
    // Electron glow
    canvas.drawCircle(
      Offset(x, y),
      12,
      Paint()..color = const Color(0xFF63B3ED).withValues(alpha: 0.3),
    );

    // Electron
    canvas.drawCircle(
      Offset(x, y),
      8,
      Paint()..color = const Color(0xFF63B3ED),
    );

    // Spin arrow
    final arrowPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (spinUp) {
      canvas.drawLine(Offset(x, y + 4), Offset(x, y - 4), arrowPaint);
      canvas.drawLine(Offset(x, y - 4), Offset(x - 3, y - 1), arrowPaint);
      canvas.drawLine(Offset(x, y - 4), Offset(x + 3, y - 1), arrowPaint);
    } else {
      canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), arrowPaint);
      canvas.drawLine(Offset(x, y + 4), Offset(x - 3, y + 1), arrowPaint);
      canvas.drawLine(Offset(x, y + 4), Offset(x + 3, y + 1), arrowPaint);
    }
  }

  void _drawAtomicOrbitals(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.45;

    // Draw nucleus
    canvas.drawCircle(
      Offset(centerX, centerY),
      12,
      Paint()..color = const Color(0xFFFC8181),
    );

    // Calculate electron distribution
    int remaining = electronCount;

    // 1s orbital (2 electrons)
    if (remaining > 0) {
      final count = math.min(2, remaining);
      _drawOrbitalShell(canvas, centerX, centerY, 35, count, 2, time);
      remaining -= count;
    }

    // 2s orbital (2 electrons)
    if (remaining > 0) {
      final count = math.min(2, remaining);
      _drawOrbitalShell(canvas, centerX, centerY, 60, count, 2, time + 0.5);
      remaining -= count;
    }

    // 2p orbital (6 electrons)
    if (remaining > 0) {
      final count = math.min(6, remaining);
      _drawOrbitalShell(canvas, centerX, centerY, 85, count, 6, time + 1.0);
      remaining -= count;
    }

    // 3s orbital (2 electrons)
    if (remaining > 0) {
      final count = math.min(2, remaining);
      _drawOrbitalShell(canvas, centerX, centerY, 110, count, 2, time + 1.5);
      remaining -= count;
    }

    // 3p orbital (6 electrons)
    if (remaining > 0) {
      final count = math.min(6, remaining);
      _drawOrbitalShell(canvas, centerX, centerY, 135, count, 6, time + 2.0);
      remaining -= count;
    }
  }

  void _drawOrbitalShell(Canvas canvas, double cx, double cy, double radius, int electrons, int maxElectrons, double timeOffset) {
    // Draw shell outline
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Draw electrons on the shell
    for (int i = 0; i < electrons; i++) {
      final angle = (i / maxElectrons) * 2 * math.pi + timeOffset;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);

      // Electron
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = const Color(0xFF63B3ED),
      );
      canvas.drawCircle(
        Offset(x, y),
        10,
        Paint()..color = const Color(0xFF63B3ED).withValues(alpha: 0.3),
      );
    }
  }

  void _drawFermiGas(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height * 0.5;
    final boxWidth = 200.0;
    final boxHeight = 150.0;

    // Draw box
    canvas.drawRect(
      Rect.fromCenter(center: Offset(centerX, centerY), width: boxWidth, height: boxHeight),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Fermi energy level
    final fermiY = centerY + boxHeight / 2 - (electronCount / 20) * boxHeight;
    canvas.drawLine(
      Offset(centerX - boxWidth / 2 - 10, fermiY),
      Offset(centerX + boxWidth / 2 + 10, fermiY),
      Paint()
        ..color = const Color(0xFFED8936)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Fill below Fermi level
    canvas.drawRect(
      Rect.fromLTRB(
        centerX - boxWidth / 2,
        fermiY,
        centerX + boxWidth / 2,
        centerY + boxHeight / 2,
      ),
      Paint()..color = const Color(0xFF63B3ED).withValues(alpha: 0.2),
    );

    // Draw electrons below Fermi level
    final random = math.Random(42);
    for (int i = 0; i < electronCount * 3; i++) {
      final x = centerX - boxWidth / 2 + random.nextDouble() * boxWidth;
      final y = fermiY + random.nextDouble() * (centerY + boxHeight / 2 - fermiY);

      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = const Color(0xFF63B3ED).withValues(alpha: 0.7),
      );
    }

    // Fermi energy label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'EF',
        style: TextStyle(
          color: const Color(0xFFED8936),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + boxWidth / 2 + 15, fermiY - 7));
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Main principle text
    textPainter.text = TextSpan(
      text: 'No two fermions can share the same quantum state',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, size.height * 0.92));

    if (viewMode == 0) {
      textPainter.text = TextSpan(
        text: '↑↓ = opposite spins',
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - textPainter.width - 20, size.height * 0.08));
    }
  }

  @override
  bool shouldRepaint(covariant PauliExclusionPainter oldDelegate) =>
      time != oldDelegate.time ||
      electronCount != oldDelegate.electronCount ||
      viewMode != oldDelegate.viewMode;
}
