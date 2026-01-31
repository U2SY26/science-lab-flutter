import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 로켓 추진 시뮬레이션
class RocketScreen extends StatefulWidget {
  const RocketScreen({super.key});

  @override
  State<RocketScreen> createState() => _RocketScreenState();
}

class _RocketScreenState extends State<RocketScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _exhaustVelocity = 3000; // 배기 속도 (m/s)
  double _massRatio = 3.0; // 초기 질량 / 최종 질량
  double _burnRate = 0.5; // 연소율
  bool _isRunning = false;

  double _altitude = 0; // 고도
  double _velocity = 0; // 속도
  double _fuelRemaining = 1.0; // 남은 연료 (0~1)
  double _time = 0;

  static const double _g = 9.8;

  // 치올콥스키 방정식: Δv = v_e * ln(m0/mf)
  double get _deltaV => _exhaustVelocity * math.log(_massRatio);
  double get _thrust => _fuelRemaining > 0 ? _exhaustVelocity * _burnRate : 0;

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
      _time += 0.016;

      // 연료 소모
      if (_fuelRemaining > 0) {
        _fuelRemaining -= 0.002 * _burnRate;
        if (_fuelRemaining < 0) _fuelRemaining = 0;

        // 추력 - 중력
        final currentMass = 1 + _fuelRemaining * (_massRatio - 1);
        final acceleration = _thrust / currentMass - _g;
        _velocity += acceleration * 0.05;
      } else {
        // 연료 소진 후 자유낙하
        _velocity -= _g * 0.05;
      }

      _altitude += _velocity * 0.1;

      // 지면 충돌
      if (_altitude < 0) {
        _altitude = 0;
        _velocity = 0;
        _isRunning = false;
        _controller.stop();
      }
    });
  }

  void _launch() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRunning = true;
      _controller.repeat();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _altitude = 0;
      _velocity = 0;
      _fuelRemaining = 1.0;
      _time = 0;
      _controller.stop();
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
              '로켓 추진',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '로켓 추진',
          formula: 'Δv = v_e ln(m₀/m_f)',
          formulaDescription: '치올콥스키 방정식: 로켓의 속도 변화',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _RocketPainter(
                altitude: _altitude,
                fuelRemaining: _fuelRemaining,
                isThrusting: _fuelRemaining > 0 && _isRunning,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 정보
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
                        _InfoItem(label: '고도', value: '${_altitude.toStringAsFixed(0)} m', color: Colors.blue),
                        _InfoItem(label: '속도', value: '${_velocity.toStringAsFixed(1)} m/s', color: Colors.green),
                        _InfoItem(label: '시간', value: '${_time.toStringAsFixed(1)} s', color: AppColors.accent),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('연료: ', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _fuelRemaining,
                            backgroundColor: AppColors.cardBorder,
                            valueColor: AlwaysStoppedAnimation(
                              _fuelRemaining > 0.3 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(_fuelRemaining * 100).toInt()}%',
                          style: TextStyle(
                            color: _fuelRemaining > 0.3 ? Colors.green : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('이론적 Δv = ', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        Text(
                          '${_deltaV.toStringAsFixed(0)} m/s',
                          style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '배기 속도 v_e (m/s)',
                  value: _exhaustVelocity,
                  min: 1000,
                  max: 5000,
                  defaultValue: 3000,
                  formatValue: (v) => '${v.toInt()} m/s',
                  onChanged: (v) {
                    setState(() {
                      _exhaustVelocity = v;
                      _reset();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '질량비 m₀/m_f',
                    value: _massRatio,
                    min: 1.5,
                    max: 10,
                    defaultValue: 3.0,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) {
                      setState(() {
                        _massRatio = v;
                        _reset();
                      });
                    },
                  ),
                  SimSlider(
                    label: '연소율',
                    value: _burnRate,
                    min: 0.1,
                    max: 1.0,
                    defaultValue: 0.5,
                    formatValue: (v) => '${(v * 100).toInt()}%',
                    onChanged: (v) {
                      setState(() {
                        _burnRate = v;
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
                label: _isRunning ? '정지' : '🚀 발사!',
                icon: _isRunning ? Icons.pause : Icons.rocket_launch,
                isPrimary: true,
                onPressed: _isRunning ? () => setState(() => _isRunning = false) : _launch,
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
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RocketPainter extends CustomPainter {
  final double altitude;
  final double fuelRemaining;
  final bool isThrusting;

  _RocketPainter({
    required this.altitude,
    required this.fuelRemaining,
    required this.isThrusting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 하늘 그라데이션 (고도에 따라)
    final skyGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: altitude > 1000
          ? [Colors.black, Colors.indigo.shade900]
          : [Colors.blue.shade300, Colors.blue.shade100],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = skyGradient.createShader(Offset.zero & size),
    );

    // 별 (고도가 높으면)
    if (altitude > 500) {
      final starOpacity = ((altitude - 500) / 1000).clamp(0.0, 1.0);
      final random = math.Random(42);
      for (int i = 0; i < 30; i++) {
        canvas.drawCircle(
          Offset(random.nextDouble() * size.width, random.nextDouble() * size.height * 0.7),
          1 + random.nextDouble(),
          Paint()..color = Colors.white.withValues(alpha: starOpacity * random.nextDouble()),
        );
      }
    }

    // 지면
    final groundY = size.height - 40;
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, 40),
      Paint()..color = Colors.brown.shade700,
    );

    // 발사대
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - 15, groundY - 20, 30, 20),
      Paint()..color = Colors.grey.shade600,
    );

    // 로켓 위치 (화면상)
    final rocketY = groundY - 60 - (altitude / 50).clamp(0, size.height - 150);
    final rocketX = size.width / 2;

    // 로켓 그리기
    _drawRocket(canvas, rocketX, rocketY, isThrusting);

    // 고도 표시
    _drawText(canvas, '${altitude.toStringAsFixed(0)}m', Offset(size.width - 60, 20), Colors.white);
  }

  void _drawRocket(Canvas canvas, double x, double y, bool thrusting) {
    // 로켓 몸체
    final bodyPath = Path()
      ..moveTo(x, y - 30) // 노즈
      ..lineTo(x - 12, y + 10)
      ..lineTo(x - 12, y + 30)
      ..lineTo(x + 12, y + 30)
      ..lineTo(x + 12, y + 10)
      ..close();

    canvas.drawPath(bodyPath, Paint()..color = Colors.white);

    // 노즈콘
    canvas.drawPath(
      Path()
        ..moveTo(x, y - 30)
        ..lineTo(x - 8, y - 10)
        ..lineTo(x + 8, y - 10)
        ..close(),
      Paint()..color = Colors.red,
    );

    // 날개
    canvas.drawPath(
      Path()
        ..moveTo(x - 12, y + 15)
        ..lineTo(x - 22, y + 35)
        ..lineTo(x - 12, y + 30)
        ..close(),
      Paint()..color = Colors.red,
    );
    canvas.drawPath(
      Path()
        ..moveTo(x + 12, y + 15)
        ..lineTo(x + 22, y + 35)
        ..lineTo(x + 12, y + 30)
        ..close(),
      Paint()..color = Colors.red,
    );

    // 추진 불꽃
    if (thrusting) {
      final random = math.Random();
      for (int i = 0; i < 5; i++) {
        final flameLength = 20 + random.nextDouble() * 30;
        final flameWidth = 8 - i * 1.5;
        final offset = (random.nextDouble() - 0.5) * 6;

        canvas.drawPath(
          Path()
            ..moveTo(x - flameWidth + offset, y + 30)
            ..lineTo(x + offset, y + 30 + flameLength)
            ..lineTo(x + flameWidth + offset, y + 30)
            ..close(),
          Paint()
            ..color = i < 2
                ? Colors.yellow.withValues(alpha: 0.9)
                : Colors.orange.withValues(alpha: 0.7 - i * 0.1),
        );
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _RocketPainter oldDelegate) => true;
}
