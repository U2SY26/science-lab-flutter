import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/ai_chat_provider.dart';
import '../../features/home/data/xr_sim_ids.dart';

/// XR 3D WebView 뷰어 — 풀스크린으로 웹 XR 시뮬레이션 로드
/// 자이로스코프(DeviceOrientation) 지원 포함
class XrWebViewViewer extends ConsumerStatefulWidget {
  final String simId;

  const XrWebViewViewer({super.key, required this.simId});

  @override
  ConsumerState<XrWebViewViewer> createState() => _XrWebViewViewerState();
}

class _XrWebViewViewerState extends ConsumerState<XrWebViewViewer> {
  double _progress = 0;
  bool _hasError = false;
  bool _showSlowWarning = false;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    // AI 튜터 오버레이 숨기기 — 3D 환경에서는 3D만 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(showAiOverlayProvider.notifier).state = false;
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // XR 모드: 가로모드 강제 (WebXR 3D 시뮬레이션 최적화)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 25초 후에도 로딩 50% 미만이면 느린 로딩 경고 표시
    _slowTimer = Timer(const Duration(seconds: 25), () {
      if (mounted && _progress < 0.5 && !_hasError) {
        setState(() => _showSlowWarning = true);
      }
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    // AI 튜터 오버레이 복원 (.then() 콜백에서 주로 처리, 여기선 fallback)
    try {
      ref.read(showAiOverlayProvider.notifier).state = true;
    } catch (_) {}
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // 세로모드 복원
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _openInBrowser() async {
    final url = getXrViewerUrl(widget.simId);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // AI 튜터 복원 — 닫기 직전 호출 (ref가 살아있는 시점)
  void _restoreAiOverlay() {
    try {
      ref.read(showAiOverlayProvider.notifier).state = true;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final url = getXrViewerUrl(widget.simId);

    return PopScope(
      // 시스템 백 제스처/버튼으로 닫힐 때도 AI 튜터 복원
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _restoreAiOverlay();
      },
      child: Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // WebView
          if (!_hasError)
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(url)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                useHybridComposition: true,
                transparentBackground: false,
                allowsInlineMediaPlayback: true,
                supportZoom: false,
                // Android WebGL 안정성: 다크모드 강제 비활성 (색상 왜곡 방지)
                algorithmicDarkeningAllowed: false,
              ),
              onProgressChanged: (controller, progress) {
                setState(() {
                  _progress = progress / 100;
                  // 로딩 완료되면 느린 경고 숨기기
                  if (_progress >= 1.0) _showSlowWarning = false;
                });
              },
              onLoadStop: (controller, url) async {
                _slowTimer?.cancel();
                setState(() => _showSlowWarning = false);
                // XR 뷰어 전용: 디버그 HUD(FPS/Draw/Tris) + 광고 영역 제거
                await controller.evaluateJavascript(source: r"""
                  (function() {
                    var attempts = 0;
                    var timer = setInterval(function() {
                      // 디버그 HUD: 좌상단 monospace 오버레이 숨기기
                      document.querySelectorAll('*').forEach(function(el) {
                        var s = window.getComputedStyle(el);
                        if ((s.position === 'absolute' || s.position === 'fixed') &&
                            s.fontFamily.indexOf('monospace') !== -1 &&
                            el.getBoundingClientRect().top < 120 &&
                            el.getBoundingClientRect().left < 200) {
                          el.style.display = 'none';
                        }
                      });
                      // AdSense 자동 광고 숨기기
                      document.querySelectorAll(
                        'ins.adsbygoogle, .adsbygoogle, [id*="google_ads"], ' +
                        'iframe[src*="googlesyndication"], iframe[src*="doubleclick"]'
                      ).forEach(function(el) {
                        var p = el.parentElement || el;
                        p.style.height = '0';
                        p.style.overflow = 'hidden';
                        p.style.display = 'none';
                      });
                      if (++attempts >= 8) clearInterval(timer);
                    }, 800);
                  })();
                """);
              },
              onPermissionRequest: (controller, request) async {
                // 자이로스코프(DeviceOrientation) 퍼미션 허용
                return PermissionResponse(
                  resources: request.resources,
                  action: PermissionResponseAction.GRANT,
                );
              },
              onReceivedError: (controller, request, error) {
                if (request.isForMainFrame ?? false) {
                  _slowTimer?.cancel();
                  setState(() => _hasError = true);
                }
              },
            ),

          // 오프라인 에러 오버레이
          if (_hasError) _buildErrorOverlay(context),

          // 로딩 바
          if (_progress < 1.0 && !_hasError)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.transparent,
                color: AppColors.accent,
                minHeight: 3,
              ),
            ),

          // 느린 로딩 경고 + 외부 브라우저 버튼
          if (_showSlowWarning && !_hasError && _progress < 1.0)
            _buildSlowLoadingBanner(context),

          // 닫기 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: GestureDetector(
              onTap: () {
                _restoreAiOverlay();
                Navigator.of(context).pop();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white24,
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    ),  // Scaffold
    );  // PopScope
  }

  Widget _buildSlowLoadingBanner(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_empty, color: Colors.white54, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '3D 로딩에 시간이 걸립니다.\n외부 브라우저에서 더 빠를 수 있어요.',
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _openInBrowser,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('브라우저로\n열기', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, height: 1.3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, color: AppColors.muted, size: 48),
            const SizedBox(height: 16),
            Text(
              '인터넷 연결이 필요합니다',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    '돌아가기',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _hasError = false;
                      _progress = 0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
