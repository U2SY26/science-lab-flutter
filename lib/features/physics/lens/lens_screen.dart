import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 렌즈 광선 추적 시뮬레이션
class LensScreen extends StatefulWidget {
  const LensScreen({super.key});

  @override
  State<LensScreen> createState() => _LensScreenState();
}

class _LensScreenState extends State<LensScreen> {
  double _objectDistance = 150; // 물체 거리 (픽셀)
  double _objectHeight = 60; // 물체 높이
  double _focalLength = 80; // 초점 거리
  bool _isConvex = true; // 볼록/오목 렌즈

  // 렌즈 공식: 1/f = 1/do + 1/di
  double get _imageDistance {
    if (_isConvex) {
      final di = (_focalLength * _objectDistance) / (_objectDistance - _focalLength);
      return di;
    } else {
      // 오목 렌즈: f가 음수
      final f = -_focalLength;
      final di = (f * _objectDistance) / (_objectDistance - f);
      return di;
    }
  }

  // 배율: M = -di/do = hi/ho
  double get _magnification => -_imageDistance / _objectDistance;

  double get _imageHeight => _objectHeight * _magnification;

  String get _imageType {
    if (_imageDistance > 0) {
      return _magnification < 0 ? '실상 (도립)' : '실상 (정립)';
    } else {
      return '허상 (정립)';
    }
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
              '물리학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '렌즈 광선 추적',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '렌즈 광선 추적',
          formula: '1/f = 1/dₒ + 1/dᵢ',
          formulaDescription: '얇은 렌즈 공식과 광선 추적',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _LensPainter(
                objectDistance: _objectDistance,
                objectHeight: _objectHeight,
                focalLength: _focalLength,
                imageDistance: _imageDistance,
                imageHeight: _imageHeight,
                isConvex: _isConvex,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 결과 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(
                          label: '상의 거리',
                          value: '${_imageDistance.toStringAsFixed(1)} px',
                          color: _imageDistance > 0 ? Colors.green : Colors.orange,
                        ),
                        _InfoItem(
                          label: '배율',
                          value: '${_magnification.toStringAsFixed(2)}x',
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: '상의 종류',
                          value: _imageType,
                          color: _imageDistance > 0 ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isConvex ? '볼록 렌즈 (수렴)' : '오목 렌즈 (발산)',
                      style: TextStyle(
                        color: _isConvex ? Colors.blue : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 렌즈 타입 선택
              PresetGroup(
                label: '렌즈 타입',
                presets: [
                  PresetButton(
                    label: '볼록 렌즈',
                    isSelected: _isConvex,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isConvex = true);
                    },
                  ),
                  PresetButton(
                    label: '오목 렌즈',
                    isSelected: !_isConvex,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isConvex = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '물체 거리 (dₒ)',
                  value: _objectDistance,
                  min: 50,
                  max: 250,
                  defaultValue: 150,
                  formatValue: (v) => '${v.toInt()} px',
                  onChanged: (v) => setState(() => _objectDistance = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '초점 거리 (f)',
                    value: _focalLength,
                    min: 40,
                    max: 150,
                    defaultValue: 80,
                    formatValue: (v) => '${v.toInt()} px',
                    onChanged: (v) => setState(() => _focalLength = v),
                  ),
                  SimSlider(
                    label: '물체 높이',
                    value: _objectHeight,
                    min: 30,
                    max: 100,
                    defaultValue: 60,
                    formatValue: (v) => '${v.toInt()} px',
                    onChanged: (v) => setState(() => _objectHeight = v),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '2f 밖',
                icon: Icons.zoom_out,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _objectDistance = 200;
                    _isConvex = true;
                  });
                },
              ),
              SimButton(
                label: 'f와 2f 사이',
                icon: Icons.center_focus_strong,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _objectDistance = 120;
                    _isConvex = true;
                  });
                },
              ),
              SimButton(
                label: 'f 안쪽',
                icon: Icons.zoom_in,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _objectDistance = 60;
                    _isConvex = true;
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

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _LensPainter extends CustomPainter {
  final double objectDistance;
  final double objectHeight;
  final double focalLength;
  final double imageDistance;
  final double imageHeight;
  final bool isConvex;

  _LensPainter({
    required this.objectDistance,
    required this.objectHeight,
    required this.focalLength,
    required this.imageDistance,
    required this.imageHeight,
    required this.isConvex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 광축
    canvas.drawLine(
      Offset(20, centerY),
      Offset(size.width - 20, centerY),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // 렌즈
    _drawLens(canvas, Offset(centerX, centerY), isConvex);

    // 초점 표시
    final f = isConvex ? focalLength : -focalLength;
    _drawFocalPoint(canvas, Offset(centerX + f, centerY), 'F');
    _drawFocalPoint(canvas, Offset(centerX - f, centerY), 'F\'');

    // 2F 표시
    _drawFocalPoint(canvas, Offset(centerX + 2 * f, centerY), '2F', isSecondary: true);
    _drawFocalPoint(canvas, Offset(centerX - 2 * f, centerY), '2F\'', isSecondary: true);

    // 물체
    final objectX = centerX - objectDistance;
    _drawArrow(canvas, Offset(objectX, centerY), Offset(objectX, centerY - objectHeight), Colors.blue, '물체');

    // 광선 추적
    _drawRays(canvas, size, centerX, centerY, objectX);

    // 상
    if (imageDistance.isFinite && imageHeight.isFinite) {
      final imageX = centerX + imageDistance;
      final isVirtual = imageDistance < 0;
      final imageColor = isVirtual ? Colors.orange : Colors.green;

      if (isVirtual) {
        // 허상 (점선)
        _drawDashedArrow(canvas, Offset(imageX, centerY), Offset(imageX, centerY - imageHeight), imageColor);
      } else {
        _drawArrow(canvas, Offset(imageX, centerY), Offset(imageX, centerY - imageHeight), imageColor, '상');
      }
    }
  }

  void _drawLens(Canvas canvas, Offset center, bool convex) {
    final height = 140.0;
    final width = convex ? 20.0 : -15.0;

    final path = Path();

    if (convex) {
      // 볼록 렌즈
      path.moveTo(center.dx, center.dy - height / 2);
      path.quadraticBezierTo(
        center.dx + width,
        center.dy,
        center.dx,
        center.dy + height / 2,
      );
      path.quadraticBezierTo(
        center.dx - width,
        center.dy,
        center.dx,
        center.dy - height / 2,
      );
    } else {
      // 오목 렌즈
      path.moveTo(center.dx - 5, center.dy - height / 2);
      path.quadraticBezierTo(
        center.dx + width,
        center.dy,
        center.dx - 5,
        center.dy + height / 2,
      );
      path.lineTo(center.dx + 5, center.dy + height / 2);
      path.quadraticBezierTo(
        center.dx - width,
        center.dy,
        center.dx + 5,
        center.dy - height / 2,
      );
      path.close();
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.lightBlue.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.lightBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawFocalPoint(Canvas canvas, Offset pos, String label, {bool isSecondary = false}) {
    canvas.drawCircle(
      pos,
      isSecondary ? 3 : 5,
      Paint()..color = isSecondary ? AppColors.muted : Colors.orange,
    );

    _drawText(canvas, label, Offset(pos.dx - 8, pos.dy + 10), AppColors.muted, fontSize: 10);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color, String label) {
    // 몸체
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = 3,
    );

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

    // 라벨
    _drawText(canvas, label, Offset(start.dx - 15, end.dy - 15), color, fontSize: 10);
  }

  void _drawDashedArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final dashLength = 5.0;
    final gapLength = 3.0;

    double drawn = 0;
    bool drawing = true;

    while (drawn < length) {
      final startRatio = drawn / length;
      final segmentLength = drawing ? dashLength : gapLength;
      final endRatio = math.min((drawn + segmentLength) / length, 1.0);

      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + dx * startRatio, start.dy + dy * startRatio),
          Offset(start.dx + dx * endRatio, start.dy + dy * endRatio),
          Paint()
            ..color = color
            ..strokeWidth = 3,
        );
      }

      drawn += segmentLength;
      drawing = !drawing;
    }

    _drawText(canvas, '허상', Offset(start.dx - 15, end.dy - 15), color, fontSize: 10);
  }

  void _drawRays(Canvas canvas, Size size, double centerX, double centerY, double objectX) {
    final objectTop = centerY - objectHeight;
    final rayPaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 1.5;

    final f = isConvex ? focalLength : -focalLength;

    // 광선 1: 광축에 평행 → 초점 통과
    canvas.drawLine(Offset(objectX, objectTop), Offset(centerX, objectTop), rayPaint);

    if (isConvex) {
      // 볼록: 오른쪽 초점으로
      _drawRayToPoint(canvas, Offset(centerX, objectTop), Offset(centerX + f, centerY), size.width - 20, rayPaint);
    } else {
      // 오목: 왼쪽 초점에서 발산하는 것처럼
      _drawRayFromPoint(canvas, Offset(centerX, objectTop), Offset(centerX + f, centerY), rayPaint);
    }

    // 광선 2: 렌즈 중심 통과 (직진)
    final slope = objectHeight / objectDistance;
    final farX = size.width - 20;
    final farY = centerY + (farX - centerX) * slope;
    canvas.drawLine(Offset(objectX, objectTop), Offset(farX, farY), rayPaint);

    // 광선 3: 초점 통과 → 광축에 평행
    if (isConvex && objectDistance > focalLength) {
      // 왼쪽 초점을 향해
      final leftFocalX = centerX - f;
      final slopeToFocus = (centerY - objectTop) / (leftFocalX - objectX);
      final yAtLens = objectTop + slopeToFocus * (centerX - objectX);

      canvas.drawLine(Offset(objectX, objectTop), Offset(centerX, yAtLens), rayPaint);
      canvas.drawLine(Offset(centerX, yAtLens), Offset(size.width - 20, yAtLens), rayPaint);
    }
  }

  void _drawRayToPoint(Canvas canvas, Offset start, Offset focal, double endX, Paint paint) {
    final slope = (focal.dy - start.dy) / (focal.dx - start.dx);
    final endY = start.dy + slope * (endX - start.dx);
    canvas.drawLine(start, Offset(endX, endY), paint);
  }

  void _drawRayFromPoint(Canvas canvas, Offset start, Offset focal, Paint paint) {
    // 허초점에서 발산하는 것처럼 (점선으로 연장)
    final slope = (start.dy - focal.dy) / (start.dx - focal.dx);
    final endX = start.dx + 150;
    final endY = start.dy + slope * (endX - start.dx);
    canvas.drawLine(start, Offset(endX, endY), paint);
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
  bool shouldRepaint(covariant _LensPainter oldDelegate) {
    return oldDelegate.objectDistance != objectDistance ||
           oldDelegate.focalLength != focalLength ||
           oldDelegate.isConvex != isConvex;
  }
}
