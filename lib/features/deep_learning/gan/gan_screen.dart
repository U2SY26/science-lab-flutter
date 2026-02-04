import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Generative Adversarial Network Simulation
class GanScreen extends ConsumerStatefulWidget {
  const GanScreen({super.key});

  @override
  ConsumerState<GanScreen> createState() => _GanScreenState();
}

class _GanScreenState extends ConsumerState<GanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  // Generator network
  List<double> _noiseVector = [];
  List<double> _generatorHidden = [];
  List<List<double>> _generatedImage = [];

  // Discriminator network
  List<double> _discriminatorHidden = [];
  double _discriminatorOutput = 0.5;

  // Real data samples
  List<List<double>> _realImage = [];

  // Training state
  bool _isTraining = false;
  int _epoch = 0;
  double _generatorLoss = 1.0;
  double _discriminatorLoss = 1.0;
  double _learningRate = 0.1;

  // Weights
  List<List<double>> _genWeights1 = [];
  List<List<double>> _genWeights2 = [];
  List<List<double>> _discWeights1 = [];
  List<double> _discWeights2 = [];

  // Parameters
  final int _noiseSize = 4;
  final int _hiddenSize = 16;
  final int _imageSize = 6;

  // Mode
  bool _showReal = true;

  @override
  void initState() {
    super.initState();
    _initializeNetworks();
    _generateRealData();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(_train);
  }

  void _initializeNetworks() {
    final scale1 = math.sqrt(2.0 / (_noiseSize + _hiddenSize));
    final scale2 = math.sqrt(2.0 / (_hiddenSize + _imageSize * _imageSize));

    // Generator weights
    _genWeights1 = List.generate(
      _hiddenSize,
      (_) => List.generate(_noiseSize, (_) => (_random.nextDouble() - 0.5) * 2 * scale1),
    );
    _genWeights2 = List.generate(
      _imageSize * _imageSize,
      (_) => List.generate(_hiddenSize, (_) => (_random.nextDouble() - 0.5) * 2 * scale2),
    );

    // Discriminator weights
    _discWeights1 = List.generate(
      _hiddenSize,
      (_) => List.generate(_imageSize * _imageSize, (_) => (_random.nextDouble() - 0.5) * 2 * scale2),
    );
    _discWeights2 = List.generate(_hiddenSize, (_) => (_random.nextDouble() - 0.5) * 2 * scale1);

    _noiseVector = List.filled(_noiseSize, 0.0);
    _generatorHidden = List.filled(_hiddenSize, 0.0);
    _discriminatorHidden = List.filled(_hiddenSize, 0.0);
    _generatedImage = List.generate(_imageSize, (_) => List.filled(_imageSize, 0.0));
  }

  void _generateRealData() {
    // Create a simple pattern (e.g., horizontal stripes)
    _realImage = List.generate(_imageSize, (i) {
      return List.generate(_imageSize, (j) {
        return i % 2 == 0 ? 1.0 : 0.0;
      });
    });
  }

  double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x.clamp(-500, 500)));
  double _leakyRelu(double x) => x > 0 ? x : 0.01 * x;

  void _sampleNoise() {
    _noiseVector = List.generate(_noiseSize, (_) => _random.nextDouble() * 2 - 1);
  }

  void _runGenerator() {
    // Hidden layer
    _generatorHidden = List.generate(_hiddenSize, (i) {
      double sum = 0;
      for (int j = 0; j < _noiseSize; j++) {
        sum += _noiseVector[j] * _genWeights1[i][j];
      }
      return _leakyRelu(sum);
    });

    // Output layer
    final flatOutput = List.generate(_imageSize * _imageSize, (i) {
      double sum = 0;
      for (int j = 0; j < _hiddenSize; j++) {
        sum += _generatorHidden[j] * _genWeights2[i][j];
      }
      return _sigmoid(sum);
    });

    // Reshape to image
    _generatedImage = List.generate(_imageSize, (i) {
      return List.generate(_imageSize, (j) => flatOutput[i * _imageSize + j]);
    });
  }

  double _runDiscriminator(List<List<double>> image) {
    // Flatten image
    final flatImage = image.expand((row) => row).toList();

    // Hidden layer
    _discriminatorHidden = List.generate(_hiddenSize, (i) {
      double sum = 0;
      for (int j = 0; j < _imageSize * _imageSize; j++) {
        sum += flatImage[j] * _discWeights1[i][j];
      }
      return _leakyRelu(sum);
    });

    // Output layer
    double output = 0;
    for (int i = 0; i < _hiddenSize; i++) {
      output += _discriminatorHidden[i] * _discWeights2[i];
    }
    return _sigmoid(output);
  }

  void _train() {
    if (!_isTraining) return;

    setState(() {
      // Sample noise and generate fake image
      _sampleNoise();
      _runGenerator();

      // Discriminator on real data
      final realPred = _runDiscriminator(_realImage);

      // Discriminator on fake data
      final fakePred = _runDiscriminator(_generatedImage);

      // Calculate losses
      _discriminatorLoss = -math.log(realPred.clamp(0.0001, 0.9999)) -
          math.log((1 - fakePred).clamp(0.0001, 0.9999));
      _generatorLoss = -math.log(fakePred.clamp(0.0001, 0.9999));

      // Update discriminator weights
      final discError = (realPred - 1) + fakePred;
      for (int i = 0; i < _hiddenSize; i++) {
        _discWeights2[i] -= _learningRate * discError * _discriminatorHidden[i] * 0.1;
        for (int j = 0; j < _imageSize * _imageSize; j++) {
          final realFlat = _realImage.expand((r) => r).toList();
          _discWeights1[i][j] -= _learningRate * discError * realFlat[j] * 0.01;
        }
      }

      // Update generator weights (to fool discriminator)
      final genError = fakePred - 1; // Want fakePred to be 1
      for (int i = 0; i < _imageSize * _imageSize; i++) {
        for (int j = 0; j < _hiddenSize; j++) {
          _genWeights2[i][j] -= _learningRate * genError * _generatorHidden[j] * 0.1;
        }
      }
      for (int i = 0; i < _hiddenSize; i++) {
        for (int j = 0; j < _noiseSize; j++) {
          _genWeights1[i][j] -= _learningRate * genError * _noiseVector[j] * 0.01;
        }
      }

      _discriminatorOutput = fakePred;
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

  void _generateOnce() {
    HapticFeedback.lightImpact();
    setState(() {
      _sampleNoise();
      _runGenerator();
      _discriminatorOutput = _runDiscriminator(_generatedImage);
    });
  }

  void _setPattern(String pattern) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (pattern) {
        case 'stripes_h':
          _realImage = List.generate(_imageSize, (i) {
            return List.generate(_imageSize, (j) => i % 2 == 0 ? 1.0 : 0.0);
          });
          break;
        case 'stripes_v':
          _realImage = List.generate(_imageSize, (i) {
            return List.generate(_imageSize, (j) => j % 2 == 0 ? 1.0 : 0.0);
          });
          break;
        case 'checker':
          _realImage = List.generate(_imageSize, (i) {
            return List.generate(_imageSize, (j) => (i + j) % 2 == 0 ? 1.0 : 0.0);
          });
          break;
        case 'cross':
          _realImage = List.generate(_imageSize, (i) {
            return List.generate(_imageSize, (j) {
              if (i == _imageSize ~/ 2 || j == _imageSize ~/ 2) return 1.0;
              return 0.0;
            });
          });
          break;
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      _isTraining = false;
      _epoch = 0;
      _generatorLoss = 1.0;
      _discriminatorLoss = 1.0;
      _initializeNetworks();
      _generateRealData();
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
              isKorean ? '생성적 적대 신경망 (GAN)' : 'Generative Adversarial Network',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '딥러닝' : 'Deep Learning',
          title: 'GAN',
          formula: 'min_G max_D V(D,G) = E[log D(x)] + E[log(1-D(G(z)))]',
          formulaDescription: isKorean
              ? '생성자(G)와 판별자(D)가 경쟁하며 학습하는 적대적 네트워크'
              : 'Generator and Discriminator compete in adversarial training',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _GanPainter(
                noiseVector: _noiseVector,
                generatorHidden: _generatorHidden,
                generatedImage: _generatedImage,
                realImage: _realImage,
                discriminatorHidden: _discriminatorHidden,
                discriminatorOutput: _discriminatorOutput,
                showReal: _showReal,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mode toggle
              SimToggle(
                label: isKorean ? '실제 이미지 표시' : 'Show Real Image',
                value: _showReal,
                onChanged: (v) => setState(() => _showReal = v),
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
                          label: 'Epoch',
                          value: '$_epoch',
                          color: Colors.blue,
                        ),
                        _StatItem(
                          label: isKorean ? '생성자 손실' : 'G Loss',
                          value: _generatorLoss.toStringAsFixed(3),
                          color: Colors.green,
                        ),
                        _StatItem(
                          label: isKorean ? '판별자 손실' : 'D Loss',
                          value: _discriminatorLoss.toStringAsFixed(3),
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Discriminator confidence bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKorean
                              ? '판별자 출력 (가짜일 확률: ${(1 - _discriminatorOutput).toStringAsFixed(2)})'
                              : 'Discriminator Output (Fake prob: ${(1 - _discriminatorOutput).toStringAsFixed(2)})',
                          style: const TextStyle(color: AppColors.muted, fontSize: 10),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _discriminatorOutput.clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red, Colors.green],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isKorean ? '가짜' : 'Fake',
                                style: const TextStyle(color: Colors.red, fontSize: 9)),
                            Text(isKorean ? '진짜' : 'Real',
                                style: const TextStyle(color: Colors.green, fontSize: 9)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Target pattern selection
              PresetGroup(
                label: isKorean ? '목표 패턴' : 'Target Pattern',
                presets: [
                  PresetButton(
                    label: isKorean ? '가로줄' : 'H-Stripes',
                    isSelected: false,
                    onPressed: () => _setPattern('stripes_h'),
                  ),
                  PresetButton(
                    label: isKorean ? '세로줄' : 'V-Stripes',
                    isSelected: false,
                    onPressed: () => _setPattern('stripes_v'),
                  ),
                  PresetButton(
                    label: isKorean ? '체커보드' : 'Checker',
                    isSelected: false,
                    onPressed: () => _setPattern('checker'),
                  ),
                  PresetButton(
                    label: isKorean ? '십자' : 'Cross',
                    isSelected: false,
                    onPressed: () => _setPattern('cross'),
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
                label: isKorean ? '생성' : 'Generate',
                icon: Icons.auto_awesome,
                onPressed: _generateOnce,
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

class _GanPainter extends CustomPainter {
  final List<double> noiseVector;
  final List<double> generatorHidden;
  final List<List<double>> generatedImage;
  final List<List<double>> realImage;
  final List<double> discriminatorHidden;
  final double discriminatorOutput;
  final bool showReal;
  final bool isKorean;

  _GanPainter({
    required this.noiseVector,
    required this.generatorHidden,
    required this.generatedImage,
    required this.realImage,
    required this.discriminatorHidden,
    required this.discriminatorOutput,
    required this.showReal,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 15.0;
    final imageSize = 70.0;
    final centerY = size.height / 2;

    // Draw noise vector (z)
    _drawNoiseVector(
      canvas,
      noiseVector,
      Offset(padding, centerY - 50),
      15,
      100,
      'z',
    );

    // Draw Generator box
    _drawNetworkBox(
      canvas,
      Offset(padding + 40, centerY - 40),
      60,
      80,
      isKorean ? '생성자\n(G)' : 'Generator\n(G)',
      Colors.green,
    );

    // Draw generated image
    _drawImage(
      canvas,
      generatedImage,
      Offset(padding + 120, centerY - imageSize / 2),
      imageSize,
      isKorean ? '생성' : 'Fake',
      Colors.green,
    );

    // Draw real image (if showing)
    if (showReal) {
      _drawImage(
        canvas,
        realImage,
        Offset(padding + 120, centerY - imageSize - 20),
        imageSize * 0.7,
        isKorean ? '실제' : 'Real',
        Colors.blue,
      );
    }

    // Draw Discriminator box
    _drawNetworkBox(
      canvas,
      Offset(size.width - padding - 130, centerY - 40),
      60,
      80,
      isKorean ? '판별자\n(D)' : 'Discriminator\n(D)',
      Colors.orange,
    );

    // Draw discriminator output
    _drawDiscriminatorOutput(
      canvas,
      discriminatorOutput,
      Offset(size.width - padding - 50, centerY - 30),
      40,
      60,
    );

    // Draw arrows
    final arrowPaint = Paint()
      ..color = AppColors.muted
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // z -> G
    _drawArrow(canvas, Offset(padding + 30, centerY), Offset(padding + 40, centerY), arrowPaint);

    // G -> Fake image
    _drawArrow(canvas, Offset(padding + 100, centerY), Offset(padding + 120, centerY), arrowPaint);

    // Fake image -> D
    _drawArrow(
      canvas,
      Offset(padding + 120 + imageSize, centerY),
      Offset(size.width - padding - 130, centerY),
      arrowPaint,
    );

    // D -> Output
    _drawArrow(
      canvas,
      Offset(size.width - padding - 70, centerY),
      Offset(size.width - padding - 55, centerY),
      arrowPaint,
    );

    // Draw labels
    _drawText(canvas, isKorean ? '노이즈' : 'Noise', Offset(padding - 5, centerY + 60),
        AppColors.muted,
        fontSize: 9);
  }

  void _drawNoiseVector(
    Canvas canvas,
    List<double> vector,
    Offset origin,
    double width,
    double height,
    String label,
  ) {
    if (vector.isEmpty) return;

    final cellHeight = height / vector.length;

    for (int i = 0; i < vector.length; i++) {
      final y = origin.dy + i * cellHeight;
      final normalizedValue = ((vector[i] + 1) / 2).clamp(0.0, 1.0);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(origin.dx, y, width, cellHeight - 2),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.purple.withValues(alpha: normalizedValue.clamp(0.2, 1.0)),
      );
    }

    _drawText(canvas, label, Offset(origin.dx + 3, origin.dy + height + 5), Colors.purple,
        fontSize: 10);
  }

  void _drawNetworkBox(
    Canvas canvas,
    Offset origin,
    double width,
    double height,
    String label,
    Color color,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx, origin.dy, width, height),
        const Radius.circular(8),
      ),
      Paint()..color = color.withValues(alpha: 0.2),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx, origin.dy, width, height),
        const Radius.circular(8),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw label (handle multi-line)
    final lines = label.split('\n');
    for (int i = 0; i < lines.length; i++) {
      _drawText(
        canvas,
        lines[i],
        Offset(origin.dx + width / 2 - lines[i].length * 3.5,
            origin.dy + height / 2 - 10 + i * 14),
        color,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      );
    }
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

    canvas.drawRect(
      Rect.fromLTWH(origin.dx, origin.dy, size, size),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    _drawText(canvas, label, Offset(origin.dx, origin.dy + size + 3), borderColor,
        fontSize: 9);
  }

  void _drawDiscriminatorOutput(
    Canvas canvas,
    double output,
    Offset origin,
    double width,
    double height,
  ) {
    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx, origin.dy, width, height),
        const Radius.circular(6),
      ),
      Paint()..color = AppColors.cardBorder,
    );

    // Fill based on output (real probability)
    final fillHeight = height * output;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx, origin.dy + height - fillHeight, width, fillHeight),
        const Radius.circular(6),
      ),
      Paint()
        ..color = Color.lerp(Colors.red, Colors.green, output)!.withValues(alpha: 0.8),
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(origin.dx, origin.dy, width, height),
        const Radius.circular(6),
      ),
      Paint()
        ..color = AppColors.muted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Value
    _drawText(
      canvas,
      output.toStringAsFixed(2),
      Offset(origin.dx + 5, origin.dy + height / 2 - 5),
      Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    _drawText(canvas, isKorean ? '출력' : 'Output', Offset(origin.dx - 2, origin.dy + height + 5),
        AppColors.muted,
        fontSize: 9);
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);

    final direction = (end - start).direction;
    final arrowSize = 6.0;
    final arrowPaint = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      end,
      Offset(
        end.dx - arrowSize * math.cos(direction - 0.5),
        end.dy - arrowSize * math.sin(direction - 0.5),
      ),
      arrowPaint,
    );
    canvas.drawLine(
      end,
      Offset(
        end.dx - arrowSize * math.cos(direction + 0.5),
        end.dy - arrowSize * math.sin(direction + 0.5),
      ),
      arrowPaint,
    );
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
  bool shouldRepaint(covariant _GanPainter oldDelegate) => true;
}
