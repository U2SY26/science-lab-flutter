import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Quantum Gates Simulation
/// 양자 게이트 시뮬레이션 (Hadamard, CNOT, Pauli)
class QuantumGatesScreen extends StatefulWidget {
  const QuantumGatesScreen({super.key});

  @override
  State<QuantumGatesScreen> createState() => _QuantumGatesScreenState();
}

class _QuantumGatesScreenState extends State<QuantumGatesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Qubit state: |ψ⟩ = α|0⟩ + β|1⟩
  double alpha = 1.0;
  double betaReal = 0.0;
  double betaImag = 0.0;

  bool isRunning = true;
  int selectedGate = 0; // 0: H, 1: X, 2: Y, 3: Z, 4: S, 5: T

  double time = 0;
  bool isKorean = true;
  List<int> gateHistory = [];

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
      alpha = 1.0;
      betaReal = 0.0;
      betaImag = 0.0;
      gateHistory.clear();
    });
  }

  void _applyGate(int gateIndex) {
    HapticFeedback.selectionClick();

    setState(() {
      // Apply quantum gate transformation
      switch (gateIndex) {
        case 0: // Hadamard
          final newAlpha = (alpha + betaReal) / math.sqrt(2);
          final newBetaReal = (alpha - betaReal) / math.sqrt(2);
          final newBetaImag = -betaImag / math.sqrt(2);
          alpha = newAlpha;
          betaReal = newBetaReal;
          betaImag = newBetaImag;
          break;
        case 1: // Pauli-X (NOT)
          final temp = alpha;
          alpha = betaReal;
          betaReal = temp;
          // Imaginary part stays with beta
          break;
        case 2: // Pauli-Y
          final newAlpha = -betaImag;
          final newBetaReal = 0.0;
          final newBetaImag = alpha;
          alpha = newAlpha;
          betaReal = newBetaReal;
          betaImag = newBetaImag;
          break;
        case 3: // Pauli-Z
          betaReal = -betaReal;
          betaImag = -betaImag;
          break;
        case 4: // S gate (sqrt(Z))
          final tempReal = betaReal;
          betaReal = -betaImag;
          betaImag = tempReal;
          break;
        case 5: // T gate (π/8)
          final angle = math.pi / 4;
          final tempReal = betaReal * math.cos(angle) - betaImag * math.sin(angle);
          final tempImag = betaReal * math.sin(angle) + betaImag * math.cos(angle);
          betaReal = tempReal;
          betaImag = tempImag;
          break;
      }

      // Normalize
      final norm = math.sqrt(alpha * alpha + betaReal * betaReal + betaImag * betaImag);
      if (norm > 0) {
        alpha /= norm;
        betaReal /= norm;
        betaImag /= norm;
      }

      gateHistory.add(gateIndex);
      if (gateHistory.length > 8) {
        gateHistory.removeAt(0);
      }
    });
  }

  String get _gateNames {
    const names = ['H', 'X', 'Y', 'Z', 'S', 'T'];
    return gateHistory.map((i) => names[i]).join(' → ');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prob0 = alpha * alpha;
    final prob1 = betaReal * betaReal + betaImag * betaImag;

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
              isKorean ? '양자 게이트' : 'Quantum Gates',
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
          title: isKorean ? '양자 게이트' : 'Quantum Gates',
          formula: 'H = (1/√2)[1 1; 1 -1]',
          formulaDescription: isKorean
              ? '양자 게이트는 큐비트 상태를 변환합니다. H(아다마르)는 중첩을 생성하고, '
                  'X,Y,Z(파울리)는 회전을, S,T는 위상 게이트입니다.'
              : 'Quantum gates transform qubit states. H (Hadamard) creates superposition, '
                  'X,Y,Z (Pauli) perform rotations, S,T are phase gates.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: QuantumGatesPainter(
                time: time,
                alpha: alpha,
                betaReal: betaReal,
                betaImag: betaImag,
                selectedGate: selectedGate,
                gateHistory: gateHistory,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKorean ? '게이트 선택' : 'Select Gate',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _GateButton(label: 'H', index: 0, selected: selectedGate, onTap: () => _applyGate(0)),
                  _GateButton(label: 'X', index: 1, selected: selectedGate, onTap: () => _applyGate(1)),
                  _GateButton(label: 'Y', index: 2, selected: selectedGate, onTap: () => _applyGate(2)),
                  _GateButton(label: 'Z', index: 3, selected: selectedGate, onTap: () => _applyGate(3)),
                  _GateButton(label: 'S', index: 4, selected: selectedGate, onTap: () => _applyGate(4)),
                  _GateButton(label: 'T', index: 5, selected: selectedGate, onTap: () => _applyGate(5)),
                ],
              ),
              const SizedBox(height: 16),
              _PhysicsInfo(
                alpha: alpha,
                betaReal: betaReal,
                betaImag: betaImag,
                prob0: prob0,
                prob1: prob1,
                gateHistory: _gateNames,
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
                label: '|0⟩',
                icon: Icons.restart_alt,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateButton extends StatelessWidget {
  final String label;
  final int index;
  final int selected;
  final VoidCallback onTap;

  const _GateButton({
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.accent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _PhysicsInfo extends StatelessWidget {
  final double alpha;
  final double betaReal;
  final double betaImag;
  final double prob0;
  final double prob1;
  final String gateHistory;
  final bool isKorean;

  const _PhysicsInfo({
    required this.alpha,
    required this.betaReal,
    required this.betaImag,
    required this.prob0,
    required this.prob1,
    required this.gateHistory,
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
                label: 'P(|0⟩)',
                value: '${(prob0 * 100).toInt()}%',
              ),
              _InfoItem(
                label: 'P(|1⟩)',
                value: '${(prob1 * 100).toInt()}%',
              ),
            ],
          ),
          if (gateHistory.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              gateHistory,
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
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

class QuantumGatesPainter extends CustomPainter {
  final double time;
  final double alpha;
  final double betaReal;
  final double betaImag;
  final int selectedGate;
  final List<int> gateHistory;

  QuantumGatesPainter({
    required this.time,
    required this.alpha,
    required this.betaReal,
    required this.betaImag,
    required this.selectedGate,
    required this.gateHistory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);
    _drawBlochSphere(canvas, size);
    _drawQuantumCircuit(canvas, size);
    _drawStateVector(canvas, size);
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

  void _drawBlochSphere(Canvas canvas, Size size) {
    final centerX = size.width * 0.25;
    final centerY = size.height * 0.45;
    final radius = 80.0;

    // Sphere outline
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Equator
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, centerY), width: radius * 2, height: radius * 0.5),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke,
    );

    // Axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.4)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(centerX, centerY - radius - 10),
      Offset(centerX, centerY + radius + 10),
      axisPaint,
    );

    // Calculate Bloch vector from state
    final theta = 2 * math.acos(alpha.abs().clamp(0.0, 1.0));
    final phi = math.atan2(betaImag, betaReal);

    final blochX = radius * math.sin(theta) * math.cos(phi + time * 0.3);
    final blochZ = -radius * math.cos(theta);

    final screenX = centerX + blochX;
    final screenY = centerY + blochZ;

    // Bloch vector
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(screenX, screenY),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3,
    );

    // Vector tip
    canvas.drawCircle(
      Offset(screenX, screenY),
      6,
      Paint()..color = AppColors.accent,
    );

    // |0⟩ and |1⟩ labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: '|0⟩',
      style: TextStyle(color: const Color(0xFF48BB78), fontSize: 11, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + 5, centerY - radius - 20));

    textPainter.text = TextSpan(
      text: '|1⟩',
      style: TextStyle(color: const Color(0xFFFC8181), fontSize: 11, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(centerX + 5, centerY + radius + 5));
  }

  void _drawQuantumCircuit(Canvas canvas, Size size) {
    final startX = size.width * 0.45;
    final endX = size.width - 30;
    final y = size.height * 0.45;

    // Qubit line
    canvas.drawLine(
      Offset(startX, y),
      Offset(endX, y),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2,
    );

    // Input state
    final textPainter = TextPainter(
      text: TextSpan(
        text: '|ψ⟩',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(startX - 25, y - 8));

    // Draw gates in history
    final gateWidth = 35.0;
    final gateSpacing = 45.0;
    const gateNames = ['H', 'X', 'Y', 'Z', 'S', 'T'];
    const gateColors = [
      Color(0xFF63B3ED), // H - blue
      Color(0xFFFC8181), // X - red
      Color(0xFF68D391), // Y - green
      Color(0xFF805AD5), // Z - purple
      Color(0xFFED8936), // S - orange
      Color(0xFFF687B3), // T - pink
    ];

    for (int i = 0; i < gateHistory.length && i < 5; i++) {
      final gateX = startX + 40 + i * gateSpacing;
      final gateIndex = gateHistory[gateHistory.length - 1 - i];

      // Gate box
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(gateX, y), width: gateWidth, height: gateWidth),
          const Radius.circular(4),
        ),
        Paint()..color = gateColors[gateIndex].withValues(alpha: 0.2),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(gateX, y), width: gateWidth, height: gateWidth),
          const Radius.circular(4),
        ),
        Paint()
          ..color = gateColors[gateIndex]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Gate label
      textPainter.text = TextSpan(
        text: gateNames[gateIndex],
        style: TextStyle(
          color: gateColors[gateIndex],
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(gateX - textPainter.width / 2, y - 10));
    }
  }

  void _drawStateVector(Canvas canvas, Size size) {
    final x = size.width * 0.7;
    final y = size.height * 0.75;

    final prob0 = alpha * alpha;
    final prob1 = betaReal * betaReal + betaImag * betaImag;

    // State vector text
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: '|ψ⟩ = ${alpha.toStringAsFixed(2)}|0⟩ + (${betaReal.toStringAsFixed(2)}${betaImag >= 0 ? "+" : ""}${betaImag.toStringAsFixed(2)}i)|1⟩',
      style: TextStyle(
        color: AppColors.accent,
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));

    // Probability bars
    final barWidth = 80.0;
    final barHeight = 15.0;
    final barY = y + 25;

    // |0⟩ bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 2, barY, barWidth * prob0, barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF48BB78),
    );

    // |1⟩ bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 2, barY + 20, barWidth * prob1, barHeight),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFC8181),
    );

    // Labels
    textPainter.text = TextSpan(
      text: '|0⟩ ${(prob0 * 100).toInt()}%',
      style: TextStyle(color: const Color(0xFF48BB78), fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x + barWidth / 2 + 5, barY));

    textPainter.text = TextSpan(
      text: '|1⟩ ${(prob1 * 100).toInt()}%',
      style: TextStyle(color: const Color(0xFFFC8181), fontSize: 9),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x + barWidth / 2 + 5, barY + 20));
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Bloch sphere label
    textPainter.text = TextSpan(
      text: 'Bloch Sphere',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.25 - textPainter.width / 2, size.height * 0.8));

    // Circuit label
    textPainter.text = TextSpan(
      text: 'Quantum Circuit',
      style: TextStyle(
        color: AppColors.muted,
        fontSize: 10,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * 0.65 - textPainter.width / 2, size.height * 0.25));
  }

  @override
  bool shouldRepaint(covariant QuantumGatesPainter oldDelegate) =>
      time != oldDelegate.time ||
      alpha != oldDelegate.alpha ||
      betaReal != oldDelegate.betaReal ||
      betaImag != oldDelegate.betaImag ||
      gateHistory.length != oldDelegate.gateHistory.length;
}
