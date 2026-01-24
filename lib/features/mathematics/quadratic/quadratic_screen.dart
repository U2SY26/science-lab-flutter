import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 이차함수 꼭짓점 탐색기
class QuadraticScreen extends StatefulWidget {
  const QuadraticScreen({super.key});

  @override
  State<QuadraticScreen> createState() => _QuadraticScreenState();
}

class _QuadraticScreenState extends State<QuadraticScreen> {
  // 기본값
  static const double _defaultA = 1;
  static const double _defaultB = 0;
  static const double _defaultC = 0;

  double a = _defaultA;
  double b = _defaultB;
  double c = _defaultC;

  // 프리셋
  String? _selectedPreset;

  // 꼭짓점 계산
  double get vertexX => a != 0 ? -b / (2 * a) : 0.0;
  double get vertexY => a * vertexX * vertexX + b * vertexX + c;

  // 축 방정식
  String get axisEquation => 'x = ${vertexX.toStringAsFixed(2)}';

  // 판별식
  double get discriminant => b * b - 4 * a * c;

  // x절편
  List<double>? get xIntercepts {
    if (discriminant < 0) return null;
    if (discriminant == 0) return [-b / (2 * a)];
    final sqrtD = discriminant >= 0 ? discriminant.sqrt() : 0.0;
    return [
      (-b + sqrtD) / (2 * a),
      (-b - sqrtD) / (2 * a),
    ];
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;

      switch (preset) {
        case 'standard':
          a = 1;
          b = 0;
          c = 0;
          break;
        case 'shifted':
          a = 1;
          b = -4;
          c = 3;
          break;
        case 'inverted':
          a = -1;
          b = 0;
          c = 4;
          break;
        case 'narrow':
          a = 3;
          b = 0;
          c = -2;
          break;
        case 'wide':
          a = 0.5;
          b = 0;
          c = 1;
          break;
        case 'no_roots':
          a = 1;
          b = 0;
          c = 2;
          break;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      a = _defaultA;
      b = _defaultB;
      c = _defaultC;
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
          onPressed: () => context.go('/home'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '고등 수학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '이차함수 꼭짓점',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '고등 수학',
          title: '이차함수 꼭짓점',
          formula: 'y = ${a.toStringAsFixed(1)}x² ${b >= 0 ? '+' : ''}${b.toStringAsFixed(1)}x ${c >= 0 ? '+' : ''}${c.toStringAsFixed(1)}',
          formulaDescription: '포물선의 특성 탐구 - 꼭짓점, 축, 절편',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: QuadraticPainter(
                a: a,
                b: b,
                c: c,
                xIntercepts: xIntercepts,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋
              PresetGroup(
                label: '대표 함수',
                presets: [
                  PresetButton(
                    label: '표준형',
                    isSelected: _selectedPreset == 'standard',
                    onPressed: () => _applyPreset('standard'),
                  ),
                  PresetButton(
                    label: '이동',
                    isSelected: _selectedPreset == 'shifted',
                    onPressed: () => _applyPreset('shifted'),
                  ),
                  PresetButton(
                    label: '뒤집힘',
                    isSelected: _selectedPreset == 'inverted',
                    onPressed: () => _applyPreset('inverted'),
                  ),
                  PresetButton(
                    label: '좁은 폭',
                    isSelected: _selectedPreset == 'narrow',
                    onPressed: () => _applyPreset('narrow'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 정보 표시
              _QuadraticInfo(
                vertexX: vertexX,
                vertexY: vertexY,
                a: a,
                c: c,
                discriminant: discriminant,
                xIntercepts: xIntercepts,
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: 'a (곡률) - ${a > 0 ? "아래로 볼록" : a < 0 ? "위로 볼록" : "직선"}',
                  value: a,
                  min: -3,
                  max: 3,
                  defaultValue: _defaultA,
                  formatValue: (v) => v.toStringAsFixed(1),
                  onChanged: (v) => setState(() {
                    a = v == 0 ? 0.1 : v;
                    _selectedPreset = null;
                  }),
                ),
                advancedControls: [
                  SimSlider(
                    label: 'b (x계수)',
                    value: b,
                    min: -5,
                    max: 5,
                    defaultValue: _defaultB,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() {
                      b = v;
                      _selectedPreset = null;
                    }),
                  ),
                  SimSlider(
                    label: 'c (y절편)',
                    value: c,
                    min: -5,
                    max: 5,
                    defaultValue: _defaultC,
                    formatValue: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() {
                      c = v;
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
                label: '기본값',
                icon: Icons.restart_alt,
                isPrimary: true,
                onPressed: _reset,
              ),
              SimButton(
                label: '뒤집기',
                icon: Icons.flip,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    a = -a;
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

/// 이차함수 정보 위젯
class _QuadraticInfo extends StatelessWidget {
  final double vertexX;
  final double vertexY;
  final double a;
  final double c;
  final double discriminant;
  final List<double>? xIntercepts;

  const _QuadraticInfo({
    required this.vertexX,
    required this.vertexY,
    required this.a,
    required this.c,
    required this.discriminant,
    required this.xIntercepts,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  label: '꼭짓점',
                  value: '(${vertexX.toStringAsFixed(2)}, ${vertexY.toStringAsFixed(2)})',
                  icon: Icons.gps_fixed,
                ),
              ),
              Expanded(
                child: _InfoRow(
                  label: '축',
                  value: 'x = ${vertexX.toStringAsFixed(2)}',
                  icon: Icons.vertical_align_center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  label: '개형',
                  value: a > 0 ? '∪ (아래 볼록)' : '∩ (위로 볼록)',
                  icon: a > 0 ? Icons.expand_more : Icons.expand_less,
                ),
              ),
              Expanded(
                child: _InfoRow(
                  label: 'y절편',
                  value: '(0, ${c.toStringAsFixed(1)})',
                  icon: Icons.adjust,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.cardBorder, height: 16),
          _InfoRow(
            label: '판별식 D',
            value: '${discriminant.toStringAsFixed(2)} → ${_getDiscriminantMeaning()}',
            icon: Icons.calculate,
          ),
          if (xIntercepts != null) ...[
            const SizedBox(height: 4),
            _InfoRow(
              label: 'x절편',
              value: xIntercepts!.length == 1
                  ? '(${xIntercepts![0].toStringAsFixed(2)}, 0) - 중근'
                  : '(${xIntercepts![0].toStringAsFixed(2)}, 0), (${xIntercepts![1].toStringAsFixed(2)}, 0)',
              icon: Icons.linear_scale,
            ),
          ],
        ],
      ),
    );
  }

  String _getDiscriminantMeaning() {
    if (discriminant > 0) return '서로 다른 두 실근';
    if (discriminant == 0) return '중근 (한 점에서 접함)';
    return '실근 없음';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class QuadraticPainter extends CustomPainter {
  final double a;
  final double b;
  final double c;
  final List<double>? xIntercepts;

  QuadraticPainter({
    required this.a,
    required this.b,
    required this.c,
    required this.xIntercepts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    // 그리드
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = -5; i <= 5; i++) {
      final x = centerX + i * graphWidth / 10;
      final y = centerY - i * graphHeight / 10;
      canvas.drawLine(Offset(x, padding), Offset(x, size.height - padding), gridPaint);
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
    }

    // 축
    final axisPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(padding, centerY), Offset(size.width - padding, centerY), axisPaint);
    canvas.drawLine(Offset(centerX, padding), Offset(centerX, size.height - padding), axisPaint);

    // 좌표 변환
    double toScreenX(double x) => centerX + x * graphWidth / 10;
    double toScreenY(double y) => centerY - y * graphHeight / 10;

    // 대칭축 (점선)
    final vertexX = a != 0 ? -b / (2 * a) : 0.0;
    final axisX = toScreenX(vertexX);
    final dashPaint = Paint()
      ..color = AppColors.accent2.withValues(alpha: 0.6)
      ..strokeWidth = 2;

    for (double y = padding; y < size.height - padding; y += 10) {
      canvas.drawLine(
        Offset(axisX, y),
        Offset(axisX, y + 5),
        dashPaint,
      );
    }

    // 포물선 그리기 (글로우 효과)
    final glowPath = Path();
    final mainPath = Path();
    bool started = false;

    for (double x = -6; x <= 6; x += 0.1) {
      final y = a * x * x + b * x + c;
      final screenX = toScreenX(x);
      final screenY = toScreenY(y);

      if (screenY > padding && screenY < size.height - padding) {
        if (!started) {
          glowPath.moveTo(screenX, screenY);
          mainPath.moveTo(screenX, screenY);
          started = true;
        } else {
          glowPath.lineTo(screenX, screenY);
          mainPath.lineTo(screenX, screenY);
        }
      }
    }

    // 글로우
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 메인 곡선
    canvas.drawPath(
      mainPath,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // 꼭짓점 표시 (글로우)
    final vY = a * vertexX * vertexX + b * vertexX + c;
    final screenVertexX = toScreenX(vertexX);
    final screenVertexY = toScreenY(vY);

    canvas.drawCircle(
      Offset(screenVertexX, screenVertexY),
      12,
      Paint()..color = AppColors.accent2.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      Offset(screenVertexX, screenVertexY),
      8,
      Paint()..color = AppColors.accent2,
    );
    canvas.drawCircle(
      Offset(screenVertexX, screenVertexY),
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // y절편 표시
    final yIntercept = toScreenY(c);
    if (yIntercept > padding && yIntercept < size.height - padding) {
      canvas.drawCircle(
        Offset(centerX, yIntercept),
        6,
        Paint()..color = Colors.green,
      );
    }

    // x절편 표시
    if (xIntercepts != null) {
      for (final xi in xIntercepts!) {
        final xScreen = toScreenX(xi);
        if (xScreen > padding && xScreen < size.width - padding) {
          canvas.drawCircle(
            Offset(xScreen, centerY),
            6,
            Paint()..color = Colors.orange,
          );
        }
      }
    }

    // 축 레이블
    _drawText(canvas, 'x', Offset(size.width - padding + 5, centerY - 10));
    _drawText(canvas, 'y', Offset(centerX + 5, padding - 15));
    _drawText(canvas, 'O', Offset(centerX + 5, centerY + 5));
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant QuadraticPainter oldDelegate) =>
      a != oldDelegate.a || b != oldDelegate.b || c != oldDelegate.c;
}

extension DoubleExt on double {
  double sqrt() => this >= 0 ? math.sqrt(this) : 0.0;
}
