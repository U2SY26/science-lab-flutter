import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';
import '../../../shared/painters/projection_3d.dart';

/// Embedding Vectors Visualization
class EmbeddingVectorsScreen extends StatefulWidget {
  const EmbeddingVectorsScreen({super.key});

  @override
  State<EmbeddingVectorsScreen> createState() => _EmbeddingVectorsScreenState();
}

class _EmbeddingVectorsScreenState extends State<EmbeddingVectorsScreen>
    with SingleTickerProviderStateMixin, Rotation3DController {
  late AnimationController _controller;

  double _time = 0.0;
  bool _isAnimating = true;
  bool _showAnalogy = true;
  bool _showLabels = true;
  int _selectedWord = 0;
  bool _isKorean = true;

  // Embedding data: [word, x, y, z, groupId]
  // Groups: 0=animals(orange), 1=food(cyan), 2=emotions(green), 3=places(magenta)
  static const List<Map<String, dynamic>> _words = [
    // Animals
    {'w': 'dog',    'x': -0.8, 'y':  0.6, 'z': -0.3, 'g': 0},
    {'w': 'cat',    'x': -0.7, 'y':  0.8, 'z': -0.1, 'g': 0},
    {'w': 'bird',   'x': -0.6, 'y':  0.5, 'z':  0.4, 'g': 0},
    {'w': 'fish',   'x': -0.9, 'y':  0.3, 'z':  0.2, 'g': 0},
    {'w': 'lion',   'x': -1.0, 'y':  0.7, 'z': -0.5, 'g': 0},
    {'w': 'tiger',  'x': -0.5, 'y':  0.9, 'z': -0.4, 'g': 0},
    // Food
    {'w': 'apple',  'x':  0.8, 'y':  0.5, 'z': -0.6, 'g': 1},
    {'w': 'pizza',  'x':  0.6, 'y':  0.3, 'z': -0.8, 'g': 1},
    {'w': 'sushi',  'x':  0.9, 'y':  0.2, 'z': -0.5, 'g': 1},
    {'w': 'coffee', 'x':  0.7, 'y':  0.6, 'z': -0.3, 'g': 1},
    {'w': 'bread',  'x':  0.5, 'y':  0.4, 'z': -0.7, 'g': 1},
    // Emotions
    {'w': 'happy',  'x': -0.3, 'y': -0.7, 'z':  0.8, 'g': 2},
    {'w': 'sad',    'x': -0.5, 'y': -0.9, 'z':  0.6, 'g': 2},
    {'w': 'angry',  'x': -0.1, 'y': -0.8, 'z':  0.7, 'g': 2},
    {'w': 'love',   'x':  0.1, 'y': -0.6, 'z':  0.9, 'g': 2},
    {'w': 'fear',   'x': -0.4, 'y': -0.5, 'z':  0.5, 'g': 2},
    // Places
    {'w': 'Paris',  'x':  0.5, 'y': -0.4, 'z': -0.7, 'g': 3},
    {'w': 'Tokyo',  'x':  0.3, 'y': -0.6, 'z': -0.5, 'g': 3},
    {'w': 'Seoul',  'x':  0.4, 'y': -0.5, 'z': -0.6, 'g': 3},
    {'w': 'London', 'x':  0.6, 'y': -0.3, 'z': -0.8, 'g': 3},
    {'w': 'NYC',    'x':  0.2, 'y': -0.7, 'z': -0.4, 'g': 3},
    // Analogy: king, man, woman, queen
    {'w': 'king',   'x': -0.2, 'y':  0.2, 'z':  0.3, 'g': 4},
    {'w': 'queen',  'x':  0.1, 'y':  0.1, 'z':  0.4, 'g': 4},
    {'w': 'man',    'x': -0.3, 'y':  0.0, 'z':  0.2, 'g': 4},
    {'w': 'woman',  'x':  0.2, 'y': -0.1, 'z':  0.3, 'g': 4},
  ];

  static const List<Color> _groupColors = [
    Color(0xFFFF6B35), // animals: orange
    Color(0xFF00D4FF), // food: cyan
    Color(0xFF64FF8C), // emotions: green
    Color(0xFFFF44AA), // places: magenta
    Color(0xFFFFD700), // analogy words: gold
  ];

  @override
  void initState() {
    super.initState();
    rotX = 0.3;
    rotY = 0.4;
    scale3d = 75.0;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateAnimation);
    _controller.repeat();
  }

  void _updateAnimation() {
    if (!_isAnimating) return;
    setState(() {
      _time += 0.012;
      rotY += 0.008;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      rotX = 0.3;
      rotY = 0.4;
      scale3d = 75.0;
      _isAnimating = true;
      _selectedWord = 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isKorean ? '딥러닝 시뮬레이션' : 'DEEP LEARNING SIMULATION',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _isKorean ? '임베딩 벡터' : 'Embedding Vectors',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => _isKorean = !_isKorean),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: _isKorean ? '딥러닝 시뮬레이션' : 'DEEP LEARNING SIMULATION',
          title: _isKorean ? '임베딩 벡터 공간' : 'Embedding Vector Space',
          formula: 'sim(A,B) = A·B / (|A||B|)',
          formulaDescription: _isKorean
              ? '단어/개념을 고차원 벡터로 표현합니다. 의미가 비슷한 단어는 공간에서 가까이 위치하며, 벡터 연산으로 의미 유추가 가능합니다.'
              : 'Words/concepts are represented as high-dimensional vectors. Similar words cluster together, and vector arithmetic enables semantic analogy.',
          simulation: SizedBox(
            height: 380,
            child: GestureDetector(
              onPanStart: handlePanStart,
              onPanUpdate: (d) => handlePanUpdate(d, setState),
              child: CustomPaint(
                painter: _EmbeddingPainter(
                  time: _time,
                  rotX: rotX,
                  rotY: rotY,
                  scale: scale3d,
                  words: _words,
                  groupColors: _groupColors,
                  selectedWord: _selectedWord,
                  showAnalogy: _showAnalogy,
                  showLabels: _showLabels,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PresetGroup(
                label: _isKorean ? '카테고리' : 'Category',
                presets: [
                  PresetButton(
                    label: _isKorean ? '동물' : 'Animals',
                    isSelected: _selectedWord == 0,
                    onPressed: () { HapticFeedback.selectionClick(); setState(() => _selectedWord = 0); },
                  ),
                  PresetButton(
                    label: _isKorean ? '음식' : 'Food',
                    isSelected: _selectedWord == 1,
                    onPressed: () { HapticFeedback.selectionClick(); setState(() => _selectedWord = 1); },
                  ),
                  PresetButton(
                    label: _isKorean ? '감정' : 'Emotions',
                    isSelected: _selectedWord == 2,
                    onPressed: () { HapticFeedback.selectionClick(); setState(() => _selectedWord = 2); },
                  ),
                  PresetButton(
                    label: _isKorean ? '장소' : 'Places',
                    isSelected: _selectedWord == 3,
                    onPressed: () { HapticFeedback.selectionClick(); setState(() => _selectedWord = 3); },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ControlGroup(
                primaryControl: SimToggle(
                  label: _isKorean ? '의미 유추 화살표 표시' : 'Show Analogy Arrows',
                  value: _showAnalogy,
                  onChanged: (v) => setState(() => _showAnalogy = v),
                ),
                advancedControls: [
                  SimToggle(
                    label: _isKorean ? '레이블 표시' : 'Show Labels',
                    value: _showLabels,
                    onChanged: (v) => setState(() => _showLabels = v),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isAnimating
                    ? (_isKorean ? '정지' : 'Pause')
                    : (_isKorean ? '재생' : 'Play'),
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isAnimating = !_isAnimating);
                },
              ),
              SimButton(
                label: _isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmbeddingPainter extends CustomPainter {
  final double time;
  final double rotX;
  final double rotY;
  final double scale;
  final List<Map<String, dynamic>> words;
  final List<Color> groupColors;
  final int selectedWord;
  final bool showAnalogy;
  final bool showLabels;

  _EmbeddingPainter({
    required this.time,
    required this.rotX,
    required this.rotY,
    required this.scale,
    required this.words,
    required this.groupColors,
    required this.selectedWord,
    required this.showAnalogy,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0D1A20),
    );

    final center = Offset(size.width / 2, size.height * 0.48);
    final proj = Projection3D(
      rotX: rotX,
      rotY: rotY,
      scale: scale * (size.width / 320),
      center: center,
    );

    // Draw 3D grid (XZ plane)
    _drawGrid(canvas, proj);

    // Draw axes
    _drawAxes(canvas, proj, size);

    // Sort words by depth for correct overdraw order
    final sortedIndices = List.generate(words.length, (i) => i)
      ..sort((a, b) {
        final wa = words[a];
        final wb = words[b];
        return proj.depth(
          (wa['x'] as double),
          (wa['y'] as double),
          (wa['z'] as double),
        ).compareTo(
          proj.depth(
            (wb['x'] as double),
            (wb['y'] as double),
            (wb['z'] as double),
          ),
        );
      });

    // Draw cluster halos
    _drawClusterHalos(canvas, proj);

    // Draw analogy arrows
    if (showAnalogy) {
      _drawAnalogyArrows(canvas, proj);
    }

    // Draw word points
    for (final idx in sortedIndices) {
      _drawWordPoint(canvas, proj, idx);
    }

    // Draw info panel
    _drawInfoPanel(canvas, size);
  }

  void _drawGrid(Canvas canvas, Projection3D proj) {
    Projection3D.drawGridPlane(
      canvas, proj, 2.4,
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.08)
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke,
      divisions: 8,
    );
  }

  void _drawAxes(Canvas canvas, Projection3D proj, Size size) {
    final axisData = [
      {'label': 'Semantic 1', 'ex': 1.3, 'ey': 0.0, 'ez': 0.0, 'color': const Color(0xFFFF6B35)},
      {'label': 'Semantic 2', 'ex': 0.0, 'ey': 1.3, 'ez': 0.0, 'color': const Color(0xFF64FF8C)},
      {'label': 'Semantic 3', 'ex': 0.0, 'ey': 0.0, 'ez': 1.3, 'color': const Color(0xFF00D4FF)},
    ];
    final origin = proj.project(0, 0, 0);
    for (final ax in axisData) {
      final end = proj.project(
        (ax['ex'] as double), (ax['ey'] as double), (ax['ez'] as double),
      );
      final col = ax['color'] as Color;
      canvas.drawLine(origin, end, Paint()..color = col.withValues(alpha: 0.4)..strokeWidth = 1.2);
      final tp = TextPainter(
        text: TextSpan(text: ax['label'] as String, style: TextStyle(color: col.withValues(alpha: 0.6), fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(end.dx - tp.width / 2, end.dy - tp.height - 2));
    }
  }

  void _drawClusterHalos(Canvas canvas, Projection3D proj) {
    // For each group, draw a soft halo connecting cluster members
    for (int g = 0; g < 5; g++) {
      final groupWords = words.where((w) => w['g'] == g).toList();
      if (groupWords.isEmpty) continue;
      // Find centroid
      double cx = 0, cy = 0, cz = 0;
      for (final w in groupWords) {
        cx += w['x'] as double;
        cy += w['y'] as double;
        cz += w['z'] as double;
      }
      cx /= groupWords.length;
      cy /= groupWords.length;
      cz /= groupWords.length;
      final centroid2d = proj.project(cx, cy, cz);
      final col = groupColors[g];
      // Halo
      final pulse = 0.5 + 0.5 * math.sin(time * 1.5 + g * 1.2);
      canvas.drawCircle(
        centroid2d,
        28.0 + 4 * pulse,
        Paint()
          ..color = col.withValues(alpha: 0.04 + 0.02 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
      // Thin lines from centroid to members
      for (final w in groupWords) {
        final wp = proj.project(w['x'] as double, w['y'] as double, w['z'] as double);
        canvas.drawLine(
          centroid2d, wp,
          Paint()
            ..color = col.withValues(alpha: 0.08)
            ..strokeWidth = 0.7,
        );
      }
    }
  }

  void _drawAnalogyArrows(Canvas canvas, Projection3D proj) {
    // king - man + woman = queen
    // Find relevant words
    Map<String, dynamic>? kingW, manW, womanW, queenW;
    for (final w in words) {
      switch (w['w']) {
        case 'king':  kingW = w;
        case 'man':   manW = w;
        case 'woman': womanW = w;
        case 'queen': queenW = w;
      }
    }
    if (kingW == null || manW == null || womanW == null || queenW == null) return;

    final kingP = proj.project(kingW['x'] as double, kingW['y'] as double, kingW['z'] as double);
    final manP = proj.project(manW['x'] as double, manW['y'] as double, manW['z'] as double);
    final womanP = proj.project(womanW['x'] as double, womanW['y'] as double, womanW['z'] as double);
    final queenP = proj.project(queenW['x'] as double, queenW['y'] as double, queenW['z'] as double);

    // Animate: pulsing arrow
    final pulse = 0.6 + 0.4 * math.sin(time * 2.5);

    // king -> man (subtract)
    _drawArrow(canvas, kingP, manP, const Color(0xFFFF6B35).withValues(alpha: 0.7 * pulse), 1.5, '- man');
    // king -> queen (result)
    _drawArrow(canvas, kingP, queenP, const Color(0xFFFFD700).withValues(alpha: 0.8 * pulse), 2.0, '');
    // woman (add) hint
    _drawArrow(canvas, manP, womanP, const Color(0xFF64FF8C).withValues(alpha: 0.6 * pulse), 1.5, '+ woman');

    // Label
    final tp = TextPainter(
      text: TextSpan(
        text: 'king - man + woman ≈ queen',
        style: TextStyle(
          color: const Color(0xFFFFD700).withValues(alpha: 0.85),
          fontSize: 9,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(kingP.dx - tp.width / 2, kingP.dy - 22));
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color, double strokeWidth, String label) {
    canvas.drawLine(from, to, Paint()..color = color..strokeWidth = strokeWidth..strokeCap = StrokeCap.round);
    // Arrowhead
    final dir = (to - from);
    final len = dir.distance;
    if (len < 1) return;
    final norm = dir / len;
    final perp = Offset(-norm.dy, norm.dx);
    final tip = to;
    final base = tip - norm * 8;
    final left = base + perp * 4;
    final right = base - perp * 4;
    canvas.drawPath(
      Path()..moveTo(tip.dx, tip.dy)..lineTo(left.dx, left.dy)..lineTo(right.dx, right.dy)..close(),
      Paint()..color = color,
    );
    if (label.isNotEmpty) {
      final mid = Offset((from.dx + to.dx) / 2 + 6, (from.dy + to.dy) / 2 - 10);
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: color, fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, mid);
    }
  }

  void _drawWordPoint(Canvas canvas, Projection3D proj, int idx) {
    final w = words[idx];
    final group = w['g'] as int;
    final col = groupColors[group];
    final p = proj.project(w['x'] as double, w['y'] as double, w['z'] as double);
    final isSelectedGroup = group == selectedWord || (group == 4);
    final pulse = isSelectedGroup
        ? (1.0 + 0.3 * math.sin(time * 3 + idx * 0.7))
        : 1.0;
    final radius = isSelectedGroup ? 5.5 * pulse : 3.5;

    // Outer glow
    canvas.drawCircle(
      p,
      radius * 2.5,
      Paint()
        ..color = col.withValues(alpha: isSelectedGroup ? 0.25 : 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Main dot
    canvas.drawCircle(p, radius, Paint()..color = col);
    // Bright center
    canvas.drawCircle(p, radius * 0.45, Paint()..color = Colors.white.withValues(alpha: 0.8));

    // Label
    if (showLabels && (isSelectedGroup || idx < 6)) {
      final tp = TextPainter(
        text: TextSpan(
          text: w['w'] as String,
          style: TextStyle(
            color: col,
            fontSize: isSelectedGroup ? 9.5 : 8.0,
            fontWeight: isSelectedGroup ? FontWeight.w600 : FontWeight.normal,
            shadows: const [Shadow(blurRadius: 4, color: Color(0xFF0D1A20))],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx + radius + 2, p.dy - tp.height / 2));
    }
  }

  void _drawInfoPanel(Canvas canvas, Size size) {
    // Cosine similarity top-3 for selected group
    final groupNames = ['Animals', 'Food', 'Emotions', 'Places', 'Royalty'];
    final groupName = groupNames[selectedWord.clamp(0, groupNames.length - 1)];

    final panel = Rect.fromLTWH(8, 8, 140, 68);
    canvas.drawRRect(
      RRect.fromRectAndRadius(panel, const Radius.circular(8)),
      Paint()..color = const Color(0xFF0D1A20).withValues(alpha: 0.88),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panel, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFF00D4FF).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    void drawText(String text, Offset offset, double fs, Color c) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: c, fontSize: fs)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, offset);
    }

    drawText('Selected: $groupName', Offset(panel.left + 6, panel.top + 6), 8.5, const Color(0xFF00D4FF));
    drawText('dim: 768 → 3D proj', Offset(panel.left + 6, panel.top + 22), 8, const Color(0xFF5A8A9A));
    drawText('Cosine sim (intra):', Offset(panel.left + 6, panel.top + 36), 8, const Color(0xFFE0F4FF));
    final simVal = 0.82 + 0.1 * math.sin(time * 0.7);
    drawText('≈ ${simVal.toStringAsFixed(2)}', Offset(panel.left + 100, panel.top + 36), 8, const Color(0xFF64FF8C));
    drawText('(inter-cluster) ≈ 0.12', Offset(panel.left + 6, panel.top + 52), 8, const Color(0xFF5A8A9A));
  }

  @override
  bool shouldRepaint(covariant _EmbeddingPainter old) => true;
}
