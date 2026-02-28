import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ElNinoScreen extends StatefulWidget {
  const ElNinoScreen({super.key});
  @override
  State<ElNinoScreen> createState() => _ElNinoScreenState();
}

class _ElNinoScreenState extends State<ElNinoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _soi = 0;
  
  double _sstAnomaly = 0; String _phase = "중립";

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
      _sstAnomaly = -_soi * 0.8;
      _phase = _soi < -0.5 ? "엘니뉴" : _soi > 0.5 ? "라니냐" : "중립";
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _soi = 0.0;
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
          const Text('엘니뇨와 라니냐', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '엘니뇨와 라니냐',
          formula: 'SOI = (P_Tahiti - P_Darwin)/σ',
          formulaDescription: '엘니뇨/라니냐 현상과 해수면 온도 변화를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ElNinoScreenPainter(
                time: _time,
                soi: _soi,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'SOI',
                value: _soi,
                min: -3,
                max: 3,
                step: 0.1,
                defaultValue: 0,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _soi = v),
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
          _V('SST', _sstAnomaly.toStringAsFixed(1) + ' °C'),
          _V('위상', _phase),
          _V('SOI', _soi.toStringAsFixed(1)),
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

class _ElNinoScreenPainter extends CustomPainter {
  final double time;
  final double soi;

