import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 파스칼 삼각형 시뮬레이션
class PascalTriangleScreen extends StatefulWidget {
  const PascalTriangleScreen({super.key});

  @override
  State<PascalTriangleScreen> createState() => _PascalTriangleScreenState();
}

class _PascalTriangleScreenState extends State<PascalTriangleScreen> {
  int _rows = 8;
  bool _showMultiples = false;
  int _multipleOf = 2;

  List<List<int>> _buildTriangle() {
    final triangle = <List<int>>[];

    for (int row = 0; row < _rows; row++) {
      final currentRow = <int>[];
      for (int col = 0; col <= row; col++) {
        if (col == 0 || col == row) {
          currentRow.add(1);
        } else {
          currentRow.add(triangle[row - 1][col - 1] + triangle[row - 1][col]);
        }
      }
      triangle.add(currentRow);
    }

    return triangle;
  }

  @override
  Widget build(BuildContext context) {
    final triangle = _buildTriangle();

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
              '파스칼 삼각형',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '수학',
          title: '파스칼 삼각형',
          formula: 'C(n,k) = C(n-1,k-1) + C(n-1,k)',
          formulaDescription: '이항계수, 조합, 확률과 관련된 수학적 패턴',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _PascalTrianglePainter(
                triangle: triangle,
                showMultiples: _showMultiples,
                multipleOf: _multipleOf,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 배수 하이라이트 옵션
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showMultiples = !_showMultiples);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _showMultiples ? AppColors.accent.withValues(alpha: 0.2) : AppColors.simBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _showMultiples ? AppColors.accent : AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showMultiples ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 18,
                        color: _showMultiples ? AppColors.accent : AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '배수 하이라이트',
                        style: TextStyle(
                          color: _showMultiples ? AppColors.accent : AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_showMultiples)
                PresetGroup(
                  label: '배수',
                  presets: [2, 3, 5, 7].map((n) {
                    return PresetButton(
                      label: '${n}의 배수',
                      isSelected: _multipleOf == n,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _multipleOf = n);
                      },
                    );
                  }).toList(),
                ),

              if (_showMultiples) const SizedBox(height: 16),

              // 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('파스칼 삼각형의 특징', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 4),
                    Text(
                      '• 각 수 = 위 두 수의 합\n'
                      '• n행의 합 = 2ⁿ\n'
                      '• 대각선: 자연수, 삼각수, 피보나치\n'
                      '• 2의 배수: 시어핀스키 삼각형',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '행 개수',
                  value: _rows.toDouble(),
                  min: 4,
                  max: 15,
                  defaultValue: 8,
                  formatValue: (v) => '${v.toInt()}행',
                  onChanged: (v) => setState(() => _rows = v.toInt()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PascalTrianglePainter extends CustomPainter {
  final List<List<int>> triangle;
  final bool showMultiples;
  final int multipleOf;

  _PascalTrianglePainter({
    required this.triangle,
    required this.showMultiples,
    required this.multipleOf,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (triangle.isEmpty) return;

    final padding = 20.0;
    final availableWidth = size.width - padding * 2;
    final availableHeight = size.height - padding * 2;
    final cellSize = (availableWidth / triangle.length).clamp(20.0, 40.0);
    final verticalSpacing = (availableHeight / triangle.length).clamp(20.0, 40.0);

    for (int row = 0; row < triangle.length; row++) {
      final rowWidth = triangle[row].length * cellSize;
      final startX = (size.width - rowWidth) / 2;

      for (int col = 0; col < triangle[row].length; col++) {
        final value = triangle[row][col];
        final x = startX + col * cellSize + cellSize / 2;
        final y = padding + row * verticalSpacing + verticalSpacing / 2;

        Color bgColor = AppColors.card;
        Color textColor = AppColors.ink;

        if (showMultiples) {
          if (value % multipleOf == 0) {
            bgColor = AppColors.accent;
            textColor = Colors.white;
          } else {
            bgColor = AppColors.card;
            textColor = AppColors.muted;
          }
        }

        // 육각형 또는 원
        canvas.drawCircle(
          Offset(x, y),
          cellSize / 2 - 2,
          Paint()..color = bgColor,
        );

        canvas.drawCircle(
          Offset(x, y),
          cellSize / 2 - 2,
          Paint()
            ..color = AppColors.cardBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );

        // 숫자
        final fontSize = value > 999 ? 8.0 : (value > 99 ? 10.0 : 12.0);
        _drawText(canvas, '$value', Offset(x, y), textColor, fontSize: fontSize);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PascalTrianglePainter oldDelegate) => true;
}
