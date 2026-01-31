import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 푸리에 변환 시뮬레이션 (에피사이클)
class FourierScreen extends StatefulWidget {
  const FourierScreen({super.key});

  @override
  State<FourierScreen> createState() => _FourierScreenState();
}

class _FourierScreenState extends State<FourierScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 기본값
  static const int _defaultNumCircles = 5;
  static const double _defaultSpeed = 1.0;

  int numCircles = _defaultNumCircles;
  double time = 0;
  double speed = _defaultSpeed;
  bool isRunning = true;
  String waveType = 'square'; // square, sawtooth, triangle
  List<Offset> wave = [];
  bool showCircles = true;

  // 프리셋
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!isRunning) return;
    setState(() {
      time += 0.02 * speed;
    });
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      wave.clear();
      time = 0;

      switch (preset) {
        case 'simple':
          numCircles = 3;
          waveType = 'square';
          speed = 0.5;
          break;
        case 'detailed':
          numCircles = 15;
          waveType = 'square';
          speed = 1.0;
          break;
        case 'smooth':
          numCircles = 10;
          waveType = 'triangle';
          speed = 0.8;
          break;
        case 'sharp':
          numCircles = 20;
          waveType = 'sawtooth';
          speed = 1.2;
          break;
      }
    });
  }

  List<Map<String, double>> _getFourierCoefficients() {
    List<Map<String, double>> coefficients = [];

    for (int n = 0; n < numCircles; n++) {
      double freq;
      double amp;

      switch (waveType) {
        case 'square':
          // 사각파: 홀수 고조파만
          freq = 2 * n + 1;
          amp = 80 / (freq * math.pi);
          break;
        case 'sawtooth':
          // 톱니파: 모든 고조파
          freq = (n + 1).toDouble();
          amp = 80 / (freq * math.pi) * (n % 2 == 0 ? 1 : -1);
          break;
        case 'triangle':
          // 삼각파: 홀수 고조파, 진폭 감소
          freq = 2 * n + 1;
          amp = 80 * 8 / (math.pow(math.pi, 2) * math.pow(freq, 2)) *
              (n % 2 == 0 ? 1 : -1);
          break;
        default:
          freq = (n + 1).toDouble();
          amp = 80 / (n + 1);
      }

      coefficients.add({'freq': freq, 'amp': amp.abs(), 'phase': amp < 0 ? math.pi : 0});
    }

    return coefficients;
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      wave.clear();
      numCircles = _defaultNumCircles;
      speed = _defaultSpeed;
      waveType = 'square';
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
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '신호처리',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '푸리에 변환',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              showCircles ? Icons.circle_outlined : Icons.circle,
              color: showCircles ? AppColors.accent : AppColors.muted,
            ),
            tooltip: '원 표시',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => showCircles = !showCircles);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '신호처리',
          title: '푸리에 변환',
          formula: 'f(x) = Σ(aₙcos(nωx) + bₙsin(nωx))',
          formulaDescription: '모든 주기 함수는 사인, 코사인 함수의 합으로 표현 가능',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: FourierPainter(
                coefficients: _getFourierCoefficients(),
                time: time,
                wave: wave,
                showCircles: showCircles,
                onWaveUpdate: (newWave) => wave = newWave,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋
              PresetGroup(
                label: '근사 정도',
                presets: [
                  PresetButton(
                    label: '단순',
                    isSelected: _selectedPreset == 'simple',
                    onPressed: () => _applyPreset('simple'),
                  ),
                  PresetButton(
                    label: '상세',
                    isSelected: _selectedPreset == 'detailed',
                    onPressed: () => _applyPreset('detailed'),
                  ),
                  PresetButton(
                    label: '부드럽게',
                    isSelected: _selectedPreset == 'smooth',
                    onPressed: () => _applyPreset('smooth'),
                  ),
                  PresetButton(
                    label: '날카롭게',
                    isSelected: _selectedPreset == 'sharp',
                    onPressed: () => _applyPreset('sharp'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 파형 정보
              _WaveInfo(
                waveType: waveType,
                numCircles: numCircles,
              ),
              const SizedBox(height: 16),
              // 파형 선택
              PresetGroup(
                label: '파형 선택',
                presets: [
                  PresetButton(
                    label: '사각파',
                    isSelected: waveType == 'square',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        waveType = 'square';
                        wave.clear();
                        _selectedPreset = null;
                      });
                    },
                  ),
                  PresetButton(
                    label: '톱니파',
                    isSelected: waveType == 'sawtooth',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        waveType = 'sawtooth';
                        wave.clear();
                        _selectedPreset = null;
                      });
                    },
                  ),
                  PresetButton(
                    label: '삼각파',
                    isSelected: waveType == 'triangle',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        waveType = 'triangle';
                        wave.clear();
                        _selectedPreset = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '원의 개수 (고조파 수)',
                  value: numCircles.toDouble(),
                  min: 1,
                  max: 30,
                  defaultValue: _defaultNumCircles.toDouble(),
                  formatValue: (v) => '${v.toInt()}',
                  onChanged: (v) => setState(() {
                    numCircles = v.toInt();
                    wave.clear();
                    _selectedPreset = null;
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: '애니메이션 속도',
                    value: speed,
                    min: 0.2,
                    max: 3.0,
                    defaultValue: _defaultSpeed,
                    formatValue: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => setState(() {
                      speed = v;
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
}

/// 파형 정보 위젯
class _WaveInfo extends StatelessWidget {
  final String waveType;
  final int numCircles;

  const _WaveInfo({
    required this.waveType,
    required this.numCircles,
  });

  String get _waveTypeName {
    switch (waveType) {
      case 'square':
        return '사각파';
      case 'sawtooth':
        return '톱니파';
      case 'triangle':
        return '삼각파';
      default:
        return waveType;
    }
  }

  String get _harmonicsInfo {
    switch (waveType) {
      case 'square':
        return '홀수 고조파만';
      case 'sawtooth':
        return '모든 고조파';
      case 'triangle':
        return '홀수 고조파 (감쇠)';
      default:
        return '';
    }
  }

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
          _InfoItem(label: '파형', value: _waveTypeName),
          _InfoItem(label: '고조파', value: '$numCircles개'),
          _InfoItem(label: '특성', value: _harmonicsInfo),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

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
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class FourierPainter extends CustomPainter {
  final List<Map<String, double>> coefficients;
  final double time;
  final List<Offset> wave;
  final bool showCircles;
  final Function(List<Offset>) onWaveUpdate;

  FourierPainter({
    required this.coefficients,
    required this.time,
    required this.wave,
    required this.showCircles,
    required this.onWaveUpdate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    final centerX = size.width * 0.25;
    final centerY = size.height / 2;

    double x = centerX;
    double y = centerY;

    // 에피사이클 그리기
    for (int i = 0; i < coefficients.length; i++) {
      final coef = coefficients[i];
      final freq = coef['freq']!;
      final radius = coef['amp']!;
      final phase = coef['phase']!;

      if (showCircles) {
        // 원 그리기
        canvas.drawCircle(
          Offset(x, y),
          radius,
          Paint()
            ..color = AppColors.accent.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      // 다음 점 계산
      final angle = freq * time + phase;
      final prevX = x;
      final prevY = y;
      x += radius * math.cos(angle);
      y += radius * math.sin(angle);

      // 반지름 선
      canvas.drawLine(
        Offset(prevX, prevY),
        Offset(x, y),
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.6)
          ..strokeWidth = showCircles ? 2 : 1,
      );
    }

    // 끝점 표시 (글로우 효과)
    canvas.drawCircle(
      Offset(x, y),
      8,
      Paint()..color = AppColors.accent2.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      Offset(x, y),
      5,
      Paint()..color = AppColors.accent2,
    );

    // 파형 연결선
    final waveStartX = size.width * 0.45;
    canvas.drawLine(
      Offset(x, y),
      Offset(waveStartX, y),
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.4)
        ..strokeWidth = 1,
    );

    // 파형 업데이트
    final newWave = List<Offset>.from(wave);
    newWave.insert(0, Offset(waveStartX, y));
    if (newWave.length > 300) newWave.removeLast();
    onWaveUpdate(newWave);

    // 파형 그리기
    if (wave.length > 1) {
      final path = Path();
      path.moveTo(wave[0].dx, wave[0].dy);
      for (int i = 1; i < wave.length; i++) {
        path.lineTo(wave[i].dx + i * 0.5, wave[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // 파형 글로우
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // 중심축 표시
    canvas.drawLine(
      Offset(waveStartX, 0),
      Offset(waveStartX, size.height),
      Paint()
        ..color = AppColors.simGrid.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant FourierPainter oldDelegate) => true;
}
