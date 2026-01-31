import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 수소 결합 시뮬레이션
class HydrogenBondingScreen extends StatefulWidget {
  const HydrogenBondingScreen({super.key});

  @override
  State<HydrogenBondingScreen> createState() => _HydrogenBondingScreenState();
}

class _HydrogenBondingScreenState extends State<HydrogenBondingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int _moleculeCount = 5;
  bool _showHBonds = true;
  bool _showPartialCharges = true;
  HBondExample _selectedExample = HBondExample.water;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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
              '화학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '수소 결합',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학',
          title: '수소 결합',
          formula: 'X-H···Y (X, Y = F, O, N)',
          formulaDescription: '전기음성도가 큰 원자와 수소 사이의 분자간 인력',
          simulation: SizedBox(
            height: 350,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _HydrogenBondingPainter(
                    example: _selectedExample,
                    moleculeCount: _moleculeCount,
                    showHBonds: _showHBonds,
                    showPartialCharges: _showPartialCharges,
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
              // 수소 결합 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedExample.name,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedExample.formula,
                            style: const TextStyle(
                              color: Colors.cyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(label: '결합 에너지', value: _selectedExample.bondEnergy),
                    _DetailRow(label: '결합 길이', value: _selectedExample.bondLength),
                    _DetailRow(label: '특성', value: _selectedExample.property),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 옵션 토글
              Row(
                children: [
                  Expanded(
                    child: _OptionToggle(
                      label: '수소 결합 표시',
                      isSelected: _showHBonds,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showHBonds = !_showHBonds);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OptionToggle(
                      label: '부분 전하',
                      isSelected: _showPartialCharges,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showPartialCharges = !_showPartialCharges);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 예시 선택
              PresetGroup(
                label: '예시 분자',
                presets: [
                  PresetButton(
                    label: '물 (H₂O)',
                    isSelected: _selectedExample == HBondExample.water,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedExample = HBondExample.water);
                    },
                  ),
                  PresetButton(
                    label: 'DNA 염기쌍',
                    isSelected: _selectedExample == HBondExample.dna,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedExample = HBondExample.dna);
                    },
                  ),
                  PresetButton(
                    label: '단백질',
                    isSelected: _selectedExample == HBondExample.protein,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedExample = HBondExample.protein);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 분자 수 조절
              ControlGroup(
                primaryControl: SimSlider(
                  label: '분자 수',
                  value: _moleculeCount.toDouble(),
                  min: 2,
                  max: 8,
                  defaultValue: 5,
                  formatValue: (v) => '${v.toInt()}개',
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _moleculeCount = v.toInt());
                  },
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '물',
                icon: Icons.water_drop,
                isPrimary: _selectedExample == HBondExample.water,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedExample = HBondExample.water);
                },
              ),
              SimButton(
                label: 'DNA',
                icon: Icons.biotech,
                isPrimary: _selectedExample == HBondExample.dna,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedExample = HBondExample.dna);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionToggle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyan.withValues(alpha: 0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.cyan : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: isSelected ? Colors.cyan : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.cyan : AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum HBondExample {
  water('물 분자 네트워크', 'H₂O···H₂O', '~20 kJ/mol', '~1.97 Å', '높은 끓는점, 표면장력'),
  dna('DNA 염기쌍', 'A-T, G-C', '~12-29 kJ/mol', '~2.8-3.0 Å', 'DNA 이중나선 안정화'),
  protein('단백질 2차구조', 'N-H···O=C', '~8-20 kJ/mol', '~2.0 Å', '알파헬릭스, 베타시트');

  final String name;
  final String formula;
  final String bondEnergy;
  final String bondLength;
  final String property;

  const HBondExample(this.name, this.formula, this.bondEnergy, this.bondLength, this.property);
}

class _HydrogenBondingPainter extends CustomPainter {
  final HBondExample example;
  final int moleculeCount;
  final bool showHBonds;
  final bool showPartialCharges;
  final double animation;

  _HydrogenBondingPainter({
    required this.example,
    required this.moleculeCount,
    required this.showHBonds,
    required this.showPartialCharges,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    switch (example) {
      case HBondExample.water:
        _drawWaterNetwork(canvas, size);
        break;
      case HBondExample.dna:
        _drawDNABasePair(canvas, size);
        break;
      case HBondExample.protein:
        _drawProteinStructure(canvas, size);
        break;
    }
  }

  void _drawWaterNetwork(Canvas canvas, Size size) {
    final random = math.Random(42);
    final molecules = <Offset>[];

    // 분자 위치 생성
    for (int i = 0; i < moleculeCount; i++) {
      final x = 80 + random.nextDouble() * (size.width - 160);
      final y = 60 + random.nextDouble() * (size.height - 120);
      molecules.add(Offset(x, y));
    }

    // 수소 결합 그리기
    if (showHBonds) {
      for (int i = 0; i < molecules.length; i++) {
        for (int j = i + 1; j < molecules.length; j++) {
          final dist = (molecules[i] - molecules[j]).distance;
          if (dist < 120) {
            _drawHydrogenBond(canvas, molecules[i], molecules[j], animation);
          }
        }
      }
    }

    // 물 분자 그리기
    for (int i = 0; i < molecules.length; i++) {
      final angle = animation * math.pi * 2 + i * 0.5;
      _drawWaterMolecule(canvas, molecules[i], angle);
    }

    // 범례
    _drawText(canvas, '물 분자 네트워크', Offset(size.width / 2 - 50, 15), AppColors.ink, fontSize: 14, fontWeight: FontWeight.bold);
    _drawText(canvas, '점선: 수소결합', Offset(size.width / 2 - 40, size.height - 25), AppColors.muted, fontSize: 11);
  }

  void _drawWaterMolecule(Canvas canvas, Offset center, double rotation) {
    final bondLength = 25.0;
    final angle = 104.5 * math.pi / 180;

    // 산소
    final oPos = center;

    // 수소 위치
    final h1Pos = Offset(
      center.dx + bondLength * math.cos(rotation - angle / 2),
      center.dy + bondLength * math.sin(rotation - angle / 2),
    );
    final h2Pos = Offset(
      center.dx + bondLength * math.cos(rotation + angle / 2),
      center.dy + bondLength * math.sin(rotation + angle / 2),
    );

    // 결합선
    canvas.drawLine(oPos, h1Pos, Paint()..color = AppColors.accent..strokeWidth = 3);
    canvas.drawLine(oPos, h2Pos, Paint()..color = AppColors.accent..strokeWidth = 3);

    // 산소 원자
    canvas.drawCircle(oPos, 15, Paint()..color = Colors.red);
    if (showPartialCharges) {
      _drawText(canvas, 'δ-', Offset(oPos.dx - 8, oPos.dy - 25), Colors.blue, fontSize: 10, fontWeight: FontWeight.bold);
    }

    // 수소 원자
    canvas.drawCircle(h1Pos, 10, Paint()..color = Colors.white);
    canvas.drawCircle(h2Pos, 10, Paint()..color = Colors.white);

    if (showPartialCharges) {
      _drawText(canvas, 'δ+', Offset(h1Pos.dx - 6, h1Pos.dy + 12), Colors.red, fontSize: 9, fontWeight: FontWeight.bold);
      _drawText(canvas, 'δ+', Offset(h2Pos.dx - 6, h2Pos.dy + 12), Colors.red, fontSize: 9, fontWeight: FontWeight.bold);
    }

    // 원자 기호
    _drawText(canvas, 'O', Offset(oPos.dx - 5, oPos.dy - 7), Colors.white, fontSize: 12, fontWeight: FontWeight.bold);
    _drawText(canvas, 'H', Offset(h1Pos.dx - 4, h1Pos.dy - 6), Colors.black, fontSize: 10);
    _drawText(canvas, 'H', Offset(h2Pos.dx - 4, h2Pos.dy - 6), Colors.black, fontSize: 10);
  }

  void _drawHydrogenBond(Canvas canvas, Offset p1, Offset p2, double anim) {
    final dashPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.6 + 0.3 * math.sin(anim * math.pi * 2))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 점선 그리기
    final path = Path();
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final dashLength = 6.0;
    final gapLength = 4.0;

    double drawn = 0;
    bool drawing = true;

    while (drawn < length) {
      final startRatio = drawn / length;
      final segmentLength = drawing ? dashLength : gapLength;
      final endRatio = math.min((drawn + segmentLength) / length, 1.0);

      if (drawing) {
        path.moveTo(
          p1.dx + dx * startRatio,
          p1.dy + dy * startRatio,
        );
        path.lineTo(
          p1.dx + dx * endRatio,
          p1.dy + dy * endRatio,
        );
      }

      drawn += segmentLength;
      drawing = !drawing;
    }

    canvas.drawPath(path, dashPaint);
  }

  void _drawDNABasePair(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // A-T 염기쌍 (2개 수소결합)
    final atX = size.width * 0.3;

    // 아데닌 (A)
    _drawBase(canvas, Offset(atX - 40, centerY), 'A', Colors.green);
    // 티민 (T)
    _drawBase(canvas, Offset(atX + 40, centerY), 'T', Colors.red);

    if (showHBonds) {
      _drawHydrogenBond(canvas, Offset(atX - 15, centerY - 10), Offset(atX + 15, centerY - 10), animation);
      _drawHydrogenBond(canvas, Offset(atX - 15, centerY + 10), Offset(atX + 15, centerY + 10), animation);
    }

    // G-C 염기쌍 (3개 수소결합)
    final gcX = size.width * 0.7;

    // 구아닌 (G)
    _drawBase(canvas, Offset(gcX - 40, centerY), 'G', Colors.blue);
    // 시토신 (C)
    _drawBase(canvas, Offset(gcX + 40, centerY), 'C', Colors.orange);

    if (showHBonds) {
      _drawHydrogenBond(canvas, Offset(gcX - 15, centerY - 15), Offset(gcX + 15, centerY - 15), animation);
      _drawHydrogenBond(canvas, Offset(gcX - 15, centerY), Offset(gcX + 15, centerY), animation);
      _drawHydrogenBond(canvas, Offset(gcX - 15, centerY + 15), Offset(gcX + 15, centerY + 15), animation);
    }

    // 라벨
    _drawText(canvas, 'A-T (2 H-bonds)', Offset(atX - 45, centerY + 60), AppColors.muted, fontSize: 11);
    _drawText(canvas, 'G-C (3 H-bonds)', Offset(gcX - 45, centerY + 60), AppColors.muted, fontSize: 11);
    _drawText(canvas, 'DNA 염기쌍 수소결합', Offset(size.width / 2 - 65, 20), AppColors.ink, fontSize: 14, fontWeight: FontWeight.bold);
  }

  void _drawBase(Canvas canvas, Offset center, String label, Color color) {
    // 육각형 베이스
    final path = Path();
    final radius = 30.0;

    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 - math.pi / 6;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.3));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawText(canvas, label, Offset(center.dx - 8, center.dy - 10), color, fontSize: 20, fontWeight: FontWeight.bold);
  }

  void _drawProteinStructure(Canvas canvas, Size size) {
    // 알파 헬릭스 표현
    final centerX = size.width / 2;
    final startY = 60.0;

    for (int i = 0; i < moleculeCount; i++) {
      final y = startY + i * 50;
      final xOffset = 40 * math.sin(i * 0.8 + animation * math.pi * 2);

      // 아미노산 잔기
      canvas.drawCircle(
        Offset(centerX + xOffset, y),
        20,
        Paint()..color = AppColors.accent.withValues(alpha: 0.7),
      );

      // C=O (카르보닐)
      canvas.drawCircle(
        Offset(centerX + xOffset + 25, y - 10),
        8,
        Paint()..color = Colors.red,
      );

      // N-H (아미드)
      canvas.drawCircle(
        Offset(centerX + xOffset - 25, y + 10),
        8,
        Paint()..color = Colors.blue,
      );

      // 수소결합 (i → i+4)
      if (showHBonds && i >= 4) {
        final prevY = startY + (i - 4) * 50;
        final prevXOffset = 40 * math.sin((i - 4) * 0.8 + animation * math.pi * 2);

        _drawHydrogenBond(
          canvas,
          Offset(centerX + xOffset - 25, y + 10),
          Offset(centerX + prevXOffset + 25, prevY - 10),
          animation,
        );
      }

      // 라벨
      _drawText(canvas, '${i + 1}', Offset(centerX + xOffset - 5, y - 7), Colors.white, fontSize: 12);
    }

    _drawText(canvas, '알파 헬릭스 (i → i+4 수소결합)', Offset(size.width / 2 - 90, 20), AppColors.ink, fontSize: 14, fontWeight: FontWeight.bold);
    _drawText(canvas, 'N-H···O=C', Offset(size.width / 2 - 30, size.height - 30), AppColors.muted, fontSize: 11);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    Color color, {
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.normal,
  }) {
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
  bool shouldRepaint(covariant _HydrogenBondingPainter oldDelegate) {
    return oldDelegate.animation != animation ||
           oldDelegate.example != example ||
           oldDelegate.moleculeCount != moleculeCount;
  }
}
