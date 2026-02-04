import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Autoencoder Simulation
class AutoencoderScreen extends ConsumerStatefulWidget {
  const AutoencoderScreen({super.key});

  @override
  ConsumerState<AutoencoderScreen> createState() => _AutoencoderScreenState();
}

class _AutoencoderScreenState extends ConsumerState<AutoencoderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  // Input image (8x8)
  List<List<double>> _inputImage = [];

  // Encoder layers
  List<double> _encoded1 = []; // 16 neurons
  List<double> _latentSpace = []; // 4 neurons (bottleneck)

  // Decoder layers
  List<double> _decoded1 = []; // 16 neurons
  List<List<double>> _reconstructed = []; // 8x8 output

  // Training
  bool _isTraining = false;
  int _epoch = 0;
  double _loss = 1.0;
  double _learningRate = 0.1;

  // Weights (simplified)
  List<List<double>> _encoderWeights1 = [];
  List<List<double>> _encoderWeights2 = [];
  List<List<double>> _decoderWeights1 = [];
  List<List<double>> _decoderWeights2 = [];

  // Autoencoder type
  String _aeType = 'standard'; // 'standard', 'denoising', 'variational'
  double _noiseLevel = 0.2;

  @override
  void initState() {
    super.initState();
    _initializeNetwork();
    _generateInput();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_train);
  }

  void _initializeNetwork() {
    // Xavier initialization
    final scale1 = math.sqrt(2.0 / 80); // 64 + 16
    final scale2 = math.sqrt(2.0 / 20); // 16 + 4

    _encoderWeights1 = List.generate(
      16,
      (_) => List.generate(64, (_) => (_random.nextDouble() - 0.5) * 2 * scale1),
    );
    _encoderWeights2 = List.generate(
      4,
      (_) => List.generate(16, (_) => (_random.nextDouble() - 0.5) * 2 * scale2),
    );
    _decoderWeights1 = List.generate(
      16,
      (_) => List.generate(4, (_) => (_random.nextDouble() - 0.5) * 2 * scale2),
    );
    _decoderWeights2 = List.generate(
      64,
      (_) => List.generate(16, (_) => (_random.nextDouble() - 0.5) * 2 * scale1),
    );

    _encoded1 = List.filled(16, 0.0);
    _latentSpace = List.filled(4, 0.0);
    _decoded1 = List.filled(16, 0.0);
    _reconstructed = List.generate(8, (_) => List.filled(8, 0.0));
  }

  void _generateInput() {
    // Generate a simple pattern
    _inputImage = List.generate(8, (i) {
      return List.generate(8, (j) {
        // Create a diagonal pattern
        if ((i + j) % 4 < 2) return 1.0;
        return 0.0;
      });
    });
    _epoch = 0;
    _loss = 1.0;
    _forward();
  }

  List<double> _flatten(List<List<double>> matrix) {
    return matrix.expand((row) => row).toList();
  }

  List<List<double>> _unflatten(List<double> vector, int rows, int cols) {
    return List.generate(rows, (i) {
      return List.generate(cols, (j) => vector[i * cols + j]);
    });
  }

  double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x.clamp(-500, 500)));
  double _relu(double x) => math.max(0, x);

  void _forward() {
    // Flatten input
    List<double> input = _flatten(_inputImage);

    // Add noise for denoising autoencoder
    if (_aeType == 'denoising') {
      input = input.map((v) {
        return (v + (_random.nextDouble() - 0.5) * 2 * _noiseLevel).clamp(0.0, 1.0);
      }).toList();
    }

    // Encoder layer 1
    _encoded1 = List.generate(16, (i) {
      double sum = 0;
      for (int j = 0; j < 64; j++) {
        sum += input[j] * _encoderWeights1[i][j];
      }
      return _relu(sum);
    });

    // Latent space (encoder layer 2)
    _latentSpace = List.generate(4, (i) {
      double sum = 0;
      for (int j = 0; j < 16; j++) {
        sum += _encoded1[j] * _encoderWeights2[i][j];
      }
      if (_aeType == 'variational') {
        // Add random noise for VAE
        sum += _random.nextGaussian() * 0.1;
      }
      return _sigmoid(sum);
    });

    // Decoder layer 1
    _decoded1 = List.generate(16, (i) {
      double sum = 0;
      for (int j = 0; j < 4; j++) {
        sum += _latentSpace[j] * _decoderWeights1[i][j];
      }
      return _relu(sum);
    });

    // Output layer (decoder layer 2)
    final output = List.generate(64, (i) {
      double sum = 0;
      for (int j = 0; j < 16; j++) {
        sum += _decoded1[j] * _decoderWeights2[i][j];
      }
      return _sigmoid(sum);
    });

    _reconstructed = _unflatten(output, 8, 8);

    // Calculate reconstruction loss
    final original = _flatten(_inputImage);
    double mse = 0;
    for (int i = 0; i < 64; i++) {
      mse += math.pow(original[i] - output[i], 2);
    }
    _loss = _loss * 0.95 + (mse / 64) * 0.05;
  }

  void _train() {
    if (!_isTraining) return;

    setState(() {
      // Simple gradient descent update
      final original = _flatten(_inputImage);
      final reconstructedFlat = _flatten(_reconstructed);

      // Calculate error
      final errors = List.generate(64, (i) => original[i] - reconstructedFlat[i]);

      // Update decoder weights (simplified backprop)
      for (int i = 0; i < 64; i++) {
        for (int j = 0; j < 16; j++) {
          _decoderWeights2[i][j] += _learningRate * errors[i] * _decoded1[j] * 0.01;
        }
      }

      // Update encoder weights
      for (int i = 0; i < 16; i++) {
        double delta = 0;
        for (int j = 0; j < 64; j++) {
          delta += errors[j] * _decoderWeights2[j][i];
        }
        for (int j = 0; j < 64; j++) {
          _encoderWeights1[i][j] += _learningRate * delta * original[j] * 0.001;
        }
      }

      _forward();
      _epoch++;
    });
  }

  void _toggleTraining() {
    HapticFeedback.selectionClick();
    setState(() {
      _isTraining = !_isTraining;
      if (_isTraining) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _setPattern(String pattern) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (pattern) {
        case 'diagonal':
          _inputImage = List.generate(8, (i) {
            return List.generate(8, (j) => (i + j) % 4 < 2 ? 1.0 : 0.0);
          });
          break;
        case 'cross':
          _inputImage = List.generate(8, (i) {
            return List.generate(8, (j) {
              if (i == 3 || i == 4 || j == 3 || j == 4) return 1.0;
              return 0.0;
            });
          });
          break;
        case 'circle':
          _inputImage = List.generate(8, (i) {
            return List.generate(8, (j) {
              final dist = math.sqrt(math.pow(i - 3.5, 2) + math.pow(j - 3.5, 2));
              return dist < 3 ? 1.0 : 0.0;
            });
          });
          break;
        case 'random':
          _inputImage = List.generate(8, (i) {
            return List.generate(8, (j) => _random.nextDouble() > 0.5 ? 1.0 : 0.0);
          });
          break;
      }
      _forward();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      _isTraining = false;
      _initializeNetwork();
      _generateInput();
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
              isKorean ? '오토인코더' : 'Autoencoder',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '딥러닝' : 'Deep Learning',
          title: isKorean ? '오토인코더' : 'Autoencoder',
          formula: 'L = ||x - D(E(x))||^2',
          formulaDescription: isKorean
              ? '입력을 압축(인코딩)한 후 복원(디코딩)하여 특징을 학습'
              : 'Learn features by compressing (encoding) and reconstructing (decoding) input',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _AutoencoderPainter(
                inputImage: _inputImage,
                encoded1: _encoded1,
                latentSpace: _latentSpace,
                decoded1: _decoded1,
                reconstructed: _reconstructed,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Autoencoder type selection
              SimSegment<String>(
                label: isKorean ? '오토인코더 타입' : 'Autoencoder Type',
                options: {
                  'standard': isKorean ? '표준' : 'Standard',
                  'denoising': isKorean ? '디노이징' : 'Denoising',
                  'variational': 'VAE',
                },
                selected: _aeType,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _aeType = v;
                    _forward();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Stats display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _loss < 0.1
                      ? Colors.green.withValues(alpha: 0.1)
                      : AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _loss < 0.1 ? Colors.green : AppColors.cardBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Epoch',
                      value: '$_epoch',
                      color: Colors.blue,
                    ),
                    _StatItem(
                      label: isKorean ? '재구성 손실' : 'Recon Loss',
                      value: _loss.toStringAsFixed(4),
                      color: _loss < 0.1 ? Colors.green : AppColors.accent,
                    ),
                    _StatItem(
                      label: isKorean ? '잠재 차원' : 'Latent Dim',
                      value: '4',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Input pattern selection
              PresetGroup(
                label: isKorean ? '입력 패턴' : 'Input Pattern',
                presets: [
                  PresetButton(
                    label: isKorean ? '대각선' : 'Diagonal',
                    isSelected: false,
                    onPressed: () => _setPattern('diagonal'),
                  ),
                  PresetButton(
                    label: isKorean ? '십자' : 'Cross',
                    isSelected: false,
                    onPressed: () => _setPattern('cross'),
                  ),
                  PresetButton(
                    label: isKorean ? '원' : 'Circle',
                    isSelected: false,
                    onPressed: () => _setPattern('circle'),
                  ),
                  PresetButton(
                    label: isKorean ? '랜덤' : 'Random',
                    isSelected: false,
                    onPressed: () => _setPattern('random'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Learning rate slider
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '학습률' : 'Learning Rate',
                  value: _learningRate,
                  min: 0.01,
                  max: 0.5,
                  defaultValue: 0.1,
                  formatValue: (v) => v.toStringAsFixed(2),
                  onChanged: (v) => setState(() => _learningRate = v),
                ),
              ),

              // Latent space visualization
              const SizedBox(height: 16),
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
                      isKorean ? '잠재 공간 (Latent Space)' : 'Latent Space',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(_latentSpace.length, (i) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(
                                        alpha: _latentSpace[i].clamp(0.1, 1.0)),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.purple),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _latentSpace[i].toStringAsFixed(2),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'z$i',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isTraining
                    ? (isKorean ? '정지' : 'Stop')
                    : (isKorean ? '학습' : 'Train'),
                icon: _isTraining ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleTraining,
              ),
              SimButton(
                label: isKorean ? '순전파' : 'Forward',
                icon: Icons.arrow_forward,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _forward());
                },
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
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
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

class _AutoencoderPainter extends CustomPainter {
  final List<List<double>> inputImage;
  final List<double> encoded1;
  final List<double> latentSpace;
  final List<double> decoded1;
  final List<List<double>> reconstructed;
  final bool isKorean;

  _AutoencoderPainter({
    required this.inputImage,
    required this.encoded1,
    required this.latentSpace,
    required this.decoded1,
    required this.reconstructed,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 20.0;
    final imageSize = 80.0;
    final layerHeight = 150.0;

    // Draw input image
    _drawImage(
      canvas,
      inputImage,
      Offset(padding, size.height / 2 - imageSize / 2),
      imageSize,
      isKorean ? '입력' : 'Input',
      Colors.blue,
    );

    // Draw encoder layer 1
    _drawLayer(
      canvas,
      encoded1,
      Offset(padding + imageSize + 30, 40),
      20,
      layerHeight,
      'E1 (16)',
      AppColors.accent,
    );

    // Draw latent space
    _drawLayer(
      canvas,
      latentSpace,
      Offset(size.width / 2 - 15, 80),
      30,
      100,
      isKorean ? '잠재(4)' : 'Latent(4)',
      Colors.purple,
    );

    // Draw decoder layer 1
    _drawLayer(
      canvas,
      decoded1,
      Offset(size.width - padding - imageSize - 60, 40),
      20,
      layerHeight,
      'D1 (16)',
      Colors.green,
    );

    // Draw reconstructed image
    _drawImage(
      canvas,
      reconstructed,
      Offset(size.width - padding - imageSize, size.height / 2 - imageSize / 2),
      imageSize,
      isKorean ? '복원' : 'Reconstructed',
      Colors.green,
    );

    // Draw arrows
    final arrowPaint = Paint()
      ..color = AppColors.muted
      ..strokeWidth = 1.5;

    // Input -> E1
    canvas.drawLine(
      Offset(padding + imageSize + 5, size.height / 2),
      Offset(padding + imageSize + 25, size.height / 2),
      arrowPaint,
    );

    // E1 -> Latent
    canvas.drawLine(
      Offset(padding + imageSize + 55, size.height / 2),
      Offset(size.width / 2 - 20, size.height / 2),
      arrowPaint,
    );

    // Latent -> D1
    canvas.drawLine(
      Offset(size.width / 2 + 20, size.height / 2),
      Offset(size.width - padding - imageSize - 65, size.height / 2),
      arrowPaint,
    );

    // D1 -> Output
    canvas.drawLine(
      Offset(size.width - padding - imageSize - 35, size.height / 2),
      Offset(size.width - padding - imageSize - 5, size.height / 2),
      arrowPaint,
    );

    // Labels
    _drawText(canvas, isKorean ? '인코더' : 'Encoder',
        Offset(padding + imageSize + 40, 20), AppColors.accent,
        fontSize: 10, fontWeight: FontWeight.bold);
    _drawText(canvas, isKorean ? '디코더' : 'Decoder',
        Offset(size.width - padding - imageSize - 70, 20), Colors.green,
        fontSize: 10, fontWeight: FontWeight.bold);
  }

  void _drawImage(
    Canvas canvas,
    List<List<double>> image,
    Offset origin,
    double size,
    String label,
    Color borderColor,
  ) {
    if (image.isEmpty) return;

    final cellSize = size / image.length;

    for (int i = 0; i < image.length; i++) {
      for (int j = 0; j < image[i].length; j++) {
        final x = origin.dx + j * cellSize;
        final y = origin.dy + i * cellSize;
        final value = image[i][j].clamp(0.0, 1.0);

        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize - 0.5, cellSize - 0.5),
          Paint()..color = Color.lerp(Colors.black, Colors.white, value)!,
        );
      }
    }

    // Border
    canvas.drawRect(
      Rect.fromLTWH(origin.dx, origin.dy, size, size),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Label
    _drawText(canvas, label, Offset(origin.dx, origin.dy + size + 5), borderColor,
        fontSize: 10);
  }

  void _drawLayer(
    Canvas canvas,
    List<double> neurons,
    Offset origin,
    double width,
    double height,
    String label,
    Color color,
  ) {
    if (neurons.isEmpty) return;

    final neuronHeight = height / neurons.length;

    for (int i = 0; i < neurons.length; i++) {
      final y = origin.dy + i * neuronHeight;
      final value = neurons[i].clamp(0.0, 1.0);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(origin.dx, y, width, neuronHeight - 2),
          const Radius.circular(3),
        ),
        Paint()..color = color.withValues(alpha: value.clamp(0.2, 1.0)),
      );
    }

    // Label
    _drawText(canvas, label, Offset(origin.dx - 5, origin.dy + height + 5), color,
        fontSize: 9);
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
  bool shouldRepaint(covariant _AutoencoderPainter oldDelegate) => true;
}

// Extension for random gaussian
extension RandomExtension on math.Random {
  double nextGaussian() {
    double u1 = nextDouble();
    double u2 = nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }
}
