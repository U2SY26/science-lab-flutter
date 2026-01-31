import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 갈톤 보드 시뮬레이션
class GaltonBoardScreen extends StatefulWidget {
  const GaltonBoardScreen({super.key});

  @override
  State<GaltonBoardScreen> createState() => _GaltonBoardScreenState();
}

class _GaltonBoardScreenState extends State<GaltonBoardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final _random = math.Random();
  List<_Ball> _balls = [];
  List<int> _bins = [];
  int _rows = 8;
  bool _isRunning = false;
  int _totalBalls = 0;

  @override
  void initState() {
    super.initState();
    _bins = List.filled(_rows + 1, 0);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      // 새 공 추가
      if (_random.nextDouble() < 0.1) {
        _addBall();
      }

      // 공들 업데이트
      for (var ball in _balls) {
        ball.y += ball.speed;

        // 핀에 부딪힘
        final row = (ball.y / 30).floor();
        if (row > ball.lastRow && row < _rows) {
          ball.lastRow = row;
          // 50% 확률로 좌우 이동
          ball.x += _random.nextBool() ? 0.5 : -0.5;
        }

        // 바닥에 도달
        if (ball.y >= _rows * 30 + 50) {
          final binIndex = ((ball.x + _rows / 2) * (_rows + 1) / _rows).floor().clamp(0, _rows);
          _bins[binIndex]++;
          ball.settled = true;
        }
      }

      // 정착된 공 제거
      _balls.removeWhere((b) => b.settled);
    });
  }

  void _addBall() {
    _balls.add(_Ball(
      x: 0,
      y: 0,
      speed: 2 + _random.nextDouble() * 2,
    ));
    _totalBalls++;
  }

  void _start() {
    HapticFeedback.mediumImpact();
    _isRunning = true;
    _controller.repeat();
    setState(() {});
  }

  void _stop() {
    _isRunning = false;
    _controller.stop();
    setState(() {});
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _isRunning = false;
    _controller.stop();
    _balls = [];
    _bins = List.filled(_rows + 1, 0);
    _totalBalls = 0;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxBin = _bins.isEmpty ? 1 : _bins.reduce(math.max).clamp(1, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '수학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '갈톤 보드',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '갈톤 보드',
          formula: 'P(k) = C(n,k) × (1/2)ⁿ',
          formulaDescription: '이항분포를 시각적으로 보여주는 확률 실험 장치',
          simulation: SizedBox(
            height: 400,
            child: CustomPaint(
              painter: _GaltonBoardPainter(
                balls: _balls,
                bins: _bins,
                rows: _rows,
                maxBin: maxBin.toInt(),
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 통계
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '총 공', value: '$_totalBalls', color: AppColors.accent),
                        _InfoItem(label: '떨어지는 중', value: '${_balls.length}', color: Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '공이 떨어질수록 정규분포에 가까워집니다',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '핀 행 수',
                  value: _rows.toDouble(),
                  min: 4,
                  max: 12,
                  defaultValue: 8,
                  formatValue: (v) => '${v.toInt()}행',
                  onChanged: (v) {
                    setState(() {
                      _rows = v.toInt();
                      _reset();
                    });
                  },
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning ? '정지' : '시작',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _isRunning ? _stop : _start,
              ),
              SimButton(
                label: '리셋',
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

class _Ball {
  double x, y;
  double speed;
  int lastRow = -1;
  bool settled = false;

  _Ball({required this.x, required this.y, required this.speed});
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _GaltonBoardPainter extends CustomPainter {
  final List<_Ball> balls;
  final List<int> bins;
  final int rows;
  final int maxBin;

  _GaltonBoardPainter({
    required this.balls,
    required this.bins,
    required this.rows,
    required this.maxBin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final pinSpacing = 25.0;
    final startY = 30.0;
    final binHeight = 100.0;

    // 핀 그리기
    for (int row = 0; row < rows; row++) {
      final pinsInRow = row + 1;
      final rowWidth = (pinsInRow - 1) * pinSpacing;
      final startX = centerX - rowWidth / 2;

      for (int col = 0; col < pinsInRow; col++) {
        final x = startX + col * pinSpacing;
        final y = startY + row * 30;

        canvas.drawCircle(
          Offset(x, y),
          4,
          Paint()..color = AppColors.muted,
        );
      }
    }

    // 공 그리기
    for (var ball in balls) {
      final x = centerX + ball.x * pinSpacing;
      final y = startY + ball.y;

      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = Colors.red,
      );
    }

    // 빈 (막대 그래프)
    final binWidth = size.width / (bins.length + 1);
    final binStartY = size.height - binHeight - 20;

    for (int i = 0; i < bins.length; i++) {
      final x = binWidth * (i + 0.5);
      final height = maxBin > 0 ? (bins[i] / maxBin) * binHeight : 0.0;

      // 막대
      canvas.drawRect(
        Rect.fromLTWH(x - binWidth / 2 + 2, binStartY + binHeight - height, binWidth - 4, height),
        Paint()..color = AppColors.accent,
      );

      // 구분선
      canvas.drawLine(
        Offset(x - binWidth / 2, binStartY),
        Offset(x - binWidth / 2, size.height - 20),
        Paint()
          ..color = AppColors.muted.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );

      // 개수
      if (bins[i] > 0) {
        _drawText(canvas, '${bins[i]}', Offset(x - 8, binStartY + binHeight + 5), AppColors.muted, fontSize: 9);
      }
    }

    // 바닥선
    canvas.drawLine(
      Offset(0, binStartY),
      Offset(size.width, binStartY),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2,
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 10}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _GaltonBoardPainter oldDelegate) => true;
}
