import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

/// Rive 스플래시 스크린
/// 상단: pomodoro 캐릭터 / 하단: start 버튼 → 누르면 홈으로 전환
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Rive 에셋
  Artboard? _topArtboard;
  Artboard? _btnArtboard;
  StateMachineController? _btnController;

  bool _isLoading = true;
  bool _pressed = false;

  // 페이드아웃
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadRiveAssets();
  }

  Future<void> _loadRiveAssets() async {
    try {
      debugPrint('[Splash] Loading Rive assets...');
      // 상단 캐릭터
      final topFile = await RiveFile.asset('assets/rive/splash_top.riv');
      final topAb = topFile.mainArtboard;
      // State Machine 자동 탐색
      for (final name in ['State Machine 1', 'State Machine', 'default']) {
        try {
          final ctrl = StateMachineController.fromArtboard(topAb, name);
          if (ctrl != null) { topAb.addController(ctrl); break; }
        } catch (_) {}
      }
      // fallback: SimpleAnimation
      if (topAb.animationByName('') == null) {
        try { topAb.addController(SimpleAnimation(topAb.animations.first.name)); } catch (_) {}
      }

      // 하단 스타트 버튼
      final btnFile = await RiveFile.asset('assets/rive/start_button.riv');
      final btnAb = btnFile.mainArtboard;
      StateMachineController? btnCtrl;
      for (final name in ['State Machine 1', 'State Machine', 'default']) {
        try {
          btnCtrl = StateMachineController.fromArtboard(btnAb, name);
          if (btnCtrl != null) { btnAb.addController(btnCtrl); break; }
        } catch (_) {}
      }

      // Hovering 항상 ON
      if (btnCtrl != null) {
        for (final input in btnCtrl.inputs) {
          if (input.name == 'Hovering' && input is SMIBool) {
            input.value = true;
          }
        }
      }

      debugPrint('[Splash] Rive loaded successfully');
      if (mounted) {
        setState(() {
          _topArtboard = topAb;
          _btnArtboard = btnAb;
          _btnController = btnCtrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Splash] Rive load failed: $e');
      // Rive 실패해도 UI 표시 (fallback 버튼 사용)
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onStartPressed() {
    if (_pressed) return;
    _pressed = true;

    // Rive Clicked 입력 — 0.5초만 true 유지 후 false
    if (_btnController != null) {
      for (final input in _btnController!.inputs) {
        if (input.name == 'Clicked' && input is SMIBool) {
          input.value = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            input.value = false;
          });
          break;
        }
        // Trigger 타입이면 fire
        if (input.name == 'Clicked' && input is SMITrigger) {
          input.fire();
          break;
        }
      }
    }

    // 2초 대기 (클릭 애니메이션 복귀) → 페이드아웃 1초 → 홈
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _fadeCtrl.forward().then((_) {
        if (mounted) _goHome();
      });
    });
  }

  Future<void> _goHome() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool('isFirstLaunch') ?? true;
    if (!mounted) return;
    context.go(isFirst ? '/onboarding' : '/home');
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF313131),
      body: Stack(
        children: [
          // 메인 콘텐츠
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.accent))
          else ...[
            // ① 상단 캐릭터 — 맨 뒤 (상단 절반)
            if (_topArtboard != null)
              Positioned.fill(
                top: MediaQuery.of(context).size.height * 0.08,
                bottom: MediaQuery.of(context).size.height * 0.35,
                child: IgnorePointer(
                  child: Container(
                    color: Colors.transparent,
                    child: Rive(artboard: _topArtboard!, fit: BoxFit.contain),
                  ),
                ),
              ),

            // ② 스타트 버튼 — 맨 앞, 화면 하단 중앙
            Align(
              alignment: const Alignment(0, 0.75),
              child: GestureDetector(
                onTap: _onStartPressed,
                child: Container(
                  width: 650,
                  height: 310,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.transparent),
                  ),
                  child: _btnArtboard != null
                      ? Rive(artboard: _btnArtboard!, fit: BoxFit.contain)
                      : ElevatedButton(
                          onPressed: _onStartPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text('START', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                ),
              ),
            ),
          ],

          // 페이드아웃 오버레이
          AnimatedBuilder(
            animation: _fadeCtrl,
            builder: (_, __) => _fadeCtrl.value > 0
                ? Container(color: Colors.black.withValues(alpha: _fadeCtrl.value))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
