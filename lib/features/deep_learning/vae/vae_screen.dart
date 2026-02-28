import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class VaeScreen extends StatefulWidget {
  const VaeScreen({super.key});
  @override
  State<VaeScreen> createState() => _VaeScreenState();
}

class _VaeScreenState extends State<VaeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _latentDim = 2;
  double _klWeight = 1;
  double _recon = 0.5, _kl = 0.1, _elbo = 0.4;

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
      _recon = 0.5 * math.exp(-_time * 0.1);
      _kl = 0.1 * _klWeight * _latentDim;
      _elbo = -_recon - _kl;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _latentDim = 2.0; _klWeight = 1.0;
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
          Text('AI/ML 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('변분 오토인코더', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '변분 오토인코더',
          formula: 'ELBO = E[log p(x|z)] - KL(q||p)',
          formulaDescription: '변분 오토인코더의 잠재 공간을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _VaeScreenPainter(
                time: _time,
                latentDim: _latentDim,
                klWeight: _klWeight,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '잠재 차원',
                value: _latentDim,
                min: 1,
                max: 10,
                step: 1,
                defaultValue: 2,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _latentDim = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'KL 가중치 (β)',
                value: _klWeight,
                min: 0,
                max: 5,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _klWeight = v),
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
          _V('Recon', _recon.toStringAsFixed(3)),
          _V('KL', _kl.toStringAsFixed(3)),
          _V('ELBO', _elbo.toStringAsFixed(3)),
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

class _VaeScreenPainter extends CustomPainter {
  final double time;
  final double latentDim;
  final double klWeight;

  _VaeScreenPainter({
    required this.time,
    required this.latentDim,
    required this.klWeight,
  });

  // 5 class colors for point cloud clusters
  static const _classColors = [
    Color(0xFF00D4FF), // cyan
    Color(0xFFFF6B35), // orange
    Color(0xFF64FF8C), // green
    Color(0xFFFF3D8A), // pink
    Color(0xFFFFD700), // gold
  ];

  // Cluster centers in latent space (normalized -1..1)
  static const _centers = [
    Offset(-0.45, -0.35),
    Offset(0.42, -0.38),
    Offset(-0.38, 0.40),
    Offset(0.40, 0.38),
    Offset(0.0, 0.0),
  ];

  // Seeded random for stable point positions
  static final _rng = math.Random(42);
  static final List<_LatentPoint> _points = _generatePoints();

  static List<_LatentPoint> _generatePoints() {
    final pts = <_LatentPoint>[];
    for (int c = 0; c < 5; c++) {
      for (int i = 0; i < 40; i++) {
        final angle = _rng.nextDouble() * math.pi * 2;
        final r = _rng.nextDouble() * 0.22;
        pts.add(_LatentPoint(
          baseX: _centers[c].dx + math.cos(angle) * r,
          baseY: _centers[c].dy + math.sin(angle) * r,
          classIdx: c,
          phase: _rng.nextDouble() * math.pi * 2,
          speed: 0.3 + _rng.nextDouble() * 0.4,
        ));
      }
    }
    return pts;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Reserve space: top panel for latent space, bottom strip for encoder/decoder paths
    final latentH = size.height * 0.72;
    final stripH = size.height - latentH;
    final pad = 28.0;

    // --- Latent space panel ---
    _drawLatentAxes(canvas, size, pad, latentH);
    _drawLatentPoints(canvas, size, pad, latentH);
    _drawKLRings(canvas, size, pad, latentH);
    _drawSampledPoint(canvas, size, pad, latentH);

    // --- Encoder / Decoder strip ---
    _drawEncoderDecoderStrip(canvas, size, latentH, stripH);
  }

  void _drawLatentAxes(Canvas canvas, Size size, double pad, double latentH) {
    final cx = size.width / 2, cy = latentH / 2;
    final axisPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.5)
      ..strokeWidth = 0.7;

    // Grid lines
    for (int i = -2; i <= 2; i++) {
      final fx = i / 2.5;
      final gx = cx + fx * (size.width / 2 - pad);
      final gy = cy + fx * (latentH / 2 - pad);
      canvas.drawLine(Offset(gx, pad), Offset(gx, latentH - pad), axisPaint);
      canvas.drawLine(Offset(pad, gy), Offset(size.width - pad, gy), axisPaint);
    }

