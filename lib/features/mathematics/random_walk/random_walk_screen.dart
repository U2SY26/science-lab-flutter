import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 랜덤 워크 시뮬레이션
class RandomWalkScreen extends StatefulWidget {
  const RandomWalkScreen({super.key});

  @override
  State<RandomWalkScreen> createState() => _RandomWalkScreenState();
}

class _RandomWalkScreenState extends State<RandomWalkScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  List<Offset> _path = [Offset.zero];
  String _walkType = '2d';
  int _speed = 5;
  bool _isRunning = false;

  double get _distance {
    final last = _path.last;
    return math.sqrt(last.dx * last.dx + last.dy * last.dy);
  }

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
        _addStep();
      }
    });
  }

  void _addStep() {
    final last = _path.last;
    Offset next;

    switch (_walkType) {
      case '1d':
        final step = _random.nextBool() ? 1.0 : -1.0;
        next = Offset(last.dx + step, 0);
        break;
      case '2d':
        final dir = _random.nextInt(4);
        switch (dir) {
          case 0:
            next = Offset(last.dx + 1, last.dy);
            break;
          case 1:
            next = Offset(last.dx - 1, last.dy);
            break;
          case 2:
            next = Offset(last.dx, last.dy + 1);
            break;
          default:
            next = Offset(last.dx, last.dy - 1);
        }
        break;
      case 'continuous':
        final angle = _random.nextDouble() * 2 * math.pi;
        next = Offset(last.dx + math.cos(angle), last.dy + math.sin(angle));
        break;
      default:
        next = last;
    }

    _path.add(next);

    // 최대 경로 길이 제한
    if (_path.length > 2000) {
      _path.removeAt(0);
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
    _path = [Offset.zero];
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
              '랜덤 워크',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '랜덤 워크 (Random Walk)',
          formula: 'E[D] ∝ √n',
          formulaDescription: '무작위 걸음의 기대 거리는 걸음 수의 제곱근에 비례',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _RandomWalkPainter(
                path: _path,
                walkType: _walkType,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoItem(label: '걸음 수', value: '${_path.length - 1}', color: AppColors.ink),
                    _InfoItem(label: '원점 거리', value: _distance.toStringAsFixed(1), color: Colors.blue),
                    _InfoItem(label: '√n', value: math.sqrt(_path.length - 1).toStringAsFixed(1), color: Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 워크 타입
              PresetGroup(
                label: '타입',
                presets: [
                  PresetButton(
                    label: '1D',
                    isSelected: _walkType == '1d',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _walkType = '1d';
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '2D 격자',
                    isSelected: _walkType == '2d',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _walkType = '2d';
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '연속',
                    isSelected: _walkType == 'continuous',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _walkType = 'continuous';
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '속도',
                  value: _speed.toDouble(),
                  min: 1,
                  max: 20,
                  defaultValue: 5,
                  formatValue: (v) => '${v.toInt()}걸음/프레임',
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
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _RandomWalkPainter extends CustomPainter {
  final List<Offset> path;
  final String walkType;

  _RandomWalkPainter({required this.path, required this.walkType});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (path.length < 2) {
      _drawText(canvas, '시작을 눌러 랜덤 워크', Offset(size.width / 2 - 70, size.height / 2), AppColors.muted);
      // 원점 표시
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        5,
        Paint()..color = Colors.red,
      );
      return;
    }

    // 경로 범위 계산
    double minX = 0, maxX = 0, minY = 0, maxY = 0;
    for (var p in path) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }

    // 여유 공간 추가
    final rangeX = (maxX - minX).abs() + 10;
    final rangeY = walkType == '1d' ? 2.0 : (maxY - minY).abs() + 10;

    final padding = 30.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    final scale = math.min(graphWidth / rangeX, graphHeight / rangeY);
    final offsetX = size.width / 2 - (maxX + minX) / 2 * scale;
    final offsetY = size.height / 2 - (maxY + minY) / 2 * scale;

    // 원점 표시
    canvas.drawCircle(
      Offset(offsetX, offsetY),
      4,
      Paint()..color = Colors.red,
    );

    // 경로 그리기
    final pathPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final pathObj = Path();
    for (int i = 0; i < path.length; i++) {
      final screenX = offsetX + path[i].dx * scale;
      final screenY = offsetY + path[i].dy * scale;

      if (i == 0) {
        pathObj.moveTo(screenX, screenY);
      } else {
        pathObj.lineTo(screenX, screenY);
      }
    }

    canvas.drawPath(pathObj, pathPaint);

    // 현재 위치
    final last = path.last;
    final lastX = offsetX + last.dx * scale;
    final lastY = offsetY + last.dy * scale;

    canvas.drawCircle(
      Offset(lastX, lastY),
      6,
      Paint()..color = Colors.green,
    );

    // 원점에서 현재 위치까지 선
    canvas.drawLine(
      Offset(offsetX, offsetY),
      Offset(lastX, lastY),
      Paint()
        ..color = Colors.orange
        ..strokeWidth = 2,
    );

    // 범례
    canvas.drawCircle(Offset(size.width - 60, 15), 4, Paint()..color = Colors.red);
    _drawText(canvas, '원점', Offset(size.width - 50, 10), Colors.red, fontSize: 10);

    canvas.drawCircle(Offset(size.width - 60, 30), 4, Paint()..color = Colors.green);
    _drawText(canvas, '현재', Offset(size.width - 50, 25), Colors.green, fontSize: 10);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _RandomWalkPainter oldDelegate) => true;
}
