import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Transformer Architecture Simulation
class TransformerScreen extends ConsumerStatefulWidget {
  const TransformerScreen({super.key});

  @override
  ConsumerState<TransformerScreen> createState() => _TransformerScreenState();
}

class _TransformerScreenState extends ConsumerState<TransformerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  // Input tokens
  List<String> _inputTokens = ['The', 'cat', 'sat', 'on', 'mat'];
  List<String> _outputTokens = ['Le', 'chat', 'assis', 'sur', 'tapis'];

  // Embeddings (simplified 4D)
  List<List<double>> _inputEmbeddings = [];
  List<List<double>> _outputEmbeddings = [];

  // Attention weights
  List<List<double>> _selfAttentionWeights = [];
  List<List<double>> _crossAttentionWeights = [];

  // Parameters
  final int _embeddingDim = 4;
  final int _numHeads = 2;
  int _currentLayer = 0;
  int _currentHead = 0;
  bool _isAnimating = false;
  String _viewMode = 'architecture'; // 'architecture', 'attention', 'embedding'

  @override
  void initState() {
    super.initState();
    _initializeModel();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(_animate);
  }

  void _initializeModel() {
    // Initialize random embeddings
    _inputEmbeddings = _inputTokens
        .map((_) => List.generate(_embeddingDim, (_) => _random.nextDouble()))
        .toList();
    _outputEmbeddings = _outputTokens
        .map((_) => List.generate(_embeddingDim, (_) => _random.nextDouble()))
        .toList();

    // Compute self-attention weights (softmax of Q*K^T)
    _computeAttentionWeights();
  }

  void _computeAttentionWeights() {
    final n = _inputTokens.length;

    // Self-attention for encoder
    _selfAttentionWeights = List.generate(n, (i) {
      final row = List.generate(n, (j) {
        double dot = 0;
        for (int k = 0; k < _embeddingDim; k++) {
          dot += _inputEmbeddings[i][k] * _inputEmbeddings[j][k];
        }
        return math.exp(dot / math.sqrt(_embeddingDim));
      });
      final sum = row.reduce((a, b) => a + b);
      return row.map((v) => v / sum).toList();
    });

    // Cross-attention (decoder attending to encoder)
    _crossAttentionWeights = List.generate(_outputTokens.length, (i) {
      final row = List.generate(n, (j) {
        double dot = 0;
        for (int k = 0; k < _embeddingDim; k++) {
          dot += _outputEmbeddings[i][k] * _inputEmbeddings[j][k];
        }
        return math.exp(dot / math.sqrt(_embeddingDim));
      });
      final sum = row.reduce((a, b) => a + b);
      return row.map((v) => v / sum).toList();
    });
  }

  void _animate() {
    if (!_isAnimating) return;

    setState(() {
      _currentHead = (_currentHead + 1) % _numHeads;
      if (_currentHead == 0) {
        _currentLayer = (_currentLayer + 1) % 3;
      }
    });
  }

  void _startAnimation() {
    HapticFeedback.selectionClick();
    setState(() {
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

  void _shuffleAttention() {
    HapticFeedback.mediumImpact();
    setState(() {
      _inputEmbeddings = _inputTokens
          .map((_) => List.generate(_embeddingDim, (_) => _random.nextDouble()))
          .toList();
      _outputEmbeddings = _outputTokens
          .map((_) => List.generate(_embeddingDim, (_) => _random.nextDouble()))
          .toList();
      _computeAttentionWeights();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      _isAnimating = false;
      _currentLayer = 0;
      _currentHead = 0;
      _initializeModel();
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
              isKorean ? '트랜스포머 아키텍처' : 'Transformer Architecture',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '딥러닝' : 'Deep Learning',
          title: isKorean ? '트랜스포머 아키텍처' : 'Transformer Architecture',
          formula: 'Attention(Q,K,V) = softmax(QK^T/sqrt(d_k))V',
          formulaDescription: isKorean
              ? '셀프 어텐션 메커니즘을 통해 시퀀스의 모든 위치를 동시에 처리'
              : 'Self-attention mechanism processes all positions simultaneously',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _TransformerPainter(
                inputTokens: _inputTokens,
                outputTokens: _outputTokens,
                selfAttentionWeights: _selfAttentionWeights,
                crossAttentionWeights: _crossAttentionWeights,
                currentLayer: _currentLayer,
                currentHead: _currentHead,
                viewMode: _viewMode,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // View mode selection
              SimSegment<String>(
                label: isKorean ? '뷰 모드' : 'View Mode',
                options: {
                  'architecture': isKorean ? '아키텍처' : 'Architecture',
                  'attention': isKorean ? '어텐션' : 'Attention',
                },
                selected: _viewMode,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _viewMode = v);
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
                          label: isKorean ? '임베딩 차원' : 'Embed Dim',
                          value: '$_embeddingDim',
                          color: Colors.blue,
                        ),
                        _StatItem(
                          label: isKorean ? '어텐션 헤드' : 'Num Heads',
                          value: '$_numHeads',
                          color: AppColors.accent,
                        ),
                        _StatItem(
                          label: isKorean ? '현재 레이어' : 'Current Layer',
                          value: '${_currentLayer + 1} / 3',
                          color: Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: isKorean ? '입력 토큰' : 'Input Tokens',
                          value: '${_inputTokens.length}',
                          color: Colors.orange,
                        ),
                        _StatItem(
                          label: isKorean ? '출력 토큰' : 'Output Tokens',
                          value: '${_outputTokens.length}',
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Preset sentences
              PresetGroup(
                label: isKorean ? '예제 문장' : 'Example Sentences',
                presets: [
                  PresetButton(
                    label: isKorean ? '영어->프랑스어' : 'EN->FR',
                    isSelected: _inputTokens[0] == 'The',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _inputTokens = ['The', 'cat', 'sat', 'on', 'mat'];
                        _outputTokens = ['Le', 'chat', 'assis', 'sur', 'tapis'];
                        _initializeModel();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '한국어->영어' : 'KO->EN',
                    isSelected: _inputTokens[0] == '나는',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _inputTokens = ['나는', '학교에', '간다'];
                        _outputTokens = ['I', 'go', 'to', 'school'];
                        _initializeModel();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '짧은 문장' : 'Short',
                    isSelected: _inputTokens.length == 3 && _inputTokens[0] == 'Hello',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _inputTokens = ['Hello', 'world', '!'];
                        _outputTokens = ['Bonjour', 'monde', '!'];
                        _initializeModel();
                      });
                    },
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
                    : (isKorean ? '애니메이션' : 'Animate'),
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _isAnimating ? _stopAnimation : _startAnimation,
              ),
              SimButton(
                label: isKorean ? '셔플' : 'Shuffle',
                icon: Icons.shuffle,
                onPressed: _shuffleAttention,
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
          ),
        ),
      ],
    );
  }
}

class _TransformerPainter extends CustomPainter {
  final List<String> inputTokens;
  final List<String> outputTokens;
  final List<List<double>> selfAttentionWeights;
  final List<List<double>> crossAttentionWeights;
  final int currentLayer;
  final int currentHead;
  final String viewMode;
  final bool isKorean;

  _TransformerPainter({
    required this.inputTokens,
    required this.outputTokens,
    required this.selfAttentionWeights,
    required this.crossAttentionWeights,
    required this.currentLayer,
    required this.currentHead,
    required this.viewMode,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (viewMode == 'architecture') {
      _drawArchitecture(canvas, size);
    } else {
      _drawAttentionMatrix(canvas, size);
    }
  }

  void _drawArchitecture(Canvas canvas, Size size) {
    final padding = 20.0;
    final encoderX = size.width * 0.25;
    final decoderX = size.width * 0.75;
    final blockHeight = 45.0;
    final blockWidth = 100.0;

    // Draw input tokens
    _drawTokens(canvas, inputTokens, Offset(encoderX - blockWidth / 2, size.height - 40),
        blockWidth / inputTokens.length, Colors.blue);

    // Draw output tokens
    _drawTokens(canvas, outputTokens, Offset(decoderX - blockWidth / 2, size.height - 40),
        blockWidth / outputTokens.length, Colors.purple);

    // Encoder blocks
    _drawText(canvas, isKorean ? '인코더' : 'Encoder', Offset(encoderX - 25, padding),
        AppColors.ink,
        fontSize: 12, fontWeight: FontWeight.bold);

    for (int i = 0; i < 3; i++) {
      final y = padding + 30 + i * (blockHeight + 20);
      final isActive = i == currentLayer;

      // Multi-head attention
      _drawBlock(
        canvas,
        Offset(encoderX - blockWidth / 2, y),
        blockWidth,
        blockHeight / 2,
        isKorean ? '멀티헤드\n어텐션' : 'Multi-Head\nAttention',
        isActive ? AppColors.accent : AppColors.cardBorder,
        isActive,
      );

      // Feed forward
      _drawBlock(
        canvas,
        Offset(encoderX - blockWidth / 2, y + blockHeight / 2 + 5),
        blockWidth,
        blockHeight / 2,
        isKorean ? '피드포워드' : 'Feed Forward',
        isActive ? Colors.green : AppColors.cardBorder,
        isActive,
      );
    }

    // Decoder blocks
    _drawText(canvas, isKorean ? '디코더' : 'Decoder', Offset(decoderX - 25, padding),
        AppColors.ink,
        fontSize: 12, fontWeight: FontWeight.bold);

    for (int i = 0; i < 3; i++) {
      final y = padding + 30 + i * (blockHeight + 20);
      final isActive = i == currentLayer;

      // Masked self-attention
      _drawBlock(
        canvas,
        Offset(decoderX - blockWidth / 2, y),
        blockWidth,
        blockHeight / 3,
        isKorean ? '마스크드\n셀프어텐션' : 'Masked\nSelf-Attn',
        isActive ? Colors.orange : AppColors.cardBorder,
        isActive,
      );

      // Cross-attention
      _drawBlock(
        canvas,
        Offset(decoderX - blockWidth / 2, y + blockHeight / 3 + 3),
        blockWidth,
        blockHeight / 3,
        isKorean ? '크로스\n어텐션' : 'Cross\nAttention',
        isActive ? AppColors.accent : AppColors.cardBorder,
        isActive,
      );

      // Feed forward
      _drawBlock(
        canvas,
        Offset(decoderX - blockWidth / 2, y + (blockHeight / 3) * 2 + 6),
        blockWidth,
        blockHeight / 3,
        isKorean ? '피드포워드' : 'FFN',
        isActive ? Colors.green : AppColors.cardBorder,
        isActive,
      );

      // Cross-attention arrow
      if (isActive) {
        canvas.drawLine(
          Offset(encoderX + blockWidth / 2, y + blockHeight / 2),
          Offset(decoderX - blockWidth / 2, y + blockHeight / 2),
          Paint()
            ..color = AppColors.accent
            ..strokeWidth = 2,
        );
      }
    }

    // Labels
    _drawText(canvas, isKorean ? '입력' : 'Input',
        Offset(encoderX - 15, size.height - 20), Colors.blue,
        fontSize: 10);
    _drawText(canvas, isKorean ? '출력' : 'Output',
        Offset(decoderX - 15, size.height - 20), Colors.purple,
        fontSize: 10);
  }

  void _drawAttentionMatrix(Canvas canvas, Size size) {
    final padding = 30.0;
    final matrixSize = math.min(size.width - padding * 2, size.height - 100) * 0.45;
    final selfMatrixX = padding;
    final crossMatrixX = size.width / 2 + padding / 2;
    final matrixY = 50.0;

    // Self-attention matrix
    _drawText(canvas, isKorean ? '셀프 어텐션' : 'Self-Attention',
        Offset(selfMatrixX, 20), AppColors.ink,
        fontSize: 11, fontWeight: FontWeight.bold);

    if (selfAttentionWeights.isNotEmpty) {
      _drawMatrix(
        canvas,
        selfAttentionWeights,
        Offset(selfMatrixX, matrixY),
        matrixSize,
        inputTokens,
        inputTokens,
        AppColors.accent,
      );
    }

    // Cross-attention matrix
    _drawText(canvas, isKorean ? '크로스 어텐션' : 'Cross-Attention',
        Offset(crossMatrixX, 20), AppColors.ink,
        fontSize: 11, fontWeight: FontWeight.bold);

    if (crossAttentionWeights.isNotEmpty) {
      _drawMatrix(
        canvas,
        crossAttentionWeights,
        Offset(crossMatrixX, matrixY),
        matrixSize,
        inputTokens,
        outputTokens,
        Colors.purple,
      );
    }

    // Legend
    final legendY = size.height - 30;
    _drawText(canvas, isKorean ? '밝음 = 높은 어텐션' : 'Bright = High Attention',
        Offset(size.width / 2 - 60, legendY), AppColors.muted,
        fontSize: 10);
  }

  void _drawMatrix(
    Canvas canvas,
    List<List<double>> weights,
    Offset origin,
    double size,
    List<String> colLabels,
    List<String> rowLabels,
    Color color,
  ) {
    final cellWidth = size / colLabels.length;
    final cellHeight = size / rowLabels.length;

    for (int i = 0; i < rowLabels.length; i++) {
      for (int j = 0; j < colLabels.length; j++) {
        final x = origin.dx + j * cellWidth;
        final y = origin.dy + i * cellHeight;
        final weight = i < weights.length && j < weights[i].length
            ? weights[i][j]
            : 0.0;

        canvas.drawRect(
          Rect.fromLTWH(x, y, cellWidth - 1, cellHeight - 1),
          Paint()..color = color.withValues(alpha: weight.clamp(0.1, 1.0)),
        );
      }
    }

    // Column labels (top)
    for (int j = 0; j < colLabels.length; j++) {
      final label = colLabels[j].length > 4
          ? '${colLabels[j].substring(0, 3)}..'
          : colLabels[j];
      _drawText(
        canvas,
        label,
        Offset(origin.dx + j * cellWidth + 2, origin.dy - 15),
        AppColors.muted,
        fontSize: 8,
      );
    }

    // Row labels (left)
    for (int i = 0; i < rowLabels.length; i++) {
      final label = rowLabels[i].length > 4
          ? '${rowLabels[i].substring(0, 3)}..'
          : rowLabels[i];
      _drawText(
        canvas,
        label,
        Offset(origin.dx - 30, origin.dy + i * cellHeight + cellHeight / 2 - 5),
        AppColors.muted,
        fontSize: 8,
      );
    }
  }

  void _drawBlock(
    Canvas canvas,
    Offset position,
    double width,
    double height,
    String label,
    Color color,
    bool isActive,
  ) {
    final rect = Rect.fromLTWH(position.dx, position.dy, width, height);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = isActive ? color.withValues(alpha: 0.8) : color.withValues(alpha: 0.3),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 2 : 1,
    );

    // Draw label (handle multi-line)
    final lines = label.split('\n');
    final lineHeight = 10.0;
    final startY = position.dy + height / 2 - (lines.length * lineHeight) / 2;

    for (int i = 0; i < lines.length; i++) {
      _drawText(
        canvas,
        lines[i],
        Offset(position.dx + width / 2 - lines[i].length * 2.5,
            startY + i * lineHeight),
        isActive ? Colors.white : AppColors.muted,
        fontSize: 8,
      );
    }
  }

  void _drawTokens(
    Canvas canvas,
    List<String> tokens,
    Offset origin,
    double tokenWidth,
    Color color,
  ) {
    for (int i = 0; i < tokens.length; i++) {
      final x = origin.dx + i * tokenWidth;
      final label =
          tokens[i].length > 3 ? '${tokens[i].substring(0, 2)}..' : tokens[i];
      _drawText(canvas, label, Offset(x, origin.dy), color, fontSize: 9);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color,
      {double fontSize = 12, FontWeight fontWeight = FontWeight.normal}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _TransformerPainter oldDelegate) => true;
}
