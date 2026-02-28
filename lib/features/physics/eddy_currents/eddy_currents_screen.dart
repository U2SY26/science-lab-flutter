import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class EddyCurrentsScreen extends StatefulWidget {
  const EddyCurrentsScreen({super.key});
  @override
  State<EddyCurrentsScreen> createState() => _EddyCurrentsScreenState();
}

class _EddyCurrentsScreenState extends State<EddyCurrentsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _bField = 0.5;
  double _freq = 50;
  double _power = 0, _force = 0;

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
      _power = 0.01 * _bField * _bField * _freq * _freq;
      _force = _power * 0.1;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _bField = 0.5; _freq = 50.0;
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
          const Text('와전류', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 시뮬레이션',
          title: '와전류',
          formula: 'P = k·B²·f²·d²',
          formulaDescription: '변화하는 자기장에 의한 와전류를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _EddyCurrentsScreenPainter(
                time: _time,
                bField: _bField,
                freq: _freq,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '자기장 (T)',
                value: _bField,
                min: 0.01,
                max: 2,
                step: 0.01,
                defaultValue: 0.5,
                formatValue: (v) => v.toStringAsFixed(2) + ' T',
                onChanged: (v) => setState(() => _bField = v),
              ),
              advancedControls: [
            SimSlider(
                label: '주파수 (Hz)',
                value: _freq,
                min: 10,
                max: 500,
                step: 10,
                defaultValue: 50,
                formatValue: (v) => v.toStringAsFixed(0) + ' Hz',
                onChanged: (v) => setState(() => _freq = v),
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
          _V('손실', _power.toStringAsFixed(2) + ' W'),
          _V('제동력', _force.toStringAsFixed(3) + ' N'),
          _V('B', _bField.toStringAsFixed(2) + ' T'),
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

class _EddyCurrentsScreenPainter extends CustomPainter {
  final double time;
  final double bField;
  final double freq;

  _EddyCurrentsScreenPainter({
    required this.time,
    required this.bField,
    required this.freq,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;

    // Grid
    final gridPaint = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.4)..strokeWidth = 0.5;
    for (double x = 0; x < w; x += 30) { canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint); }
    for (double y = 0; y < h; y += 30) { canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint); }

    // --- Two falling disks side by side ---
    // Left: solid disk (strong eddy currents, slow fall)
    // Right: slotted disk (weak eddy currents, fast fall)

    // B-field region (horizontal band in the middle)
    final bTop = h * 0.38;
    final bBot = h * 0.72;
    canvas.drawRect(
      Rect.fromLTWH(0, bTop, w, bBot - bTop),
      Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.05 + bField * 0.04),
    );
    // B-field boundary lines
    final bLinePaint = Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.35)..strokeWidth = 1..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, bTop), Offset(w, bTop), bLinePaint);
    canvas.drawLine(Offset(0, bBot), Offset(w, bBot), bLinePaint);
    _drawLabel(canvas, 'B 자기장 영역', Offset(w * 0.5, bTop - 10), const Color(0xFF00D4FF), 9);

    // B-field dot symbols inside region
    final bRows = 2, bCols = 6;
    for (int r = 0; r < bRows; r++) {
      for (int c = 0; c < bCols; c++) {
        final bx = (c + 0.5) * w / bCols;
        final by = bTop + (r + 0.5) * (bBot - bTop) / bRows;
        canvas.drawCircle(Offset(bx, by), 2.5, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.2));
        canvas.drawCircle(Offset(bx, by), 0.8, Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.5));
      }
    }

    // Disk fall animation
    // Solid disk falls slower inside B region
    final fallCycle = (time * 0.4) % 1.0; // 0..1 = one full cycle
    // Disk Y: travels from top to bottom of canvas
    double rawY = fallCycle * (h + 40) - 20;
    // Slow down inside B region for solid disk
    double solidY = rawY;
    if (rawY > bTop - 20 && rawY < bBot + 20) {
      final slowFactor = 1.0 - bField * 0.6; // slow based on B
      final enterProgress = (rawY - (bTop - 20)) / (bBot - bTop + 40);
      solidY = bTop - 20 + enterProgress * (bBot - bTop + 40) * slowFactor.clamp(0.1, 1.0) +
          (rawY - (bTop - 20)) * (1 - slowFactor.clamp(0.1, 1.0)) * 0.15;
    }
    // Slotted disk barely slows
    final slottedY = rawY;

    final diskR = h * 0.09;

    // --- Solid disk (left) ---
    final sdCx = w * 0.28;
    final sdCy = solidY.clamp(-diskR, h + diskR).toDouble();

    canvas.drawCircle(
      Offset(sdCx, sdCy),
      diskR,
      Paint()..color = const Color(0xFF1A3040),
    );
    canvas.drawCircle(
      Offset(sdCx, sdCy),
      diskR,
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.8)..strokeWidth = 2..style = PaintingStyle.stroke,
    );

    // Eddy current loops on solid disk (when in B field)
    final inBField = sdCy > bTop - diskR && sdCy < bBot + diskR;
    if (inBField) {
      final eddyAlpha = (bField * freq / 500 * 0.7 + 0.2).clamp(0.15, 0.9);
      final eddyPaint = Paint()..color = const Color(0xFFFF6B35).withValues(alpha: eddyAlpha)..strokeWidth = 1.5..style = PaintingStyle.stroke;
      // Two concentric eddy current loops
      for (final r2 in [diskR * 0.35, diskR * 0.65]) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(sdCx, sdCy), width: r2 * 2, height: r2 * 2),
          time * 2, math.pi * 1.7, false, eddyPaint,
        );
        // Arrow on loop
        final ax = sdCx + r2 * math.cos(time * 2 + math.pi * 1.7);
        final ay = sdCy + r2 * math.sin(time * 2 + math.pi * 1.7);
        canvas.drawCircle(Offset(ax, ay), 2, Paint()..color = const Color(0xFFFF6B35).withValues(alpha: eddyAlpha));
      }
      // Braking force arrow (upward)
      canvas.drawLine(Offset(sdCx, sdCy + diskR + 2), Offset(sdCx, sdCy + diskR + 14),
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 2);
      canvas.drawLine(Offset(sdCx - 4, sdCy + diskR + 8), Offset(sdCx, sdCy + diskR + 2), Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 2);
      canvas.drawLine(Offset(sdCx + 4, sdCy + diskR + 8), Offset(sdCx, sdCy + diskR + 2), Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 2);
      _drawLabel(canvas, 'F_제동', Offset(sdCx, sdCy + diskR + 22), const Color(0xFF64FF8C), 8);
    }
    _drawLabel(canvas, '실속 원판', Offset(sdCx, h * 0.12), const Color(0xFF5A8A9A), 9);
    _drawLabel(canvas, '(느림)', Offset(sdCx, h * 0.18), const Color(0xFFFF6B35), 8);

    // --- Slotted disk (right) ---
    final slCx = w * 0.72;
    final slCy = slottedY.clamp(-diskR, h + diskR).toDouble();

    canvas.drawCircle(
      Offset(slCx, slCy),
      diskR,
      Paint()..color = const Color(0xFF1A3040),
    );
    canvas.drawCircle(
      Offset(slCx, slCy),
      diskR,
      Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.8)..strokeWidth = 2..style = PaintingStyle.stroke,
    );
    // Slots (radial cuts)
    for (int s = 0; s < 6; s++) {
      final sAngle = s * math.pi / 3;
      canvas.drawLine(
        Offset(slCx + diskR * 0.3 * math.cos(sAngle), slCy + diskR * 0.3 * math.sin(sAngle)),
        Offset(slCx + diskR * 0.9 * math.cos(sAngle), slCy + diskR * 0.9 * math.sin(sAngle)),
        Paint()..color = const Color(0xFF0D1A20)..strokeWidth = 3,
      );
    }
    // Weak eddy current (small loops only)
    final slInB = slCy > bTop - diskR && slCy < bBot + diskR;
    if (slInB) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(slCx, slCy), width: diskR * 0.5, height: diskR * 0.5),
        time * 2, math.pi * 1.5, false,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.25)..strokeWidth = 1..style = PaintingStyle.stroke,
      );
    }
    _drawLabel(canvas, '슬롯 원판', Offset(slCx, h * 0.12), const Color(0xFF5A8A9A), 9);
    _drawLabel(canvas, '(빠름)', Offset(slCx, h * 0.18), const Color(0xFF64FF8C), 8);

    // --- Lenz's law annotation ---
    _drawLabel(canvas, "렌츠 법칙: 와전류 → 운동 반대 방향 제동", Offset(w / 2, h * 0.86), const Color(0xFFE0F4FF), 9);
    _drawLabel(canvas, 'B=${bField.toStringAsFixed(2)}T  f=${freq.toStringAsFixed(0)}Hz', Offset(w / 2, h * 0.93), const Color(0xFF5A8A9A), 9);

    // Title
    _drawLabel(canvas, '와전류 & 자기 제동 (렌츠)', Offset(w / 2, 14), const Color(0xFF00D4FF), 12, bold: true);
  }

  void _drawLabel(Canvas canvas, String text, Offset center, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _EddyCurrentsScreenPainter oldDelegate) => true;
}
