import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class QuantumFourierScreen extends StatefulWidget {
  const QuantumFourierScreen({super.key});
  @override
  State<QuantumFourierScreen> createState() => _QuantumFourierScreenState();
}

class _QuantumFourierScreenState extends State<QuantumFourierScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _nQubits = 3;
  
  double _stateSize = 8.0, _phaseRes = 45.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;
    setState(() {
      _time += 0.016;
      final n = _nQubits.toInt();
      _stateSize = math.pow(2, n).toDouble();
      _phaseRes = 360.0 / _stateSize;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _nQubits = 3.0;
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('양자역학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('양자 푸리에 변환', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '양자 푸리에 변환',
          formula: 'QFT|j⟩ = (1/√N)Σ e^(2πijk/N)|k⟩',
          formulaDescription: '양자 푸리에 변환의 과정을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _QuantumFourierScreenPainter(
                time: _time,
                nQubits: _nQubits,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '큐비트 수',
                value: _nQubits,
                min: 1,
                max: 6,
                step: 1,
                defaultValue: 3,
                formatValue: (v) => '${v.toInt()} qubits',
                onChanged: (v) => setState(() => _nQubits = v),
              ),
              
            ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(children: [
          _V('상태 수', _stateSize.toInt().toString()),
          _V('위상 해상도', '${_phaseRes.toStringAsFixed(1)}°'),
          _V('큐비트', _nQubits.toInt().toString()),
                ]),
              ),
            ],
          ),
          buttons: SimButtonGroup(expanded: true, buttons: [
            SimButton(
              label: _isRunning ? '정지' : '재생',
              icon: _isRunning ? Icons.pause : Icons.play_arrow,
              isPrimary: true,
              onPressed: () { HapticFeedback.selectionClick(); setState(() => _isRunning = !_isRunning); },
            ),
            SimButton(label: '리셋', icon: Icons.refresh, onPressed: _reset),
          ]),
        ),
      ),
    );
  }
}

class _V extends StatelessWidget {
  final String label, value;
  const _V(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
  ]));
}

class _QuantumFourierScreenPainter extends CustomPainter {
  final double time;
  final double nQubits;

  _QuantumFourierScreenPainter({
    required this.time,
    required this.nQubits,
  });

