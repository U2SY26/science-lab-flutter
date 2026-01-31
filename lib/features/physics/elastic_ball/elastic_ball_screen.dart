import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 탄성 공 튕기기 시뮬레이션
class ElasticBallScreen extends StatefulWidget {
  const ElasticBallScreen({super.key});

  @override
  State<ElasticBallScreen> createState() => _ElasticBallScreenState();
}

class _ElasticBallScreenState extends State<ElasticBallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _restitution = 0.8; // 반발 계수 (0~1)
  double _initialHeight = 200; // 초기 높이
  bool _isRunning = true;

  double _y = 0; // 공 위치
  double _vy = 0; // 속도
  int _bounceCount = 0;
  double _maxHeight = 200;

  static const double _g = 9.8;
  static const double _ballRadius = 15;

  @override
  void initState() {
    super.initState();
    _y = _initialHeight;
    _maxHeight = _initialHeight;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      // 중력 가속도
      _vy += _g * 0.3;
      _y -= _vy;

      // 바닥 충돌
      if (_y <= _ballRadius) {
        _y = _ballRadius;
        _vy = -_vy * _restitution;
        _bounceCount++;
        HapticFeedback.lightImpact();

        // 다음 최대 높이 계산
        _maxHeight = _maxHeight * _restitution * _restitution;
      }

      // 거의 멈춤
      if (_vy.abs() < 0.5 && _y <= _ballRadius + 1) {
        _vy = 0;
        _y = _ballRadius;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _y = _initialHeight;
      _vy = 0;
      _bounceCount = 0;
      _maxHeight = _initialHeight;
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
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '물리학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '탄성 충돌',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '탄성 공 튕기기',
          formula: 'e = v_after / v_before',
          formulaDescription: '반발 계수: 충돌 전후 속도의 비율',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _BallPainter(
                y: _y,
                maxHeight: _initialHeight,
                restitution: _restitution,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 정보 표시
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
                        _InfoItem(label: '높이', value: '${_y.toStringAsFixed(0)} px', color: Colors.blue),
                        _InfoItem(label: '속도', value: '${_vy.abs().toStringAsFixed(1)}', color: Colors.green),
                        _InfoItem(label: '튕김 횟수', value: '$_bounceCount', color: AppColors.accent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (_y / _initialHeight).clamp(0, 1),
                      backgroundColor: AppColors.cardBorder,
                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 반발 계수 프리셋
              PresetGroup(
                label: '재질',
                presets: [
                  PresetButton(
                    label: '고무공',
                    isSelected: _restitution >= 0.75,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _restitution = 0.85;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '테니스공',
                    isSelected: _restitution >= 0.6 && _restitution < 0.75,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _restitution = 0.7;
                        _reset();
                      });
                    },
                  ),
                  PresetButton(
                    label: '찰흙',
                    isSelected: _restitution < 0.3,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _restitution = 0.1;
                        _reset();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '반발 계수 e',
                  value: _restitution,
                  min: 0,
                  max: 1,
                  defaultValue: 0.8,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() {
                      _restitution = v;
                      _reset();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '초기 높이',
                    value: _initialHeight,
                    min: 100,
                    max: 300,
                    defaultValue: 200,
                    formatValue: (v) => '${v.toInt()} px',
                    onChanged: (v) {
                      setState(() {
                        _initialHeight = v;
                        _reset();
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning ? '정지' : '재생',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isRunning = !_isRunning);
                },
              ),
              SimButton(
                label: '다시 떨어뜨리기',
                icon: Icons.arrow_downward,
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
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BallPainter extends CustomPainter {
  final double y;
  final double maxHeight;
  final double restitution;

  _BallPainter({required this.y, required this.maxHeight, required this.restitution});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final groundY = size.height - 30;
    final ballRadius = 15.0;

    // 바닥
    canvas.drawLine(
      Offset(50, groundY),
      Offset(size.width - 50, groundY),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 3,
    );

    // 높이 눈금
    for (int i = 0; i <= 5; i++) {
      final markY = groundY - (i / 5) * (size.height - 80);
      canvas.drawLine(
        Offset(40, markY),
        Offset(50, markY),
        Paint()
          ..color = AppColors.muted.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }

    // 공 위치 계산
    final ballY = groundY - y;

    // 그림자 (바닥에 가까울수록 진해짐)
    final shadowOpacity = ((maxHeight - y) / maxHeight * 0.5).clamp(0.0, 0.5);
    final shadowSize = 20 + (1 - y / maxHeight) * 15;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, groundY - 5), width: shadowSize, height: 8),
      Paint()..color = Colors.black.withValues(alpha: shadowOpacity),
    );

    // 공
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        Colors.orange.shade300,
        Colors.orange,
        Colors.orange.shade800,
      ],
    );

    canvas.drawCircle(
      Offset(centerX, ballY),
      ballRadius,
      Paint()..shader = gradient.createShader(Rect.fromCircle(center: Offset(centerX, ballY), radius: ballRadius)),
    );

    // 하이라이트
    canvas.drawCircle(
      Offset(centerX - 5, ballY - 5),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    // 압축 효과 (바닥 근처에서)
    if (y < ballRadius * 2) {
      final compression = 1 - (y / (ballRadius * 2));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, groundY - ballRadius * (1 - compression * 0.3)),
          width: ballRadius * 2 * (1 + compression * 0.3),
          height: ballRadius * 2 * (1 - compression * 0.3),
        ),
        Paint()..color = Colors.orange.withValues(alpha: 0.3),
      );
    }

    // 반발 계수 표시
    _drawText(canvas, 'e = ${restitution.toStringAsFixed(2)}', Offset(size.width - 80, 20), AppColors.accent);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _BallPainter oldDelegate) {
    return oldDelegate.y != y;
  }
}
