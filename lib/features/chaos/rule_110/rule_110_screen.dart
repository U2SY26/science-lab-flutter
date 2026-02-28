import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class Rule110Screen extends StatefulWidget {
  const Rule110Screen({super.key});
  @override
  State<Rule110Screen> createState() => _Rule110ScreenState();
}

class _Rule110ScreenState extends State<Rule110Screen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _ruleNumber = 110;
  double _gridSize = 50;


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
      
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _ruleNumber = 110; _gridSize = 50;
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
          Text('카오스/복잡계 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('규칙 110 오토마타', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '카오스/복잡계 시뮬레이션',
          title: '규칙 110 오토마타',
          formula: 'Rule 110: 01101110₂',
          formulaDescription: '튜링 완전한 규칙 110 셀룰러 오토마타를 탐구합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _Rule110ScreenPainter(
                time: _time,
                ruleNumber: _ruleNumber,
                gridSize: _gridSize,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '규칙 번호',
                value: _ruleNumber,
                min: 0,
                max: 255,
                step: 1,
                defaultValue: 110,
                formatValue: (v) => '규칙 ${v.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => _ruleNumber = v),
              ),
              advancedControls: [
            SimSlider(
                label: '격자 크기',
                value: _gridSize,
                min: 20,
                max: 100,
                step: 5,
                defaultValue: 50,
                formatValue: (v) => v.toStringAsFixed(0),
                onChanged: (v) => setState(() => _gridSize = v),
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
          _V('규칙', _ruleNumber.toStringAsFixed(0)),
          _V('격자', '${_gridSize.toStringAsFixed(0)}×${_gridSize.toStringAsFixed(0)}'),
          _V('세대', (_time * 10).toStringAsFixed(0)),
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

class _Rule110ScreenPainter extends CustomPainter {
  final double time;
  final double ruleNumber;
  final double gridSize;

  _Rule110ScreenPainter({
    required this.time,
    required this.ruleNumber,
    required this.gridSize,
  });

  // Apply 1D cellular automaton rule
  int _applyRule(int left, int center, int right, int rule) {
    final pattern = (left << 2) | (center << 1) | right;
    return (rule >> pattern) & 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 1 || size.height < 1) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final rule = ruleNumber.toInt().clamp(0, 255);
    const int cols = 100;
    // Reserve bottom area for rule pattern display
    const double ruleDisplayH = 36.0;
    final availH = size.height - ruleDisplayH;
    final cellW = size.width / cols;
    final rows = (availH / cellW).floor().clamp(1, 60);
    final cellH = availH / rows;

    // Generate initial row: single center cell
    final gen0 = List<int>.filled(cols, 0);
    gen0[cols ~/ 2] = 1;

    // Generate all rows
    final grid = <List<int>>[gen0];
    for (int r = 1; r < rows; r++) {
      final prev = grid[r - 1];
      final next = List<int>.filled(cols, 0);
      for (int c = 0; c < cols; c++) {
        final l = prev[(c - 1 + cols) % cols];
        final ctr = prev[c];
        final rt = prev[(c + 1) % cols];
        next[c] = _applyRule(l, ctr, rt, rule);
      }
      grid.add(next);
    }

    // Animate: reveal rows one by one
    final revealRows = ((time * 12) % (rows + 8)).toInt().clamp(0, rows);

    // Glow paint for cyan cells
    final glowPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Draw cells
    for (int r = 0; r < revealRows; r++) {
      for (int c = 0; c < cols; c++) {
        if (grid[r][c] == 1) {
          final rect = Rect.fromLTWH(c * cellW, r * cellH, cellW - 0.3, cellH - 0.3);
          // Glow for Rule 110 "gliders"
          if (rule == 110) {
            canvas.drawRect(rect.inflate(1), glowPaint);
          }
          // Determine color: use orange glow for rule 110 complex patterns
          Color cellColor = AppColors.accent;
          if (rule == 110 && r > 10) {
            // Check if this is a "complex" region by neighbor count
            int nbCount = 0;
            if (c > 0 && r > 0 && grid[r - 1][c - 1] == 1) nbCount++;
            if (r > 0 && grid[r - 1][c] == 1) nbCount++;
            if (c < cols - 1 && r > 0 && grid[r - 1][c + 1] == 1) nbCount++;
            if (nbCount == 2) cellColor = AppColors.accent2;
          }
          canvas.drawRect(rect, Paint()..color = cellColor.withValues(alpha: 0.9));
        }
      }
    }

    // Bottom: 8-bit rule pattern display
    final ruleY = availH + 4;
    final patW = size.width / 8;
    for (int p = 7; p >= 0; p--) {
      final bit = (rule >> p) & 1;
      final rx = (7 - p) * patW;
      // Pattern label (3 bits)
      final patStr = '${(p >> 2) & 1}${(p >> 1) & 1}${p & 1}';
      final patColor = bit == 1 ? AppColors.accent : AppColors.muted.withValues(alpha: 0.3);
      canvas.drawRect(
        Rect.fromLTWH(rx + 1, ruleY + 14, patW - 2, ruleDisplayH - 18),
        Paint()..color = patColor,
      );
      final tp = TextPainter(
        text: TextSpan(text: patStr, style: const TextStyle(color: AppColors.muted, fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(rx + (patW - tp.width) / 2, ruleY));
    }

    // Generation counter
    final genTp = TextPainter(
      text: TextSpan(
        text: '규칙 $rule  세대: $revealRows',
        style: const TextStyle(color: AppColors.muted, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    genTp.paint(canvas, Offset(2, availH - 12));
  }

  @override
  bool shouldRepaint(covariant _Rule110ScreenPainter oldDelegate) => true;
}
