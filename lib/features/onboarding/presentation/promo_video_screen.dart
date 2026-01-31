import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';

/// 최초 실행 시 프로모 영상 화면
class PromoVideoScreen extends StatefulWidget {
  const PromoVideoScreen({super.key});

  @override
  State<PromoVideoScreen> createState() => _PromoVideoScreenState();
}

class _PromoVideoScreenState extends State<PromoVideoScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showSkipButton = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();

    // 2초 후 스킵 버튼 표시
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSkipButton = true);
      }
    });
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/video/promo.mp4');

    try {
      await _controller.initialize();
      setState(() => _isInitialized = true);

      // 전체화면 모드
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

      _controller.play();

      // 영상 종료 시 다음 화면으로
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          _navigateToNext();
        }
      });
    } catch (e) {
      // 영상 로드 실패 시 바로 다음으로
      _navigateToNext();
    }
  }

  void _navigateToNext() {
    if (!mounted) return;

    // 시스템 UI 복원
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    context.go('/onboarding');
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 영상
          if (_isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          // 스킵 버튼
          if (_showSkipButton)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: _showSkipButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: TextButton.icon(
                  onPressed: _navigateToNext,
                  icon: const Icon(Icons.skip_next, color: Colors.white70),
                  label: const Text(
                    '건너뛰기',
                    style: TextStyle(color: Colors.white70),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black45,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ),

          // 하단 진행 바
          if (_isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: false,
                colors: VideoProgressColors(
                  playedColor: AppColors.accent,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
