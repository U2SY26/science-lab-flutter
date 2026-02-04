import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Bifurcation Diagram Simulation
class BifurcationScreen extends ConsumerStatefulWidget {
  const BifurcationScreen({super.key});

  @override
  ConsumerState<BifurcationScreen> createState() => _BifurcationScreenState();
}

class _BifurcationScreenState extends ConsumerState<BifurcationScreen> {
  // Parameters
  double _rMin = 2.5;
  double _rMax = 4.0;
  int _resolution = 400;
  int _iterations = 100;
  int _skip = 50;

  // Data
  List<List<double>> _bifurcationData = [];
  bool _isComputing = false;

  @override
  void initState() {
    super.initState();
    _computeBifurcation();
  }

  void _computeBifurcation() {
    setState(() => _isComputing = true);

    // Compute in next frame to allow UI update
    Future.microtask(() {
      final data = <List<double>>[];

      final rStep = (_rMax - _rMin) / _resolution;

      for (int i = 0; i <= _resolution; i++) {
        final r = _rMin + i * rStep;
        double x = 0.5; // Initial value

        // Skip transient iterations
        for (int j = 0; j < _skip; j++) {
          x = r * x * (1 - x);
        }

        // Record stable iterations
        final points = <double>[];
        for (int j = 0; j < _iterations; j++) {
          x = r * x * (1 - x);
          if (x.isFinite && x >= 0 && x <= 1) {
            points.add(x);
          }
        }

        data.add([r, ...points]);
      }

      if (mounted) {
        setState(() {
          _bifurcationData = data;
          _isComputing = false;
        });
      }
    });
  }

