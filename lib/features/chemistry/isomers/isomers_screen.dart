import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class IsomersScreen extends StatefulWidget {
  const IsomersScreen({super.key});
  @override
  State<IsomersScreen> createState() => _IsomersScreenState();
}

class _IsomersScreenState extends State<IsomersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _carbonCount = 4;
  
  int _structuralIsomers = 2, _stereoIsomers = 0;

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
      final c = _carbonCount.toInt();
      _structuralIsomers = [1, 1, 1, 2, 3, 5, 9, 18][c.clamp(1, 8) - 1];
      _stereoIsomers = c >= 4 ? (c - 3) : 0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _carbonCount = 4.0;
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
          const Text('구조 및 기하 이성질체', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '구조 및 기하 이성질체',
          formula: 'cis-trans, E-Z',
          formulaDescription: '구조 이성질체와 기하 이성질체를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _IsomersScreenPainter(
                time: _time,
                carbonCount: _carbonCount,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '탄소 수',
                value: _carbonCount,
                min: 2,
                max: 8,
                step: 1,
                defaultValue: 4,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _carbonCount = v),
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
          _V('구조', '$_structuralIsomers'),
          _V('기하', '$_stereoIsomers'),
          _V('C', _carbonCount.toInt().toString()),
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

class _IsomersScreenPainter extends CustomPainter {
  final double time;
  final double carbonCount;

