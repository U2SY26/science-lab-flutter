import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ActionPotentialSynapseScreen extends StatefulWidget {
  const ActionPotentialSynapseScreen({super.key});
  @override
  State<ActionPotentialSynapseScreen> createState() => _ActionPotentialSynapseScreenState();
}

class _ActionPotentialSynapseScreenState extends State<ActionPotentialSynapseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _neurotransmitter = 1;
  
  double _postV = -70, _epsp = 0;

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
      _epsp = 20 * _neurotransmitter / (_neurotransmitter + 1);
      _postV = -70 + _epsp * math.exp(-(_time % 5) * 2);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _neurotransmitter = 1.0;
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
          Text('생물학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('시냅스 전달', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '시냅스 전달',
          formula: 'V_m = V_rest + ΔV',
          formulaDescription: '시냅스에서의 신경 전달 과정을 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ActionPotentialSynapseScreenPainter(
                time: _time,
                neurotransmitter: _neurotransmitter,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '신경전달물질 (mM)',
                value: _neurotransmitter,
                min: 0,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1) + ' mM',
                onChanged: (v) => setState(() => _neurotransmitter = v),
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
          _V('V_m', _postV.toStringAsFixed(1) + ' mV'),
          _V('EPSP', _epsp.toStringAsFixed(1) + ' mV'),
          _V('NT', _neurotransmitter.toStringAsFixed(1) + ' mM'),
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

class _ActionPotentialSynapseScreenPainter extends CustomPainter {
  final double time;
  final double neurotransmitter;

  _ActionPotentialSynapseScreenPainter({
    required this.time,
    required this.neurotransmitter,
  });

  void _lbl(Canvas canvas, String text, Offset pos, Color color, double fs, {FontWeight fw = FontWeight.normal}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fs, fontWeight: fw)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // ── Upper half: Action Potential voltage curve ──────────────────────
    final apTop = 22.0;
    final apH = h * 0.38;
    final apBottom = apTop + apH;
    final apLeft = 28.0;
    final apRight = w - 12.0;
    final apW = apRight - apLeft;

