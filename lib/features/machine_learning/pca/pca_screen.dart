import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// PCA (주성분 분석) 시각화 화면
class PcaScreen extends StatefulWidget {
  const PcaScreen({super.key});

  @override
  State<PcaScreen> createState() => _PcaScreenState();
}

class _PcaScreenState extends State<PcaScreen> {
  // 데이터 포인트
  List<Offset> _points = [];

  // PCA 결과
  Offset _mean = Offset.zero;
  Offset _pc1 = Offset.zero; // 첫 번째 주성분
  Offset _pc2 = Offset.zero; // 두 번째 주성분
  double _variance1 = 0;
  double _variance2 = 0;

  // 시각화 옵션
  bool _showProjection = true;
  bool _showPC2 = true;

  // 회전 각도 (데이터 생성용)
  double _angle = 30;
  double _spread = 0.5;

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  void _generateData() {
    final rand = math.Random();
    _points = [];

    // 타원형 분포 생성
    final radians = _angle * math.pi / 180;
    final cos = math.cos(radians);
    final sin = math.sin(radians);

    for (int i = 0; i < 50; i++) {
      // 기본 타원
      final x = (rand.nextDouble() - 0.5) * 0.6;
      final y = (rand.nextDouble() - 0.5) * 0.6 * _spread;

      // 회전 적용
      final rx = x * cos - y * sin;
      final ry = x * sin + y * cos;

      _points.add(Offset(0.5 + rx, 0.5 + ry));
    }

    _computePCA();
    setState(() {});
  }

  void _computePCA() {
    if (_points.isEmpty) return;

    // 1. 평균 계산
    double sumX = 0, sumY = 0;
    for (final p in _points) {
      sumX += p.dx;
      sumY += p.dy;
    }
    _mean = Offset(sumX / _points.length, sumY / _points.length);

    // 2. 공분산 행렬 계산
    double cxx = 0, cyy = 0, cxy = 0;
    for (final p in _points) {
      final dx = p.dx - _mean.dx;
      final dy = p.dy - _mean.dy;
      cxx += dx * dx;
      cyy += dy * dy;
      cxy += dx * dy;
    }
    cxx /= _points.length;
    cyy /= _points.length;
    cxy /= _points.length;

    // 3. 고유값 계산 (2x2 행렬의 해석적 해)
    final trace = cxx + cyy;
    final det = cxx * cyy - cxy * cxy;
    final discriminant = math.sqrt(trace * trace / 4 - det);

    final lambda1 = trace / 2 + discriminant;
    final lambda2 = trace / 2 - discriminant;

    _variance1 = lambda1;
    _variance2 = lambda2;

    // 4. 고유벡터 계산
    if (cxy.abs() > 0.0001) {
      _pc1 = Offset(lambda1 - cyy, cxy);
      _pc2 = Offset(lambda2 - cyy, cxy);
    } else {
      _pc1 = cxx >= cyy ? const Offset(1, 0) : const Offset(0, 1);
      _pc2 = cxx >= cyy ? const Offset(0, 1) : const Offset(1, 0);
    }

    // 정규화
    final norm1 = math.sqrt(_pc1.dx * _pc1.dx + _pc1.dy * _pc1.dy);
    final norm2 = math.sqrt(_pc2.dx * _pc2.dx + _pc2.dy * _pc2.dy);
    if (norm1 > 0) _pc1 = Offset(_pc1.dx / norm1, _pc1.dy / norm1);
    if (norm2 > 0) _pc2 = Offset(_pc2.dx / norm2, _pc2.dy / norm2);
  }

