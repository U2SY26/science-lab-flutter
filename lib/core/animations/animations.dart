import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A-001: 커스텀 페이지 트랜지션
class FadeSlideTransitionPage<T> extends CustomTransitionPage<T> {
  FadeSlideTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

/// A-001: 확대 페이드 트랜지션
class ScaleFadeTransitionPage<T> extends CustomTransitionPage<T> {
  ScaleFadeTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
    super.key,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.95,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
        );
}

/// A-002: 스태거 애니메이션 래퍼
class StaggeredAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Offset? slideOffset;
  final double? scaleStart;

  const StaggeredAnimation({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.duration = const Duration(milliseconds: 400),
    this.slideOffset = const Offset(0, 20),
    this.scaleStart,
  });

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset ?? Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.scaleStart != null) {
      _scaleAnimation = Tween<double>(
        begin: widget.scaleStart,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    }

    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _controller.forward();
    });
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
        Widget result = Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: widget.child,
          ),
        );

        if (_scaleAnimation != null) {
          result = Transform.scale(
            scale: _scaleAnimation!.value,
            child: result,
          );
        }

        return result;
      },
    );
  }
}

/// A-002: 리스트 아이템 스태거 빌더
class StaggeredListBuilder extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Duration itemDelay;
  final Duration animationDuration;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const StaggeredListBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 400),
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemBuilder: (context, index) {
        return StaggeredAnimation(
          index: index,
          delay: itemDelay,
          duration: animationDuration,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

/// A-003: 탭 피드백 위젯
class TapFeedback extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final double pressedOpacity;

  const TapFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.pressedOpacity = 0.8,
  });

  @override
  State<TapFeedback> createState() => _TapFeedbackState();
}

class _TapFeedbackState extends State<TapFeedback> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _isPressed ? widget.pressedOpacity : 1.0,
          duration: const Duration(milliseconds: 100),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A-004: 숫자 카운트업 애니메이션
class AnimatedCounter extends StatefulWidget {
  final int value;
  final Duration duration;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 800),
    this.style,
    this.prefix,
    this.suffix,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _controller.reset();
      _controller.forward();
    }
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
        return Text(
          '${widget.prefix ?? ''}${_animation.value.toInt()}${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}

/// A-005: 시뮬레이션 상태 전환 애니메이션
class SimulationStateTransition extends StatefulWidget {
  final bool isRunning;
  final Widget child;
  final Duration duration;

  const SimulationStateTransition({
    super.key,
    required this.isRunning,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<SimulationStateTransition> createState() => _SimulationStateTransitionState();
}

class _SimulationStateTransitionState extends State<SimulationStateTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isRunning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SimulationStateTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.animateTo(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isRunning ? _pulseAnimation.value : 1.0,
          child: widget.child,
        );
      },
    );
  }
}

/// A-006: 쉐이크 애니메이션 (오류 표시용)
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final bool shake;
  final double intensity;
  final Duration duration;

  const ShakeAnimation({
    super.key,
    required this.child,
    this.shake = false,
    this.intensity = 10,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0);
    }
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
        final offset = math.sin(_controller.value * math.pi * 4) *
            widget.intensity *
            (1 - _controller.value);
        return Transform.translate(
          offset: Offset(offset, 0),
          child: widget.child,
        );
      },
    );
  }
}

/// A-007: 페이드 스위치 애니메이션
class FadeSwitch extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const FadeSwitch({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: child,
    );
  }
}

/// A-008: 슬라이드 스위치 애니메이션
class SlideSwitch extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Offset beginOffset;

  const SlideSwitch({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.beginOffset = const Offset(0, 0.1),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: child,
    );
  }
}

/// A-009: 팝 애니메이션 (등장)
class PopAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;

  const PopAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.elasticOut,
  });

  @override
  State<PopAnimation> createState() => _PopAnimationState();
}

class _PopAnimationState extends State<PopAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

/// A-010: 로딩 스피너 애니메이션
class LoadingSpinner extends StatefulWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const LoadingSpinner({
    super.key,
    this.size = 40,
    this.color = Colors.white,
    this.strokeWidth = 3,
  });

  @override
  State<LoadingSpinner> createState() => _LoadingSpinnerState();
}

class _LoadingSpinnerState extends State<LoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
          painter: LoadingSpinnerPainter(
            progress: _controller.value,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }
}

class LoadingSpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  LoadingSpinnerPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = progress * 2 * math.pi;
    final sweepAngle = math.pi * 0.8;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant LoadingSpinnerPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// 애니메이션 유틸리티 확장
extension AnimationExtensions on AnimationController {
  /// 부드러운 정지
  Future<void> smoothStop() async {
    if (isAnimating) {
      await animateTo(value, duration: const Duration(milliseconds: 200));
    }
  }
}

/// 위젯 확장 - 애니메이션 래퍼
extension WidgetAnimationExtensions on Widget {
  /// 페이드 인 래퍼
  Widget fadeIn({Duration duration = const Duration(milliseconds: 300)}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: this,
    );
  }

  /// 슬라이드 인 래퍼
  Widget slideIn({
    Duration duration = const Duration(milliseconds: 300),
    Offset begin = const Offset(0, 20),
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: begin, end: Offset.zero),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(offset: value, child: child);
      },
      child: this,
    );
  }
}
