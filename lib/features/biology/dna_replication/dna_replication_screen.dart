import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// DNA Replication Simulation
class DnaReplicationScreen extends ConsumerStatefulWidget {
  const DnaReplicationScreen({super.key});

  @override
  ConsumerState<DnaReplicationScreen> createState() => _DnaReplicationScreenState();
}

class _DnaReplicationScreenState extends ConsumerState<DnaReplicationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Replication parameters
  double _replicationSpeed = 1.0;
  double _replicationProgress = 0.0;
  bool _isRunning = false;
  bool _showLabels = true;

  // DNA structure
  final List<String> _templateStrand = ['A', 'T', 'G', 'C', 'A', 'A', 'T', 'C', 'G', 'T', 'A', 'C'];
  final List<String> _complementStrand = ['T', 'A', 'C', 'G', 'T', 'T', 'A', 'G', 'C', 'A', 'T', 'G'];

  // Replication fork position
  int _forkPosition = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(_updateReplication);
  }

  void _updateReplication() {
    if (!_isRunning) return;

    setState(() {
      _replicationProgress += 0.005 * _replicationSpeed;
      _forkPosition = (_replicationProgress * _templateStrand.length).floor();

      if (_replicationProgress >= 1.0) {
        _replicationProgress = 1.0;
        _isRunning = false;
        _controller.stop();
      }
    });
  }

  void _toggleRunning() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = false;
      _replicationProgress = 0.0;
      _forkPosition = 0;
      _controller.stop();
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
              isKorean ? '생물학' : 'BIOLOGY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? 'DNA 복제' : 'DNA Replication',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showLabels ? Icons.label : Icons.label_off),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _showLabels = !_showLabels);
            },
            tooltip: isKorean ? '라벨 표시' : 'Show Labels',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '생물학' : 'Biology',
          title: isKorean ? 'DNA 복제' : 'DNA Replication',
          formula: "5' → 3' (Leading) / 3' → 5' (Lagging)",
          formulaDescription: isKorean
              ? 'DNA 중합효소가 주형 가닥을 읽어 상보적인 염기를 추가하여 새로운 가닥을 합성합니다.'
              : 'DNA polymerase reads the template strand and adds complementary bases to synthesize a new strand.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: _DnaReplicationPainter(
                templateStrand: _templateStrand,
                complementStrand: _complementStrand,
                replicationProgress: _replicationProgress,
                forkPosition: _forkPosition,
                showLabels: _showLabels,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status info
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
                        _InfoItem(
                          label: isKorean ? '복제 진행' : 'Progress',
                          value: '${(_replicationProgress * 100).toStringAsFixed(1)}%',
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: isKorean ? '복제된 염기' : 'Replicated',
                          value: '$_forkPosition / ${_templateStrand.length}',
                          color: AppColors.accent2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BaseLegend(base: 'A', color: Colors.red, label: isKorean ? '아데닌' : 'Adenine'),
                        const SizedBox(width: 12),
                        _BaseLegend(base: 'T', color: Colors.blue, label: isKorean ? '티민' : 'Thymine'),
                        const SizedBox(width: 12),
                        _BaseLegend(base: 'G', color: Colors.green, label: isKorean ? '구아닌' : 'Guanine'),
                        const SizedBox(width: 12),
                        _BaseLegend(base: 'C', color: Colors.orange, label: isKorean ? '시토신' : 'Cytosine'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Controls
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '복제 속도' : 'Replication Speed',
                  value: _replicationSpeed,
                  min: 0.1,
                  max: 3.0,
                  defaultValue: 1.0,
                  formatValue: (v) => '${v.toStringAsFixed(1)}x',
                  onChanged: (v) => setState(() => _replicationSpeed = v),
                ),
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: _isRunning
                    ? (isKorean ? '일시정지' : 'Pause')
                    : (isKorean ? '시작' : 'Start'),
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: _toggleRunning,
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
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _BaseLegend extends StatelessWidget {
  final String base;
  final Color color;
  final String label;

  const _BaseLegend({required this.base, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(base, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 9)),
      ],
    );
  }
}