    // Grid lines
    final gridPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final gy = apTop + apH * i / 4;
      canvas.drawLine(Offset(apLeft, gy), Offset(apRight, gy), gridPaint);
    }

    // Y-axis voltage labels
    final voltages = ['+40', '0', '-40', '-70'];
    for (int i = 0; i < voltages.length; i++) {
      final vy = apTop + apH * i / 3;
      _lbl(canvas, voltages[i], Offset(apLeft - 10, vy), const Color(0xFF5A8A9A), 7);
    }
    _lbl(canvas, 'mV', Offset(apLeft - 10, apTop - 8), const Color(0xFF5A8A9A), 7);

    // Action potential waveform (scrolling)
    final cycleT = 3.0; // seconds per cycle
    final scrollSpeed = neurotransmitter * 0.4 + 0.3;
    final totalPoints = 200;

    // Map voltage -80..+60 → apTop..apBottom
    double voltToY(double v) => apTop + (60 - v) / 140 * apH;

    double apVoltage(double t) {
      final phase = (t % cycleT) / cycleT;
      if (phase < 0.05) return -70 + phase / 0.05 * 110; // rise
      if (phase < 0.12) return 40 - (phase - 0.05) / 0.07 * 55; // fall fast
      if (phase < 0.22) return -15 - (phase - 0.12) / 0.10 * 65; // hyperpolar
      if (phase < 0.40) return -80 + (phase - 0.22) / 0.18 * 10; // recover
      return -70;
    }

    final apPath = Path();
    for (int i = 0; i <= totalPoints; i++) {
      final t = (time * scrollSpeed - 2.0 + i * 2.0 / totalPoints);
      final x = apLeft + apW * i / totalPoints;
      final v = apVoltage(t);
      final y = voltToY(v);
      if (i == 0) { apPath.moveTo(x, y); } else { apPath.lineTo(x, y); }
    }
    canvas.drawPath(apPath, Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 2..style = PaintingStyle.stroke);

    // Ion channel timing bars below waveform
    final barY = apBottom + 6;
    // Na+ channel (opens at depolarization)
    final naNorm = ((time * scrollSpeed % cycleT) / cycleT);
    final naOpen = naNorm > 0.0 && naNorm < 0.12;
    final naColor = naOpen ? const Color(0xFF00D4FF) : const Color(0xFF1A3040);
    canvas.drawRect(Rect.fromLTWH(apLeft, barY, apW * 0.12, 7),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.25));
    canvas.drawRect(Rect.fromLTWH(apLeft, barY, apW * 0.12 * (naOpen ? 1.0 : 0.0), 7),
        Paint()..color = naColor.withValues(alpha: 0.7));
    _lbl(canvas, 'Na⁺', Offset(apLeft - 12, barY + 3.5), const Color(0xFF00D4FF), 7);

    canvas.drawRect(Rect.fromLTWH(apLeft, barY + 10, apW * 0.30, 7),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.25));
    final kNorm2 = naNorm;
    final kOpen = kNorm2 > 0.05 && kNorm2 < 0.40;
    canvas.drawRect(Rect.fromLTWH(apLeft + apW * 0.05, barY + 10, apW * 0.30 * (kOpen ? 1.0 : 0.0), 7),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7));
    _lbl(canvas, 'K⁺', Offset(apLeft - 12, barY + 13.5), const Color(0xFFFF6B35), 7);

    // Divider
    final divY = apBottom + 32.0;
    canvas.drawLine(Offset(0, divY), Offset(w, divY),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);

    // ── Lower half: Synapse structure ──────────────────────────────────
    final synTop = divY + 6;
    final synH = h - synTop - 4;
    final synCx = w / 2;

    // Pre-synaptic terminal (bulb)
    final preY = synTop + synH * 0.18;
    final preR = synH * 0.20;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(synCx, preY), width: preR * 3.2, height: preR * 1.5),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.12),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(synCx, preY), width: preR * 3.2, height: preR * 1.5),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
    _lbl(canvas, '시냅스 전 뉴런', Offset(synCx, synTop + 6), const Color(0xFF5A8A9A), 7.5);

    // Synaptic vesicles inside pre-terminal
    final rng = math.Random(77);
    for (int i = 0; i < 8; i++) {
      final vx = synCx - preR * 1.4 + rng.nextDouble() * preR * 2.8;
      final vy = preY - preR * 0.5 + rng.nextDouble() * preR * 0.8;
      canvas.drawCircle(Offset(vx, vy), 4.5, Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.6));
      canvas.drawCircle(Offset(vx, vy), 4.5, Paint()..color = const Color(0xFF64FF8C)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }

    // Synaptic cleft
    final cleftTop = preY + preR * 0.75;
    final cleftBottom = cleftTop + synH * 0.14;
    canvas.drawRect(
      Rect.fromLTWH(synCx - preR * 1.6, cleftTop, preR * 3.2, cleftBottom - cleftTop),
      Paint()..color = const Color(0xFF0D1A20),
    );
    _lbl(canvas, '시냅스 틈새', Offset(synCx, (cleftTop + cleftBottom) / 2), const Color(0xFF5A8A9A), 7);

    // Neurotransmitter dots floating across cleft
    final ntPhase = (time * scrollSpeed * 0.7) % 1.0;
    final ntCount = (neurotransmitter * 2 + 2).clamp(2, 8).toInt();
    for (int i = 0; i < ntCount; i++) {
      final t2 = (ntPhase + i / ntCount) % 1.0;
      final nx = synCx - preR * 1.4 + (i / ntCount) * preR * 2.8;
      final ny = cleftTop + t2 * (cleftBottom - cleftTop);
      canvas.drawCircle(Offset(nx, ny), 3, Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.85));
    }

    // Post-synaptic membrane (receptor)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(synCx, cleftBottom + synH * 0.18), width: preR * 3.2, height: preR * 1.4),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.12),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(synCx, cleftBottom + synH * 0.18), width: preR * 3.2, height: preR * 1.4),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
    _lbl(canvas, '시냅스 후 수용체', Offset(synCx, h - 6), const Color(0xFF5A8A9A), 7.5);

    // Receptor binding dots
    for (int i = 0; i < 5; i++) {
      final rx = synCx - preR * 1.2 + i * preR * 0.6;
      final ry = cleftBottom + 3.0;
      final bound = (ntPhase + i * 0.15) % 1.0 > 0.5;
      canvas.drawCircle(Offset(rx, ry), 3.5,
          Paint()..color = (bound ? const Color(0xFFFFD700) : const Color(0xFF1A3040)).withValues(alpha: 0.8));
      canvas.drawCircle(Offset(rx, ry), 3.5,
          Paint()..color = const Color(0xFFFF6B35)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }

    // Title
    _lbl(canvas, '시냅스 전달 (Synaptic Transmission)', Offset(w / 2, 11), const Color(0xFF00D4FF), 10, fw: FontWeight.bold);
  }

  @override
  bool shouldRepaint(covariant _ActionPotentialSynapseScreenPainter oldDelegate) => true;
}
