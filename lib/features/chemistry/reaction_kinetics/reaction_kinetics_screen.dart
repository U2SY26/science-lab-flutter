import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 반응 속도론 시뮬레이션
class ReactionKineticsScreen extends StatefulWidget {
  const ReactionKineticsScreen({super.key});

  @override
  State<ReactionKineticsScreen> createState() => _ReactionKineticsScreenState();
}

class _ReactionKineticsScreenState extends State<ReactionKineticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 반응 파라미터
  double _temperature = 300; // K
  double _activationEnergy = 50; // kJ/mol
  double _concentration = 1.0; // M
  int _reactionOrder = 1;
  bool _isRunning = true;

  // 반응 진행
  double _time = 0;
  List<double> _concentrationHistory = [];
  List<double> _timeHistory = [];

  // 상수
  static const double R = 8.314; // J/(mol·K)
  static const double A = 1e10; // 전지수 인자

  double get _rateConstant {
    // Arrhenius 방정식: k = A * exp(-Ea/RT)
    return A * math.exp(-_activationEnergy * 1000 / (R * _temperature));
  }

  double get _halfLife {
    switch (_reactionOrder) {
      case 0:
        return _concentration / (2 * _rateConstant);
      case 1:
        return math.log(2) / _rateConstant;
      case 2:
        return 1 / (_rateConstant * _concentration);
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _resetReaction();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateReaction);
    _controller.repeat();
  }

  void _resetReaction() {
    setState(() {
      _time = 0;
      _concentrationHistory = [_concentration];
      _timeHistory = [0];
    });
  }

  void _updateReaction() {
    if (!_isRunning) return;

    setState(() {
      _time += 0.01;

      double currentConc;
      switch (_reactionOrder) {
        case 0:
          // [A] = [A]₀ - kt
          currentConc = math.max(0, _concentration - _rateConstant * _time);
          break;
        case 1:
          // [A] = [A]₀ * exp(-kt)
          currentConc = _concentration * math.exp(-_rateConstant * _time);
          break;
        case 2:
          // 1/[A] = 1/[A]₀ + kt
          currentConc = _concentration / (1 + _rateConstant * _concentration * _time);
          break;
        default:
          currentConc = _concentration;
      }

      _concentrationHistory.add(currentConc);
      _timeHistory.add(_time);

      // 최대 500개 데이터 포인트
      if (_concentrationHistory.length > 500) {
        _concentrationHistory.removeAt(0);
        _timeHistory.removeAt(0);
      }
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
              '화학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '반응 속도론',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학',
          title: '반응 속도론',
          formula: 'k = A·exp(-Eₐ/RT)',
          formulaDescription: 'Arrhenius 방정식 - 온도와 활성화 에너지에 따른 반응 속도',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _ReactionKineticsPainter(
                concentrationHistory: _concentrationHistory,
                timeHistory: _timeHistory,
                initialConcentration: _concentration,
                reactionOrder: _reactionOrder,
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
                        _InfoItem(
                          label: '반응 속도 상수 k',
                          value: _rateConstant.toStringAsExponential(2),
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: '반감기 t½',
                          value: _halfLife.isFinite
                              ? '${_halfLife.toStringAsFixed(3)} s'
                              : '∞',
                          color: AppColors.accent2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(
                          label: '시간',
                          value: '${_time.toStringAsFixed(2)} s',
                          color: AppColors.muted,
                        ),
                        _InfoItem(
                          label: '현재 농도',
                          value: _concentrationHistory.isNotEmpty
                              ? '${_concentrationHistory.last.toStringAsFixed(3)} M'
                              : '-',
                          color: AppColors.ink,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 반응 차수 선택
              PresetGroup(
                label: '반응 차수',
                presets: [
                  PresetButton(
                    label: '0차',
                    isSelected: _reactionOrder == 0,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _reactionOrder = 0;
                        _resetReaction();
                      });
                    },
                  ),
                  PresetButton(
                    label: '1차',
                    isSelected: _reactionOrder == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _reactionOrder = 1;
                        _resetReaction();
                      });
                    },
                  ),
                  PresetButton(
                    label: '2차',
                    isSelected: _reactionOrder == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _reactionOrder = 2;
                        _resetReaction();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 파라미터 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '온도 (K)',
                  value: _temperature,
                  min: 200,
                  max: 500,
                  defaultValue: 300,
                  formatValue: (v) => '${v.toInt()} K (${(v - 273.15).toInt()}°C)',
                  onChanged: (v) {
                    setState(() {
                      _temperature = v;
                      _resetReaction();
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '활성화 에너지 (kJ/mol)',
                    value: _activationEnergy,
                    min: 10,
                    max: 100,
                    defaultValue: 50,
                    formatValue: (v) => '${v.toInt()} kJ/mol',
                    onChanged: (v) {
                      setState(() {
                        _activationEnergy = v;
                        _resetReaction();
                      });
                    },
                  ),
                  SimSlider(
                    label: '초기 농도 (M)',
                    value: _concentration,
                    min: 0.1,
                    max: 2.0,
                    defaultValue: 1.0,
                    formatValue: (v) => '${v.toStringAsFixed(1)} M',
                    onChanged: (v) {
                      setState(() {
                        _concentration = v;
                        _resetReaction();
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
                label: '리셋',
                icon: Icons.refresh,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _resetReaction();
                },
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

  const _InfoItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReactionKineticsPainter extends CustomPainter {
  final List<double> concentrationHistory;
  final List<double> timeHistory;
  final double initialConcentration;
  final int reactionOrder;

  _ReactionKineticsPainter({
    required this.concentrationHistory,
    required this.timeHistory,
    required this.initialConcentration,
    required this.reactionOrder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    final padding = 50.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 축 그리기
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // Y축
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );

    // X축
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );

    // 축 라벨
    _drawText(canvas, '농도 [A]', Offset(10, padding - 20), AppColors.muted, 11);
    _drawText(canvas, '시간 (s)', Offset(size.width - 60, size.height - 20), AppColors.muted, 11);

    // 그리드
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    for (int i = 1; i <= 4; i++) {
      final y = padding + (graphHeight * i / 4);
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );

      // Y축 값
      final yValue = initialConcentration * (4 - i) / 4;
      _drawText(
        canvas,
        yValue.toStringAsFixed(2),
        Offset(padding - 35, y - 5),
        AppColors.muted,
        9,
      );
    }

    if (concentrationHistory.isEmpty || timeHistory.isEmpty) return;

    // 시간 범위 계산
    final maxTime = timeHistory.isNotEmpty ? timeHistory.last : 1.0;
    final timeScale = maxTime > 0 ? graphWidth / maxTime : 1;

    // 농도 그래프 그리기
    final graphPath = Path();
    bool started = false;

    for (int i = 0; i < concentrationHistory.length; i++) {
      final x = padding + timeHistory[i] * timeScale;
      final normalizedConc = concentrationHistory[i] / initialConcentration;
      final y = padding + graphHeight * (1 - normalizedConc.clamp(0, 1));

      if (!started) {
        graphPath.moveTo(x, y);
        started = true;
      } else {
        graphPath.lineTo(x, y);
      }
    }

    // 그래프 선
    canvas.drawPath(
      graphPath,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 현재 위치 점
    if (concentrationHistory.isNotEmpty) {
      final lastX = padding + timeHistory.last * timeScale;
      final lastY = padding + graphHeight * (1 - (concentrationHistory.last / initialConcentration).clamp(0, 1));

      canvas.drawCircle(
        Offset(lastX, lastY),
        8,
        Paint()..color = AppColors.accent.withValues(alpha: 0.3),
      );
      canvas.drawCircle(
        Offset(lastX, lastY),
        5,
        Paint()..color = AppColors.accent,
      );
    }

    // 반응 차수 표시
    String orderText;
    String equation;
    switch (reactionOrder) {
      case 0:
        orderText = '0차 반응';
        equation = '[A] = [A]₀ - kt';
        break;
      case 1:
        orderText = '1차 반응';
        equation = '[A] = [A]₀·e⁻ᵏᵗ';
        break;
      case 2:
        orderText = '2차 반응';
        equation = '1/[A] = 1/[A]₀ + kt';
        break;
      default:
        orderText = '';
        equation = '';
    }

    _drawText(canvas, orderText, Offset(size.width - 100, padding + 10), AppColors.accent, 12, fontWeight: FontWeight.bold);
    _drawText(canvas, equation, Offset(size.width - 120, padding + 28), AppColors.muted, 11);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize, {FontWeight fontWeight = FontWeight.normal}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _ReactionKineticsPainter oldDelegate) {
    return oldDelegate.concentrationHistory.length != concentrationHistory.length;
  }
}