class _DnaReplicationPainter extends CustomPainter {
  final List<String> templateStrand;
  final List<String> complementStrand;
  final double replicationProgress;
  final int forkPosition;
  final bool showLabels;
  final bool isKorean;

  _DnaReplicationPainter({
    required this.templateStrand,
    required this.complementStrand,
    required this.replicationProgress,
    required this.forkPosition,
    required this.showLabels,
    required this.isKorean,
  });

  Color _getBaseColor(String base) {
    switch (base) {
      case 'A': return Colors.red;
      case 'T': return Colors.blue;
      case 'G': return Colors.green;
      case 'C': return Colors.orange;
      default: return AppColors.muted;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerY = size.height / 2;
    final baseWidth = size.width / (templateStrand.length + 4);
    final startX = baseWidth * 2;

    // Draw DNA backbone
    final backbonePaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw replication fork
    final forkX = startX + forkPosition * baseWidth;

    // Fork shape
    if (forkPosition > 0 && forkPosition < templateStrand.length) {
      final forkPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final forkPath = Path()
        ..moveTo(forkX, centerY - 60)
        ..lineTo(forkX + 30, centerY)
        ..lineTo(forkX, centerY + 60)
        ..close();

      canvas.drawPath(forkPath, forkPaint);

      // Helicase label
      if (showLabels) {
        _drawText(canvas, isKorean ? '헬리카제' : 'Helicase',
            Offset(forkX + 35, centerY - 8), AppColors.accent, 10);
      }
    }

    // Draw template strand (top, 3' to 5')
    for (int i = 0; i < templateStrand.length; i++) {
      final x = startX + i * baseWidth;
      final base = templateStrand[i];
      final isReplicated = i < forkPosition;

      // Backbone
      if (i > 0) {
        canvas.drawLine(
          Offset(startX + (i - 1) * baseWidth + 15, centerY - 40),
          Offset(x - 5, centerY - 40),
          backbonePaint,
        );
      }

      // Base
      final basePaint = Paint()
        ..color = _getBaseColor(base).withValues(alpha: isReplicated ? 1.0 : 0.5);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, centerY - 40), width: 24, height: 20),
          const Radius.circular(4),
        ),
        basePaint,
      );

      _drawText(canvas, base, Offset(x - 5, centerY - 47), Colors.white, 12, fontWeight: FontWeight.bold);

      // Hydrogen bonds (only for unreplicated region)
      if (!isReplicated) {
        final bondPaint = Paint()
          ..color = AppColors.muted.withValues(alpha: 0.4)
          ..strokeWidth = 1;

        final bondCount = (base == 'G' || base == 'C') ? 3 : 2;
        for (int j = 0; j < bondCount; j++) {
          final bondY = centerY - 25 + j * 8;
          canvas.drawLine(
            Offset(x, bondY),
            Offset(x, bondY + 5),
            bondPaint,
          );
        }
      }
    }

    // Draw complement strand (bottom, 5' to 3')
    for (int i = 0; i < complementStrand.length; i++) {
      final x = startX + i * baseWidth;
      final base = complementStrand[i];
      final isReplicated = i < forkPosition;

      // Backbone
      if (i > 0) {
        canvas.drawLine(
          Offset(startX + (i - 1) * baseWidth + 15, centerY + 40),
          Offset(x - 5, centerY + 40),
          backbonePaint,
        );
      }

      // Base
      final basePaint = Paint()
        ..color = _getBaseColor(base).withValues(alpha: isReplicated ? 1.0 : 0.5);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, centerY + 40), width: 24, height: 20),
          const Radius.circular(4),
        ),
        basePaint,
      );

      _drawText(canvas, base, Offset(x - 5, centerY + 33), Colors.white, 12, fontWeight: FontWeight.bold);
    }

    // Draw newly synthesized strands
    for (int i = 0; i < forkPosition; i++) {
      final x = startX + i * baseWidth;

      // New strand for template (below, synthesized 5' to 3')
      final newBase1 = _getComplement(templateStrand[i]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, centerY - 5), width: 20, height: 16),
          const Radius.circular(3),
        ),
        Paint()..color = _getBaseColor(newBase1).withValues(alpha: 0.8),
      );
      _drawText(canvas, newBase1, Offset(x - 4, centerY - 11), Colors.white, 10, fontWeight: FontWeight.bold);

      // New strand for complement (above, synthesized 3' to 5' via Okazaki fragments)
      final newBase2 = _getComplement(complementStrand[i]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, centerY + 5), width: 20, height: 16),
          const Radius.circular(3),
        ),
        Paint()..color = _getBaseColor(newBase2).withValues(alpha: 0.8),
      );
      _drawText(canvas, newBase2, Offset(x - 4, centerY - 1), Colors.white, 10, fontWeight: FontWeight.bold);

      // New hydrogen bonds
      final bondPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.5)
        ..strokeWidth = 1;

      canvas.drawLine(Offset(x, centerY - 30), Offset(x, centerY - 13), bondPaint);
      canvas.drawLine(Offset(x, centerY + 13), Offset(x, centerY + 30), bondPaint);
    }

    // Labels
    if (showLabels) {
      _drawText(canvas, "3'", Offset(startX - 25, centerY - 45), AppColors.muted, 11);
      _drawText(canvas, "5'", Offset(startX + templateStrand.length * baseWidth + 5, centerY - 45), AppColors.muted, 11);
      _drawText(canvas, "5'", Offset(startX - 25, centerY + 35), AppColors.muted, 11);
      _drawText(canvas, "3'", Offset(startX + complementStrand.length * baseWidth + 5, centerY + 35), AppColors.muted, 11);

      _drawText(canvas, isKorean ? '주형 가닥' : 'Template', Offset(10, centerY - 70), AppColors.muted, 10);
      _drawText(canvas, isKorean ? '주형 가닥' : 'Template', Offset(10, centerY + 55), AppColors.muted, 10);

      if (forkPosition > 0) {
        _drawText(canvas, isKorean ? '선도 가닥' : 'Leading', Offset(10, centerY - 12), Colors.green, 9);
        _drawText(canvas, isKorean ? '지연 가닥' : 'Lagging', Offset(10, centerY + 2), Colors.orange, 9);
      }
    }

    // DNA Polymerase indicator
    if (forkPosition > 0 && forkPosition < templateStrand.length) {
      final polyX = startX + (forkPosition - 0.5) * baseWidth;

      // Leading strand polymerase
      canvas.drawCircle(
        Offset(polyX, centerY - 5),
        8,
        Paint()..color = Colors.purple.withValues(alpha: 0.7),
      );

      // Lagging strand polymerase
      canvas.drawCircle(
        Offset(polyX - baseWidth, centerY + 5),
        8,
        Paint()..color = Colors.purple.withValues(alpha: 0.7),
      );

      if (showLabels) {
        _drawText(canvas, isKorean ? 'DNA 중합효소' : 'DNA Pol',
            Offset(polyX + 15, centerY - 10), Colors.purple, 9);
      }
    }
  }

  String _getComplement(String base) {
    switch (base) {
      case 'A': return 'T';
      case 'T': return 'A';
      case 'G': return 'C';
      case 'C': return 'G';
      default: return '';
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize,
      {FontWeight fontWeight = FontWeight.normal}) {
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
  bool shouldRepaint(covariant _DnaReplicationPainter oldDelegate) {
    return oldDelegate.replicationProgress != replicationProgress ||
           oldDelegate.showLabels != showLabels;
  }
}
