import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 스프링 시뮬레이션 화면
class SpringScreen extends StatefulWidget {
  const SpringScreen({super.key});

  @override
  State<SpringScreen> createState() => _SpringScreenState();
}

class _SpringScreenState extends State<SpringScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 기본값
  static const double _defaultK = 50; // 스프링 상수
  static const double _defaultMass = 1;
  static const double _defaultDamping = 0.1;
  static const int _defaultNodeCount = 5;

  // 파라미터
  double _k = _defaultK;
  double _mass = _defaultMass;
  double _damping = _defaultDamping;
  int _nodeCount = _defaultNodeCount;
  bool _isRunning = true;

  // 노드 상태 (위치, 속도)
  List<double> _positions = [];
  List<double> _velocities = [];
  final double _restLength = 60;

  // 프리셋
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _initNodes();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_update);
    _controller.repeat();
  }

  void _initNodes() {
    _positions = List.generate(_nodeCount, (i) => 0.0);
    _velocities = List.generate(_nodeCount, (i) => 0.0);
    // 초기 변위 적용
    if (_positions.isNotEmpty) {
      _positions[0] = 50;
    }
  }

  void _update() {
    if (!_isRunning) return;

    setState(() {
      const dt = 0.016;

      // 가속도 계산
      final accelerations = List<double>.filled(_nodeCount, 0);

      for (int i = 0; i < _nodeCount; i++) {
        double force = 0;

        // 왼쪽 스프링 (고정점 또는 이전 노드)
        if (i == 0) {
          force += -_k * _positions[i]; // 고정점에서의 복원력
        } else {
          final dx = _positions[i] - _positions[i - 1];
          force += -_k * dx;
        }

        // 오른쪽 스프링 (다음 노드)
        if (i < _nodeCount - 1) {
          final dx = _positions[i] - _positions[i + 1];
          force += -_k * dx;
        }

        // 감쇠력
        force += -_damping * _velocities[i];

        accelerations[i] = force / _mass;
      }

      // 위치와 속도 업데이트 (Verlet 적분)
      for (int i = 0; i < _nodeCount; i++) {
        _velocities[i] += accelerations[i] * dt;
        _positions[i] += _velocities[i] * dt;
      }
    });
  }

  void _perturb() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_positions.isNotEmpty) {
        _positions[0] = 50;
        _velocities[0] = 0;
      }
    });
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _initNodes();
      _selectedPreset = null;
    });
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'soft':
          _k = 20;
          _mass = 1;
          _damping = 0.05;
          break;
        case 'stiff':
          _k = 100;
          _mass = 1;
          _damping = 0.1;
          break;
        case 'heavy':
          _k = 50;
          _mass = 3;
          _damping = 0.2;
          break;
        case 'undamped':
          _k = 50;
          _mass = 1;
          _damping = 0;
          break;
        case 'overdamped':
          _k = 50;
          _mass = 1;
          _damping = 5;
          break;
      }
      _initNodes();
    });
  }

  // 고유 진동수 계산
  double get _naturalFrequency => math.sqrt(_k / _mass) / (2 * math.pi);

  // 감쇠비 계산
  double get _dampingRatio => _damping / (2 * math.sqrt(_k * _mass));

  // 총 에너지 계산
  double get _totalEnergy {
    double ke = 0; // 운동 에너지
    double pe = 0; // 위치 에너지

    for (int i = 0; i < _nodeCount; i++) {
      ke += 0.5 * _mass * _velocities[i] * _velocities[i];

      // 왼쪽 스프링 위치 에너지
      if (i == 0) {
        pe += 0.5 * _k * _positions[i] * _positions[i];
      } else {
        final dx = _positions[i] - _positions[i - 1];
        pe += 0.5 * _k * dx * dx;
      }
    }

    return ke + pe;
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
              '역학',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '스프링 체인',
              style: TextStyle(color: AppColors.ink, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '역학',
          title: '스프링 체인',
          formula: 'F = -kx - cv',
          formulaDescription: '감쇠 조화 진동자 체인의 결합 운동',
          simulation: GestureDetector(
            onTapDown: (details) => _perturb(),
            child: SizedBox(
              height: 300,
              child: CustomPaint(
                painter: SpringPainter(
                  positions: _positions,
                  restLength: _restLength,
                  nodeCount: _nodeCount,
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
                label: '시스템 특성',
                presets: [
                  PresetButton(
                    label: '부드러움',
                    isSelected: _selectedPreset == 'soft',
                    onPressed: () => _applyPreset('soft'),
                  ),
                  PresetButton(
                    label: '딱딱함',
                    isSelected: _selectedPreset == 'stiff',
                    onPressed: () => _applyPreset('stiff'),
                  ),
                  PresetButton(
                    label: '무거움',
                    isSelected: _selectedPreset == 'heavy',
                    onPressed: () => _applyPreset('heavy'),
                  ),
                  PresetButton(
                    label: '비감쇠',
                    isSelected: _selectedPreset == 'undamped',
                    onPressed: () => _applyPreset('undamped'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 시스템 정보
              _SpringInfo(
                k: _k,
                mass: _mass,
                damping: _damping,
                naturalFrequency: _naturalFrequency,
                dampingRatio: _dampingRatio,
                totalEnergy: _totalEnergy,
              ),
              const SizedBox(height: 16),
              // 컨트롤
              ControlGroup(
                primaryControl: SimSlider(
                  label: '스프링 상수 (k)',
                  value: _k,
                  min: 10,
                  max: 200,
                  defaultValue: _defaultK,
                  formatValue: (v) => '${v.toStringAsFixed(0)} N/m',
                  onChanged: (v) {
                    setState(() {
                      _k = v;
                      _selectedPreset = null;
                    });
                  },
                ),
                advancedControls: [
                  SimSlider(
                    label: '질량 (m)',
                    value: _mass,
                    min: 0.1,
                    max: 5,
                    defaultValue: _defaultMass,
                    formatValue: (v) => '${v.toStringAsFixed(1)} kg',
                    onChanged: (v) {
                      setState(() {
                        _mass = v;
                        _selectedPreset = null;
                      });
                    },
                  ),
                  SimSlider(
                    label: '감쇠 계수 (c)',
                    value: _damping,
                    min: 0,
                    max: 5,
                    defaultValue: _defaultDamping,
                    formatValue: (v) => v.toStringAsFixed(2),
                    onChanged: (v) {
                      setState(() {
                        _damping = v;
                        _selectedPreset = null;
                      });
                    },
                  ),
                  SimSlider(
                    label: '노드 개수',
                    value: _nodeCount.toDouble(),
                    min: 1,
                    max: 10,
                    defaultValue: _defaultNodeCount.toDouble(),
                    formatValue: (v) => '${v.toInt()}개',
                    onChanged: (v) {
                      setState(() {
                        _nodeCount = v.toInt();
                        _initNodes();
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
                label: '흔들기',
                icon: Icons.vibration,
                onPressed: _perturb,
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

/// 스프링 정보 위젯
class _SpringInfo extends StatelessWidget {
  final double k;
  final double mass;
  final double damping;
  final double naturalFrequency;
  final double dampingRatio;
  final double totalEnergy;

  const _SpringInfo({
    required this.k,
    required this.mass,
    required this.damping,
    required this.naturalFrequency,
    required this.dampingRatio,
    required this.totalEnergy,
  });

  String _getDampingState() {
    if (dampingRatio == 0) return '비감쇠';
    if (dampingRatio < 1) return '미감쇠';
    if (dampingRatio == 1) return '임계감쇠';
    return '과감쇠';
  }

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
                  label: '고유 진동수',
                  value: '${naturalFrequency.toStringAsFixed(2)} Hz',
                  icon: Icons.waves,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: '감쇠비 ζ',
                  value: dampingRatio.toStringAsFixed(3),
                  icon: Icons.trending_down,
                  color: AppColors.accent2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: '감쇠 상태',
                  value: _getDampingState(),
                  icon: Icons.info_outline,
                  color: dampingRatio < 1 ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  label: '총 에너지',
                  value: '${totalEnergy.toStringAsFixed(1)} J',
                  icon: Icons.bolt,
                  color: Colors.yellow.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.7),
                    fontSize: 9,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 스프링 체인 페인터
class SpringPainter extends CustomPainter {
  final List<double> positions;
  final double restLength;
  final int nodeCount;

  SpringPainter({
    required this.positions,
    required this.restLength,
    required this.nodeCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 배경
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.simBg);

    final centerY = size.height / 2;
    final startX = 50.0;
    final totalWidth = size.width - 100;
    final spacing = nodeCount > 0 ? totalWidth / (nodeCount + 1) : totalWidth;

    // 고정점
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(startX - 10, centerY),
        width: 20,
        height: 60,
      ),
      Paint()..color = Colors.grey.shade700,
    );

    // 각 노드와 스프링 그리기
    double prevX = startX;
    double prevY = centerY;

    for (int i = 0; i < nodeCount; i++) {
      final nodeX = startX + (i + 1) * spacing;
      final nodeY = centerY + positions[i];

      // 스프링 그리기
      _drawSpring(canvas, Offset(prevX, prevY), Offset(nodeX, nodeY));

      // 노드 (질량) 그리기
      // 글로우
      canvas.drawCircle(
        Offset(nodeX, nodeY),
        20,
        Paint()..color = AppColors.accent.withValues(alpha: 0.2),
      );

      // 메인 원
      canvas.drawCircle(
        Offset(nodeX, nodeY),
        15,
        Paint()..color = AppColors.accent,
      );

      // 테두리
      canvas.drawCircle(
        Offset(nodeX, nodeY),
        15,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // 노드 번호
      _drawText(canvas, '${i + 1}', Offset(nodeX - 4, nodeY - 5), color: Colors.white);

      prevX = nodeX;
      prevY = nodeY;
    }

    // 평형 위치 표시 (점선)
    final dashPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (double x = startX; x < size.width - 50; x += 10) {
      canvas.drawLine(
        Offset(x, centerY),
        Offset(x + 5, centerY),
        dashPaint,
      );
    }

    // 안내 텍스트
    _drawText(canvas, '탭하여 흔들기', Offset(size.width / 2 - 30, size.height - 30));
  }

  void _drawSpring(Canvas canvas, Offset start, Offset end) {
    final path = Path();
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle = math.atan2(dy, dx);

    const coils = 10;
    const amplitude = 8.0;

    path.moveTo(start.dx, start.dy);

    for (int i = 0; i <= coils * 4; i++) {
      final t = i / (coils * 4);
      final x = start.dx + t * dx;
      final y = start.dy + t * dy;

      // 지그재그 오프셋
      final offset = math.sin(t * coils * 2 * math.pi) * amplitude;
      final perpX = -math.sin(angle) * offset;
      final perpY = math.cos(angle) * offset;

      if (i == 0 || i == coils * 4) {
        path.lineTo(x, y);
      } else {
        path.lineTo(x + perpX, y + perpY);
      }
    }

    // 스프링 그리기
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent2
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawText(Canvas canvas, String text, Offset position, {Color color = AppColors.muted}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant SpringPainter oldDelegate) => true;
}