  _IsomersScreenPainter({
    required this.time,
    required this.carbonCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;
    final topH = h * 0.5;
    final botH = h * 0.5;
    final cyanPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final orangePaint = Paint()
      ..color = const Color(0xFFFF6B35)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // ── TOP: Structural isomers (n-butane vs isobutane) ──────────────────
    _drawSectionLabel(canvas, 'n-뷰테인  vs  아이소뷰테인', w / 2, 8, const Color(0xFF00D4FF));

    // n-butane: left half top
    final nBX = w * 0.25;
    final nBY = topH * 0.5;
    _drawChain(canvas, nBX, nBY, 4, cyanPaint, false, 0);

    // isobutane: right half top
    final isoX = w * 0.72;
    final isoY = topH * 0.5;
    _drawIsoButane(canvas, isoX, isoY, cyanPaint);

    // divider between the two structural isomers
    _drawArrow(canvas, w * 0.5, nBY, '⇌', const Color(0xFF00D4FF));
    _drawLabel(canvas, 'C${carbonCount.toInt()}H${2 * carbonCount.toInt() + 2}', w * 0.5, topH - 14, const Color(0xFF00D4FF));
    _drawLabel(canvas, '끓는점: -0.5°C', nBX, topH - 14, const Color(0xFF5A8A9A));
    _drawLabel(canvas, '끓는점: -11.7°C', isoX, topH - 14, const Color(0xFF5A8A9A));

    // Divider line
    canvas.drawLine(Offset(0, topH), Offset(w, topH),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.8);

    // ── BOTTOM: Geometric isomers (cis vs trans 2-butene) ─────────────────
    final botBase = topH;
    _drawSectionLabel(canvas, 'cis-2-뷰텐  vs  trans-2-뷰텐', w / 2, botBase + 6, const Color(0xFFFF6B35));

    final cisX = w * 0.25;
    final cisY = botBase + botH * 0.52;
    _drawCisButene(canvas, cisX, cisY, orangePaint);

    final transX = w * 0.72;
    final transY = botBase + botH * 0.52;
    _drawTransButene(canvas, transX, transY, orangePaint);

    _drawArrow(canvas, w * 0.5, cisY, '⇌', const Color(0xFFFF6B35));
    _drawLabel(canvas, 'C₄H₈', w * 0.5, botBase + botH - 14, const Color(0xFFFF6B35));
    _drawLabel(canvas, 'bp: 3.7°C', cisX, botBase + botH - 14, const Color(0xFF5A8A9A));
    _drawLabel(canvas, 'bp: 0.9°C', transX, botBase + botH - 14, const Color(0xFF5A8A9A));
  }

  void _drawSectionLabel(Canvas canvas, String text, double cx, double y, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  void _drawLabel(Canvas canvas, String text, double cx, double y, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 8)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  void _drawArrow(Canvas canvas, double cx, double cy, String symbol, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: symbol, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawAtom(Canvas canvas, double x, double y, String label, Color color) {
    canvas.drawCircle(Offset(x, y), 7.5,
        Paint()..color = const Color(0xFF0D1A20)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(x, y), 7.5,
        Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.0);
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: color, fontSize: 7)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  // n-chain: linear carbon chain with bond length
  void _drawChain(Canvas canvas, double cx, double cy, int n, Paint p, bool isZigzag, double angleOff) {
    final spacing = 18.0;
    final startX = cx - (n - 1) * spacing / 2;
    for (int i = 0; i < n - 1; i++) {
      final x1 = startX + i * spacing;
      final y1 = cy + (isZigzag ? (i % 2 == 0 ? -6.0 : 6.0) : 0.0);
      final x2 = startX + (i + 1) * spacing;
      final y2 = cy + (isZigzag ? ((i + 1) % 2 == 0 ? -6.0 : 6.0) : 0.0);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);
    }
    for (int i = 0; i < n; i++) {
      final x = startX + i * spacing;
      final y = cy + (isZigzag ? (i % 2 == 0 ? -6.0 : 6.0) : 0.0);
      _drawAtom(canvas, x, y, 'C', p.color);
    }
  }

  // isobutane: branched
  void _drawIsoButane(Canvas canvas, double cx, double cy, Paint p) {
    // central C at top, 3 branches
    canvas.drawLine(Offset(cx, cy - 16), Offset(cx, cy), p);
    canvas.drawLine(Offset(cx, cy), Offset(cx - 16, cy + 12), p);
    canvas.drawLine(Offset(cx, cy), Offset(cx + 16, cy + 12), p);
    canvas.drawLine(Offset(cx, cy), Offset(cx, cy + 18), p);
    _drawAtom(canvas, cx, cy - 16, 'C', p.color);
    _drawAtom(canvas, cx, cy, 'C', p.color);
    _drawAtom(canvas, cx - 16, cy + 12, 'C', p.color);
    _drawAtom(canvas, cx + 16, cy + 12, 'C', p.color);
  }

  // cis-2-butene: same side CH3 groups
  void _drawCisButene(Canvas canvas, double cx, double cy, Paint p) {
    // C=C double bond horizontal
    canvas.drawLine(Offset(cx - 12, cy), Offset(cx + 12, cy), p);
    canvas.drawLine(Offset(cx - 12, cy + 3), Offset(cx + 12, cy + 3), p);
    // CH3 groups - both pointing up (same side = cis)
    canvas.drawLine(Offset(cx - 12, cy), Offset(cx - 24, cy - 14), p);
    canvas.drawLine(Offset(cx + 12, cy), Offset(cx + 24, cy - 14), p);
    _drawAtom(canvas, cx - 12, cy, 'C', p.color);
    _drawAtom(canvas, cx + 12, cy, 'C', p.color);
    _drawAtom(canvas, cx - 24, cy - 14, 'C', p.color);
    _drawAtom(canvas, cx + 24, cy - 14, 'C', p.color);
    final ltp = TextPainter(
      text: TextSpan(text: 'cis', style: TextStyle(color: p.color, fontSize: 9, fontStyle: FontStyle.italic)),
      textDirection: TextDirection.ltr,
    )..layout();
    ltp.paint(canvas, Offset(cx - ltp.width / 2, cy + 10));
  }

  // trans-2-butene: opposite side CH3 groups
  void _drawTransButene(Canvas canvas, double cx, double cy, Paint p) {
    canvas.drawLine(Offset(cx - 12, cy), Offset(cx + 12, cy), p);
    canvas.drawLine(Offset(cx - 12, cy + 3), Offset(cx + 12, cy + 3), p);
    // CH3 groups - opposite sides (trans)
    canvas.drawLine(Offset(cx - 12, cy), Offset(cx - 24, cy - 14), p);
    canvas.drawLine(Offset(cx + 12, cy), Offset(cx + 24, cy + 14), p);
    _drawAtom(canvas, cx - 12, cy, 'C', p.color);
    _drawAtom(canvas, cx + 12, cy, 'C', p.color);
    _drawAtom(canvas, cx - 24, cy - 14, 'C', p.color);
    _drawAtom(canvas, cx + 24, cy + 14, 'C', p.color);
    final ltp = TextPainter(
      text: TextSpan(text: 'trans', style: TextStyle(color: p.color, fontSize: 9, fontStyle: FontStyle.italic)),
      textDirection: TextDirection.ltr,
    )..layout();
    ltp.paint(canvas, Offset(cx - ltp.width / 2, cy + 10));
  }

  @override
  bool shouldRepaint(covariant _IsomersScreenPainter oldDelegate) => true;
}