  double get _explainedVariance {
    final total = _variance1 + _variance2;
    if (total == 0) return 0;
    return _variance1 / total * 100;
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _generateData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '머신러닝',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              'PCA 주성분 분석',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '머신러닝',
          title: 'PCA 주성분 분석',
          formula: 'Cov = XᵀX/(n-1)',
          formulaDescription: '고차원 데이터의 분산을 최대화하는 방향을 찾는 차원 축소 기법',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _PcaPainter(
                points: _points,
                mean: _mean,
                pc1: _pc1,
                pc2: _pc2,
                variance1: _variance1,
                variance2: _variance2,
                showProjection: _showProjection,
                showPC2: _showPC2,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PCA 정보
              _PcaInfo(
                explainedVariance: _explainedVariance,
                variance1: _variance1,
                variance2: _variance2,
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: '데이터 회전 각도',
                  value: _angle,
                  min: 0,
                  max: 90,
                  defaultValue: 30,
                  formatValue: (v) => '${v.toInt()}°',
                  onChanged: (v) {
                    setState(() {
                      _angle = v;
                      _generateData();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              ControlGroup(
                primaryControl: SimSlider(
                  label: '데이터 퍼짐 (Y축)',
                  value: _spread,
                  min: 0.1,
                  max: 1.0,
                  defaultValue: 0.5,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) {
                    setState(() {
                      _spread = v;
                      _generateData();
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              // 옵션 토글
              Row(
                children: [
                  Expanded(
                    child: _ToggleOption(
                      label: '투영 표시',
                      value: _showProjection,
                      onChanged: (v) => setState(() => _showProjection = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToggleOption(
                      label: 'PC2 표시',
                      value: _showPC2,
                      onChanged: (v) => setState(() => _showPC2 = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '새 데이터',
                icon: Icons.refresh,
                isPrimary: true,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleOption({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? AppColors.accent.withValues(alpha: 0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? AppColors.accent : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: value ? AppColors.accent : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? AppColors.accent : AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PcaInfo extends StatelessWidget {
  final double explainedVariance;
  final double variance1;
  final double variance2;

  const _PcaInfo({
    required this.explainedVariance,
    required this.variance1,
    required this.variance2,
  });

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
          // 설명된 분산 바
          Row(
            children: [
              Text(
                'PC1 설명 분산:',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: explainedVariance / 100,
                    backgroundColor: AppColors.muted.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${explainedVariance.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoChip(
                label: 'λ₁ (PC1)',
                value: variance1.toStringAsFixed(4),
                color: AppColors.accent,
              ),
              _InfoChip(
                label: 'λ₂ (PC2)',
                value: variance2.toStringAsFixed(4),
                color: AppColors.accent2,
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
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _PcaPainter extends CustomPainter {
  final List<Offset> points;
  final Offset mean;
  final Offset pc1, pc2;
  final double variance1, variance2;
  final bool showProjection;
  final bool showPC2;

  _PcaPainter({
    required this.points,
    required this.mean,
    required this.pc1,
    required this.pc2,
    required this.variance1,
    required this.variance2,
    required this.showProjection,
    required this.showPC2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 20.0;
    final plotWidth = size.width - padding * 2;
    final plotHeight = size.height - padding * 2;

    Offset toScreen(Offset p) {
      return Offset(
        padding + p.dx * plotWidth,
        padding + (1 - p.dy) * plotHeight,
      );
    }

    final meanScreen = toScreen(mean);

    // 주성분 축 그리기
    final scale1 = math.sqrt(variance1) * 3;
    final scale2 = math.sqrt(variance2) * 3;

    // PC1 (첫 번째 주성분)
    final pc1End1 = toScreen(Offset(
      mean.dx + pc1.dx * scale1,
      mean.dy + pc1.dy * scale1,
    ));
    final pc1End2 = toScreen(Offset(
      mean.dx - pc1.dx * scale1,
      mean.dy - pc1.dy * scale1,
    ));

    canvas.drawLine(
      pc1End1,
      pc1End2,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // PC1 화살표
    _drawArrow(canvas, meanScreen, pc1End1, AppColors.accent);

    // PC2 (두 번째 주성분)
    if (showPC2) {
      final pc2End1 = toScreen(Offset(
        mean.dx + pc2.dx * scale2,
        mean.dy + pc2.dy * scale2,
      ));
      final pc2End2 = toScreen(Offset(
        mean.dx - pc2.dx * scale2,
        mean.dy - pc2.dy * scale2,
      ));

      canvas.drawLine(
        pc2End1,
        pc2End2,
        Paint()
          ..color = AppColors.accent2
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

      _drawArrow(canvas, meanScreen, pc2End1, AppColors.accent2);
    }

    // 데이터 포인트와 투영 그리기
    for (final point in points) {
      final screenPoint = toScreen(point);

      // PC1으로의 투영
      if (showProjection) {
        final dx = point.dx - mean.dx;
        final dy = point.dy - mean.dy;
        final proj = dx * pc1.dx + dy * pc1.dy;
        final projPoint = Offset(
          mean.dx + proj * pc1.dx,
          mean.dy + proj * pc1.dy,
        );
        final projScreen = toScreen(projPoint);

        // 투영선
        canvas.drawLine(
          screenPoint,
          projScreen,
          Paint()
            ..color = AppColors.muted.withValues(alpha: 0.3)
            ..strokeWidth = 1,
        );

        // 투영점
        canvas.drawCircle(
          projScreen,
          3,
          Paint()..color = AppColors.accent.withValues(alpha: 0.5),
        );
      }

      // 원본 포인트
      canvas.drawCircle(screenPoint, 5, Paint()..color = AppColors.ink);
      canvas.drawCircle(
        screenPoint,
        5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // 평균점
    canvas.drawCircle(
      meanScreen,
      8,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(meanScreen, 6, Paint()..color = Colors.white);

    // 레이블
    _drawLabel(canvas, pc1End1, 'PC1', AppColors.accent);
    if (showPC2) {
      final pc2End1 = toScreen(Offset(
        mean.dx + pc2.dx * scale2,
        mean.dy + pc2.dy * scale2,
      ));
      _drawLabel(canvas, pc2End1, 'PC2', AppColors.accent2);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowSize = 10.0;

    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(
        to.dx - arrowSize * math.cos(angle - 0.4),
        to.dy - arrowSize * math.sin(angle - 0.4),
      )
      ..lineTo(
        to.dx - arrowSize * math.cos(angle + 0.4),
        to.dy - arrowSize * math.sin(angle + 0.4),
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawLabel(Canvas canvas, Offset pos, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(pos.dx + 8, pos.dy - 6));
  }

  @override
  bool shouldRepaint(covariant _PcaPainter oldDelegate) => true;
}
