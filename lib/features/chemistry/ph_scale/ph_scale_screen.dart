import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// pH 스케일 시뮬레이션
class PhScaleScreen extends StatefulWidget {
  const PhScaleScreen({super.key});

  @override
  State<PhScaleScreen> createState() => _PhScaleScreenState();
}

class _PhScaleScreenState extends State<PhScaleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _pH = 7.0;
  String? _selectedSolution;

  // 용액 예시
  static const Map<String, double> _solutions = {
    '위산': 1.5,
    '레몬즙': 2.0,
    '식초': 2.9,
    '오렌지주스': 3.5,
    '토마토': 4.5,
    '커피': 5.0,
    '우유': 6.5,
    '순수한 물': 7.0,
    '혈액': 7.4,
    '바닷물': 8.0,
    '베이킹소다': 8.5,
    '암모니아': 11.0,
    '표백제': 12.5,
    '배수관 세정제': 14.0,
  };

  // pH에 따른 색상 (보편적 pH 지시약 색상)
  Color get _pHColor {
    if (_pH < 3) return const Color(0xFFFF0000);
    if (_pH < 4) return const Color(0xFFFF6600);
    if (_pH < 5) return const Color(0xFFFF9900);
    if (_pH < 6) return const Color(0xFFFFCC00);
    if (_pH < 7) return const Color(0xFFCCFF00);
    if (_pH < 8) return const Color(0xFF66FF00);
    if (_pH < 9) return const Color(0xFF00FF66);
    if (_pH < 10) return const Color(0xFF00FFCC);
    if (_pH < 11) return const Color(0xFF00CCFF);
    if (_pH < 12) return const Color(0xFF0066FF);
    if (_pH < 13) return const Color(0xFF6600FF);
    return const Color(0xFF9900FF);
  }

  String get _classification {
    if (_pH < 7) return '산성';
    if (_pH > 7) return '염기성 (알칼리성)';
    return '중성';
  }

  double get _hConcentration => math.pow(10, -_pH).toDouble();
  double get _ohConcentration => math.pow(10, -_pOH).toDouble();
  double get _pOH => 14 - _pH;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectSolution(String name, double pH) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSolution = name;
      _pH = pH;
    });
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
              'pH 스케일',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학',
          title: 'pH 스케일',
          formula: 'pH = -log₁₀[H⁺]',
          formulaDescription: '용액의 수소이온 농도를 나타내는 척도 (0-14)',
          simulation: SizedBox(
            height: 380,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _pHScalePainter(
                    pH: _pH,
                    pHColor: _pHColor,
                    animation: _controller.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _pHColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _pHColor.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(
                          label: 'pH',
                          value: _pH.toStringAsFixed(1),
                          color: _pHColor,
                        ),
                        _InfoItem(
                          label: 'pOH',
                          value: _pOH.toStringAsFixed(1),
                          color: AppColors.accent2,
                        ),
                        _InfoItem(
                          label: '분류',
                          value: _classification,
                          color: AppColors.ink,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '[H⁺] = ${_hConcentration.toStringAsExponential(2)} M',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // pH 슬라이더
              ControlGroup(
                primaryControl: SimSlider(
                  label: 'pH 값',
                  value: _pH,
                  min: 0,
                  max: 14,
                  defaultValue: 7,
                  formatValue: (v) => v.toStringAsFixed(1),
                  onChanged: (v) {
                    setState(() {
                      _pH = v;
                      _selectedSolution = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 용액 예시 버튼
              const Text(
                '일반적인 용액',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _solutions.entries.map((e) {
                  final isSelected = _selectedSolution == e.key;
                  return GestureDetector(
                    onTap: () => _selectSolution(e.key, e.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.2)
                            : AppColors.simBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        '${e.key} (${e.value})',
                        style: TextStyle(
                          color: isSelected ? AppColors.accent : AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '산성 (pH 2)',
                icon: Icons.science,
                onPressed: () => _selectSolution('레몬즙', 2.0),
              ),
              SimButton(
                label: '중성 (pH 7)',
                icon: Icons.water_drop,
                isPrimary: true,
                onPressed: () => _selectSolution('순수한 물', 7.0),
              ),
              SimButton(
                label: '염기 (pH 12)',
                icon: Icons.cleaning_services,
                onPressed: () => _selectSolution('표백제', 12.5),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _pHScalePainter extends CustomPainter {
  final double pH;
  final Color pHColor;
  final double animation;

  _pHScalePainter({
    required this.pH,
    required this.pHColor,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    final centerX = size.width / 2;
    final scaleWidth = size.width - 60;
    final scaleLeft = 30.0;
    final scaleTop = 60.0;
    final scaleHeight = 50.0;

    // pH 스케일 그라데이션 바
    final List<Color> pHColors = [
      const Color(0xFFFF0000),  // 0
      const Color(0xFFFF6600),  // 2
      const Color(0xFFFFCC00),  // 4
      const Color(0xFFCCFF00),  // 6
      const Color(0xFF00FF00),  // 7
      const Color(0xFF00FFCC),  // 9
      const Color(0xFF0066FF),  // 11
      const Color(0xFF6600FF),  // 13
      const Color(0xFF9900FF),  // 14
    ];

    final gradient = LinearGradient(
      colors: pHColors,
    );

    final rect = Rect.fromLTWH(scaleLeft, scaleTop, scaleWidth, scaleHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..shader = gradient.createShader(rect),
    );

    // 눈금 및 숫자
    for (int i = 0; i <= 14; i++) {
      final x = scaleLeft + (scaleWidth * i / 14);
      final isMain = i % 2 == 0;

      canvas.drawLine(
        Offset(x, scaleTop + scaleHeight),
        Offset(x, scaleTop + scaleHeight + (isMain ? 10 : 5)),
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = isMain ? 1.5 : 1,
      );

      if (isMain) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$i',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: i == 7 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, scaleTop + scaleHeight + 12),
        );
      }
    }

    // 현재 pH 표시 마커
    final markerX = scaleLeft + (scaleWidth * pH / 14);

    // 마커 삼각형
    final markerPath = Path()
      ..moveTo(markerX, scaleTop - 5)
      ..lineTo(markerX - 10, scaleTop - 20)
      ..lineTo(markerX + 10, scaleTop - 20)
      ..close();

    canvas.drawPath(markerPath, Paint()..color = pHColor);
    canvas.drawPath(
      markerPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // pH 값 표시
    final pHText = TextPainter(
      text: TextSpan(
        text: 'pH ${pH.toStringAsFixed(1)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    pHText.layout();
    pHText.paint(
      canvas,
      Offset(markerX - pHText.width / 2, scaleTop - 38),
    );

    // 분류 라벨
    final acidLabel = TextPainter(
      text: const TextSpan(
        text: '산성 (ACIDIC)',
        style: TextStyle(color: Color(0xFFFF6600), fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    );
    acidLabel.layout();
    acidLabel.paint(canvas, Offset(scaleLeft + 10, scaleTop + scaleHeight + 35));

    final neutralLabel = TextPainter(
      text: const TextSpan(
        text: '중성',
        style: TextStyle(color: Color(0xFF00FF00), fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    );
    neutralLabel.layout();
    neutralLabel.paint(
      canvas,
      Offset(centerX - neutralLabel.width / 2, scaleTop + scaleHeight + 35),
    );

    final baseLabel = TextPainter(
      text: const TextSpan(
        text: '염기성 (BASIC)',
        style: TextStyle(color: Color(0xFF6600FF), fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    );
    baseLabel.layout();
    baseLabel.paint(
      canvas,
      Offset(scaleLeft + scaleWidth - baseLabel.width - 10, scaleTop + scaleHeight + 35),
    );

    // 비커 시각화
    final beakerCenterX = size.width / 2;
    final beakerTop = 180.0;
    final beakerWidth = 120.0;
    final beakerHeight = 150.0;

    // 비커 외형
    final beakerPath = Path()
      ..moveTo(beakerCenterX - beakerWidth / 2, beakerTop)
      ..lineTo(beakerCenterX - beakerWidth / 2 - 10, beakerTop + beakerHeight)
      ..lineTo(beakerCenterX + beakerWidth / 2 + 10, beakerTop + beakerHeight)
      ..lineTo(beakerCenterX + beakerWidth / 2, beakerTop);

    // 용액
    final liquidPath = Path()
      ..moveTo(beakerCenterX - beakerWidth / 2 + 5, beakerTop + 20)
      ..lineTo(beakerCenterX - beakerWidth / 2 - 5, beakerTop + beakerHeight - 5)
      ..lineTo(beakerCenterX + beakerWidth / 2 + 5, beakerTop + beakerHeight - 5)
      ..lineTo(beakerCenterX + beakerWidth / 2 - 5, beakerTop + 20)
      ..close();

    canvas.drawPath(liquidPath, Paint()..color = pHColor.withValues(alpha: 0.6));

    // 비커 유리
    canvas.drawPath(
      beakerPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 버블 애니메이션
    final random = math.Random(42);
    for (int i = 0; i < 8; i++) {
      final bubbleX = beakerCenterX - beakerWidth / 2 + 20 + random.nextDouble() * (beakerWidth - 40);
      final bubbleY = beakerTop + beakerHeight - 20 - ((animation + i * 0.1) % 1.0) * (beakerHeight - 50);
      final bubbleRadius = 2.0 + random.nextDouble() * 4;

      canvas.drawCircle(
        Offset(bubbleX, bubbleY),
        bubbleRadius,
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
    }

    // H+ 및 OH- 이온 표시
    final ionSize = 14.0;
    final hCount = (7 - (pH - 7).abs()).clamp(1, 7).toInt();

    if (pH < 7) {
      // 산성: H+ 이온 많이 표시
      for (int i = 0; i < hCount; i++) {
        final ionX = beakerCenterX - 40 + (i % 3) * 30;
        final ionY = beakerTop + 60 + (i ~/ 3) * 30;
        _drawIon(canvas, Offset(ionX, ionY), 'H⁺', ionSize, Colors.red);
      }
    } else if (pH > 7) {
      // 염기성: OH- 이온 많이 표시
      for (int i = 0; i < hCount; i++) {
        final ionX = beakerCenterX - 40 + (i % 3) * 30;
        final ionY = beakerTop + 60 + (i ~/ 3) * 30;
        _drawIon(canvas, Offset(ionX, ionY), 'OH⁻', ionSize, Colors.blue);
      }
    } else {
      // 중성: H+와 OH- 균형
      _drawIon(canvas, Offset(beakerCenterX - 25, beakerTop + 70), 'H⁺', ionSize, Colors.red);
      _drawIon(canvas, Offset(beakerCenterX + 25, beakerTop + 70), 'OH⁻', ionSize, Colors.blue);
    }
  }

  void _drawIon(Canvas canvas, Offset position, String text, double size, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _pHScalePainter oldDelegate) {
    return oldDelegate.pH != pH || oldDelegate.animation != animation;
  }
}
