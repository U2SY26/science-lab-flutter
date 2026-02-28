import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class OrganicFunctionalGroupsScreen extends StatefulWidget {
  const OrganicFunctionalGroupsScreen({super.key});
  @override
  State<OrganicFunctionalGroupsScreen> createState() => _OrganicFunctionalGroupsScreenState();
}

class _OrganicFunctionalGroupsScreenState extends State<OrganicFunctionalGroupsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _groupType = 0;
  
  String _polarity = "극성"; double _boilingPt = 100;

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
      _polarity = _groupType < 4 ? "극성" : "비극성";
      _boilingPt = [78, 118, -33, 21, 56, 222][_groupType.toInt()].toDouble();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _groupType = 0.0;
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
          const Text('유기 작용기', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '유기 작용기',
          formula: '-OH, -COOH, -NH₂, ...',
          formulaDescription: '주요 유기 작용기의 구조와 성질을 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _OrganicFunctionalGroupsScreenPainter(
                time: _time,
                groupType: _groupType,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '작용기 유형',
                value: _groupType,
                min: 0,
                max: 5,
                step: 1,
                defaultValue: 0,
                formatValue: (v) => ['-OH','-COOH','-NH₂','-CHO','C=O','-CONH₂'][v.toInt()],
                onChanged: (v) => setState(() => _groupType = v),
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
          _V('극성', _polarity),
          _V('끓는점', '${_boilingPt.toStringAsFixed(0)} °C'),
          _V('작용기', ['-OH','-COOH','-NH₂','-CHO','C=O','-CONH₂'][_groupType.toInt()]),
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

class _OrganicFunctionalGroupsScreenPainter extends CustomPainter {
  final double time;
  final double groupType;

  _OrganicFunctionalGroupsScreenPainter({
    required this.time,
    required this.groupType,
  });

  // Group definitions: [name, formula, polarity, color]
  static const _groups = [
    ['-OH', 'Alcohol', 'Polar', '알코올'],
    ['-COOH', 'Carboxylic', 'Polar', '카르복실산'],
    ['-CHO', 'Aldehyde', 'Polar', '알데히드'],
    ['C=O', 'Ketone', 'Polar', '케톤'],
    ['-NH₂', 'Amine', 'Polar', '아민'],
    ['-COO-', 'Ester', 'Low', '에스터'],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final int selected = groupType.toInt().clamp(0, 5);
    final cols = 3, rows = 2;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final bondPaint = Paint()
      ..color = const Color(0xFF5A8A9A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final selectedBondPaint = Paint()
      ..color = const Color(0xFF00D4FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final cx = cellW * col + cellW / 2;
      final cy = cellH * row + cellH / 2;
      final isSelected = (i == selected);

      // Cell background highlight
      if (isSelected) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: cellW - 4, height: cellH - 4),
            const Radius.circular(6),
          ),
          Paint()..color = const Color(0xFF00D4FF).withValues(alpha: 0.08),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: cellW - 4, height: cellH - 4),
            const Radius.circular(6),
          ),
          Paint()
            ..color = const Color(0xFF00D4FF).withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }

      // Draw structural formula for each group
      final bp = isSelected ? selectedBondPaint : bondPaint;
      final atomColor = isSelected ? const Color(0xFF00D4FF) : const Color(0xFF5A8A9A);
      _drawGroupStructure(canvas, i, cx, cy, bp, atomColor, time, isSelected);

      // Group name label
      final nameStyle = TextStyle(
        color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF5A8A9A),
        fontSize: 9,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      );
      final tp = TextPainter(
        text: TextSpan(text: _groups[i][3], style: nameStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy + 28));

      // Formula label
      final ftp = TextPainter(
        text: TextSpan(
          text: _groups[i][0],
          style: TextStyle(
            color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF5A8A9A).withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ftp.paint(canvas, Offset(cx - ftp.width / 2, cy + 38));
    }

    // Grid dividers
    final divPaint = Paint()
      ..color = const Color(0xFF1A3040)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(cellW, 0), Offset(cellW, size.height), divPaint);
    canvas.drawLine(Offset(cellW * 2, 0), Offset(cellW * 2, size.height), divPaint);
    canvas.drawLine(Offset(0, cellH), Offset(size.width, cellH), divPaint);
  }

  void _drawGroupStructure(Canvas canvas, int group, double cx, double cy,
      Paint bondPaint, Color atomColor, double t, bool animated) {
    final rot = animated ? math.sin(t * 1.2) * 0.08 : 0.0;
    final bgp = Paint()..color = const Color(0xFF0D1A20)..style = PaintingStyle.fill;

    void drawAtom(double x, double y, String label, {double r = 7}) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.drawCircle(Offset.zero, r, bgp);
      canvas.drawCircle(Offset.zero, r, Paint()..color = atomColor..style = PaintingStyle.stroke..strokeWidth = 1.0);
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: atomColor, fontSize: 7)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    void drawBond(double x1, double y1, double x2, double y2, {bool doubleBond = false}) {
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), bondPaint);
      if (doubleBond) {
        final dx = y2 - y1, dy = x1 - x2;
        final len = math.sqrt(dx * dx + dy * dy);
        if (len > 0) {
          final nx = dx / len * 2.5, ny = dy / len * 2.5;
          canvas.drawLine(Offset(x1 + nx, y1 + ny), Offset(x2 + nx, y2 + ny), bondPaint);
        }
      }
    }

    switch (group) {
      case 0: // -OH Alcohol: C-O-H
        drawBond(cx - 18, cy, cx, cy);
        drawBond(cx, cy, cx + 16, cy - 10);
        drawAtom(cx - 18, cy, 'C');
        drawAtom(cx, cy, 'O');
        drawAtom(cx + 16, cy - 10, 'H', r: 5);
        break;
      case 1: // -COOH Carboxylic acid: C(=O)-O-H
        drawBond(cx - 18, cy, cx, cy);
        drawBond(cx, cy, cx + 14, cy - 12, doubleBond: false);
        drawBond(cx, cy, cx + 14, cy + 10);
        drawBond(cx + 14, cy + 10, cx + 24, cy + 5);
        drawAtom(cx - 18, cy, 'C');
        drawAtom(cx, cy, 'C');
        drawAtom(cx + 14, cy - 12, 'O', r: 6);
        drawAtom(cx + 14, cy + 10, 'O');
        drawAtom(cx + 24, cy + 5, 'H', r: 5);
        // double bond mark
        canvas.drawLine(Offset(cx + 1, cy - 2), Offset(cx + 13, cy - 11),
            Paint()..color = atomColor..strokeWidth = 1.5);
        canvas.drawLine(Offset(cx + 3, cy + 1), Offset(cx + 15, cy - 9),
            Paint()..color = atomColor..strokeWidth = 1.5);
        break;
      case 2: // -CHO Aldehyde: C-C(=O)-H
        drawBond(cx - 15, cy, cx, cy);
        drawBond(cx, cy, cx + 15, cy + 8);
        drawAtom(cx - 15, cy, 'C');
        drawAtom(cx, cy, 'C');
        // =O up
        canvas.drawLine(Offset(cx, cy), Offset(cx + 4, cy - 16), bondPaint);
        canvas.drawLine(Offset(cx + 2, cy), Offset(cx + 6, cy - 16), bondPaint);
        drawAtom(cx + 5, cy - 16, 'O', r: 6);
        drawAtom(cx + 15, cy + 8, 'H', r: 5);
        break;
      case 3: // C=O Ketone: C-C(=O)-C
        drawBond(cx - 18, cy, cx, cy);
        drawBond(cx, cy, cx + 18, cy);
        canvas.drawLine(Offset(cx - 1, cy - 2), Offset(cx - 1, cy - 18), bondPaint);
        canvas.drawLine(Offset(cx + 2, cy - 2), Offset(cx + 2, cy - 18), bondPaint);
        drawAtom(cx - 18, cy, 'C');
        drawAtom(cx, cy, 'C');
        drawAtom(cx + 18, cy, 'C');
        drawAtom(cx, cy - 18, 'O', r: 6);
        break;
      case 4: // -NH2 Amine: C-N with 2H
        drawBond(cx - 15, cy, cx, cy);
        drawBond(cx, cy, cx + 12, cy - 12);
        drawBond(cx, cy, cx + 12, cy + 12);
        drawAtom(cx - 15, cy, 'C');
        drawAtom(cx, cy, 'N');
        drawAtom(cx + 12, cy - 12, 'H', r: 5);
        drawAtom(cx + 12, cy + 12, 'H', r: 5);
        break;
      case 5: // -COO- Ester: C-O-C=O
        drawBond(cx - 20, cy, cx - 6, cy);
        drawBond(cx - 6, cy, cx + 6, cy);
        drawBond(cx + 6, cy, cx + 20, cy);
        canvas.drawLine(Offset(cx + 6, cy), Offset(cx + 10, cy - 15), bondPaint);
        canvas.drawLine(Offset(cx + 8, cy), Offset(cx + 12, cy - 15), bondPaint);
        drawAtom(cx - 20, cy, 'C');
        drawAtom(cx - 6, cy, 'O');
        drawAtom(cx + 6, cy, 'C');
        drawAtom(cx + 20, cy, 'C');
        drawAtom(cx + 11, cy - 15, 'O', r: 6);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicFunctionalGroupsScreenPainter oldDelegate) => true;
}
