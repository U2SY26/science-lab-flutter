import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/language_provider.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Emission Spectrum Simulation
class EmissionSpectrumScreen extends ConsumerStatefulWidget {
  const EmissionSpectrumScreen({super.key});

  @override
  ConsumerState<EmissionSpectrumScreen> createState() => _EmissionSpectrumScreenState();
}

class _EmissionSpectrumScreenState extends ConsumerState<EmissionSpectrumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Selected element
  String _selectedElement = 'H';
  bool _showAbsorption = false;

  // Element emission lines (wavelength in nm)
  final Map<String, List<double>> _emissionLines = {
    'H': [410.2, 434.0, 486.1, 656.3], // Balmer series
    'He': [388.9, 447.1, 471.3, 492.2, 501.6, 587.6, 667.8],
    'Na': [589.0, 589.6], // Sodium doublet
    'Ne': [585.2, 588.2, 603.0, 607.4, 616.4, 621.7, 626.6, 633.4, 640.2, 650.6],
    'Hg': [404.7, 435.8, 546.1, 577.0, 579.1],
    'Li': [610.4, 670.8],
  };

  // Energy levels for visualization (simplified)
  final Map<String, List<double>> _energyLevels = {
    'H': [-13.6, -3.4, -1.5, -0.85, -0.54, 0],
    'He': [-24.6, -4.8, -1.5, 0],
    'Na': [-5.1, -3.0, -1.5, 0],
    'Ne': [-21.6, -4.9, -1.5, 0],
    'Hg': [-10.4, -5.5, -1.6, 0],
    'Li': [-5.4, -3.5, -1.5, 0],
  };

  double _animationPhase = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(() {
      setState(() {
        _animationPhase += 0.05;
      });
    });
    _controller.repeat();
  }

  Color _wavelengthToColor(double wavelength) {
    // Convert wavelength (nm) to RGB color
    double r = 0, g = 0, b = 0;

    if (wavelength >= 380 && wavelength < 440) {
      r = -(wavelength - 440) / (440 - 380);
      g = 0;
      b = 1;
    } else if (wavelength >= 440 && wavelength < 490) {
      r = 0;
      g = (wavelength - 440) / (490 - 440);
      b = 1;
    } else if (wavelength >= 490 && wavelength < 510) {
      r = 0;
      g = 1;
      b = -(wavelength - 510) / (510 - 490);
    } else if (wavelength >= 510 && wavelength < 580) {
      r = (wavelength - 510) / (580 - 510);
      g = 1;
      b = 0;
    } else if (wavelength >= 580 && wavelength < 645) {
      r = 1;
      g = -(wavelength - 645) / (645 - 580);
      b = 0;
    } else if (wavelength >= 645 && wavelength <= 780) {
      r = 1;
      g = 0;
      b = 0;
    }

    return Color.fromRGBO(
      (r * 255).round(),
      (g * 255).round(),
      (b * 255).round(),
      1,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(languageProvider.notifier).isKorean;

    final lines = _emissionLines[_selectedElement] ?? [];

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
              isKorean ? '화학' : 'CHEMISTRY',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '방출 스펙트럼' : 'Emission Spectrum',
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '화학' : 'Chemistry',
          title: isKorean ? '방출 스펙트럼' : 'Emission Spectrum',
          formula: 'E = hf = hc/l',
          formulaDescription: isKorean
              ? '전자가 높은 에너지 준위에서 낮은 준위로 전이할 때 특정 파장의 빛을 방출합니다.'
              : 'When electrons transition from higher to lower energy levels, they emit light of specific wavelengths.',
          simulation: SizedBox(
            height: 400,
            child: CustomPaint(
              painter: _EmissionSpectrumPainter(
                element: _selectedElement,
                emissionLines: lines,
                energyLevels: _energyLevels[_selectedElement] ?? [],
                showAbsorption: _showAbsorption,
                animationPhase: _animationPhase,
                wavelengthToColor: _wavelengthToColor,
                isKorean: isKorean,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Element info
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getElementName(_selectedElement, isKorean),
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${lines.length} ${isKorean ? '선' : 'lines'}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Show wavelengths
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: lines.map((wl) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _wavelengthToColor(wl).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _wavelengthToColor(wl)),
                        ),
                        child: Text(
                          '${wl.toInt()} nm',
                          style: TextStyle(
                            color: _wavelengthToColor(wl),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Element selection
              PresetGroup(
                label: isKorean ? '원소' : 'Element',
                presets: [
                  PresetButton(
                    label: 'H',
                    isSelected: _selectedElement == 'H',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedElement = 'H');
                    },
                  ),
                  PresetButton(
                    label: 'He',
                    isSelected: _selectedElement == 'He',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedElement = 'He');
                    },
                  ),
                  PresetButton(
                    label: 'Na',
                    isSelected: _selectedElement == 'Na',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedElement = 'Na');
                    },
                  ),
                  PresetButton(
                    label: 'Ne',
                    isSelected: _selectedElement == 'Ne',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedElement = 'Ne');
                    },
                  ),
                  PresetButton(
                    label: 'Hg',
                    isSelected: _selectedElement == 'Hg',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedElement = 'Hg');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Toggle absorption/emission
              Row(
                children: [
                  Switch(
                    value: _showAbsorption,
                    onChanged: (v) => setState(() => _showAbsorption = v),
                    activeColor: AppColors.accent,
                  ),
                  Text(
                    isKorean ? '흡수 스펙트럼 표시' : 'Show Absorption Spectrum',
                    style: const TextStyle(color: AppColors.ink),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getElementName(String symbol, bool isKorean) {
    final names = {
      'H': isKorean ? '수소 (H)' : 'Hydrogen (H)',
      'He': isKorean ? '헬륨 (He)' : 'Helium (He)',
      'Na': isKorean ? '나트륨 (Na)' : 'Sodium (Na)',
      'Ne': isKorean ? '네온 (Ne)' : 'Neon (Ne)',
      'Hg': isKorean ? '수은 (Hg)' : 'Mercury (Hg)',
      'Li': isKorean ? '리튬 (Li)' : 'Lithium (Li)',
    };
    return names[symbol] ?? symbol;
  }
}

class _EmissionSpectrumPainter extends CustomPainter {
  final String element;
  final List<double> emissionLines;
  final List<double> energyLevels;
  final bool showAbsorption;
  final double animationPhase;
  final Color Function(double) wavelengthToColor;
  final bool isKorean;

  _EmissionSpectrumPainter({
    required this.element,
    required this.emissionLines,
    required this.energyLevels,
    required this.showAbsorption,
    required this.animationPhase,
    required this.wavelengthToColor,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // Draw spectrum (top section)
    _drawSpectrum(canvas, Rect.fromLTWH(0, 0, size.width, size.height * 0.35));

    // Draw energy level diagram (bottom section)
    _drawEnergyLevels(canvas, Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.6));
  }

  void _drawSpectrum(Canvas canvas, Rect bounds) {
    final spectrumHeight = bounds.height * 0.6;
    final spectrumTop = bounds.top + 30;

    // Title
    _drawText(canvas, showAbsorption
        ? (isKorean ? '흡수 스펙트럼' : 'Absorption Spectrum')
        : (isKorean ? '방출 스펙트럼' : 'Emission Spectrum'),
        Offset(bounds.left + 10, bounds.top + 5), AppColors.accent, 12, fontWeight: FontWeight.bold);

    if (showAbsorption) {
      // Draw continuous spectrum with dark lines
      for (double x = bounds.left; x < bounds.right; x++) {
        final wavelength = 380 + (x - bounds.left) / bounds.width * 400;
        canvas.drawLine(
          Offset(x, spectrumTop),
          Offset(x, spectrumTop + spectrumHeight),
          Paint()..color = wavelengthToColor(wavelength),
        );
      }

      // Draw absorption lines (dark)
      for (final wl in emissionLines) {
        final x = bounds.left + (wl - 380) / 400 * bounds.width;
        canvas.drawLine(
          Offset(x, spectrumTop),
          Offset(x, spectrumTop + spectrumHeight),
          Paint()
            ..color = Colors.black
            ..strokeWidth = 3,
        );
      }
    } else {
      // Draw black background
      canvas.drawRect(
        Rect.fromLTWH(bounds.left, spectrumTop, bounds.width, spectrumHeight),
        Paint()..color = Colors.black,
      );

      // Draw emission lines
      for (final wl in emissionLines) {
        final x = bounds.left + (wl - 380) / 400 * bounds.width;
        final color = wavelengthToColor(wl);

        // Glow effect
        canvas.drawLine(
          Offset(x, spectrumTop),
          Offset(x, spectrumTop + spectrumHeight),
          Paint()
            ..color = color.withValues(alpha: 0.3)
            ..strokeWidth = 8,
        );
        canvas.drawLine(
          Offset(x, spectrumTop),
          Offset(x, spectrumTop + spectrumHeight),
          Paint()
            ..color = color
            ..strokeWidth = 3,
        );
      }
    }

    // Wavelength scale
    for (int wl = 400; wl <= 700; wl += 50) {
      final x = bounds.left + (wl - 380) / 400 * bounds.width;
      canvas.drawLine(
        Offset(x, spectrumTop + spectrumHeight),
        Offset(x, spectrumTop + spectrumHeight + 5),
        Paint()..color = AppColors.muted,
      );
      _drawText(canvas, '$wl', Offset(x - 12, spectrumTop + spectrumHeight + 8), AppColors.muted, 9);
    }
    _drawText(canvas, 'nm', Offset(bounds.right - 20, spectrumTop + spectrumHeight + 8), AppColors.muted, 9);
  }

  void _drawEnergyLevels(Canvas canvas, Rect bounds) {
    if (energyLevels.isEmpty) return;

    final padding = 40.0;
    final graphWidth = bounds.width - padding * 2;
    final graphHeight = bounds.height - 40;

    // Title
    _drawText(canvas, isKorean ? '에너지 준위 다이어그램' : 'Energy Level Diagram',
        Offset(bounds.left + 10, bounds.top + 5), AppColors.accent, 12, fontWeight: FontWeight.bold);

    // Find energy range
    final minE = energyLevels.reduce(math.min);
    final maxE = energyLevels.reduce(math.max);
    final range = maxE - minE;

    // Draw energy levels
    for (int i = 0; i < energyLevels.length; i++) {
      final e = energyLevels[i];
      final y = bounds.top + 30 + graphHeight * (1 - (e - minE) / range);

      // Level line
      canvas.drawLine(
        Offset(bounds.left + padding, y),
        Offset(bounds.right - padding, y),
        Paint()
          ..color = AppColors.muted.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );

      // Level label
      final label = i == 0 ? 'n=1' : i == energyLevels.length - 1 ? '...' : 'n=${i + 1}';
      _drawText(canvas, label, Offset(bounds.left + 5, y - 6), AppColors.muted, 10);
      _drawText(canvas, '${e.toStringAsFixed(1)} eV', Offset(bounds.right - 45, y - 6), AppColors.muted, 10);
    }

    // Draw transitions (animated)
    if (energyLevels.length >= 2) {
      final transitionIndex = (animationPhase * 2).floor() % (energyLevels.length - 1);
      final fromLevel = transitionIndex + 1;
      final toLevel = 0;

      if (fromLevel < energyLevels.length) {
        final y1 = bounds.top + 30 + graphHeight * (1 - (energyLevels[fromLevel] - minE) / range);
        final y2 = bounds.top + 30 + graphHeight * (1 - (energyLevels[toLevel] - minE) / range);
        final x = bounds.left + padding + graphWidth * 0.5;

        // Transition arrow
        final progress = (animationPhase * 2) % 1;
        final currentY = y1 + (y2 - y1) * progress;

        // Photon
        final photonColor = emissionLines.isNotEmpty
            ? wavelengthToColor(emissionLines[transitionIndex % emissionLines.length])
            : Colors.yellow;

        canvas.drawCircle(
          Offset(x, currentY),
          6,
          Paint()..color = photonColor.withValues(alpha: 0.5),
        );
        canvas.drawCircle(
          Offset(x, currentY),
          4,
          Paint()..color = photonColor,
        );

        // Wavy line (photon emission)
        if (progress > 0.5) {
          final waveX = x + 20 + (progress - 0.5) * 100;
          final path = Path();
          path.moveTo(x + 10, currentY);
          for (double dx = 0; dx < waveX - x - 10; dx += 2) {
            path.lineTo(x + 10 + dx, currentY + math.sin(dx * 0.3) * 5);
          }
          canvas.drawPath(path, Paint()
            ..color = photonColor
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
        }
      }
    }

    // Y-axis label
    _drawText(canvas, isKorean ? '에너지' : 'Energy', Offset(bounds.left + 5, bounds.top + 30), AppColors.muted, 10);
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
  bool shouldRepaint(covariant _EmissionSpectrumPainter oldDelegate) => true;
}