  _ElNinoScreenPainter({
    required this.time,
    required this.soi,
  });

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    canvas.drawLine(from, to, paint);
    final dir = to - from;
    final len = dir.distance;
    if (len < 1) return;
    final u = dir / len;
    final perp = Offset(-u.dy, u.dx);
    const as_ = 7.0;
    final p1 = to - u * as_ + perp * as_ * 0.4;
    final p2 = to - u * as_ - perp * as_ * 0.4;
    final path = Path()..moveTo(to.dx, to.dy)..lineTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..close();
    canvas.drawPath(path, Paint()..color = paint.color..style = PaintingStyle.fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    const pad = 12.0;
    const titleH = 18.0;

    // Section heights
    final crossH = h * 0.52;  // Pacific cross-section top area
    final graphTop = crossH + 4;
    final graphH = h - graphTop - pad;

    // ── Title ──────────────────────────────────────────────────────────────
    void drawLabel(String text, double x, double y, Color color, double fs, {FontWeight fw = FontWeight.normal}) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fs, fontWeight: fw)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
    }

    final phase = soi < -0.5 ? '엘니뇨' : soi > 0.5 ? '라니냐' : '중립';
    final phaseColor = soi < -0.5 ? const Color(0xFFFF4444) : soi > 0.5 ? const Color(0xFF00D4FF) : const Color(0xFF5A8A9A);
    drawLabel('엘니뇨 / 라니냐  ($phase)', w / 2, titleH / 2 + pad, phaseColor, 10.5, fw: FontWeight.w700);

    // ── Pacific cross-section ───────────────────────────────────────────────
    final secTop = titleH + pad + 4;
    final secBot = crossH - 4;
    final secH = secBot - secTop;
    final secL = pad + 4;
    final secR = w - pad - 4;
    final secW = secR - secL;

    // Ocean floor
    final floorPaint = Paint()..color = const Color(0xFF3A2510)..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTRB(secL, secBot - 8, secR, secBot), floorPaint);

    // SST gradient: soi<0 → warm east; soi>0 → warm west
    // Warm water position shifts with SOI
    final warmCenter = 0.5 - soi * 0.15;  // 0=west, 1=east
    for (int i = 0; i <= 40; i++) {
      final t = i / 40.0;
      final dist = (t - warmCenter).abs();
      final warmness = (1 - dist * 2.0).clamp(0.0, 1.0);
      final r = (0x00 + warmness * 0xFF).round().clamp(0, 255);
      final b = (0xAA - warmness * 0x88).round().clamp(0, 255);
      final waterColor = Color.fromARGB(200, r, 0x44, b);
      final x = secL + t * secW;
      final thermoclineY = secTop + secH * (0.35 + soi * 0.06 * (t - 0.5));
      canvas.drawRect(
        Rect.fromLTRB(x, secTop, x + secW / 40 + 1, thermoclineY),
        Paint()..color = waterColor,
      );
      // Cold deep water below thermocline
      canvas.drawRect(
        Rect.fromLTRB(x, thermoclineY, x + secW / 40 + 1, secBot - 8),
        Paint()..color = const Color(0xFF003366).withValues(alpha: 0.7),
      );
    }

    // Thermocline line
    final thermoPaint = Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final thermoPath = Path();
    for (int i = 0; i <= 60; i++) {
      final t = i / 60.0;
      final x = secL + t * secW;
      final y = secTop + secH * (0.35 + soi * 0.06 * (t - 0.5));
      if (i == 0) { thermoPath.moveTo(x, y); } else { thermoPath.lineTo(x, y); }
    }
    canvas.drawPath(thermoPath, thermoPaint);

    // Trade wind arrows (direction depends on SOI)
    final windStrength = soi.abs().clamp(0.2, 1.0);
    final windDir = soi >= 0 ? -1.0 : 1.0;  // normal/la nina: west→east, el nino: reversed
    final windPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final windY = secTop + secH * 0.12;
    for (int i = 0; i < 4; i++) {
      final baseX = secL + secW * (0.1 + i * 0.22);
      final dx = secW * 0.14 * windDir * windStrength;
      _drawArrow(canvas, Offset(baseX, windY), Offset(baseX + dx, windY), windPaint);
    }
    drawLabel(soi >= 0 ? '무역풍 →' : '← 약화', w / 2, windY - 8, const Color(0xFFFFD700), 8);

    // Upwelling (cold) on east side when normal/la nina
    if (soi > -0.3) {
      final upPaint = Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.7)..strokeWidth = 2..style = PaintingStyle.stroke;
      for (int i = 0; i < 3; i++) {
        final ux = secR - 16 - i * 10.0;
        _drawArrow(canvas, Offset(ux, secBot - 20), Offset(ux, secTop + secH * 0.2), upPaint);
      }
      drawLabel('냉용승', secR - 18, secTop + secH * 0.5, const Color(0xFF00D4FF), 7.5);
    }

    // Land labels
    drawLabel('서태평양\n(인도네시아)', secL + 28, secBot - 20, const Color(0xFFE0F4FF), 7.5);
    drawLabel('동태평양\n(남미)', secR - 22, secBot - 20, const Color(0xFFE0F4FF), 7.5);
    drawLabel('온도약층', secW * 0.3 + secL, secTop + secH * 0.43, const Color(0xFF00D4FF), 7.5);

    // ── SST Anomaly bar chart (bottom) ─────────────────────────────────────
    if (graphH > 20) {
      final gL = pad + 4;
      final gR = w - pad - 4;
      final gW = gR - gL;
      final gMid = graphTop + graphH * 0.5;

      final axPaint = Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1;
      canvas.drawLine(Offset(gL, gMid), Offset(gR, gMid), axPaint);

      // SOI scale bar
      final barW = gW * 0.6;
      final barX = gL + gW * 0.2;
      final barH = graphH * 0.35;
      final soiNorm = (soi / 3.0).clamp(-1.0, 1.0);
      final barColor = soiNorm < 0 ? const Color(0xFFFF4444) : const Color(0xFF00D4FF);
      canvas.drawRect(
        Rect.fromLTRB(
          barX + barW / 2,
          soiNorm < 0 ? gMid : gMid - barH * soiNorm,
          barX + barW / 2 + barW / 2 * soiNorm.abs(),
          soiNorm < 0 ? gMid + barH * soiNorm.abs() : gMid,
        ),
        Paint()..color = barColor.withValues(alpha: 0.7),
      );
      drawLabel('SOI: ${soi.toStringAsFixed(1)}  ($phase)', w / 2, graphTop + graphH * 0.15, barColor, 9, fw: FontWeight.w600);
      drawLabel('-3 라니냐', gL + 20, gMid + graphH * 0.38, const Color(0xFF00D4FF), 7.5);
      drawLabel('+3 엘니뇨', gR - 20, gMid + graphH * 0.38, const Color(0xFFFF4444), 7.5);
    }
  }

  @override
  bool shouldRepaint(covariant _ElNinoScreenPainter oldDelegate) => true;
}