  void _drawText(Canvas canvas, String text, Offset offset,
      {double fontSize = 10, Color color = const Color(0xFFE0F4FF), bool bold = false, TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    double dx = offset.dx;
    if (align == TextAlign.center) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final n = nQubits.toInt().clamp(2, 4);
    final N = math.pow(2, n).toInt();
    final w = size.width;
    final h = size.height;

    // --- Layout ---
    final circuitTop = 20.0;
    final circuitHeight = h * 0.48;
    final spectrumTop = circuitTop + circuitHeight + 16;
    final spectrumHeight = h - spectrumTop - 12;

    final qubitSpacing = circuitHeight / (n + 1);
    final leftMargin = 36.0;
    final rightMargin = 36.0;
    final circuitWidth = w - leftMargin - rightMargin;

    // Gate animation progress (0~1 cycling)
    final gateProgress = (time * 0.3) % 1.0;

    // --- Draw qubit wires ---
    final wirePaint = Paint()
      ..color = const Color(0xFF5A8A9A).withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    final wirePaintActive = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 1.5;

    for (int q = 0; q < n; q++) {
      final y = circuitTop + qubitSpacing * (q + 1);
      // Label |q⟩
      _drawText(canvas, '|q$q⟩', Offset(2, y - 6),
          fontSize: 9, color: const Color(0xFF5A8A9A));
      canvas.drawLine(Offset(leftMargin, y), Offset(w - rightMargin, y), wirePaint);
    }

    // Gate column positions: H gates then controlled-R gates then SWAP
    // For n qubits, QFT has n H gates + control gates
    final gateSlots = <List<dynamic>>[]; // [type, qubit, controlQubit or -1, kVal]
    for (int q = 0; q < n; q++) {
      gateSlots.add(['H', q, -1, 0]);
      for (int k = 2; k <= n - q; k++) {
        gateSlots.add(['R', q + k - 1, q, k]);
      }
    }
    // SWAP gates at end
    for (int i = 0; i < n ~/ 2; i++) {
      gateSlots.add(['SWAP', i, n - 1 - i, 0]);
    }

    final totalSlots = gateSlots.length;
    final slotWidth = circuitWidth / (totalSlots + 1);
    final currentSlot = (gateProgress * totalSlots).floor();

    final boxPaint = Paint()..style = PaintingStyle.fill;
    final boxBorderPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final ctrlLinePaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.8)
      ..strokeWidth = 1.2;

    for (int s = 0; s < gateSlots.length; s++) {
      final slot = gateSlots[s];
      final type = slot[0] as String;
      final q = slot[1] as int;
      final ctrl = slot[2] as int;
      final k = slot[3] as int;
      final x = leftMargin + slotWidth * (s + 1);
      final y = circuitTop + qubitSpacing * (q + 1);
      final isActive = s == currentSlot;
      final isPast = s < currentSlot;

      final gateAlpha = isPast ? 0.9 : (isActive ? 1.0 : 0.45);
      final gateColor = isActive
          ? const Color(0xFF00D4FF)
          : (isPast ? const Color(0xFF00D4FF).withValues(alpha: 0.7) : const Color(0xFF1A3040));

      if (type == 'H') {
        // Hadamard gate box
        boxPaint.color = gateColor.withValues(alpha: 0.2 * gateAlpha + 0.1);
        boxBorderPaint.color = const Color(0xFF00D4FF).withValues(alpha: gateAlpha);
        final rect = Rect.fromCenter(center: Offset(x, y), width: 22, height: 16);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), boxPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), boxBorderPaint);
        _drawText(canvas, 'H', Offset(x, y - 5),
            fontSize: 9, color: const Color(0xFF00D4FF).withValues(alpha: gateAlpha), bold: true, align: TextAlign.center);
        // Animate highlight
        if (isActive) {
          // Draw wire glow
          canvas.drawLine(Offset(leftMargin, y), Offset(x - 11, y), wirePaintActive);
        }
      } else if (type == 'R') {
        // Controlled-phase gate: dot on control, box on target
        final ctrlY = circuitTop + qubitSpacing * (ctrl + 1);
        final tgtY = y;
        // Control dot
        canvas.drawCircle(Offset(x, ctrlY), 4,
            Paint()..color = const Color(0xFFFF6B35).withValues(alpha: gateAlpha));
        // Line ctrl→target
        canvas.drawLine(Offset(x, ctrlY), Offset(x, tgtY), ctrlLinePaint..color = const Color(0xFFFF6B35).withValues(alpha: gateAlpha * 0.7));
        // Target box with Rk label
        boxPaint.color = const Color(0xFFFF6B35).withValues(alpha: 0.15 * gateAlpha + 0.05);
        boxBorderPaint.color = const Color(0xFFFF6B35).withValues(alpha: gateAlpha);
        final rect = Rect.fromCenter(center: Offset(x, tgtY), width: 22, height: 16);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), boxPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), boxBorderPaint);
        _drawText(canvas, 'R$k', Offset(x, tgtY - 5),
            fontSize: 8, color: const Color(0xFFFF6B35).withValues(alpha: gateAlpha), align: TextAlign.center);
      } else if (type == 'SWAP') {
        // SWAP gate: × on two wires
        final y2 = circuitTop + qubitSpacing * (ctrl + 1);
        canvas.drawLine(Offset(x, y), Offset(x, y2),
            ctrlLinePaint..color = const Color(0xFF5A8A9A).withValues(alpha: gateAlpha));
        for (final yw in [y, y2]) {
          final xp = Paint()
            ..color = const Color(0xFF5A8A9A).withValues(alpha: gateAlpha)
            ..strokeWidth = 2;
          canvas.drawLine(Offset(x - 5, yw - 5), Offset(x + 5, yw + 5), xp);
          canvas.drawLine(Offset(x + 5, yw - 5), Offset(x - 5, yw + 5), xp);
        }
      }
    }

    // Input/output labels
    _drawText(canvas, '|ψ⟩', Offset(leftMargin - 6, circuitTop + qubitSpacing - 6),
        fontSize: 9, color: const Color(0xFF00D4FF));
    _drawText(canvas, '|QFT⟩', Offset(w - rightMargin + 2, circuitTop + qubitSpacing - 6),
        fontSize: 8, color: const Color(0xFF00D4FF));

    // --- Frequency Spectrum below ---
    if (spectrumHeight > 20) {
      final specLeft = leftMargin;
      final specRight = w - rightMargin;
      final specW = specRight - specLeft;
      final specBottom = spectrumTop + spectrumHeight;

      // Axes
      final axisPaint = Paint()
        ..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(specLeft, specBottom), Offset(specRight, specBottom), axisPaint);
      canvas.drawLine(Offset(specLeft, spectrumTop), Offset(specLeft, specBottom), axisPaint);
      _drawText(canvas, '주파수 스펙트럼', Offset(specLeft + specW / 2, spectrumTop),
          fontSize: 9, color: const Color(0xFF5A8A9A), align: TextAlign.center);

      // QFT amplitudes: |QFT(x)|² for input state |x⟩
      // For uniform superposition, all equal 1/N
      // Animate: show growing bars
      final barW = specW / N - 2;
      for (int k = 0; k < N; k++) {
        final phase = 2 * math.pi * k / N;
        // Amplitude with animation ripple
        final amp = 0.5 + 0.5 * math.cos(phase - time * 1.5);
        final barH = amp.clamp(0.0, 1.0) * (spectrumHeight - 14);
        final bx = specLeft + (k + 0.5) * (specW / N);
        final barColor = Color.lerp(const Color(0xFF00D4FF), const Color(0xFFFF6B35), k / N)!;
        canvas.drawRect(
          Rect.fromLTWH(bx - barW / 2, specBottom - barH, barW, barH),
          Paint()..color = barColor.withValues(alpha: 0.75),
        );
        if (N <= 8 && k < N) {
          _drawText(canvas, '$k', Offset(bx, specBottom + 2),
              fontSize: 8, color: const Color(0xFF5A8A9A), align: TextAlign.center);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QuantumFourierScreenPainter oldDelegate) => true;
}