    // Axis arrows
    final arrowPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(pad, cy), Offset(size.width - pad + 4, cy), arrowPaint);
    canvas.drawLine(Offset(cx, latentH - pad), Offset(cx, pad - 4), arrowPaint);

    // Axis labels
    _drawText(canvas, 'z₁', Offset(size.width - pad - 4, cy + 4), 9, AppColors.muted.withValues(alpha: 0.7));
    _drawText(canvas, 'z₂', Offset(cx + 4, pad - 2), 9, AppColors.muted.withValues(alpha: 0.7));
    _drawText(canvas, 'Latent Space', Offset(pad, pad - 4), 9, AppColors.accent.withValues(alpha: 0.7));
  }

  void _drawLatentPoints(Canvas canvas, Size size, double pad, double latentH) {
    final cx = size.width / 2, cy = latentH / 2;
    final scaleX = (size.width / 2 - pad) * 0.95;
    final scaleY = (latentH / 2 - pad) * 0.95;

    // KL weight compresses clusters toward origin
    final compress = 1.0 - (klWeight * 0.08).clamp(0.0, 0.55);

    for (final pt in _points) {
      final drift = math.sin(time * pt.speed + pt.phase) * 0.025;
      final px = cx + (pt.baseX * compress + drift) * scaleX;
      final py = cy + (pt.baseY * compress + drift * 0.6) * scaleY;
      final col = _classColors[pt.classIdx];

      // Soft glow
      canvas.drawCircle(Offset(px, py), 7, Paint()..color = col.withValues(alpha: 0.08));
      canvas.drawCircle(Offset(px, py), 4, Paint()..color = col.withValues(alpha: 0.18));
      canvas.drawCircle(Offset(px, py), 2.2, Paint()..color = col.withValues(alpha: 0.85));
    }
  }

  void _drawKLRings(Canvas canvas, Size size, double pad, double latentH) {
    final cx = size.width / 2, cy = latentH / 2;
    final scaleX = (size.width / 2 - pad) * 0.95;
    final scaleY = (latentH / 2 - pad) * 0.95;
    final compress = 1.0 - (klWeight * 0.08).clamp(0.0, 0.55);

    // KL divergence ring around each cluster center
    for (int c = 0; c < 5; c++) {
      final cxC = cx + _centers[c].dx * compress * scaleX;
      final cyC = cy + _centers[c].dy * compress * scaleY;
      final klRadius = 18.0 + klWeight * 2.5;

      final ringPaint = Paint()
        ..color = _classColors[c].withValues(alpha: 0.18)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(cxC, cyC), klRadius, ringPaint);

      // Pulse
      final pulse = math.sin(time * 1.2 + c * 1.2) * 0.5 + 0.5;
      canvas.drawCircle(
        Offset(cxC, cyC),
        klRadius * (1.0 + pulse * 0.15),
        Paint()
          ..color = _classColors[c].withValues(alpha: 0.06)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawSampledPoint(Canvas canvas, Size size, double pad, double latentH) {
    final cx = size.width / 2, cy = latentH / 2;
    final scaleX = (size.width / 2 - pad) * 0.95;
    final scaleY = (latentH / 2 - pad) * 0.95;
    final compress = 1.0 - (klWeight * 0.08).clamp(0.0, 0.55);

    // Sampled point orbits center of class 0 cluster
    final sAngle = time * 0.7;
    final sR = 0.12 * compress;
    final spx = cx + (_centers[0].dx * compress + math.cos(sAngle) * sR) * scaleX;
    final spy = cy + (_centers[0].dy * compress + math.sin(sAngle) * sR) * scaleY;

    // Animated arrow from sample point downward (decoder expansion)
    final arrowPaint = Paint()
      ..color = AppColors.accent2.withValues(alpha: 0.7)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(spx, spy), Offset(spx, latentH - pad + 4), arrowPaint);

    // Sample point: bright white dot with cross hairs
    for (final r in [10.0, 6.0, 3.0]) {
      canvas.drawCircle(
        Offset(spx, spy), r,
        Paint()..color = Colors.white.withValues(alpha: r == 3 ? 0.95 : 0.12),
      );
    }
    canvas.drawLine(Offset(spx - 8, spy), Offset(spx + 8, spy),
        Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 0.8);
    canvas.drawLine(Offset(spx, spy - 8), Offset(spx, spy + 8),
        Paint()..color = Colors.white.withValues(alpha: 0.5)..strokeWidth = 0.8);
  }

  void _drawEncoderDecoderStrip(Canvas canvas, Size size, double top, double h) {
    final w = size.width;
    final mid = w / 2;
    final stripY = top + 4;
    final stripH = h - 8;

    // Background bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8, stripY, w - 16, stripH), const Radius.circular(5)),
      Paint()..color = AppColors.simGrid.withValues(alpha: 0.35),
    );

    // Encoder label (left)
    _drawText(canvas, 'Encoder →', Offset(14, stripY + 3), 9, AppColors.accent.withValues(alpha: 0.75));

    // Animated encode flow: particle from left toward center
    final encPhase = (time * 0.8) % 1.0;
    final epx = 14 + encPhase * (mid - 22);
    canvas.drawCircle(
      Offset(epx, stripY + stripH / 2),
      3.5,
      Paint()..color = AppColors.accent.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(epx, stripY + stripH / 2),
      7,
      Paint()..color = AppColors.accent.withValues(alpha: 0.18),
    );

    // Decoder label (right)
    _drawText(canvas, '← Decoder', Offset(mid + 8, stripY + 3), 9, AppColors.accent2.withValues(alpha: 0.75));

    // Animated decode flow: particle from center toward right
    final decPhase = (time * 0.8 + 0.5) % 1.0;
    final dpx = mid + 8 + decPhase * (w - mid - 22);
    canvas.drawCircle(
      Offset(dpx, stripY + stripH / 2),
      3.5,
      Paint()..color = AppColors.accent2.withValues(alpha: 0.85),
    );
    canvas.drawCircle(
      Offset(dpx, stripY + stripH / 2),
      7,
      Paint()..color = AppColors.accent2.withValues(alpha: 0.18),
    );

    // Divider
    canvas.drawLine(
      Offset(mid, stripY + 2), Offset(mid, stripY + stripH - 2),
      Paint()..color = AppColors.muted.withValues(alpha: 0.35)..strokeWidth = 0.8,
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, double fontSize, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _VaeScreenPainter oldDelegate) => true;
}

class _LatentPoint {
  final double baseX, baseY;
  final int classIdx;
  final double phase, speed;
  const _LatentPoint({
    required this.baseX,
    required this.baseY,
    required this.classIdx,
    required this.phase,
    required this.speed,
  });
}
