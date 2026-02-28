import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class NetworkCascadeScreen extends StatefulWidget {
  const NetworkCascadeScreen({super.key});
  @override
  State<NetworkCascadeScreen> createState() => _NetworkCascadeScreenState();
}

class _NetworkCascadeScreenState extends State<NetworkCascadeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _beta = 0.3;
  double _gammaR = 0.1;
  double _infected = 0.01, _recovered = 0.0;

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
      final s = 1 - _infected - _recovered;
      final di = _beta * s * _infected - _gammaR * _infected;
      _infected = (_infected + di * 0.016).clamp(0.0, 1.0);
      _recovered = (_recovered + _gammaR * _infected * 0.016).clamp(0.0, 1.0);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _beta = 0.3; _gammaR = 0.1; _infected = 0.01; _recovered = 0.0;
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
          Text('카오스 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('네트워크 전파', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스 시뮬레이션',
          title: '네트워크 전파',
          formula: 'I(t+1) = I(t) + βSI - γI',
          formulaDescription: '네트워크에서의 정보 전파와 캐스케이드를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _NetworkCascadeScreenPainter(
                time: _time,
                beta: _beta,
                gammaR: _gammaR,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '전파율 (β)',
                value: _beta,
                min: 0.01,
                max: 1,
                step: 0.01,
                defaultValue: 0.3,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _beta = v),
              ),
              advancedControls: [
            SimSlider(
                label: '회복률 (γ)',
                value: _gammaR,
                min: 0.01,
                max: 0.5,
                step: 0.01,
                defaultValue: 0.1,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _gammaR = v),
              ),
              ],
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
          _V('감염', (_infected * 100).toStringAsFixed(1) + '%'),
          _V('회복', (_recovered * 100).toStringAsFixed(1) + '%'),
          _V('R₀', (_beta / _gammaR).toStringAsFixed(2)),
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

class _NetworkCascadeScreenPainter extends CustomPainter {
  final double time;
  final double beta;
  final double gammaR;

  _NetworkCascadeScreenPainter({
    required this.time,
    required this.beta,
    required this.gammaR,
  });

  static const int _numNodes = 20;

  // Fixed node layout: mix of ring + scattered interior
  static List<Offset> _buildNodePositions(Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final ringR = math.min(size.width, size.height) * 0.36;
    final rng = math.Random(99);
    final positions = <Offset>[];
    for (int i = 0; i < _numNodes; i++) {
      if (i < 14) {
        final a = i * math.pi * 2 / 14 - math.pi / 2;
        positions.add(Offset(cx + ringR * math.cos(a), cy + ringR * math.sin(a)));
      } else {
        positions.add(Offset(
          cx + (rng.nextDouble() - 0.5) * ringR * 0.9,
          cy + (rng.nextDouble() - 0.5) * ringR * 0.9,
        ));
      }
    }
    return positions;
  }

