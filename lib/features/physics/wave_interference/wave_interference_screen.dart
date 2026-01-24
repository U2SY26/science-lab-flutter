import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 파동 간섭 (이중 슬릿) 시뮬레이션
class WaveInterferenceScreen extends StatefulWidget {
  const WaveInterferenceScreen({super.key});

  @override
  State<WaveInterferenceScreen> createState() => _WaveInterferenceScreenState();
}

class _WaveInterferenceScreenState extends State<WaveInterferenceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 기본값
  static const double _defaultWavelength = 20;
  static const double _defaultSlitDistance = 100;
  static const double _defaultAmplitude = 1.0;

  double wavelength = _defaultWavelength;
  double slitDistance = _defaultSlitDistance;
  double amplitude = _defaultAmplitude;
  double time = 0;
  bool isRunning = true;
  bool showIntensityGraph = true;

  // 프리셋
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        if (isRunning) {
          setState(() => time += 0.1);
        }
      });
    _controller.repeat();
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      time = 0;

      switch (preset) {
        case 'visible_light':
          wavelength = 15;
          slitDistance = 80;
          amplitude = 1.0;
          break;
        case 'water_wave':
          wavelength = 35;
          slitDistance = 120;
          amplitude = 1.5;
          break;
        case 'microwave':
          wavelength = 25;
          slitDistance = 60;
          amplitude = 0.8;
          break;
        case 'close_slits':
          wavelength = 20;
          slitDistance = 40;
          amplitude = 1.0;
          break;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      wavelength = _defaultWavelength;
      slitDistance = _defaultSlitDistance;
      amplitude = _defaultAmplitude;
      time = 0;
      _selectedPreset = null;
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
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '물리 엔진',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '이중 슬릿 간섭',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              showIntensityGraph ? Icons.show_chart : Icons.show_chart_outlined,
              color: showIntensityGraph ? AppColors.accent : AppColors.muted,
            ),
            tooltip: '강도 그래프',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => showIntensityGraph = !showIntensityGraph);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리 엔진',
          title: '이중 슬릿 간섭',
          formula: 'I = 4I₀cos²(πd sinθ/λ)',
          formulaDescription: '토마스 영의 이중 슬릿 실험 - 빛의 파동성 증명',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: WaveInterferencePainter(
                wavelength: wavelength,
                slitDistance: slitDistance,
                amplitude: amplitude,
                time: time,
                showIntensityGraph: showIntensityGraph,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋
              PresetGroup(
                label: '실험 설정',
                presets: [
                  PresetButton(
                    label: '가시광선',
                    isSelected: _selectedPreset == 'visible_light',
                    onPressed: () => _applyPreset('visible_light'),
                  ),
                  PresetButton(
                    label: '수면파',
                    isSelected: _selectedPreset == 'water_wave',
                    onPressed: () => _applyPreset('water_wave'),
                  ),
                  PresetButton(
                    label: '마이크로파',
                    isSelected: _selectedPreset == 'microwave',
                    onPressed: () => _applyPreset('microwave'),
                  ),
                  PresetButton(
                    label: '좁은 슬릿',
                    isSelected: _selectedPreset == 'close_slits',
                    onPressed: () => _applyPreset('close_slits'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 물리량 정보
              _PhysicsInfo(
                wavelength: wavelength,
                slitDistance: slitDistance,
                fringeSpacing: _calculateFringeSpacing(),
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '파장 (λ)',
                  value: wavelength,
                  min: 10,
                  max: 50,
                  defaultValue: _defaultWavelength,
                  formatValue: (v) => '${v.toInt()} px',
                  onChanged: (v) => setState(() {
                    wavelength = v;
                    _selectedPreset = null;
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: '슬릿 간격 (d)',
                    value: slitDistance,
                    min: 40,
                    max: 200,
                    defaultValue: _defaultSlitDistance,
                    formatValue: (v) => '${v.toInt()} px',
                    onChanged: (v) => setState(() {
                      slitDistance = v;
                      _selectedPreset = null;
                    }),
                  ),
                  SimSlider(
                    label: '진폭 (A)',
                    value: amplitude,
                    min: 0.5,
                    max: 2.0,
                    defaultValue: _defaultAmplitude,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() {
                      amplitude = v;
                      _selectedPreset = null;
                    }),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning ? '정지' : '재생',
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => isRunning = !isRunning);
                },
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

  double _calculateFringeSpacing() {
    // 간섭 무늬 간격 (근사)
    return wavelength * 200 / slitDistance;
  }
}

/// 물리량 정보 위젯
class _PhysicsInfo extends StatelessWidget {
  final double wavelength;
  final double slitDistance;
  final double fringeSpacing;

  const _PhysicsInfo({
    required this.wavelength,
    required this.slitDistance,
    required this.fringeSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _InfoItem(label: '파장 λ', value: '${wavelength.toInt()}', unit: 'px'),
          _InfoItem(label: '슬릿 간격 d', value: '${slitDistance.toInt()}', unit: 'px'),
          _InfoItem(label: '무늬 간격', value: fringeSpacing.toStringAsFixed(1), unit: 'px'),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _InfoItem({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WaveInterferencePainter extends CustomPainter {
  final double wavelength;
  final double slitDistance;
  final double amplitude;
  final double time;
  final bool showIntensityGraph;

  WaveInterferencePainter({
    required this.wavelength,
    required this.slitDistance,
    required this.amplitude,
    required this.time,
    required this.showIntensityGraph,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF000510),
    );

    final centerY = size.height / 2;
    final slit1Y = centerY - slitDistance / 2;
    final slit2Y = centerY + slitDistance / 2;
    final slitX = 50.0;

    // 슬릿 벽 그리기
    final wallPaint = Paint()
      ..color = AppColors.muted
      ..strokeWidth = 4;
    canvas.drawLine(Offset(slitX, 0), Offset(slitX, slit1Y - 10), wallPaint);
    canvas.drawLine(
        Offset(slitX, slit1Y + 10), Offset(slitX, slit2Y - 10), wallPaint);
    canvas.drawLine(
        Offset(slitX, slit2Y + 10), Offset(slitX, size.height), wallPaint);

    // 간섭 패턴 그리기
    final intensities = <double>[];
    for (double x = slitX + 10; x < size.width - (showIntensityGraph ? 60 : 0); x += 3) {
      for (double y = 0; y < size.height; y += 3) {
        final d1 = math.sqrt(math.pow(x - slitX, 2) + math.pow(y - slit1Y, 2));
        final d2 = math.sqrt(math.pow(x - slitX, 2) + math.pow(y - slit2Y, 2));

        final phase1 = (d1 / wavelength - time) * 2 * math.pi;
        final phase2 = (d2 / wavelength - time) * 2 * math.pi;

        final wave1 = amplitude * math.sin(phase1);
        final wave2 = amplitude * math.sin(phase2);

        final combined = (wave1 + wave2) / 2;
        final intensity = (combined + 1) / 2; // 0 to 1

        // 스크린 끝 지점의 강도 저장
        if (x > size.width - (showIntensityGraph ? 70 : 10) && showIntensityGraph) {
          intensities.add(intensity);
        }

        final color = Color.lerp(
          const Color(0xFF001030),
          AppColors.accent,
          intensity.clamp(0, 1),
        )!;

        canvas.drawRect(
          Rect.fromLTWH(x, y, 3, 3),
          Paint()..color = color,
        );
      }
    }

    // 강도 그래프 그리기
    if (showIntensityGraph && intensities.isNotEmpty) {
      _drawIntensityGraph(canvas, size, intensities);
    }

    // 슬릿 표시 (글로우 효과)
    for (final slitY in [slit1Y, slit2Y]) {
      canvas.drawCircle(
        Offset(slitX, slitY),
        8,
        Paint()..color = AppColors.accent2.withValues(alpha: 0.3),
      );
      canvas.drawCircle(
        Offset(slitX, slitY),
        5,
        Paint()..color = AppColors.accent2,
      );
    }

    // 정보 텍스트
    _drawText(canvas, 'S₁', Offset(slitX + 12, slit1Y - 5));
    _drawText(canvas, 'S₂', Offset(slitX + 12, slit2Y - 5));

    // 입사파 표시
    _drawIncidentWave(canvas, slitX, centerY);
  }

  void _drawIntensityGraph(Canvas canvas, Size size, List<double> intensities) {
    final graphX = size.width - 50;
    final graphWidth = 40.0;
    final graphHeight = size.height;

    // 그래프 배경
    canvas.drawRect(
      Rect.fromLTWH(graphX, 0, graphWidth, graphHeight),
      Paint()..color = const Color(0xFF001020),
    );

    // 강도 곡선
    final path = Path();
    final stepY = graphHeight / intensities.length;

    for (int i = 0; i < intensities.length; i++) {
      final x = graphX + intensities[i] * graphWidth * 0.8;
      final y = i * stepY;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 라벨
    _drawText(canvas, 'I', Offset(graphX + graphWidth / 2 - 3, graphHeight - 15));
  }

  void _drawIncidentWave(Canvas canvas, double slitX, double centerY) {
    final wavePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..strokeWidth = 2;

    // 평면파 표시
    for (double x = 10; x < slitX - 5; x += wavelength / 2) {
      final offset = (time * wavelength) % (wavelength / 2);
      final drawX = x + offset;
      if (drawX < slitX - 5) {
        canvas.drawLine(
          Offset(drawX, centerY - 30),
          Offset(drawX, centerY + 30),
          wavePaint,
        );
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant WaveInterferencePainter oldDelegate) => true;
}
