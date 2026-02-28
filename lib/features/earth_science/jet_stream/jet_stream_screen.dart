import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class JetStreamScreen extends StatefulWidget {
  const JetStreamScreen({super.key});
  @override
  State<JetStreamScreen> createState() => _JetStreamScreenState();
}

class _JetStreamScreenState extends State<JetStreamScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _amplitude = 0.5;
  double _speed = 200.0;
  

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
      
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _amplitude = 0.5;
      _speed = 200.0;
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
          Text('지구과학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('제트 기류', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '제트 기류',
          formulaDescription: '제트 기류의 사행과 전 세계 기상에 미치는 영향을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _JetStreamScreenPainter(
                time: _time,
                amplitude: _amplitude,
                speed: _speed,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '로스비파 진폭',
                value: _amplitude,
                min: 0.1,
                max: 1.0,
                step: 0.05,
                defaultValue: 0.5,
                formatValue: (v) => '${v.toStringAsFixed(2)}',
                onChanged: (v) => setState(() => _amplitude = v),
              ),
              advancedControls: [
            SimSlider(
                label: '제트 기류 속도 (km/h)',
                value: _speed,
                min: 100.0,
                max: 400.0,
                defaultValue: 200.0,
                formatValue: (v) => '${v.toInt()} km/h',
                onChanged: (v) => setState(() => _speed = v),
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
          _V('속도', '${_speed.toInt()} km/h'),
          _V('진폭', '${_amplitude.toStringAsFixed(2)}'),
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

class _JetStreamScreenPainter extends CustomPainter {
  final double time;
  final double amplitude;
  final double speed;

  _JetStreamScreenPainter({
    required this.time,
    required this.amplitude,
    required this.speed,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, {Color color = const Color(0xFF5A8A9A), double fontSize = 9}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    final speedFactor = speed / 400.0; // 0..1

    // Background: hemisphere map
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF051228), const Color(0xFF0A2A18), const Color(0xFF0A1A30)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Latitude lines
    final latPaint = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.7)..strokeWidth = 0.6;
    final latLabels = ['90°N', '60°N', '30°N', '0°', '30°S', '60°S', '90°S'];
    for (int i = 0; i <= 6; i++) {
      final y = h * i / 6;
      canvas.drawLine(Offset(0, y), Offset(w, y), latPaint);
      _drawLabel(canvas, latLabels[i], Offset(22, y), color: const Color(0xFF3A5A6A), fontSize: 8);
    }

    // Longitude lines
    final lonPaint = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.4)..strokeWidth = 0.4;
    for (int i = 0; i <= 8; i++) {
      final x = w * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, h), lonPaint);
    }

    // Helper to compute jet stream y position (Rossby wave)
    double jetY(double x, double baseLatFrac, double waveNum, double phaseOff) {
      final phase = time * speedFactor * 2.0 + phaseOff;
      return h * baseLatFrac + h * 0.065 * amplitude * math.sin(waveNum * x / w * math.pi * 2 - phase);
    }

    // Draw two jet streams: polar jet (~60°N => y=h*1/6) and subtropical jet (~30°N => y=h*2/6)
    final jets = [
      (1.0 / 6.0, 3.5, 0.0, '극 제트 기류  ~60°N', const Color(0xFF00D4FF)),   // polar
      (2.0 / 6.0, 2.5, 1.2, '아열대 제트  ~30°N', const Color(0xFF64CFFF)),    // subtropical
      (4.0 / 6.0, 2.0, 0.6, '아열대 제트  ~30°S', const Color(0xFF4488AA)),    // SH subtropical
      (5.0 / 6.0, 3.0, 2.0, '극 제트 기류  ~60°S', const Color(0xFF2266AA)),   // SH polar
    ];

    for (final jet in jets) {
      final baseLatFrac = jet.$1;
      final waveNum = jet.$2;
      final phaseOff = jet.$3;
      final label = jet.$4;
      final jetColor = jet.$5;

      // Glow layer
      final glowPath = Path();
      bool first = true;
      for (int px = 0; px <= w.toInt(); px += 2) {
        final y = jetY(px.toDouble(), baseLatFrac, waveNum, phaseOff);
        if (first) { glowPath.moveTo(px.toDouble(), y); first = false; }
        else { glowPath.lineTo(px.toDouble(), y); }
      }
      canvas.drawPath(glowPath, Paint()
        ..color = jetColor.withValues(alpha: 0.15)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

      // Main stream path with speed-based color
      final mainPath = Path();
      first = true;
      for (int px = 0; px <= w.toInt(); px += 2) {
        final y = jetY(px.toDouble(), baseLatFrac, waveNum, phaseOff);
        if (first) { mainPath.moveTo(px.toDouble(), y); first = false; }
        else { mainPath.lineTo(px.toDouble(), y); }
      }
      canvas.drawPath(mainPath, Paint()
        ..color = jetColor.withValues(alpha: 0.85)
        ..strokeWidth = 2.5 + speedFactor * 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round);

      // Flow particles along jet
      for (int p = 0; p < 8; p++) {
        final tFrac = ((p / 8.0) + time * speedFactor * 0.5 + phaseOff * 0.1) % 1.0;
        final px = tFrac * w;
        final py = jetY(px, baseLatFrac, waveNum, phaseOff);
        canvas.drawCircle(Offset(px, py), 2.5 + speedFactor * 1.5,
          Paint()..color = jetColor.withValues(alpha: 0.9));
      }

      // Label at the right side
      final labelY = jetY(w * 0.72, baseLatFrac, waveNum, phaseOff);
      _drawLabel(canvas, label, Offset(w * 0.72, labelY - 10), color: jetColor.withValues(alpha: 0.9), fontSize: 8);
    }

    // Rossby wave annotation at top
    _drawLabel(canvas, '로스비파 (Rossby Wave)', Offset(w * 0.5, 12), color: const Color(0xFF5A8A9A), fontSize: 9);
    _drawLabel(canvas, '진폭 ${amplitude.toStringAsFixed(2)}  |  속도 ${speed.toInt()} km/h',
      Offset(w * 0.5, h - 10), color: const Color(0xFF3A5A6A), fontSize: 8);

    // Speed color legend bar
    final barRect = Rect.fromLTWH(w - 60, h * 0.3, 10, h * 0.4);
    final barPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF00D4FF), const Color(0xFF1A3040)],
      ).createShader(barRect);
    canvas.drawRect(barRect, barPaint);
    _drawLabel(canvas, '빠름', Offset(w - 36, h * 0.3 + 4), color: const Color(0xFF00D4FF), fontSize: 7);
    _drawLabel(canvas, '느림', Offset(w - 36, h * 0.7 - 4), color: const Color(0xFF3A5A6A), fontSize: 7);
  }

  @override
  bool shouldRepaint(covariant _JetStreamScreenPainter oldDelegate) => true;
}
