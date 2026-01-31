import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 테셀레이션 시뮬레이션
class TessellationScreen extends StatefulWidget {
  const TessellationScreen({super.key});

  @override
  State<TessellationScreen> createState() => _TessellationScreenState();
}

class _TessellationScreenState extends State<TessellationScreen> {
  String _pattern = 'triangles';
  double _size = 40;
  bool _showColors = true;

  final Map<String, String> _patternNames = {
    'triangles': '정삼각형',
    'squares': '정사각형',
    'hexagons': '정육각형',
    'cairo': '카이로 타일',
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
              '수학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '테셀레이션',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '테셀레이션 (Tessellation)',
          formula: '정다각형 평면 채우기',
          formulaDescription: '틈 없이 평면을 덮는 도형 패턴',
          simulation: SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomPaint(
                painter: _TessellationPainter(
                  pattern: _pattern,
                  tileSize: _size,
                  showColors: _showColors,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 패턴 선택
              PresetGroup(
                label: '패턴',
                presets: _patternNames.keys.map((p) {
                  return PresetButton(
                    label: _patternNames[p]!,
                    isSelected: _pattern == p,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _pattern = p);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 정보
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
                      _patternNames[_pattern]!,
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPatternInfo(),
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 색상 토글
              Row(
                children: [
                  const Text('색상 표시', style: TextStyle(color: AppColors.muted)),
                  const Spacer(),
                  Switch(
                    value: _showColors,
                    onChanged: (v) => setState(() => _showColors = v),
                    activeColor: AppColors.accent,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '타일 크기',
                  value: _size,
                  min: 20,
                  max: 80,
                  defaultValue: 40,
                  formatValue: (v) => '${v.toInt()}px',
                  onChanged: (v) => setState(() => _size = v),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPatternInfo() {
    switch (_pattern) {
      case 'triangles':
        return '내각 60°, 한 점에 6개의 삼각형이 모임\n360° ÷ 60° = 6';
      case 'squares':
        return '내각 90°, 한 점에 4개의 사각형이 모임\n360° ÷ 90° = 4';
      case 'hexagons':
        return '내각 120°, 한 점에 3개의 육각형이 모임\n360° ÷ 120° = 3';
      case 'cairo':
        return '불규칙 오각형으로 이루어진 테셀레이션\n카이로 거리에서 발견되어 이름 붙여짐';
      default:
        return '';
    }
  }
}

class _TessellationPainter extends CustomPainter {
  final String pattern;
  final double tileSize;
  final bool showColors;

  _TessellationPainter({
    required this.pattern,
    required this.tileSize,
    required this.showColors,
  });

  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    switch (pattern) {
      case 'triangles':
        _drawTriangles(canvas, size);
        break;
      case 'squares':
        _drawSquares(canvas, size);
        break;
      case 'hexagons':
        _drawHexagons(canvas, size);
        break;
      case 'cairo':
        _drawCairo(canvas, size);
        break;
    }
  }

  void _drawTriangles(Canvas canvas, Size size) {
    final h = tileSize * math.sqrt(3) / 2;
    int colorIndex = 0;

    for (double y = -h; y < size.height + h; y += h) {
      final rowOffset = ((y / h).floor() % 2) * (tileSize / 2);
      for (double x = -tileSize; x < size.width + tileSize; x += tileSize) {
        // 위쪽 삼각형
        final path1 = Path()
          ..moveTo(x + rowOffset, y)
          ..lineTo(x + rowOffset + tileSize, y)
          ..lineTo(x + rowOffset + tileSize / 2, y + h)
          ..close();

        canvas.drawPath(
          path1,
          Paint()..color = showColors ? _colors[colorIndex % _colors.length].withValues(alpha: 0.6) : Colors.blue.withValues(alpha: 0.2),
        );
        canvas.drawPath(
          path1,
          Paint()
            ..color = showColors ? _colors[colorIndex % _colors.length] : Colors.blue
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
        colorIndex++;

        // 아래쪽 삼각형
        final path2 = Path()
          ..moveTo(x + rowOffset + tileSize / 2, y)
          ..lineTo(x + rowOffset + tileSize * 1.5, y)
          ..lineTo(x + rowOffset + tileSize, y + h)
          ..close();

        canvas.drawPath(
          path2,
          Paint()..color = showColors ? _colors[colorIndex % _colors.length].withValues(alpha: 0.6) : Colors.green.withValues(alpha: 0.2),
        );
        canvas.drawPath(
          path2,
          Paint()
            ..color = showColors ? _colors[colorIndex % _colors.length] : Colors.green
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
        colorIndex++;
      }
    }
  }

  void _drawSquares(Canvas canvas, Size size) {
    int colorIndex = 0;

    for (double y = 0; y < size.height; y += tileSize) {
      for (double x = 0; x < size.width; x += tileSize) {
        final rect = Rect.fromLTWH(x, y, tileSize, tileSize);

        canvas.drawRect(
          rect,
          Paint()..color = showColors ? _colors[colorIndex % _colors.length].withValues(alpha: 0.6) : Colors.blue.withValues(alpha: 0.2),
        );
        canvas.drawRect(
          rect,
          Paint()
            ..color = showColors ? _colors[colorIndex % _colors.length] : Colors.blue
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
        colorIndex++;
      }
    }
  }

  void _drawHexagons(Canvas canvas, Size size) {
    final w = tileSize;
    final h = tileSize * math.sqrt(3) / 2;
    int colorIndex = 0;

    for (double row = -1; row < size.height / (h * 2) + 1; row++) {
      for (double col = -1; col < size.width / (w * 1.5) + 1; col++) {
        final cx = col * w * 1.5 + w;
        final cy = row * h * 2 + (col.toInt() % 2 == 0 ? 0 : h) + h;

        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = math.pi / 3 * i - math.pi / 6;
          final px = cx + w / 2 * math.cos(angle);
          final py = cy + w / 2 * math.sin(angle);

          if (i == 0) {
            path.moveTo(px, py);
          } else {
            path.lineTo(px, py);
          }
        }
        path.close();

        canvas.drawPath(
          path,
          Paint()..color = showColors ? _colors[colorIndex % _colors.length].withValues(alpha: 0.6) : Colors.blue.withValues(alpha: 0.2),
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = showColors ? _colors[colorIndex % _colors.length] : Colors.blue
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
        colorIndex++;
      }
    }
  }

  void _drawCairo(Canvas canvas, Size size) {
    final s = tileSize * 0.4;
    int colorIndex = 0;

    for (double y = -tileSize; y < size.height + tileSize; y += tileSize * 0.8) {
      for (double x = -tileSize; x < size.width + tileSize; x += tileSize * 0.8) {
        // 카이로 펜타곤 패턴 (간단화된 버전)
        for (int i = 0; i < 4; i++) {
          final angle = math.pi / 2 * i;
          final cx = x + tileSize * 0.4 * math.cos(angle);
          final cy = y + tileSize * 0.4 * math.sin(angle);

          final path = Path();
          final points = <Offset>[];

          for (int j = 0; j < 5; j++) {
            final a = angle + math.pi / 2.5 * j - math.pi / 5;
            final r = j % 2 == 0 ? s : s * 0.7;
            points.add(Offset(cx + r * math.cos(a), cy + r * math.sin(a)));
          }

          path.moveTo(points[0].dx, points[0].dy);
          for (int j = 1; j < 5; j++) {
            path.lineTo(points[j].dx, points[j].dy);
          }
          path.close();

          canvas.drawPath(
            path,
            Paint()..color = showColors ? _colors[colorIndex % _colors.length].withValues(alpha: 0.6) : Colors.blue.withValues(alpha: 0.2),
          );
          canvas.drawPath(
            path,
            Paint()
              ..color = showColors ? _colors[colorIndex % _colors.length] : Colors.blue
              ..strokeWidth = 1
              ..style = PaintingStyle.stroke,
          );
          colorIndex++;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TessellationPainter oldDelegate) => true;
}
