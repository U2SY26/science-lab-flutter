import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 파장 시뮬레이션
class WavelengthScreen extends StatefulWidget {
  const WavelengthScreen({super.key});

  @override
  State<WavelengthScreen> createState() => _WavelengthScreenState();
}

class _WavelengthScreenState extends State<WavelengthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _wavelength = 500; // nm (가시광선 범위)
  double _amplitude = 50;
  double _speed = 1.0;
  String _waveType = 'visible';
  bool _showProperties = true;

  // 전자기파 스펙트럼 데이터
  final Map<String, _WaveSpectrum> _spectrum = {
    'radio': _WaveSpectrum(
      name: '라디오파',
      minWavelength: 1e6,
      maxWavelength: 1e9,
      color: Colors.brown,
      description: 'AM/FM 라디오, TV 방송',
    ),
    'microwave': _WaveSpectrum(
      name: '마이크로파',
      minWavelength: 1e3,
      maxWavelength: 1e6,
      color: Colors.orange,
      description: '전자레인지, 레이더, WiFi',
    ),
    'infrared': _WaveSpectrum(
      name: '적외선',
      minWavelength: 700,
      maxWavelength: 1e6,
      color: Colors.red,
      description: '열 복사, 리모컨, 야간 투시',
    ),
    'visible': _WaveSpectrum(
      name: '가시광선',
      minWavelength: 380,
      maxWavelength: 700,
      color: Colors.white,
      description: '인간의 눈으로 볼 수 있는 빛',
    ),
    'ultraviolet': _WaveSpectrum(
      name: '자외선',
      minWavelength: 10,
      maxWavelength: 380,
      color: Colors.purple,
      description: '살균, 일광욕, 형광',
    ),
    'xray': _WaveSpectrum(
      name: 'X선',
      minWavelength: 0.01,
      maxWavelength: 10,
      color: Colors.blue,
      description: '의료 영상, 공항 검색',
    ),
    'gamma': _WaveSpectrum(
      name: '감마선',
      minWavelength: 0.0001,
      maxWavelength: 0.01,
      color: Colors.green,
      description: '핵반응, 암 치료',
    ),
  };

  Color get _currentColor {
    if (_waveType == 'visible') {
      return _wavelengthToColor(_wavelength);
    }
    return _spectrum[_waveType]!.color;
  }

  double get _frequency {
    // c = λf, f = c/λ
    // c = 3e8 m/s, λ in nm -> λ in m = λ * 1e-9
    return 3e8 / (_wavelength * 1e-9);
  }

  double get _energy {
    // E = hf, h = 6.626e-34 J·s
    return 6.626e-34 * _frequency;
  }

  Color _wavelengthToColor(double wavelength) {
    // 가시광선 스펙트럼 색상 변환 (380-700nm)
    double r, g, b;

    if (wavelength >= 380 && wavelength < 440) {
      r = -(wavelength - 440) / (440 - 380);
      g = 0;
      b = 1;
    } else if (wavelength >= 440 && wavelength < 490) {
      r = 0;
      g = (wavelength - 440) / (490 - 440);
      b = 1;
    } else if (wavelength >= 490 && wavelength < 510) {
      r = 0;
      g = 1;
      b = -(wavelength - 510) / (510 - 490);
    } else if (wavelength >= 510 && wavelength < 580) {
      r = (wavelength - 510) / (580 - 510);
      g = 1;
      b = 0;
    } else if (wavelength >= 580 && wavelength < 645) {
      r = 1;
      g = -(wavelength - 645) / (645 - 580);
      b = 0;
    } else if (wavelength >= 645 && wavelength <= 700) {
      r = 1;
      g = 0;
      b = 0;
    } else {
      r = 0;
      g = 0;
      b = 0;
    }

    return Color.fromRGBO((r * 255).round(), (g * 255).round(), (b * 255).round(), 1);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
              '파장',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '파장과 전자기파 스펙트럼',
          formula: 'c = λf, E = hf',
          formulaDescription: '빛의 속도 = 파장 × 주파수',
          simulation: SizedBox(
            height: 300,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WavelengthPainter(
                    wavelength: _wavelength,
                    amplitude: _amplitude,
                    speed: _speed,
                    waveType: _waveType,
                    color: _currentColor,
                    animation: _controller.value,
                    showProperties: _showProperties,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 파장 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _currentColor.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(
                          label: '파장 (λ)',
                          value: _waveType == 'visible'
                              ? '${_wavelength.toInt()} nm'
                              : _spectrum[_waveType]!.name,
                          color: _currentColor,
                        ),
                        _InfoItem(
                          label: '주파수 (f)',
                          value: _formatFrequency(_frequency),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(
                          label: '에너지',
                          value: _formatEnergy(_energy),
                          color: Colors.green,
                        ),
                        _InfoItem(
                          label: '광속',
                          value: '3×10⁸ m/s',
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 스펙트럼 선택
              const Text('전자기파 스펙트럼', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _spectrum.entries.map((entry) {
                    final isSelected = _waveType == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _waveType = entry.key;
                            if (entry.key == 'visible') {
                              _wavelength = 500;
                            } else {
                              _wavelength = (entry.value.minWavelength + entry.value.maxWavelength) / 2;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? entry.value.color.withValues(alpha: 0.2) : AppColors.simBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? entry.value.color : AppColors.cardBorder,
                            ),
                          ),
                          child: Text(
                            entry.value.name,
                            style: TextStyle(
                              color: isSelected ? entry.value.color : AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // 설명
              if (_waveType != 'visible')
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _spectrum[_waveType]!.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _spectrum[_waveType]!.description,
                    style: TextStyle(color: _spectrum[_waveType]!.color, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 16),

              if (_waveType == 'visible')
                ControlGroup(
                  primaryControl: SimSlider(
                    label: '파장 (nm)',
                    value: _wavelength,
                    min: 380,
                    max: 700,
                    defaultValue: 500,
                    formatValue: (v) => '${v.toInt()} nm',
                    onChanged: (v) => setState(() => _wavelength = v),
                  ),
                  advancedControls: [
                    SimSlider(
                      label: '진폭',
                      value: _amplitude,
                      min: 20,
                      max: 80,
                      defaultValue: 50,
                      formatValue: (v) => v.toInt().toString(),
                      onChanged: (v) => setState(() => _amplitude = v),
                    ),
                    SimSlider(
                      label: '속도',
                      value: _speed,
                      min: 0.5,
                      max: 3,
                      defaultValue: 1.0,
                      formatValue: (v) => '${v.toStringAsFixed(1)}x',
                      onChanged: (v) => setState(() => _speed = v),
                    ),
                  ],
                ),

              if (_waveType != 'visible')
                ControlGroup(
                  primaryControl: SimSlider(
                    label: '진폭',
                    value: _amplitude,
                    min: 20,
                    max: 80,
                    defaultValue: 50,
                    formatValue: (v) => v.toInt().toString(),
                    onChanged: (v) => setState(() => _amplitude = v),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFrequency(double freq) {
    if (freq >= 1e18) return '${(freq / 1e18).toStringAsFixed(1)} EHz';
    if (freq >= 1e15) return '${(freq / 1e15).toStringAsFixed(1)} PHz';
    if (freq >= 1e12) return '${(freq / 1e12).toStringAsFixed(1)} THz';
    if (freq >= 1e9) return '${(freq / 1e9).toStringAsFixed(1)} GHz';
    if (freq >= 1e6) return '${(freq / 1e6).toStringAsFixed(1)} MHz';
    if (freq >= 1e3) return '${(freq / 1e3).toStringAsFixed(1)} kHz';
    return '${freq.toStringAsFixed(1)} Hz';
  }

  String _formatEnergy(double energy) {
    final eV = energy / 1.602e-19;
    if (eV >= 1e6) return '${(eV / 1e6).toStringAsFixed(1)} MeV';
    if (eV >= 1e3) return '${(eV / 1e3).toStringAsFixed(1)} keV';
    if (eV >= 1) return '${eV.toStringAsFixed(2)} eV';
    if (eV >= 1e-3) return '${(eV * 1e3).toStringAsFixed(2)} meV';
    return '${(eV * 1e6).toStringAsFixed(2)} μeV';
  }
}

class _WaveSpectrum {
  final String name;
  final double minWavelength;
  final double maxWavelength;
  final Color color;
  final String description;

  _WaveSpectrum({
    required this.name,
    required this.minWavelength,
    required this.maxWavelength,
    required this.color,
    required this.description,
  });
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

class _WavelengthPainter extends CustomPainter {
  final double wavelength;
  final double amplitude;
  final double speed;
  final String waveType;
  final Color color;
  final double animation;
  final bool showProperties;

  _WavelengthPainter({
    required this.wavelength,
    required this.amplitude,
    required this.speed,
    required this.waveType,
    required this.color,
    required this.animation,
    required this.showProperties,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0a0a1a));

    final centerY = size.height / 2;
    final padding = 30.0;

    // 스펙트럼 바 (상단)
    _drawSpectrumBar(canvas, size);

    // 축
    canvas.drawLine(
      Offset(padding, centerY),
      Offset(size.width - padding, centerY),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // 파동 그리기
    final path = Path();
    final waveWidth = size.width - padding * 2;

    // 파장을 픽셀로 변환 (가시광선 기준 스케일링)
    double pixelWavelength;
    if (waveType == 'visible') {
      pixelWavelength = waveWidth / ((700 - wavelength) / 50 + 3);
    } else {
      pixelWavelength = waveWidth / 5;
    }

    final phase = animation * 2 * math.pi * speed;

    for (double x = 0; x <= waveWidth; x += 2) {
      final y = amplitude * math.sin(2 * math.pi * x / pixelWavelength - phase);

      if (x == 0) {
        path.moveTo(padding + x, centerY - y);
      } else {
        path.lineTo(padding + x, centerY - y);
      }
    }

    // 글로우 효과
    for (int i = 3; i > 0; i--) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.1)
          ..strokeWidth = 2.0 + i * 2
          ..style = PaintingStyle.stroke,
      );
    }

    // 메인 파형
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // 파장 표시
    if (showProperties) {
      final arrowY = centerY + amplitude + 30;
      final startX = padding + waveWidth / 2 - pixelWavelength / 2;
      final endX = padding + waveWidth / 2 + pixelWavelength / 2;

      // 양방향 화살표
      canvas.drawLine(
        Offset(startX, arrowY),
        Offset(endX, arrowY),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5,
      );

      // 화살촉
      canvas.drawLine(Offset(startX, arrowY), Offset(startX + 8, arrowY - 5), Paint()..color = Colors.white..strokeWidth = 1.5);
      canvas.drawLine(Offset(startX, arrowY), Offset(startX + 8, arrowY + 5), Paint()..color = Colors.white..strokeWidth = 1.5);
      canvas.drawLine(Offset(endX, arrowY), Offset(endX - 8, arrowY - 5), Paint()..color = Colors.white..strokeWidth = 1.5);
      canvas.drawLine(Offset(endX, arrowY), Offset(endX - 8, arrowY + 5), Paint()..color = Colors.white..strokeWidth = 1.5);

      _drawText(canvas, 'λ', Offset((startX + endX) / 2 - 5, arrowY + 5), Colors.white);

      // 진폭 표시
      final ampX = padding + 20;
      canvas.drawLine(
        Offset(ampX, centerY),
        Offset(ampX, centerY - amplitude),
        Paint()
          ..color = Colors.yellow.withValues(alpha: 0.7)
          ..strokeWidth = 1.5,
      );
      _drawText(canvas, 'A', Offset(ampX + 5, centerY - amplitude / 2 - 6), Colors.yellow, fontSize: 10);
    }
  }

  void _drawSpectrumBar(Canvas canvas, Size size) {
    final barHeight = 15.0;
    final barY = 10.0;
    final barWidth = size.width - 60;
    final barX = 30.0;

    // 가시광선 스펙트럼 그라데이션
    for (double i = 0; i < barWidth; i++) {
      final wavelength = 380 + (700 - 380) * (i / barWidth);
      final color = _wavelengthToColor(wavelength);

      canvas.drawLine(
        Offset(barX + i, barY),
        Offset(barX + i, barY + barHeight),
        Paint()..color = color,
      );
    }

    // 테두리
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke,
    );

    // 현재 파장 마커 (가시광선일 때만)
    if (waveType == 'visible') {
      final markerX = barX + (wavelength - 380) / (700 - 380) * barWidth;
      canvas.drawLine(
        Offset(markerX, barY - 3),
        Offset(markerX, barY + barHeight + 3),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2,
      );
    }

    // 레이블
    _drawText(canvas, '380nm', Offset(barX - 5, barY + barHeight + 3), AppColors.muted, fontSize: 8);
    _drawText(canvas, '700nm', Offset(barX + barWidth - 20, barY + barHeight + 3), AppColors.muted, fontSize: 8);
  }

  Color _wavelengthToColor(double wavelength) {
    double r, g, b;

    if (wavelength >= 380 && wavelength < 440) {
      r = -(wavelength - 440) / (440 - 380);
      g = 0;
      b = 1;
    } else if (wavelength >= 440 && wavelength < 490) {
      r = 0;
      g = (wavelength - 440) / (490 - 440);
      b = 1;
    } else if (wavelength >= 490 && wavelength < 510) {
      r = 0;
      g = 1;
      b = -(wavelength - 510) / (510 - 490);
    } else if (wavelength >= 510 && wavelength < 580) {
      r = (wavelength - 510) / (580 - 510);
      g = 1;
      b = 0;
    } else if (wavelength >= 580 && wavelength < 645) {
      r = 1;
      g = -(wavelength - 645) / (645 - 580);
      b = 0;
    } else if (wavelength >= 645 && wavelength <= 700) {
      r = 1;
      g = 0;
      b = 0;
    } else {
      r = 0;
      g = 0;
      b = 0;
    }

    return Color.fromRGBO((r * 255).round(), (g * 255).round(), (b * 255).round(), 1);
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
  bool shouldRepaint(covariant _WavelengthPainter oldDelegate) => true;
}
