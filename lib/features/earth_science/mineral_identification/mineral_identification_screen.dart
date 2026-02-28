import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class MineralIdentificationScreen extends StatefulWidget {
  const MineralIdentificationScreen({super.key});
  @override
  State<MineralIdentificationScreen> createState() => _MineralIdentificationScreenState();
}

class _MineralIdentificationScreenState extends State<MineralIdentificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _hardness = 5;
  
  String _mineral = "인회석";

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
      _mineral = _hardness <= 2 ? "석고" : _hardness <= 3 ? "방해석" : _hardness <= 5 ? "인회석" : _hardness <= 6 ? "정장석" : _hardness <= 7 ? "석영" : "강옥";
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _hardness = 5.0;
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
          const Text('광물 감정', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '지구과학 시뮬레이션',
          title: '광물 감정',
          formula: 'Mohs 1-10',
          formulaDescription: '광물의 물리적 성질을 이용한 감정 과정을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _MineralIdentificationScreenPainter(
                time: _time,
                hardness: _hardness,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '경도 (Mohs)',
                value: _hardness,
                min: 1,
                max: 10,
                step: 0.5,
                defaultValue: 5,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => setState(() => _hardness = v),
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
          _V('경도', _hardness.toStringAsFixed(1)),
          _V('광물', _mineral),
          _V('조흔', _hardness > 7 ? '백색' : '다양'),
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

class _MineralIdentificationScreenPainter extends CustomPainter {
  final double time;
  final double hardness;

  _MineralIdentificationScreenPainter({
    required this.time,
    required this.hardness,
  });

  void _drawLabel(Canvas canvas, String text, Offset pos, {Color color = const Color(0xFF5A8A9A), double fontSize = 8}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawCrystal(Canvas canvas, Offset center, double r, int sides, Color fillColor, Color strokeColor, double rotation) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = rotation + i * math.pi * 2 / sides;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(path, Paint()..color = strokeColor..strokeWidth = 1.2..style = PaintingStyle.stroke);
  }

  void _drawCleavageLine(Canvas canvas, Offset center, double r, double angle, Color color) {
    final dx = math.cos(angle) * r;
    final dy = math.sin(angle) * r;
    canvas.drawLine(
      Offset(center.dx - dx, center.dy - dy),
      Offset(center.dx + dx, center.dy + dy),
      Paint()..color = color..strokeWidth = 0.8..style = PaintingStyle.stroke,
    );
  }

  void _drawHardnessBar(Canvas canvas, Rect barRect, double hardnessVal, double maxH, Color barColor) {
    // Background bar
    canvas.drawRect(barRect, Paint()..color = const Color(0xFF1A3040));
    // Fill bar
    final fillW = barRect.width * (hardnessVal / maxH).clamp(0.0, 1.0);
    if (fillW > 0) {
      canvas.drawRect(
        Rect.fromLTWH(barRect.left, barRect.top, fillW, barRect.height),
        Paint()..color = barColor,
      );
    }
    canvas.drawRect(barRect, Paint()..color = const Color(0xFF3A5A6A)..strokeWidth = 0.8..style = PaintingStyle.stroke);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width, h = size.height;

    // Background grid
    final gridPaint = Paint()..color = const Color(0xFF1A3040).withValues(alpha: 0.4)..strokeWidth = 0.4;
    for (double x = 0; x < w; x += w / 8) { canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint); }
    for (double y = 0; y < h; y += h / 6) { canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint); }

    // Mineral data: [name, hardness, sides, fill color, stroke color, luster, streak]
    final minerals = [
      ('석영',   7.0, 6,  const Color(0xFFAADDFF), const Color(0xFF88BBDD), '유리광택', '흰색'),
      ('장석',   6.0, 4,  const Color(0xFFFFCCAA), const Color(0xFFDDAA88), '진주광택', '흰색'),
      ('운모',   2.5, 6,  const Color(0xFFBBAA44), const Color(0xFF998822), '진주광택', '흰색'),
      ('방해석', 3.0, 3,  const Color(0xFFCCFFCC), const Color(0xFF88AA88), '유리광택', '흰색'),
      ('황철석', 6.2, 4,  const Color(0xFFDDCC00), const Color(0xFF998800), '금속광택', '흑색'),
      ('형석',   4.0, 8,  const Color(0xFFBB88FF), const Color(0xFF8844CC), '유리광택', '흰색'),
    ];

    // Grid layout: 3 cols x 2 rows
    final cols = 3, rows = 2;
    final cellW = w / cols, cellH = h * 0.72 / rows;
    final crystalR = math.min(cellW, cellH) * 0.22;

    // Determine selected mineral index from hardness slider
    int selectedIdx = 0;
    double minDist = double.infinity;
    for (int i = 0; i < minerals.length; i++) {
      final d = (minerals[i].$2 - hardness).abs();
      if (d < minDist) {
        minDist = d;
        selectedIdx = i;
      }
    }

    for (int i = 0; i < minerals.length; i++) {
      final col = i % cols, row = i ~/ cols;
      final cx = cellW * col + cellW / 2;
      final cy = cellH * row + cellH / 2;
      final m = minerals[i];
      final isSelected = i == selectedIdx;

      // Cell highlight
      if (isSelected) {
        canvas.drawRect(
          Rect.fromLTWH(cellW * col + 2, cellH * row + 2, cellW - 4, cellH - 4),
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.08),
        );
        canvas.drawRect(
          Rect.fromLTWH(cellW * col + 2, cellH * row + 2, cellW - 4, cellH - 4),
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.35)..strokeWidth = 1.5..style = PaintingStyle.stroke,
        );
      }

      // Crystal shape with shimmer
      final shimmerAlpha = isSelected ? (0.7 + 0.3 * math.sin(time * 3)) : 0.7;
      final rotation = time * (isSelected ? 0.5 : 0.1) + i * 0.4;
      _drawCrystal(canvas, Offset(cx, cy - cellH * 0.08), crystalR, m.$3,
        m.$4.withValues(alpha: shimmerAlpha), m.$5.withValues(alpha: 0.9), rotation);

      // Inner facets for 3D effect
      if (m.$3 >= 6) {
        _drawCrystal(canvas, Offset(cx, cy - cellH * 0.08), crystalR * 0.6, m.$3,
          m.$4.withValues(alpha: shimmerAlpha * 0.4), m.$5.withValues(alpha: 0.3), rotation + math.pi / m.$3);
      }

      // Cleavage lines
      if (m.$1 == '운모' || m.$1 == '방해석' || m.$1 == '장석') {
        _drawCleavageLine(canvas, Offset(cx, cy - cellH * 0.08), crystalR * 0.85, 0, m.$5.withValues(alpha: 0.4));
        if (m.$1 != '운모') {
          _drawCleavageLine(canvas, Offset(cx, cy - cellH * 0.08), crystalR * 0.85, math.pi / 3, m.$5.withValues(alpha: 0.3));
        }
      }

      // Name label
      _drawLabel(canvas, m.$1, Offset(cx, cy + cellH * 0.26),
        color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFFE0F4FF), fontSize: 9);

      // Hardness bar
      final barY = cy + cellH * 0.36;
      final barRect = Rect.fromCenter(center: Offset(cx, barY), width: cellW * 0.6, height: 5);
      _drawHardnessBar(canvas, barRect, m.$2, 10, m.$4);
      _drawLabel(canvas, 'Mohs ${m.$2.toStringAsFixed(1)}', Offset(cx, barY + 8), color: const Color(0xFF5A8A9A), fontSize: 7);
    }

    // Radar chart for selected mineral (bottom panel)
    final sel = minerals[selectedIdx];
    final radarCx = w * 0.5, radarCy = h * 0.855;
    final radarR = h * 0.09;

    // Axes labels
    final radarLabels = ['경도', '광택', '밀도', '벽개', '색'];
    for (int a = 0; a < radarLabels.length; a++) {
      final angle = -math.pi / 2 + a * math.pi * 2 / radarLabels.length;
      final lx = radarCx + (radarR + 12) * math.cos(angle);
      final ly = radarCy + (radarR + 12) * math.sin(angle);
      _drawLabel(canvas, radarLabels[a], Offset(lx, ly), color: const Color(0xFF3A6A8A), fontSize: 7);
    }

    // Radar background rings
    for (int ring = 1; ring <= 3; ring++) {
      final ringPath = Path();
      for (int a = 0; a < 5; a++) {
        final angle = -math.pi / 2 + a * math.pi * 2 / 5;
        final rx = radarCx + radarR * ring / 3 * math.cos(angle);
        final ry = radarCy + radarR * ring / 3 * math.sin(angle);
        if (a == 0) { ringPath.moveTo(rx, ry); } else { ringPath.lineTo(rx, ry); }
      }
      ringPath.close();
      canvas.drawPath(ringPath, Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.5..style = PaintingStyle.stroke);
    }

    // Radar axes
    for (int a = 0; a < 5; a++) {
      final angle = -math.pi / 2 + a * math.pi * 2 / 5;
      canvas.drawLine(
        Offset(radarCx, radarCy),
        Offset(radarCx + radarR * math.cos(angle), radarCy + radarR * math.sin(angle)),
        Paint()..color = const Color(0xFF1A3040)..strokeWidth = 0.8,
      );
    }

    // Radar data for selected mineral: [hardness/10, luster, density, cleavage, color richness]
    final radarData = [
      sel.$2 / 10.0,                         // hardness
      sel.$6 == '금속광택' ? 0.9 : 0.6,        // luster
      0.4 + sel.$2 * 0.05,                    // density approx
      (sel.$1 == '운모' || sel.$1 == '방해석') ? 0.85 : 0.4, // cleavage
      0.5 + selectedIdx * 0.08,               // color
    ];

    final radarPath = Path();
    for (int a = 0; a < 5; a++) {
      final angle = -math.pi / 2 + a * math.pi * 2 / 5;
      final r = radarR * radarData[a].clamp(0.0, 1.0);
      final rx = radarCx + r * math.cos(angle);
      final ry = radarCy + r * math.sin(angle);
      if (a == 0) { radarPath.moveTo(rx, ry); } else { radarPath.lineTo(rx, ry); }
    }
    radarPath.close();
    canvas.drawPath(radarPath, Paint()..color = sel.$4.withValues(alpha: 0.2));
    canvas.drawPath(radarPath, Paint()..color = sel.$4.withValues(alpha: 0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke);

    // Selected mineral info
    _drawLabel(canvas, '${sel.$1}  경도:${sel.$2.toStringAsFixed(1)}  광택:${sel.$6}  조흔:${sel.$7}',
      Offset(w * 0.5, h * 0.96), color: const Color(0xFF5A8A9A), fontSize: 8);
  }

  @override
  bool shouldRepaint(covariant _MineralIdentificationScreenPainter oldDelegate) => true;
}
