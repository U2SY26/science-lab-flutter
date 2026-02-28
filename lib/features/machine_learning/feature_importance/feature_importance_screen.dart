import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

class FeatureImportanceScreen extends StatefulWidget {
  const FeatureImportanceScreen({super.key});
  @override
  State<FeatureImportanceScreen> createState() => _FeatureImportanceScreenState();
}

class _FeatureImportanceScreenState extends State<FeatureImportanceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _time = 0;
  bool _isRunning = true;
  double _numFeatures = 5;
  
  double _topShap = 0.3, _sumShap = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_update);
    _controller.repeat();
  }

  void _update() {
    if (!_isRunning) return;
    setState(() {
      _time += 0.016;
      _topShap = 1.0 / _numFeatures + 0.2;
      _sumShap = 1.0;
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _time = 0;
      _numFeatures = 5.0;
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg.withValues(alpha: 0.9),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI/ML 시뮬레이션', style: TextStyle(color: AppColors.accent, fontSize: 11, letterSpacing: 1.5)),
          const Text('특성 중요도 (SHAP)', style: TextStyle(color: AppColors.ink, fontSize: 16)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: 'AI/ML 시뮬레이션',
          title: '특성 중요도 (SHAP)',
          formula: 'φ_i = Σ |S|!(M-|S|-1)!/M! [f(S∪{i})-f(S)]',
          formulaDescription: 'SHAP 값을 이용한 특성 중요도 분석을 시각화합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _FeatureImportanceScreenPainter(
                time: _time,
                numFeatures: _numFeatures,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ControlGroup(
              primaryControl: SimSlider(
                label: '특성 수',
                value: _numFeatures,
                min: 2,
                max: 20,
                step: 1,
                defaultValue: 5,
                formatValue: (v) => v.toInt().toString(),
                onChanged: (v) => setState(() => _numFeatures = v),
              ),
              
            ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.simBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(children: [
          _V('최대 SHAP', _topShap.toStringAsFixed(3)),
          _V('합계', _sumShap.toStringAsFixed(3)),
          _V('특성', _numFeatures.toInt().toString()),
                ]),
              ),
            ],
          ),
          buttons: SimButtonGroup(expanded: true, buttons: [
            SimButton(
              label: _isRunning ? '정지' : '재생',
              icon: _isRunning ? Icons.pause : Icons.play_arrow,
              isPrimary: true,
              onPressed: () { HapticFeedback.selectionClick(); setState(() => _isRunning = !_isRunning); },
            ),
            SimButton(label: '리셋', icon: Icons.refresh, onPressed: _reset),
          ]),
        ),
      ),
    );
  }
}

class _V extends StatelessWidget {
  final String label, value;
  const _V(this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
  ]));
}

class _FeatureImportanceScreenPainter extends CustomPainter {
  final double time;
  final double numFeatures;

  _FeatureImportanceScreenPainter({
    required this.time,
    required this.numFeatures,
  });

  static const List<String> _featureNames = ['Age', 'Income', 'Score', 'Tenure', 'Usage', 'Region', 'Device', 'Plan'];
  static const List<double> _baseImportances = [0.82, 0.67, 0.58, 0.51, 0.44, 0.35, 0.24, 0.13];
  static const List<bool> _isPositive = [true, true, false, true, true, false, true, false];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final n = numFeatures.toInt().clamp(2, 8);
    final entryT = (time / 1.2).clamp(0.0, 1.0);
    final labelW = 52.0;
    final valueW = 38.0;
    final marginTop = 16.0;
    final marginBottom = 16.0;
    final barAreaW = size.width - labelW - valueW - 24;
    final rowH = (size.height - marginTop - marginBottom) / n;

    // Sort by importance descending
    final indices = List.generate(n, (i) => i)
      ..sort((a, b) => _baseImportances[b].compareTo(_baseImportances[a]));

