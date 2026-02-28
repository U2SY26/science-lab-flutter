import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CellularRespirationScreen extends StatefulWidget {
  const CellularRespirationScreen({super.key});
  @override
  State<CellularRespirationScreen> createState() => _CellularRespirationScreenState();
}

class _CellularRespirationScreenState extends State<CellularRespirationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _glucoseConc = 5;
  double _oxygenLevel = 100;
  double _atpTotal = 0, _glycolysisAtp = 0;

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
      _glycolysisAtp = 2;
      _atpTotal = _oxygenLevel > 20 ? 36.0 * _glucoseConc / 5 : 2.0 * _glucoseConc / 5;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _glucoseConc = 5; _oxygenLevel = 100;
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
          Text('생물학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('세포 호흡', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '생물학 시뮬레이션',
          title: '세포 호흡',
          formula: 'C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O + 36ATP',
          formulaDescription: '해당과정, 크렙스 회로, 전자전달계를 통한 에너지 생산을 추적합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CellularRespirationScreenPainter(
                time: _time,
                glucoseConc: _glucoseConc,
                oxygenLevel: _oxygenLevel,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '포도당 농도 (mM)',
                value: _glucoseConc,
                min: 0.1,
                max: 10,
                step: 0.1,
                defaultValue: 5,
                formatValue: (v) => '${v.toStringAsFixed(1)} mM',
                onChanged: (v) => setState(() => _glucoseConc = v),
              ),
              advancedControls: [
            SimSlider(
                label: '산소 수준 (%)',
                value: _oxygenLevel,
                min: 0,
                max: 100,
                step: 5,
                defaultValue: 100,
                formatValue: (v) => '${v.toStringAsFixed(0)}%',
                onChanged: (v) => setState(() => _oxygenLevel = v),
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
          _V('해당과정 ATP', _glycolysisAtp.toStringAsFixed(0)),
          _V('총 ATP', _atpTotal.toStringAsFixed(1)),
          _V('O₂', '${_oxygenLevel.toStringAsFixed(0)}%'),
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

class _CellularRespirationScreenPainter extends CustomPainter {
  final double time;
  final double glucoseConc;
  final double oxygenLevel;

  _CellularRespirationScreenPainter({
    required this.time,
    required this.glucoseConc,
    required this.oxygenLevel,
  });

  void _label(Canvas canvas, String text, Offset pos, {double fs = 8, Color col = const Color(0xFF5A8A9A), bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: col, fontSize: fs, fontWeight: FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center ? pos.dx - tp.width / 2 : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color, {double sw = 1.5}) {
    final paint = Paint()..color = color..strokeWidth = sw..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, paint);
    // Arrowhead
    final dir = (to - from);
    final len = dir.distance;
    if (len < 1) return;
    final norm = dir / len;
    final perp = Offset(-norm.dy, norm.dx);
    final head1 = to - norm * 7 + perp * 4;
    final head2 = to - norm * 7 - perp * 4;
    final hp = Path()..moveTo(to.dx, to.dy)..lineTo(head1.dx, head1.dy)..lineTo(head2.dx, head2.dy)..close();
    canvas.drawPath(hp, Paint()..color = color..style = PaintingStyle.fill);
  }

  void _drawStageBox(Canvas canvas, Rect rect, String title, String subtitle, String atp, Color color) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _label(canvas, title, Offset(rect.left + rect.width / 2, rect.top + 4), fs: 8, col: color, center: true);
    _label(canvas, subtitle, Offset(rect.left + rect.width / 2, rect.top + 15), fs: 7, col: const Color(0xFFE0F4FF), center: true);
    // ATP badge
    final badgeRect = Rect.fromCenter(center: Offset(rect.right - 18, rect.bottom - 10), width: 32, height: 14);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(4)),
        Paint()..color = color.withValues(alpha: 0.5));
    _label(canvas, atp, Offset(badgeRect.left + 2, badgeRect.top + 2), fs: 7, col: const Color(0xFFE0F4FF));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final isAerobic = oxygenLevel > 20;

    // --- Cell outer membrane ---
    final cellRect = Rect.fromLTWH(8, 8, w - 16, h - 16);
    canvas.drawRRect(RRect.fromRectAndRadius(cellRect, const Radius.circular(20)),
        Paint()..color = const Color(0xFF1A3040));
    canvas.drawRRect(RRect.fromRectAndRadius(cellRect, const Radius.circular(20)),
        Paint()..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 2);
    _label(canvas, '세포질', Offset(14, 12), fs: 7, col: const Color(0xFF5A8A9A));

    // --- Mitochondria (oval, right half) ---
    final mitoCx = w * 0.7;
    final mitoCy = h * 0.45;
    final mitoW = w * 0.5;
    final mitoH = h * 0.45;
    final mitoRect = Rect.fromCenter(center: Offset(mitoCx, mitoCy), width: mitoW, height: mitoH);
    canvas.drawOval(mitoRect, Paint()..color = const Color(0xFF0D2A15));
    canvas.drawOval(mitoRect,
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // Inner membrane (cristae — wavy line)
    final cristPath = Path();
    for (int px = 0; px <= 40; px++) {
      final t = px / 40.0;
      final x = mitoRect.left + 12 + t * (mitoW - 24);
      final y = mitoCy + math.sin(t * math.pi * 4 + time) * 6;
      if (px == 0) {
        cristPath.moveTo(x, y);
      } else {
        cristPath.lineTo(x, y);
      }
    }
    canvas.drawPath(cristPath,
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.4)..strokeWidth = 1.2..style = PaintingStyle.stroke);
    _label(canvas, '미토콘드리아', Offset(mitoCx - 30, mitoRect.top + 4), fs: 7, col: const Color(0xFF64FF8C));

    // --- Stage boxes ---
    // Glycolysis (left side, cytoplasm)
    final glyRect = Rect.fromLTWH(14, h * 0.08, w * 0.35, h * 0.22);
    _drawStageBox(canvas, glyRect, '①해당과정', '포도당→피루브산', '2 ATP', const Color(0xFFFF6B35));

    // TCA cycle (inside mito, top)
    final tcaRect = Rect.fromLTWH(mitoCx - mitoW / 2 + 12, mitoCy - mitoH / 2 + 10, mitoW - 24, mitoH * 0.35);
    _drawStageBox(canvas, tcaRect, '②TCA 회로', '아세틸CoA→CO₂', '2 ATP', const Color(0xFF5A8A9A));

    // Electron transport (inside mito, bottom)
    final etcRect = Rect.fromLTWH(mitoCx - mitoW / 2 + 12, mitoCy + 4, mitoW - 24, mitoH * 0.35);
    if (isAerobic) {
      _drawStageBox(canvas, etcRect, '③전자전달계', 'NADH→H₂O', '34 ATP', const Color(0xFF00D4FF));
    } else {
      _drawStageBox(canvas, etcRect, '③발효', '피루브산→젖산', '0 ATP', const Color(0xFF5A8A9A));
    }

    // --- Arrows between stages ---
    final glyOut = Offset(glyRect.right, glyRect.top + glyRect.height / 2);
    _drawArrow(canvas, glyOut, Offset(mitoCx - mitoW / 2 + 6, mitoCy - 4), const Color(0xFFFF6B35));

    // Glucose input arrow
    _drawArrow(canvas, Offset(14, glyRect.top + glyRect.height / 2),
        Offset(glyRect.left, glyRect.top + glyRect.height / 2), const Color(0xFFFF6B35));
    _label(canvas, 'C₆H₁₂O₆', Offset(2, glyRect.top + glyRect.height / 2 - 16), fs: 7, col: const Color(0xFFFF6B35));

    // O2 indicator
    _label(canvas, 'O₂: ${oxygenLevel.toStringAsFixed(0)}%', Offset(14, h - 26), fs: 8,
        col: Color.lerp(const Color(0xFFFF6B35), const Color(0xFF00D4FF), oxygenLevel / 100)!);

    // Total ATP
    final totalAtp = isAerobic ? 36 : 2;
    final atpColor = isAerobic ? const Color(0xFF64FF8C) : const Color(0xFFFF6B35);
    _label(canvas, '총 ATP: $totalAtp/포도당', Offset(14, h - 14), fs: 9, col: atpColor);
    _label(canvas, isAerobic ? '호기성 호흡' : '혐기성(발효)', Offset(w - 72, h - 14), fs: 8,
        col: isAerobic ? const Color(0xFF00D4FF) : const Color(0xFFFF6B35));

    // Animated electron dots (ETC only)
    if (isAerobic) {
      for (int i = 0; i < 5; i++) {
        final t = (time * 1.5 + i * 0.2) % 1.0;
        final ex = etcRect.left + t * etcRect.width;
        final ey = etcRect.top + etcRect.height / 2 + math.sin(t * math.pi * 4) * 4;
        canvas.drawCircle(Offset(ex, ey), 2.5,
            Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.9));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CellularRespirationScreenPainter oldDelegate) => true;
}
