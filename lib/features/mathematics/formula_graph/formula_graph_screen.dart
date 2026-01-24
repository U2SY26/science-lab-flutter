import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:math_expressions/math_expressions.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 함수 카테고리 열거형
enum FunctionCategory {
  trigonometric('삼각함수', Icons.waves),
  polynomial('다항함수', Icons.show_chart),
  exponential('지수/로그', Icons.trending_up),
  special('특수함수', Icons.auto_awesome);

  final String label;
  final IconData icon;
  const FunctionCategory(this.label, this.icon);
}

/// 수식 그래프 화면
class FormulaGraphScreen extends StatefulWidget {
  const FormulaGraphScreen({super.key});

  @override
  State<FormulaGraphScreen> createState() => _FormulaGraphScreenState();
}

class _FormulaGraphScreenState extends State<FormulaGraphScreen> {
  final TextEditingController _formulaController =
      TextEditingController(text: 'sin(x)');
  String _currentFormula = 'sin(x)';
  String? _error;
  double _xMin = -10;
  double _xMax = 10;
  double _scale = 1.0;
  FunctionCategory _selectedCategory = FunctionCategory.trigonometric;

  // 카테고리별 프리셋
  final Map<FunctionCategory, List<Map<String, String>>> _presetsByCategory = {
    FunctionCategory.trigonometric: [
      {'name': 'sin(x)', 'formula': 'sin(x)', 'desc': '사인 함수'},
      {'name': 'cos(x)', 'formula': 'cos(x)', 'desc': '코사인 함수'},
      {'name': 'tan(x)', 'formula': 'tan(x)', 'desc': '탄젠트 함수'},
      {'name': 'sin(2x)', 'formula': 'sin(2*x)', 'desc': '주기 π'},
    ],
    FunctionCategory.polynomial: [
      {'name': 'x²', 'formula': 'x^2', 'desc': '포물선'},
      {'name': 'x³', 'formula': 'x^3', 'desc': '삼차함수'},
      {'name': 'x⁴-x²', 'formula': 'x^4-x^2', 'desc': 'W자 곡선'},
      {'name': '|x|', 'formula': 'abs(x)', 'desc': '절대값'},
    ],
    FunctionCategory.exponential: [
      {'name': 'eˣ', 'formula': 'e^x', 'desc': '자연지수'},
      {'name': 'e⁻ˣ', 'formula': 'e^(-x)', 'desc': '감쇠'},
      {'name': 'ln(x)', 'formula': 'ln(x)', 'desc': '자연로그'},
      {'name': '2ˣ', 'formula': '2^x', 'desc': '밑이 2인 지수'},
    ],
    FunctionCategory.special: [
      {'name': '1/x', 'formula': '1/x', 'desc': '쌍곡선'},
      {'name': '√x', 'formula': 'sqrt(x)', 'desc': '제곱근'},
      {'name': 'sin/cos', 'formula': 'sin(x)*cos(x)', 'desc': '합성'},
      {'name': 'Gaussian', 'formula': 'e^(-(x^2))', 'desc': '정규분포'},
    ],
  };

  double? _evaluate(double x) {
    try {
      final parser = Parser();
      final exp = parser.parse(_currentFormula);
      final cm = ContextModel();
      cm.bindVariable(Variable('x'), Number(x));
      final result = exp.evaluate(EvaluationType.REAL, cm);
      if (result is num && result.isFinite) {
        return result.toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _updateFormula(String formula) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentFormula = formula;
      _formulaController.text = formula;
      _error = null;
      try {
        final parser = Parser();
        parser.parse(formula);
      } catch (e) {
        _error = '수식 오류';
      }
    });
  }

  void _zoomIn() {
    HapticFeedback.lightImpact();
    setState(() {
      _scale = (_scale * 1.5).clamp(0.5, 5.0);
      final center = (_xMin + _xMax) / 2;
      final range = (_xMax - _xMin) / 1.5;
      _xMin = center - range / 2;
      _xMax = center + range / 2;
    });
  }

  void _zoomOut() {
    HapticFeedback.lightImpact();
    setState(() {
      _scale = (_scale / 1.5).clamp(0.5, 5.0);
      final center = (_xMin + _xMax) / 2;
      final range = (_xMax - _xMin) * 1.5;
      _xMin = center - range / 2;
      _xMax = center + range / 2;
    });
  }

  void _resetView() {
    HapticFeedback.mediumImpact();
    setState(() {
      _xMin = -10;
      _xMax = 10;
      _scale = 1.0;
    });
  }

