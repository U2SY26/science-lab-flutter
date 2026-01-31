import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 물결 파동 시뮬레이션
class RippleWaveScreen extends StatefulWidget {
  const RippleWaveScreen({super.key});

  @override
  State<RippleWaveScreen> createState() => _RippleWaveScreenState();
}

class _RippleWaveScreenState extends State<RippleWaveScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  List<_Ripple> _ripples = [];
  String _waveType = 'circular';
  double _waveSpeed = 100;
  double _frequency = 2.0;
  double _damping = 0.3;
  bool _showInterference = true;
  Color _waveColor = Colors.cyan;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    setState(() {
      // 파동 업데이트
      for (var ripple in _ripples) {
        ripple.radius += _waveSpeed * 0.016;
        ripple.age += 0.016;
      }

      // 오래된 파동 제거
      _ripples.removeWhere((r) => r.age > 5 || r.radius > 500);
    });
  }

  void _addRipple(Offset position, Size size) {
    HapticFeedback.lightImpact();
    setState(() {
      _ripples.add(_Ripple(
        center: position,
        radius: 0,
        age: 0,
        color: _waveColor,
      ));

      // 최대 파동 수 제한
      if (_ripples.length > 20) {
        _ripples.removeAt(0);
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _ripples.clear();
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
              '물결 파동',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '물결 파동 (Ripple Wave)',
          formula: 'y = A·sin(kr - ωt)·e^(-γt)',
          formulaDescription: '화면을 터치하면 물결이 퍼져나갑니다',
          simulation: SizedBox(
            height: 300,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    _addRipple(details.localPosition, constraints.biggest);
                  },
                  onPanUpdate: (details) {
                    if (_ripples.isEmpty ||
                        (DateTime.now().millisecondsSinceEpoch % 100 < 20)) {
                      _addRipple(details.localPosition, constraints.biggest);
                    }
                  },
                  child: CustomPaint(
                    painter: _RipplePainter(
                      ripples: _ripples,
                      waveType: _waveType,
                      frequency: _frequency,
                      damping: _damping,
                      showInterference: _showInterference,
                      time: DateTime.now().millisecondsSinceEpoch / 1000,
                    ),
                    size: Size.infinite,
                  ),
                );
              },
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: _waveColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '화면을 터치하세요',
                            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '활성 파동: ${_ripples.length}개',
                            style: const TextStyle(color: AppColors.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 파동 타입
              PresetGroup(
                label: '파동 타입',
                presets: [
                  PresetButton(
                    label: '원형파',
                    isSelected: _waveType == 'circular',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _waveType = 'circular');
                    },
                  ),
                  PresetButton(
                    label: '동심원',
                    isSelected: _waveType == 'concentric',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _waveType = 'concentric');
                    },
                  ),
                  PresetButton(
                    label: '3D 효과',
                    isSelected: _waveType == '3d',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _waveType = '3d');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 색상 선택
              const Text('파동 색상', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ColorButton(color: Colors.cyan, isSelected: _waveColor == Colors.cyan, onTap: () => setState(() => _waveColor = Colors.cyan)),
                  _ColorButton(color: Colors.blue, isSelected: _waveColor == Colors.blue, onTap: () => setState(() => _waveColor = Colors.blue)),
                  _ColorButton(color: Colors.purple, isSelected: _waveColor == Colors.purple, onTap: () => setState(() => _waveColor = Colors.purple)),
                  _ColorButton(color: Colors.pink, isSelected: _waveColor == Colors.pink, onTap: () => setState(() => _waveColor = Colors.pink)),
                  _ColorButton(color: Colors.orange, isSelected: _waveColor == Colors.orange, onTap: () => setState(() => _waveColor = Colors.orange)),
                  _ColorButton(color: Colors.green, isSelected: _waveColor == Colors.green, onTap: () => setState(() => _waveColor = Colors.green)),
                ],
              ),
              const SizedBox(height: 16),

              // 간섭 표시 토글
              Row(
                children: [
                  const Text('파동 간섭 표시', style: TextStyle(color: AppColors.muted)),
                  const Spacer(),
                  Switch(
                    value: _showInterference,
                    onChanged: (v) => setState(() => _showInterference = v),
                    activeColor: AppColors.accent,
                  ),
                ],
              ),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '파동 속도',
                  value: _waveSpeed,
                  min: 50,
                  max: 200,
                  defaultValue: 100,
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) => setState(() => _waveSpeed = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '주파수',
                    value: _frequency,
                    min: 1,
                    max: 5,
                    defaultValue: 2.0,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _frequency = v),
                  ),
                  SimSlider(
                    label: '감쇠율',
                    value: _damping,
                    min: 0.1,
                    max: 1.0,
                    defaultValue: 0.3,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _damping = v),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '초기화',
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

class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
              : null,
        ),
      ),
    );
  }
}

class _Ripple {
  Offset center;
  double radius;
  double age;
  Color color;

  _Ripple({
    required this.center,
    required this.radius,
    required this.age,
    required this.color,
  });
}

