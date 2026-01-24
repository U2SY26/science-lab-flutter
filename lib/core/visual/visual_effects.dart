import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// V-001: 네온 글로우 효과 위젯
class NeonGlow extends StatelessWidget {
  final Widget child;
  final Color color;
  final double intensity;
  final double spread;

  const NeonGlow({
    super.key,
    required this.child,
    this.color = AppColors.accent,
    this.intensity = 0.6,
    this.spread = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: intensity * 0.4),
            blurRadius: spread,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withValues(alpha: intensity * 0.2),
            blurRadius: spread * 2,
            spreadRadius: spread / 2,
          ),
          BoxShadow(
            color: color.withValues(alpha: intensity * 0.1),
            blurRadius: spread * 3,
            spreadRadius: spread,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// V-001: 네온 테두리 효과
class NeonBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double borderWidth;
  final double borderRadius;
  final double glowIntensity;

  const NeonBorder({
    super.key,
    required this.child,
    this.color = AppColors.accent,
    this.borderWidth = 1,
    this.borderRadius = 12,
    this.glowIntensity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.8),
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: glowIntensity * 0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withValues(alpha: glowIntensity * 0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: child,
      ),
    );
  }
}

/// V-002: 그라데이션 텍스트
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientText({
    super.key,
    required this.text,
    this.style,
    this.colors = const [AppColors.accent, AppColors.accent2],
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      ).createShader(bounds),
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}

/// V-002: 그라데이션 아이콘
class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final List<Color> colors;

  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.colors = const [AppColors.accent, AppColors.accent2],
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
      ),
    );
  }
}

/// V-003: 그리드 배경 페인터
class GridBackgroundPainter extends CustomPainter {
  final Color gridColor;
  final double spacing;
  final double lineWidth;
  final bool showAxes;
  final Color? axisColor;
  final Offset center;

  GridBackgroundPainter({
    this.gridColor = AppColors.simGrid,
    this.spacing = 20,
    this.lineWidth = 0.5,
    this.showAxes = false,
    this.axisColor,
    this.center = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = lineWidth;

    // 수직선
    for (double x = center.dx % spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 수평선
    for (double y = center.dy % spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 축 그리기
    if (showAxes) {
      final axisPaint = Paint()
        ..color = axisColor ?? AppColors.accent.withValues(alpha: 0.5)
        ..strokeWidth = 1.5;

      // X축
      if (center.dy >= 0 && center.dy <= size.height) {
        canvas.drawLine(
          Offset(0, center.dy),
          Offset(size.width, center.dy),
          axisPaint,
        );
      }

      // Y축
      if (center.dx >= 0 && center.dx <= size.width) {
        canvas.drawLine(
          Offset(center.dx, 0),
          Offset(center.dx, size.height),
          axisPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridBackgroundPainter oldDelegate) =>
      gridColor != oldDelegate.gridColor ||
      spacing != oldDelegate.spacing ||
      lineWidth != oldDelegate.lineWidth ||
      showAxes != oldDelegate.showAxes ||
      center != oldDelegate.center;
}

/// V-004: 파티클 시스템
class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.color,
  });
}

class ParticleSystem extends StatefulWidget {
  final int particleCount;
  final Color baseColor;
  final double maxSpeed;
  final double maxSize;
  final bool connectNearby;
  final double connectionDistance;

  const ParticleSystem({
    super.key,
    this.particleCount = 50,
    this.baseColor = AppColors.accent,
    this.maxSpeed = 0.5,
    this.maxSize = 3,
    this.connectNearby = true,
    this.connectionDistance = 80,
  });

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];
  Size? _size;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateParticles);
    _controller.repeat();
  }

  void _initParticles(Size size) {
    if (_size == size && particles.isNotEmpty) return;
    _size = size;
    final random = math.Random();

    particles = List.generate(widget.particleCount, (_) {
      return Particle(
        x: random.nextDouble() * size.width,
        y: random.nextDouble() * size.height,
        vx: (random.nextDouble() - 0.5) * widget.maxSpeed * 2,
        vy: (random.nextDouble() - 0.5) * widget.maxSpeed * 2,
        size: random.nextDouble() * widget.maxSize + 1,
        opacity: random.nextDouble() * 0.5 + 0.2,
        color: widget.baseColor,
      );
    });
  }