  @override
  void dispose() {
    _formulaController.dispose();
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
              '수식 그래프',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: _zoomIn,
            tooltip: '확대',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _zoomOut,
            tooltip: '축소',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '고등 수학',
          title: '수식 그래프',
          formula: 'y = $_currentFormula',
          formulaDescription: '다양한 함수의 그래프를 시각화',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: GraphPainter(
                evaluate: _evaluate,
                xMin: _xMin,
                xMax: _xMax,
                formula: _currentFormula,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 수식 입력
              _FormulaInput(
                controller: _formulaController,
                error: _error,
                onSubmitted: _updateFormula,
              ),
              const SizedBox(height: 16),
              // 카테고리 선택
              PresetGroup(
                label: '함수 유형',
                presets: FunctionCategory.values.map((cat) => PresetButton(
                  label: cat.label,
                  isSelected: _selectedCategory == cat,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = cat);
                  },
                )).toList(),
              ),
              const SizedBox(height: 12),
              // 선택된 카테고리의 프리셋
              _FunctionPresets(
                presets: _presetsByCategory[_selectedCategory]!,
                currentFormula: _currentFormula,
                onSelect: _updateFormula,
              ),
              const SizedBox(height: 16),
              // 함수 정보
              _FunctionInfo(
                formula: _currentFormula,
                xMin: _xMin,
                xMax: _xMax,
                evaluate: _evaluate,
              ),
              const SizedBox(height: 16),
              // 범위 설정
              ControlGroup(
                primaryControl: _RangeControl(
                  xMin: _xMin,
                  xMax: _xMax,
                  onMinChanged: (v) => setState(() => _xMin = v),
                  onMaxChanged: (v) => setState(() => _xMax = v),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '초기화',
                icon: Icons.restart_alt,
                isPrimary: true,
                onPressed: _resetView,
              ),
              SimButton(
                label: '전체보기',
                icon: Icons.fit_screen,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _xMin = -10;
                    _xMax = 10;
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

/// 수식 입력 위젯
class _FormulaInput extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final Function(String) onSubmitted;

  const _FormulaInput({
    required this.controller,
    required this.error,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.simBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: error != null ? Colors.red.withValues(alpha: 0.5) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          const Text(
            'y = ',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: AppColors.accent,
                fontFamily: 'monospace',
                fontSize: 16,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                hintText: '수식을 입력하세요',
                hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.5)),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: AppColors.accent),
            onPressed: () => onSubmitted(controller.text),
          ),
        ],
      ),
    );
  }
}

/// 함수 프리셋 위젯
class _FunctionPresets extends StatelessWidget {
  final List<Map<String, String>> presets;
  final String currentFormula;
  final Function(String) onSelect;

