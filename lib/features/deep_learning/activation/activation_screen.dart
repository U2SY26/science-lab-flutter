import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 활성화 함수 열거형
enum ActivationFunc {
  sigmoid(
    '시그모이드',
    'σ(x) = 1/(1+e⁻ˣ)',
    '출력을 0~1 사이로 압축. 이진 분류에 사용',
  ),
  tanh(
    'Tanh',
    'tanh(x) = (eˣ-e⁻ˣ)/(eˣ+e⁻ˣ)',
    '출력을 -1~1 사이로 압축. 은닉층에 적합',
  ),
  relu(
    'ReLU',
    'f(x) = max(0, x)',
    '0 이하를 0으로. 현재 가장 인기 있는 활성화 함수',
  ),
  leakyRelu(
    'Leaky ReLU',
    'f(x) = max(αx, x)',
    '음수에서도 작은 기울기 유지. Dying ReLU 문제 해결',
  ),
  elu(
    'ELU',
    'f(x) = x if x>0, α(eˣ-1) otherwise',
    '음수에서 부드러운 곡선. 평균 출력이 0에 가까움',
  ),
  swish(
    'Swish',
    'f(x) = x·σ(x)',
    'Google 제안. 깊은 네트워크에서 성능 우수',
  ),
  softplus(
    'Softplus',
    'f(x) = ln(1+eˣ)',
    'ReLU의 부드러운 버전. 미분이 sigmoid',
  ),
  gelu(
    'GELU',
    'f(x) ≈ x·Φ(x)',
    'Transformer에서 사용. BERT, GPT의 기본 활성화',
  );

  final String label;
  final String formula;
  final String description;
  const ActivationFunc(this.label, this.formula, this.description);

  double compute(double x, {double alpha = 0.01}) {
    switch (this) {
      case ActivationFunc.sigmoid:
        return 1 / (1 + math.exp(-x));
      case ActivationFunc.tanh:
        return (math.exp(x) - math.exp(-x)) / (math.exp(x) + math.exp(-x));
      case ActivationFunc.relu:
        return x > 0 ? x : 0;
      case ActivationFunc.leakyRelu:
        return x > 0 ? x : alpha * x;
      case ActivationFunc.elu:
        return x > 0 ? x : alpha * (math.exp(x) - 1);
      case ActivationFunc.swish:
        return x / (1 + math.exp(-x));
      case ActivationFunc.softplus:
        return math.log(1 + math.exp(x));
      case ActivationFunc.gelu:
        // 근사 공식
        return 0.5 * x * (1 + _tanh(math.sqrt(2 / math.pi) * (x + 0.044715 * x * x * x)));
    }
  }

  double derivative(double x, {double alpha = 0.01}) {
    switch (this) {
      case ActivationFunc.sigmoid:
        final s = compute(x);
        return s * (1 - s);
      case ActivationFunc.tanh:
        final t = compute(x);
        return 1 - t * t;
      case ActivationFunc.relu:
        return x > 0 ? 1 : 0;
      case ActivationFunc.leakyRelu:
        return x > 0 ? 1 : alpha;
      case ActivationFunc.elu:
        return x > 0 ? 1 : compute(x) + alpha;
      case ActivationFunc.swish:
        final s = 1 / (1 + math.exp(-x));
        return s + x * s * (1 - s);
      case ActivationFunc.softplus:
        return 1 / (1 + math.exp(-x));
      case ActivationFunc.gelu:
        // 근사 미분
        final inner = math.sqrt(2 / math.pi) * (x + 0.044715 * x * x * x);
        final t = _tanh(inner);
        return 0.5 * (1 + t) + 0.5 * x * (1 - t * t) * math.sqrt(2 / math.pi) * (1 + 3 * 0.044715 * x * x);
    }
  }

  static double _tanh(double x) {
    return (math.exp(x) - math.exp(-x)) / (math.exp(x) + math.exp(-x));
  }
}