  void _updateParticles() {
    if (_size == null) return;

    for (var particle in particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;

      // 경계 처리
      if (particle.x < 0 || particle.x > _size!.width) particle.vx *= -1;
      if (particle.y < 0 || particle.y > _size!.height) particle.vy *= -1;

      particle.x = particle.x.clamp(0, _size!.width);
      particle.y = particle.y.clamp(0, _size!.height);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initParticles(size);

        return CustomPaint(
          painter: ParticlePainter(
            particles: particles,
            connectNearby: widget.connectNearby,
            connectionDistance: widget.connectionDistance,
          ),
          size: size,
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final bool connectNearby;
  final double connectionDistance;

  ParticlePainter({
    required this.particles,
    required this.connectNearby,
    required this.connectionDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 파티클 연결선
    if (connectNearby) {
      for (int i = 0; i < particles.length; i++) {
        for (int j = i + 1; j < particles.length; j++) {
          final dx = particles[i].x - particles[j].x;
          final dy = particles[i].y - particles[j].y;
          final distance = math.sqrt(dx * dx + dy * dy);

          if (distance < connectionDistance) {
            final opacity = (1 - distance / connectionDistance) * 0.3;
            canvas.drawLine(
              Offset(particles[i].x, particles[i].y),
              Offset(particles[j].x, particles[j].y),
              Paint()
                ..color = particles[i].color.withValues(alpha: opacity)
                ..strokeWidth = 0.5,
            );
          }
        }
      }
    }

    // 파티클 그리기
    for (var particle in particles) {
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        Paint()..color = particle.color.withValues(alpha: particle.opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

/// V-005: 반응형 글로우 버튼
class GlowButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color glowColor;
  final double borderRadius;

  const GlowButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.glowColor = AppColors.accent,
    this.borderRadius = 8,
  });

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: 0.3 + _controller.value * 0.4),
                  blurRadius: 8 + _controller.value * 12,
                  spreadRadius: _controller.value * 2,
                ),
              ],
            ),
            child: AnimatedScale(
              scale: _isPressed ? 0.98 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// V-006: 펄스 애니메이션
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// V-007: 스캔라인 효과
class ScanlineOverlay extends StatefulWidget {
  final double opacity;
  final double speed;

  const ScanlineOverlay({
    super.key,
    this.opacity = 0.03,
    this.speed = 2,
  });

  @override
  State<ScanlineOverlay> createState() => _ScanlineOverlayState();
}

class _ScanlineOverlayState extends State<ScanlineOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.speed.toInt()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ScanlinePainter(
            progress: _controller.value,
            opacity: widget.opacity,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class ScanlinePainter extends CustomPainter {
  final double progress;
  final double opacity;

  ScanlinePainter({required this.progress, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity);

    // 스캔라인 패턴
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // 이동하는 밝은 라인
    final scanY = progress * size.height;
    final scanPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, scanY - 50),
        Offset(0, scanY + 50),
        [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: opacity * 3),
          Colors.white.withValues(alpha: 0),
        ],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 50, size.width, 100),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScanlinePainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// V-008: 글리치 효과
class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration interval;

  const GlitchText({
    super.key,
    required this.text,
    this.style,
    this.interval = const Duration(seconds: 3),
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _startGlitchLoop();
  }

  void _startGlitchLoop() async {
    while (mounted) {
      await Future.delayed(widget.interval);
      if (!mounted) return;

      setState(() => _isGlitching = true);
      await _controller.forward();
      await _controller.reverse();
      await _controller.forward();
      await _controller.reverse();
      if (mounted) setState(() => _isGlitching = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 빨간색 오프셋
        if (_isGlitching)
          Positioned(
            left: -2,
            child: Text(
              widget.text,
              style: (widget.style ?? const TextStyle()).copyWith(
                color: Colors.red.withValues(alpha: 0.5),
              ),
            ),
          ),
        // 파란색 오프셋
        if (_isGlitching)
          Positioned(
            left: 2,
            child: Text(
              widget.text,
              style: (widget.style ?? const TextStyle()).copyWith(
                color: Colors.blue.withValues(alpha: 0.5),
              ),
            ),
          ),
        // 메인 텍스트
        Text(widget.text, style: widget.style),
      ],
    );
  }
}

/// V-009: 그라데이션 배경
class GradientBackground extends StatelessWidget {
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final Widget? child;

  const GradientBackground({
    super.key,
    this.colors = const [
      Color(0xFF0A0A0F),
      Color(0xFF0D1420),
      Color(0xFF0A0A0F),
    ],
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: begin,
          end: end,
        ),
      ),
      child: child,
    );
  }
}

/// V-010: 데이터 스트림 시각화
class DataStreamVisualization extends StatefulWidget {
  final int columnCount;
  final Color color;

