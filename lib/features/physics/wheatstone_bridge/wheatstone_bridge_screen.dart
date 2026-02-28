import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class WheatstoneBridgeScreen extends StatefulWidget {
  const WheatstoneBridgeScreen({super.key});
  @override
  State<WheatstoneBridgeScreen> createState() => _WheatstoneBridgeScreenState();
}

class _WheatstoneBridgeScreenState extends State<WheatstoneBridgeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _r1 = 100;
  double _r2 = 200;
  double _r3 = 150.0, _rx = 300.0, _vBridge = 0.0;

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
      _rx = _r3 * (_r2 / _r1);
      _vBridge = 5.0 * (_r2 / (_r1 + _r2) - _r3 / (_r3 + _rx));
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _r1 = 100.0; _r2 = 200.0;
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
          Text('물리 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('휘트스톤 브리지', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '휘트스톤 브리지',
          formula: 'R_x = R₃(R₂/R₁)',
          formulaDescription: '미지 저항을 측정하기 위해 휘트스톤 브리지를 균형합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _WheatstoneBridgeScreenPainter(
                time: _time,
                r1: _r1,
                r2: _r2,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: 'R₁ (Ω)',
                value: _r1,
                min: 10,
                max: 1000,
                step: 10,
                defaultValue: 100,
                formatValue: (v) => v.toStringAsFixed(0) + ' Ω',
                onChanged: (v) => setState(() => _r1 = v),
              ),
              advancedControls: [
            SimSlider(
                label: 'R₂ (Ω)',
                value: _r2,
                min: 10,
                max: 1000,
                step: 10,
                defaultValue: 200,
                formatValue: (v) => v.toStringAsFixed(0) + ' Ω',
                onChanged: (v) => setState(() => _r2 = v),
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
          _V('Rx', _rx.toStringAsFixed(1) + ' Ω'),
          _V('Vₐ', _vBridge.toStringAsFixed(3) + ' V'),
          _V('비율', (_r2 / _r1).toStringAsFixed(2)),
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

class _WheatstoneBridgeScreenPainter extends CustomPainter {
  final double time;
  final double r1;
  final double r2;

  _WheatstoneBridgeScreenPainter({
    required this.time,
    required this.r1,
    required this.r2,
  });

  void _label(Canvas canvas, String text, Offset pos, Color color, double sz,
      {bool bold = false, bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color,
              fontSize: sz,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center ? Offset(pos.dx - tp.width / 2, pos.dy) : pos);
  }

  // Draw a resistor symbol (zigzag) between two points (horizontal or vertical)
  void _drawResistor(Canvas canvas, Offset a, Offset b, Color color) {
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 4) return;
    final nx = dx / len, ny = dy / len;
    final px = -ny, py = nx; // perpendicular
    const zigs = 5;
    const zigW = 5.0;
    final segLen = len / (zigs * 2 + 2);
    final path = Path()..moveTo(a.dx, a.dy);
    path.lineTo(a.dx + nx * segLen, a.dy + ny * segLen);
    for (int i = 0; i < zigs; i++) {
      final sign = (i % 2 == 0) ? 1.0 : -1.0;
      path.lineTo(
          a.dx + nx * (segLen + (i * 2 + 1) * segLen) + px * zigW * sign,
          a.dy + ny * (segLen + (i * 2 + 1) * segLen) + py * zigW * sign);
      path.lineTo(
          a.dx + nx * (segLen + (i * 2 + 2) * segLen),
          a.dy + ny * (segLen + (i * 2 + 2) * segLen));
    }
    path.lineTo(b.dx, b.dy);
    canvas.drawPath(path,
        Paint()..color = color..strokeWidth = 1.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;

    // === Bridge diamond geometry ===
    // 4 nodes: top, left, right, bottom
    final cx = w * 0.5;
    final bridgeTop = Offset(cx, h * 0.10);
    final bridgeLeft = Offset(cx - w * 0.26, h * 0.45);
    final bridgeRight = Offset(cx + w * 0.26, h * 0.45);
    final bridgeBot = Offset(cx, h * 0.80);

    // Battery below bottom node
    final battTop = Offset(cx, h * 0.80);
    final battBot = Offset(cx, h * 0.95);

    // Compute voltages at each node
    // V_top = 5V, V_bot = 0V
    // Left branch: R1 (top→left) + R3 (left→bot)
    // Right branch: R2 (top→right) + R4 (right→bot), R4 = Rx
    const vSupply = 5.0;
    final r3 = 150.0;
    final rx = r3 * (r2 / r1);
    final vLeft = vSupply * r3 / (r1 + r3);
    final vRight = vSupply * rx / (r2 + rx);
    final vBridge = vLeft - vRight; // galvanometer voltage
    final isBalanced = vBridge.abs() < 0.01;

    // Wire color based on voltage
    Color wireColor(double v) {
      final t = (v / vSupply).clamp(0.0, 1.0);
      return Color.lerp(const Color(0xFF003060), const Color(0xFF00D4FF), t)!;
    }

    // Draw wires (thick colored segments showing voltage)
    final wirePaint = Paint()..strokeWidth = 2.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;

    // Top→Left wire (R1 segment)
    wirePaint.color = wireColor((vSupply + vLeft) / 2);
    canvas.drawLine(bridgeTop, bridgeLeft, wirePaint);
    // Top→Right wire (R2 segment)
    wirePaint.color = wireColor((vSupply + vRight) / 2);
    canvas.drawLine(bridgeTop, bridgeRight, wirePaint);
    // Left→Bot wire (R3 segment)
    wirePaint.color = wireColor(vLeft / 2);
    canvas.drawLine(bridgeLeft, bridgeBot, wirePaint);
    // Right→Bot wire (R4/Rx segment)
    wirePaint.color = wireColor(vRight / 2);
    canvas.drawLine(bridgeRight, bridgeBot, wirePaint);

    // Galvanometer wire (middle, muted)
    wirePaint.color = const Color(0xFF5A8A9A).withValues(alpha: isBalanced ? 0.4 : 0.8);
    canvas.drawLine(bridgeLeft, bridgeRight, wirePaint);

    // Battery wire
    wirePaint.color = const Color(0xFF5A8A9A);
    canvas.drawLine(battTop, battBot, wirePaint);
    // Battery symbol
    canvas.drawLine(Offset(cx - 10, h * 0.88), Offset(cx + 10, h * 0.88),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 3);
    canvas.drawLine(Offset(cx - 6, h * 0.91), Offset(cx + 6, h * 0.91),
        Paint()..color = const Color(0xFF00D4FF)..strokeWidth = 1.5);
    _label(canvas, '+', Offset(cx + 12, h * 0.85), const Color(0xFFFF6B35), 9);
    _label(canvas, '−', Offset(cx + 12, h * 0.90), const Color(0xFF5A8A9A), 9);
    _label(canvas, '5V', Offset(cx - 28, h * 0.87), const Color(0xFFE0F4FF), 8);

    // Draw resistors on each arm
    final r1Mid = Offset((bridgeTop.dx + bridgeLeft.dx) / 2, (bridgeTop.dy + bridgeLeft.dy) / 2);
    final r2Mid = Offset((bridgeTop.dx + bridgeRight.dx) / 2, (bridgeTop.dy + bridgeRight.dy) / 2);
    final r3Mid = Offset((bridgeLeft.dx + bridgeBot.dx) / 2, (bridgeLeft.dy + bridgeBot.dy) / 2);
    final r4Mid = Offset((bridgeRight.dx + bridgeBot.dx) / 2, (bridgeRight.dy + bridgeBot.dy) / 2);

    _drawResistor(canvas,
        Offset(bridgeTop.dx * 0.6 + bridgeLeft.dx * 0.4, bridgeTop.dy * 0.6 + bridgeLeft.dy * 0.4),
        Offset(bridgeTop.dx * 0.4 + bridgeLeft.dx * 0.6, bridgeTop.dy * 0.4 + bridgeLeft.dy * 0.6),
        const Color(0xFF00D4FF));
    _label(canvas, 'R₁=${r1.toStringAsFixed(0)}Ω', Offset(r1Mid.dx - 34, r1Mid.dy - 4),
        const Color(0xFF00D4FF), 8);

    _drawResistor(canvas,
        Offset(bridgeTop.dx * 0.6 + bridgeRight.dx * 0.4, bridgeTop.dy * 0.6 + bridgeRight.dy * 0.4),
        Offset(bridgeTop.dx * 0.4 + bridgeRight.dx * 0.6, bridgeTop.dy * 0.4 + bridgeRight.dy * 0.6),
        const Color(0xFFFF6B35));
    _label(canvas, 'R₂=${r2.toStringAsFixed(0)}Ω', Offset(r2Mid.dx + 4, r2Mid.dy - 4),
        const Color(0xFFFF6B35), 8);

    _drawResistor(canvas,
        Offset(bridgeLeft.dx * 0.6 + bridgeBot.dx * 0.4, bridgeLeft.dy * 0.6 + bridgeBot.dy * 0.4),
        Offset(bridgeLeft.dx * 0.4 + bridgeBot.dx * 0.6, bridgeLeft.dy * 0.4 + bridgeBot.dy * 0.6),
        const Color(0xFF00D4FF));
    _label(canvas, 'R₃=${r3.toStringAsFixed(0)}Ω', Offset(r3Mid.dx - 38, r3Mid.dy - 4),
        const Color(0xFF00D4FF), 8);

    _drawResistor(canvas,
        Offset(bridgeRight.dx * 0.6 + bridgeBot.dx * 0.4, bridgeRight.dy * 0.6 + bridgeBot.dy * 0.4),
        Offset(bridgeRight.dx * 0.4 + bridgeBot.dx * 0.6, bridgeRight.dy * 0.4 + bridgeBot.dy * 0.6),
        const Color(0xFFFF6B35));
    _label(canvas, 'Rx=${rx.toStringAsFixed(0)}Ω', Offset(r4Mid.dx + 4, r4Mid.dy - 4),
        const Color(0xFFFF6B35), 8);

    // Galvanometer in the middle
    final galvMid = Offset((bridgeLeft.dx + bridgeRight.dx) / 2,
        (bridgeLeft.dy + bridgeRight.dy) / 2);
    canvas.drawCircle(galvMid, 10,
        Paint()..color = const Color(0xFF0A0A0F)..style = PaintingStyle.fill);
    canvas.drawCircle(galvMid, 10,
        Paint()..color = const Color(0xFF5A8A9A)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    _label(canvas, 'G', Offset(galvMid.dx - 4, galvMid.dy - 5), const Color(0xFF5A8A9A), 9);

    // Animated current dot on galvanometer branch
    if (!isBalanced) {
      final dotPhase = (time * 1.5) % 1.0;
      final direction = vBridge > 0 ? dotPhase : (1.0 - dotPhase);
      final dotX = bridgeLeft.dx + (bridgeRight.dx - bridgeLeft.dx) * direction;
      final dotY = bridgeLeft.dy + (bridgeRight.dy - bridgeLeft.dy) * direction;
      canvas.drawCircle(Offset(dotX, dotY), 3.5,
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.9));
    }

    // Animated current dots on main branches
    for (int i = 0; i < 3; i++) {
      final phase = ((time * 1.2 + i / 3.0) % 1.0);
      // Left branch: top→left→bot
      final leftBranchX = bridgeTop.dx + (bridgeBot.dx - bridgeTop.dx) * phase;
      final leftBranchY = bridgeTop.dy + (bridgeBot.dy - bridgeTop.dy) * phase;
      canvas.drawCircle(Offset(leftBranchX - 8, leftBranchY),
          2.5, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.6));
      // Right branch
      canvas.drawCircle(Offset(leftBranchX + 8, leftBranchY),
          2.5, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.6));
    }

    // Node dots
    for (final node in [bridgeTop, bridgeLeft, bridgeRight, bridgeBot]) {
      canvas.drawCircle(node, 4, Paint()..color = const Color(0xFFE0F4FF));
    }

    // Voltage labels at nodes
    _label(canvas, '${vSupply.toStringAsFixed(0)}V', Offset(bridgeTop.dx + 5, bridgeTop.dy - 12),
        const Color(0xFFE0F4FF), 8);
    _label(canvas, '${vLeft.toStringAsFixed(2)}V', Offset(bridgeLeft.dx - 32, bridgeLeft.dy - 5),
        const Color(0xFF00D4FF), 8);
    _label(canvas, '${vRight.toStringAsFixed(2)}V', Offset(bridgeRight.dx + 5, bridgeRight.dy - 5),
        const Color(0xFFFF6B35), 8);
    _label(canvas, '0V', Offset(bridgeBot.dx + 5, bridgeBot.dy - 5),
        const Color(0xFF5A8A9A), 8);

    // Balance / imbalance indicator
    final balStr = isBalanced ? '균형 (G=0)' : 'Δ=${vBridge.toStringAsFixed(3)}V';
    _label(canvas, balStr, Offset(galvMid.dx, galvMid.dy + 15),
        isBalanced ? const Color(0xFF64FF8C) : const Color(0xFFFF6B35), 8, center: true);

    // Balance condition label
    _label(canvas, 'R₁/R₂ = R₃/Rx', Offset(cx - 36, h * 0.97 - 2),
        const Color(0xFF5A8A9A), 8, bold: true);
  }

  @override
  bool shouldRepaint(covariant _WheatstoneBridgeScreenPainter oldDelegate) => true;
}
