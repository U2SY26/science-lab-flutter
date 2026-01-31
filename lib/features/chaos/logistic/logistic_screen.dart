import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 로지스틱 맵 & 분기 다이어그램 화면
class LogisticScreen extends StatefulWidget {
  const LogisticScreen({super.key});

  @override
  State<LogisticScreen> createState() => _LogisticScreenState();
}

class _LogisticScreenState extends State<LogisticScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 파라미터
  double _r = 2.5; // 성장률 (0~4)
  double _x = 0.5; // 초기값 (0~1)
  bool _isRunning = true;
  bool _showBifurcation = false;

  // 시계열 데이터
  final List<double> _timeSeries = [];
  final int _maxPoints = 100;

  // 분기 다이어그램 데이터
  List<List<double>>? _bifurcationData;

  // 프리셋
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _timeSeries.add(_x);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_update);
    _controller.repeat();
    _computeBifurcation();
  }

  void _update() {
    if (!_isRunning || _showBifurcation) return;

    setState(() {
      // 로지스틱 맵: x_{n+1} = r * x_n * (1 - x_n)
      final newX = _r * _x * (1 - _x);
      _x = newX.clamp(0.0, 1.0);
      _timeSeries.add(_x);
      if (_timeSeries.length > _maxPoints) {
        _timeSeries.removeAt(0);
      }
    });
  }

  void _computeBifurcation() {
    // 분기 다이어그램 계산 (백그라운드에서 수행하면 더 좋음)
    final data = <List<double>>[];
    const rMin = 2.5;
    const rMax = 4.0;
    const steps = 300;

    for (int i = 0; i <= steps; i++) {
      final r = rMin + (rMax - rMin) * i / steps;
      double x = 0.5;

      // 과도 상태 건너뛰기
      for (int j = 0; j < 200; j++) {
        x = r * x * (1 - x);
      }

      // 수렴 후 값 저장
      final values = <double>[];
      for (int j = 0; j < 100; j++) {
        x = r * x * (1 - x);
        if (x.isFinite) {
          values.add(x);
        }
      }
      data.add([r, ...values.toSet()]); // 유일한 값만
    }

    setState(() => _bifurcationData = data);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _x = 0.5;
      _timeSeries.clear();
      _timeSeries.add(_x);
      _selectedPreset = null;
    });
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    _reset();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'stable':
          _r = 2.0;
          break;
        case 'period2':
          _r = 3.2;
          break;
        case 'period4':
          _r = 3.5;
          break;
        case 'chaos':
          _r = 3.9;
          break;
        case 'feigenbaum':
          _r = 3.5699; // 페이겐바움 점 근처
          break;
      }
    });
  }

  // 현재 상태 분석
  String get _stateAnalysis {
    if (_r < 1) return '소멸 (x → 0)';
    if (_r < 3) return '안정 고정점';
    if (_r < 3.449) return '주기 2';
    if (_r < 3.544) return '주기 4';
    if (_r < 3.5699) return '주기 8+';
    return '카오스 영역';
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
              '혼돈 이론',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '로지스틱 맵',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showBifurcation ? Icons.timeline : Icons.account_tree,
              color: AppColors.accent,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _showBifurcation = !_showBifurcation);
            },
            tooltip: _showBifurcation ? '시계열 보기' : '분기도 보기',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '혼돈 이론',
          title: '로지스틱 맵',
          formula: 'x[n+1] = r * x[n] * (1 - x[n])',
          formulaDescription: '단순한 방정식에서 나타나는 결정론적 카오스',
          simulation: SizedBox(
            height: 300,
            child: _showBifurcation
                ? CustomPaint(
                    painter: BifurcationPainter(
                      data: _bifurcationData ?? [],
                      currentR: _r,
                    ),
                    size: Size.infinite,
                  )
                : CustomPaint(
                    painter: TimeSeriesPainter(
                      data: _timeSeries,
                      r: _r,
                    ),
                    size: Size.infinite,
                  ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 프리셋
              PresetGroup(
                label: '동적 상태',
                presets: [
                  PresetButton(
                    label: '안정',
                    isSelected: _selectedPreset == 'stable',
                    onPressed: () => _applyPreset('stable'),
                  ),
                  PresetButton(
                    label: '주기2',
                    isSelected: _selectedPreset == 'period2',
                    onPressed: () => _applyPreset('period2'),
                  ),
                  PresetButton(
                    label: '주기4',
                    isSelected: _selectedPreset == 'period4',
                    onPressed: () => _applyPreset('period4'),
                  ),
                  PresetButton(
                    label: '카오스',
                    isSelected: _selectedPreset == 'chaos',
                    onPressed: () => _applyPreset('chaos'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 상태 정보
              _StateInfo(
                r: _r,
                x: _x,
                stateAnalysis: _stateAnalysis,
                showBifurcation: _showBifurcation,
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: 'r (성장률) - $_stateAnalysis',
                  value: _r,
                  min: 0,
                  max: 4,
                  defaultValue: 2.5,
                  formatValue: (v) => v.toStringAsFixed(3),
                  onChanged: (v) {
                    setState(() {
                      _r = v;
                      _selectedPreset = null;
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '초기값 x(0)',
                    value: _timeSeries.isNotEmpty ? _timeSeries.first : 0.5,
                    min: 0.01,
                    max: 0.99,
                    defaultValue: 0.5,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) {
                      setState(() {
                        _x = v;
                        _timeSeries.clear();
                        _timeSeries.add(v);
                        _selectedPreset = null;
                      });
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
                label: _isRunning ? '정지' : '재생',
                icon: _isRunning ? Icons.pause : Icons.play_arrow,
                isPrimary: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isRunning = !_isRunning);
                },
              ),
              SimButton(
                label: '리셋',
                icon: Icons.refresh,
                onPressed: _reset,
              ),
              SimButton(
                label: _showBifurcation ? '시계열' : '분기도',
                icon: _showBifurcation ? Icons.timeline : Icons.account_tree,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showBifurcation = !_showBifurcation);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상태 정보 위젯
class _StateInfo extends StatelessWidget {
  final double r;
  final double x;
  final String stateAnalysis;
  final bool showBifurcation;

  const _StateInfo({
    required this.r,
    required this.x,
    required this.stateAnalysis,
    required this.showBifurcation,
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
              Expanded(
                child: _InfoChip(
                  label: 'r',
                  value: r.toStringAsFixed(3),
                  icon: Icons.tune,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: 'x(n)',
                  value: x.toStringAsFixed(4),
                  icon: Icons.circle,
                  color: AppColors.accent2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: '상태',
                  value: stateAnalysis,
                  icon: Icons.analytics,
                  color: _getStateColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    showBifurcation
                        ? 'r이 증가하면 주기가 2배씩 늘어나다 카오스로 진입 (페이겐바움 상수)'
                        : 'r ≈ 3.5699에서 카오스가 시작됩니다. 작은 r 변화로 큰 행동 변화!',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor() {
    if (r < 3) return Colors.green;
    if (r < 3.5699) return Colors.orange;
    return Colors.red;
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 시계열 페인터
class TimeSeriesPainter extends CustomPainter {
  final List<double> data;
  final double r;

  TimeSeriesPainter({
    required this.data,
    required this.r,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 40.0;

    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // 그리드
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 10; i++) {
      final x = padding + (size.width - padding * 2) * i / 10;
      final y = padding + (size.height - padding * 2) * i / 10;
      canvas.drawLine(Offset(x, padding), Offset(x, size.height - padding), gridPaint);
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
    }

    if (data.isEmpty) return;

    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;

    // 시계열 그래프 (글로우)
    final glowPath = Path();
    final mainPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / data.length) * graphWidth;
      final y = size.height - padding - data[i] * graphHeight;

      if (i == 0) {
        glowPath.moveTo(x, y);
        mainPath.moveTo(x, y);
      } else {
        glowPath.lineTo(x, y);
        mainPath.lineTo(x, y);
      }
    }

    // 글로우
    canvas.drawPath(
      glowPath,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..strokeWidth = 8
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 메인 라인
    canvas.drawPath(
      mainPath,
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // 현재 점
    if (data.isNotEmpty) {
      final lastX = size.width - padding;
      final lastY = size.height - padding - data.last * graphHeight;

      canvas.drawCircle(
        Offset(lastX, lastY),
        8,
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      );
      canvas.drawCircle(
        Offset(lastX, lastY),
        5,
        Paint()..color = Colors.white,
      );
    }

    // 축 레이블
    _drawText(canvas, 'n', Offset(size.width - padding + 5, size.height - padding + 5));
    _drawText(canvas, 'x', Offset(padding - 15, padding - 15));
    _drawText(canvas, '1', Offset(padding - 15, padding));
    _drawText(canvas, '0', Offset(padding - 15, size.height - padding));

    // r 값 표시
    _drawText(canvas, 'r = ${r.toStringAsFixed(3)}', Offset(padding + 10, padding + 10),
        color: AppColors.accent, fontSize: 14);
  }

  void _drawText(Canvas canvas, String text, Offset position,
      {Color color = AppColors.muted, double fontSize = 11}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant TimeSeriesPainter oldDelegate) => true;
}

/// 분기 다이어그램 페인터
class BifurcationPainter extends CustomPainter {
  final List<List<double>> data;
  final double currentR;

  BifurcationPainter({
    required this.data,
    required this.currentR,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 40.0;

    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    // 그리드
    final gridPaint = Paint()
      ..color = AppColors.simGrid.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 10; i++) {
      final x = padding + (size.width - padding * 2) * i / 10;
      final y = padding + (size.height - padding * 2) * i / 10;
      canvas.drawLine(Offset(x, padding), Offset(x, size.height - padding), gridPaint);
      canvas.drawLine(Offset(padding, y), Offset(size.width - padding, y), gridPaint);
    }

    final graphWidth = size.width - padding * 2;
    final graphHeight = size.height - padding * 2;
    const rMin = 2.5;
    const rMax = 4.0;

    // 분기 다이어그램 점 그리기
    final pointPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (final entry in data) {
      if (entry.isEmpty) continue;
      final r = entry[0];
      final x = padding + ((r - rMin) / (rMax - rMin)) * graphWidth;

      for (int i = 1; i < entry.length; i++) {
        final xVal = entry[i];
        final y = size.height - padding - xVal * graphHeight;
        canvas.drawCircle(Offset(x, y), 0.8, pointPaint);
      }
    }

    // 현재 r 값 표시 (수직선)
    if (currentR >= rMin && currentR <= rMax) {
      final currentX = padding + ((currentR - rMin) / (rMax - rMin)) * graphWidth;

      // 수직 하이라이트
      canvas.drawLine(
        Offset(currentX, padding),
        Offset(currentX, size.height - padding),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 2,
      );
    }

    // 주요 분기점 표시
    _drawBifurcationPoint(canvas, size, 3.0, 'r=3', padding, graphWidth, rMin, rMax);
    _drawBifurcationPoint(canvas, size, 3.449, 'r≈3.45', padding, graphWidth, rMin, rMax);
    _drawBifurcationPoint(canvas, size, 3.5699, '카오스', padding, graphWidth, rMin, rMax);

    // 축 레이블
    _drawText(canvas, 'r', Offset(size.width - padding + 5, size.height - padding + 5));
    _drawText(canvas, 'x', Offset(padding - 15, padding - 15));
    _drawText(canvas, '2.5', Offset(padding - 5, size.height - padding + 10));
    _drawText(canvas, '4.0', Offset(size.width - padding - 10, size.height - padding + 10));
  }

  void _drawBifurcationPoint(Canvas canvas, Size size, double r, String label,
      double padding, double graphWidth, double rMin, double rMax) {
    if (r < rMin || r > rMax) return;

    final x = padding + ((r - rMin) / (rMax - rMin)) * graphWidth;
    canvas.drawLine(
      Offset(x, size.height - padding),
      Offset(x, size.height - padding + 5),
      Paint()
        ..color = AppColors.muted
        ..strokeWidth = 1,
    );
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant BifurcationPainter oldDelegate) =>
      currentR != oldDelegate.currentR;
}
