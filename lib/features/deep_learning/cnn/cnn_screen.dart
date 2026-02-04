import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Convolutional Neural Network Simulation
class CnnScreen extends ConsumerStatefulWidget {
  const CnnScreen({super.key});

  @override
  ConsumerState<CnnScreen> createState() => _CnnScreenState();
}

class _CnnScreenState extends ConsumerState<CnnScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Input image (8x8 grid)
  late List<List<double>> _inputImage;

  // Kernel/Filter (3x3)
  List<List<double>> _kernel = [
    [-1, -1, -1],
    [-1, 8, -1],
    [-1, -1, -1],
  ];

  // Feature map after convolution
  List<List<double>> _featureMap = [];

  // Pooled output
  List<List<double>> _pooledOutput = [];

  // Parameters
  int _kernelSize = 3;
  int _stride = 1;
  int _poolSize = 2;
  String _poolType = 'max';
  double _animationProgress = 0.0;
  int _currentConvX = 0;
  int _currentConvY = 0;
  bool _isAnimating = false;

  // Preset patterns
  String _selectedPattern = 'edge';

  @override
  void initState() {
    super.initState();
    _initializeImage();
    _initializeKernel();
    _computeConvolution();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_animate);
  }

  void _initializeImage() {
    // Create a simple pattern (vertical edge)
    _inputImage = List.generate(8, (i) {
      return List.generate(8, (j) {
        if (j < 4) return 0.0;
        return 1.0;
      });
    });
  }

  void _initializeKernel() {
    switch (_selectedPattern) {
      case 'edge':
        _kernel = [
          [-1, -1, -1],
          [-1, 8, -1],
          [-1, -1, -1],
        ];
        break;
      case 'blur':
        _kernel = [
          [1 / 9, 1 / 9, 1 / 9],
          [1 / 9, 1 / 9, 1 / 9],
          [1 / 9, 1 / 9, 1 / 9],
        ];
        break;
      case 'sharpen':
        _kernel = [
          [0, -1, 0],
          [-1, 5, -1],
          [0, -1, 0],
        ];
        break;
      case 'sobel_x':
        _kernel = [
          [-1, 0, 1],
          [-2, 0, 2],
          [-1, 0, 1],
        ];
        break;
      case 'sobel_y':
        _kernel = [
          [-1, -2, -1],
          [0, 0, 0],
          [1, 2, 1],
        ];
        break;
    }
  }

  void _computeConvolution() {
    final inputSize = _inputImage.length;
    final outputSize = ((inputSize - _kernelSize) / _stride).floor() + 1;

    _featureMap = List.generate(outputSize, (i) {
      return List.generate(outputSize, (j) {
        double sum = 0;
        for (int ki = 0; ki < _kernelSize; ki++) {
          for (int kj = 0; kj < _kernelSize; kj++) {
            final ii = i * _stride + ki;
            final jj = j * _stride + kj;
            if (ii < inputSize && jj < inputSize) {
              sum += _inputImage[ii][jj] * _kernel[ki][kj];
            }
          }
        }
        return sum;
      });
    });

    _computePooling();
  }

  void _computePooling() {
    if (_featureMap.isEmpty) return;

    final inputSize = _featureMap.length;
    final outputSize = (inputSize / _poolSize).floor();

    _pooledOutput = List.generate(outputSize, (i) {
      return List.generate(outputSize, (j) {
        final startI = i * _poolSize;
        final startJ = j * _poolSize;

        double result = _poolType == 'max' ? double.negativeInfinity : 0;
        int count = 0;

        for (int pi = 0; pi < _poolSize; pi++) {
          for (int pj = 0; pj < _poolSize; pj++) {
            final ii = startI + pi;
            final jj = startJ + pj;
            if (ii < inputSize && jj < inputSize) {
              if (_poolType == 'max') {
                result = math.max(result, _featureMap[ii][jj]);
              } else {
                result += _featureMap[ii][jj];
                count++;
              }
            }
          }
        }

        return _poolType == 'max' ? result : result / count;
      });
    });
  }

  void _animate() {
    if (!_isAnimating) return;

    setState(() {
      _animationProgress += 0.05;
      if (_animationProgress >= 1.0) {
        _animationProgress = 0.0;
        _currentConvX++;
        if (_currentConvX >= _featureMap.length) {
          _currentConvX = 0;
          _currentConvY++;
          if (_currentConvY >= _featureMap.length) {
            _currentConvY = 0;
            _isAnimating = false;
            _controller.stop();
          }
        }
      }
    });
  }

  void _startAnimation() {
    HapticFeedback.selectionClick();
    setState(() {
      _isAnimating = true;
      _currentConvX = 0;
      _currentConvY = 0;
      _animationProgress = 0.0;
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

  void _randomizeInput() {
    HapticFeedback.mediumImpact();
    final random = math.Random();
    setState(() {
      _inputImage = List.generate(8, (i) {
        return List.generate(8, (j) => random.nextDouble());
      });
      _computeConvolution();
    });
  }

  void _setPatternInput(String pattern) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (pattern) {
        case 'vertical':
          _inputImage = List.generate(8, (i) {
            return List.generate(8, (j) => j < 4 ? 0.0 : 1.0);
          });
          break;
        case 'horizontal':
          _inputImage = List.generate(8, (i) {
            return List.generate(8, (j) => i < 4 ? 0.0 : 1.0);
          });
          break;
        case 'diagonal':
          _inputImage = List.generate(8, (i) {
            return List.generate(8, (j) => i <= j ? 1.0 : 0.0);
          });
          break;
        case 'center':
          _inputImage = List.generate(8, (i) {
            return List.generate(8, (j) {
              if (i >= 2 && i < 6 && j >= 2 && j < 6) return 1.0;
              return 0.0;
            });
          });
          break;
      }
      _computeConvolution();
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      _isAnimating = false;
      _currentConvX = 0;
      _currentConvY = 0;
      _animationProgress = 0.0;
      _initializeImage();
      _computeConvolution();
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
              isKorean ? '합성곱 신경망 (CNN)' : 'Convolutional Neural Network',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '딥러닝' : 'Deep Learning',
          title: isKorean ? '합성곱 신경망 (CNN)' : 'Convolutional Neural Network',
          formula: '(f * g)[i,j] = ΣΣ f[m,n] · g[i-m, j-n]',
          formulaDescription: isKorean
              ? '입력 이미지에 커널(필터)을 적용하여 특징을 추출하는 합성곱 연산'
              : 'Convolution operation that applies a kernel to extract features from input',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _CnnPainter(
                inputImage: _inputImage,
                kernel: _kernel,
                featureMap: _featureMap,
                pooledOutput: _pooledOutput,
                currentX: _currentConvX,
                currentY: _currentConvY,
                kernelSize: _kernelSize,
                isAnimating: _isAnimating,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kernel preset selection
              PresetGroup(
                label: isKorean ? '커널(필터) 선택' : 'Select Kernel',
                presets: [
                  PresetButton(
                    label: isKorean ? '엣지' : 'Edge',
                    isSelected: _selectedPattern == 'edge',
                    onPressed: () {
                      setState(() {
                        _selectedPattern = 'edge';
                        _initializeKernel();
                        _computeConvolution();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '블러' : 'Blur',
                    isSelected: _selectedPattern == 'blur',
                    onPressed: () {
                      setState(() {
                        _selectedPattern = 'blur';
                        _initializeKernel();
                        _computeConvolution();
                      });
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '샤픈' : 'Sharpen',
                    isSelected: _selectedPattern == 'sharpen',
                    onPressed: () {
                      setState(() {
                        _selectedPattern = 'sharpen';
                        _initializeKernel();
                        _computeConvolution();
                      });
                    },
                  ),
                  PresetButton(
                    label: 'Sobel X',
                    isSelected: _selectedPattern == 'sobel_x',
                    onPressed: () {
                      setState(() {
                        _selectedPattern = 'sobel_x';
                        _initializeKernel();
                        _computeConvolution();
                      });
                    },
                  ),
                  PresetButton(
                    label: 'Sobel Y',
                    isSelected: _selectedPattern == 'sobel_y',
                    onPressed: () {
                      setState(() {
                        _selectedPattern = 'sobel_y';
                        _initializeKernel();
                        _computeConvolution();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Input pattern selection
              PresetGroup(
                label: isKorean ? '입력 패턴' : 'Input Pattern',
                presets: [
                  PresetButton(
                    label: isKorean ? '수직' : 'Vertical',
                    isSelected: false,
                    onPressed: () => _setPatternInput('vertical'),
                  ),
                  PresetButton(
                    label: isKorean ? '수평' : 'Horizontal',
                    isSelected: false,
                    onPressed: () => _setPatternInput('horizontal'),
                  ),
                  PresetButton(
                    label: isKorean ? '대각선' : 'Diagonal',
                    isSelected: false,
                    onPressed: () => _setPatternInput('diagonal'),
                  ),
                  PresetButton(
                    label: isKorean ? '중앙' : 'Center',
                    isSelected: false,
                    onPressed: () => _setPatternInput('center'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Pooling type
              SimSegment<String>(
                label: isKorean ? '풀링 타입' : 'Pooling Type',
                options: {
                  'max': isKorean ? '맥스 풀링' : 'Max Pool',
                  'avg': isKorean ? '평균 풀링' : 'Avg Pool',
                },
                selected: _poolType,
                onChanged: (v) {
                  setState(() {
                    _poolType = v;
                    _computePooling();
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: isKorean ? '입력' : 'Input',
                      value: '8x8',
                      color: Colors.blue,
                    ),
                    _StatItem(
                      label: isKorean ? '특징맵' : 'Feature Map',
                      value: '${_featureMap.length}x${_featureMap.length}',
                      color: AppColors.accent,
                    ),
                    _StatItem(
                      label: isKorean ? '풀링 출력' : 'Pooled',
                      value: '${_pooledOutput.length}x${_pooledOutput.length}',
                      color: Colors.green,
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
                label: _isAnimating
                    ? (isKorean ? '정지' : 'Stop')
                    : (isKorean ? '애니메이션' : 'Animate'),
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _isAnimating ? _stopAnimation : _startAnimation,
              ),
              SimButton(
                label: isKorean ? '랜덤' : 'Random',
                icon: Icons.shuffle,
                onPressed: _randomizeInput,
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CnnPainter extends CustomPainter {
  final List<List<double>> inputImage;
  final List<List<double>> kernel;
  final List<List<double>> featureMap;
  final List<List<double>> pooledOutput;
  final int currentX;
  final int currentY;
  final int kernelSize;
  final bool isAnimating;
  final bool isKorean;

  _CnnPainter({
    required this.inputImage,
    required this.kernel,
    required this.featureMap,
    required this.pooledOutput,
    required this.currentX,
    required this.currentY,
    required this.kernelSize,
    required this.isAnimating,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 20.0;
    final sectionWidth = (size.width - padding * 4) / 4;
    final cellSize = math.min(sectionWidth / 8, 25.0);

    // Draw input image
    _drawGrid(
      canvas,
      inputImage,
      Offset(padding, 60),
      cellSize,
      isKorean ? '입력 (8x8)' : 'Input (8x8)',
      highlightX: isAnimating ? currentY : null,
      highlightY: isAnimating ? currentX : null,
      highlightSize: kernelSize,
    );

    // Draw kernel
    final kernelCellSize = cellSize * 1.5;
    _drawKernel(
      canvas,
      kernel,
      Offset(padding + sectionWidth + padding, 60),
      kernelCellSize,
      isKorean ? '커널 (3x3)' : 'Kernel (3x3)',
    );

    // Draw feature map
    _drawGrid(
      canvas,
      featureMap,
      Offset(padding + (sectionWidth + padding) * 2, 60),
      cellSize,
      isKorean ? '특징맵' : 'Feature Map',
      highlightX: isAnimating ? currentX : null,
      highlightY: isAnimating ? currentY : null,
      highlightSize: 1,
      isFeatureMap: true,
    );

    // Draw pooled output
    _drawGrid(
      canvas,
      pooledOutput,
      Offset(padding + (sectionWidth + padding) * 3, 60),
      cellSize * 1.5,
      isKorean ? '풀링 출력' : 'Pooled Output',
      isFeatureMap: true,
    );

    // Draw arrows
    final arrowPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final arrowY = 60 + cellSize * 4;
    _drawArrow(canvas, Offset(padding + sectionWidth, arrowY),
        Offset(padding + sectionWidth + padding / 2, arrowY), arrowPaint);
    _drawArrow(
        canvas,
        Offset(padding + (sectionWidth + padding) * 2 - padding / 2, arrowY),
        Offset(padding + (sectionWidth + padding) * 2, arrowY),
        arrowPaint);
    _drawArrow(
        canvas,
        Offset(padding + (sectionWidth + padding) * 3 - padding / 2, arrowY),
        Offset(padding + (sectionWidth + padding) * 3, arrowY),
        arrowPaint);

    // Draw labels
    _drawText(canvas, 'Conv', Offset(padding + sectionWidth + padding / 4, arrowY - 15),
        AppColors.accent,
        fontSize: 10);
    _drawText(canvas, 'Pool',
        Offset(padding + (sectionWidth + padding) * 3 - padding / 2, arrowY - 15), AppColors.accent,
        fontSize: 10);
  }

  void _drawGrid(
    Canvas canvas,
    List<List<double>> data,
    Offset origin,
    double cellSize,
    String label, {
    int? highlightX,
    int? highlightY,
    int highlightSize = 1,
    bool isFeatureMap = false,
  }) {
    if (data.isEmpty) return;

    // Draw label
    _drawText(canvas, label, Offset(origin.dx, origin.dy - 20), AppColors.ink,
        fontSize: 11);

    for (int i = 0; i < data.length; i++) {
      for (int j = 0; j < data[i].length; j++) {
        final x = origin.dx + j * cellSize;
        final y = origin.dy + i * cellSize;
        final rect = Rect.fromLTWH(x, y, cellSize - 1, cellSize - 1);

        // Calculate color based on value
        double value = data[i][j];
        Color cellColor;
        if (isFeatureMap) {
          // Normalize feature map values for display
          final normalizedValue = (value + 4) / 8; // Rough normalization
          cellColor = Color.lerp(
            Colors.blue.shade900,
            Colors.yellow,
            normalizedValue.clamp(0, 1),
          )!;
        } else {
          cellColor = Color.lerp(
            Colors.black,
            Colors.white,
            value.clamp(0, 1),
          )!;
        }

        canvas.drawRect(rect, Paint()..color = cellColor);

        // Highlight current convolution window
        if (highlightX != null &&
            highlightY != null &&
            i >= highlightX &&
            i < highlightX + highlightSize &&
            j >= highlightY &&
            j < highlightY + highlightSize) {
          canvas.drawRect(
            rect,
            Paint()
              ..color = AppColors.accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }
  }

  void _drawKernel(
    Canvas canvas,
    List<List<double>> data,
    Offset origin,
    double cellSize,
    String label,
  ) {
    _drawText(canvas, label, Offset(origin.dx, origin.dy - 20), AppColors.ink,
        fontSize: 11);

    for (int i = 0; i < data.length; i++) {
      for (int j = 0; j < data[i].length; j++) {
        final x = origin.dx + j * cellSize;
        final y = origin.dy + i * cellSize;
        final rect = Rect.fromLTWH(x, y, cellSize - 2, cellSize - 2);

        // Color based on kernel value
        final value = data[i][j];
        Color cellColor;
        if (value > 0) {
          cellColor = Colors.green.withValues(alpha: (value.abs() / 10).clamp(0.2, 1.0));
        } else if (value < 0) {
          cellColor = Colors.red.withValues(alpha: (value.abs() / 10).clamp(0.2, 1.0));
        } else {
          cellColor = Colors.grey.shade800;
        }

        canvas.drawRect(rect, Paint()..color = cellColor);
        canvas.drawRect(
          rect,
          Paint()
            ..color = AppColors.cardBorder
            ..style = PaintingStyle.stroke,
        );

        // Draw value
        final valueText = value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
        _drawText(
          canvas,
          valueText,
          Offset(x + cellSize / 2 - 6, y + cellSize / 2 - 6),
          Colors.white,
          fontSize: 9,
        );
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    final direction = (end - start).direction;
    final arrowSize = 8.0;
    canvas.drawLine(
      end,
      Offset(
        end.dx - arrowSize * math.cos(direction - 0.5),
        end.dy - arrowSize * math.sin(direction - 0.5),
      ),
      paint,
    );
    canvas.drawLine(
      end,
      Offset(
        end.dx - arrowSize * math.cos(direction + 0.5),
        end.dy - arrowSize * math.sin(direction + 0.5),
      ),
      paint,
    );
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
  bool shouldRepaint(covariant _CnnPainter oldDelegate) => true;
}
