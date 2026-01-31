import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 스넬의 법칙 시뮬레이션
class SnellScreen extends StatefulWidget {
  const SnellScreen({super.key});

  @override
  State<SnellScreen> createState() => _SnellScreenState();
}

class _SnellScreenState extends State<SnellScreen> {
  double _incidentAngle = 45; // 입사각 (도)
  double _n1 = 1.0; // 매질 1 굴절률 (공기)
  double _n2 = 1.5; // 매질 2 굴절률 (유리)

  // 굴절각 계산
  double get _refractedAngle {
    final sinTheta2 = _n1 * math.sin(_incidentAngle * math.pi / 180) / _n2;
    if (sinTheta2.abs() > 1) return double.nan; // 전반사
    return math.asin(sinTheta2) * 180 / math.pi;
  }

  // 임계각 계산
  double? get _criticalAngle {
    if (_n1 <= _n2) return null;
    return math.asin(_n2 / _n1) * 180 / math.pi;
  }

  bool get _isTotalReflection => _refractedAngle.isNaN;

  static const Map<String, double> _materials = {
    '공기': 1.0,
    '물': 1.33,
    '유리': 1.5,
    '다이아몬드': 2.42,
    '아크릴': 1.49,
    '에탄올': 1.36,
  };

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
              "스넬의 법칙",
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: "스넬의 법칙",
          formula: 'n₁sinθ₁ = n₂sinθ₂',
          formulaDescription: '빛이 다른 매질로 입사할 때의 굴절 법칙',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _SnellPainter(
                incidentAngle: _incidentAngle,
                refractedAngle: _refractedAngle,
                n1: _n1,
                n2: _n2,
                isTotalReflection: _isTotalReflection,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 각도 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isTotalReflection
                      ? Colors.red.withValues(alpha: 0.1)
                      : AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isTotalReflection
                        ? Colors.red.withValues(alpha: 0.5)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _AngleBox(
                          label: '입사각 θ₁',
                          angle: _incidentAngle,
                          color: Colors.yellow,
                        ),
                        _AngleBox(
                          label: '굴절각 θ₂',
                          angle: _isTotalReflection ? double.nan : _refractedAngle,
                          color: Colors.cyan,
                        ),
                      ],
                    ),
                    if (_isTotalReflection) ...[
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '전반사 발생!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_criticalAngle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '임계각: ${_criticalAngle!.toStringAsFixed(1)}°',
                        style: const TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 매질 선택
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '매질 1 (위)',
                          style: TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        _MaterialSelector(
                          value: _n1,
                          materials: _materials,
                          onChanged: (v) => setState(() => _n1 = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '매질 2 (아래)',
                          style: TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        _MaterialSelector(
                          value: _n2,
                          materials: _materials,
                          onChanged: (v) => setState(() => _n2 = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 입사각 슬라이더
              ControlGroup(
                primaryControl: SimSlider(
                  label: '입사각 (θ₁)',
                  value: _incidentAngle,
                  min: 0,
                  max: 89,
                  defaultValue: 45,
                  formatValue: (v) => '${v.toInt()}°',
                  onChanged: (v) => setState(() => _incidentAngle = v),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '공기→유리',
                icon: Icons.arrow_downward,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _n1 = 1.0;
                    _n2 = 1.5;
                    _incidentAngle = 45;
                  });
                },
              ),
              SimButton(
                label: '물→공기',
                icon: Icons.arrow_upward,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _n1 = 1.33;
                    _n2 = 1.0;
                    _incidentAngle = 45;
                  });
                },
              ),
              SimButton(
                label: '전반사',
                icon: Icons.flip,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _n1 = 1.5;
                    _n2 = 1.0;
                    _incidentAngle = 60;
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

class _AngleBox extends StatelessWidget {
  final String label;
  final double angle;
  final Color color;

  const _AngleBox({
    required this.label,
    required this.angle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          angle.isNaN ? '-' : '${angle.toStringAsFixed(1)}°',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MaterialSelector extends StatelessWidget {
  final double value;
  final Map<String, double> materials;
  final ValueChanged<double> onChanged;

  const _MaterialSelector({
    required this.value,
    required this.materials,
    required this.onChanged,
  });

  String _getMaterialName() {
    for (var entry in materials.entries) {
      if ((entry.value - value).abs() < 0.01) return entry.key;
    }
    return '커스텀';
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      initialValue: value,
      onSelected: onChanged,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_getMaterialName()} (n=${value.toStringAsFixed(2)})',
              style: const TextStyle(color: AppColors.ink, fontSize: 12),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.muted),
          ],
        ),
      ),
      itemBuilder: (context) => materials.entries
          .map((e) => PopupMenuItem(
                value: e.value,
                child: Text('${e.key} (n=${e.value})'),
              ))
          .toList(),
    );
  }
}

