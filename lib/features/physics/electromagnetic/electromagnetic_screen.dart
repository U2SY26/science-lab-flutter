import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 전자기장 시각화 화면
class ElectromagneticScreen extends StatefulWidget {
  const ElectromagneticScreen({super.key});

  @override
  State<ElectromagneticScreen> createState() => _ElectromagneticScreenState();
}

class _ElectromagneticScreenState extends State<ElectromagneticScreen> {
  // 전하 목록
  List<_Charge> _charges = [];

  // 시각화 옵션
  bool _showFieldLines = true;
  bool _showVectors = true;
  int _fieldLineCount = 12;

  // 선택된 프리셋
  String _selectedPreset = 'dipole';

  @override
  void initState() {
    super.initState();
    _loadPreset('dipole');
  }

  void _loadPreset(String preset) {
    _selectedPreset = preset;
    _charges = [];

    switch (preset) {
      case 'dipole':
        // 쌍극자
        _charges = [
          _Charge(x: 0.35, y: 0.5, q: 1),
          _Charge(x: 0.65, y: 0.5, q: -1),
        ];
        break;
      case 'same':
        // 같은 전하
        _charges = [
          _Charge(x: 0.35, y: 0.5, q: 1),
          _Charge(x: 0.65, y: 0.5, q: 1),
        ];
        break;
      case 'quadrupole':
        // 사중극자
        _charges = [
          _Charge(x: 0.35, y: 0.35, q: 1),
          _Charge(x: 0.65, y: 0.35, q: -1),
          _Charge(x: 0.35, y: 0.65, q: -1),
          _Charge(x: 0.65, y: 0.65, q: 1),
        ];
        break;
      case 'line':
        // 전하 줄
        for (int i = 0; i < 5; i++) {
          _charges.add(_Charge(
            x: 0.2 + i * 0.15,
            y: 0.5,
            q: i % 2 == 0 ? 1 : -1,
          ));
        }
        break;
    }

    setState(() {});
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _loadPreset(_selectedPreset);
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
              '물리',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '전기장 시각화',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '물리',
          title: '전기장 시각화',
          formula: 'E = kQ/r²',
          formulaDescription: '점전하 주변의 전기장 분포를 시각화합니다',
          simulation: SizedBox(
            height: 300,
            child: GestureDetector(
              onTapDown: (details) {
                // 터치로 전하 추가
                final box = context.findRenderObject() as RenderBox;
                final localPos = box.globalToLocal(details.globalPosition);
                final size = box.size;

                if (_charges.length < 8) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _charges.add(_Charge(
                      x: localPos.dx / size.width,
                      y: localPos.dy / size.height,
                      q: _charges.length % 2 == 0 ? 1 : -1,
                    ));
                  });
                }
              },
              child: CustomPaint(
                painter: _ElectricFieldPainter(
                  charges: _charges,
                  showFieldLines: _showFieldLines,
                  showVectors: _showVectors,
                  fieldLineCount: _fieldLineCount,
                ),
                size: Size.infinite,
              ),
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프리셋
              PresetGroup(
                label: '전하 배치',
                presets: [
                  PresetButton(
                    label: '쌍극자',
                    isSelected: _selectedPreset == 'dipole',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _loadPreset('dipole');
                    },
                  ),
                  PresetButton(
                    label: '같은 전하',
                    isSelected: _selectedPreset == 'same',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _loadPreset('same');
                    },
                  ),
                  PresetButton(
                    label: '사중극자',
                    isSelected: _selectedPreset == 'quadrupole',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _loadPreset('quadrupole');
                    },
                  ),
                  PresetButton(
                    label: '전하 줄',
                    isSelected: _selectedPreset == 'line',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _loadPreset('line');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 안내 메시지
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '화면을 터치하여 전하를 추가하세요 (최대 8개)',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ControlGroup(
                primaryControl: SimSlider(
                  label: '전기력선 수',
                  value: _fieldLineCount.toDouble(),
                  min: 6,
                  max: 24,
                  defaultValue: 12,
                  formatValue: (v) => v.toInt().toString(),
                  onChanged: (v) => setState(() => _fieldLineCount = v.toInt()),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ToggleChip(
                      label: '전기력선',
                      value: _showFieldLines,
                      onChanged: (v) => setState(() => _showFieldLines = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleChip(
                      label: '벡터장',
                      value: _showVectors,
                      onChanged: (v) => setState(() => _showVectors = v),
                    ),
                  ),
                ],
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: '초기화',
                icon: Icons.refresh,
                isPrimary: true,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Charge {
  final double x, y;
  final double q; // +1 or -1

  _Charge({required this.x, required this.y, required this.q});
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? AppColors.accent.withValues(alpha: 0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? AppColors.accent : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value ? Icons.visibility : Icons.visibility_off,
              size: 16,
              color: value ? AppColors.accent : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: value ? AppColors.accent : AppColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ElectricFieldPainter extends CustomPainter {
  final List<_Charge> charges;
  final bool showFieldLines;
  final bool showVectors;
  final int fieldLineCount;

  _ElectricFieldPainter({
    required this.charges,
    required this.showFieldLines,
    required this.showVectors,
    required this.fieldLineCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    if (charges.isEmpty) return;

    // 전기장 벡터 그리기
    if (showVectors) {
      _drawVectorField(canvas, size);
    }

    // 전기력선 그리기
    if (showFieldLines) {
      for (final charge in charges) {
        if (charge.q > 0) {
          _drawFieldLinesFromCharge(canvas, size, charge);
        }
      }
    }

    // 전하 그리기
    for (final charge in charges) {
      final pos = Offset(charge.x * size.width, charge.y * size.height);
      final color = charge.q > 0 ? Colors.red : Colors.blue;

      // 글로우
      canvas.drawCircle(
        pos,
        25,
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // 본체
      canvas.drawCircle(pos, 15, Paint()..color = color);

      // 부호
      final textPainter = TextPainter(
        text: TextSpan(
          text: charge.q > 0 ? '+' : '−',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );
    }
  }

  Offset _getFieldAt(double x, double y, Size size) {
    double ex = 0, ey = 0;

    for (final charge in charges) {
      final dx = x - charge.x * size.width;
      final dy = y - charge.y * size.height;
      final r2 = dx * dx + dy * dy;
      final r = math.sqrt(r2);

      if (r > 20) {
        final e = charge.q / r2;
        ex += e * dx / r;
        ey += e * dy / r;
      }
    }

    return Offset(ex, ey);
  }

  void _drawVectorField(Canvas canvas, Size size) {
    const gridSize = 15;
    final cellW = size.width / gridSize;
    final cellH = size.height / gridSize;

    for (int i = 1; i < gridSize; i++) {
      for (int j = 1; j < gridSize; j++) {
        final x = i * cellW;
        final y = j * cellH;

        final field = _getFieldAt(x, y, size);
        final magnitude = math.sqrt(field.dx * field.dx + field.dy * field.dy);

        if (magnitude > 0.0001) {
          final normalizedE = Offset(field.dx / magnitude, field.dy / magnitude);
          final arrowLength = math.min(15.0, magnitude * 500);

          final start = Offset(x, y);
          final end = Offset(
            x + normalizedE.dx * arrowLength,
            y + normalizedE.dy * arrowLength,
          );

          final alpha = math.min(1.0, magnitude * 200);
          final paint = Paint()
            ..color = AppColors.ink.withValues(alpha: alpha * 0.5)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round;

          canvas.drawLine(start, end, paint);

          // 화살표 머리
          final angle = math.atan2(normalizedE.dy, normalizedE.dx);
          const arrowSize = 4.0;
          canvas.drawLine(
            end,
            Offset(
              end.dx - arrowSize * math.cos(angle - 0.5),
              end.dy - arrowSize * math.sin(angle - 0.5),
            ),
            paint,
          );
          canvas.drawLine(
            end,
            Offset(
              end.dx - arrowSize * math.cos(angle + 0.5),
              end.dy - arrowSize * math.sin(angle + 0.5),
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawFieldLinesFromCharge(Canvas canvas, Size size, _Charge charge) {
    final startX = charge.x * size.width;
    final startY = charge.y * size.height;

    for (int i = 0; i < fieldLineCount; i++) {
      final angle = i * 2 * math.pi / fieldLineCount;
      final path = Path();

      double x = startX + 20 * math.cos(angle);
      double y = startY + 20 * math.sin(angle);
      path.moveTo(x, y);

      const steps = 200;
      const stepSize = 3.0;

      for (int step = 0; step < steps; step++) {
        final field = _getFieldAt(x, y, size);
        final magnitude = math.sqrt(field.dx * field.dx + field.dy * field.dy);

        if (magnitude < 0.00001) break;
        if (x < 0 || x > size.width || y < 0 || y > size.height) break;

        // 음전하에 도달했는지 확인
        bool reachedNegative = false;
        for (final c in charges) {
          if (c.q < 0) {
            final dx = x - c.x * size.width;
            final dy = y - c.y * size.height;
            if (dx * dx + dy * dy < 400) {
              reachedNegative = true;
              break;
            }
          }
        }
        if (reachedNegative) break;

        final nx = field.dx / magnitude;
        final ny = field.dy / magnitude;

        x += nx * stepSize;
        y += ny * stepSize;

        path.lineTo(x, y);
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ElectricFieldPainter oldDelegate) => true;
}