  // Fixed edges: ring neighbors + some cross-connections
  static List<List<int>> _buildEdges() {
    final edges = <List<int>>[];
    // Ring edges
    for (int i = 0; i < 14; i++) {
      edges.add([i, (i + 1) % 14]);
      if (i % 3 == 0) { edges.add([i, (i + 2) % 14]); }
    }
    // Cross edges to interior
    final rng = math.Random(42);
    final innerNodes = List.generate(6, (i) => 14 + i);
    for (final inner in innerNodes) {
      final targets = List.generate(3, (_) => rng.nextInt(14));
      for (final t in targets) {
        edges.add([inner, t]);
      }
    }
    // Interior cross-edges
    for (int i = 14; i < _numNodes - 1; i++) {
      edges.add([i, i + 1]);
    }
    return edges;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final positions = _buildNodePositions(size);
    final edges = _buildEdges();

    // Cascade wave: one origin node, wave spreads over time
    // Cascade period: faster when R0 > 1
    final cascadeSpeed = (beta * 1.5).clamp(0.3, 2.5);
    final cascadePhase = (time * cascadeSpeed) % 8.0; // 0..8 cycle
    final waveRadius = cascadePhase * 1.8; // node-hop distance
    const originNode = 0;

    // Compute per-node hop distance from origin (BFS-like, deterministic)
    final hopDist = List.filled(_numNodes, 999);
    hopDist[originNode] = 0;
    // Simple BFS over edges
    bool changed = true;
    while (changed) {
      changed = false;
      for (final e in edges) {
        final a = e[0], b = e[1];
        if (hopDist[a] + 1 < hopDist[b]) { hopDist[b] = hopDist[a] + 1; changed = true; }
        if (hopDist[b] + 1 < hopDist[a]) { hopDist[a] = hopDist[b] + 1; changed = true; }
      }
    }

    // Node states
    // INACTIVE=0, ACTIVE=1, RECOVERED=2
    final states = List.filled(_numNodes, 0);
    final recoveryDelay = 1.0 / (gammaR + 0.01) * 0.3;
    for (int n = 0; n < _numNodes; n++) {
      final d = hopDist[n].toDouble();
      if (d <= waveRadius) {
        final activatedAt = d / cascadeSpeed;
        final elapsed = time * cascadeSpeed % 8.0 / cascadeSpeed - activatedAt;
        if (elapsed > recoveryDelay) {
          states[n] = 2; // recovered
        } else {
          states[n] = 1; // active
        }
      }
    }

    // Infected count
    final infectedCount = states.where((s) => s == 1).length;

    // Draw edges
    final edgePaint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (final e in edges) {
      final a = positions[e[0]], b = positions[e[1]];
      final aState = states[e[0]], bState = states[e[1]];
      if (aState == 1 || bState == 1) {
        edgePaint.color = AppColors.accent.withValues(alpha: 0.45);
        edgePaint.strokeWidth = 1.5;
      } else {
        edgePaint.color = AppColors.muted.withValues(alpha: 0.25);
        edgePaint.strokeWidth = 0.8;
      }
      canvas.drawLine(a, b, edgePaint);
    }

    // Draw nodes
    for (int n = 0; n < _numNodes; n++) {
      final pos = positions[n];
      final state = states[n];
      Color nodeCol;
      double nodeR;
      switch (state) {
        case 1: // active/infected — cyan glow
          nodeCol = AppColors.accent;
          nodeR = 7.0;
          // Ripple
          final rippleT = ((time * cascadeSpeed % 8.0) - hopDist[n]) % 1.0;
          canvas.drawCircle(pos, nodeR + rippleT * 12,
              Paint()..color = AppColors.accent.withValues(alpha: (1.0 - rippleT) * 0.3));
          break;
        case 2: // recovered — orange dim
          nodeCol = AppColors.accent2.withValues(alpha: 0.6);
          nodeR = 5.0;
          break;
        default: // inactive
          nodeCol = AppColors.muted.withValues(alpha: 0.7);
          nodeR = 4.5;
      }
      // Glow
      if (state == 1) {
        canvas.drawCircle(pos, nodeR + 4, Paint()..color = nodeCol.withValues(alpha: 0.2));
      }
      canvas.drawCircle(pos, nodeR, Paint()..color = nodeCol);
      canvas.drawCircle(pos, nodeR,
          Paint()..color = AppColors.ink.withValues(alpha: 0.3)..strokeWidth = 0.8..style = PaintingStyle.stroke);
    }

    // Origin node marker
    canvas.drawCircle(positions[originNode], 9,
        Paint()..color = AppColors.accent.withValues(alpha: 0.4)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Stats
    final infPct = infectedCount / _numNodes * 100;
    final tp = TextPainter(
      text: TextSpan(
        text: 'β=${beta.toStringAsFixed(2)} γ=${gammaR.toStringAsFixed(2)}  감염 ${infPct.toStringAsFixed(0)}%',
        style: const TextStyle(color: Color(0xFF5A8A9A), fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(6, size.height - 18));
  }

  @override
  bool shouldRepaint(covariant _NetworkCascadeScreenPainter oldDelegate) => true;
}