/// 활성화 함수 시각화 화면
class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  ActivationFunc _selectedFunc = ActivationFunc.relu;
  double _alpha = 0.01; // Leaky ReLU, ELU 파라미터
  bool _showDerivative = false;
  double _inputValue = 0;

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
              '딥러닝',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '활성화 함수',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '딥러닝',
          title: '활성화 함수',
          formula: _selectedFunc.formula,
          formulaDescription: _selectedFunc.description,
          simulation: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _inputValue = (_inputValue + details.delta.dx * 0.02).clamp(-5.0, 5.0);
              });
            },
            child: SizedBox(
              height: 300,
              child: CustomPaint(
                painter: ActivationPainter(
                  func: _selectedFunc,
                  showDerivative: _showDerivative,
                  alpha: _alpha,
                  inputValue: _inputValue,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 함수 선택 (주요)
              PresetGroup(
                label: '주요 활성화 함수',
                presets: [
                  PresetButton(
                    label: 'ReLU',
                    isSelected: _selectedFunc == ActivationFunc.relu,
                    onPressed: () => _selectFunc(ActivationFunc.relu),
                  ),
                  PresetButton(
                    label: 'Sigmoid',
                    isSelected: _selectedFunc == ActivationFunc.sigmoid,
                    onPressed: () => _selectFunc(ActivationFunc.sigmoid),
                  ),
                  PresetButton(
                    label: 'Tanh',
                    isSelected: _selectedFunc == ActivationFunc.tanh,
                    onPressed: () => _selectFunc(ActivationFunc.tanh),
                  ),
                  PresetButton(
                    label: 'GELU',
                    isSelected: _selectedFunc == ActivationFunc.gelu,
                    onPressed: () => _selectFunc(ActivationFunc.gelu),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 함수 선택 (변형)
              PresetGroup(
                label: '변형 활성화 함수',
                presets: [
                  PresetButton(
                    label: 'Leaky',
                    isSelected: _selectedFunc == ActivationFunc.leakyRelu,
                    onPressed: () => _selectFunc(ActivationFunc.leakyRelu),
                  ),
                  PresetButton(
                    label: 'ELU',
                    isSelected: _selectedFunc == ActivationFunc.elu,
                    onPressed: () => _selectFunc(ActivationFunc.elu),
                  ),
                  PresetButton(
                    label: 'Swish',
                    isSelected: _selectedFunc == ActivationFunc.swish,
                    onPressed: () => _selectFunc(ActivationFunc.swish),
                  ),
                  PresetButton(
                    label: 'Softplus',
                    isSelected: _selectedFunc == ActivationFunc.softplus,
                    onPressed: () => _selectFunc(ActivationFunc.softplus),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 함수 정보
              _FunctionInfo(
                func: _selectedFunc,
                inputValue: _inputValue,
                alpha: _alpha,
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '입력값 x',
                  value: _inputValue,
                  min: -5,
                  max: 5,
                  defaultValue: 0,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _inputValue = v),
                ),
                advancedControls: [
                  if (_selectedFunc == ActivationFunc.leakyRelu ||
                      _selectedFunc == ActivationFunc.elu)
                    SimSlider(
                      label: 'α (파라미터)',
                      value: _alpha,
                      min: 0.001,
                      max: 0.3,
                      defaultValue: 0.01,
                      formatValue: (v) => v.toStringAsFixed(3),
                      onChanged: (v) => setState(() => _alpha = v),
                    ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _showDerivative ? '함수 보기' : '도함수 보기',
                icon: Icons.functions,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showDerivative = !_showDerivative);
                },
              ),
              SimButton(
                label: '비교',
                icon: Icons.compare,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showComparisonSheet(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectFunc(ActivationFunc func) {
    HapticFeedback.selectionClick();
    setState(() => _selectedFunc = func);
  }

  void _showComparisonSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '활성화 함수 비교',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: ActivationFunc.values.map((func) {
                  final output = func.compute(_inputValue, alpha: _alpha);
                  return ListTile(
                    title: Text(
                      func.label,
                      style: TextStyle(
                        color: _selectedFunc == func ? AppColors.accent : AppColors.ink,
                        fontWeight: _selectedFunc == func ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      func.formula,
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                    trailing: Text(
                      'f($_inputValue) = ${output.toStringAsFixed(3)}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontFamily: 'monospace',
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _selectFunc(func);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 함수 정보 위젯
class _FunctionInfo extends StatelessWidget {
  final ActivationFunc func;
  final double inputValue;
  final double alpha;

  const _FunctionInfo({
    required this.func,
    required this.inputValue,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    final output = func.compute(inputValue, alpha: alpha);
    final derivative = func.derivative(inputValue, alpha: alpha);

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
                  label: '입력 x',
                  value: inputValue.toStringAsFixed(2),
                  icon: Icons.input,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: '출력 f(x)',
                  value: output.toStringAsFixed(4),
                  icon: Icons.output,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: "도함수 f'(x)",
                  value: derivative.toStringAsFixed(4),
                  icon: Icons.trending_up,
                  color: AppColors.accent2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getUsageTip(),
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getUsageTip() {
    switch (func) {
      case ActivationFunc.sigmoid:
        return '출력층에서 이진 분류에 사용. 기울기 소실 문제 주의';
      case ActivationFunc.tanh:
        return 'RNN에서 많이 사용. 출력이 0 중심이라 학습에 유리';
      case ActivationFunc.relu:
        return 'CNN에서 기본 선택. 빠르고 효과적이지만 Dying ReLU 주의';
      case ActivationFunc.leakyRelu:
        return 'α값으로 음수 기울기 조절. Dying ReLU 문제 해결';
      case ActivationFunc.elu:
        return '음수에서 부드럽게 포화. 배치 정규화 없이도 효과적';
      case ActivationFunc.swish:
        return 'ImageNet에서 ReLU보다 우수. 깊은 네트워크에 적합';
      case ActivationFunc.softplus:
        return 'ReLU의 부드러운 근사. 미분이 sigmoid와 동일';
      case ActivationFunc.gelu:
        return 'BERT, GPT의 기본 활성화. NLP에서 표준';
    }
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
    final chipColor = color ?? AppColors.muted;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: chipColor),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  color: chipColor.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

/// 활성화 함수 페인터
class ActivationPainter extends CustomPainter {
  final ActivationFunc func;
  final bool showDerivative;
  final double alpha;
  final double inputValue;

  ActivationPainter({
    required this.func,
    required this.showDerivative,
    required this.alpha,
    required this.inputValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

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
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(padding, centerY), Offset(size.width - padding, centerY), axisPaint);
    canvas.drawLine(Offset(centerX, padding), Offset(centerX, size.height - padding), axisPaint);

    // 스케일
    final scale = graphHeight / 4; // -2 ~ 2 범위

    Offset toScreen(double x, double y) {
      return Offset(
        centerX + x * graphWidth / 10,
        centerY - y * scale,
      );
    }

    // 함수 그리기
    final path = Path();
    final glowPath = Path();
    bool started = false;

    for (double x = -5; x <= 5; x += 0.05) {
      final y = showDerivative
          ? func.derivative(x, alpha: alpha)
          : func.compute(x, alpha: alpha);

      if (y.isFinite && y.abs() < 10) {
        final p = toScreen(x, y);
        if (p.dy > padding && p.dy < size.height - padding) {
          if (!started) {
            path.moveTo(p.dx, p.dy);
            glowPath.moveTo(p.dx, p.dy);
            started = true;
          } else {
            path.lineTo(p.dx, p.dy);
            glowPath.lineTo(p.dx, p.dy);
          }
        } else {
          started = false;
        }
      } else {
        started = false;
      }
    }

    // 글로우
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = (showDerivative ? AppColors.accent2 : AppColors.accent).withValues(alpha: 0.3)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // 메인 곡선
    canvas.drawPath(
      path,
      Paint()
        ..color = showDerivative ? AppColors.accent2 : AppColors.accent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 현재 입력값 표시
    final currentY = showDerivative
        ? func.derivative(inputValue, alpha: alpha)
        : func.compute(inputValue, alpha: alpha);
    final currentPoint = toScreen(inputValue, currentY);

    // 수직선
    canvas.drawLine(
      Offset(currentPoint.dx, centerY),
      currentPoint,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // 포인트 글로우
    canvas.drawCircle(
      currentPoint,
      15,
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );

    // 포인트
    canvas.drawCircle(
      currentPoint,
      8,
      Paint()..color = Colors.white,
    );

    // 축 레이블
    _drawText(canvas, 'x', Offset(size.width - padding + 5, centerY - 15));
    _drawText(canvas, showDerivative ? "f'(x)" : 'f(x)', Offset(centerX + 5, padding - 15));

    // 현재 값 표시
    _drawText(
      canvas,
      '(${inputValue.toStringAsFixed(1)}, ${currentY.toStringAsFixed(2)})',
      Offset(currentPoint.dx + 10, currentPoint.dy - 20),
      color: Colors.white,
    );

    // 함수 이름
    _drawText(
      canvas,
      showDerivative ? "${func.label}' (도함수)" : func.label,
      Offset(padding + 10, padding + 10),
      color: showDerivative ? AppColors.accent2 : AppColors.accent,
      fontSize: 14,
    );
  }

  void _drawText(Canvas canvas, String text, Offset position,
      {Color color = AppColors.muted, double fontSize = 11}) {
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
  bool shouldRepaint(covariant ActivationPainter oldDelegate) =>
      func != oldDelegate.func ||
      showDerivative != oldDelegate.showDerivative ||
      alpha != oldDelegate.alpha ||
      inputValue != oldDelegate.inputValue;
}
