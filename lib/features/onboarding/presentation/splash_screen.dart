import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

/// O-001~O-004: 스플래시 스크린
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _waveController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // O-002: 로고 애니메이션 컨트롤러
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // O-003: 배경 파동 애니메이션
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // O-004: 프로그레스 인디케이터
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    _progressController.forward();

    // O-001: 스플래시 지속시간 1.5초 후 네비게이션
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    // 첫 실행 여부 확인
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (!mounted) return;

    if (isFirstLaunch) {
      context.go('/promo');
    } else {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // O-003: 배경 파동 애니메이션
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                painter: WaveBackgroundPainter(
                  animation: _waveController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // 중앙 콘텐츠
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // O-002: 원자 로고 애니메이션
                    Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: _buildAtomLogo(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 앱 이름
                    Opacity(
                      opacity: _textOpacity.value,
                      child: Column(
                        children: [
                          Text(
                            '3DWeb Science Lab',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '손끝으로 느끼는 우주의 법칙',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // O-004: 하단 로딩 인디케이터
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (context, child) {
                return Column(
                  children: [
                    // 물리 공식 기반 진행바
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          backgroundColor: AppColors.cardBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accent,
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'E = mc²',
                      style: TextStyle(
                        color: AppColors.muted.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAtomLogo() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          painter: AtomLogoPainter(
            animation: _waveController.value,
          ),
          size: const Size(120, 120),
        );
      },
    );
  }
}

/// 원자 로고 페인터
class AtomLogoPainter extends CustomPainter {
  final double animation;

  AtomLogoPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // 핵 (중앙 원)
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.fill,
    );

    // 전자 궤도 3개
    for (int i = 0; i < 3; i++) {
      final angle = (i * math.pi / 3) + animation * math.pi * 2;

      // 타원 궤도
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final orbitPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 0.6),
        orbitPaint,
      );

      // 전자 (회전하는 점)
      final electronAngle = animation * math.pi * 2 * (i + 1);
      final electronX = radius * math.cos(electronAngle);
      final electronY = radius * 0.3 * math.sin(electronAngle);

      canvas.drawCircle(
        Offset(electronX, electronY),
        5,
        Paint()..color = AppColors.accent2,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant AtomLogoPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// 배경 파동 페인터
class WaveBackgroundPainter extends CustomPainter {
  final double animation;

  WaveBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 동심원 파동
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 5; i++) {
      final radius = 100.0 + i * 80 + animation * 80;
      final opacity = (1 - (radius / (size.width))).clamp(0.0, 0.1);
      paint.color = AppColors.accent.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
