import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 길이 수축 시뮬레이션 화면 (Length Contraction)
/// 특수 상대성 이론의 길이 수축 효과를 시각화합니다.
class LengthContractionScreen extends StatefulWidget {
  const LengthContractionScreen({super.key});

  @override
  State<LengthContractionScreen> createState() => _LengthContractionScreenState();
}

class _LengthContractionScreenState extends State<LengthContractionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 물리 파라미터
  static const double _defaultVelocity = 0.0;
  static const double _defaultRestLength = 100.0; // 정지 길이 (픽셀)

  double velocity = _defaultVelocity; // v/c 비율
  double restLength = _defaultRestLength;
  bool isRunning = true;
  bool showComparison = true;

  // 애니메이션 위치
  double objectPosition = 0;

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
      // 물체의 움직임 (화면을 가로질러 이동)
      objectPosition += velocity * 3; // 속도에 비례한 이동
      if (objectPosition > 400) {
        objectPosition = -200;
      }
    });
  }

  double _calculateLorentzFactor(double v) {
    if (v >= 1) return double.infinity;
    return 1 / math.sqrt(1 - v * v);
  }

  // 수축된 길이 계산: L' = L * sqrt(1 - v^2/c^2) = L / gamma
  double get contractedLength {
    final gamma = _calculateLorentzFactor(velocity);
    return restLength / gamma;
  }

  double get lorentzFactor => _calculateLorentzFactor(velocity);

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      objectPosition = 0;
      velocity = _defaultVelocity;
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
              '상대성 이론',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '길이 수축 (Length Contraction)',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              showComparison ? Icons.compare_arrows : Icons.compare_arrows_outlined,
              color: showComparison ? AppColors.accent : AppColors.muted,
            ),
            onPressed: () => setState(() => showComparison = !showComparison),
            tooltip: '비교 표시',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '상대성 이론',
          title: '길이 수축 (Length Contraction)',
          formula: "L' = L * sqrt(1 - v^2/c^2)",
          formulaDescription:
              '빠르게 움직이는 물체는 운동 방향으로 길이가 수축합니다. '
              '정지한 관찰자가 볼 때 움직이는 물체의 길이는 정지 길이보다 짧아집니다. '
              '속도가 광속에 가까워질수록 수축 효과가 커집니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: LengthContractionPainter(
                velocity: velocity,
                restLength: restLength,
                contractedLength: contractedLength,
                objectPosition: objectPosition,
                lorentzFactor: lorentzFactor,
                showComparison: showComparison,
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 속도 프리셋
              PresetGroup(
                label: '속도 프리셋',
                presets: [
                  PresetButton(
                    label: '정지',
                    isSelected: velocity == 0,
                    onPressed: () => setState(() => velocity = 0),
                  ),
                  PresetButton(
                    label: '0.5c',
                    isSelected: velocity == 0.5,
                    onPressed: () => setState(() => velocity = 0.5),
                  ),
                  PresetButton(
                    label: '0.8c',
                    isSelected: velocity == 0.8,
                    onPressed: () => setState(() => velocity = 0.8),
                  ),
                  PresetButton(
                    label: '0.9c',
                    isSelected: velocity == 0.9,
                    onPressed: () => setState(() => velocity = 0.9),
                  ),
                  PresetButton(
                    label: '0.99c',
                    isSelected: velocity == 0.99,
                    onPressed: () => setState(() => velocity = 0.99),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 컨트롤 그룹
              ControlGroup(
                primaryControl: SimSlider(
                  label: '속도 (v/c)',
                  value: velocity,
                  min: 0,
                  max: 0.99,
                  step: 0.01,
                  defaultValue: _defaultVelocity,
                  formatValue: (v) => '${(v * 100).toStringAsFixed(0)}% c',
                  onChanged: (v) => setState(() => velocity = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '정지 길이 (L)',
                    value: restLength,
                    min: 50,
                    max: 150,
                    step: 10,
                    defaultValue: _defaultRestLength,
                    formatValue: (v) => '${v.toInt()} px',
                    onChanged: (v) => setState(() => restLength = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 물리량 표시
              _PhysicsInfo(
                lorentzFactor: lorentzFactor,
                restLength: restLength,
                contractedLength: contractedLength,
                contractionRatio: contractedLength / restLength,
              ),
            ],
          ),
          buttons: SimButtonGroup(
            expanded: true,
            buttons: [
              SimButton(
                label: isRunning ? '정지' : '재생',
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => isRunning = !isRunning);
                },
              ),
              SimButton(
                label: '리셋',
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

/// 물리량 정보 위젯
class _PhysicsInfo extends StatelessWidget {
  final double lorentzFactor;
  final double restLength;
  final double contractedLength;
  final double contractionRatio;

  const _PhysicsInfo({
    required this.lorentzFactor,
    required this.restLength,
    required this.contractedLength,
    required this.contractionRatio,
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
        children: [
          Row(
            children: [
              _InfoItem(
                label: '로렌츠 인자 (gamma)',
                value: lorentzFactor.toStringAsFixed(3),
              ),
              _InfoItem(
                label: '수축 비율',
                value: '${(contractionRatio * 100).toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: '정지 길이 (L)',
                value: '${restLength.toStringAsFixed(0)} px',
              ),
              _InfoItem(
                label: "수축 길이 (L')",
                value: '${contractedLength.toStringAsFixed(1)} px',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 길이 수축 시뮬레이션 페인터
class LengthContractionPainter extends CustomPainter {
  final double velocity;
  final double restLength;
  final double contractedLength;
  final double objectPosition;
  final double lorentzFactor;
  final bool showComparison;

  LengthContractionPainter({
    required this.velocity,
    required this.restLength,
    required this.contractedLength,
    required this.objectPosition,
    required this.lorentzFactor,
    required this.showComparison,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.simBg,
    );

    // 그리드
    _drawGrid(canvas, size);

    // 정지한 물체 (비교용, 상단)
    if (showComparison) {
      _drawObject(
        canvas,
        Offset(size.width / 2, size.height * 0.25),
        restLength,
        '정지 상태 (Rest Frame)',
        AppColors.muted,
        false,
      );
    }

    // 움직이는 물체 (하단)
    final movingY = showComparison ? size.height * 0.55 : size.height * 0.4;
    _drawObject(
      canvas,
      Offset(size.width / 2 + objectPosition, movingY),
      contractedLength,
      velocity > 0 ? '이동 중 (Moving)' : '정지 상태',
      AppColors.accent,
      velocity > 0,
    );

    // 길이 비교 눈금자
    _drawRuler(canvas, size);

    // 수축 비율 표시
    _drawContractionInfo(canvas, size);
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

  void _drawObject(
    Canvas canvas,
    Offset center,
    double length,
    String label,
    Color color,
    bool isMoving,
  ) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: length,
        height: 40,
      ),
      const Radius.circular(8),
    );

    // 그림자
    canvas.drawRRect(
      rect.shift(const Offset(3, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // 물체 본체
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0.8),
        color.withValues(alpha: 0.4),
      ],
    ).createShader(rect.outerRect);

    canvas.drawRRect(
      rect,
      Paint()..shader = gradient,
    );

    // 테두리
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 속도 화살표 (움직이는 경우)
    if (isMoving) {
      final arrowY = center.dy;
      final arrowStart = Offset(center.dx + length / 2 + 10, arrowY);
      final arrowEnd = Offset(center.dx + length / 2 + 30 + velocity * 30, arrowY);

      canvas.drawLine(
        arrowStart,
        arrowEnd,
        Paint()
          ..color = AppColors.accent2
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );

      // 화살표 머리
      final arrowPath = Path()
        ..moveTo(arrowEnd.dx + 8, arrowY)
        ..lineTo(arrowEnd.dx - 4, arrowY - 6)
        ..lineTo(arrowEnd.dx - 4, arrowY + 6)
        ..close();
      canvas.drawPath(arrowPath, Paint()..color = AppColors.accent2);
    }

    // 라벨
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 30),
    );

    // 길이 표시
    final lengthText = '${length.toStringAsFixed(1)} px';
    final lengthPainter = TextPainter(
      text: TextSpan(
        text: lengthText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    lengthPainter.paint(
      canvas,
      Offset(center.dx - lengthPainter.width / 2, center.dy - 6),
    );
  }

  void _drawRuler(Canvas canvas, Size size) {
    final rulerY = size.height * 0.82;
    final rulerStart = size.width * 0.15;
    final rulerEnd = size.width * 0.85;

    // 눈금자 라인
    canvas.drawLine(
      Offset(rulerStart, rulerY),
      Offset(rulerEnd, rulerY),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.5)
        ..strokeWidth = 1,
    );

    // 눈금
    const tickSpacing = 20.0;
    for (double x = rulerStart; x <= rulerEnd; x += tickSpacing) {
      final isMajor = ((x - rulerStart) / tickSpacing).round() % 5 == 0;
      canvas.drawLine(
        Offset(x, rulerY - (isMajor ? 8 : 4)),
        Offset(x, rulerY + (isMajor ? 8 : 4)),
        Paint()
          ..color = AppColors.muted.withValues(alpha: 0.5)
          ..strokeWidth = isMajor ? 1.5 : 1,
      );
    }
  }

  void _drawContractionInfo(Canvas canvas, Size size) {
    final ratio = contractedLength / restLength;
    final text = "L' / L = ${ratio.toStringAsFixed(3)}";

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height - 35),
    );
  }

  @override
  bool shouldRepaint(covariant LengthContractionPainter oldDelegate) => true;
}
