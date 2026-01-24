import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

/// O-005~O-010: 온보딩 튜토리얼
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // O-006: 인터랙티브 진자 데모
  late AnimationController _pendulumController;
  double _pendulumAngle = 0.3;
  bool _userInteracted = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: '우주의 비밀을 탐험하세요',
      subtitle: '62개의 인터랙티브 시뮬레이션으로\n수학과 물리의 아름다움을 발견하세요',
      icon: Icons.auto_awesome,
    ),
    OnboardingPage(
      title: '직접 터치하고 조작하세요',
      subtitle: '아래 진자를 드래그해서\n물리 법칙을 체험해 보세요',
      icon: Icons.touch_app,
      isInteractive: true,
    ),
    OnboardingPage(
      title: '학습을 시작할 준비가 되셨나요?',
      subtitle: '단순한 진자부터 복잡한 신경망까지\n단계별로 탐험해 보세요',
      icon: Icons.rocket_launch,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pendulumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updatePendulum);
    _pendulumController.repeat();
  }

  void _updatePendulum() {
    if (!_userInteracted) {
      setState(() {
        // 단순 조화 운동
        final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
        _pendulumAngle = 0.5 * math.sin(time * 2);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pendulumController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  // O-008: 스킵 버튼
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // 페이지 뷰
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                HapticFeedback.selectionClick();
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return _buildPage(page, index);
              },
            ),

            // O-008: 스킵 버튼 (우측 상단)
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  '건너뛰기',
                  style: TextStyle(
                    color: AppColors.muted.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // 하단 네비게이션
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // O-009: 진행 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.accent
                              : AppColors.muted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 다음 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1 ? '시작하기' : '다음',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // 아이콘 또는 인터랙티브 데모
          if (page.isInteractive)
            _buildInteractivePendulum()
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                page.icon,
                size: 56,
                color: AppColors.accent,
              ),
            ),

          const SizedBox(height: 48),

          // O-005: 환영 메시지
          Text(
            page.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            page.subtitle,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // O-007: 제스처 힌트
          if (page.isInteractive) ...[
            const SizedBox(height: 24),
            _buildGestureHint(),
          ],

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // O-006: 인터랙티브 진자 데모
  Widget _buildInteractivePendulum() {
    return GestureDetector(
      onPanStart: (_) {
        setState(() => _userInteracted = true);
        HapticFeedback.lightImpact();
      },
      onPanUpdate: (details) {
        setState(() {
          _pendulumAngle += details.delta.dx * 0.005;
          _pendulumAngle = _pendulumAngle.clamp(-1.0, 1.0);
        });
      },
      onPanEnd: (_) {
        // 사용자가 놓으면 자연스럽게 진동 시작
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _userInteracted = false);
          }
        });
      },
      child: SizedBox(
        width: 200,
        height: 200,
        child: CustomPaint(
          painter: OnboardingPendulumPainter(
            angle: _pendulumAngle,
          ),
        ),
      ),
    );
  }

  // O-007: 제스처 힌트 애니메이션
  Widget _buildGestureHint() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Opacity(
          opacity: _userInteracted ? 0.0 : (0.5 + 0.5 * math.sin(value * math.pi * 2)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swipe,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '좌우로 드래그하세요',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 온보딩 페이지 데이터
class OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isInteractive;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isInteractive = false,
  });
}

/// 온보딩 진자 페인터
class OnboardingPendulumPainter extends CustomPainter {
  final double angle;

  OnboardingPendulumPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final pivotX = size.width / 2;
    final pivotY = 20.0;
    final ropeLength = 120.0;
    final bobRadius = 20.0;

    // 진자 위치 계산
    final bobX = pivotX + ropeLength * math.sin(angle);
    final bobY = pivotY + ropeLength * math.cos(angle);

    // 피벗 (고정점)
    canvas.drawCircle(
      Offset(pivotX, pivotY),
      6,
      Paint()..color = AppColors.muted,
    );

    // 줄
    canvas.drawLine(
      Offset(pivotX, pivotY),
      Offset(bobX, bobY),
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // 공 (그림자)
    canvas.drawCircle(
      Offset(bobX + 4, bobY + 4),
      bobRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.2),
    );

    // 공
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        AppColors.accent,
        AppColors.accent.withValues(alpha: 0.7),
      ],
    );

    canvas.drawCircle(
      Offset(bobX, bobY),
      bobRadius,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: Offset(bobX, bobY), radius: bobRadius),
        ),
    );

    // 하이라이트
    canvas.drawCircle(
      Offset(bobX - 6, bobY - 6),
      5,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant OnboardingPendulumPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}
