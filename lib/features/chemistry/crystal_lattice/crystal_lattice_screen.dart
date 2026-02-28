import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class CrystalLatticeScreen extends StatefulWidget {
  const CrystalLatticeScreen({super.key});
  @override
  State<CrystalLatticeScreen> createState() => _CrystalLatticeScreenState();
}

class _CrystalLatticeScreenState extends State<CrystalLatticeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _latticeType = 0;
  
  int _atoms = 1, _coordination = 6;

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
      final t = _latticeType.toInt();
      _atoms = [1, 2, 4, 6][t];
      _coordination = [6, 8, 12, 12][t];
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _latticeType = 0.0;
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
          const Text('결정 격자 구조', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학 시뮬레이션',
          title: '결정 격자 구조',
          formula: 'a, b, c, α, β, γ',
          formulaDescription: '다양한 결정 격자 구조를 3D로 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CrystalLatticeScreenPainter(
                time: _time,
                latticeType: _latticeType,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '격자 유형',
                value: _latticeType,
                min: 0,
                max: 3,
                step: 1,
                defaultValue: 0,
                formatValue: (v) => ['SC','BCC','FCC','HCP'][v.toInt()],
                onChanged: (v) => setState(() => _latticeType = v),
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
          _V('원자/셀', '$_atoms'),
          _V('배위수', '$_coordination'),
          _V('유형', ['SC','BCC','FCC','HCP'][_latticeType.toInt()]),
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

class _CrystalLatticeScreenPainter extends CustomPainter {
  final double time;
  final double latticeType;

  _CrystalLatticeScreenPainter({
    required this.time,
    required this.latticeType,
  });

  // Isometric projection: rotate around Y axis by rotY
  Offset _project(double x, double y, double z, double rotY, Size size) {
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final rx = x * cosY + z * sinY;
    final rz = -x * sinY + z * cosY;
    // Then tilt: simple isometric tilt around X
    const tilt = 0.4;
    final px = rx;
    final py = -y + rz * tilt;
    final scale = size.height * 0.22;
    return Offset(size.width / 2 + px * scale, size.height / 2 + py * scale);
  }

  double _depth(double x, double y, double z, double rotY) {
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    return -x * sinY + z * cosY;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0D1A20));

    final rotY = time * 0.5;
    final type = latticeType.toInt().clamp(0, 3);

    // Build atom positions in unit cell coords [-0.5, 0.5]
    // Corners shared by all
    final corners = <List<double>>[
      [-0.5, -0.5, -0.5], [0.5, -0.5, -0.5], [-0.5, 0.5, -0.5], [0.5, 0.5, -0.5],
      [-0.5, -0.5,  0.5], [0.5, -0.5,  0.5], [-0.5, 0.5,  0.5], [0.5, 0.5,  0.5],
    ];

    final faceAtoms = <List<double>>[];
    final bodyAtom = <List<double>>[];

    if (type == 1 || type == 3) {
      // BCC or HCP (treat HCP as BCC for simplicity)
      bodyAtom.add([0, 0, 0]);
    }
    if (type == 2) {
      // FCC face centers
      faceAtoms.addAll([
        [0, 0, -0.5], [0, 0, 0.5],
        [0, -0.5, 0], [0, 0.5, 0],
        [-0.5, 0, 0], [0.5, 0, 0],
      ]);
    }

    // Collect all atoms with depth
    final allAtoms = <Map<String, dynamic>>[];
    for (final c in corners) {
      allAtoms.add({'pos': c, 'type': 'corner'});
    }
    for (final f in faceAtoms) {
      allAtoms.add({'pos': f, 'type': 'face'});
    }
    for (final b in bodyAtom) {
      allAtoms.add({'pos': b, 'type': 'body'});
    }
    allAtoms.sort((a, b) {
      final pa = a['pos'] as List<double>;
      final pb = b['pos'] as List<double>;
      return _depth(pa[0], pa[1], pa[2], rotY).compareTo(_depth(pb[0], pb[1], pb[2], rotY));
    });

    // Draw lattice edges
    final edgePaint = Paint()
      ..color = const Color(0xFF5A8A9A).withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final edgeIndices = [
      [0,1],[2,3],[4,5],[6,7],
      [0,2],[1,3],[4,6],[5,7],
      [0,4],[1,5],[2,6],[3,7],
    ];
    for (final e in edgeIndices) {
      final a = corners[e[0]];
      final b2 = corners[e[1]];
      final pa = _project(a[0], a[1], a[2], rotY, size);
      final pb = _project(b2[0], b2[1], b2[2], rotY, size);
      canvas.drawLine(pa, pb, edgePaint);
    }

    // Draw atoms
    for (final atom in allAtoms) {
      final pos = atom['pos'] as List<double>;
      final atype = atom['type'] as String;
      final proj = _project(pos[0], pos[1], pos[2], rotY, size);
      double r;
      Color col;
      if (atype == 'corner') {
        r = 7; col = const Color(0xFF00D4FF);
      } else if (atype == 'face') {
        r = 9; col = const Color(0xFF64FF8C);
      } else {
        r = 11; col = const Color(0xFFFF6B35);
      }
      canvas.drawCircle(proj, r, Paint()..color = col.withValues(alpha: 0.25));
      canvas.drawCircle(proj, r, Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = 1.5);
      canvas.drawCircle(proj, r * 0.4, Paint()..color = col.withValues(alpha: 0.8));
    }

    // Labels
    final typeNames = ['SC', 'BCC', 'FCC', 'HCP'];
    final coordNums = ['6', '8', '12', '12'];
    final atomCounts = ['1', '2', '4', '6'];
    _drawText(canvas, typeNames[type], Offset(12, 12), 13, const Color(0xFF00D4FF), bold: true);
    _drawText(canvas, '배위수: ${coordNums[type]}', Offset(12, 30), 10, const Color(0xFF5A8A9A));
    _drawText(canvas, '원자/셀: ${atomCounts[type]}', Offset(12, 44), 10, const Color(0xFF5A8A9A));

    // Legend
    _drawText(canvas, '● 꼭짓점', Offset(size.width - 70, 12), 9, const Color(0xFF00D4FF));
    if (type == 2) _drawText(canvas, '● 면심', Offset(size.width - 70, 24), 9, const Color(0xFF64FF8C));
    if (type == 1 || type == 3) _drawText(canvas, '● 체심', Offset(size.width - 70, 24), 9, const Color(0xFFFF6B35));
  }

  void _drawText(Canvas canvas, String text, Offset offset, double fontSize, Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _CrystalLatticeScreenPainter oldDelegate) => true;
}
