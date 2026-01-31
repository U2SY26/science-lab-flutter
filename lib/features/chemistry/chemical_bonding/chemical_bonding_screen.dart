import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 화학 결합 시뮬레이션 (이온/공유 결합)
class ChemicalBondingScreen extends StatefulWidget {
  const ChemicalBondingScreen({super.key});

  @override
  State<ChemicalBondingScreen> createState() => _ChemicalBondingScreenState();
}

class _ChemicalBondingScreenState extends State<ChemicalBondingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  BondType _selectedBond = BondType.ionicNaCl;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
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
              '화학 결합',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학',
          title: '화학 결합',
          formula: _selectedBond.formula,
          formulaDescription: _selectedBond.description,
          simulation: SizedBox(
            height: 350,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ChemicalBondingPainter(
                    bondType: _selectedBond,
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
              // 결합 정보
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
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedBond.isIonic
                                ? Colors.orange.withValues(alpha: 0.2)
                                : Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedBond.isIonic ? '이온 결합' : '공유 결합',
                            style: TextStyle(
                              color: _selectedBond.isIonic
                                  ? Colors.orange
                                  : Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _selectedBond.compound,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(label: '결합 에너지', value: _selectedBond.bondEnergy),
                    _DetailRow(label: '전기음성도 차이', value: _selectedBond.electronegativityDiff),
                    _DetailRow(label: '특성', value: _selectedBond.properties),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 이온 결합 예시
              const Text(
                '이온 결합',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _BondButton(
                    label: 'NaCl',
                    sublabel: '소금',
                    isSelected: _selectedBond == BondType.ionicNaCl,
                    color: Colors.orange,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedBond = BondType.ionicNaCl);
                    },
                  ),
                  const SizedBox(width: 8),
                  _BondButton(
                    label: 'MgO',
                    sublabel: '산화마그네슘',
                    isSelected: _selectedBond == BondType.ionicMgO,
                    color: Colors.orange,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedBond = BondType.ionicMgO);
                    },
                  ),
                  const SizedBox(width: 8),
                  _BondButton(
                    label: 'CaF₂',
                    sublabel: '플루오린화칼슘',
                    isSelected: _selectedBond == BondType.ionicCaF2,
                    color: Colors.orange,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedBond = BondType.ionicCaF2);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 공유 결합 예시
              const Text(
                '공유 결합',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _BondButton(
                    label: 'H₂',
                    sublabel: '수소',
                    isSelected: _selectedBond == BondType.covalentH2,
                    color: Colors.blue,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedBond = BondType.covalentH2);
                    },
                  ),
                  const SizedBox(width: 8),
                  _BondButton(
                    label: 'O₂',
                    sublabel: '산소',
                    isSelected: _selectedBond == BondType.covalentO2,
                    color: Colors.blue,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedBond = BondType.covalentO2);
                    },
                  ),
                  const SizedBox(width: 8),
                  _BondButton(
                    label: 'H₂O',
                    sublabel: '물',
                    isSelected: _selectedBond == BondType.covalentH2O,
                    color: Colors.blue,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedBond = BondType.covalentH2O);
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
                label: '이온 결합',
                icon: Icons.add_circle,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedBond = BondType.ionicNaCl);
                },
              ),
              SimButton(
                label: '공유 결합',
                icon: Icons.share,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedBond = BondType.covalentH2);
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
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.ink, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _BondButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _BondButton({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : AppColors.ink,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  color: isSelected ? color : AppColors.muted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum BondType {
  ionicNaCl(
    true,
    'NaCl',
    '염화나트륨 (소금)',
    'Na⁺ + Cl⁻ → NaCl',
    '전자 이동에 의한 정전기적 인력',
    '788 kJ/mol',
    '2.1',
    '높은 녹는점, 전해질',
  ),
  ionicMgO(
    true,
    'MgO',
    '산화마그네슘',
    'Mg²⁺ + O²⁻ → MgO',
    '2가 이온 결합, 매우 강한 결합',
    '3850 kJ/mol',
    '2.3',
    '매우 높은 녹는점',
  ),
  ionicCaF2(
    true,
    'CaF₂',
    '플루오린화칼슘',
    'Ca²⁺ + 2F⁻ → CaF₂',
    '1:2 비율의 이온 결합',
    '2630 kJ/mol',
    '3.0',
    '형석 구조',
  ),
  covalentH2(
    false,
    'H₂',
    '수소 분자',
    'H· + ·H → H:H',
    '전자쌍 공유 (단일 결합)',
    '436 kJ/mol',
    '0',
    '무극성 공유',
  ),
  covalentO2(
    false,
    'O₂',
    '산소 분자',
    ':O: + :O: → O=O',
    '전자쌍 공유 (이중 결합)',
    '498 kJ/mol',
    '0',
    '무극성, 이중결합',
  ),
  covalentH2O(
    false,
    'H₂O',
    '물',
    '2H· + :O: → H-O-H',
    '극성 공유 결합',
    '464 kJ/mol',
    '1.4',
    '극성, 수소결합 가능',
  );

  final bool isIonic;
  final String compound;
  final String name;
  final String formula;
  final String description;
  final String bondEnergy;
  final String electronegativityDiff;
  final String properties;

  const BondType(
    this.isIonic,
    this.compound,
    this.name,
    this.formula,
    this.description,
    this.bondEnergy,
    this.electronegativityDiff,
    this.properties,
  );
}

class _ChemicalBondingPainter extends CustomPainter {
  final BondType bondType;
  final double animation;

  _ChemicalBondingPainter({
    required this.bondType,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    final center = Offset(size.width / 2, size.height / 2);

    if (bondType.isIonic) {
      _drawIonicBond(canvas, size, center);
    } else {
      _drawCovalentBond(canvas, size, center);
    }
  }

  void _drawIonicBond(Canvas canvas, Size size, Offset center) {
    // 이온 결합 애니메이션: 전자 이동
    final separation = 80.0 + math.sin(animation * math.pi * 2) * 20;

    // 양이온 (오른쪽)
    final cationPos = Offset(center.dx + separation, center.dy);
    _drawAtom(canvas, cationPos, _getCation(), 35, Colors.red.shade400, '+');

    // 음이온 (왼쪽)
    final anionPos = Offset(center.dx - separation, center.dy);
    _drawAtom(canvas, anionPos, _getAnion(), 40, Colors.green.shade400, '-');

    // 정전기 인력 표시
    if (animation > 0.5) {
      final attractionPaint = Paint()
        ..color = Colors.yellow.withValues(alpha: (animation - 0.5) * 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(cationPos.dx - 30, cationPos.dy),
        Offset(anionPos.dx + 35, anionPos.dy),
        attractionPaint,
      );
    }

    // 전자 이동 화살표
    if (animation < 0.5) {
      final electronPos = Offset(
        center.dx + separation - animation * 2 * separation,
        center.dy - 50,
      );
      _drawElectron(canvas, electronPos, 6);

      // 화살표
      _drawArrow(
        canvas,
        Offset(center.dx + 60, center.dy - 50),
        Offset(center.dx - 60, center.dy - 50),
        AppColors.accent,
      );
    }

    // 라벨
    _drawText(canvas, '양이온', Offset(cationPos.dx - 20, cationPos.dy + 50), Colors.red);
    _drawText(canvas, '음이온', Offset(anionPos.dx - 20, anionPos.dy + 50), Colors.green);
    _drawText(canvas, '전자 이동', Offset(center.dx - 25, center.dy - 80), AppColors.accent);
  }

  void _drawCovalentBond(Canvas canvas, Size size, Offset center) {
    switch (bondType) {
      case BondType.covalentH2:
        _drawH2(canvas, center);
        break;
      case BondType.covalentO2:
        _drawO2(canvas, center);
        break;
      case BondType.covalentH2O:
        _drawH2O(canvas, center);
        break;
      default:
        break;
    }
  }

  void _drawH2(Canvas canvas, Offset center) {
    final separation = 50.0;
    final bondPulse = math.sin(animation * math.pi * 2) * 5;

    // 두 수소 원자
    final h1Pos = Offset(center.dx - separation / 2 - bondPulse, center.dy);
    final h2Pos = Offset(center.dx + separation / 2 + bondPulse, center.dy);

    // 공유 전자쌍 영역
    canvas.drawOval(
      Rect.fromCenter(center: center, width: separation + 30, height: 35),
      Paint()..color = AppColors.accent.withValues(alpha: 0.2),
    );

    _drawAtom(canvas, h1Pos, 'H', 25, Colors.white, null);
    _drawAtom(canvas, h2Pos, 'H', 25, Colors.white, null);

    // 공유 전자쌍
    _drawElectron(canvas, Offset(center.dx - 8, center.dy), 5);
    _drawElectron(canvas, Offset(center.dx + 8, center.dy), 5);

    _drawText(canvas, '단일 결합 (σ)', Offset(center.dx - 40, center.dy + 60), AppColors.accent);
  }

  void _drawO2(Canvas canvas, Offset center) {
    final separation = 60.0;
    final bondPulse = math.sin(animation * math.pi * 2) * 3;

    final o1Pos = Offset(center.dx - separation / 2 - bondPulse, center.dy);
    final o2Pos = Offset(center.dx + separation / 2 + bondPulse, center.dy);

    // 이중 결합 영역
    canvas.drawOval(
      Rect.fromCenter(center: center, width: separation + 40, height: 50),
      Paint()..color = Colors.red.withValues(alpha: 0.15),
    );

    _drawAtom(canvas, o1Pos, 'O', 30, Colors.red, null);
    _drawAtom(canvas, o2Pos, 'O', 30, Colors.red, null);

    // 이중 결합 선
    canvas.drawLine(
      Offset(center.dx - 15, center.dy - 8),
      Offset(center.dx + 15, center.dy - 8),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(center.dx - 15, center.dy + 8),
      Offset(center.dx + 15, center.dy + 8),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3,
    );

    // 공유 전자쌍 (4개)
    _drawElectron(canvas, Offset(center.dx - 5, center.dy - 8), 4);
    _drawElectron(canvas, Offset(center.dx + 5, center.dy - 8), 4);
    _drawElectron(canvas, Offset(center.dx - 5, center.dy + 8), 4);
    _drawElectron(canvas, Offset(center.dx + 5, center.dy + 8), 4);

    _drawText(canvas, '이중 결합 (σ + π)', Offset(center.dx - 50, center.dy + 70), AppColors.accent);
  }

  void _drawH2O(Canvas canvas, Offset center) {
    final angle = 104.5 * math.pi / 180;
    final bondLength = 55.0;

    final oPos = center;
    final h1Pos = Offset(
      center.dx - bondLength * math.sin(angle / 2),
      center.dy + bondLength * math.cos(angle / 2),
    );
    final h2Pos = Offset(
      center.dx + bondLength * math.sin(angle / 2),
      center.dy + bondLength * math.cos(angle / 2),
    );

    // 부분 전하 표시
    final pulseAlpha = 0.3 + math.sin(animation * math.pi * 2) * 0.2;

    // δ- 영역 (산소)
    canvas.drawCircle(
      oPos,
      45,
      Paint()..color = Colors.blue.withValues(alpha: pulseAlpha),
    );

    // δ+ 영역 (수소)
    canvas.drawCircle(
      h1Pos,
      30,
      Paint()..color = Colors.red.withValues(alpha: pulseAlpha * 0.7),
    );
    canvas.drawCircle(
      h2Pos,
      30,
      Paint()..color = Colors.red.withValues(alpha: pulseAlpha * 0.7),
    );

    // 결합선
    canvas.drawLine(
      oPos,
      h1Pos,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 4,
    );
    canvas.drawLine(
      oPos,
      h2Pos,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 4,
    );

    _drawAtom(canvas, oPos, 'O', 30, Colors.red, 'δ-');
    _drawAtom(canvas, h1Pos, 'H', 20, Colors.white, 'δ+');
    _drawAtom(canvas, h2Pos, 'H', 20, Colors.white, 'δ+');

    // 결합각 표시
    _drawText(canvas, '104.5°', Offset(center.dx - 20, center.dy + 25), AppColors.muted);
    _drawText(canvas, '극성 공유 결합', Offset(center.dx - 45, center.dy - 70), AppColors.accent);
  }

  void _drawAtom(Canvas canvas, Offset pos, String symbol, double radius, Color color, String? charge) {
    // 그림자
    canvas.drawCircle(
      Offset(pos.dx + 2, pos.dy + 2),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );

    // 원자
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: radius)),
    );

    // 테두리
    canvas.drawCircle(
      pos,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 기호
    final textColor = color == Colors.white ? Colors.black : Colors.white;
    _drawText(canvas, symbol, Offset(pos.dx - 8, pos.dy - 8), textColor, fontSize: 16, fontWeight: FontWeight.bold);

    // 전하
    if (charge != null) {
      _drawText(canvas, charge, Offset(pos.dx + radius - 5, pos.dy - radius - 5), AppColors.accent, fontSize: 12);
    }
  }

  void _drawElectron(Canvas canvas, Offset pos, double radius) {
    canvas.drawCircle(
      pos,
      radius,
      Paint()..color = AppColors.accent,
    );
    canvas.drawCircle(
      Offset(pos.dx - 1, pos.dy - 1),
      radius * 0.3,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);

    // 화살촉
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowSize = 10.0;

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle - math.pi / 6),
        end.dy - arrowSize * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + math.pi / 6),
        end.dy - arrowSize * math.sin(angle + math.pi / 6),
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
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

  String _getCation() {
    switch (bondType) {
      case BondType.ionicNaCl:
        return 'Na⁺';
      case BondType.ionicMgO:
        return 'Mg²⁺';
      case BondType.ionicCaF2:
        return 'Ca²⁺';
      default:
        return '';
    }
  }

  String _getAnion() {
    switch (bondType) {
      case BondType.ionicNaCl:
        return 'Cl⁻';
      case BondType.ionicMgO:
        return 'O²⁻';
      case BondType.ionicCaF2:
        return 'F⁻';
      default:
        return '';
    }
  }

  @override
  bool shouldRepaint(covariant _ChemicalBondingPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.bondType != bondType;
  }
}
