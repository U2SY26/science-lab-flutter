import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class MazeRlScreen extends StatefulWidget {
  const MazeRlScreen({super.key});
  @override
  State<MazeRlScreen> createState() => _MazeRlScreenState();
}

class _MazeRlScreenState extends State<MazeRlScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _learningRateRL = 0.1;
  double _discountFactor = 0.95;
  double _episode = 0, _reward = 0;

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
      _episode = _time * 2;
      _reward = math.min(100, _episode * _learningRateRL * 10);
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _learningRateRL = 0.1; _discountFactor = 0.95;
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
          Text('AI/ML 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('미로 강화학습', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '미로 강화학습',
          formula: 'Q(s,a) \u2190 Q + \u03B1[r + \u03B3 max Q\u2032 - Q]',
          formulaDescription: 'RL 에이전트가 미로를 푸는 것을 관찰합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _MazeRlScreenPainter(
                time: _time,
                learningRateRL: _learningRateRL,
                discountFactor: _discountFactor,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '학습률 α',
                value: _learningRateRL,
                min: 0.01,
                max: 1,
                step: 0.01,
                defaultValue: 0.1,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _learningRateRL = v),
              ),
              advancedControls: [
            SimSlider(
                label: '할인 인자 γ',
                value: _discountFactor,
                min: 0.5,
                max: 0.99,
                step: 0.01,
                defaultValue: 0.95,
                formatValue: (v) => v.toStringAsFixed(2),
                onChanged: (v) => setState(() => _discountFactor = v),
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
          _V('에피소드', _episode.toStringAsFixed(0)),
          _V('보상', _reward.toStringAsFixed(1)),
          _V('γ', _discountFactor.toStringAsFixed(2)),
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

class _MazeRlScreenPainter extends CustomPainter {
  final double time;
  final double learningRateRL;
  final double discountFactor;

  _MazeRlScreenPainter({
    required this.time,
    required this.learningRateRL,
    required this.discountFactor,
  });

  static const int _cols = 7;
  static const int _rows = 7;

  // Precomputed maze walls: each entry is a Set of blocked directions (0=up,1=right,2=down,3=left)
  // Encoded as bitmask per cell: bit0=up, bit1=right, bit2=down, bit3=left
  static final List<List<int>> _walls = _buildMaze();

  static List<List<int>> _buildMaze() {
    final rng = math.Random(42);
    // Start with all walls up, then carve using DFS
    final walls = List.generate(_rows, (_) => List.filled(_cols, 0xF)); // all 4 walls
    final visited = List.generate(_rows, (_) => List.filled(_cols, false));

    void carve(int r, int c) {
      visited[r][c] = true;
      final dirs = [0, 1, 2, 3]..shuffle(rng);
      for (final d in dirs) {
        final nr = r + [-1, 0, 1, 0][d];
        final nc = c + [0, 1, 0, -1][d];
        if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) continue;
        if (visited[nr][nc]) continue;
        // Remove wall between (r,c) and (nr,nc)
        walls[r][c] &= ~(1 << d);
        walls[nr][nc] &= ~(1 << [2, 3, 0, 1][d]);
        carve(nr, nc);
      }
    }

    carve(0, 0);
    return walls;
  }

  // Precomputed Q-values (simulated)
  static double _qValue(int r, int c, double lr, double gamma) {
    // Distance-to-goal heuristic, influenced by lr & gamma
    final goalR = _rows - 1, goalC = _cols - 1;
    final dist = (goalR - r).abs() + (goalC - c).abs();
    final maxDist = _rows + _cols - 2;
    return (1.0 - dist / maxDist) * gamma * (0.5 + lr * 0.5);
  }

  // Agent path via simple BFS from (0,0) to (rows-1,cols-1)
  static List<List<int>> _findPath() {
    final prev = List.generate(_rows, (_) => List.filled(_cols, -1));
    final queue = <List<int>>[[0, 0]];
    final visited = List.generate(_rows, (_) => List.filled(_cols, false));
    visited[0][0] = true;
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      final r = cur[0], c = cur[1];
      if (r == _rows - 1 && c == _cols - 1) break;
      for (int d = 0; d < 4; d++) {
        if (_walls[r][c] & (1 << d) != 0) continue; // wall blocked
        final nr = r + [-1, 0, 1, 0][d];
        final nc = c + [0, 1, 0, -1][d];
        if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) continue;
        if (visited[nr][nc]) continue;
        visited[nr][nc] = true;
        prev[nr][nc] = r * _cols + c;
        queue.add([nr, nc]);
      }
    }
    // Reconstruct
    final path = <List<int>>[];
    int cur = (_rows - 1) * _cols + (_cols - 1);
    while (cur != -1) {
      path.insert(0, [cur ~/ _cols, cur % _cols]);
      if (cur == 0) break;
      cur = prev[cur ~/ _cols][cur % _cols];
    }
    return path;
  }

  static final List<List<int>> _path = _findPath();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final pad = 18.0;
    final cellW = (size.width - pad * 2) / _cols;
    final cellH = (size.height - pad * 2) / _rows;

    // Agent position along path, one step per 0.5s
    final stepInterval = math.max(0.08, 0.5 - learningRateRL * 0.3);
    final rawStep = (time / stepInterval).floor();
    final pathLen = _path.length;
    final stepIdx = rawStep % (pathLen + 8); // pause at goal then restart

    final agentPathIdx = stepIdx.clamp(0, pathLen - 1);
    final agentCell = _path[agentPathIdx];
    final agentRow = agentCell[0], agentCol = agentCell[1];

    // Visited cells set
    final visitedSteps = math.min(agentPathIdx + 1, pathLen);

    // 1. Draw Q-value heatmap
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final qv = _qValue(r, c, learningRateRL, discountFactor);
        final cellRect = Rect.fromLTWH(
          pad + c * cellW, pad + r * cellH, cellW, cellH,
        );
        // Heatmap color: low=dark blue, high=cyan
        final heatColor = Color.lerp(
          const Color(0xFF0D1A20),
          const Color(0xFF003A50),
          qv,
        )!;
        canvas.drawRect(cellRect, Paint()..color = heatColor);
      }
    }

    // 2. Highlight visited path cells
    for (int i = 0; i < visitedSteps && i < pathLen; i++) {
      final pc = _path[i];
      final cellRect = Rect.fromLTWH(
        pad + pc[1] * cellW + 1, pad + pc[0] * cellH + 1, cellW - 2, cellH - 2,
      );
      canvas.drawRect(
        cellRect,
        Paint()..color = AppColors.accent2.withValues(alpha: 0.18),
      );
      // Reward trail dots
      if (i > 0) {
        final prev = _path[i - 1];
        final x1 = pad + prev[1] * cellW + cellW / 2;
        final y1 = pad + prev[0] * cellH + cellH / 2;
        final x2 = pad + pc[1] * cellW + cellW / 2;
        final y2 = pad + pc[0] * cellH + cellH / 2;
        canvas.drawLine(
          Offset(x1, y1), Offset(x2, y2),
          Paint()
            ..color = AppColors.accent2.withValues(alpha: 0.35)
            ..strokeWidth = 1.8,
        );
      }
    }

    // 3. Draw maze walls
    final wallPaint = Paint()
      ..color = const Color(0xFF2A5A7A)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final x = pad + c * cellW;
        final y = pad + r * cellH;
        // up
        if (_walls[r][c] & 1 != 0) {
          canvas.drawLine(Offset(x, y), Offset(x + cellW, y), wallPaint);
        }
        // right
        if (_walls[r][c] & 2 != 0) {
          canvas.drawLine(Offset(x + cellW, y), Offset(x + cellW, y + cellH), wallPaint);
        }
        // down
        if (_walls[r][c] & 4 != 0) {
          canvas.drawLine(Offset(x, y + cellH), Offset(x + cellW, y + cellH), wallPaint);
        }
        // left
        if (_walls[r][c] & 8 != 0) {
          canvas.drawLine(Offset(x, y), Offset(x, y + cellH), wallPaint);
        }
      }
    }

    // 4. Draw goal (orange glowing star)
    final goalX = pad + (_cols - 1) * cellW + cellW / 2;
    final goalY = pad + (_rows - 1) * cellH + cellH / 2;
    final goalPulse = 1.0 + math.sin(time * 3.0) * 0.15;
    for (int g = 3; g >= 1; g--) {
      canvas.drawCircle(
        Offset(goalX, goalY), 9 * goalPulse + g * 3,
        Paint()..color = AppColors.accent2.withValues(alpha: 0.07 * g),
      );
    }
    // Star shape
    final starPath = Path();
    for (int p = 0; p < 10; p++) {
      final angle = p * math.pi / 5 - math.pi / 2;
      final r2 = p.isEven ? 7.0 * goalPulse : 3.5 * goalPulse;
      final sx = goalX + r2 * math.cos(angle);
      final sy = goalY + r2 * math.sin(angle);
      p == 0 ? starPath.moveTo(sx, sy) : starPath.lineTo(sx, sy);
    }
    starPath.close();
    canvas.drawPath(starPath, Paint()..color = AppColors.accent2);

    // 5. Draw agent (glowing cyan circle)
    final ax = pad + agentCol * cellW + cellW / 2;
    final ay = pad + agentRow * cellH + cellH / 2;
    final agentPulse = 1.0 + math.sin(time * 4.5) * 0.1;
    for (int g = 4; g >= 1; g--) {
      canvas.drawCircle(
        Offset(ax, ay), 7 * agentPulse + g * 3,
        Paint()..color = AppColors.accent.withValues(alpha: 0.06 * g),
      );
    }
    canvas.drawCircle(Offset(ax, ay), 6.5 * agentPulse, Paint()..color = AppColors.accent);
    canvas.drawCircle(Offset(ax, ay), 3.5 * agentPulse, Paint()..color = Colors.white.withValues(alpha: 0.8));

    // 6. Status label
    final isRandom = math.Random(rawStep + 3).nextDouble() < 0.15;
    final statusTp = TextPainter(
      text: TextSpan(
        text: isRandom ? '? 탐험' : '→ 최적',
        style: TextStyle(
          color: isRandom ? AppColors.accent2 : AppColors.accent,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    statusTp.paint(canvas, Offset(4, 4));
  }

  @override
  bool shouldRepaint(covariant _MazeRlScreenPainter oldDelegate) => true;
}