  const DataStreamVisualization({
    super.key,
    this.columnCount = 20,
    this.color = AppColors.accent,
  });

  @override
  State<DataStreamVisualization> createState() => _DataStreamVisualizationState();
}

class _DataStreamVisualizationState extends State<DataStreamVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<double> _offsets;
  late List<double> _speeds;
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _offsets = List.generate(widget.columnCount, (_) => _random.nextDouble() * 100);
    _speeds = List.generate(widget.columnCount, (_) => 0.5 + _random.nextDouble() * 2);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(() {
        setState(() {
          for (int i = 0; i < _offsets.length; i++) {
            _offsets[i] += _speeds[i];
            if (_offsets[i] > 100) _offsets[i] = 0;
          }
        });
      });
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DataStreamPainter(
        offsets: _offsets,
        color: widget.color,
      ),
      size: Size.infinite,
    );
  }
}

class DataStreamPainter extends CustomPainter {
  final List<double> offsets;
  final Color color;

  DataStreamPainter({required this.offsets, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final columnWidth = size.width / offsets.length;
    final charHeight = 14.0;
    final random = math.Random(42);
    const chars = '01アイウエオカキクケコ';

    for (int col = 0; col < offsets.length; col++) {
      final x = col * columnWidth + columnWidth / 2;
      final offset = offsets[col];

      for (int row = 0; row < (size.height / charHeight).ceil() + 10; row++) {
        final y = (row * charHeight + offset * charHeight) % (size.height + charHeight * 10);
        final char = chars[random.nextInt(chars.length)];
        final distanceFromTop = y / size.height;
        final opacity = (1 - distanceFromTop).clamp(0.0, 1.0) * 0.8;

        final textPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(
              color: color.withValues(alpha: opacity),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant DataStreamPainter oldDelegate) => true;
}

/// V-011: 원형 진행 표시기
class CircularProgress extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;
  final Widget? child;

  const CircularProgress({
    super.key,
    required this.progress,
    this.size = 60,
    this.strokeWidth = 4,
    this.backgroundColor = AppColors.cardBorder,
    this.progressColor = AppColors.accent,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: CircularProgressPainter(
              progress: progress,
              backgroundColor: backgroundColor,
              progressColor: progressColor,
              strokeWidth: strokeWidth,
            ),
            size: Size(size, size),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 배경 원
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // 진행 호
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// V-012: 웨이브 배경
class WaveBackground extends StatefulWidget {
  final Color color;
  final int waveCount;
  final double amplitude;

  const WaveBackground({
    super.key,
    this.color = AppColors.accent,
    this.waveCount = 3,
    this.amplitude = 20,
  });

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(
            phase: _controller.value * 2 * math.pi,
            color: widget.color,
            waveCount: widget.waveCount,
            amplitude: widget.amplitude,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  final int waveCount;
  final double amplitude;

  WavePainter({
    required this.phase,
    required this.color,
    required this.waveCount,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < waveCount; i++) {
      final path = Path();
      final wavePhase = phase + i * math.pi / waveCount;
      final waveAmplitude = amplitude * (1 - i * 0.2);
      final baseY = size.height * (0.6 + i * 0.1);
      final opacity = 0.1 - i * 0.03;

      path.moveTo(0, baseY);

      for (double x = 0; x <= size.width; x += 5) {
        final y = baseY + math.sin(x * 0.02 + wavePhase) * waveAmplitude;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      phase != oldDelegate.phase;
}

/// V-013: 블러 배경
class BlurredBackground extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? overlayColor;

  const BlurredBackground({
    super.key,
    required this.child,
    this.blur = 10,
    this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              color: overlayColor ?? Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}