  const _FunctionPresets({
    required this.presets,
    required this.currentFormula,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: presets.map((preset) {
        final isActive = currentFormula == preset['formula'];
        return Tooltip(
          message: preset['desc']!,
          child: GestureDetector(
            onTap: () => onSelect(preset['formula']!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : AppColors.simBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.accent : AppColors.cardBorder,
                ),
              ),
              child: Text(
                preset['name']!,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 함수 정보 위젯
class _FunctionInfo extends StatelessWidget {
  final String formula;
  final double xMin;
  final double xMax;
  final double? Function(double) evaluate;

  const _FunctionInfo({
    required this.formula,
    required this.xMin,
    required this.xMax,
    required this.evaluate,
  });

  @override
  Widget build(BuildContext context) {
    // 최대/최소값 계산
    double? yMin, yMax;
    double? yAtZero = evaluate(0);

    for (double x = xMin; x <= xMax; x += (xMax - xMin) / 100) {
      final y = evaluate(x);
      if (y != null) {
        if (yMin == null || y < yMin) yMin = y;
        if (yMax == null || y > yMax) yMax = y;
      }
    }

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
              const Icon(Icons.analytics, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              const Text(
                '함수 분석',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: '정의역',
                  value: '[$xMin, $xMax]',
                  icon: Icons.straighten,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: 'f(0)',
                  value: yAtZero?.toStringAsFixed(2) ?? 'N/A',
                  icon: Icons.gps_fixed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: '최소값',
                  value: yMin?.toStringAsFixed(2) ?? 'N/A',
                  icon: Icons.arrow_downward,
                  color: AppColors.accent2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: '최대값',
                  value: yMax?.toStringAsFixed(2) ?? 'N/A',
                  icon: Icons.arrow_upward,
                  color: AppColors.accent,
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
  final Color? color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.accent;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: chipColor.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: chipColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 범위 컨트롤 위젯
class _RangeControl extends StatelessWidget {
  final double xMin;
  final double xMax;
  final Function(double) onMinChanged;
  final Function(double) onMaxChanged;

  const _RangeControl({
    required this.xMin,
    required this.xMax,
    required this.onMinChanged,
    required this.onMaxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.straighten, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        const Text(
          'X 범위:',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.cardBorder,
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: RangeSlider(
              values: RangeValues(xMin, xMax),
              min: -50,
              max: 50,
              onChanged: (values) {
                HapticFeedback.selectionClick();
                onMinChanged(values.start);
                onMaxChanged(values.end);
              },
            ),
          ),
        ),
        Text(
          '[${xMin.toInt()}, ${xMax.toInt()}]',
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// 그래프 페인터
class GraphPainter extends CustomPainter {
  final double? Function(double) evaluate;
  final double xMin;
  final double xMax;
  final String formula;

  GraphPainter({
    required this.evaluate,
    required this.xMin,
    required this.xMax,
    required this.formula,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // y 범위 계산
    double yMin = double.infinity;
    double yMax = double.negativeInfinity;
    final points = <Offset>[];
    final steps = 300;
    final dx = (xMax - xMin) / steps;

    for (int i = 0; i <= steps; i++) {
      final x = xMin + i * dx;
      final y = evaluate(x);
      if (y != null && y.isFinite) {
        if (y < yMin) yMin = y;
        if (y > yMax) yMax = y;
        points.add(Offset(x, y));
      }
    }

    // y 범위 조정
    if (yMin == double.infinity) {
      yMin = -10;
      yMax = 10;
    }
    final yRange = yMax - yMin;
    if (yRange < 0.1) {
      yMin -= 5;
      yMax += 5;
    } else {
      yMin -= yRange * 0.1;
      yMax += yRange * 0.1;
    }

    // 좌표 변환 함수
    Offset transform(double x, double y) {
      final px = padding + (x - xMin) / (xMax - xMin) * graphWidth;
      final py = padding + (1 - (y - yMin) / (yMax - yMin)) * graphHeight;
      return Offset(px, py);
    }

    // 그리드 그리기
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 10; i++) {
      final x = padding + i * graphWidth / 10;
      final y = padding + i * graphHeight / 10;
      canvas.drawLine(Offset(x, padding), Offset(x, size.height - padding), gridPaint);
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
    }

    // 축 그리기
    final axisPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    // X축
    if (yMin <= 0 && yMax >= 0) {
      final y0 = transform(0, 0).dy;
      canvas.drawLine(Offset(padding, y0), Offset(size.width - padding, y0), axisPaint);
    }
    // Y축
    if (xMin <= 0 && xMax >= 0) {
      final x0 = transform(0, 0).dx;
      canvas.drawLine(Offset(x0, padding), Offset(x0, size.height - padding), axisPaint);
    }

    // 그래프 그리기 (글로우 효과)
    if (points.length >= 2) {
      final glowPath = Path();
      final mainPath = Path();
      var started = false;
      Offset? lastPoint;

      for (int i = 0; i < points.length; i++) {
        final p = transform(points[i].dx, points[i].dy);

        // 화면 범위 내인지 확인 & 불연속점 처리
        final inBounds = p.dy.isFinite && p.dy > padding - 10 && p.dy < size.height - padding + 10;
        final discontinuous = lastPoint != null && (p.dy - lastPoint.dy).abs() > graphHeight * 0.5;

        if (inBounds && !discontinuous) {
          if (!started) {
            glowPath.moveTo(p.dx, p.dy);
            mainPath.moveTo(p.dx, p.dy);
            started = true;
          } else {
            glowPath.lineTo(p.dx, p.dy);
            mainPath.lineTo(p.dx, p.dy);
          }
        } else {
          started = false;
        }
        lastPoint = p;
      }

      // 글로우
      canvas.drawPath(
        glowPath,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.3)
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // 메인 곡선
      canvas.drawPath(
        mainPath,
        Paint()
          ..color = AppColors.accent
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // 축 레이블
    _drawText(canvas, '${xMin.toInt()}', Offset(padding - 5, size.height - padding + 15),
        fontSize: 10);
    _drawText(canvas, '${xMax.toInt()}',
        Offset(size.width - padding - 10, size.height - padding + 15),
        fontSize: 10);
    _drawText(canvas, yMax.toStringAsFixed(1), Offset(5, padding - 5), fontSize: 10);
    _drawText(canvas, yMin.toStringAsFixed(1),
        Offset(5, size.height - padding - 5),
        fontSize: 10);

    // 수식 표시
    _drawText(canvas, 'y = $formula', Offset(padding + 10, padding + 10),
        fontSize: 12, color: AppColors.accent);
  }

  void _drawText(Canvas canvas, String text, Offset position,
      {double fontSize = 11, Color color = AppColors.muted}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) =>
      formula != oldDelegate.formula ||
      xMin != oldDelegate.xMin ||
      xMax != oldDelegate.xMax;
}
