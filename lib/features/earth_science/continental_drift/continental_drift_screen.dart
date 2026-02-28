import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ContinentalDriftScreen extends StatefulWidget {
  const ContinentalDriftScreen({super.key});
  @override
  State<ContinentalDriftScreen> createState() => _ContinentalDriftScreenState();
}

class _ContinentalDriftScreenState extends State<ContinentalDriftScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _timeAge = 0;


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
      _timeAge = 0;
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
          const Text('대륙 이동 증거', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '대륙 이동 증거',
          formula: 'v ≈ 2-10 cm/yr',
          formulaDescription: '대륙 이동과 판게아의 증거를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ContinentalDriftScreenPainter(
                time: _time,
                timeAge: _timeAge,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '시대 (백만 년 전)',
                value: _timeAge,
                min: 0,
                max: 300,
                step: 10,
                defaultValue: 0,
                formatValue: (v) => '${v.toStringAsFixed(0)} Ma',
                onChanged: (v) => setState(() => _timeAge = v),
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
          _V('시대', '${_timeAge.toStringAsFixed(0)} Ma'),
          _V('이동 속도', '~5 cm/yr'),
          _V('상태', _timeAge > 200 ? '판게아' : '현재'),
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

class _ContinentalDriftScreenPainter extends CustomPainter {
  final double time;
  final double timeAge;

  _ContinentalDriftScreenPainter({
    required this.time,
    required this.timeAge,
  });

  void _label(Canvas canvas, String text, Offset pos, {double fs = 9, Color col = const Color(0xFF5A8A9A)}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, pos);
  }

  // t=0: present, t=1: Pangaea (250 Myr ago)
  // Draws a simplified continent shape offset by drift amount
  void _drawContinent(Canvas canvas, List<Offset> shape, Color color, {double alpha = 0.85}) {
    final path = Path()..moveTo(shape[0].dx, shape[0].dy);
    for (int i = 1; i < shape.length; i++) {
      path.lineTo(shape[i].dx, shape[i].dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    // Ocean background
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A1520));

    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final w = size.width;
    final h = size.height;

    // t: 0=present, 1=Pangaea
    final t = (timeAge / 250.0).clamp(0.0, 1.0);
    // Non-linear interpolation: ease in (use math.pow for smoothing)
    final tc = math.pow(t, 2.0).toDouble();

    // --- Ocean grid lines ---
    final gridP = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5;
    for (double x = 0; x < w; x += w / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, h * 0.82), gridP);
    }
    for (double y = 0; y < h * 0.82; y += h / 8) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridP);
    }

    // Continent color
    const landColor = Color(0xFF4A7C3F);
    const pangaeaColor = Color(0xFF6B5B2F);

    if (tc < 0.85) {
      // --- Present-day approximation: North America (left), South America (lower-left),
      // Europe/Africa (center-right), Asia (right)

      // Separation offset from Pangaea
      final sep = 1.0 - tc;

      // North America
      final naOffX = -w * 0.22 * sep;
      final naOffY = -h * 0.05 * sep;
      final na = [
        Offset(cx + naOffX - 60, cy + naOffY - 60),
        Offset(cx + naOffX - 20, cy + naOffY - 80),
        Offset(cx + naOffX + 10, cy + naOffY - 55),
        Offset(cx + naOffX + 5, cy + naOffY - 10),
        Offset(cx + naOffX - 30, cy + naOffY + 20),
        Offset(cx + naOffX - 70, cy + naOffY),
      ];
      _drawContinent(canvas, na, landColor);

      // South America
      final saOffX = -w * 0.18 * sep;
      final saOffY = h * 0.08 * sep;
      final sa = [
        Offset(cx + saOffX - 20, cy + saOffY + 15),
        Offset(cx + saOffX + 15, cy + saOffY + 5),
        Offset(cx + saOffX + 20, cy + saOffY + 60),
        Offset(cx + saOffX + 5, cy + saOffY + 90),
        Offset(cx + saOffX - 20, cy + saOffY + 70),
        Offset(cx + saOffX - 30, cy + saOffY + 30),
      ];
      _drawContinent(canvas, sa, landColor);

      // Europe/Africa
      final eaOffX = w * 0.16 * sep;
      final ea = [
        Offset(cx + eaOffX - 5, cy - 75),
        Offset(cx + eaOffX + 30, cy - 70),
        Offset(cx + eaOffX + 25, cy - 40),
        Offset(cx + eaOffX + 35, cy + 10),
        Offset(cx + eaOffX + 20, cy + 80),
        Offset(cx + eaOffX - 5, cy + 85),
        Offset(cx + eaOffX - 20, cy + 40),
        Offset(cx + eaOffX - 15, cy - 30),
      ];
      _drawContinent(canvas, ea, landColor);

      // Asia
      final asiaOffX = w * 0.28 * sep;
      final asia = [
        Offset(cx + asiaOffX + 20, cy - 80),
        Offset(cx + asiaOffX + 80, cy - 55),
        Offset(cx + asiaOffX + 75, cy - 10),
        Offset(cx + asiaOffX + 50, cy + 20),
        Offset(cx + asiaOffX + 15, cy + 5),
        Offset(cx + asiaOffX + 10, cy - 40),
      ];
      _drawContinent(canvas, asia, landColor);

      // Australia
      final ausOffX = w * 0.32 * sep;
      final ausOffY = h * 0.18 * sep;
      final aus = [
        Offset(cx + ausOffX + 30, cy + ausOffY + 20),
        Offset(cx + ausOffX + 65, cy + ausOffY + 15),
        Offset(cx + ausOffX + 70, cy + ausOffY + 50),
        Offset(cx + ausOffX + 45, cy + ausOffY + 60),
        Offset(cx + ausOffX + 25, cy + ausOffY + 45),
      ];
      _drawContinent(canvas, aus, landColor);

      // --- Fossil match dots: Mesosaurus (SA - Africa) ---
      final fossilAlpha = (1 - tc * 1.5).clamp(0.0, 1.0);
      if (fossilAlpha > 0) {
        // Connect same fossil locations
        final fosP1 = Offset(cx + saOffX + 15, cy + saOffY + 30);
        final fosP2 = Offset(cx + eaOffX - 8, cy + 15);
        canvas.drawCircle(fosP1, 4, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: fossilAlpha));
        canvas.drawCircle(fosP2, 4, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: fossilAlpha));
        canvas.drawLine(fosP1, fosP2, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: fossilAlpha * 0.6)..strokeWidth = 1.5..style = PaintingStyle.stroke);
        if (fossilAlpha > 0.5) {
          _label(canvas, '화석 일치', Offset(cx + naOffX - 65, cy + naOffY + 26), fs: 7, col: const Color(0xFFFF6B35));
        }
      }

      // Mountain chain continuity (Appalachian - Caledonian)
      if (tc < 0.5) {
        final mtnAlpha = (1 - tc * 2).clamp(0.0, 1.0);
        canvas.drawLine(
          Offset(cx + naOffX - 5, cy + naOffY - 50),
          Offset(cx + eaOffX + 5, cy - 55),
          Paint()..color = const Color(0xFF64FF8C).withValues(alpha: mtnAlpha * 0.7)..strokeWidth = 2.5..style = PaintingStyle.stroke,
        );
        if (mtnAlpha > 0.4) {
          _label(canvas, '산맥 연속', Offset(cx - 20, cy - 72), fs: 7, col: const Color(0xFF64FF8C));
        }
      }
    } else {
      // Pangaea
      final pangaea = [
        Offset(cx - 80, cy - 90),
        Offset(cx + 85, cy - 80),
        Offset(cx + 90, cy - 20),
        Offset(cx + 70, cy + 50),
        Offset(cx + 30, cy + 90),
        Offset(cx - 30, cy + 85),
        Offset(cx - 75, cy + 40),
        Offset(cx - 90, cy - 10),
      ];
      _drawContinent(canvas, pangaea, pangaeaColor);
      _label(canvas, '판게아', Offset(cx - 20, cy - 8), fs: 13, col: const Color(0xFFE0F4FF));
    }

    // Time line at bottom
    final barY = h * 0.86;
    final barW = w * 0.8;
    final barX = (w - barW) / 2;
    canvas.drawLine(Offset(barX, barY), Offset(barX + barW, barY),
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1);
    // Marker
    final markerX = barX + (1 - t) * barW;
    canvas.drawCircle(Offset(markerX, barY), 5, Paint()..color = const Color(0xFF00D4FF));
    _label(canvas, '현재', Offset(barX - 4, barY + 6), fs: 7);
    _label(canvas, '250 Ma', Offset(barX + barW - 24, barY + 6), fs: 7);
    _label(canvas, '${timeAge.toStringAsFixed(0)} Ma', Offset(markerX - 12, barY - 14), fs: 9, col: const Color(0xFF00D4FF));

    // Stage label
    final stage = t < 0.2 ? '현재 대륙' : (t < 0.6 ? '로라시아+곤드와나' : (t < 0.9 ? '분리 중' : '판게아'));
    _label(canvas, stage, Offset(8, 8), fs: 9, col: const Color(0xFFE0F4FF));
    _label(canvas, '이동 속도: ~5 cm/yr', Offset(w - 100, 8), fs: 7, col: const Color(0xFF5A8A9A));
  }

  @override
  bool shouldRepaint(covariant _ContinentalDriftScreenPainter oldDelegate) => true;
}
