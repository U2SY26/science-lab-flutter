import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class VoronoiScreen extends StatefulWidget {
  const VoronoiScreen({super.key});
  @override
  State<VoronoiScreen> createState() => _VoronoiScreenState();
}

class _VoronoiScreenState extends State<VoronoiScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _numSites = 10;
  
  int _edges = 0, _faces = 0;

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
      _faces = _numSites.toInt();
      _edges = (3 * _numSites - 6).toInt().clamp(3, 999);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _numSites = 10.0;
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
          Text('수학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('보로노이 다이어그램', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학 시뮬레이션',
          title: '보로노이 다이어그램',
          formula: 'V(p) = {x : d(x,p) ≤ d(x,q)}',
          formulaDescription: '보로노이 다이어그램과 최근접 이웃 분할을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _VoronoiScreenPainter(
                time: _time,
                numSites: _numSites,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '사이트 수',
                value: _numSites,
                min: 3,
                max: 50,
                step: 1,
                defaultValue: 10,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _numSites = v),
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
          _V('영역', '$_faces'),
          _V('변', '$_edges'),
          _V('사이트', _numSites.toInt().toString()),
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

class _VoronoiScreenPainter extends CustomPainter {
  final double time;
  final double numSites;

  _VoronoiScreenPainter({required this.time, required this.numSites});

  static const int kSites = 12;

  static const List<Color> _cellColors = [
    Color(0x331A3A50), Color(0x33203A1A), Color(0x33381A40),
    Color(0x33401A1A), Color(0x331A3840), Color(0x33403A1A),
    Color(0x331A2840), Color(0x33281A40), Color(0x33402810),
    Color(0x331A4028), Color(0x33402018), Color(0x33182040),
  ];

  List<Offset> _sites(Size size) {
    final rng = math.Random(42);
    return List.generate(kSites, (i) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * (size.height - 30);
      final dx = 8 * math.sin(time * 0.4 + i * 1.3);
      final dy = 8 * math.cos(time * 0.35 + i * 0.9);
      return Offset(
        (baseX + dx).clamp(10, size.width - 10),
        (baseY + dy).clamp(10, size.height - 30),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 10 || size.height < 10) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final sites = _sites(size);
    const double gridStep = 12.0;
    final int cols = (size.width / gridStep).ceil();
    final int rows = ((size.height - 25) / gridStep).ceil();

    // Voronoi coloring via nearest-site grid sampling
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final px = c * gridStep + gridStep / 2;
        final py = r * gridStep + gridStep / 2;
        int nearest = 0;
        double minDist = double.infinity;
        for (int s = 0; s < kSites; s++) {
          final dx = px - sites[s].dx, dy = py - sites[s].dy;
          final d = dx * dx + dy * dy;
          if (d < minDist) { minDist = d; nearest = s; }
        }
        canvas.drawRect(
          Rect.fromLTWH(c * gridStep, r * gridStep, gridStep, gridStep),
          Paint()..color = _cellColors[nearest % _cellColors.length],
        );
      }
    }

    // Cell boundary lines (draw bright lines between different cells)
    final borderPaint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int r = 0; r < rows - 1; r++) {
      for (int c = 0; c < cols - 1; c++) {
        final px = c * gridStep + gridStep / 2;
        final py = r * gridStep + gridStep / 2;
        int siteHere = 0; double minD = double.infinity;
        int siteRight = 0; double minDR = double.infinity;
        int siteDown = 0; double minDD = double.infinity;
        for (int s = 0; s < kSites; s++) {
          double d = (px - sites[s].dx) * (px - sites[s].dx) + (py - sites[s].dy) * (py - sites[s].dy);
          if (d < minD) { minD = d; siteHere = s; }
          d = (px + gridStep - sites[s].dx) * (px + gridStep - sites[s].dx) + (py - sites[s].dy) * (py - sites[s].dy);
          if (d < minDR) { minDR = d; siteRight = s; }
          d = (px - sites[s].dx) * (px - sites[s].dx) + (py + gridStep - sites[s].dy) * (py + gridStep - sites[s].dy);
          if (d < minDD) { minDD = d; siteDown = s; }
        }
        if (siteHere != siteRight) {
          canvas.drawLine(Offset(c * gridStep + gridStep, r * gridStep), Offset(c * gridStep + gridStep, r * gridStep + gridStep), borderPaint);
        }
        if (siteHere != siteDown) {
          canvas.drawLine(Offset(c * gridStep, r * gridStep + gridStep), Offset(c * gridStep + gridStep, r * gridStep + gridStep), borderPaint);
        }
      }
    }

    // Fortune's sweep line
    final sweepY = ((time * 30) % (size.height - 25)).toDouble();
    canvas.drawLine(Offset(0, sweepY), Offset(size.width, sweepY),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.7)..strokeWidth = 1.5);

    // Seed points
    for (int i = 0; i < kSites; i++) {
      final s = sites[i];
      canvas.drawCircle(s, 7, Paint()..color = const Color(0xFF0D1A20)..style = PaintingStyle.fill);
      canvas.drawCircle(s, 7, Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5..style = PaintingStyle.stroke);
      // Glow
      canvas.drawCircle(s, 10, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.15)..style = PaintingStyle.fill);
      // Index label
      final tp = TextPainter(
        text: TextSpan(text: '$i', style: const TextStyle(color: Color(0xFFE0F4FF), fontSize: 7)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, s - Offset(tp.width / 2, tp.height / 2));
    }

    // Bottom label
    final ltp = TextPainter(
      text: const TextSpan(text: 'Fortune\'s sweep line →', style: TextStyle(color: Color(0xFFFF6B35), fontSize: 9)),
      textDirection: TextDirection.ltr,
    )..layout();
    ltp.paint(canvas, Offset(size.width - ltp.width - 8, size.height - 18));
  }

  @override
  bool shouldRepaint(covariant _VoronoiScreenPainter oldDelegate) => true;
}
