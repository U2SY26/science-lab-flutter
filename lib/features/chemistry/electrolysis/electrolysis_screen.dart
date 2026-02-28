import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class ElectrolysisScreen extends StatefulWidget {
  const ElectrolysisScreen({super.key});
  @override
  State<ElectrolysisScreen> createState() => _ElectrolysisScreenState();
}

class _ElectrolysisScreenState extends State<ElectrolysisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _current = 1;
  
  double _mass = 0, _volume = 0;

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
      _mass = 63.55 * _current * _time / (2 * 96485);
      _volume = 22400 * _current * _time / (2 * 96485);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _current = 1.0;
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
          const Text('전기분해', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '전기분해',
          formula: 'm = MIt/zF',
          formulaDescription: '패러데이 법칙에 따른 전기분해를 시뮬레이션합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ElectrolysisScreenPainter(
                time: _time,
                current: _current,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '전류 (A)',
                value: _current,
                min: 0.1,
                max: 10,
                step: 0.1,
                defaultValue: 1,
                formatValue: (v) => '${v.toStringAsFixed(1)} A',
                onChanged: (v) => setState(() => _current = v),
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
          _V('석출량', '${(_mass * 1000).toStringAsFixed(2)} mg'),
          _V('기체량', '${_volume.toStringAsFixed(2)} mL'),
          _V('Q', '${(_current * _time).toStringAsFixed(1)} C'),
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

class _ElectrolysisScreenPainter extends CustomPainter {
  final double time;
  final double current;

  _ElectrolysisScreenPainter({
    required this.time,
    required this.current,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    final cx = w / 2;

    // Electrolytic cell dimensions
    final cellLeft = w * 0.12;
    final cellRight = w * 0.88;
    final cellTop = h * 0.15;
    final cellBottom = h * 0.82;
    final cellW = cellRight - cellLeft;
    final cellH = cellBottom - cellTop;

    // Solution fill (CuSO4 blue tint)
    canvas.drawRect(
      Rect.fromLTRB(cellLeft + 2, cellTop + 2, cellRight - 2, cellBottom - 2),
      Paint()..color = const Color(0xFF0A2040).withValues(alpha: 0.8),
    );

    // Cell walls
    final wallPaint = Paint()
      ..color = const Color(0xFF5A8A9A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final cellPath = Path()
      ..moveTo(cellLeft, cellTop)
      ..lineTo(cellLeft, cellBottom)
      ..lineTo(cellRight, cellBottom)
      ..lineTo(cellRight, cellTop);
    canvas.drawPath(cellPath, wallPaint);

    // Electrodes
    final anodeX = cellLeft + cellW * 0.2;
    final cathodeX = cellLeft + cellW * 0.8;
    final electrodeTop = cellTop + 8;
    final electrodeBot = cellBottom - 8;

    // Anode (orange/+)
    canvas.drawRect(
      Rect.fromLTWH(anodeX - 4, electrodeTop, 8, electrodeBot - electrodeTop),
      Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.25)..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      Rect.fromLTWH(anodeX - 4, electrodeTop, 8, electrodeBot - electrodeTop),
      Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.5..style = PaintingStyle.stroke,
    );

    // Cathode (cyan/-)
    canvas.drawRect(
      Rect.fromLTWH(cathodeX - 4, electrodeTop, 8, electrodeBot - electrodeTop),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.25)..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      Rect.fromLTWH(cathodeX - 4, electrodeTop, 8, electrodeBot - electrodeTop),
      Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5..style = PaintingStyle.stroke,
    );

    // Electrode labels
    void label(String t, double x, double y, Color c) {
      final tp = TextPainter(
        text: TextSpan(text: t, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y));
    }
    label('양극(+)', anodeX, cellTop - 14, const Color(0xFFFF6B35));
    label('산화', anodeX, cellTop - 4, const Color(0xFFFF6B35));
    label('음극(-)', cathodeX, cellTop - 14, const Color(0xFF00D4FF));
    label('환원', cathodeX, cellTop - 4, const Color(0xFF00D4FF));

    // Cu deposit growing on cathode (green tint)
    final depositH = (63.55 * current * time / (2 * 96485) * 1e6).clamp(0.0, cellH * 0.4);
    if (depositH > 1) {
      canvas.drawRect(
        Rect.fromLTWH(cathodeX - 4, electrodeBot - depositH, 8, depositH),
        Paint()..color = const Color(0xFFB87333).withValues(alpha: 0.7)..style = PaintingStyle.fill,
      );
    }

    // Ions moving
    final rand = math.Random(42);
    final int ionCount = (6 + current * 2).toInt().clamp(4, 16);
    for (int i = 0; i < ionCount; i++) {
      final phase = (time * 0.5 + i * 0.37) % 1.0;
      // Cations (Cu2+) move toward cathode
      final isCation = (i % 2 == 0);
      final ionX = isCation
          ? anodeX + (cathodeX - anodeX) * phase
          : cathodeX - (cathodeX - anodeX) * phase;
      final ionY = cellTop + 10 + (cellH - 20) * rand.nextDouble();
      final ionColor = isCation ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35);
      canvas.drawCircle(Offset(ionX, ionY), 5,
          Paint()..color = ionColor.withValues(alpha: 0.7)..style = PaintingStyle.fill);
      final ionLabel = isCation ? 'Cu²⁺' : 'SO₄²⁻';
      final ltp = TextPainter(
        text: TextSpan(text: ionLabel, style: TextStyle(color: ionColor, fontSize: 5)),
        textDirection: TextDirection.ltr,
      )..layout();
      ltp.paint(canvas, Offset(ionX - ltp.width / 2, ionY + 6));
    }

    // Bubbles on anode (O2)
    for (int b = 0; b < 4; b++) {
      final bPhase = (time * 0.7 + b * 0.25) % 1.0;
      final bY = electrodeBot - cellH * 0.1 - cellH * 0.6 * bPhase;
      final bX = anodeX + (b % 2 == 0 ? -8.0 : 8.0);
      canvas.drawCircle(Offset(bX, bY), 4,
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.4)..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(bX, bY), 4,
          Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }

    // External circuit wires + battery
    final wireY = cellTop - 22;
    canvas.drawLine(Offset(anodeX, electrodeTop), Offset(anodeX, wireY), wallPaint);
    canvas.drawLine(Offset(cathodeX, electrodeTop), Offset(cathodeX, wireY), wallPaint);
    canvas.drawLine(Offset(anodeX, wireY), Offset(cx - 18, wireY), wallPaint);
    canvas.drawLine(Offset(cathodeX, wireY), Offset(cx + 18, wireY), wallPaint);
    // Battery symbol
    canvas.drawLine(Offset(cx - 18, wireY - 6), Offset(cx - 18, wireY + 6),
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 3.0);
    canvas.drawLine(Offset(cx + 18, wireY - 3), Offset(cx + 18, wireY + 3),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx - 18, wireY), Offset(cx + 18, wireY),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.3)..strokeWidth = 0.5);
    label('${current.toStringAsFixed(1)} A', cx, wireY - 16, const Color(0xFFE0F4FF));

    // Faraday info at bottom
    final massStr = (63.55 * current * time / (2 * 96485) * 1000).toStringAsFixed(3);
    label('Cu 석출: $massStr mg  |  m = MIt/zF', cx, cellBottom + 6, const Color(0xFF5A8A9A));
  }

  @override
  bool shouldRepaint(covariant _ElectrolysisScreenPainter oldDelegate) => true;
}
