import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/simulation_container.dart';
import '../../../shared/widgets/control_panel.dart';

/// 양자 터널링 시뮬레이션 화면
/// Quantum tunneling simulation
class QuantumTunnelingScreen extends StatefulWidget {
  const QuantumTunnelingScreen({super.key});

  @override
  State<QuantumTunnelingScreen> createState() => _QuantumTunnelingScreenState();
}

class _QuantumTunnelingScreenState extends State<QuantumTunnelingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 물리 파라미터 (기본값)
  static const double _defaultBarrierHeight = 1.0;
  static const double _defaultBarrierWidth = 30.0;
  static const double _defaultParticleEnergy = 0.6;

  double barrierHeight = _defaultBarrierHeight;
  double barrierWidth = _defaultBarrierWidth;
  double particleEnergy = _defaultParticleEnergy;
  bool isRunning = true;
  bool showProbability = true;

  // 애니메이션 상태
  double time = 0;
  List<TunnelParticle> particles = [];
  int transmittedCount = 0;
  int reflectedCount = 0;
  final math.Random _random = math.Random();

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
      time += 0.02;

      // 새 입자 생성
      if (_random.nextDouble() < 0.05) {
        _emitParticle();
      }

      // 입자 업데이트
      particles = particles.where((p) {
        p.x += p.vx;
        p.phase += 0.1;

        // 장벽 영역 체크
        final barrierStart = 150.0;
        final barrierEnd = barrierStart + barrierWidth;

        if (p.x >= barrierStart && p.x <= barrierEnd && !p.hasDecided) {
          // 터널링 확률 계산
          final tunnelProb = _calculateTunnelingProbability();
          p.willTunnel = _random.nextDouble() < tunnelProb;
          p.hasDecided = true;

          if (!p.willTunnel) {
            p.vx = -p.vx.abs(); // 반사
          }
        }

        // 화면 밖으로 나가면 제거
        if (p.x > 350) {
          transmittedCount++;
          return false;
        } else if (p.x < -20) {
          reflectedCount++;
          return false;
        }

        return true;
      }).toList();
    });
  }

  double _calculateTunnelingProbability() {
    // T ≈ e^(-2κL)
    // κ = sqrt(2m(V-E)/ℏ²)
    if (particleEnergy >= barrierHeight) return 1.0;

    final kappa = math.sqrt(2 * (barrierHeight - particleEnergy));
    final L = barrierWidth / 30; // 정규화
    final T = math.exp(-2 * kappa * L);

    return T.clamp(0.0, 1.0);
  }

  void _emitParticle() {
    particles.add(TunnelParticle(
      x: 0,
      y: 175 + (_random.nextDouble() - 0.5) * 10,
      vx: 2 + _random.nextDouble(),
      phase: _random.nextDouble() * math.pi * 2,
    ));
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      time = 0;
      particles.clear();
      transmittedCount = 0;
      reflectedCount = 0;
    });
  }

  void _fireParticle() {
    HapticFeedback.lightImpact();
    _emitParticle();
  }

  // 투과율
  double get transmissionRate {
    final total = transmittedCount + reflectedCount;
    if (total == 0) return 0;
    return transmittedCount / total;
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
              '양자역학 시뮬레이션',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              '양자 터널링',
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
              showProbability ? Icons.show_chart : Icons.show_chart_outlined,
              color: showProbability ? AppColors.accent : AppColors.muted,
            ),
            onPressed: () => setState(() => showProbability = !showProbability),
            tooltip: '확률 분포 표시',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SimulationContainer(
          category: '양자역학 시뮬레이션',
          title: '양자 터널링 (Quantum Tunneling)',
          formula: 'T ≈ e^(-2κL), κ = √(2m(V-E)/ℏ²)',
          formulaDescription:
              '투과 확률 T는 장벽 높이 V, 입자 에너지 E, 장벽 두께 L에 의해 결정됩니다. '
              '고전 물리학에서는 불가능한 현상이지만, 양자역학에서는 입자가 에너지보다 높은 장벽을 통과할 확률이 존재합니다.',
          simulation: SizedBox(
            height: 350,
            child: CustomPaint(
              painter: QuantumTunnelingPainter(
                time: time,
                barrierHeight: barrierHeight,
                barrierWidth: barrierWidth,
                particleEnergy: particleEnergy,
                particles: particles,
                showProbability: showProbability,
                tunnelingProbability: _calculateTunnelingProbability(),
              ),
              size: Size.infinite,
            ),
          ),
          controls: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 컨트롤 그룹
              ControlGroup(
                primaryControl: SimSlider(
                  label: '입자 에너지 (E)',
                  value: particleEnergy,
                  min: 0.1,
                  max: 1.5,
                  step: 0.1,
                  defaultValue: _defaultParticleEnergy,
                  formatValue: (v) => '${v.toStringAsFixed(1)} eV',
                  onChanged: (v) => setState(() => particleEnergy = v),
                ),
                advancedControls: [
                  SimSlider(
                    label: '장벽 높이 (V)',
                    value: barrierHeight,
                    min: 0.5,
                    max: 2.0,
                    step: 0.1,
                    defaultValue: _defaultBarrierHeight,
                    formatValue: (v) => '${v.toStringAsFixed(1)} eV',
                    onChanged: (v) => setState(() => barrierHeight = v),
                  ),
                  SimSlider(
                    label: '장벽 두께 (L)',
                    value: barrierWidth,
                    min: 10,
                    max: 60,
                    defaultValue: _defaultBarrierWidth,
                    formatValue: (v) => '${v.toInt()} nm',
                    onChanged: (v) => setState(() => barrierWidth = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 물리량 표시
              _PhysicsInfo(
                particleEnergy: particleEnergy,
                barrierHeight: barrierHeight,
                tunnelingProbability: _calculateTunnelingProbability(),
                transmittedCount: transmittedCount,
                reflectedCount: reflectedCount,
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
                label: '발사',
                icon: Icons.send,
                onPressed: _fireParticle,
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

/// 터널링 입자 클래스
class TunnelParticle {
  double x;
  double y;
  double vx;
  double phase;
  bool hasDecided;
  bool willTunnel;

  TunnelParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.phase,
    this.hasDecided = false,
    this.willTunnel = false,
  });
}

/// 물리량 정보 위젯
class _PhysicsInfo extends StatelessWidget {
  final double particleEnergy;
  final double barrierHeight;
  final double tunnelingProbability;
  final int transmittedCount;
  final int reflectedCount;

  const _PhysicsInfo({
    required this.particleEnergy,
    required this.barrierHeight,
    required this.tunnelingProbability,
    required this.transmittedCount,
    required this.reflectedCount,
  });

  @override
  Widget build(BuildContext context) {
    final total = transmittedCount + reflectedCount;
    final measuredRate = total > 0 ? transmittedCount / total : 0.0;

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
                label: '이론 투과율',
                value: '${(tunnelingProbability * 100).toStringAsFixed(1)}%',
              ),
              _InfoItem(
                label: '실제 투과율',
                value: '${(measuredRate * 100).toStringAsFixed(1)}%',
              ),
              _InfoItem(
                label: 'E/V 비율',
                value: (particleEnergy / barrierHeight).toStringAsFixed(2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(
                label: '투과',
                value: '$transmittedCount',
                color: Colors.green,
              ),
              _InfoItem(
                label: '반사',
                value: '$reflectedCount',
                color: Colors.red,
              ),
              _InfoItem(
                label: '총 입자',
                value: '$total',
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
  final Color? color;

  const _InfoItem({required this.label, required this.value, this.color});

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
            style: TextStyle(
              color: color ?? AppColors.accent,
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

/// 양자 터널링 페인터
class QuantumTunnelingPainter extends CustomPainter {
  final double time;
  final double barrierHeight;
  final double barrierWidth;
  final double particleEnergy;
  final List<TunnelParticle> particles;
  final bool showProbability;
  final double tunnelingProbability;

  QuantumTunnelingPainter({
    required this.time,
    required this.barrierHeight,
    required this.barrierWidth,
    required this.particleEnergy,
    required this.particles,
    required this.showProbability,
    required this.tunnelingProbability,
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

    final barrierStart = size.width * 0.4;
    final barrierEnd = barrierStart + barrierWidth;
    final groundY = size.height * 0.7;

    // 에너지 레벨 라인
    _drawEnergyLevels(canvas, size, groundY, barrierStart, barrierEnd);

    // 장벽 그리기
    _drawBarrier(canvas, size, barrierStart, barrierEnd, groundY);

    // 확률 분포 (파동 함수)
    if (showProbability) {
      _drawWaveFunction(canvas, size, barrierStart, barrierEnd, groundY);
    }

    // 입자 그리기
    _drawParticles(canvas, size);

    // 레이블
    _drawLabels(canvas, size, barrierStart, barrierEnd, groundY);
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

  void _drawEnergyLevels(Canvas canvas, Size size, double groundY,
      double barrierStart, double barrierEnd) {
    final energyY = groundY - (particleEnergy / 2) * 100;

    // 입자 에너지 레벨
    final energyPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 점선으로 에너지 레벨 표시
    final dashPath = Path();
    for (double x = 20; x < size.width - 20; x += 10) {
      dashPath.moveTo(x, energyY);
      dashPath.lineTo(x + 5, energyY);
    }
    canvas.drawPath(dashPath, energyPaint);

    // 에너지 레이블
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'E = ${particleEnergy.toStringAsFixed(1)} eV',
        style: TextStyle(
          color: AppColors.accent,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(25, energyY - 15));
  }

  void _drawBarrier(Canvas canvas, Size size, double barrierStart,
      double barrierEnd, double groundY) {
    final barrierTopY = groundY - (barrierHeight / 2) * 100;

    // 장벽 그라데이션
    final barrierGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF8B5CF6).withValues(alpha: 0.8),
        const Color(0xFF6D28D9).withValues(alpha: 0.9),
      ],
    ).createShader(
      Rect.fromLTRB(barrierStart, barrierTopY, barrierEnd, groundY),
    );

    canvas.drawRect(
      Rect.fromLTRB(barrierStart, barrierTopY, barrierEnd, groundY),
      Paint()..shader = barrierGradient,
    );

    // 장벽 테두리
    canvas.drawRect(
      Rect.fromLTRB(barrierStart, barrierTopY, barrierEnd, groundY),
      Paint()
        ..color = const Color(0xFF8B5CF6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 장벽 높이 레이블
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'V = ${barrierHeight.toStringAsFixed(1)} eV',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        barrierStart + (barrierWidth - textPainter.width) / 2,
        barrierTopY + 10,
      ),
    );

    // 지면
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      Paint()
        ..color = AppColors.muted.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );
  }

  void _drawWaveFunction(Canvas canvas, Size size, double barrierStart,
      double barrierEnd, double groundY) {
    final wavePath = Path();
    final energyY = groundY - (particleEnergy / 2) * 100;

    // 입사파 영역
    wavePath.moveTo(20, energyY);
    for (double x = 20; x < barrierStart; x += 2) {
      final amplitude = 20 * math.sin((x - time * 50) * 0.1);
      wavePath.lineTo(x, energyY + amplitude);
    }

    // 장벽 내부 (지수 감쇠)
    if (particleEnergy < barrierHeight) {
      final kappa = math.sqrt(2 * (barrierHeight - particleEnergy));
      for (double x = barrierStart; x < barrierEnd; x += 2) {
        final decay = math.exp(-kappa * (x - barrierStart) / 20);
        final amplitude = 20 * decay * math.sin((x - time * 50) * 0.05);
        wavePath.lineTo(x, energyY + amplitude);
      }
    } else {
      // 에너지가 장벽보다 높으면 그냥 통과
      for (double x = barrierStart; x < barrierEnd; x += 2) {
        final amplitude = 20 * math.sin((x - time * 50) * 0.1);
        wavePath.lineTo(x, energyY + amplitude);
      }
    }

    // 투과파 영역
    final transmissionAmplitude = 20 * math.sqrt(tunnelingProbability);
    for (double x = barrierEnd; x < size.width - 20; x += 2) {
      final amplitude = transmissionAmplitude * math.sin((x - time * 50) * 0.1);
      wavePath.lineTo(x, energyY + amplitude);
    }

    canvas.drawPath(
      wavePath,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 확률 밀도 채우기
    final fillPath = Path.from(wavePath);
    fillPath.lineTo(size.width - 20, energyY);
    fillPath.lineTo(20, energyY);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()..color = AppColors.accent.withValues(alpha: 0.1),
    );
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (final particle in particles) {
      // 입자 색상 결정
      Color particleColor;
      if (particle.hasDecided) {
        particleColor = particle.willTunnel ? Colors.green : Colors.red;
      } else {
        particleColor = AppColors.accent;
      }

      // 파동 패킷 효과
      for (int i = 0; i < 5; i++) {
        final offset = i * 6.0;
        final opacity = (1 - i / 5) * 0.3;
        canvas.drawCircle(
          Offset(particle.x - offset, particle.y),
          4,
          Paint()..color = particleColor.withValues(alpha: opacity),
        );
      }

      // 메인 입자
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        6,
        Paint()..color = particleColor,
      );

      // 글로우
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        10,
        Paint()..color = particleColor.withValues(alpha: 0.3),
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size, double barrierStart,
      double barrierEnd, double groundY) {
    // 입사 영역 레이블
    final incidentLabel = TextPainter(
      text: const TextSpan(
        text: 'Incident',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    incidentLabel.layout();
    incidentLabel.paint(canvas, Offset(50, size.height - 30));

    // 투과 영역 레이블
    final transmittedLabel = TextPainter(
      text: const TextSpan(
        text: 'Transmitted',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    transmittedLabel.layout();
    transmittedLabel.paint(canvas, Offset(size.width - 90, size.height - 30));

    // 투과 확률 표시
    final probLabel = TextPainter(
      text: TextSpan(
        text: 'T = ${(tunnelingProbability * 100).toStringAsFixed(1)}%',
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    probLabel.layout();
    probLabel.paint(canvas, Offset(size.width - 80, 20));
  }

  @override
  bool shouldRepaint(covariant QuantumTunnelingPainter oldDelegate) => true;
}
