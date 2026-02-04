import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// RNN & LSTM Simulation
class RnnLstmScreen extends ConsumerStatefulWidget {
  const RnnLstmScreen({super.key});

  @override
  ConsumerState<RnnLstmScreen> createState() => _RnnLstmScreenState();
}

class _RnnLstmScreenState extends ConsumerState<RnnLstmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  // Network type
  String _networkType = 'rnn'; // 'rnn' or 'lstm'

  // Sequence data
  List<double> _inputSequence = [];
  List<double> _hiddenStates = [];
  List<double> _cellStates = []; // For LSTM
  List<double> _outputs = [];

  // LSTM gates
  List<double> _forgetGates = [];
  List<double> _inputGates = [];
  List<double> _outputGates = [];
  List<double> _candidateCells = [];

  // Parameters
  int _sequenceLength = 8;
  int _hiddenSize = 4;
  int _currentStep = 0;
  bool _isAnimating = false;

  // Weights (simplified)
  late List<List<double>> _Wxh; // Input to hidden
  late List<List<double>> _Whh; // Hidden to hidden
  late List<double> _bh; // Hidden bias

  @override
  void initState() {
    super.initState();
    _initializeNetwork();
    _generateSequence();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(_stepAnimation);
  }

  void _initializeNetwork() {
    // Initialize weights with Xavier initialization
    final scale = math.sqrt(2.0 / (_hiddenSize + 1));

    _Wxh = List.generate(
      _hiddenSize,
      (_) => List.generate(1, (_) => (_random.nextDouble() - 0.5) * 2 * scale),
    );
    _Whh = List.generate(
      _hiddenSize,
      (_) => List.generate(
          _hiddenSize, (_) => (_random.nextDouble() - 0.5) * 2 * scale),
    );
    _bh = List.generate(_hiddenSize, (_) => 0.0);

    _hiddenStates = List.filled(_sequenceLength + 1, 0.0);
    _cellStates = List.filled(_sequenceLength + 1, 0.0);
    _outputs = List.filled(_sequenceLength, 0.0);

    _forgetGates = List.filled(_sequenceLength, 0.0);
    _inputGates = List.filled(_sequenceLength, 0.0);
    _outputGates = List.filled(_sequenceLength, 0.0);
    _candidateCells = List.filled(_sequenceLength, 0.0);
  }

  void _generateSequence() {
    // Generate a sine wave sequence
    _inputSequence = List.generate(
      _sequenceLength,
      (i) => math.sin(i * 0.5) * 0.5 + 0.5,
    );
    _currentStep = 0;
    _hiddenStates = List.filled(_sequenceLength + 1, 0.0);
    _cellStates = List.filled(_sequenceLength + 1, 0.0);
    _outputs = List.filled(_sequenceLength, 0.0);
    _forgetGates = List.filled(_sequenceLength, 0.0);
    _inputGates = List.filled(_sequenceLength, 0.0);
    _outputGates = List.filled(_sequenceLength, 0.0);
    _candidateCells = List.filled(_sequenceLength, 0.0);
  }

  double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x.clamp(-500, 500)));
  double _tanh(double x) {
    final ex = math.exp(x.clamp(-500, 500));
    final emx = math.exp(-x.clamp(-500, 500));
    return (ex - emx) / (ex + emx);
  }

  void _processStep(int step) {
    if (step >= _sequenceLength) return;

    final x = _inputSequence[step];
    final hPrev = step > 0 ? _hiddenStates[step] : 0.0;
    final cPrev = step > 0 ? _cellStates[step] : 0.0;

    if (_networkType == 'rnn') {
      // Simple RNN: h_t = tanh(W_xh * x + W_hh * h_{t-1} + b)
      double h = 0;
      for (int i = 0; i < _hiddenSize; i++) {
        h += _Wxh[i][0] * x + _Whh[i][0] * hPrev + _bh[i];
      }
      h = _tanh(h / _hiddenSize);
      _hiddenStates[step + 1] = h;
      _outputs[step] = _sigmoid(h);
    } else {
      // LSTM
      // Forget gate: f_t = sigmoid(W_f * [h_{t-1}, x_t] + b_f)
      final f = _sigmoid(0.5 * hPrev + 0.5 * x - 0.2);
      _forgetGates[step] = f;

      // Input gate: i_t = sigmoid(W_i * [h_{t-1}, x_t] + b_i)
      final i = _sigmoid(0.5 * hPrev + 0.5 * x);
      _inputGates[step] = i;

      // Candidate cell: c_tilde = tanh(W_c * [h_{t-1}, x_t] + b_c)
      final cTilde = _tanh(0.5 * hPrev + 0.5 * x);
      _candidateCells[step] = cTilde;

      // Cell state: c_t = f_t * c_{t-1} + i_t * c_tilde
      final c = f * cPrev + i * cTilde;
      _cellStates[step + 1] = c;

      // Output gate: o_t = sigmoid(W_o * [h_{t-1}, x_t] + b_o)
      final o = _sigmoid(0.5 * hPrev + 0.5 * x + 0.1);
      _outputGates[step] = o;

      // Hidden state: h_t = o_t * tanh(c_t)
      final h = o * _tanh(c);
      _hiddenStates[step + 1] = h;
      _outputs[step] = _sigmoid(h);
    }
  }

  void _stepAnimation() {
    if (!_isAnimating) return;

    setState(() {
      if (_currentStep < _sequenceLength) {
        _processStep(_currentStep);
        _currentStep++;
      } else {
        _isAnimating = false;
        _controller.stop();
      }
    });
  }

  void _startAnimation() {
    HapticFeedback.selectionClick();
    setState(() {
      _generateSequence();
      _isAnimating = true;
    });
    _controller.repeat();
  }

  void _stopAnimation() {
    HapticFeedback.selectionClick();
    setState(() {
      _isAnimating = false;
    });
    _controller.stop();
  }

  void _stepOnce() {
    HapticFeedback.lightImpact();
    if (_currentStep < _sequenceLength) {
      setState(() {
        _processStep(_currentStep);
        _currentStep++;
      });
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      _isAnimating = false;
      _generateSequence();
    });
  }

  void _randomizeSequence() {
    HapticFeedback.mediumImpact();
    setState(() {
      _inputSequence = List.generate(
        _sequenceLength,
        (_) => _random.nextDouble(),
      );
      _currentStep = 0;
      _hiddenStates = List.filled(_sequenceLength + 1, 0.0);
      _cellStates = List.filled(_sequenceLength + 1, 0.0);
      _outputs = List.filled(_sequenceLength, 0.0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);

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
              isKorean ? '딥러닝' : 'DEEP LEARNING',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? 'RNN & LSTM' : 'RNN & LSTM',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '딥러닝' : 'Deep Learning',
          title: isKorean ? 'RNN & LSTM' : 'RNN & LSTM',
          formula: _networkType == 'rnn'
              ? 'h_t = tanh(W_xh·x_t + W_hh·h_{t-1} + b)'
              : 'c_t = f_t·c_{t-1} + i_t·tanh(W_c·[h_{t-1},x_t])',
          formulaDescription: isKorean
              ? (_networkType == 'rnn'
                  ? '순환 신경망: 이전 상태를 기억하여 시퀀스 데이터를 처리'
                  : 'LSTM: 게이트 메커니즘으로 장기 의존성 문제 해결')
              : (_networkType == 'rnn'
                  ? 'RNN: Processes sequences by maintaining hidden state'
                  : 'LSTM: Solves vanishing gradient with gate mechanisms'),
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _RnnLstmPainter(
                networkType: _networkType,
                inputSequence: _inputSequence,
                hiddenStates: _hiddenStates,
                cellStates: _cellStates,
                outputs: _outputs,
                forgetGates: _forgetGates,
                inputGates: _inputGates,
                outputGates: _outputGates,
                currentStep: _currentStep,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Network type selection
              SimSegment<String>(
                label: isKorean ? '네트워크 타입' : 'Network Type',
                options: {
                  'rnn': 'RNN',
                  'lstm': 'LSTM',
                },
                selected: _networkType,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _networkType = v;
                    _reset();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Stats display
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
                        _StatItem(
                          label: isKorean ? '시퀀스 길이' : 'Seq Length',
                          value: '$_sequenceLength',
                          color: Colors.blue,
                        ),
                        _StatItem(
                          label: isKorean ? '현재 스텝' : 'Current Step',
                          value: '$_currentStep / $_sequenceLength',
                          color: AppColors.accent,
                        ),
                        _StatItem(
                          label: isKorean ? '은닉 상태' : 'Hidden State',
                          value: _hiddenStates[_currentStep].toStringAsFixed(3),
                          color: Colors.green,
                        ),
                      ],
                    ),
                    if (_networkType == 'lstm' && _currentStep > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _GateIndicator(
                            label: isKorean ? '망각' : 'Forget',
                            value: _forgetGates[_currentStep - 1],
                            color: Colors.red,
                          ),
                          _GateIndicator(
                            label: isKorean ? '입력' : 'Input',
                            value: _inputGates[_currentStep - 1],
                            color: Colors.blue,
                          ),
                          _GateIndicator(
                            label: isKorean ? '출력' : 'Output',
                            value: _outputGates[_currentStep - 1],
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sequence pattern presets
              PresetGroup(
                label: isKorean ? '시퀀스 패턴' : 'Sequence Pattern',
                presets: [
                  PresetButton(
                    label: isKorean ? '사인파' : 'Sine',
                    isSelected: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _inputSequence = List.generate(
                          _sequenceLength,
                          (i) => math.sin(i * 0.5) * 0.5 + 0.5,
                        );
                        _currentStep = 0;
                        _generateSequence();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '계단' : 'Step',
                    isSelected: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _inputSequence = List.generate(
                          _sequenceLength,
                          (i) => i < _sequenceLength / 2 ? 0.2 : 0.8,
                        );
                        _currentStep = 0;
                        _generateSequence();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '램프' : 'Ramp',
                    isSelected: false,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _inputSequence = List.generate(
                          _sequenceLength,
                          (i) => i / (_sequenceLength - 1),
                        );
                        _currentStep = 0;
                        _generateSequence();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '랜덤' : 'Random',
                    isSelected: false,
                    onPressed: _randomizeSequence,
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isAnimating
                    ? (isKorean ? '정지' : 'Stop')
                    : (isKorean ? '실행' : 'Run'),
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _isAnimating ? _stopAnimation : _startAnimation,
              ),
              SimButton(
                label: isKorean ? '한 스텝' : 'Step',
                icon: Icons.skip_next,
                onPressed: _currentStep < _sequenceLength ? _stepOnce : null,
              ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _GateIndicator extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _GateIndicator({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 9),
        ),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.cardBorder,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0, 1),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(color: color, fontSize: 9, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}

class _RnnLstmPainter extends CustomPainter {
  final String networkType;
  final List<double> inputSequence;
  final List<double> hiddenStates;
  final List<double> cellStates;
  final List<double> outputs;
  final List<double> forgetGates;
  final List<double> inputGates;
  final List<double> outputGates;
  final int currentStep;
  final bool isKorean;

  _RnnLstmPainter({
    required this.networkType,
    required this.inputSequence,
    required this.hiddenStates,
    required this.cellStates,
    required this.outputs,
    required this.forgetGates,
    required this.inputGates,
    required this.outputGates,
    required this.currentStep,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 30.0;
    final cellWidth = (size.width - padding * 2) / inputSequence.length;
    final cellHeight = 40.0;

    // Draw input sequence
    _drawSequenceRow(
      canvas,
      inputSequence,
      Offset(padding, 40),
      cellWidth,
      cellHeight,
      isKorean ? '입력 시퀀스' : 'Input Sequence',
      Colors.blue,
      currentStep,
    );

    // Draw RNN/LSTM cells
    if (networkType == 'lstm') {
      _drawLstmCells(canvas, size, padding, cellWidth);
    } else {
      _drawRnnCells(canvas, size, padding, cellWidth);
    }

    // Draw hidden states
    _drawSequenceRow(
      canvas,
      hiddenStates.sublist(1),
      Offset(padding, size.height - 100),
      cellWidth,
      cellHeight,
      isKorean ? '은닉 상태' : 'Hidden States',
      Colors.green,
      currentStep - 1,
    );

    // Draw outputs
    _drawSequenceRow(
      canvas,
      outputs,
      Offset(padding, size.height - 40),
      cellWidth,
      cellHeight * 0.8,
      isKorean ? '출력' : 'Output',
      AppColors.accent,
      currentStep - 1,
    );
  }

  void _drawSequenceRow(
    Canvas canvas,
    List<double> data,
    Offset origin,
    double cellWidth,
    double cellHeight,
    String label,
    Color color,
    int highlightIndex,
  ) {
    // Draw label
    _drawText(canvas, label, Offset(origin.dx, origin.dy - 18), AppColors.ink,
        fontSize: 10);

    for (int i = 0; i < data.length; i++) {
      final x = origin.dx + i * cellWidth;
      final rect = Rect.fromLTWH(x + 2, origin.dy, cellWidth - 4, cellHeight);

      // Background
      final intensity = data[i].clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = color.withValues(alpha: 0.1 + intensity * 0.5),
      );

      // Border
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()
          ..color = i == highlightIndex ? color : color.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == highlightIndex ? 2 : 1,
      );

      // Value
      _drawText(
        canvas,
        data[i].toStringAsFixed(2),
        Offset(x + cellWidth / 2 - 12, origin.dy + cellHeight / 2 - 6),
        i == highlightIndex ? color : AppColors.muted,
        fontSize: 9,
      );
    }
  }

  void _drawRnnCells(
      Canvas canvas, Size size, double padding, double cellWidth) {
    final centerY = size.height / 2;
    final cellSize = 50.0;

    for (int i = 0; i < inputSequence.length; i++) {
      final x = padding + i * cellWidth + cellWidth / 2;

      // Draw RNN cell
      final cellRect =
          Rect.fromCenter(center: Offset(x, centerY), width: cellSize, height: cellSize);

      final isActive = i < currentStep;
      final isCurrent = i == currentStep - 1;

      canvas.drawRRect(
        RRect.fromRectAndRadius(cellRect, const Radius.circular(8)),
        Paint()
          ..color = isActive
              ? (isCurrent ? AppColors.accent : AppColors.accent.withValues(alpha: 0.3))
              : AppColors.cardBorder,
      );

      // Draw "tanh" label
      _drawText(canvas, 'tanh', Offset(x - 12, centerY - 6),
          isActive ? Colors.white : AppColors.muted,
          fontSize: 10);

      // Draw recurrent connection
      if (i < inputSequence.length - 1) {
        final arrowPaint = Paint()
          ..color = isActive ? AppColors.accent : AppColors.cardBorder
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(x + cellSize / 2, centerY),
          Offset(x + cellWidth - cellSize / 2, centerY),
          arrowPaint,
        );

        // Arrow head
        final arrowX = x + cellWidth - cellSize / 2;
        canvas.drawLine(
          Offset(arrowX, centerY),
          Offset(arrowX - 6, centerY - 4),
          arrowPaint,
        );
        canvas.drawLine(
          Offset(arrowX, centerY),
          Offset(arrowX - 6, centerY + 4),
          arrowPaint,
        );
      }

      // Draw input arrow
      canvas.drawLine(
        Offset(x, 80),
        Offset(x, centerY - cellSize / 2),
        Paint()
          ..color = isActive ? Colors.blue : AppColors.cardBorder
          ..strokeWidth = 1.5,
      );

      // Draw output arrow
      canvas.drawLine(
        Offset(x, centerY + cellSize / 2),
        Offset(x, size.height - 120),
        Paint()
          ..color = isActive ? Colors.green : AppColors.cardBorder
          ..strokeWidth = 1.5,
      );
    }
  }

  void _drawLstmCells(
      Canvas canvas, Size size, double padding, double cellWidth) {
    final centerY = size.height / 2;
    final cellSize = 60.0;

    for (int i = 0; i < inputSequence.length; i++) {
      final x = padding + i * cellWidth + cellWidth / 2;

      // Draw LSTM cell
      final cellRect =
          Rect.fromCenter(center: Offset(x, centerY), width: cellSize, height: cellSize);

      final isActive = i < currentStep;
      final isCurrent = i == currentStep - 1;

      // Cell background
      canvas.drawRRect(
        RRect.fromRectAndRadius(cellRect, const Radius.circular(8)),
        Paint()
          ..color = isActive
              ? (isCurrent ? AppColors.accent.withValues(alpha: 0.8) : AppColors.accent.withValues(alpha: 0.3))
              : AppColors.cardBorder.withValues(alpha: 0.5),
      );

      // Draw gate indicators inside cell
      if (isActive && i < forgetGates.length) {
        final gateY = centerY - 15;
        final gateSize = 12.0;

        // Forget gate (red)
        canvas.drawCircle(
          Offset(x - 15, gateY),
          gateSize / 2 * forgetGates[i],
          Paint()..color = Colors.red.withValues(alpha: 0.8),
        );

        // Input gate (blue)
        canvas.drawCircle(
          Offset(x, gateY),
          gateSize / 2 * inputGates[i],
          Paint()..color = Colors.blue.withValues(alpha: 0.8),
        );

        // Output gate (green)
        canvas.drawCircle(
          Offset(x + 15, gateY),
          gateSize / 2 * outputGates[i],
          Paint()..color = Colors.green.withValues(alpha: 0.8),
        );
      }

      // Draw "LSTM" label
      _drawText(canvas, 'LSTM', Offset(x - 14, centerY + 5),
          isActive ? Colors.white : AppColors.muted,
          fontSize: 9);

      // Draw cell state line (top)
      if (i < inputSequence.length - 1) {
        canvas.drawLine(
          Offset(x + cellSize / 2, centerY - 20),
          Offset(x + cellWidth - cellSize / 2, centerY - 20),
          Paint()
            ..color = isActive ? Colors.orange : AppColors.cardBorder
            ..strokeWidth = 2,
        );
      }

      // Draw recurrent connection
      if (i < inputSequence.length - 1) {
        canvas.drawLine(
          Offset(x + cellSize / 2, centerY),
          Offset(x + cellWidth - cellSize / 2, centerY),
          Paint()
            ..color = isActive ? AppColors.accent : AppColors.cardBorder
            ..strokeWidth = 2,
        );
      }

      // Draw input arrow
      canvas.drawLine(
        Offset(x, 80),
        Offset(x, centerY - cellSize / 2),
        Paint()
          ..color = isActive ? Colors.blue : AppColors.cardBorder
          ..strokeWidth = 1.5,
      );

      // Draw output arrow
      canvas.drawLine(
        Offset(x, centerY + cellSize / 2),
        Offset(x, size.height - 120),
        Paint()
          ..color = isActive ? Colors.green : AppColors.cardBorder
          ..strokeWidth = 1.5,
      );
    }

    // Draw legend for LSTM
    final legendY = centerY + cellSize / 2 + 15;
    _drawText(canvas, 'f', Offset(padding, legendY), Colors.red, fontSize: 9);
    _drawText(canvas, isKorean ? '=망각' : '=forget', Offset(padding + 8, legendY),
        AppColors.muted,
        fontSize: 8);
    _drawText(canvas, 'i', Offset(padding + 50, legendY), Colors.blue, fontSize: 9);
    _drawText(canvas, isKorean ? '=입력' : '=input', Offset(padding + 58, legendY),
        AppColors.muted,
        fontSize: 8);
    _drawText(
        canvas, 'o', Offset(padding + 100, legendY), Colors.green, fontSize: 9);
    _drawText(canvas, isKorean ? '=출력' : '=output', Offset(padding + 108, legendY),
        AppColors.muted,
        fontSize: 8);
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color,
      {double fontSize = 12}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _RnnLstmPainter oldDelegate) => true;
}
