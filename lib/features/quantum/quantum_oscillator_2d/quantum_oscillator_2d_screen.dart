import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class QuantumOscillator2dScreen extends StatefulWidget {
  const QuantumOscillator2dScreen({super.key});
  @override
  State<QuantumOscillator2dScreen> createState() => _QuantumOscillator2dScreenState();
}

class _QuantumOscillator2dScreenState extends State<QuantumOscillator2dScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _nX = 1;
  double _nY = 0;
  double _energy = 0;

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
      _energy = (_nX + _nY + 1);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _nX = 1; _nY = 0;
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
          Text('양자역학 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('2차원 양자 조화 진동자', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '2차원 양자 조화 진동자',
          formula: 'E=(n_x+n_y+1)ℏω',
          formulaDescription: '2차원 양자 조화 진동자의 파동함수를 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _QuantumOscillator2dScreenPainter(
                time: _time,
                nX: _nX,
                nY: _nY,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '양자 수 n_x',
                value: _nX,
                min: 0,
                max: 8,
                step: 1,
                defaultValue: 1,
                formatValue: (v) => 'n_x = ${v.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => _nX = v),
              ),
              advancedControls: [
            SimSlider(
                label: '양자 수 n_y',
                value: _nY,
                min: 0,
                max: 8,
                step: 1,
                defaultValue: 0,
                formatValue: (v) => 'n_y = ${v.toStringAsFixed(0)}',
                onChanged: (v) => setState(() => _nY = v),
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
          _V('n_x', _nX.toStringAsFixed(0)),
          _V('n_y', _nY.toStringAsFixed(0)),
          _V('E/ℏω', _energy.toStringAsFixed(0)),
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

class _QuantumOscillator2dScreenPainter extends CustomPainter {
  final double time;
  final double nX;
  final double nY;

  _QuantumOscillator2dScreenPainter({
    required this.time,
    required this.nX,
    required this.nY,
  });

  void _label(Canvas canvas, String text, Offset offset,
      {double fontSize = 9, Color color = const Color(0xFF5A8A9A)}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  // Hermite polynomial H_n(x)
  double _hermite(int n, double x) {
    if (n == 0) return 1.0;
    if (n == 1) return 2.0 * x;
    double hPrev = 1.0, hCur = 2.0 * x;
    for (int k = 2; k <= n; k++) {
      final hNext = 2.0 * x * hCur - 2.0 * (k - 1) * hPrev;
      hPrev = hCur;
      hCur = hNext;
    }
    return hCur;
  }

  // 1D harmonic oscillator wavefunction psi_n(x)
  double _psi1D(int n, double x) {
    final gauss = math.exp(-x * x / 2.0);
    final hn = _hermite(n, x);
    // normalization constant (not critical for visualization)
    return gauss * hn;
  }

  // 2D probability density |psi_nx(x) * psi_ny(y)|^2
  double _prob2D(int nx, int ny, double x, double y) {
    final px = _psi1D(nx, x);
    final py = _psi1D(ny, y);
    return px * px * py * py;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final w = size.width;
    final h = size.height;
    final nx = nX.round().clamp(0, 8);
    final ny = nY.round().clamp(0, 8);

    // Layout: center square colormap, right strip = y-slice, bottom strip = x-slice
    final marginR = w * 0.20;
    final marginB = h * 0.20;
    final padL = 14.0, padT = 14.0;

    final mapLeft = padL;
    final mapTop = padT;
    final mapRight = w - marginR - 4;
    final mapBot = h - marginB - 4;
    final mapW = mapRight - mapLeft;
    final mapH = mapBot - mapTop;

    // Phase space range: -4 to +4 (covers most probability)
    final range = 4.0;

    // Compute probability density on grid
    const gridN = 50;
    final cells = List.generate(gridN, (_) => List.filled(gridN, 0.0));
    double pMax = 0;

    for (int ix = 0; ix < gridN; ix++) {
      for (int iy = 0; iy < gridN; iy++) {
        final xv = -range + (ix + 0.5) / gridN * 2 * range;
        final yv = -range + (iy + 0.5) / gridN * 2 * range;
        final p = _prob2D(nx, ny, xv, yv);
        cells[ix][iy] = p;
        if (p > pMax) pMax = p;
      }
    }
    if (pMax < 1e-10) pMax = 1.0;

    final cellW = mapW / gridN;
    final cellH = mapH / gridN;

    // Draw colormap: probability density with cyan palette
    for (int ix = 0; ix < gridN; ix++) {
      for (int iy = 0; iy < gridN; iy++) {
        final t = (cells[ix][iy] / pMax).clamp(0.0, 1.0);
        // Color gradient: dark bg -> deep blue -> cyan -> white
        final Color cellColor;
        if (t < 0.3) {
          cellColor = Color.lerp(
              const Color(0xFF0D1A20), const Color(0xFF003344), t / 0.3)!;
        } else if (t < 0.7) {
          cellColor = Color.lerp(
              const Color(0xFF003344), const Color(0xFF00D4FF), (t - 0.3) / 0.4)!;
        } else {
          cellColor = Color.lerp(
              const Color(0xFF00D4FF), const Color(0xFFE0F4FF), (t - 0.7) / 0.3)!;
        }
        final cx = mapLeft + ix * cellW;
        final cy = mapBot - (iy + 1) * cellH;
        canvas.drawRect(
          Rect.fromLTWH(cx, cy, cellW + 0.5, cellH + 0.5),
          Paint()..color = cellColor,
        );
      }
    }

    // Axes (center crosshairs)
    final axisPaint = Paint()..color = const Color(0xFF1A3040)..strokeWidth = 1;
    final axisX = mapLeft + mapW / 2;
    final axisY = mapTop + mapH / 2;
    canvas.drawLine(Offset(mapLeft, axisY), Offset(mapRight, axisY), axisPaint);
    canvas.drawLine(Offset(axisX, mapTop), Offset(axisX, mapBot), axisPaint);
    _label(canvas, 'x', Offset(mapRight - 8, axisY + 2));
    _label(canvas, 'y', Offset(axisX + 2, mapTop));

    // ---- Right strip: y-slice at x=0 ----
    final rLeft = mapRight + 6;
    final rRight = w - 2.0;
    final rW = rRight - rLeft;

    // |psi_ny(y)|^2 profile
    final ySlicePath = Path()..moveTo(rLeft, mapBot);
    double ySliceMax = 0;
    final ySliceVals = List.filled(gridN, 0.0);
    for (int iy = 0; iy < gridN; iy++) {
      final yv = -range + (iy + 0.5) / gridN * 2 * range;
      final p = _psi1D(ny, yv);
      ySliceVals[iy] = p * p;
      if (p * p > ySliceMax) ySliceMax = p * p;
    }
    if (ySliceMax < 1e-10) ySliceMax = 1.0;
    for (int iy = 0; iy < gridN; iy++) {
      final py = mapBot - (iy + 0.5) / gridN * mapH;
      final px = rLeft + ySliceVals[iy] / ySliceMax * rW;
      ySlicePath.lineTo(px, py);
    }
    ySlicePath.lineTo(rLeft, mapTop);
    ySlicePath.close();
    canvas.drawPath(ySlicePath,
        Paint()..color = const Color(0xFF64FF8C).withValues(alpha: 0.35));
    final ySliceStroke = Path()..moveTo(rLeft, mapBot);
    for (int iy = 0; iy < gridN; iy++) {
      final py = mapBot - (iy + 0.5) / gridN * mapH;
      final px = rLeft + ySliceVals[iy] / ySliceMax * rW;
      ySliceStroke.lineTo(px, py);
    }
    canvas.drawPath(ySliceStroke,
        Paint()..color = const Color(0xFF64FF8C)..strokeWidth = 1.2..style = PaintingStyle.stroke);
    _label(canvas, '|ψ_y|²', Offset(rLeft, mapTop - 12), color: const Color(0xFF64FF8C), fontSize: 8);

    // ---- Bottom strip: x-slice at y=0 ----
    final bTop = mapBot + 6;
    final bBot = h - 2.0;
    final bH = bBot - bTop;

    final xSliceVals = List.filled(gridN, 0.0);
    double xSliceMax = 0;
    for (int ix = 0; ix < gridN; ix++) {
      final xv = -range + (ix + 0.5) / gridN * 2 * range;
      final p = _psi1D(nx, xv);
      xSliceVals[ix] = p * p;
      if (p * p > xSliceMax) xSliceMax = p * p;
    }
    if (xSliceMax < 1e-10) xSliceMax = 1.0;
    final midB = bTop + bH / 2;
    final xSlicePath = Path()..moveTo(mapLeft, midB);
    for (int ix = 0; ix < gridN; ix++) {
      final px = mapLeft + (ix + 0.5) / gridN * mapW;
      final py = midB - xSliceVals[ix] / xSliceMax * bH * 0.45;
      xSlicePath.lineTo(px, py);
    }
    xSlicePath.lineTo(mapRight, midB);
    xSlicePath.close();
    canvas.drawPath(xSlicePath,
        Paint()..color = const Color(0xFFFF6B35).withValues(alpha: 0.3));
    final xSliceStroke = Path()..moveTo(mapLeft, midB);
    for (int ix = 0; ix < gridN; ix++) {
      final px = mapLeft + (ix + 0.5) / gridN * mapW;
      final py = midB - xSliceVals[ix] / xSliceMax * bH * 0.45;
      xSliceStroke.lineTo(px, py);
    }
    canvas.drawPath(xSliceStroke,
        Paint()..color = const Color(0xFFFF6B35)..strokeWidth = 1.2..style = PaintingStyle.stroke);
    _label(canvas, '|ψ_x|²', Offset(mapRight + 2, bTop), color: const Color(0xFFFF6B35), fontSize: 8);

    // Energy and degeneracy label
    final energy = nx + ny + 1;
    final degeneracy = energy; // degeneracy = nx+ny+1 for 2D isotropic
    _label(canvas, 'E=($nx+$ny+1)ℏω = ${energy}ℏω', Offset(padL, mapTop),
        color: const Color(0xFF00D4FF), fontSize: 9);
    _label(canvas, 'g=$degeneracy', Offset(padL + mapW * 0.65, mapTop),
        color: const Color(0xFF5A8A9A), fontSize: 9);
    _label(canvas, '(nx=$nx, ny=$ny)', Offset(padL, mapBot + 4),
        color: const Color(0xFF5A8A9A), fontSize: 8);
  }

  @override
  bool shouldRepaint(covariant _QuantumOscillator2dScreenPainter oldDelegate) => true;
}
