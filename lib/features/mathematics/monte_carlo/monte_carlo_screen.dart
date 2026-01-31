import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 몬테카를로 Pi 추정 시뮬레이션
class MonteCarloScreen extends StatefulWidget {
  const MonteCarloScreen({super.key});

  @override
  State<MonteCarloScreen> createState() => _MonteCarloScreenState();
}

class _MonteCarloScreenState extends State<MonteCarloScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final _random = math.Random();
  List<_Point> _points = [];
  int _insideCircle = 0;
  bool _isRunning = false;
  int _speed = 5;

  double get _estimatedPi => _points.isEmpty ? 0 : 4 * _insideCircle / _points.length;
  double get _error => (_estimatedPi - math.pi).abs();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      for (int i = 0; i < _speed; i++) {
        _addPoint();
      }
    });
  }

  void _addPoint() {
    final x = _random.nextDouble() * 2 - 1; // -1 to 1
    final y = _random.nextDouble() * 2 - 1;
    final inside = x * x + y * y <= 1;

    _points.add(_Point(x: x, y: y, inside: inside));
    if (inside) _insideCircle++;

    // 최대 점 개수 제한
    if (_points.length > 5000) {
      final removed = _points.removeAt(0);
      if (removed.inside) _insideCircle--;
    }
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
    _points = [];
    _insideCircle = 0;
    setState(() {});
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
              '몬테카를로 Pi',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '몬테카를로 Pi 추정',
          formula: 'π ≈ 4 × (원 안 점) / (전체 점)',
          formulaDescription: '무작위 점을 던져 원주율을 추정하는 확률적 방법',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _MonteCarloPainter(points: _points),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pi 추정값
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('π ≈ ', style: TextStyle(color: AppColors.muted, fontSize: 18)),
                        Text(
                          _estimatedPi.toStringAsFixed(6),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '실제 π', value: math.pi.toStringAsFixed(6), color: Colors.green),
                        _InfoItem(label: '오차', value: _error.toStringAsFixed(6), color: Colors.red),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(label: '전체 점', value: '${_points.length}', color: AppColors.ink),
                        _InfoItem(label: '원 안', value: '$_insideCircle', color: Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '속도',
                  value: _speed.toDouble(),
                  min: 1,
                  max: 20,
                  defaultValue: 5,
                  formatValue: (v) => '${v.toInt()}점/프레임',
                  onChanged: (v) => setState(() => _speed = v.toInt()),
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

class _Point {
  final double x, y;
  final bool inside;
  _Point({required this.x, required this.y, required this.inside});
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
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _MonteCarloPainter extends CustomPainter {
  final List<_Point> points;

  _MonteCarloPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final squareSize = math.min(size.width, size.height) - 40;
    final offsetX = (size.width - squareSize) / 2;
    final offsetY = (size.height - squareSize) / 2;

    // 정사각형 배경
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, squareSize, squareSize),
      Paint()..color = AppColors.card,
    );

    // 원
    canvas.drawCircle(
      Offset(offsetX + squareSize / 2, offsetY + squareSize / 2),
      squareSize / 2,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(offsetX + squareSize / 2, offsetY + squareSize / 2),
      squareSize / 2,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 점들
    for (var p in points) {
      final px = offsetX + (p.x + 1) / 2 * squareSize;
      final py = offsetY + (p.y + 1) / 2 * squareSize;

      canvas.drawCircle(
        Offset(px, py),
        2,
        Paint()..color = p.inside ? Colors.blue : Colors.red.withValues(alpha: 0.7),
      );
    }

    // 정사각형 테두리
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, squareSize, squareSize),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _MonteCarloPainter oldDelegate) => true;
}
