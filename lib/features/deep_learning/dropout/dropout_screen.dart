import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 드롭아웃 시뮬레이션
class DropoutScreen extends StatefulWidget {
  const DropoutScreen({super.key});

  @override
  State<DropoutScreen> createState() => _DropoutScreenState();
}

class _DropoutScreenState extends State<DropoutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _dropoutRate = 0.5;
  bool _isTraining = true;
  final _random = math.Random();

  List<List<bool>> _activeLayers = [];

  @override
  void initState() {
    super.initState();
    _generateActiveNeurons();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
        if (_controller.status == AnimationStatus.completed) {
          _generateActiveNeurons();
          _controller.reset();
          _controller.forward();
        }
      });
    _controller.forward();
  }

  void _generateActiveNeurons() {
    // 4개 레이어: [4, 6, 6, 2]
    final layerSizes = [4, 6, 6, 2];
    _activeLayers = [];

    for (int l = 0; l < layerSizes.length; l++) {
      final active = <bool>[];
      for (int n = 0; n < layerSizes[l]; n++) {
        // 첫 번째와 마지막 레이어는 드롭아웃 적용 안함
        if (l == 0 || l == layerSizes.length - 1 || !_isTraining) {
          active.add(true);
        } else {
          active.add(_random.nextDouble() > _dropoutRate);
        }
      }
      _activeLayers.add(active);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
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
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI/ML',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '드롭아웃',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML',
          title: '드롭아웃 (Dropout)',
          formula: 'p(drop) = r',
          formulaDescription: '과적합 방지를 위해 학습 시 랜덤하게 뉴런을 비활성화',
          simulation: SizedBox(
            height: 300,
            child: CustomPaint(
              painter: _DropoutPainter(
                activeLayers: _activeLayers,
                isTraining: _isTraining,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 모드 선택
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ModeButton(
                          label: '학습 모드',
                          isSelected: _isTraining,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _isTraining = true;
                              _generateActiveNeurons();
                            });
                          },
                        ),
                        _ModeButton(
                          label: '추론 모드',
                          isSelected: !_isTraining,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _isTraining = false;
                              _generateActiveNeurons();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isTraining
                          ? '학습 시: 뉴런을 랜덤하게 비활성화'
                          : '추론 시: 모든 뉴런 활성화 (가중치 스케일링)',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 설명
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
                    Text('드롭아웃이란?', style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 4),
                    Text(
                      '• 학습 시 랜덤하게 뉴런을 비활성화\n'
                      '• 앙상블 효과로 과적합 방지\n'
                      '• 추론 시에는 모든 뉴런 사용',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '드롭아웃 비율',
                  value: _dropoutRate,
                  min: 0,
                  max: 0.9,
                  defaultValue: 0.5,
                  formatValue: (v) => '${(v * 100).toInt()}%',
                  onChanged: (v) {
                    setState(() {
                      _dropoutRate = v;
                      _generateActiveNeurons();
                    });
                  },
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '새 드롭아웃',
                icon: Icons.shuffle,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _generateActiveNeurons();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.accent : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.muted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _DropoutPainter extends CustomPainter {
  final List<List<bool>> activeLayers;
  final bool isTraining;

  _DropoutPainter({required this.activeLayers, required this.isTraining});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (activeLayers.isEmpty) return;

    final padding = 40.0;
    final layerSpacing = (size.width - padding * 2) / (activeLayers.length - 1);
    final neuronRadius = 15.0;

    // 연결선 먼저 그리기
    for (int l = 0; l < activeLayers.length - 1; l++) {
      final x1 = padding + l * layerSpacing;
      final x2 = padding + (l + 1) * layerSpacing;

      for (int i = 0; i < activeLayers[l].length; i++) {
        for (int j = 0; j < activeLayers[l + 1].length; j++) {
          final y1 = _getNeuronY(size.height, activeLayers[l].length, i);
          final y2 = _getNeuronY(size.height, activeLayers[l + 1].length, j);

          final active = activeLayers[l][i] && activeLayers[l + 1][j];

          canvas.drawLine(
            Offset(x1 + neuronRadius, y1),
            Offset(x2 - neuronRadius, y2),
            Paint()
              ..color = active
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.muted.withValues(alpha: 0.1)
              ..strokeWidth = active ? 1.5 : 0.5,
          );
        }
      }
    }

    // 뉴런 그리기
    for (int l = 0; l < activeLayers.length; l++) {
      final x = padding + l * layerSpacing;

      for (int i = 0; i < activeLayers[l].length; i++) {
        final y = _getNeuronY(size.height, activeLayers[l].length, i);
        final active = activeLayers[l][i];

        // 비활성화된 뉴런에 X 표시
        if (!active) {
          canvas.drawCircle(
            Offset(x, y),
            neuronRadius,
            Paint()
              ..color = Colors.red.withValues(alpha: 0.2)
              ..style = PaintingStyle.fill,
          );
          canvas.drawLine(
            Offset(x - 8, y - 8),
            Offset(x + 8, y + 8),
            Paint()
              ..color = Colors.red
              ..strokeWidth = 2,
          );
          canvas.drawLine(
            Offset(x + 8, y - 8),
            Offset(x - 8, y + 8),
            Paint()
              ..color = Colors.red
              ..strokeWidth = 2,
          );
        } else {
          canvas.drawCircle(
            Offset(x, y),
            neuronRadius,
            Paint()..color = l == 0 ? Colors.green : (l == activeLayers.length - 1 ? Colors.orange : AppColors.accent),
          );
        }

        canvas.drawCircle(
          Offset(x, y),
          neuronRadius,
          Paint()
            ..color = active ? AppColors.accent : Colors.red
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // 레이어 라벨
    final labels = ['입력', '은닉1', '은닉2', '출력'];
    for (int l = 0; l < labels.length && l < activeLayers.length; l++) {
      final x = padding + l * layerSpacing;
      _drawText(canvas, labels[l], Offset(x - 15, size.height - 20), AppColors.muted);
    }
  }

  double _getNeuronY(double height, int layerSize, int index) {
    final spacing = (height - 80) / (layerSize + 1);
    return 40 + spacing * (index + 1);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _DropoutPainter oldDelegate) => true;
}
