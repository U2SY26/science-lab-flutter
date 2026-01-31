import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 분자 기하학 시뮬레이션 (VSEPR 이론)
class MolecularGeometryScreen extends StatefulWidget {
  const MolecularGeometryScreen({super.key});

  @override
  State<MolecularGeometryScreen> createState() => _MolecularGeometryScreenState();
}

class _MolecularGeometryScreenState extends State<MolecularGeometryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  MoleculeType _selectedMolecule = MoleculeType.methane;
  double _rotationX = 0.3;
  double _rotationY = 0.5;
  Offset? _lastPanPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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
              '분자 기하학',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학',
          title: '분자 기하학 (VSEPR)',
          formula: _selectedMolecule.formula,
          formulaDescription: '전자쌍 반발 이론에 따른 분자 구조 시각화',
          simulation: GestureDetector(
            onPanStart: (details) {
              _lastPanPosition = details.localPosition;
            },
            onPanUpdate: (details) {
              setState(() {
                if (_lastPanPosition != null) {
                  _rotationY += (details.localPosition.dx - _lastPanPosition!.dx) * 0.01;
                  _rotationX += (details.localPosition.dy - _lastPanPosition!.dy) * 0.01;
                }
                _lastPanPosition = details.localPosition;
              });
            },
            child: SizedBox(
              height: 350,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MolecularGeometryPainter(
                      molecule: _selectedMolecule,
                      rotationX: _rotationX,
                      rotationY: _rotationY + _controller.value * 0.5,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
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
                          _selectedMolecule.name,
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
                            _selectedMolecule.formula,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(label: '기하 구조', value: _selectedMolecule.geometry),
                    _DetailRow(label: '결합각', value: _selectedMolecule.bondAngle),
                    _DetailRow(label: '혼성화', value: _selectedMolecule.hybridization),
                    _DetailRow(label: '극성', value: _selectedMolecule.polarity),
                  ],
                ),
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
                children: MoleculeType.values.map((molecule) {
                  final isSelected = _selectedMolecule == molecule;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMolecule = molecule);
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
                      child: Column(
                        children: [
                          Text(
                            molecule.formula,
                            style: TextStyle(
                              color: isSelected ? AppColors.accent : AppColors.ink,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            molecule.geometry,
                            style: TextStyle(
                              color: isSelected ? AppColors.accent : AppColors.muted,
                              fontSize: 9,
                            ),
                          ),
                        ],
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
                label: '정면',
                icon: Icons.crop_portrait,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _rotationX = 0;
                    _rotationY = 0;
                  });
                },
              ),
              SimButton(
                label: '측면',
                icon: Icons.view_in_ar,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _rotationX = 0.3;
                    _rotationY = 0.5;
                  });
                },
              ),
              SimButton(
                label: '위에서',
                icon: Icons.arrow_downward,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _rotationX = math.pi / 2;
                    _rotationY = 0;
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
            width: 70,
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

/// 분자 타입
enum MoleculeType {
  methane('메테인', 'CH₄', '정사면체', '109.5°', 'sp³', '무극성'),
  ammonia('암모니아', 'NH₃', '삼각 피라미드', '107°', 'sp³', '극성'),
  water('물', 'H₂O', '굽은형', '104.5°', 'sp³', '극성'),
  carbonDioxide('이산화탄소', 'CO₂', '선형', '180°', 'sp', '무극성'),
  boronTrifluoride('삼플루오린화붕소', 'BF₃', '평면 삼각형', '120°', 'sp²', '무극성'),
  sulfurHexafluoride('육플루오린화황', 'SF₆', '정팔면체', '90°', 'sp³d²', '무극성');

  final String name;
  final String formula;
  final String geometry;
  final String bondAngle;
  final String hybridization;
  final String polarity;

  const MoleculeType(this.name, this.formula, this.geometry, this.bondAngle, this.hybridization, this.polarity);

  List<Atom> get atoms {
    switch (this) {
      case MoleculeType.methane:
        // CH4 - 정사면체
        return [
          Atom(0, 0, 0, 'C', Colors.grey),
          Atom(1, 1, 1, 'H', Colors.white),
          Atom(-1, -1, 1, 'H', Colors.white),
          Atom(-1, 1, -1, 'H', Colors.white),
          Atom(1, -1, -1, 'H', Colors.white),
        ];
      case MoleculeType.ammonia:
        // NH3 - 삼각 피라미드
        return [
          Atom(0, 0.3, 0, 'N', Colors.blue),
          Atom(0.94, -0.3, 0, 'H', Colors.white),
          Atom(-0.47, -0.3, 0.82, 'H', Colors.white),
          Atom(-0.47, -0.3, -0.82, 'H', Colors.white),
        ];
      case MoleculeType.water:
        // H2O - 굽은형
        return [
          Atom(0, 0, 0, 'O', Colors.red),
          Atom(0.96, 0, 0, 'H', Colors.white),
          Atom(-0.24, 0.93, 0, 'H', Colors.white),
        ];
      case MoleculeType.carbonDioxide:
        // CO2 - 선형
        return [
          Atom(0, 0, 0, 'C', Colors.grey),
          Atom(-1.2, 0, 0, 'O', Colors.red),
          Atom(1.2, 0, 0, 'O', Colors.red),
        ];
      case MoleculeType.boronTrifluoride:
        // BF3 - 평면 삼각형
        return [
          Atom(0, 0, 0, 'B', Colors.pink),
          Atom(1.3, 0, 0, 'F', Colors.green),
          Atom(-0.65, 1.13, 0, 'F', Colors.green),
          Atom(-0.65, -1.13, 0, 'F', Colors.green),
        ];
      case MoleculeType.sulfurHexafluoride:
        // SF6 - 정팔면체
        return [
          Atom(0, 0, 0, 'S', Colors.yellow),
          Atom(1.5, 0, 0, 'F', Colors.green),
          Atom(-1.5, 0, 0, 'F', Colors.green),
          Atom(0, 1.5, 0, 'F', Colors.green),
          Atom(0, -1.5, 0, 'F', Colors.green),
          Atom(0, 0, 1.5, 'F', Colors.green),
          Atom(0, 0, -1.5, 'F', Colors.green),
        ];
    }
  }

  List<List<int>> get bonds {
    switch (this) {
      case MoleculeType.methane:
        return [[0, 1], [0, 2], [0, 3], [0, 4]];
      case MoleculeType.ammonia:
        return [[0, 1], [0, 2], [0, 3]];
      case MoleculeType.water:
        return [[0, 1], [0, 2]];
      case MoleculeType.carbonDioxide:
        return [[0, 1], [0, 2]];
      case MoleculeType.boronTrifluoride:
        return [[0, 1], [0, 2], [0, 3]];
      case MoleculeType.sulfurHexafluoride:
        return [[0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6]];
    }
  }
}

class Atom {
  final double x, y, z;
  final String symbol;
  final Color color;

  Atom(this.x, this.y, this.z, this.symbol, this.color);
}

class _MolecularGeometryPainter extends CustomPainter {
  final MoleculeType molecule;
  final double rotationX;
  final double rotationY;

  _MolecularGeometryPainter({
    required this.molecule,
    required this.rotationX,
    required this.rotationY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) / 5;

    // 회전 행렬 적용
    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX);
    final cosY = math.cos(rotationY);
    final sinY = math.sin(rotationY);

    List<_ProjectedAtom> projectedAtoms = [];

    for (final atom in molecule.atoms) {
      // Y축 회전
      final x1 = atom.x * cosY - atom.z * sinY;
      final z1 = atom.x * sinY + atom.z * cosY;

      // X축 회전
      final y1 = atom.y * cosX - z1 * sinX;
      final z2 = atom.y * sinX + z1 * cosX;

      final screenX = center.dx + x1 * scale;
      final screenY = center.dy - y1 * scale;

      projectedAtoms.add(_ProjectedAtom(
        screenX: screenX,
        screenY: screenY,
        z: z2,
        symbol: atom.symbol,
        color: atom.color,
      ));
    }

    // Z 정렬 (뒤에서 앞으로)
    final sortedIndices = List.generate(projectedAtoms.length, (i) => i);
    sortedIndices.sort((a, b) => projectedAtoms[a].z.compareTo(projectedAtoms[b].z));

    // 결합 그리기
    for (final bond in molecule.bonds) {
      final atom1 = projectedAtoms[bond[0]];
      final atom2 = projectedAtoms[bond[1]];

      // 결합 선
      final gradient = LinearGradient(
        colors: [atom1.color, atom2.color],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromPoints(
            Offset(atom1.screenX, atom1.screenY),
            Offset(atom2.screenX, atom2.screenY),
          ),
        )
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(atom1.screenX, atom1.screenY),
        Offset(atom2.screenX, atom2.screenY),
        paint,
      );
    }

    // 원자 그리기 (Z 순서로)
    for (final idx in sortedIndices.reversed) {
      final atom = projectedAtoms[idx];
      final atomRadius = atom.symbol == 'H' ? 18.0 : 25.0;
      final depthFactor = (atom.z + 2) / 4;

      // 그림자
      canvas.drawCircle(
        Offset(atom.screenX + 3, atom.screenY + 3),
        atomRadius,
        Paint()..color = Colors.black.withValues(alpha: 0.2 * depthFactor),
      );

      // 원자 구체
      final atomPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            atom.color.withValues(alpha: 0.3 + 0.7 * depthFactor),
            atom.color.withValues(alpha: 0.6 + 0.4 * depthFactor),
            atom.color.withValues(alpha: 0.2 + 0.3 * depthFactor),
          ],
          stops: const [0, 0.5, 1],
        ).createShader(
          Rect.fromCircle(
            center: Offset(atom.screenX, atom.screenY),
            radius: atomRadius,
          ),
        );

      canvas.drawCircle(
        Offset(atom.screenX, atom.screenY),
        atomRadius,
        atomPaint,
      );

      // 하이라이트
      canvas.drawCircle(
        Offset(atom.screenX - atomRadius * 0.3, atom.screenY - atomRadius * 0.3),
        atomRadius * 0.2,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );

      // 원소 기호
      final textPainter = TextPainter(
        text: TextSpan(
          text: atom.symbol,
          style: TextStyle(
            color: atom.symbol == 'H' ? Colors.black87 : Colors.white,
            fontSize: atom.symbol == 'H' ? 12 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(atom.screenX - textPainter.width / 2, atom.screenY - textPainter.height / 2),
      );
    }

    // 드래그 안내
    _drawText(
      canvas,
      '드래그하여 회전',
      Offset(size.width / 2 - 45, size.height - 25),
      AppColors.muted.withValues(alpha: 0.5),
      11,
    );
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
  bool shouldRepaint(covariant _MolecularGeometryPainter oldDelegate) {
    return oldDelegate.molecule != molecule ||
           oldDelegate.rotationX != rotationX ||
           oldDelegate.rotationY != rotationY;
  }
}

class _ProjectedAtom {
  final double screenX, screenY, z;
  final String symbol;
  final Color color;

  _ProjectedAtom({
    required this.screenX,
    required this.screenY,
    required this.z,
    required this.symbol,
    required this.color,
  });
}