  void _zoomIn(double centerR) {
    HapticFeedback.lightImpact();
    final range = (_rMax - _rMin) / 4;
    setState(() {
      _rMin = (centerR - range).clamp(0.0, 4.0);
      _rMax = (centerR + range).clamp(0.0, 4.0);
    });
    _computeBifurcation();
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _rMin = 2.5;
      _rMax = 4.0;
    });
    _computeBifurcation();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(languageProvider.notifier).isKorean;

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
              isKorean ? '혼돈 이론' : 'CHAOS THEORY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '분기 도표' : 'Bifurcation Diagram',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '혼돈 이론' : 'Chaos Theory',
          title: isKorean ? '분기 도표' : 'Bifurcation Diagram',
          formula: 'xn+1 = r * xn * (1 - xn)',
          formulaDescription: isKorean
              ? '로지스틱 맵의 분기 도표. r 값이 증가함에 따라 주기 배가와 카오스로의 전이를 보여줍니다.'
              : 'Bifurcation diagram of the logistic map. Shows period doubling and transition to chaos as r increases.',
          simulation: GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox;
              final localPos = box.globalToLocal(details.globalPosition);
              final r = _rMin + (localPos.dx / box.size.width) * (_rMax - _rMin);
              _zoomIn(r);
            },
            child: SizedBox(
              height: 350,
              child: _isComputing
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  : CustomPaint(
                      painter: _BifurcationPainter(
                        data: _bifurcationData,
                        rMin: _rMin,
                        rMax: _rMax,
                        isKorean: isKorean,
                      ),
                      size: Size.infinite,
                    ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(
                          label: 'r min',
                          value: _rMin.toStringAsFixed(3),
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: 'r max',
                          value: _rMax.toStringAsFixed(3),
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: isKorean ? '해상도' : 'Resolution',
                          value: '$_resolution',
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isKorean
                          ? '탭하여 해당 r 값 주변을 확대합니다'
                          : 'Tap to zoom around that r value',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Key r values
              PresetGroup(
                label: isKorean ? '주요 r 값' : 'Key r Values',
                presets: [
                  PresetButton(
                    label: 'r=3 (${isKorean ? '주기2' : 'Period 2'})',
                    isSelected: false,
                    onPressed: () {
                      setState(() {
                        _rMin = 2.8;
                        _rMax = 3.2;
                      });
                      _computeBifurcation();
                    },
                  ),
                  PresetButton(
                    label: 'r=3.57 (${isKorean ? '카오스' : 'Chaos'})',
                    isSelected: false,
                    onPressed: () {
                      setState(() {
                        _rMin = 3.4;
                        _rMax = 3.7;
                      });
                      _computeBifurcation();
                    },
                  ),
                  PresetButton(
                    label: isKorean ? '전체 보기' : 'Full View',
                    isSelected: _rMin == 2.5 && _rMax == 4.0,
                    onPressed: _reset,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '해상도' : 'Resolution',
                  value: _resolution.toDouble(),
                  min: 100,
                  max: 800,
                  defaultValue: 400,
                  formatValue: (v) => v.toInt().toString(),
                  onChanged: (v) {
                    setState(() => _resolution = v.toInt());
                    _computeBifurcation();
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '반복 횟수' : 'Iterations',
                    value: _iterations.toDouble(),
                    min: 50,
                    max: 200,
                    defaultValue: 100,
                    formatValue: (v) => v.toInt().toString(),
                    onChanged: (v) {
                      setState(() => _iterations = v.toInt());
                      _computeBifurcation();
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
                label: isKorean ? '다시 계산' : 'Recompute',
                icon: Icons.refresh,
                isPrimary: true,
                onPressed: _computeBifurcation,
              ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.zoom_out_map,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
      ],
    );
  }
}

class _BifurcationPainter extends CustomPainter {
  final List<List<double>> data;
  final double rMin;
  final double rMax;
  final bool isKorean;

  _BifurcationPainter({
    required this.data,
    required this.rMin,
    required this.rMax,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final padding = 40.0;
    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // Draw axes
    final axisPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );

    // Axis labels
    _drawText(canvas, 'x', Offset(padding - 20, padding - 10), AppColors.muted, 12);
    _drawText(canvas, 'r', Offset(size.width - padding - 10, size.height - padding + 15), AppColors.muted, 12);

    // R-axis values
    for (int i = 0; i <= 4; i++) {
      final r = rMin + (rMax - rMin) * i / 4;
      final x = padding + graphWidth * i / 4;
      _drawText(canvas, r.toStringAsFixed(2), Offset(x - 15, size.height - padding + 5), AppColors.muted, 9);
    }

    // X-axis values
    for (int i = 0; i <= 4; i++) {
      final xVal = i / 4;
      final y = size.height - padding - graphHeight * xVal;
      _drawText(canvas, xVal.toStringAsFixed(1), Offset(padding - 25, y - 5), AppColors.muted, 9);
    }

    if (data.isEmpty) return;

    // Draw bifurcation points
    final pointPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (final rData in data) {
      if (rData.length < 2) continue;

      final r = rData[0];
      final screenX = padding + ((r - rMin) / (rMax - rMin)) * graphWidth;

      for (int i = 1; i < rData.length; i++) {
        final x = rData[i];
        final screenY = size.height - padding - x * graphHeight;

        canvas.drawCircle(
          Offset(screenX, screenY),
          0.5,
          pointPaint,
        );
      }
    }

    // Key annotations
    if (rMin <= 3 && rMax >= 3) {
      final x3 = padding + ((3 - rMin) / (rMax - rMin)) * graphWidth;
      canvas.drawLine(
        Offset(x3, padding),
        Offset(x3, size.height - padding),
        Paint()
          ..color = Colors.orange.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );
      _drawText(canvas, 'r=3', Offset(x3 - 10, padding + 5), Colors.orange, 9);
    }

    if (rMin <= 3.57 && rMax >= 3.57) {
      final x357 = padding + ((3.57 - rMin) / (rMax - rMin)) * graphWidth;
      canvas.drawLine(
        Offset(x357, padding),
        Offset(x357, size.height - padding),
        Paint()
          ..color = Colors.red.withValues(alpha: 0.3)
          ..strokeWidth = 1,
      );
      _drawText(canvas, isKorean ? '카오스 시작' : 'Chaos onset', Offset(x357 - 25, padding + 5), Colors.red, 9);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
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
  bool shouldRepaint(covariant _BifurcationPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.rMin != rMin || oldDelegate.rMax != rMax;
  }
}
