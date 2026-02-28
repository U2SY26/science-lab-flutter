import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../l10n/app_localizations.dart';

/// What's New 서비스 — 앱 업데이트 후 변경사항 안내
class WhatsNewService {
  static final WhatsNewService _instance = WhatsNewService._internal();
  factory WhatsNewService() => _instance;
  WhatsNewService._internal();

  static const _lastSeenVersionKey = 'whats_new_last_seen_version';

  String _currentVersion = '';

  String get currentVersion => _currentVersion;

  Future<void> initialize() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _currentVersion = packageInfo.version;
  }

  /// 새 버전에서 What's New를 보여줘야 하는지 확인
  Future<bool> shouldShow() async {
    if (_currentVersion.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString(_lastSeenVersionKey) ?? '';
    return lastSeen != _currentVersion;
  }

  /// What's New를 본 것으로 기록
  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSeenVersionKey, _currentVersion);
  }
}

/// What's New 다이얼로그
class WhatsNewDialog extends StatelessWidget {
  final String version;

  const WhatsNewDialog({super.key, required this.version});

  static Future<void> showIfNeeded(BuildContext context) async {
    final service = WhatsNewService();
    if (!await service.shouldShow()) return;

    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => WhatsNewDialog(version: service.currentVersion),
    );
    await service.markSeen();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isKo = Localizations.localeOf(context).languageCode == 'ko';

    final features = isKo
        ? [
            _FeatureItem(
              icon: Icons.auto_fix_high,
              color: const Color(0xFF7C3AED),
              title: 'AI 해설 기능 개선',
              description: '더 안정적인 AI 해설과 상세한 에러 안내',
            ),
            _FeatureItem(
              icon: Icons.speed,
              color: const Color(0xFF3B82F6),
              title: '성능 최적화',
              description: '네트워크 타임아웃 추가로 앱 응답성 향상',
            ),
            _FeatureItem(
              icon: Icons.bug_report,
              color: const Color(0xFF10B981),
              title: '안정성 향상',
              description: '에러 처리 개선 및 사용 횟수 환불 로직 강화',
            ),
          ]
        : [
            _FeatureItem(
              icon: Icons.auto_fix_high,
              color: const Color(0xFF7C3AED),
              title: 'Improved AI Explanations',
              description: 'More stable AI explanations with detailed error messages',
            ),
            _FeatureItem(
              icon: Icons.speed,
              color: const Color(0xFF3B82F6),
              title: 'Performance Optimization',
              description: 'Better app responsiveness with network timeout handling',
            ),
            _FeatureItem(
              icon: Icons.bug_report,
              color: const Color(0xFF10B981),
              title: 'Stability Improvements',
              description: 'Enhanced error handling and usage refund logic',
            ),
          ];

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.new_releases, color: Color(0xFF7C3AED), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.whatsNewTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'v$version',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: f.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(f.icon, color: f.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(l10n.whatsNewDismiss, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}
