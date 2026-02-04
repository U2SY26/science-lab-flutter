import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// Wave Reflection simulation
class WaveReflectionScreen extends StatefulWidget {
  const WaveReflectionScreen({super.key});

  @override
  State<WaveReflectionScreen> createState() => _WaveReflectionScreenState();
}

class _WaveReflectionScreenState extends State<WaveReflectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Parameters
  double amplitude = 40.0;
  double wavelength = 80.0;
  double pulsePosition = 0.0;
  int boundaryType = 0; // 0: fixed end, 1: free end

  bool isRunning = false;
  bool isKorean = true;
  bool hasReflected = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updatePhysics);
    _controller.repeat();
  }

  void _updatePhysics() {
    if (!isRunning) return;

    setState(() {
      pulsePosition += 2;

      if (pulsePosition > 300) {
        hasReflected = true;
      }

      if (pulsePosition > 600) {
        _reset();
      }
    });
  }

  void _reset() {
    setState(() {
      pulsePosition = 0;
      isRunning = false;
      hasReflected = false;
    });
  }

  void _sendPulse() {
    HapticFeedback.selectionClick();
    setState(() {
      pulsePosition = 0;
      hasReflected = false;
      isRunning = true;
    });
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
              isKorean ? '파동 역학' : 'WAVE MECHANICS',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              isKorean ? '파동의 반사' : 'Wave Reflection',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Text(
              isKorean ? 'EN' : '한',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: () => setState(() => isKorean = !isKorean),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: isKorean ? '파동 역학' : 'Wave Mechanics',
          title: isKorean ? '파동의 반사' : 'Wave Reflection',
          formula: boundaryType == 0 ? 'Fixed End: Phase Inverted' : 'Free End: Phase Preserved',
          formulaDescription: isKorean
              ? (boundaryType == 0
                  ? '고정단에서 파동은 위상이 180° 반전되어 반사됩니다.'
                  : '자유단에서 파동은 위상 변화 없이 반사됩니다.')
              : (boundaryType == 0
                  ? 'At a fixed end, the wave reflects with a 180° phase inversion.'
                  : 'At a free end, the wave reflects without phase change.'),
          simulation: CustomPaint(
            painter: WaveReflectionPainter(
              amplitude: amplitude,
              wavelength: wavelength,
              pulsePosition: pulsePosition,
              boundaryType: boundaryType,
              hasReflected: hasReflected,
              isKorean: isKorean,
            ),
            size: Size.infinite,
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Boundary type selection
              SimSegment<int>(
                label: isKorean ? '경계 조건' : 'Boundary Type',
                options: {
                  0: isKorean ? '고정단' : 'Fixed End',
                  1: isKorean ? '자유단' : 'Free End',
                },
                selected: boundaryType,
                onChanged: (v) => setState(() {
                  boundaryType = v;
                  _reset();
                }),
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: isKorean ? '진폭 (A)' : 'Amplitude (A)',
                  value: amplitude,
                  min: 20,
                  max: 60,
                  defaultValue: 40,
                  formatValue: (v) => '${v.toStringAsFixed(0)} px',
                  onChanged: (v) => setState(() => amplitude = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: isKorean ? '파장 (λ)' : 'Wavelength (λ)',
                    value: wavelength,
                    min: 40,
                    max: 120,
                    defaultValue: 80,
                    formatValue: (v) => '${v.toStringAsFixed(0)} px',
                    onChanged: (v) => setState(() => wavelength = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ReflectionInfo(
                boundaryType: boundaryType,
                hasReflected: hasReflected,
                isKorean: isKorean,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isKorean ? '펄스 보내기' : 'Send Pulse',
                icon: Icons.send,
                isPrimary: true,
                onPressed: _sendPulse,
              ),
              SimButton(
                label: isKorean ? '리셋' : 'Reset',
                icon: Icons.refresh,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _reset();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReflectionInfo extends StatelessWidget {
  final int boundaryType;
  final bool hasReflected;
  final bool isKorean;

  const _ReflectionInfo({
    required this.boundaryType,
    required this.hasReflected,
    required this.isKorean,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              Icon(
                boundaryType == 0 ? Icons.lock : Icons.lock_open,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                boundaryType == 0
                    ? (isKorean ? '고정단 반사' : 'Fixed End Reflection')
                    : (isKorean ? '자유단 반사' : 'Free End Reflection'),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            boundaryType == 0
                ? (isKorean
                    ? '• 경계점이 고정되어 움직일 수 없음\n• 반사파의 위상이 180° 반전\n• 입사파와 반사파가 상쇄 간섭'
                    : '• Boundary point cannot move\n• Reflected wave phase inverted by 180°\n• Incident and reflected waves interfere destructively')
                : (isKorean
                    ? '• 경계점이 자유롭게 움직임\n• 반사파의 위상이 유지됨\n• 입사파와 반사파가 보강 간섭'
                    : '• Boundary point moves freely\n• Reflected wave phase preserved\n• Incident and reflected waves interfere constructively'),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          if (hasReflected) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent2.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isKorean ? '반사됨!' : 'Reflected!',
                style: TextStyle(
                  color: AppColors.accent2,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WaveReflectionPainter extends CustomPainter {
  final double amplitude;
  final double wavelength;
  final double pulsePosition;
  final int boundaryType;
  final bool hasReflected;
  final bool isKorean;

  WaveReflectionPainter({
    required this.amplitude,
    required this.wavelength,
    required this.pulsePosition,
    required this.boundaryType,
    required this.hasReflected,
    required this.isKorean,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    _drawGrid(canvas, size);

    final startX = 50.0;
    final endX = size.width - 50;
    final centerY = size.height / 2;
    final boundaryX = endX - 30;

    // Draw rope/string baseline
    canvas.drawLine(
      Offset(startX, centerY),
      Offset(boundaryX, centerY),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..strokeWidth = 2,
    );

    // Draw boundary
    _drawBoundary(canvas, Offset(boundaryX, centerY), boundaryType);

    // Calculate wave positions
    final incidentEnd = pulsePosition.clamp(0.0, boundaryX - startX);
    final reflectedStart = hasReflected ? (pulsePosition - (boundaryX - startX)) : 0.0;

    // Draw incident pulse
    if (pulsePosition < boundaryX - startX + wavelength) {
      _drawPulse(
        canvas,
        startX,
        centerY,
        incidentEnd,
        amplitude,
        wavelength,
        AppColors.accent,
        false,
      );
    }

    // Draw reflected pulse
    if (hasReflected && reflectedStart > 0) {
      final reflectedEnd = (boundaryX - startX - reflectedStart).clamp(0.0, boundaryX - startX);
      _drawPulse(
        canvas,
        startX + reflectedEnd,
        centerY,
        boundaryX - startX - reflectedEnd,
        amplitude,
        wavelength,
        AppColors.accent2,
        boundaryType == 0, // Invert for fixed end
      );
    }

    // Draw source
    _drawSource(canvas, Offset(startX - 20, centerY));

    // Labels
    _drawText(canvas, isKorean ? '입사파' : 'Incident', Offset(startX + 20, centerY - amplitude - 20), AppColors.accent, 11);
    if (hasReflected) {
      _drawText(canvas, isKorean ? '반사파' : 'Reflected', Offset(startX + 20, centerY + amplitude + 10), AppColors.accent2, 11);
    }

    // Phase diagram
    _drawPhaseDiagram(canvas, size, boundaryType);
  }

  void _drawPulse(Canvas canvas, double startX, double centerY, double length,
      double amp, double wl, Color color, bool inverted) {
    final path = Path();
    bool started = false;

    for (double x = 0; x <= length && x <= wl; x += 2) {
      final phase = x / wl * math.pi;
      final y = centerY - (inverted ? -1 : 1) * amp * math.sin(phase);

      if (!started) {
        path.moveTo(startX + x, y);
        started = true;
      } else {
        path.lineTo(startX + x, y);
      }
    }

    // Rest of the string at baseline
    if (length > wl) {
      path.lineTo(startX + length, centerY);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawBoundary(Canvas canvas, Offset position, int type) {
    if (type == 0) {
      // Fixed end - wall
      canvas.drawRect(
        Rect.fromCenter(center: position, width: 10, height: 80),
        Paint()..color = AppColors.pivot,
      );
      canvas.drawRect(
        Rect.fromCenter(center: position, width: 10, height: 80),
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Hash marks for fixed support
      for (double y = position.dy - 35; y <= position.dy + 35; y += 10) {
        canvas.drawLine(
          Offset(position.dx + 5, y),
          Offset(position.dx + 15, y - 10),
          Paint()
            ..color = AppColors.muted
            ..strokeWidth = 1,
        );
      }
    } else {
      // Free end - ring on rod
      canvas.drawLine(
        Offset(position.dx, position.dy - 40),
        Offset(position.dx, position.dy + 40),
        Paint()
          ..color = AppColors.muted
          ..strokeWidth = 3,
      );
      canvas.drawCircle(
        position,
        8,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  void _drawSource(Canvas canvas, Offset position) {
    canvas.drawCircle(
      position,
      15,
      Paint()..color = AppColors.accent.withValues(alpha: 0.3),
    );
    canvas.drawCircle(
      position,
      10,
      Paint()..color = AppColors.accent,
    );
  }

  void _drawPhaseDiagram(Canvas canvas, Size size, int type) {
    final boxX = 20.0;
    final boxY = size.height - 80;
    final boxWidth = 120.0;
    final boxHeight = 60.0;

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(boxX, boxY, boxWidth, boxHeight),
        const Radius.circular(8),
      ),
      Paint()..color = AppColors.card.withValues(alpha: 0.8),
    );

    // Title
    _drawText(canvas, isKorean ? '위상 변화' : 'Phase Change', Offset(boxX + 10, boxY + 5), AppColors.muted, 9);

    // Incident wave symbol
    _drawMiniWave(canvas, Offset(boxX + 20, boxY + 35), 20, false, AppColors.accent);
    _drawText(canvas, '→', Offset(boxX + 45, boxY + 28), AppColors.muted, 12);

    // Reflected wave symbol
    _drawMiniWave(canvas, Offset(boxX + 70, boxY + 35), 20, type == 0, AppColors.accent2);

    // Phase label
    _drawText(
      canvas,
      type == 0 ? '180°' : '0°',
      Offset(boxX + 95, boxY + 28),
      type == 0 ? AppColors.accent2 : AppColors.accent,
      11,
    );
  }

  void _drawMiniWave(Canvas canvas, Offset center, double width, bool inverted, Color color) {
    final path = Path();
    for (double x = 0; x <= width; x += 2) {
      final y = center.dy - (inverted ? -1 : 1) * 8 * math.sin(x / width * math.pi);
      if (x == 0) {
        path.moveTo(center.dx - width / 2 + x, y);
      } else {
        path.lineTo(center.dx - width / 2 + x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant WaveReflectionPainter oldDelegate) => true;
}