class _RipplePainter extends CustomPainter {
  final List<_Ripple> ripples;
  final String waveType;
  final double frequency;
  final double damping;
  final bool showInterference;
  final double time;

  _RipplePainter({
    required this.ripples,
    required this.waveType,
    required this.frequency,
    required this.damping,
    required this.showInterference,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF0a1628),
    );

    if (ripples.isEmpty) {
      _drawText(canvas, '터치하여 파동 생성', Offset(size.width / 2 - 60, size.height / 2), AppColors.muted);
      return;
    }

    // 간섭 패턴 그리기
    if (showInterference && ripples.length > 1) {
      _drawInterference(canvas, size);
    }

    // 각 파동 그리기
    for (var ripple in ripples) {
      _drawRipple(canvas, ripple, size);
    }

    // 파원 표시
    for (var ripple in ripples) {
      if (ripple.age < 2) {
        canvas.drawCircle(
          ripple.center,
          4,
          Paint()..color = ripple.color,
        );
      }
    }
  }

  void _drawRipple(Canvas canvas, _Ripple ripple, Size size) {
    final decay = math.exp(-damping * ripple.age);
    if (decay < 0.05) return;

    switch (waveType) {
      case 'circular':
        _drawCircularWave(canvas, ripple, decay);
        break;
      case 'concentric':
        _drawConcentricWave(canvas, ripple, decay);
        break;
      case '3d':
        _draw3DWave(canvas, ripple, decay, size);
        break;
    }
  }

  void _drawCircularWave(Canvas canvas, _Ripple ripple, double decay) {
    final numRings = (frequency * 3).toInt();

    for (int i = 0; i < numRings; i++) {
      final ringRadius = ripple.radius - i * (ripple.radius / numRings / frequency);
      if (ringRadius < 0) continue;

      final ringDecay = decay * (1 - i / numRings);
      final alpha = (ringDecay * 0.8).clamp(0.0, 1.0);

      canvas.drawCircle(
        ripple.center,
        ringRadius,
        Paint()
          ..color = ripple.color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + (1 - i / numRings) * 3,
      );
    }
  }

  void _drawConcentricWave(Canvas canvas, _Ripple ripple, double decay) {
    final spacing = 20.0 / frequency;
    final numRings = (ripple.radius / spacing).floor();

    for (int i = 0; i < numRings; i++) {
      final ringRadius = (i + 1) * spacing;
      if (ringRadius > ripple.radius) continue;

      final phase = math.sin(time * frequency * 2 * math.pi - i * 0.5);
      final intensity = (0.5 + 0.5 * phase) * decay;
      final alpha = (intensity * 0.6).clamp(0.0, 1.0);

      canvas.drawCircle(
        ripple.center,
        ringRadius,
        Paint()
          ..color = ripple.color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 + intensity * 2,
      );
    }
  }

  void _draw3DWave(Canvas canvas, _Ripple ripple, double decay, Size size) {
    final resolution = 40;
    final maxRadius = ripple.radius;

    for (int angle = 0; angle < 360; angle += 10) {
      final radians = angle * math.pi / 180;

      final path = Path();
      bool started = false;

      for (int r = 0; r < resolution; r++) {
        final radius = (r / resolution) * maxRadius;
        final x = ripple.center.dx + radius * math.cos(radians);
        final y = ripple.center.dy + radius * math.sin(radians);

        // 파동 높이 계산
        final wavePhase = radius / 20 * frequency - time * frequency * 2;
        final height = math.sin(wavePhase) * 10 * decay * (1 - radius / maxRadius);

        final screenY = y - height;

        if (!started) {
          path.moveTo(x, screenY);
          started = true;
        } else {
          path.lineTo(x, screenY);
        }
      }

      final alpha = (decay * 0.4).clamp(0.0, 1.0);
      canvas.drawPath(
        path,
        Paint()
          ..color = ripple.color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _drawInterference(Canvas canvas, Size size) {
    final resolution = 50;
    final cellWidth = size.width / resolution;
    final cellHeight = size.height / resolution;

    for (int i = 0; i < resolution; i++) {
      for (int j = 0; j < resolution; j++) {
        final point = Offset((i + 0.5) * cellWidth, (j + 0.5) * cellHeight);

        double totalAmplitude = 0;

        for (var ripple in ripples) {
          final distance = (point - ripple.center).distance;
          if (distance < ripple.radius && distance > 0) {
            final decay = math.exp(-damping * ripple.age);
            final phase = distance / 20 * frequency - time * frequency * 2;
            final amplitude = math.sin(phase) * decay * (1 - distance / ripple.radius);
            totalAmplitude += amplitude;
          }
        }

        if (totalAmplitude.abs() > 0.1) {
          final intensity = (totalAmplitude.abs()).clamp(0.0, 1.0);
          final color = totalAmplitude > 0
              ? Colors.cyan.withValues(alpha: intensity * 0.3)
              : Colors.blue.withValues(alpha: intensity * 0.3);

          canvas.drawRect(
            Rect.fromLTWH(i * cellWidth, j * cellHeight, cellWidth, cellHeight),
            Paint()..color = color,
          );
        }
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 14}) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => true;
}
