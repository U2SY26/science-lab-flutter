import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class GasLawsScreen extends StatefulWidget {
  const GasLawsScreen({super.key});
  @override
  State<GasLawsScreen> createState() => _GasLawsScreenState();
}

class _GasLawsScreenState extends State<GasLawsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _pressure = 1.0;
  double _temperature = 300.0;
  double _volume = 24.6;

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
      final n = 1.0, R = 0.0821;
      _volume = n * R * _temperature / _pressure;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _pressure = 1.0;
      _temperature = 300.0;
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
          Text('화학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('기체 법칙', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '기체 법칙',
          formula: 'PV = nRT',
          formulaDescription: '보일, 샤를, 결합 기체 법칙을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GasLawsScreenPainter(
                time: _time,
                pressure: _pressure,
                temperature: _temperature,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '압력 P (atm)',
                value: _pressure,
                min: 0.5,
                max: 5.0,
                step: 0.1,
                defaultValue: 1.0,
                formatValue: (v) => '${v.toStringAsFixed(1)} atm',
                onChanged: (v) => setState(() => _pressure = v),
              ),
              advancedControls: [
            SimSlider(
                label: '온도 T (K)',
                value: _temperature,
                min: 200.0,
                max: 600.0,
                defaultValue: 300.0,
                formatValue: (v) => '${v.toInt()} K',
                onChanged: (v) => setState(() => _temperature = v),
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
          _V('부피 V', '${_volume.toStringAsFixed(1)} L'),
          _V('P', '${_pressure.toStringAsFixed(1)} atm'),
          _V('T', '${_temperature.toInt()} K'),
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

class _GasLawsScreenPainter extends CustomPainter {
  final double time;
  final double pressure;
  final double temperature;

  _GasLawsScreenPainter({
    required this.time,
    required this.pressure,
    required this.temperature,
  });

  void _lbl(Canvas canvas, String text, Offset center, Color color, double sz,
      {FontWeight fw = FontWeight.normal}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: sz, fontFamily: 'monospace', fontWeight: fw)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final P = pressure.clamp(0.5, 5.0);
    final T = temperature.clamp(200.0, 600.0);
    const n = 1.0, R = 0.0821;
    final V = n * R * T / P;

    _lbl(canvas, '이상 기체 법칙  PV = nRT', Offset(w / 2, 12),
        const Color(0xFF00D4FF), 11, fw: FontWeight.bold);

    final axisP = Paint()..color = const Color(0xFF2A4050)..strokeWidth = 1..style = PaintingStyle.stroke;

    // ===== LEFT: Gas molecule box (40% width) =====
    final boxL = 8.0, boxT = 24.0, boxW = w * 0.40, boxH = h * 0.52;
    final boxB = boxT + boxH;

    // Box walls – thickness represents pressure
    final wallThick = (P / 5.0 * 4 + 1).clamp(1.0, 5.0);
    canvas.drawRect(Rect.fromLTWH(boxL, boxT, boxW, boxH),
        Paint()..color = const Color(0xFF1A3040));
    canvas.drawRect(Rect.fromLTWH(boxL, boxT, boxW, boxH),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6)
            ..strokeWidth = wallThick
            ..style = PaintingStyle.stroke);

    // Molecules moving inside the box
    final rng = math.Random(7);
    final numMols = 12;
    for (int i = 0; i < numMols; i++) {
      final seed = i * 1.37;
      final speed = (T / 300.0) * 0.8 + 0.2;
      final mx = boxL + 6 + ((rng.nextDouble() * (boxW - 12) +
              math.sin(time * speed + seed) * (boxW * 0.18)).abs() % (boxW - 12));
      final my = boxT + 6 + ((rng.nextDouble() * (boxH - 12) +
              math.cos(time * speed * 0.9 + seed * 2) * (boxH * 0.18)).abs() % (boxH - 12));
      // Color by speed
      final molColor = Color.lerp(
          const Color(0xFF00D4FF), const Color(0xFFFF6B35), (T - 200) / 400)!;
      canvas.drawCircle(Offset(mx, my), 4, Paint()..color = molColor.withValues(alpha: 0.85));
    }

    // Labels inside box
    _lbl(canvas, 'P=${P.toStringAsFixed(1)} atm', Offset(boxL + boxW / 2, boxB + 10),
        const Color(0xFF00D4FF), 9);
    _lbl(canvas, 'T=${T.toInt()} K', Offset(boxL + boxW / 2, boxB + 22),
        const Color(0xFFFF6B35), 9);
    _lbl(canvas, 'V=${V.toStringAsFixed(1)} L', Offset(boxL + boxW / 2, boxB + 34),
        const Color(0xFF64FF8C), 9);

    final gL = w * 0.45, gT = 24.0, gR = w - 6.0;
    final gW = gR - gL;

    // ===== RIGHT TOP: Boyle's Law P-V graph =====
    final bTop = gT, bBot = gT + (h - gT) * 0.32;
    final bH = bBot - bTop - 12;

    _lbl(canvas, '보일: PV=const (T고정)', Offset(gL + gW / 2, bTop + 5),
        const Color(0xFF64FF8C), 8);
    canvas.drawLine(Offset(gL, bBot - 4), Offset(gR, bBot - 4), axisP);
    canvas.drawLine(Offset(gL, bTop + 12), Offset(gL, bBot - 4), axisP);
    _lbl(canvas, 'V', Offset(gR, bBot), const Color(0xFF5A8A9A), 7);
    _lbl(canvas, 'P', Offset(gL - 6, bTop + 16), const Color(0xFF5A8A9A), 7);

    final boylePath = Path();
    const pvConst = 1.0 * 0.0821 * 300.0; // n*R*T at T=300
    bool boyleFirst = true;
    for (double v = 2.0; v <= 50.0; v += 0.5) {
      final p2 = pvConst / v;
      if (p2 > 6.0 || p2 < 0.3) continue;
      final px = gL + ((v - 2) / 48.0) * gW;
      final py = bBot - 4 - ((p2 - 0.3) / 5.7) * (bH - 4);
      if (boyleFirst) { boylePath.moveTo(px, py); boyleFirst = false; } else { boylePath.lineTo(px, py); }
    }
    canvas.drawPath(boylePath,
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.8..style = PaintingStyle.stroke);
    // Current state dot
    final curBx = gL + ((V - 2) / 48.0).clamp(0, 1) * gW;
    final curBy = bBot - 4 - ((P - 0.3) / 5.7).clamp(0, 1) * (bH - 4);
    canvas.drawCircle(Offset(curBx, curBy), 5, Paint()..color = const Color(0xFF64FF8C));

    // ===== RIGHT MID: Charles's Law V-T graph =====
    final cTop = bBot + 8, cBot = cTop + (h - gT) * 0.30;
    final cH = cBot - cTop - 12;

    _lbl(canvas, "샤를: V/T=const (P고정)", Offset(gL + gW / 2, cTop + 5),
        const Color(0xFF00D4FF), 8);
    canvas.drawLine(Offset(gL, cBot - 4), Offset(gR, cBot - 4), axisP);
    canvas.drawLine(Offset(gL, cTop + 12), Offset(gL, cBot - 4), axisP);
    _lbl(canvas, 'T', Offset(gR, cBot), const Color(0xFF5A8A9A), 7);
    _lbl(canvas, 'V', Offset(gL - 6, cTop + 16), const Color(0xFF5A8A9A), 7);

    final charlesPath = Path();
    final vConst = V / T; // V/T at current state
    bool charlesFirst = true;
    for (double t2 = 100.0; t2 <= 700.0; t2 += 10) {
      final v2 = vConst * t2;
      final px = gL + ((t2 - 100) / 600.0) * gW;
      final py = cBot - 4 - (v2 / 60.0).clamp(0, 1) * (cH - 4);
      if (charlesFirst) { charlesPath.moveTo(px, py); charlesFirst = false; } else { charlesPath.lineTo(px, py); }
    }
    canvas.drawPath(charlesPath,
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.8..style = PaintingStyle.stroke);
    final curCx = gL + ((T - 100) / 600.0).clamp(0, 1) * gW;
    final curCy = cBot - 4 - (V / 60.0).clamp(0, 1) * (cH - 4);
    canvas.drawCircle(Offset(curCx, curCy), 5, Paint()..color = const Color(0xFF00D4FF));

    // ===== RIGHT BOTTOM: Gay-Lussac P-T =====
    final gTop2 = cBot + 8, gBot2 = h - 6.0;
    final gH2 = gBot2 - gTop2 - 12;

    _lbl(canvas, '게이-뤼삭: P/T=const (V고정)', Offset(gL + gW / 2, gTop2 + 5),
        const Color(0xFFFF6B35), 8);
    canvas.drawLine(Offset(gL, gBot2 - 4), Offset(gR, gBot2 - 4), axisP);
    canvas.drawLine(Offset(gL, gTop2 + 12), Offset(gL, gBot2 - 4), axisP);
    _lbl(canvas, 'T', Offset(gR, gBot2), const Color(0xFF5A8A9A), 7);
    _lbl(canvas, 'P', Offset(gL - 6, gTop2 + 16), const Color(0xFF5A8A9A), 7);

    final gayPath = Path();
    final ptConst = P / T;
    bool gayFirst = true;
    for (double t2 = 100.0; t2 <= 700.0; t2 += 10) {
      final p2 = ptConst * t2;
      final px = gL + ((t2 - 100) / 600.0) * gW;
      final py = gBot2 - 4 - (p2 / 6.0).clamp(0, 1) * (gH2 - 4);
      if (gayFirst) { gayPath.moveTo(px, py); gayFirst = false; } else { gayPath.lineTo(px, py); }
    }
    canvas.drawPath(gayPath,
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.8..style = PaintingStyle.stroke);
    final curGx = gL + ((T - 100) / 600.0).clamp(0, 1) * gW;
    final curGy = gBot2 - 4 - (P / 6.0).clamp(0, 1) * (gH2 - 4);
    canvas.drawCircle(Offset(curGx, curGy), 5, Paint()..color = const Color(0xFFFF6B35));

    // Divider line between box and graphs
    canvas.drawLine(Offset(w * 0.43, 24), Offset(w * 0.43, h - 6),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant _GasLawsScreenPainter oldDelegate) => true;
}
