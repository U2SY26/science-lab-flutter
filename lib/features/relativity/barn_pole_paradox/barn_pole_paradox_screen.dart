import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class BarnPoleParadoxScreen extends StatefulWidget {
  const BarnPoleParadoxScreen({super.key});
  @override
  State<BarnPoleParadoxScreen> createState() => _BarnPoleParadoxScreenState();
}

class _BarnPoleParadoxScreenState extends State<BarnPoleParadoxScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _poleSpeed = 0.8;
  double _gamma = 1, _contractedPole = 10, _contractedBarn = 10;

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
      _gamma = 1.0 / math.sqrt(1.0 - _poleSpeed * _poleSpeed);
      _contractedPole = 10.0 / _gamma;
      _contractedBarn = 10.0 / _gamma;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _poleSpeed = 0.8;
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
          Text('상대성이론 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('헛간-막대 역설', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성이론 시뮬레이션',
          title: '헛간-막대 역설',
          formula: "L' = L/\u03B3",
          formulaDescription: '동시성의 상대성으로 헛간-막대 역설을 해결합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BarnPoleParadoxScreenPainter(
                time: _time,
                poleSpeed: _poleSpeed,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '막대 속도 (c)',
                value: _poleSpeed,
                min: 0.5,
                max: 0.99,
                step: 0.01,
                defaultValue: 0.8,
                formatValue: (v) => '${v.toStringAsFixed(2)} c',
                onChanged: (v) => setState(() => _poleSpeed = v),
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
          _V('γ', '${_gamma.toStringAsFixed(2)}'),
          _V('수축된 막대', '${_contractedPole.toStringAsFixed(1)} m'),
          _V('수축된 헛간', '${_contractedBarn.toStringAsFixed(1)} m'),
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

class _BarnPoleParadoxScreenPainter extends CustomPainter {
  final double time;
  final double poleSpeed;

  _BarnPoleParadoxScreenPainter({
    required this.time,
    required this.poleSpeed,
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

  void _drawBarn(Canvas canvas, double left, double top, double barnW, double barnH, Color color) {
    // Floor & walls
    final wallP = Paint()..color = color..strokeWidth = 1.8..style = PaintingStyle.stroke;
    final fillP = Paint()..color = color.withValues(alpha: 0.1);
    canvas.drawRect(Rect.fromLTWH(left, top, barnW, barnH), fillP);
    canvas.drawRect(Rect.fromLTWH(left, top, barnW, barnH), wallP);
    // Roof triangle
    final roofPath = Path();
    roofPath.moveTo(left, top);
    roofPath.lineTo(left + barnW / 2, top - barnH * 0.35);
    roofPath.lineTo(left + barnW, top);
    canvas.drawPath(roofPath, wallP);
    // Doors (open) on both ends
    canvas.drawLine(Offset(left, top), Offset(left, top + barnH), wallP);
    canvas.drawLine(Offset(left + barnW, top), Offset(left + barnW, top + barnH), wallP);
  }

  void _drawPole(Canvas canvas, double left, double top, double poleLen, double poleH, Color color) {
    final poleRect = Rect.fromLTWH(left, top, poleLen, poleH);
    canvas.drawRect(poleRect, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawRect(poleRect, Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke);
    // End caps
    canvas.drawCircle(Offset(left, top + poleH / 2), 4, Paint()..color = color);
    canvas.drawCircle(Offset(left + poleLen, top + poleH / 2), 4, Paint()..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final v = poleSpeed.clamp(0.5, 0.99);
    final gamma = 1.0 / math.sqrt(1.0 - v * v);
    const L0 = 10.0; // rest length (both barn and pole, same L0 for paradox)

    // Contracted lengths
    final poleContracted = L0 / gamma;  // pole contracted in barn frame
    final barnContracted = L0 / gamma;  // barn contracted in pole frame

    _lbl(canvas, '헛간-막대 역설 (동시성의 상대성)', Offset(w / 2, 12),
        const Color(0xFF00D4FF), 10, fw: FontWeight.bold);

    // ===== Panel sizing: top = barn frame, bottom = pole frame =====
    final panH = (h - 28.0) / 2 - 6;
    final panTop1 = 24.0;
    final panTop2 = panTop1 + panH + 12;
    final scalePixPerUnit = (w * 0.55) / L0; // pixels per unit length

    // Shared barn display width
    final barnDisplayW = L0 * scalePixPerUnit;
    final poleRestW = L0 * scalePixPerUnit;
    final poleContractedW = poleContracted * scalePixPerUnit;
    final barnContractedW = barnContracted * scalePixPerUnit;

    // Animate pole moving through barn
    final animCycle = (time * 0.5) % 3.0; // 0..3
    // normalised position 0=enter, 1=inside, 2=exit
    final polePos = (animCycle / 3.0); // 0..1 → left margin to right margin

    final barnLeftX = w * 0.22;
    final poleBaseY = panTop1 + panH * 0.32;
    final poleH2 = panH * 0.28;
    final barnTopY = panTop1 + panH * 0.1;
    final barnH2 = panH * 0.55;

    // ====== TOP PANEL: Barn rest frame ======
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(4, panTop1, w - 8, panH), const Radius.circular(6)),
        Paint()..color = const Color(0xFF0A1520));
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(4, panTop1, w - 8, panH), const Radius.circular(6)),
        Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.2)..strokeWidth = 1..style = PaintingStyle.stroke);

    _lbl(canvas, '헛간 기준계 (Barn frame)', Offset(w / 2, panTop1 + 9),
        const Color(0xFF00D4FF), 9, fw: FontWeight.bold);

    // Barn (rest length L0)
    _drawBarn(canvas, barnLeftX, barnTopY, barnDisplayW, barnH2, const Color(0xFF00D4FF));
    _lbl(canvas, 'L₀=${L0.toStringAsFixed(0)}', Offset(barnLeftX + barnDisplayW / 2, barnTopY + barnH2 + 9),
        const Color(0xFF00D4FF), 8);

    // Pole (contracted: L0/γ) moving through
    final poleTravelRange = barnDisplayW + poleContractedW;
    final poleCurX = barnLeftX - poleContractedW + polePos * poleTravelRange;
    _drawPole(canvas, poleCurX, poleBaseY, poleContractedW, poleH2, const Color(0xFFFF6B35));
    _lbl(canvas, "L'=L₀/γ=${poleContracted.toStringAsFixed(1)}",
        Offset(poleCurX + poleContractedW / 2, poleBaseY + poleH2 + 9),
        const Color(0xFFFF6B35), 8);

    // Speed arrow
    canvas.drawLine(
        Offset(poleCurX + poleContractedW + 2, poleBaseY + poleH2 / 2),
        Offset(poleCurX + poleContractedW + 18, poleBaseY + poleH2 / 2),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5);
    canvas.drawLine(
        Offset(poleCurX + poleContractedW + 12, poleBaseY + poleH2 / 2 - 4),
        Offset(poleCurX + poleContractedW + 18, poleBaseY + poleH2 / 2),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5);
    canvas.drawLine(
        Offset(poleCurX + poleContractedW + 12, poleBaseY + poleH2 / 2 + 4),
        Offset(poleCurX + poleContractedW + 18, poleBaseY + poleH2 / 2),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5);

    // "Fits inside!" label when pole is fully inside
    final insideBarn = poleCurX >= barnLeftX && (poleCurX + poleContractedW) <= (barnLeftX + barnDisplayW);
    if (insideBarn) {
      _lbl(canvas, '막대가 안에 들어감!', Offset(barnLeftX + barnDisplayW / 2, panTop1 + panH - 10),
          const Color(0xFF64FF8C), 9, fw: FontWeight.bold);
    }

    // Size comparison label
    _lbl(canvas, 'γ=${gamma.toStringAsFixed(2)}  v=${v.toStringAsFixed(2)}c',
        Offset(w * 0.82, panTop1 + panH * 0.5),
        const Color(0xFF5A8A9A), 8);

    // ====== BOTTOM PANEL: Pole rest frame ======
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(4, panTop2, w - 8, panH), const Radius.circular(6)),
        Paint()..color = const Color(0xFF0A1520));
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(4, panTop2, w - 8, panH), const Radius.circular(6)),
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.2)..strokeWidth = 1..style = PaintingStyle.stroke);

    _lbl(canvas, '막대 기준계 (Pole frame)', Offset(w / 2, panTop2 + 9),
        const Color(0xFFFF6B35), 9, fw: FontWeight.bold);

    // Pole at rest (full length L0)
    final pole2Left = w * 0.10;
    final pole2Top = panTop2 + panH * 0.32;
    _drawPole(canvas, pole2Left, pole2Top, poleRestW, poleH2, const Color(0xFFFF6B35));
    _lbl(canvas, "L₀=${L0.toStringAsFixed(0)} (정지)",
        Offset(pole2Left + poleRestW / 2, pole2Top + poleH2 + 9),
        const Color(0xFFFF6B35), 8);

    // Barn (contracted: L0/γ) moving opposite direction
    final barn2TravelRange = poleRestW + barnContractedW;
    final barn2RightEdge = pole2Left + poleRestW + barnContractedW +
        (1.0 - polePos) * barn2TravelRange;
    final barn2Left = barn2RightEdge - barnContractedW;
    final barn2Top = panTop2 + panH * 0.1;
    if (barn2Left > 0 && barn2Left < w) {
      _drawBarn(canvas, barn2Left, barn2Top, barnContractedW, barnH2, const Color(0xFF00D4FF));
      _lbl(canvas, "L'=L₀/γ=${barnContracted.toStringAsFixed(1)}",
          Offset(barn2Left + barnContractedW / 2, barn2Top + barnH2 + 9),
          const Color(0xFF00D4FF), 8);
    }

    // "Doesn't fit" label
    _lbl(canvas, '막대가 헛간보다 길어 보임!', Offset(w / 2, panTop2 + panH - 10),
        const Color(0xFFFFD700), 9, fw: FontWeight.bold);

    // ===== Bottom formula =====
    _lbl(canvas, "L' = L₀/γ = L₀√(1-v²/c²)  γ=${gamma.toStringAsFixed(2)}",
        Offset(w / 2, h - 5),
        const Color(0xFF5A8A9A), 8);
  }

  @override
  bool shouldRepaint(covariant _BarnPoleParadoxScreenPainter oldDelegate) => true;
}