    for (int rank = 0; rank < n; rank++) {
      final idx = indices[rank];
      final name = _featureNames[idx];
      final baseImp = _baseImportances[idx];
      final positive = _isPositive[idx];

      // Animate entry with stagger
      final stagger = (rank / n) * 0.5;
      final barT = ((entryT - stagger) / 0.5).clamp(0.0, 1.0);
      final ease = barT < 0.5 ? 2 * barT * barT : 1 - 2 * (1 - barT) * (1 - barT);

      // Slight oscillation after entry
      final osc = entryT >= 1.0 ? math.sin(time * 1.8 + rank * 0.7) * 0.015 : 0.0;
      final imp = (baseImp + osc).clamp(0.0, 1.0);

      final y = marginTop + rank * rowH;
      final cy = y + rowH / 2;
      final barMaxW = barAreaW * 0.88;
      final barW = barMaxW * imp * ease;
      final barH = (rowH * 0.52).clamp(8.0, 22.0);
      final barX = labelW + 12;
      final barY = cy - barH / 2;

      // Bar fill with gradient
      final barRect = Rect.fromLTWH(barX, barY, barW, barH);
      if (barW > 1) {
        final gradColors = positive
            ? [const Color(0xFF1A4A5A), const Color(0xFF00D4FF)]
            : [const Color(0xFF5A2A1A), const Color(0xFFFF6B35)];
        final shader = LinearGradient(colors: gradColors)
            .createShader(Rect.fromLTWH(barX, barY, barMaxW, barH));
        final barPaint = Paint()..shader = shader;
        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
          barPaint,
        );

        // Glow on top feature
        if (rank == 0 && barW > 4) {
          final glowColor = positive ? AppColors.accent : AppColors.accent2;
          for (int g = 3; g >= 1; g--) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                barRect.inflate(g.toDouble() * 1.5),
                const Radius.circular(5),
              ),
              Paint()..color = glowColor.withValues(alpha: 0.06 * g),
            );
          }
        }

        // Bar edge shimmer
        canvas.drawRRect(
          RRect.fromRectAndRadius(barRect, const Radius.circular(3)),
          Paint()
            ..color = (positive ? AppColors.accent : AppColors.accent2).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }

      // SHAP waterfall indicator dot at bar tip
      if (barW > 6) {
        final dotColor = positive ? AppColors.accent : AppColors.accent2;
        canvas.drawCircle(
          Offset(barX + barW, cy),
          barH * 0.28,
          Paint()..color = dotColor.withValues(alpha: 0.9),
        );
      }

      // Feature name label
      final ltp = TextPainter(
        text: TextSpan(
          text: name,
          style: TextStyle(
            color: rank == 0 ? AppColors.ink : AppColors.muted,
            fontSize: 9.5,
            fontWeight: rank == 0 ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: labelW);
      ltp.paint(canvas, Offset(4, cy - ltp.height / 2));

      // Value label
      final vtp = TextPainter(
        text: TextSpan(
          text: imp.toStringAsFixed(2),
          style: TextStyle(
            color: positive ? AppColors.accent : AppColors.accent2,
            fontSize: 9,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      vtp.paint(canvas, Offset(size.width - valueW + 2, cy - vtp.height / 2));

      // Separator line
      if (rank < n - 1) {
        canvas.drawLine(
          Offset(0, y + rowH),
          Offset(size.width, y + rowH),
          Paint()..color = AppColors.simGrid.withValues(alpha: 0.25)..strokeWidth = 0.5,
        );
      }
    }

    // Legend
    void drawLegendDot(double lx, double ly, Color c, String label) {
      canvas.drawCircle(Offset(lx, ly), 4, Paint()..color = c.withValues(alpha: 0.85));
      final ltp2 = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: AppColors.muted, fontSize: 8.5)),
        textDirection: TextDirection.ltr,
      )..layout();
      ltp2.paint(canvas, Offset(lx + 7, ly - ltp2.height / 2));
    }

    drawLegendDot(labelW + 12, size.height - 6, AppColors.accent, '+영향');
    drawLegendDot(labelW + 65, size.height - 6, AppColors.accent2, '-영향');
  }

  @override
  bool shouldRepaint(covariant _FeatureImportanceScreenPainter oldDelegate) => true;
}
