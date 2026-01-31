import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 이상기체 법칙 시뮬레이션
class IdealGasScreen extends StatefulWidget {
  const IdealGasScreen({super.key});

  @override
  State<IdealGasScreen> createState() => _IdealGasScreenState();
}

class _IdealGasScreenState extends State<IdealGasScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _pressure = 1.0; // atm
  double _volume = 22.4; // L (1 mol at STP)
  double _temperature = 273.15; // K (0°C)
  int _moles = 1;

  static const double _R = 0.0821; // L·atm/(mol·K)

  // PV = nRT
  // 하나의 변수를 고정하고 다른 변수 계산
  String _fixedVariable = 'n'; // 'P', 'V', 'T', 'n'

  List<_Particle> _particles = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _generateParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateParticles);
    _controller.repeat();
  }

  void _generateParticles() {
    _particles = List.generate(_moles * 20, (i) {
      return _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        vx: (_random.nextDouble() - 0.5) * 0.02,
        vy: (_random.nextDouble() - 0.5) * 0.02,
      );
    });
  }

  void _updateParticles() {
    final speedFactor = math.sqrt(_temperature / 273.15);

    setState(() {
      for (var p in _particles) {
        p.x += p.vx * speedFactor;
        p.y += p.vy * speedFactor;

        // 벽 충돌
        if (p.x < 0 || p.x > 1) {
          p.vx = -p.vx;
          p.x = p.x.clamp(0, 1);
        }
        if (p.y < 0 || p.y > 1) {
          p.vy = -p.vy;
          p.y = p.y.clamp(0, 1);
        }
      }
    });
  }

  void _recalculate() {
    // PV = nRT
    switch (_fixedVariable) {
      case 'P':
        // V = nRT/P
        _volume = (_moles * _R * _temperature / _pressure).clamp(1, 100);
        break;
      case 'V':
        // P = nRT/V
        _pressure = (_moles * _R * _temperature / _volume).clamp(0.1, 10);
        break;
      case 'T':
        // P = nRT/V
        _pressure = (_moles * _R * _temperature / _volume).clamp(0.1, 10);
        break;
      case 'n':
        // V = nRT/P
        _volume = (_moles * _R * _temperature / _pressure).clamp(1, 100);
        break;
    }
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
              '이상기체 법칙',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '이상기체 법칙',
          formula: 'PV = nRT',
          formulaDescription: '압력, 부피, 온도, 몰수의 관계',
          simulation: SizedBox(
            height: 350,
            child: Row(
              children: [
                // 기체 시각화
                Expanded(
                  flex: 2,
                  child: CustomPaint(
                    painter: _IdealGasPainter(
                      particles: _particles,
                      volume: _volume,
                      temperature: _temperature,
                    ),
                    size: Size.infinite,
                  ),
                ),
                // 상태 변수 표시
                Container(
                  width: 100,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StateBox(
                        label: 'P',
                        value: '${_pressure.toStringAsFixed(2)} atm',
                        color: Colors.red,
                        isFixed: _fixedVariable == 'P',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _fixedVariable = 'P');
                        },
                      ),
                      const SizedBox(height: 8),
                      _StateBox(
                        label: 'V',
                        value: '${_volume.toStringAsFixed(1)} L',
                        color: Colors.blue,
                        isFixed: _fixedVariable == 'V',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _fixedVariable = 'V');
                        },
                      ),
                      const SizedBox(height: 8),
                      _StateBox(
                        label: 'n',
                        value: '$_moles mol',
                        color: Colors.green,
                        isFixed: _fixedVariable == 'n',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _fixedVariable = 'n');
                        },
                      ),
                      const SizedBox(height: 8),
                      _StateBox(
                        label: 'T',
                        value: '${_temperature.toInt()} K',
                        color: Colors.orange,
                        isFixed: _fixedVariable == 'T',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _fixedVariable = 'T');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 고정 변수 표시
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      '고정: $_fixedVariable (상자를 탭하여 변경)',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '온도 (K)',
                  value: _temperature,
                  min: 100,
                  max: 500,
                  defaultValue: 273.15,
                  formatValue: (v) => '${v.toInt()} K (${(v - 273.15).toInt()}°C)',
                  onChanged: (v) {
                    setState(() {
                      _temperature = v;
                      _recalculate();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '압력 (atm)',
                    value: _pressure,
                    min: 0.1,
                    max: 5,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(2)} atm',
                    onChanged: (v) {
                      setState(() {
                        _pressure = v;
                        _recalculate();
                      });
                    },
                  ),
                  SimSlider(
                    label: '몰수 (mol)',
                    value: _moles.toDouble(),
                    min: 1,
                    max: 5,
                    defaultValue: 1,
                    formatValue: (v) => '${v.toInt()} mol',
                    onChanged: (v) {
                      setState(() {
                        _moles = v.toInt();
                        _generateParticles();
                        _recalculate();
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
                label: 'STP',
                icon: Icons.thermostat,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _pressure = 1.0;
                    _temperature = 273.15;
                    _moles = 1;
                    _volume = 22.4;
                    _generateParticles();
                  });
                },
              ),
              SimButton(
                label: '가열',
                icon: Icons.whatshot,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _temperature = 373.15;
                    _recalculate();
                  });
                },
              ),
              SimButton(
                label: '압축',
                icon: Icons.compress,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _pressure = 3.0;
                    _recalculate();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy;
  _Particle({required this.x, required this.y, required this.vx, required this.vy});
}

class _StateBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isFixed;
  final VoidCallback onTap;

  const _StateBox({
    required this.label,
    required this.value,
    required this.color,
    required this.isFixed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isFixed ? color.withValues(alpha: 0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFixed ? color : AppColors.cardBorder,
            width: isFixed ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFixed) Icon(Icons.push_pin, size: 10, color: color),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                color: isFixed ? color : AppColors.muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdealGasPainter extends CustomPainter {
  final List<_Particle> particles;
  final double volume;
  final double temperature;

  _IdealGasPainter({
    required this.particles,
    required this.volume,
    required this.temperature,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    // 컨테이너 크기 (부피에 비례)
    final normalizedVolume = (volume / 50).clamp(0.3, 1.0);
    final containerWidth = size.width * 0.8 * normalizedVolume;
    final containerHeight = size.height * 0.8 * normalizedVolume;
    final containerLeft = (size.width - containerWidth) / 2;
    final containerTop = (size.height - containerHeight) / 2;

    final containerRect = Rect.fromLTWH(
      containerLeft,
      containerTop,
      containerWidth,
      containerHeight,
    );

    // 컨테이너 배경
    canvas.drawRect(
      containerRect,
      Paint()..color = Colors.blue.withValues(alpha: 0.1),
    );

    // 컨테이너 테두리
    canvas.drawRect(
      containerRect,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 입자 그리기
    final particleColor = Color.lerp(
      Colors.blue,
      Colors.red,
      ((temperature - 100) / 400).clamp(0, 1),
    )!;

    for (var p in particles) {
      final px = containerLeft + p.x * containerWidth;
      final py = containerTop + p.y * containerHeight;

      canvas.drawCircle(
        Offset(px, py),
        4,
        Paint()..color = particleColor.withValues(alpha: 0.8),
      );
    }

    // 부피 표시
    _drawText(
      canvas,
      'V = ${volume.toStringAsFixed(1)} L',
      Offset(containerLeft, containerTop - 20),
      AppColors.muted,
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _IdealGasPainter oldDelegate) => true;
}
