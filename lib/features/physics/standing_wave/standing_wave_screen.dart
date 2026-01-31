import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 정상파 시뮬레이션
class StandingWaveScreen extends StatefulWidget {
  const StandingWaveScreen({super.key});

  @override
  State<StandingWaveScreen> createState() => _StandingWaveScreenState();
}

class _StandingWaveScreenState extends State<StandingWaveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  int _harmonicNumber = 1; // n = 1, 2, 3, ...
  double _amplitude = 50;
  double _stringLength = 1.0; // m
  bool _showNodes = true;
  bool _showEnvelope = true;

  double get _wavelength => 2 * _stringLength / _harmonicNumber;
  double get _frequency => _harmonicNumber * 1.0; // 기본 진동수의 n배

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
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
              '물리학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '정상파',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리학',
          title: '정상파',
          formula: 'λₙ = 2L/n, fₙ = nf₁',
          formulaDescription: '양 끝이 고정된 현에서 형성되는 정상파 (배음)',
          simulation: SizedBox(
            height: 350,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _StandingWavePainter(
                    harmonicNumber: _harmonicNumber,
                    amplitude: _amplitude,
                    time: _controller.value,
                    showNodes: _showNodes,
                    showEnvelope: _showEnvelope,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 정보 표시
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
                          label: '배음 번호',
                          value: 'n = $_harmonicNumber',
                          color: AppColors.accent,
                        ),
                        _InfoItem(
                          label: '파장',
                          value: 'λ = ${_wavelength.toStringAsFixed(2)} m',
                          color: Colors.cyan,
                        ),
                        _InfoItem(
                          label: '진동수',
                          value: 'f = ${_frequency.toStringAsFixed(1)}f₁',
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoItem(
                          label: '마디 수',
                          value: '${_harmonicNumber + 1}개',
                          color: Colors.red,
                        ),
                        _InfoItem(
                          label: '배 수',
                          value: '$_harmonicNumber개',
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 옵션 토글
              Row(
                children: [
                  Expanded(
                    child: _OptionChip(
                      label: '마디/배 표시',
                      isSelected: _showNodes,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showNodes = !_showNodes);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _OptionChip(
                      label: '포락선 표시',
                      isSelected: _showEnvelope,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _showEnvelope = !_showEnvelope);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 배음 선택
              PresetGroup(
                label: '배음 선택',
                presets: [
                  PresetButton(
                    label: '기본음',
                    isSelected: _harmonicNumber == 1,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _harmonicNumber = 1);
                    },
                  ),
                  PresetButton(
                    label: '2차',
                    isSelected: _harmonicNumber == 2,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _harmonicNumber = 2);
                    },
                  ),
                  PresetButton(
                    label: '3차',
                    isSelected: _harmonicNumber == 3,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _harmonicNumber = 3);
                    },
                  ),
                  PresetButton(
                    label: '4차',
                    isSelected: _harmonicNumber == 4,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _harmonicNumber = 4);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              ControlGroup(
                primaryControl: SimSlider(
                  label: '배음 번호 (n)',
                  value: _harmonicNumber.toDouble(),
                  min: 1,
                  max: 8,
                  defaultValue: 1,
                  formatValue: (v) => 'n = ${v.toInt()}',
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _harmonicNumber = v.toInt());
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '진폭',
                    value: _amplitude,
                    min: 20,
                    max: 80,
                    defaultValue: 50,
                    formatValue: (v) => '${v.toInt()}',
                    onChanged: (v) => setState(() => _amplitude = v),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '기본음 (n=1)',
                icon: Icons.music_note,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _harmonicNumber = 1);
                },
              ),
              SimButton(
                label: '5차 배음',
                icon: Icons.graphic_eq,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _harmonicNumber = 5);
                },
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
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : AppColors.simBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.accent : AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: isSelected ? AppColors.accent : AppColors.muted, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _StandingWavePainter extends CustomPainter {
  final int harmonicNumber;
  final double amplitude;
  final double time;
  final bool showNodes;
  final bool showEnvelope;

  _StandingWavePainter({
    required this.harmonicNumber,
    required this.amplitude,
    required this.time,
    required this.showNodes,
    required this.showEnvelope,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerY = size.height / 2;
    final padding = 40.0;
    final waveWidth = size.width - padding * 2;

    // 고정점 (끝점)
    canvas.drawCircle(
      Offset(padding, centerY),
      6,
      Paint()..color = AppColors.muted,
    );
    canvas.drawCircle(
      Offset(size.width - padding, centerY),
      6,
      Paint()..color = AppColors.muted,
    );

    // 평형선
    canvas.drawLine(
      Offset(padding, centerY),
      Offset(size.width - padding, centerY),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.3)
        ..strokeWidth = 1,
    );

    // 포락선 (최대 진폭 범위)
    if (showEnvelope) {
      final envelopePath = Path();
      final envelopePathNeg = Path();

      for (double x = 0; x <= waveWidth; x += 2) {
        final normalizedX = x / waveWidth;
        final spatialPart = math.sin(harmonicNumber * math.pi * normalizedX);
        final y = amplitude * spatialPart.abs();

        if (x == 0) {
          envelopePath.moveTo(padding + x, centerY - y);
          envelopePathNeg.moveTo(padding + x, centerY + y);
        } else {
          envelopePath.lineTo(padding + x, centerY - y);
          envelopePathNeg.lineTo(padding + x, centerY + y);
        }
      }

      canvas.drawPath(
        envelopePath,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.2)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
      canvas.drawPath(
        envelopePathNeg,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.2)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }

    // 정상파
    final wavePath = Path();
    final omega = 2 * math.pi;

    for (double x = 0; x <= waveWidth; x += 2) {
      final normalizedX = x / waveWidth;
      final spatialPart = math.sin(harmonicNumber * math.pi * normalizedX);
      final temporalPart = math.cos(omega * time);
      final y = amplitude * spatialPart * temporalPart;

      if (x == 0) {
        wavePath.moveTo(padding + x, centerY - y);
      } else {
        wavePath.lineTo(padding + x, centerY - y);
      }
    }

    canvas.drawPath(
      wavePath,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 마디와 배 표시
    if (showNodes) {
      // 마디 (nodes) - 항상 정지
      for (int i = 0; i <= harmonicNumber; i++) {
        final nodeX = padding + (i / harmonicNumber) * waveWidth;
        canvas.drawCircle(
          Offset(nodeX, centerY),
          8,
          Paint()..color = Colors.red.withValues(alpha: 0.3),
        );
        canvas.drawCircle(
          Offset(nodeX, centerY),
          4,
          Paint()..color = Colors.red,
        );

        // 라벨
        _drawText(canvas, 'N', Offset(nodeX - 4, centerY + 15), Colors.red, fontSize: 10);
      }

      // 배 (antinodes) - 최대 진폭
      for (int i = 0; i < harmonicNumber; i++) {
        final antinodeX = padding + ((i + 0.5) / harmonicNumber) * waveWidth;
        final temporalPart = math.cos(omega * time);
        final antinodeY = centerY - amplitude * temporalPart;

        canvas.drawCircle(
          Offset(antinodeX, antinodeY),
          6,
          Paint()..color = Colors.green,
        );

        // 라벨
        _drawText(canvas, 'A', Offset(antinodeX - 4, centerY - amplitude - 20), Colors.green, fontSize: 10);
      }
    }

    // 범례
    if (showNodes) {
      _drawText(canvas, 'N: 마디 (Node)', Offset(padding, size.height - 30), Colors.red, fontSize: 10);
      _drawText(canvas, 'A: 배 (Antinode)', Offset(padding + 100, size.height - 30), Colors.green, fontSize: 10);
    }

    // 배음 라벨
    String harmonicName;
    switch (harmonicNumber) {
      case 1:
        harmonicName = '기본 진동 (1차 배음)';
        break;
      case 2:
        harmonicName = '2차 배음 (1옥타브 위)';
        break;
      case 3:
        harmonicName = '3차 배음';
        break;
      default:
        harmonicName = '$harmonicNumber차 배음';
    }
    _drawText(canvas, harmonicName, Offset(size.width / 2 - 60, 20), AppColors.ink, fontSize: 12, fontWeight: FontWeight.bold);
  }

  void _drawText(Canvas canvas, String text, Offset pos, Color color, {double fontSize = 12, FontWeight fontWeight = FontWeight.normal}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _StandingWavePainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.harmonicNumber != harmonicNumber;
  }
}
