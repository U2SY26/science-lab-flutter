import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Logic Gates Visualization
/// 논리 게이트 시각화
class LogicGatesScreen extends StatefulWidget {
  const LogicGatesScreen({super.key});

  @override
  State<LogicGatesScreen> createState() => _LogicGatesScreenState();
}

class _LogicGatesScreenState extends State<LogicGatesScreen> {
  bool inputA = true;
  bool inputB = false;
  int gateType = 0; // 0: AND, 1: OR, 2: NOT, 3: NAND, 4: NOR, 5: XOR, 6: XNOR
  bool isKorean = true;

  bool get _output {
    switch (gateType) {
      case 0:
        return inputA && inputB;
      case 1:
        return inputA || inputB;
      case 2:
        return !inputA;
      case 3:
        return !(inputA && inputB);
      case 4:
        return !(inputA || inputB);
      case 5:
        return inputA != inputB;
      case 6:
        return inputA == inputB;
      default:
        return false;
    }
  }

  String get _gateName {
    const names = ['AND', 'OR', 'NOT', 'NAND', 'NOR', 'XOR', 'XNOR'];
    return names[gateType];
  }

  String get _gateDescription {
    if (isKorean) {
      switch (gateType) {
        case 0:
          return '두 입력이 모두 1일 때만 출력이 1';
        case 1:
          return '하나 이상의 입력이 1이면 출력이 1';
        case 2:
          return '입력의 반대를 출력';
        case 3:
          return 'AND의 반대 (범용 게이트)';
        case 4:
          return 'OR의 반대 (범용 게이트)';
        case 5:
          return '입력이 다르면 1, 같으면 0';
        case 6:
          return '입력이 같으면 1, 다르면 0';
        default:
          return '';
      }
    } else {
      switch (gateType) {
        case 0:
          return 'Output 1 only if both inputs are 1';
        case 1:
          return 'Output 1 if any input is 1';
        case 2:
          return 'Inverts the input';
        case 3:
          return 'Inverse of AND (universal gate)';
        case 4:
          return 'Inverse of OR (universal gate)';
        case 5:
          return 'Output 1 if inputs differ';
        case 6:
          return 'Output 1 if inputs are equal';
        default:
          return '';
      }
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      inputA = true;
      inputB = false;
      gateType = 0;
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
              isKorean ? '디지털 논리' : 'DIGITAL LOGIC',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '논리 게이트' : 'Logic Gates',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => setState(() => isKorean = !isKorean),
            tooltip: isKorean ? 'English' : '한국어',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '디지털 논리' : 'DIGITAL LOGIC',
          title: isKorean ? '논리 게이트' : 'Logic Gates',
          formula: '$_gateName Gate',
          formulaDescription: _gateDescription,
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: LogicGatesPainter(
                inputA: inputA,
                inputB: inputB,
                gateType: gateType,
                output: _output,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gate selection
              PresetGroup(
                label: isKorean ? '게이트 종류' : 'Gate Type',
                presets: [
                  PresetButton(label: 'AND', isSelected: gateType == 0, onPressed: () { HapticFeedback.selectionClick(); setState(() => gateType = 0); }),
                  PresetButton(label: 'OR', isSelected: gateType == 1, onPressed: () { HapticFeedback.selectionClick(); setState(() => gateType = 1); }),
                  PresetButton(label: 'NOT', isSelected: gateType == 2, onPressed: () { HapticFeedback.selectionClick(); setState(() => gateType = 2); }),
                  PresetButton(label: 'NAND', isSelected: gateType == 3, onPressed: () { HapticFeedback.selectionClick(); setState(() => gateType = 3); }),
                  PresetButton(label: 'NOR', isSelected: gateType == 4, onPressed: () { HapticFeedback.selectionClick(); setState(() => gateType = 4); }),
                  PresetButton(label: 'XOR', isSelected: gateType == 5, onPressed: () { HapticFeedback.selectionClick(); setState(() => gateType = 5); }),
                  PresetButton(label: 'XNOR', isSelected: gateType == 6, onPressed: () { HapticFeedback.selectionClick(); setState(() => gateType = 6); }),
                ],
              ),
              const SizedBox(height: 20),

              // Input controls
              Row(
                children: [
                  Expanded(
                    child: _InputButton(
                      label: 'Input A',
                      value: inputA,
                      onTap: () => setState(() => inputA = !inputA),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (gateType != 2) // NOT gate has only one input
                    Expanded(
                      child: _InputButton(
                        label: 'Input B',
                        value: inputB,
                        onTap: () => setState(() => inputB = !inputB),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Output display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _output ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _output ? Colors.green : Colors.red, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _output ? Icons.check_circle : Icons.cancel,
                      color: _output ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Text(
                          isKorean ? '출력' : 'Output',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        Text(
                          _output ? '1 (HIGH)' : '0 (LOW)',
                          style: TextStyle(
                            color: _output ? Colors.green : Colors.red,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Truth table
              _TruthTable(gateType: gateType, isKorean: isKorean),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
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

class _InputButton extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onTap;

  const _InputButton({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? AppColors.accent : AppColors.simBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value ? AppColors.accent : AppColors.cardBorder, width: 2),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: value ? Colors.white : AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              value ? '1' : '0',
              style: TextStyle(
                color: value ? Colors.white : AppColors.ink,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            Text(
              value ? 'HIGH' : 'LOW',
              style: TextStyle(color: value ? Colors.white70 : AppColors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _TruthTable extends StatelessWidget {
  final int gateType;
  final bool isKorean;

  const _TruthTable({required this.gateType, required this.isKorean});

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
          Text(
            isKorean ? '진리표' : 'Truth Table',
            style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (gateType == 2) // NOT
            _buildNotTable()
          else
            _buildTwoInputTable(),
        ],
      ),
    );
  }

  Widget _buildNotTable() {
    return Column(
      children: [
        Row(children: [_cell('A', header: true), _cell('OUT', header: true)]),
        Row(children: [_cell('0'), _cell('1', result: true)]),
        Row(children: [_cell('1'), _cell('0', result: false)]),
      ],
    );
  }

  Widget _buildTwoInputTable() {
    bool calc(bool a, bool b) {
      switch (gateType) {
        case 0: return a && b;
        case 1: return a || b;
        case 3: return !(a && b);
        case 4: return !(a || b);
        case 5: return a != b;
        case 6: return a == b;
        default: return false;
      }
    }

    return Column(
      children: [
        Row(children: [_cell('A', header: true), _cell('B', header: true), _cell('OUT', header: true)]),
        Row(children: [_cell('0'), _cell('0'), _cell(calc(false, false) ? '1' : '0', result: calc(false, false))]),
        Row(children: [_cell('0'), _cell('1'), _cell(calc(false, true) ? '1' : '0', result: calc(false, true))]),
        Row(children: [_cell('1'), _cell('0'), _cell(calc(true, false) ? '1' : '0', result: calc(true, false))]),
        Row(children: [_cell('1'), _cell('1'), _cell(calc(true, true) ? '1' : '0', result: calc(true, true))]),
      ],
    );
  }

  Widget _cell(String text, {bool header = false, bool? result}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: header ? AppColors.muted : result == true ? Colors.green : result == false ? Colors.red : AppColors.ink,
            fontSize: 12,
            fontWeight: header ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class LogicGatesPainter extends CustomPainter {
  final bool inputA, inputB;
  final int gateType;
  final bool output;

  LogicGatesPainter({
    required this.inputA,
    required this.inputB,
    required this.gateType,
    required this.output,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw gate symbol
    _drawGate(canvas, Offset(centerX, centerY), gateType);

    // Draw input wires
    final inputY1 = centerY - 20;
    final inputY2 = centerY + 20;
    final gateLeft = centerX - 40;
    final gateRight = centerX + 40;

    // Input A wire
    _drawWire(canvas, Offset(30, inputY1), Offset(gateLeft, inputY1), inputA);
    _drawText(canvas, 'A=${inputA ? 1 : 0}', Offset(30, inputY1 - 15), inputA ? Colors.green : Colors.red);

    // Input B wire (if applicable)
    if (gateType != 2) {
      _drawWire(canvas, Offset(30, inputY2), Offset(gateLeft, inputY2), inputB);
      _drawText(canvas, 'B=${inputB ? 1 : 0}', Offset(30, inputY2 + 15), inputB ? Colors.green : Colors.red);
    }

    // Output wire
    _drawWire(canvas, Offset(gateRight, centerY), Offset(size.width - 30, centerY), output);
    _drawText(canvas, 'OUT=${output ? 1 : 0}', Offset(size.width - 30, centerY - 15), output ? Colors.green : Colors.red);

    // Gate label
    final gateNames = ['AND', 'OR', 'NOT', 'NAND', 'NOR', 'XOR', 'XNOR'];
    _drawText(canvas, gateNames[gateType], Offset(centerX, centerY + 50), AppColors.accent, fontSize: 16);
  }

  void _drawGate(Canvas canvas, Offset center, int type) {
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fillPaint = Paint()..color = AppColors.accent.withValues(alpha: 0.1);

    final path = Path();
    final w = 40.0;
    final h = 30.0;

    switch (type) {
      case 0: // AND
      case 3: // NAND
        path.moveTo(center.dx - w, center.dy - h);
        path.lineTo(center.dx, center.dy - h);
        path.arcToPoint(Offset(center.dx, center.dy + h), radius: Radius.circular(h), clockwise: true);
        path.lineTo(center.dx - w, center.dy + h);
        path.close();
        break;

      case 1: // OR
      case 4: // NOR
        path.moveTo(center.dx - w, center.dy - h);
        path.quadraticBezierTo(center.dx, center.dy - h, center.dx + w, center.dy);
        path.quadraticBezierTo(center.dx, center.dy + h, center.dx - w, center.dy + h);
        path.quadraticBezierTo(center.dx - w + 15, center.dy, center.dx - w, center.dy - h);
        break;

      case 2: // NOT
        path.moveTo(center.dx - w, center.dy - h);
        path.lineTo(center.dx + w - 10, center.dy);
        path.lineTo(center.dx - w, center.dy + h);
        path.close();
        break;

      default: // XOR, XNOR
        path.moveTo(center.dx - w, center.dy - h);
        path.quadraticBezierTo(center.dx, center.dy - h, center.dx + w, center.dy);
        path.quadraticBezierTo(center.dx, center.dy + h, center.dx - w, center.dy + h);
        path.quadraticBezierTo(center.dx - w + 15, center.dy, center.dx - w, center.dy - h);
        // Extra curve for XOR
        final xorPath = Path();
        xorPath.moveTo(center.dx - w - 8, center.dy - h);
        xorPath.quadraticBezierTo(center.dx - w + 7, center.dy, center.dx - w - 8, center.dy + h);
        canvas.drawPath(xorPath, paint);
    }

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Inversion bubble for NAND, NOR, NOT, XNOR
    if (type == 2 || type == 3 || type == 4 || type == 6) {
      canvas.drawCircle(
        Offset(center.dx + w + 5, center.dy),
        5,
        Paint()..color = AppColors.accent,
      );
    }
  }

  void _drawWire(Canvas canvas, Offset start, Offset end, bool active) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = active ? Colors.green : Colors.red.withValues(alpha: 0.5)
        ..strokeWidth = active ? 3 : 2,
    );
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant LogicGatesPainter oldDelegate) =>
      inputA != oldDelegate.inputA ||
      inputB != oldDelegate.inputB ||
      gateType != oldDelegate.gateType;
}