class _SnellPainter extends CustomPainter {
  final double incidentAngle;
  final double refractedAngle;
  final double n1;
  final double n2;
  final bool isTotalReflection;

  _SnellPainter({
    required this.incidentAngle,
    required this.refractedAngle,
    required this.n1,
    required this.n2,
    required this.isTotalReflection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 매질 1 (위)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, centerY),
      Paint()..color = Colors.blue.withValues(alpha: 0.1 + (n1 - 1) * 0.2),
    );

    // 매질 2 (아래)
    canvas.drawRect(
      Rect.fromLTWH(0, centerY, size.width, centerY),
      Paint()..color = Colors.blue.withValues(alpha: 0.1 + (n2 - 1) * 0.2),
    );

    // 경계면
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 2,
    );

    // 법선
    canvas.drawLine(
      Offset(centerX, centerY - 100),
      Offset(centerX, centerY + 100),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    final rayLength = 120.0;
    final incidentRad = incidentAngle * math.pi / 180;

    // 입사광
    final incidentStart = Offset(
      centerX - rayLength * math.sin(incidentRad),
      centerY - rayLength * math.cos(incidentRad),
    );

    _drawRay(canvas, incidentStart, Offset(centerX, centerY), Colors.yellow, '입사광');

    // 반사광
    final reflectedEnd = Offset(
      centerX + rayLength * math.sin(incidentRad),
      centerY - rayLength * math.cos(incidentRad),
    );

    _drawRay(
      canvas,
      Offset(centerX, centerY),
      reflectedEnd,
      Colors.orange.withValues(alpha: isTotalReflection ? 1.0 : 0.5),
      '반사광',
    );

    // 굴절광
    if (!isTotalReflection) {
      final refractedRad = refractedAngle * math.pi / 180;
      final refractedEnd = Offset(
        centerX + rayLength * math.sin(refractedRad),
        centerY + rayLength * math.cos(refractedRad),
      );

      _drawRay(canvas, Offset(centerX, centerY), refractedEnd, Colors.cyan, '굴절광');
    }

    // 입사각 호
    _drawAngleArc(canvas, Offset(centerX, centerY), incidentAngle, true, Colors.yellow);

    // 굴절각 호
    if (!isTotalReflection) {
      _drawAngleArc(canvas, Offset(centerX, centerY), refractedAngle, false, Colors.cyan);
    }

    // 굴절률 라벨
    _drawText(canvas, 'n₁ = ${n1.toStringAsFixed(2)}', Offset(10, 20), AppColors.ink);
    _drawText(canvas, 'n₂ = ${n2.toStringAsFixed(2)}', Offset(10, centerY + 20), AppColors.ink);
    _drawText(canvas, '법선', Offset(centerX + 5, centerY - 90), AppColors.muted, fontSize: 10);
  }

  void _drawRay(Canvas canvas, Offset start, Offset end, Color color, String label) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

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

  void _drawAngleArc(Canvas canvas, Offset center, double angle, bool isAbove, Color color) {
    final radius = 30.0;
    final startAngle = isAbove ? -math.pi / 2 : math.pi / 2;
    final sweepAngle = angle * math.pi / 180 * (isAbove ? -1 : 1);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 각도 표시
    final midAngle = startAngle + sweepAngle / 2;
    final textPos = Offset(
      center.dx + (radius + 15) * math.cos(midAngle),
      center.dy + (radius + 15) * math.sin(midAngle) - 5,
    );

    _drawText(canvas, '${angle.toStringAsFixed(0)}°', textPos, color, fontSize: 10);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _SnellPainter oldDelegate) {
    return oldDelegate.incidentAngle != incidentAngle ||
           oldDelegate.n1 != n1 ||
           oldDelegate.n2 != n2;
  }
}
