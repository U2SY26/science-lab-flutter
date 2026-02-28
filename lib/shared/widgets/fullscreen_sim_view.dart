import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ad_banner.dart';

/// 전체화면 시뮬레이션 뷰
/// - 시뮬레이션 캔버스를 화면 전체로 확장
/// - 하단 광고 배너 항상 표시
/// - 우상단 종료 버튼
class FullscreenSimView extends StatefulWidget {
  final Widget Function() simulationBuilder;
  final String title;

  const FullscreenSimView({
    super.key,
    required this.simulationBuilder,
    required this.title,
  });

  @override
  State<FullscreenSimView> createState() => _FullscreenSimViewState();
}

class _FullscreenSimViewState extends State<FullscreenSimView> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // 3초 후 컨트롤 숨기기
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _showControls = !_showControls);
        if (_showControls) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showControls = false);
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 시뮬레이션 전체화면
            Positioned.fill(
              child: widget.simulationBuilder(),
            ),

            // 상단 종료 버튼 (터치 시 토글)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '전체화면 종료',
                  ),
                ),
              ),
            ),

            // 하단 광고 배너 항상 표시 (전체화면에서도)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AdBannerWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 전체화면 열기 헬퍼
void openFullscreenSim(
  BuildContext context, {
  required Widget Function() simulationBuilder,
  required String title,
}) {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  Navigator.of(context)
      .push(
    PageRouteBuilder(
      fullscreenDialog: true,
      opaque: false,
      pageBuilder: (_, __, ___) => FullscreenSimView(
        simulationBuilder: simulationBuilder,
        title: title,
      ),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: child,
      ),
      transitionDuration: const Duration(milliseconds: 300),
    ),
  )
      .then((_) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  });
}
