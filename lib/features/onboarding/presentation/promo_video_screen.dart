import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';

/// 프로모 영상 화면 - 9개 영상 중 랜덤 재생
class PromoVideoScreen extends StatefulWidget {
  const PromoVideoScreen({super.key});

  @override
  State<PromoVideoScreen> createState() => _PromoVideoScreenState();
}

class _PromoVideoScreenState extends State<PromoVideoScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showSkipButton = false;

  // 사용 가능한 프로모 비디오 목록
  static const List<String> _promoVideos = [
    'assets/video/promo1.mp4',
    'assets/video/promo2.mp4',
    'assets/video/promo3.mp4',
    'assets/video/promo4.mp4',
    'assets/video/promo5.mp4',
    'assets/video/promo6.mp4',
    'assets/video/promo7.mp4',
    'assets/video/promo8.mp4',
    'assets/video/promo9.mp4',
  ];

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
    // 랜덤으로 비디오 선택
    final randomIndex = Random().nextInt(_promoVideos.length);
    final selectedVideo = _promoVideos[randomIndex];

    _controller = VideoPlayerController.asset(selectedVideo);

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

  Future<void> _navigateToNext() async {
    if (!mounted) return;

    // 시스템 UI 복원
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // 첫 실행 여부 확인
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (!mounted) return;

    if (isFirstLaunch) {
      // 첫 실행: 온보딩으로 이동
      context.go('/onboarding');
    } else {
      // 이후 실행: 홈으로 바로 이동
      context.go('/home');
    }
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
