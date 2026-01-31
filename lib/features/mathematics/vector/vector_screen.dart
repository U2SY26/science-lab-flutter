import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 벡터 내적 탐색기 화면
class VectorScreen extends StatefulWidget {
  const VectorScreen({super.key});

  @override
  State<VectorScreen> createState() => _VectorScreenState();
}

class _VectorScreenState extends State<VectorScreen> {
  // 벡터 A
  double _ax = 3;
  double _ay = 2;

  // 벡터 B
  double _bx = 2;
  double _by = 3;

  // 프리셋
  String? _selectedPreset;

  // 계산된 값
  double get _dotProduct => _ax * _bx + _ay * _by;
  double get _magA => math.sqrt(_ax * _ax + _ay * _ay);
  double get _magB => math.sqrt(_bx * _bx + _by * _by);
  double get _angle {
    if (_magA == 0 || _magB == 0) return 0;
    final cosTheta = _dotProduct / (_magA * _magB);
    return math.acos(cosTheta.clamp(-1.0, 1.0)) * 180 / math.pi;
  }

  // A를 B에 투영한 벡터의 크기
  double get _projectionScalar {
    if (_magB == 0) return 0;
    return _dotProduct / _magB;
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'perpendicular':
          _ax = 3;
          _ay = 0;
          _bx = 0;
          _by = 3;
          break;
        case 'parallel':
          _ax = 3;
          _ay = 2;
          _bx = 6;
          _by = 4;
          break;
        case 'opposite':
          _ax = 3;
          _ay = 2;
          _bx = -3;
          _by = -2;
          break;
        case 'acute':
          _ax = 4;
          _ay = 1;
          _bx = 2;
          _by = 3;
          break;
        case 'obtuse':
          _ax = 3;
          _ay = 1;
          _bx = -2;
          _by = 3;
          break;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _ax = 3;
      _ay = 2;
      _bx = 2;
      _by = 3;
      _selectedPreset = null;
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
              '선형대수학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '벡터 내적',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '선형대수학',
          title: '벡터 내적',
          formula: 'A·B = |A||B|cosθ = AxBx + AyBy',
          formulaDescription: '두 벡터의 내적과 사잇각 관계',
          simulation: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _bx = (_bx + details.delta.dx * 0.05).clamp(-5.0, 5.0);
                _by = (_by - details.delta.dy * 0.05).clamp(-5.0, 5.0);
                _selectedPreset = null;
              });
            },
            child: SizedBox(
              height: 300,
              child: CustomPaint(
                painter: VectorPainter(
                  ax: _ax,
                  ay: _ay,
                  bx: _bx,
                  by: _by,
                  projectionScalar: _projectionScalar,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋
              PresetGroup(
                label: '벡터 관계',
                presets: [
                  PresetButton(
                    label: '직교',
                    isSelected: _selectedPreset == 'perpendicular',
                    onPressed: () => _applyPreset('perpendicular'),
                  ),
                  PresetButton(
                    label: '평행',
                    isSelected: _selectedPreset == 'parallel',
                    onPressed: () => _applyPreset('parallel'),
                  ),
                  PresetButton(
                    label: '반대',
                    isSelected: _selectedPreset == 'opposite',
                    onPressed: () => _applyPreset('opposite'),
                  ),
                  PresetButton(
                    label: '예각',
                    isSelected: _selectedPreset == 'acute',
                    onPressed: () => _applyPreset('acute'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 벡터 정보
              _VectorInfo(
                ax: _ax,
                ay: _ay,
                bx: _bx,
                by: _by,
                dotProduct: _dotProduct,
                magA: _magA,
                magB: _magB,
                angle: _angle,
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: 'A의 x 성분',
                  value: _ax,
                  min: -5,
                  max: 5,
                  defaultValue: 3,
                  formatValue: (v) => v.toStringAsFixed(1),
                  onChanged: (v) => setState(() {
                    _ax = v;
                    _selectedPreset = null;
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: 'A의 y 성분',
                    value: _ay,
                    min: -5,
                    max: 5,
                    defaultValue: 2,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() {
                      _ay = v;
                      _selectedPreset = null;
                    }),
                  ),
                  SimSlider(
                    label: 'B의 x 성분',
                    value: _bx,
                    min: -5,
                    max: 5,
                    defaultValue: 2,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() {
                      _bx = v;
                      _selectedPreset = null;
                    }),
                  ),
                  SimSlider(
                    label: 'B의 y 성분',
                    value: _by,
                    min: -5,
                    max: 5,
                    defaultValue: 3,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() {
                      _by = v;
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
                label: '초기화',
                icon: Icons.refresh,
                isPrimary: true,
                onPressed: _reset,
              ),
              SimButton(
                label: '스왑',
                icon: Icons.swap_horiz,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    final tx = _ax, ty = _ay;
                    _ax = _bx;
                    _ay = _by;
                    _bx = tx;
                    _by = ty;
                    _selectedPreset = null;
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

/// 벡터 정보 위젯
class _VectorInfo extends StatelessWidget {
  final double ax, ay, bx, by;
  final double dotProduct, magA, magB, angle;

  const _VectorInfo({
    required this.ax,
    required this.ay,
    required this.bx,
    required this.by,
    required this.dotProduct,
    required this.magA,
    required this.magB,
    required this.angle,
  });

  String _getAngleType() {
    if (angle < 1) return '평행 (0°)';
    if (angle > 179) return '반대 (180°)';
    if ((angle - 90).abs() < 1) return '직교 (90°)';
    if (angle < 90) return '예각';
    return '둔각';
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: 'A',
                  value: '(${ax.toStringAsFixed(1)}, ${ay.toStringAsFixed(1)})',
                  icon: Icons.arrow_forward,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: 'B',
                  value: '(${bx.toStringAsFixed(1)}, ${by.toStringAsFixed(1)})',
                  icon: Icons.arrow_forward,
                  color: AppColors.accent2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: '|A|',
                  value: magA.toStringAsFixed(2),
                  icon: Icons.straighten,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: '|B|',
                  value: magB.toStringAsFixed(2),
                  icon: Icons.straighten,
                  color: AppColors.accent2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: 'A·B',
                  value: dotProduct.toStringAsFixed(2),
                  icon: Icons.close,
                  color: dotProduct > 0
                      ? Colors.green
                      : dotProduct < 0
                          ? Colors.red
                          : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: 'θ',
                  value: '${angle.toStringAsFixed(1)}°',
                  icon: Icons.rotate_right,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: '관계',
                  value: _getAngleType(),
                  icon: Icons.compare_arrows,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 벡터 페인터
class VectorPainter extends CustomPainter {
  final double ax, ay, bx, by;
  final double projectionScalar;

  VectorPainter({
    required this.ax,
    required this.ay,
    required this.bx,
    required this.by,
    required this.projectionScalar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 12;

    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // 그리드
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = -5; i <= 5; i++) {
      final x = centerX + i * scale;
      final y = centerY - i * scale;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 축
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);

    // 투영 벡터 (점선)
    if (bx != 0 || by != 0) {
      final magB = math.sqrt(bx * bx + by * by);
      final unitBx = bx / magB;
      final unitBy = by / magB;
      final projX = projectionScalar * unitBx;
      final projY = projectionScalar * unitBy;

      final projEndX = centerX + projX * scale;
      final projEndY = centerY - projY * scale;

      // 투영 벡터
      _drawDashedLine(
        canvas,
        Offset(centerX, centerY),
        Offset(projEndX, projEndY),
        Paint()
          ..color = Colors.green.withValues(alpha: 0.6)
          ..strokeWidth = 2,
      );

      // A에서 투영점으로의 수직선
      final endAx = centerX + ax * scale;
      final endAy = centerY - ay * scale;
      _drawDashedLine(
        canvas,
        Offset(endAx, endAy),
        Offset(projEndX, projEndY),
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.4)
          ..strokeWidth = 1,
      );
    }

    // 사잇각 호
    _drawAngleArc(canvas, centerX, centerY, scale);

    // 벡터 A (글로우)
    _drawVector(canvas, centerX, centerY, ax * scale, -ay * scale, AppColors.accent, 'A');

    // 벡터 B (글로우)
    _drawVector(canvas, centerX, centerY, bx * scale, -by * scale, AppColors.accent2, 'B');

    // 원점
    canvas.drawCircle(
      Offset(centerX, centerY),
      4,
      Paint()..color = Colors.white,
    );
  }

  void _drawVector(Canvas canvas, double cx, double cy, double dx, double dy, Color color, String label) {
    final endX = cx + dx;
    final endY = cy + dy;

    // 글로우
    canvas.drawLine(
      Offset(cx, cy),
      Offset(endX, endY),
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 메인 라인
    canvas.drawLine(
      Offset(cx, cy),
      Offset(endX, endY),
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // 화살표 머리
    final angle = math.atan2(dy, dx);
    final arrowSize = 12.0;
    final arrowAngle = math.pi / 6;

    final arrow1X = endX - arrowSize * math.cos(angle - arrowAngle);
    final arrow1Y = endY - arrowSize * math.sin(angle - arrowAngle);
    final arrow2X = endX - arrowSize * math.cos(angle + arrowAngle);
    final arrow2Y = endY - arrowSize * math.sin(angle + arrowAngle);

    final arrowPath = Path()
      ..moveTo(endX, endY)
      ..lineTo(arrow1X, arrow1Y)
      ..lineTo(arrow2X, arrow2Y)
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = color);

    // 레이블
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(endX + 5, endY - 20));
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final dashLength = 5.0;
    final dashCount = (length / (dashLength * 2)).floor();

    for (int i = 0; i < dashCount; i++) {
      final startFraction = i * 2 * dashLength / length;
      final endFraction = (i * 2 + 1) * dashLength / length;
      canvas.drawLine(
        Offset(start.dx + dx * startFraction, start.dy + dy * startFraction),
        Offset(start.dx + dx * endFraction, start.dy + dy * endFraction),
        paint,
      );
    }
  }

  void _drawAngleArc(Canvas canvas, double cx, double cy, double scale) {
    final angleA = math.atan2(-ay, ax);
    final angleB = math.atan2(-by, bx);

    final arcRadius = 30.0;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: arcRadius),
      angleA,
      angleB - angleA,
      false,
      Paint()
        ..color = Colors.orange.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant VectorPainter oldDelegate) =>
      ax != oldDelegate.ax ||
      ay != oldDelegate.ay ||
      bx != oldDelegate.bx ||
      by != oldDelegate.by;
}
