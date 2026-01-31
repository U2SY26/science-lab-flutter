import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 적정 곡선 시뮬레이션
class TitrationScreen extends StatefulWidget {
  const TitrationScreen({super.key});

  @override
  State<TitrationScreen> createState() => _TitrationScreenState();
}

class _TitrationScreenState extends State<TitrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 적정 파라미터
  double _acidConcentration = 0.1; // M
  double _baseConcentration = 0.1; // M
  double _acidVolume = 50.0; // mL
  double _addedBaseVolume = 0.0; // mL
  TitrationType _titrationType = TitrationType.strongStrong;

  // 애니메이션
  bool _isAnimating = false;
  List<Offset> _titrationCurve = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        if (_isAnimating) {
          setState(() {
            _addedBaseVolume = _controller.value * 100;
          });
        }
      });
    _calculateCurve();
  }

  void _calculateCurve() {
    _titrationCurve.clear();
    for (double v = 0; v <= 100; v += 0.5) {
      final pH = _calculatePH(v);
      _titrationCurve.add(Offset(v, pH));
    }
  }

  double _calculatePH(double addedVolume) {
    final totalVolume = _acidVolume + addedVolume;
    final molesAcid = _acidConcentration * _acidVolume / 1000;
    final molesBase = _baseConcentration * addedVolume / 1000;

    switch (_titrationType) {
      case TitrationType.strongStrong:
        if (molesBase < molesAcid) {
          // 산 과잉
          final excessH = (molesAcid - molesBase) / (totalVolume / 1000);
          return -math.log(excessH) / math.ln10;
        } else if (molesBase > molesAcid) {
          // 염기 과잉
          final excessOH = (molesBase - molesAcid) / (totalVolume / 1000);
          final pOH = -math.log(excessOH) / math.ln10;
          return 14 - pOH;
        } else {
          return 7.0; // 당량점
        }

      case TitrationType.weakStrong:
        // 약산-강염기 적정 (아세트산 Ka = 1.8e-5)
        const Ka = 1.8e-5;
        if (molesBase < molesAcid) {
          // Henderson-Hasselbalch 방정식
          final ratio = molesBase / (molesAcid - molesBase);
          if (ratio <= 0) {
            // 초기 약산만
            final H = math.sqrt(Ka * molesAcid / (totalVolume / 1000));
            return -math.log(H) / math.ln10;
          }
          final pKa = -math.log(Ka) / math.ln10;
          return pKa + math.log(ratio) / math.ln10;
        } else if (molesBase > molesAcid) {
          final excessOH = (molesBase - molesAcid) / (totalVolume / 1000);
          final pOH = -math.log(excessOH) / math.ln10;
          return 14 - pOH;
        } else {
          // 당량점: 짝염기 가수분해
          return 8.72;
        }

      case TitrationType.strongWeak:
        // 강산-약염기 적정 (암모니아 Kb = 1.8e-5)
        const Kb = 1.8e-5;
        final molesBaseInit = _acidConcentration * _acidVolume / 1000; // 초기 염기
        final molesAcidAdded = _baseConcentration * addedVolume / 1000; // 추가된 산

        if (molesAcidAdded < molesBaseInit) {
          final ratio = molesAcidAdded / (molesBaseInit - molesAcidAdded);
          if (ratio <= 0) {
            final OH = math.sqrt(Kb * molesBaseInit / (totalVolume / 1000));
            final pOH = -math.log(OH) / math.ln10;
            return 14 - pOH;
          }
          final pKb = -math.log(Kb) / math.ln10;
          final pOH = pKb + math.log(ratio) / math.ln10;
          return 14 - pOH;
        } else if (molesAcidAdded > molesBaseInit) {
          final excessH = (molesAcidAdded - molesBaseInit) / (totalVolume / 1000);
          return -math.log(excessH) / math.ln10;
        } else {
          return 5.28; // 당량점
        }
    }
  }

  double get _currentPH => _calculatePH(_addedBaseVolume);

  double get _equivalencePoint {
    return (_acidConcentration * _acidVolume) / _baseConcentration;
  }

  Color get _indicatorColor {
    final pH = _currentPH;
    if (pH < 4.4) return Colors.red;
    if (pH < 6.2) return Colors.orange;
    if (pH < 7.6) return Colors.yellow;
    if (pH < 8.2) return Colors.green;
    if (pH < 10.0) return Colors.blue;
    return Colors.purple;
  }

  void _startAnimation() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isAnimating = true;
      _addedBaseVolume = 0;
    });
    _controller.forward(from: 0);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      _isAnimating = false;
      _addedBaseVolume = 0;
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
              '적정 곡선',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학',
          title: '적정 곡선',
          formula: 'pH = pKₐ + log([A⁻]/[HA])',
          formulaDescription: 'Henderson-Hasselbalch 방정식을 통한 완충 용액의 pH 계산',
          simulation: SizedBox(
            height: 380,
            child: Row(
              children: [
                // 적정 곡선 그래프
                Expanded(
                  flex: 3,
                  child: CustomPaint(
                    painter: _TitrationCurvePainter(
                      curve: _titrationCurve,
                      currentVolume: _addedBaseVolume,
                      currentPH: _currentPH,
                      equivalencePoint: _equivalencePoint,
                    ),
                    size: Size.infinite,
                  ),
                ),
                // 비커 시각화
                Expanded(
                  flex: 2,
                  child: CustomPaint(
                    painter: _BeakerPainter(
                      fillLevel: (_acidVolume + _addedBaseVolume) / 150,
                      color: _indicatorColor,
                      addedVolume: _addedBaseVolume,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _indicatorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _indicatorColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InfoItem(
                      label: 'pH',
                      value: _currentPH.toStringAsFixed(2),
                      color: _indicatorColor,
                    ),
                    _InfoItem(
                      label: '추가된 염기',
                      value: '${_addedBaseVolume.toStringAsFixed(1)} mL',
                      color: AppColors.accent,
                    ),
                    _InfoItem(
                      label: '당량점',
                      value: '${_equivalencePoint.toStringAsFixed(1)} mL',
                      color: AppColors.accent2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 적정 타입 선택
              PresetGroup(
                label: '적정 타입',
                presets: [
                  PresetButton(
                    label: '강산-강염기',
                    isSelected: _titrationType == TitrationType.strongStrong,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _titrationType = TitrationType.strongStrong;
                        _calculateCurve();
                      });
                    },
                  ),
                  PresetButton(
                    label: '약산-강염기',
                    isSelected: _titrationType == TitrationType.weakStrong,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _titrationType = TitrationType.weakStrong;
                        _calculateCurve();
                      });
                    },
                  ),
                  PresetButton(
                    label: '강산-약염기',
                    isSelected: _titrationType == TitrationType.strongWeak,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _titrationType = TitrationType.strongWeak;
                        _calculateCurve();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 염기 부피 슬라이더
              ControlGroup(
                primaryControl: SimSlider(
                  label: '추가 염기 부피 (mL)',
                  value: _addedBaseVolume,
                  min: 0,
                  max: 100,
                  defaultValue: 0,
                  formatValue: (v) => '${v.toStringAsFixed(1)} mL',
                  onChanged: (v) {
                    if (!_isAnimating) {
                      setState(() => _addedBaseVolume = v);
                    }
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '산 농도 (M)',
                    value: _acidConcentration,
                    min: 0.01,
                    max: 0.5,
                    defaultValue: 0.1,
                    formatValue: (v) => '${v.toStringAsFixed(2)} M',
                    onChanged: (v) {
                      setState(() {
                        _acidConcentration = v;
                        _calculateCurve();
                      });
                    },
                  ),
                  SimSlider(
                    label: '염기 농도 (M)',
                    value: _baseConcentration,
                    min: 0.01,
                    max: 0.5,
                    defaultValue: 0.1,
                    formatValue: (v) => '${v.toStringAsFixed(2)} M',
                    onChanged: (v) {
                      setState(() {
                        _baseConcentration = v;
                        _calculateCurve();
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
                label: '적정 시작',
                icon: Icons.play_arrow,
                isPrimary: true,
                onPressed: _startAnimation,
              ),
              SimButton(
                label: '당량점으로',
                icon: Icons.adjust,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _isAnimating = false;
                    _addedBaseVolume = _equivalencePoint;
                  });
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

enum TitrationType {
  strongStrong,
  weakStrong,
  strongWeak,
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TitrationCurvePainter extends CustomPainter {
  final List<Offset> curve;
  final double currentVolume;
  final double currentPH;
  final double equivalencePoint;

  _TitrationCurvePainter({
    required this.curve,
    required this.currentVolume,
    required this.currentPH,
    required this.equivalencePoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 축
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );

    // 그리드
    for (int i = 0; i <= 14; i += 2) {
      final y = size.height - padding - (i / 14) * graphHeight;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        Paint()
          ..color = AppColors.simGrid.withValues(alpha: 0.2)
          ..strokeWidth = 0.5,
      );
      _drawText(canvas, '$i', Offset(padding - 20, y - 5), AppColors.muted, 9);
    }

    // 당량점 표시
    final eqX = padding + (equivalencePoint / 100) * graphWidth;
    canvas.drawLine(
      Offset(eqX, padding),
      Offset(eqX, size.height - padding),
      Paint()
        ..color = AppColors.accent2.withValues(alpha: 0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    // 적정 곡선
    if (curve.isNotEmpty) {
      final path = Path();
      for (int i = 0; i < curve.length; i++) {
        final x = padding + (curve[i].dx / 100) * graphWidth;
        final y = size.height - padding - (curve[i].dy.clamp(0, 14) / 14) * graphHeight;
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
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // 현재 위치
    final currentX = padding + (currentVolume / 100) * graphWidth;
    final currentY = size.height - padding - (currentPH.clamp(0, 14) / 14) * graphHeight;

    canvas.drawCircle(
      Offset(currentX, currentY),
      8,
      Paint()..color = AppColors.accent.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      Offset(currentX, currentY),
      5,
      Paint()..color = AppColors.accent,
    );

    // 라벨
    _drawText(canvas, 'pH', Offset(padding - 25, padding - 15), AppColors.muted, 11);
    _drawText(canvas, 'Volume (mL)', Offset(size.width - 70, size.height - 15), AppColors.muted, 10);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _TitrationCurvePainter oldDelegate) {
    return oldDelegate.currentVolume != currentVolume;
  }
}

class _BeakerPainter extends CustomPainter {
  final double fillLevel;
  final Color color;
  final double addedVolume;

  _BeakerPainter({
    required this.fillLevel,
    required this.color,
    required this.addedVolume,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final beakerWidth = size.width * 0.7;
    final beakerHeight = size.height * 0.7;
    final beakerTop = size.height * 0.15;

    // 비커 외형
    final beakerPath = Path()
      ..moveTo(centerX - beakerWidth / 2, beakerTop)
      ..lineTo(centerX - beakerWidth / 2 - 5, beakerTop + beakerHeight)
      ..lineTo(centerX + beakerWidth / 2 + 5, beakerTop + beakerHeight)
      ..lineTo(centerX + beakerWidth / 2, beakerTop);

    // 용액
    final liquidHeight = beakerHeight * fillLevel.clamp(0, 0.9);
    final liquidTop = beakerTop + beakerHeight - liquidHeight;

    final liquidPath = Path()
      ..moveTo(centerX - beakerWidth / 2 + 5, liquidTop)
      ..lineTo(centerX - beakerWidth / 2, beakerTop + beakerHeight - 5)
      ..lineTo(centerX + beakerWidth / 2, beakerTop + beakerHeight - 5)
      ..lineTo(centerX + beakerWidth / 2 - 5, liquidTop)
      ..close();

    canvas.drawPath(liquidPath, Paint()..color = color.withValues(alpha: 0.6));

    // 비커 유리
    canvas.drawPath(
      beakerPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 뷰렛
    final buretteX = centerX;
    final buretteTop = 10.0;
    final buretteWidth = 15.0;

    canvas.drawRect(
      Rect.fromLTWH(buretteX - buretteWidth / 2, buretteTop, buretteWidth, 60),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );

    // 떨어지는 방울
    if (addedVolume > 0 && addedVolume < 100) {
      final dropY = beakerTop + (addedVolume % 5) * 10;
      canvas.drawCircle(
        Offset(buretteX, dropY),
        4,
        Paint()..color = Colors.blue.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BeakerPainter oldDelegate) {
    return oldDelegate.fillLevel != fillLevel || oldDelegate.color != color;
  }
}
