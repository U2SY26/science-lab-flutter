import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 루이스 구조 시뮬레이션
class LewisStructureScreen extends StatefulWidget {
  const LewisStructureScreen({super.key});

  @override
  State<LewisStructureScreen> createState() => _LewisStructureScreenState();
}

class _LewisStructureScreenState extends State<LewisStructureScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  LewisExample _selectedExample = _examples[0];
  bool _showElectronPairs = true;
  bool _showFormalCharge = true;

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
              '루이스 구조',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학',
          title: '루이스 구조',
          formula: _selectedExample.formula,
          formulaDescription: '원자가 전자와 공유 결합을 점으로 표시하는 분자 표현법',
          simulation: SizedBox(
            height: 350,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LewisStructurePainter(
                    example: _selectedExample,
                    showElectronPairs: _showElectronPairs,
                    showFormalCharge: _showFormalCharge,
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
              // 분자 정보
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
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedExample.formula,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(label: '총 원자가 전자', value: '${_selectedExample.totalValence}'),
                    _DetailRow(label: '결합 전자쌍', value: '${_selectedExample.bondingPairs}'),
                    _DetailRow(label: '비공유 전자쌍', value: '${_selectedExample.lonePairs}'),
                    _DetailRow(label: '옥텟 규칙', value: _selectedExample.octetStatus),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 옵션 토글
              Row(
                children: [
                  Expanded(
                    child: _OptionToggle(
                      label: '전자쌍 표시',
                      isSelected: _showElectronPairs,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showElectronPairs = !_showElectronPairs);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OptionToggle(
                      label: '형식 전하',
                      isSelected: _showFormalCharge,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showFormalCharge = !_showFormalCharge);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 분자 선택
              const Text(
                '분자 선택',
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
                children: _examples.map((ex) {
                  final isSelected = _selectedExample == ex;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedExample = ex);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.2)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.cardBorder,
                        ),
                      ),
                      child: Text(
                        ex.formula,
                        style: TextStyle(
                          color: isSelected ? AppColors.accent : AppColors.muted,
                          fontWeight: FontWeight.w500,
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
                label: 'H₂O',
                icon: Icons.water_drop,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedExample = _examples[0]);
                },
              ),
              SimButton(
                label: 'CO₂',
                icon: Icons.cloud,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedExample = _examples[1]);
                },
              ),
              SimButton(
                label: 'NH₃',
                icon: Icons.science,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedExample = _examples[2]);
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
          color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: isSelected ? AppColors.accent : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LewisExample {
  final String name;
  final String formula;
  final int totalValence;
  final int bondingPairs;
  final int lonePairs;
  final String octetStatus;
  final List<LewisAtom> atoms;
  final List<LewisBond> bonds;

  const LewisExample({
    required this.name,
    required this.formula,
    required this.totalValence,
    required this.bondingPairs,
    required this.lonePairs,
    required this.octetStatus,
    required this.atoms,
    required this.bonds,
  });
}

class LewisAtom {
  final String symbol;
  final double x;
  final double y;
  final int lonePairs;
  final int formalCharge;
  final Color color;

  const LewisAtom({
    required this.symbol,
    required this.x,
    required this.y,
    this.lonePairs = 0,
    this.formalCharge = 0,
    required this.color,
  });
}

class LewisBond {
  final int atom1;
  final int atom2;
  final int order; // 1: single, 2: double, 3: triple

  const LewisBond({
    required this.atom1,
    required this.atom2,
    this.order = 1,
  });
}

const List<LewisExample> _examples = [
  // H2O
  LewisExample(
    name: '물',
    formula: 'H₂O',
    totalValence: 8,
    bondingPairs: 2,
    lonePairs: 2,
    octetStatus: '만족 (O: 8전자)',
    atoms: [
      LewisAtom(symbol: 'O', x: 0, y: 0, lonePairs: 2, color: Colors.red),
      LewisAtom(symbol: 'H', x: -0.8, y: 0.6, color: Colors.white),
      LewisAtom(symbol: 'H', x: 0.8, y: 0.6, color: Colors.white),
    ],
    bonds: [
      LewisBond(atom1: 0, atom2: 1),
      LewisBond(atom1: 0, atom2: 2),
    ],
  ),
  // CO2
  LewisExample(
    name: '이산화탄소',
    formula: 'CO₂',
    totalValence: 16,
    bondingPairs: 4,
    lonePairs: 4,
    octetStatus: '만족 (C, O: 8전자)',
    atoms: [
      LewisAtom(symbol: 'C', x: 0, y: 0, color: Colors.grey),
      LewisAtom(symbol: 'O', x: -1, y: 0, lonePairs: 2, color: Colors.red),
      LewisAtom(symbol: 'O', x: 1, y: 0, lonePairs: 2, color: Colors.red),
    ],
    bonds: [
      LewisBond(atom1: 0, atom2: 1, order: 2),
      LewisBond(atom1: 0, atom2: 2, order: 2),
    ],
  ),
  // NH3
  LewisExample(
    name: '암모니아',
    formula: 'NH₃',
    totalValence: 8,
    bondingPairs: 3,
    lonePairs: 1,
    octetStatus: '만족 (N: 8전자)',
    atoms: [
      LewisAtom(symbol: 'N', x: 0, y: 0, lonePairs: 1, color: Colors.blue),
      LewisAtom(symbol: 'H', x: -0.8, y: 0.6, color: Colors.white),
      LewisAtom(symbol: 'H', x: 0.8, y: 0.6, color: Colors.white),
      LewisAtom(symbol: 'H', x: 0, y: -0.8, color: Colors.white),
    ],
    bonds: [
      LewisBond(atom1: 0, atom2: 1),
      LewisBond(atom1: 0, atom2: 2),
      LewisBond(atom1: 0, atom2: 3),
    ],
  ),
  // CH4
  LewisExample(
    name: '메테인',
    formula: 'CH₄',
    totalValence: 8,
    bondingPairs: 4,
    lonePairs: 0,
    octetStatus: '만족 (C: 8전자)',
    atoms: [
      LewisAtom(symbol: 'C', x: 0, y: 0, color: Colors.grey),
      LewisAtom(symbol: 'H', x: -0.7, y: -0.7, color: Colors.white),
      LewisAtom(symbol: 'H', x: 0.7, y: -0.7, color: Colors.white),
      LewisAtom(symbol: 'H', x: -0.7, y: 0.7, color: Colors.white),
      LewisAtom(symbol: 'H', x: 0.7, y: 0.7, color: Colors.white),
    ],
    bonds: [
      LewisBond(atom1: 0, atom2: 1),
      LewisBond(atom1: 0, atom2: 2),
      LewisBond(atom1: 0, atom2: 3),
      LewisBond(atom1: 0, atom2: 4),
    ],
  ),
  // N2
  LewisExample(
    name: '질소',
    formula: 'N₂',
    totalValence: 10,
    bondingPairs: 3,
    lonePairs: 2,
    octetStatus: '만족 (삼중 결합)',
    atoms: [
      LewisAtom(symbol: 'N', x: -0.6, y: 0, lonePairs: 1, color: Colors.blue),
      LewisAtom(symbol: 'N', x: 0.6, y: 0, lonePairs: 1, color: Colors.blue),
    ],
    bonds: [
      LewisBond(atom1: 0, atom2: 1, order: 3),
    ],
  ),
  // O3 (Ozone)
  LewisExample(
    name: '오존',
    formula: 'O₃',
    totalValence: 18,
    bondingPairs: 3,
    lonePairs: 6,
    octetStatus: '공명 구조',
    atoms: [
      LewisAtom(symbol: 'O', x: 0, y: 0, lonePairs: 1, formalCharge: 1, color: Colors.red),
      LewisAtom(symbol: 'O', x: -0.9, y: 0.5, lonePairs: 3, formalCharge: -1, color: Colors.red),
      LewisAtom(symbol: 'O', x: 0.9, y: 0.5, lonePairs: 2, color: Colors.red),
    ],
    bonds: [
      LewisBond(atom1: 0, atom2: 1, order: 1),
      LewisBond(atom1: 0, atom2: 2, order: 2),
    ],
  ),
];

class _LewisStructurePainter extends CustomPainter {
  final LewisExample example;
  final bool showElectronPairs;
  final bool showFormalCharge;
  final double animation;

  _LewisStructurePainter({
    required this.example,
    required this.showElectronPairs,
    required this.showFormalCharge,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) / 4;

    // 결합 그리기
    for (final bond in example.bonds) {
      final atom1 = example.atoms[bond.atom1];
      final atom2 = example.atoms[bond.atom2];

      final p1 = Offset(center.dx + atom1.x * scale, center.dy + atom1.y * scale);
      final p2 = Offset(center.dx + atom2.x * scale, center.dy + atom2.y * scale);

      _drawBond(canvas, p1, p2, bond.order);
    }

    // 원자 그리기
    for (final atom in example.atoms) {
      final pos = Offset(center.dx + atom.x * scale, center.dy + atom.y * scale);
      _drawAtom(canvas, pos, atom);
    }

    // 타이틀
    _drawText(
      canvas,
      example.name,
      Offset(center.dx - 30, 20),
      AppColors.ink,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
  }

  void _drawBond(Canvas canvas, Offset p1, Offset p2, int order) {
    final bondPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final perpX = -dy / length * 6;
    final perpY = dx / length * 6;

    switch (order) {
      case 1:
        canvas.drawLine(p1, p2, bondPaint);
        break;
      case 2:
        canvas.drawLine(
          Offset(p1.dx + perpX, p1.dy + perpY),
          Offset(p2.dx + perpX, p2.dy + perpY),
          bondPaint,
        );
        canvas.drawLine(
          Offset(p1.dx - perpX, p1.dy - perpY),
          Offset(p2.dx - perpX, p2.dy - perpY),
          bondPaint,
        );
        break;
      case 3:
        canvas.drawLine(p1, p2, bondPaint);
        canvas.drawLine(
          Offset(p1.dx + perpX * 1.5, p1.dy + perpY * 1.5),
          Offset(p2.dx + perpX * 1.5, p2.dy + perpY * 1.5),
          bondPaint,
        );
        canvas.drawLine(
          Offset(p1.dx - perpX * 1.5, p1.dy - perpY * 1.5),
          Offset(p2.dx - perpX * 1.5, p2.dy - perpY * 1.5),
          bondPaint,
        );
        break;
    }

    // 결합 전자쌍 표시
    if (showElectronPairs) {
      final midX = (p1.dx + p2.dx) / 2;
      final midY = (p1.dy + p2.dy) / 2;

      for (int i = 0; i < order; i++) {
        final offset = (i - (order - 1) / 2) * 12;
        final electronPos = Offset(
          midX + perpX * offset / 6,
          midY + perpY * offset / 6,
        );

        // 공유 전자쌍 (2개 점)
        final dotOffset = 4.0;
        canvas.drawCircle(
          Offset(electronPos.dx - dotOffset, electronPos.dy),
          2.5,
          Paint()..color = AppColors.accent2,
        );
        canvas.drawCircle(
          Offset(electronPos.dx + dotOffset, electronPos.dy),
          2.5,
          Paint()..color = AppColors.accent2,
        );
      }
    }
  }

  void _drawAtom(Canvas canvas, Offset pos, LewisAtom atom) {
    final radius = atom.symbol == 'H' ? 22.0 : 28.0;

    // 원자 배경
    canvas.drawCircle(
      pos,
      radius,
      Paint()..color = atom.color.withValues(alpha: 0.9),
    );

    // 테두리
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 원소 기호
    _drawText(
      canvas,
      atom.symbol,
      Offset(pos.dx - 8, pos.dy - 10),
      atom.symbol == 'H' ? Colors.black : Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    // 비공유 전자쌍
    if (showElectronPairs && atom.lonePairs > 0) {
      final angles = _getLonePairAngles(atom);
      for (int i = 0; i < atom.lonePairs; i++) {
        final angle = angles[i];
        final pairDist = radius + 15;

        final pairPos = Offset(
          pos.dx + pairDist * math.cos(angle),
          pos.dy + pairDist * math.sin(angle),
        );

        // 비공유 전자쌍 (2개 점)
        final perpAngle = angle + math.pi / 2;
        canvas.drawCircle(
          Offset(
            pairPos.dx + 4 * math.cos(perpAngle),
            pairPos.dy + 4 * math.sin(perpAngle),
          ),
          3,
          Paint()..color = AppColors.accent,
        );
        canvas.drawCircle(
          Offset(
            pairPos.dx - 4 * math.cos(perpAngle),
            pairPos.dy - 4 * math.sin(perpAngle),
          ),
          3,
          Paint()..color = AppColors.accent,
        );
      }
    }

    // 형식 전하
    if (showFormalCharge && atom.formalCharge != 0) {
      final chargeText = atom.formalCharge > 0
          ? '+${atom.formalCharge}'
          : '${atom.formalCharge}';
      final chargeColor = atom.formalCharge > 0 ? Colors.red : Colors.blue;

      canvas.drawCircle(
        Offset(pos.dx + radius - 5, pos.dy - radius + 5),
        10,
        Paint()..color = chargeColor,
      );

      _drawText(
        canvas,
        chargeText,
        Offset(pos.dx + radius - 10, pos.dy - radius - 2),
        Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      );
    }
  }

  List<double> _getLonePairAngles(LewisAtom atom) {
    // 비공유 전자쌍 배치 각도
    switch (atom.lonePairs) {
      case 1:
        return [-math.pi / 2];
      case 2:
        return [-math.pi / 4, -3 * math.pi / 4];
      case 3:
        return [-math.pi / 2, math.pi / 6, 5 * math.pi / 6];
      default:
        return [];
    }
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
  bool shouldRepaint(covariant _LewisStructurePainter oldDelegate) {
    return oldDelegate.example != example ||
           oldDelegate.showElectronPairs != showElectronPairs ||
           oldDelegate.showFormalCharge != showFormalCharge;
  }
}
