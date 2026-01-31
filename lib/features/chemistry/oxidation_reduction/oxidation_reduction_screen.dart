import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 산화-환원 반응 시뮬레이션
class OxidationReductionScreen extends StatefulWidget {
  const OxidationReductionScreen({super.key});

  @override
  State<OxidationReductionScreen> createState() => _OxidationReductionScreenState();
}

class _OxidationReductionScreenState extends State<OxidationReductionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  RedoxExample _selectedExample = RedoxExample.zincCopper;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        if (_controller.isCompleted) {
          setState(() => _isAnimating = false);
        }
      });
  }

  void _startAnimation() {
    HapticFeedback.mediumImpact();
    setState(() => _isAnimating = true);
    _controller.forward(from: 0);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.reset();
    setState(() => _isAnimating = false);
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
              '산화-환원 반응',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '화학',
          title: '산화-환원 반응',
          formula: _selectedExample.equation,
          formulaDescription: '전자의 이동에 의한 산화수 변화',
          simulation: SizedBox(
            height: 380,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RedoxPainter(
                    example: _selectedExample,
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
              // 반응 정보
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
                    Text(
                      _selectedExample.name,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _RedoxBox(
                            title: '산화 (Oxidation)',
                            species: _selectedExample.oxidized,
                            change: _selectedExample.oxidationChange,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _RedoxBox(
                            title: '환원 (Reduction)',
                            species: _selectedExample.reduced,
                            change: _selectedExample.reductionChange,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 4),
                    _DetailRow(
                      label: '기억법',
                      value: 'OIL RIG: Oxidation Is Loss, Reduction Is Gain',
                    ),
                    _DetailRow(
                      label: '전자 이동',
                      value: '${_selectedExample.oxidized} → ${_selectedExample.reduced}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 예시 선택
              PresetGroup(
                label: '반응 예시',
                presets: RedoxExample.values.map((ex) => PresetButton(
                  label: ex.shortName,
                  isSelected: _selectedExample == ex,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _reset();
                    setState(() => _selectedExample = ex);
                  },
                )).toList(),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isAnimating ? '진행 중...' : '반응 시작',
                icon: _isAnimating ? Icons.hourglass_empty : Icons.play_arrow,
                isPrimary: true,
                onPressed: _isAnimating ? null : _startAnimation,
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedoxBox extends StatelessWidget {
  final String title;
  final String species;
  final String change;
  final Color color;

  const _RedoxBox({
    required this.title,
    required this.species,
    required this.change,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            species,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            change,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

enum RedoxExample {
  zincCopper(
    'Zn-Cu',
    '아연-구리 전지',
    'Zn + Cu²⁺ → Zn²⁺ + Cu',
    'Zn',
    'Cu²⁺',
    '0 → +2 (전자 잃음)',
    '+2 → 0 (전자 얻음)',
  ),
  rustFormation(
    '녹 생성',
    '철의 산화 (녹)',
    '4Fe + 3O₂ → 2Fe₂O₃',
    'Fe',
    'O₂',
    '0 → +3 (전자 잃음)',
    '0 → -2 (전자 얻음)',
  ),
  combustion(
    '연소',
    '메탄 연소',
    'CH₄ + 2O₂ → CO₂ + 2H₂O',
    'C (in CH₄)',
    'O₂',
    '-4 → +4 (전자 잃음)',
    '0 → -2 (전자 얻음)',
  ),
  photosynthesis(
    '광합성',
    '광합성',
    '6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂',
    'O (in H₂O)',
    'C (in CO₂)',
    '-2 → 0 (전자 잃음)',
    '+4 → 0 (전자 얻음)',
  );

  final String shortName;
  final String name;
  final String equation;
  final String oxidized;
  final String reduced;
  final String oxidationChange;
  final String reductionChange;

  const RedoxExample(
    this.shortName,
    this.name,
    this.equation,
    this.oxidized,
    this.reduced,
    this.oxidationChange,
    this.reductionChange,
  );
}

class _RedoxPainter extends CustomPainter {
  final RedoxExample example;
  final double animation;

  _RedoxPainter({
    required this.example,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    switch (example) {
      case RedoxExample.zincCopper:
        _drawGalvanicCell(canvas, size);
        break;
      case RedoxExample.rustFormation:
        _drawRustFormation(canvas, size);
        break;
      case RedoxExample.combustion:
        _drawCombustion(canvas, size);
        break;
      case RedoxExample.photosynthesis:
        _drawPhotosynthesis(canvas, size);
        break;
    }
  }

  void _drawGalvanicCell(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 용기
    final leftBeaker = Rect.fromLTWH(30, centerY - 60, 120, 140);
    final rightBeaker = Rect.fromLTWH(size.width - 150, centerY - 60, 120, 140);

    // 용액
    canvas.drawRect(
      Rect.fromLTWH(35, centerY - 20, 110, 95),
      Paint()..color = Colors.blue.withValues(alpha: 0.3),
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - 145, centerY - 20, 110, 95),
      Paint()..color = Colors.cyan.withValues(alpha: 0.3),
    );

    // 비커 외곽
    canvas.drawRect(
      leftBeaker,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRect(
      rightBeaker,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 전극
    final znElectrode = Rect.fromLTWH(70, centerY - 50, 30, 100);
    final cuElectrode = Rect.fromLTWH(size.width - 110, centerY - 50, 30, 100);

    canvas.drawRect(znElectrode, Paint()..color = Colors.grey);
    canvas.drawRect(cuElectrode, Paint()..color = Colors.orange.shade700);

    // 전극 라벨
    _drawText(canvas, 'Zn', Offset(78, centerY - 70), Colors.grey.shade300, fontSize: 14, fontWeight: FontWeight.bold);
    _drawText(canvas, 'Cu', Offset(size.width - 103, centerY - 70), Colors.orange, fontSize: 14, fontWeight: FontWeight.bold);

    // 염다리
    final bridgeY = centerY - 80;
    canvas.drawPath(
      Path()
        ..moveTo(90, bridgeY)
        ..quadraticBezierTo(centerX, bridgeY - 40, size.width - 90, bridgeY),
      Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 15
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    _drawText(canvas, '염다리', Offset(centerX - 20, bridgeY - 60), AppColors.muted, fontSize: 11);

    // 전선
    canvas.drawPath(
      Path()
        ..moveTo(85, centerY - 50)
        ..lineTo(85, centerY - 100)
        ..lineTo(size.width - 95, centerY - 100)
        ..lineTo(size.width - 95, centerY - 50),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // 전자 이동 애니메이션
    if (animation > 0) {
      final electronCount = 5;
      for (int i = 0; i < electronCount; i++) {
        final progress = (animation + i / electronCount) % 1.0;

        // 상단 전선을 따라 이동
        double electronX;
        if (progress < 0.3) {
          // 좌측 상승
          electronX = 85;
        } else if (progress < 0.7) {
          // 상단 이동
          final t = (progress - 0.3) / 0.4;
          electronX = 85 + t * (size.width - 180);
        } else {
          // 우측 하강
          electronX = size.width - 95;
        }

        final electronY = progress < 0.3
            ? centerY - 50 - progress / 0.3 * 50
            : progress > 0.7
                ? centerY - 100 + (progress - 0.7) / 0.3 * 50
                : centerY - 100;

        _drawElectron(canvas, Offset(electronX, electronY));
      }
    }

    // 이온 표시
    _drawText(canvas, 'Zn²⁺', Offset(50, centerY + 30), Colors.blue, fontSize: 12);
    _drawText(canvas, 'SO₄²⁻', Offset(100, centerY + 50), AppColors.muted, fontSize: 10);
    _drawText(canvas, 'Cu²⁺', Offset(size.width - 130, centerY + 30), Colors.cyan, fontSize: 12);
    _drawText(canvas, 'SO₄²⁻', Offset(size.width - 80, centerY + 50), AppColors.muted, fontSize: 10);

    // 반응 설명
    _drawText(canvas, '산화: Zn → Zn²⁺ + 2e⁻', Offset(20, size.height - 50), Colors.red, fontSize: 11);
    _drawText(canvas, '환원: Cu²⁺ + 2e⁻ → Cu', Offset(size.width - 150, size.height - 50), Colors.blue, fontSize: 11);

    // e⁻ 이동 방향 화살표
    _drawArrow(canvas, Offset(centerX - 50, centerY - 100), Offset(centerX + 50, centerY - 100), Colors.yellow);
    _drawText(canvas, 'e⁻', Offset(centerX - 8, centerY - 120), Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold);
  }

  void _drawRustFormation(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 철 조각
    final ironRect = Rect.fromCenter(center: Offset(centerX, centerY), width: 120, height: 80);
    canvas.drawRRect(
      RRect.fromRectAndRadius(ironRect, const Radius.circular(8)),
      Paint()..color = Colors.grey.shade600,
    );
    _drawText(canvas, 'Fe', Offset(centerX - 12, centerY - 10), Colors.white, fontSize: 18, fontWeight: FontWeight.bold);

    // 산소 분자들
    final random = math.Random(42);
    for (int i = 0; i < 6; i++) {
      final startX = 50 + random.nextDouble() * (size.width - 100);
      final startY = 30 + random.nextDouble() * 60;

      final progress = (animation * 2 + i * 0.15) % 1.0;
      final x = startX + (centerX - startX) * progress * 0.5;
      final y = startY + (centerY - 50 - startY) * progress * 0.5;

      if (progress < 0.8) {
        canvas.drawCircle(Offset(x, y), 12, Paint()..color = Colors.red.withValues(alpha: 0.7));
        canvas.drawCircle(Offset(x + 15, y), 12, Paint()..color = Colors.red.withValues(alpha: 0.7));
        _drawText(canvas, 'O₂', Offset(x - 5, y + 15), Colors.red, fontSize: 10);
      }
    }

    // 녹 생성 (애니메이션)
    if (animation > 0.3) {
      final rustAlpha = ((animation - 0.3) / 0.7).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(ironRect.inflate(-10), const Radius.circular(4)),
        Paint()..color = Colors.orange.shade800.withValues(alpha: rustAlpha * 0.8),
      );

      if (rustAlpha > 0.5) {
        _drawText(canvas, 'Fe₂O₃', Offset(centerX - 20, centerY - 10), Colors.orange.shade200, fontSize: 14, fontWeight: FontWeight.bold);
      }
    }

    // 반응식
    _drawText(canvas, '4Fe + 3O₂ → 2Fe₂O₃', Offset(centerX - 60, size.height - 40), AppColors.ink, fontSize: 12);
    _drawText(canvas, '산화: Fe⁰ → Fe³⁺ (전자 잃음)', Offset(20, size.height - 70), Colors.red, fontSize: 11);
    _drawText(canvas, '환원: O₂ → O²⁻ (전자 얻음)', Offset(20, size.height - 55), Colors.blue, fontSize: 11);
  }

  void _drawCombustion(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 메탄 분자
    final ch4Pos = Offset(centerX - 80, centerY);
    _drawMethane(canvas, ch4Pos, 1.0 - animation.clamp(0, 0.5) * 2);

    // 산소 분자들
    for (int i = 0; i < 2; i++) {
      final o2Pos = Offset(centerX + 60 + i * 30, centerY - 30 + i * 60);
      if (animation < 0.5) {
        _drawO2(canvas, o2Pos);
      }
    }

    // 반응 진행 중
    if (animation > 0.3 && animation < 0.7) {
      // 불꽃 효과
      final flameColors = [Colors.yellow, Colors.orange, Colors.red];
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4 + animation * math.pi * 2;
        final dist = 30 + math.sin(animation * math.pi * 4 + i) * 10;
        final flamePos = Offset(
          centerX + math.cos(angle) * dist,
          centerY + math.sin(angle) * dist,
        );
        canvas.drawCircle(
          flamePos,
          8 + math.sin(animation * math.pi * 6 + i) * 4,
          Paint()..color = flameColors[i % 3].withValues(alpha: 0.6),
        );
      }
    }

    // 생성물
    if (animation > 0.5) {
      final productAlpha = ((animation - 0.5) * 2).clamp(0.0, 1.0);

      // CO2
      _drawCO2(canvas, Offset(centerX - 50, centerY - 60), productAlpha);

      // H2O
      _drawH2O(canvas, Offset(centerX + 50, centerY + 60), productAlpha);
      _drawH2O(canvas, Offset(centerX + 80, centerY + 30), productAlpha);
    }

    // 반응식
    _drawText(canvas, 'CH₄ + 2O₂ → CO₂ + 2H₂O + 열', Offset(centerX - 85, size.height - 40), AppColors.ink, fontSize: 12);
  }

  void _drawPhotosynthesis(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 태양광
    final sunY = 40.0;
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 + animation * math.pi / 2;
      final rayLength = 20 + math.sin(animation * math.pi * 2 + i) * 5;
      canvas.drawLine(
        Offset(60 + math.cos(angle) * 15, sunY + math.sin(angle) * 15),
        Offset(60 + math.cos(angle) * rayLength, sunY + math.sin(angle) * rayLength),
        Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2,
      );
    }
    canvas.drawCircle(Offset(60, sunY), 15, Paint()..color = Colors.yellow);

    // 광선 (잎으로)
    if (animation > 0) {
      final rayProgress = animation.clamp(0.0, 0.5) * 2;
      canvas.drawLine(
        Offset(60, sunY + 15),
        Offset(60 + (centerX - 80 - 60) * rayProgress, sunY + 15 + (centerY - 40 - sunY - 15) * rayProgress),
        Paint()
          ..color = Colors.yellow.withValues(alpha: 0.6)
          ..strokeWidth = 3,
      );
    }

    // 잎 (엽록체)
    final leafPath = Path();
    leafPath.moveTo(centerX - 80, centerY);
    leafPath.quadraticBezierTo(centerX - 40, centerY - 60, centerX + 40, centerY - 40);
    leafPath.quadraticBezierTo(centerX + 80, centerY - 20, centerX + 40, centerY + 20);
    leafPath.quadraticBezierTo(centerX, centerY + 40, centerX - 40, centerY + 20);
    leafPath.quadraticBezierTo(centerX - 80, centerY, centerX - 80, centerY);
    leafPath.close();

    canvas.drawPath(leafPath, Paint()..color = Colors.green.shade600);
    canvas.drawPath(
      leafPath,
      Paint()
        ..color = Colors.green.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // CO2 입력
    if (animation < 0.7) {
      final co2Alpha = 1.0 - animation / 0.7;
      _drawCO2(canvas, Offset(30, centerY + 80), co2Alpha);
      _drawArrow(canvas, Offset(60, centerY + 70), Offset(centerX - 60, centerY + 20), Colors.grey.withValues(alpha: co2Alpha));
    }

    // H2O 입력
    if (animation < 0.7) {
      final h2oAlpha = 1.0 - animation / 0.7;
      _drawH2O(canvas, Offset(size.width - 80, centerY + 80), h2oAlpha);
      _drawArrow(canvas, Offset(size.width - 60, centerY + 70), Offset(centerX + 60, centerY + 20), Colors.blue.withValues(alpha: h2oAlpha));
    }

    // O2 출력
    if (animation > 0.5) {
      final o2Alpha = (animation - 0.5) * 2;
      _drawO2(canvas, Offset(centerX + 100, centerY - 60), alpha: o2Alpha);
      _drawArrow(canvas, Offset(centerX + 40, centerY - 30), Offset(centerX + 90, centerY - 50), Colors.red.withValues(alpha: o2Alpha));
    }

    // 포도당 출력
    if (animation > 0.7) {
      final glucoseAlpha = (animation - 0.7) / 0.3;
      _drawText(canvas, 'C₆H₁₂O₆', Offset(centerX - 30, centerY + 70), Colors.brown.withValues(alpha: glucoseAlpha), fontSize: 14, fontWeight: FontWeight.bold);
    }

    // 반응식
    _drawText(canvas, '6CO₂ + 6H₂O + 빛 → C₆H₁₂O₆ + 6O₂', Offset(centerX - 100, size.height - 40), AppColors.ink, fontSize: 11);
  }

  void _drawElectron(Canvas canvas, Offset pos) {
    canvas.drawCircle(pos, 6, Paint()..color = Colors.yellow.withValues(alpha: 0.4));
    canvas.drawCircle(pos, 4, Paint()..color = Colors.yellow);
    _drawText(canvas, 'e⁻', Offset(pos.dx - 6, pos.dy - 15), Colors.yellow, fontSize: 9);
  }

  void _drawMethane(Canvas canvas, Offset center, double alpha) {
    if (alpha <= 0) return;
    canvas.drawCircle(center, 20, Paint()..color = Colors.grey.withValues(alpha: alpha));
    _drawText(canvas, 'CH₄', Offset(center.dx - 15, center.dy - 8), Colors.white.withValues(alpha: alpha), fontSize: 14, fontWeight: FontWeight.bold);
  }

  void _drawO2(Canvas canvas, Offset center, {double alpha = 1.0}) {
    canvas.drawCircle(Offset(center.dx - 8, center.dy), 12, Paint()..color = Colors.red.withValues(alpha: alpha * 0.8));
    canvas.drawCircle(Offset(center.dx + 8, center.dy), 12, Paint()..color = Colors.red.withValues(alpha: alpha * 0.8));
    _drawText(canvas, 'O₂', Offset(center.dx - 10, center.dy + 15), Colors.red.withValues(alpha: alpha), fontSize: 10);
  }

  void _drawCO2(Canvas canvas, Offset center, double alpha) {
    if (alpha <= 0) return;
    canvas.drawCircle(center, 14, Paint()..color = Colors.grey.withValues(alpha: alpha * 0.7));
    canvas.drawCircle(Offset(center.dx - 18, center.dy), 10, Paint()..color = Colors.red.withValues(alpha: alpha * 0.7));
    canvas.drawCircle(Offset(center.dx + 18, center.dy), 10, Paint()..color = Colors.red.withValues(alpha: alpha * 0.7));
    _drawText(canvas, 'CO₂', Offset(center.dx - 12, center.dy + 18), Colors.grey.withValues(alpha: alpha), fontSize: 10);
  }

  void _drawH2O(Canvas canvas, Offset center, double alpha) {
    if (alpha <= 0) return;
    canvas.drawCircle(center, 12, Paint()..color = Colors.red.withValues(alpha: alpha * 0.7));
    canvas.drawCircle(Offset(center.dx - 15, center.dy + 8), 8, Paint()..color = Colors.blue.shade200.withValues(alpha: alpha * 0.7));
    canvas.drawCircle(Offset(center.dx + 15, center.dy + 8), 8, Paint()..color = Colors.blue.shade200.withValues(alpha: alpha * 0.7));
    _drawText(canvas, 'H₂O', Offset(center.dx - 12, center.dy + 20), Colors.blue.withValues(alpha: alpha), fontSize: 10);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    canvas.drawLine(start, end, paint);

    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowSize = 8.0;

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

  @override
  bool shouldRepaint(covariant _RedoxPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.example != example;
  }
}
