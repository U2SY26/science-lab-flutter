import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Word Embedding Simulation
class WordEmbeddingScreen extends ConsumerStatefulWidget {
  const WordEmbeddingScreen({super.key});

  @override
  ConsumerState<WordEmbeddingScreen> createState() => _WordEmbeddingScreenState();
}

class _WordEmbeddingScreenState extends ConsumerState<WordEmbeddingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = math.Random();

  // Words and their embeddings (2D for visualization)
  final Map<String, List<double>> _wordEmbeddings = {};
  final List<String> _words = [
    'king', 'queen', 'man', 'woman',
    'prince', 'princess', 'boy', 'girl',
    'dog', 'cat', 'puppy', 'kitten',
  ];

  // Korean equivalents
  final Map<String, String> _koreanWords = {
    'king': '왕',
    'queen': '여왕',
    'man': '남자',
    'woman': '여자',
    'prince': '왕자',
    'princess': '공주',
    'boy': '소년',
    'girl': '소녀',
    'dog': '개',
    'cat': '고양이',
    'puppy': '강아지',
    'kitten': '새끼고양이',
  };

  // Selected words for analogy
  String? _selectedWord1;
  String? _selectedWord2;
  String? _selectedWord3;
  String? _analogyResult;

  // Similarity matrix
  List<List<double>> _similarityMatrix = [];

  // View mode
  String _viewMode = '2d'; // '2d', 'similarity', 'analogy'

  // Animation
  bool _isAnimating = false;
  double _animationAngle = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeEmbeddings();
    _computeSimilarityMatrix();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_animate);
  }

  void _initializeEmbeddings() {
    // Create semantically meaningful embeddings
    // Royal/nobility cluster
    _wordEmbeddings['king'] = [0.8, 0.7];
    _wordEmbeddings['queen'] = [0.8, -0.7];
    _wordEmbeddings['prince'] = [0.6, 0.5];
    _wordEmbeddings['princess'] = [0.6, -0.5];

    // Regular people cluster
    _wordEmbeddings['man'] = [0.0, 0.8];
    _wordEmbeddings['woman'] = [0.0, -0.8];
    _wordEmbeddings['boy'] = [-0.2, 0.6];
    _wordEmbeddings['girl'] = [-0.2, -0.6];

    // Animal cluster
    _wordEmbeddings['dog'] = [-0.8, 0.3];
    _wordEmbeddings['cat'] = [-0.8, -0.3];
    _wordEmbeddings['puppy'] = [-0.9, 0.4];
    _wordEmbeddings['kitten'] = [-0.9, -0.4];

    // Add some noise
    for (final word in _words) {
      _wordEmbeddings[word] = _wordEmbeddings[word]!
          .map((v) => v + (_random.nextDouble() - 0.5) * 0.1)
          .toList();
    }
  }

  void _computeSimilarityMatrix() {
    _similarityMatrix = List.generate(_words.length, (i) {
      return List.generate(_words.length, (j) {
        return _cosineSimilarity(
          _wordEmbeddings[_words[i]]!,
          _wordEmbeddings[_words[j]]!,
        );
      });
    });
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  void _computeAnalogy() {
    if (_selectedWord1 == null ||
        _selectedWord2 == null ||
        _selectedWord3 == null) {
      return;
    }

    // king - man + woman = queen
    // a - b + c = ?
    final a = _wordEmbeddings[_selectedWord1]!;
    final b = _wordEmbeddings[_selectedWord2]!;
    final c = _wordEmbeddings[_selectedWord3]!;

    final target = List.generate(2, (i) => a[i] - b[i] + c[i]);

    // Find closest word
    String? closest;
    double maxSimilarity = -2;

    for (final word in _words) {
      if (word == _selectedWord1 ||
          word == _selectedWord2 ||
          word == _selectedWord3) {
        continue;
      }

      final similarity = _cosineSimilarity(target, _wordEmbeddings[word]!);
      if (similarity > maxSimilarity) {
        maxSimilarity = similarity;
        closest = word;
      }
    }

    setState(() {
      _analogyResult = closest;
    });
  }

  void _animate() {
    if (!_isAnimating) return;
    setState(() {
      _animationAngle += 0.02;
    });
  }

  void _toggleAnimation() {
    HapticFeedback.selectionClick();
    setState(() {
      _isAnimating = !_isAnimating;
      if (_isAnimating) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _randomizeEmbeddings() {
    HapticFeedback.mediumImpact();
    setState(() {
      for (final word in _words) {
        _wordEmbeddings[word] = [
          _random.nextDouble() * 2 - 1,
          _random.nextDouble() * 2 - 1,
        ];
      }
      _computeSimilarityMatrix();
      _analogyResult = null;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _controller.stop();
    setState(() {
      _isAnimating = false;
      _animationAngle = 0.0;
      _selectedWord1 = null;
      _selectedWord2 = null;
      _selectedWord3 = null;
      _analogyResult = null;
      _initializeEmbeddings();
      _computeSimilarityMatrix();
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
              isKorean ? '머신러닝' : 'MACHINE LEARNING',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '단어 임베딩' : 'Word Embeddings',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '머신러닝' : 'Machine Learning',
          title: isKorean ? '단어 임베딩 (Word2Vec)' : 'Word Embeddings (Word2Vec)',
          formula: 'king - man + woman = queen',
          formulaDescription: isKorean
              ? '단어를 벡터 공간에 매핑하여 의미적 관계를 포착'
              : 'Map words to vector space to capture semantic relationships',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _WordEmbeddingPainter(
                wordEmbeddings: _wordEmbeddings,
                words: _words,
                koreanWords: _koreanWords,
                similarityMatrix: _similarityMatrix,
                selectedWord1: _selectedWord1,
                selectedWord2: _selectedWord2,
                selectedWord3: _selectedWord3,
                analogyResult: _analogyResult,
                viewMode: _viewMode,
                animationAngle: _animationAngle,
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
                  '2d': isKorean ? '2D 공간' : '2D Space',
                  'similarity': isKorean ? '유사도' : 'Similarity',
                  'analogy': isKorean ? '유추' : 'Analogy',
                },
                selected: _viewMode,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _viewMode = v);
                },
              ),
              const SizedBox(height: 16),

              // Analogy selection (when in analogy mode)
              if (_viewMode == 'analogy') ...[
                Text(
                  isKorean ? '단어 유추: A - B + C = ?' : 'Word Analogy: A - B + C = ?',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _WordDropdown(
                        label: 'A',
                        value: _selectedWord1,
                        words: _words,
                        koreanWords: _koreanWords,
                        isKorean: isKorean,
                        onChanged: (v) {
                          setState(() {
                            _selectedWord1 = v;
                            _computeAnalogy();
                          });
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('-', style: TextStyle(color: AppColors.ink, fontSize: 18)),
                    ),
                    Expanded(
                      child: _WordDropdown(
                        label: 'B',
                        value: _selectedWord2,
                        words: _words,
                        koreanWords: _koreanWords,
                        isKorean: isKorean,
                        onChanged: (v) {
                          setState(() {
                            _selectedWord2 = v;
                            _computeAnalogy();
                          });
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('+', style: TextStyle(color: AppColors.ink, fontSize: 18)),
                    ),
                    Expanded(
                      child: _WordDropdown(
                        label: 'C',
                        value: _selectedWord3,
                        words: _words,
                        koreanWords: _koreanWords,
                        isKorean: isKorean,
                        onChanged: (v) {
                          setState(() {
                            _selectedWord3 = v;
                            _computeAnalogy();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_analogyResult != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isKorean ? '결과: ' : 'Result: ',
                          style: const TextStyle(color: AppColors.ink, fontSize: 14),
                        ),
                        Text(
                          isKorean
                              ? '${_koreanWords[_analogyResult]} ($_analogyResult)'
                              : _analogyResult!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // Word clusters info
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
                      isKorean ? '단어 클러스터' : 'Word Clusters',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ClusterRow(
                      color: Colors.purple,
                      label: isKorean ? '왕족' : 'Royalty',
                      words: ['king', 'queen', 'prince', 'princess'],
                      koreanWords: _koreanWords,
                      isKorean: isKorean,
                    ),
                    const SizedBox(height: 4),
                    _ClusterRow(
                      color: Colors.blue,
                      label: isKorean ? '사람' : 'People',
                      words: ['man', 'woman', 'boy', 'girl'],
                      koreanWords: _koreanWords,
                      isKorean: isKorean,
                    ),
                    const SizedBox(height: 4),
                    _ClusterRow(
                      color: Colors.orange,
                      label: isKorean ? '동물' : 'Animals',
                      words: ['dog', 'cat', 'puppy', 'kitten'],
                      koreanWords: _koreanWords,
                      isKorean: isKorean,
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
                    : (isKorean ? '회전' : 'Rotate'),
                icon: _isAnimating ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleAnimation,
              ),
              SimButton(
                label: isKorean ? '랜덤' : 'Random',
                icon: Icons.shuffle,
                onPressed: _randomizeEmbeddings,
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

class _WordDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> words;
  final Map<String, String> koreanWords;
  final bool isKorean;
  final ValueChanged<String?> onChanged;

  const _WordDropdown({
    required this.label,
    required this.value,
    required this.words,
    required this.koreanWords,
    required this.isKorean,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text(
              isKorean ? '선택' : 'Select',
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            items: words.map((word) {
              return DropdownMenuItem(
                value: word,
                child: Text(
                  isKorean ? koreanWords[word]! : word,
                  style: const TextStyle(color: AppColors.ink, fontSize: 11),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ClusterRow extends StatelessWidget {
  final Color color;
  final String label;
  final List<String> words;
  final Map<String, String> koreanWords;
  final bool isKorean;

  const _ClusterRow({
    required this.color,
    required this.label,
    required this.words,
    required this.koreanWords,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            words.map((w) => isKorean ? koreanWords[w]! : w).join(', '),
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _WordEmbeddingPainter extends CustomPainter {
  final Map<String, List<double>> wordEmbeddings;
  final List<String> words;
  final Map<String, String> koreanWords;
  final List<List<double>> similarityMatrix;
  final String? selectedWord1;
  final String? selectedWord2;
  final String? selectedWord3;
  final String? analogyResult;
  final String viewMode;
  final double animationAngle;
  final bool isKorean;

  _WordEmbeddingPainter({
    required this.wordEmbeddings,
    required this.words,
    required this.koreanWords,
    required this.similarityMatrix,
    required this.selectedWord1,
    required this.selectedWord2,
    required this.selectedWord3,
    required this.analogyResult,
    required this.viewMode,
    required this.animationAngle,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    switch (viewMode) {
      case '2d':
        _draw2DSpace(canvas, size);
        break;
      case 'similarity':
        _drawSimilarityMatrix(canvas, size);
        break;
      case 'analogy':
        _drawAnalogy(canvas, size);
        break;
    }
  }

  void _draw2DSpace(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = math.min(size.width, size.height) * 0.35;

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(centerX - scale - 20, centerY),
      Offset(centerX + scale + 20, centerY),
      axisPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - scale - 20),
      Offset(centerX, centerY + scale + 20),
      axisPaint,
    );

    // Draw words
    for (final word in words) {
      final embedding = wordEmbeddings[word]!;

      // Apply rotation
      final rotatedX = embedding[0] * math.cos(animationAngle) -
          embedding[1] * math.sin(animationAngle);
      final rotatedY = embedding[0] * math.sin(animationAngle) +
          embedding[1] * math.cos(animationAngle);

      final x = centerX + rotatedX * scale;
      final y = centerY - rotatedY * scale;

      // Determine color based on cluster
      Color color;
      if (['king', 'queen', 'prince', 'princess'].contains(word)) {
        color = Colors.purple;
      } else if (['man', 'woman', 'boy', 'girl'].contains(word)) {
        color = Colors.blue;
      } else {
        color = Colors.orange;
      }

      // Draw point
      canvas.drawCircle(Offset(x, y), 8, Paint()..color = color);
      canvas.drawCircle(
        Offset(x, y),
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Draw label
      final label = isKorean ? koreanWords[word]! : word;
      _drawText(canvas, label, Offset(x + 10, y - 5), color, fontSize: 10);
    }
  }

  void _drawSimilarityMatrix(Canvas canvas, Size size) {
    if (similarityMatrix.isEmpty) return;

    final padding = 50.0;
    final matrixSize = math.min(size.width - padding * 2, size.height - padding);
    final cellSize = matrixSize / words.length;
    final startX = (size.width - matrixSize) / 2;
    final startY = 30.0;

    for (int i = 0; i < words.length; i++) {
      for (int j = 0; j < words.length; j++) {
        final similarity = similarityMatrix[i][j];
        final x = startX + j * cellSize;
        final y = startY + i * cellSize;

        // Color based on similarity (-1 to 1)
        final normalizedSim = (similarity + 1) / 2;
        final color = Color.lerp(Colors.red, Colors.green, normalizedSim)!;

        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize - 1, cellSize - 1),
          Paint()..color = color.withValues(alpha: 0.8),
        );
      }

      // Row labels
      final label = isKorean
          ? (koreanWords[words[i]]!.length > 3
              ? '${koreanWords[words[i]]!.substring(0, 2)}..'
              : koreanWords[words[i]]!)
          : (words[i].length > 4 ? '${words[i].substring(0, 3)}..' : words[i]);
      _drawText(
        canvas,
        label,
        Offset(startX - 35, startY + i * cellSize + cellSize / 2 - 5),
        AppColors.muted,
        fontSize: 8,
      );

      // Column labels
      _drawText(
        canvas,
        label,
        Offset(startX + i * cellSize + 2, startY - 12),
        AppColors.muted,
        fontSize: 8,
      );
    }

    // Legend
    _drawText(canvas, isKorean ? '유사도: ' : 'Similarity: ',
        Offset(20, size.height - 25), AppColors.muted,
        fontSize: 10);
    _drawText(canvas, '-1', Offset(80, size.height - 25), Colors.red, fontSize: 10);
    _drawText(canvas, '0', Offset(120, size.height - 25), Colors.yellow, fontSize: 10);
    _drawText(canvas, '+1', Offset(150, size.height - 25), Colors.green, fontSize: 10);
  }

  void _drawAnalogy(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = math.min(size.width, size.height) * 0.3;

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.cardBorder
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(centerX - scale - 20, centerY),
      Offset(centerX + scale + 20, centerY),
      axisPaint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - scale - 20),
      Offset(centerX, centerY + scale + 20),
      axisPaint,
    );

    // Draw all words (faded)
    for (final word in words) {
      final embedding = wordEmbeddings[word]!;
      final x = centerX + embedding[0] * scale;
      final y = centerY - embedding[1] * scale;

      final isSelected = word == selectedWord1 ||
          word == selectedWord2 ||
          word == selectedWord3 ||
          word == analogyResult;

      canvas.drawCircle(
        Offset(x, y),
        isSelected ? 10 : 5,
        Paint()..color = isSelected ? AppColors.accent : AppColors.muted.withValues(alpha: 0.3),
      );

      if (isSelected) {
        final label = isKorean ? koreanWords[word]! : word;
        _drawText(canvas, label, Offset(x + 12, y - 5), AppColors.accent,
            fontSize: 11, fontWeight: FontWeight.bold);
      }
    }

    // Draw analogy vectors if all selected
    if (selectedWord1 != null &&
        selectedWord2 != null &&
        selectedWord3 != null) {
      final e1 = wordEmbeddings[selectedWord1]!;
      final e2 = wordEmbeddings[selectedWord2]!;
      final e3 = wordEmbeddings[selectedWord3]!;

      final p1 = Offset(centerX + e1[0] * scale, centerY - e1[1] * scale);
      final p2 = Offset(centerX + e2[0] * scale, centerY - e2[1] * scale);
      final p3 = Offset(centerX + e3[0] * scale, centerY - e3[1] * scale);

      // Vector from B to A
      _drawArrow(canvas, p2, p1, Colors.red);

      // Vector from C to result (same direction)
      if (analogyResult != null) {
        final e4 = wordEmbeddings[analogyResult]!;
        final p4 = Offset(centerX + e4[0] * scale, centerY - e4[1] * scale);
        _drawArrow(canvas, p3, p4, Colors.green);

        // Highlight result
        canvas.drawCircle(p4, 12, Paint()..color = Colors.green.withValues(alpha: 0.3));
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start, end, paint);

    final direction = (end - start).direction;
    final arrowSize = 10.0;
    canvas.drawLine(
      end,
      Offset(
        end.dx - arrowSize * math.cos(direction - 0.4),
        end.dy - arrowSize * math.sin(direction - 0.4),
      ),
      paint,
    );
    canvas.drawLine(
      end,
      Offset(
        end.dx - arrowSize * math.cos(direction + 0.4),
        end.dy - arrowSize * math.sin(direction + 0.4),
      ),
      paint,
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
  bool shouldRepaint(covariant _WordEmbeddingPainter oldDelegate) => true;
}
