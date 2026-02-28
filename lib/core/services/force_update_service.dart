import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';

/// Force Update Service — Firebase Remote Config 기반
class ForceUpdateService {
  static final ForceUpdateService _instance = ForceUpdateService._internal();
  factory ForceUpdateService() => _instance;
  ForceUpdateService._internal();

  bool _initialized = false;

  /// Dynamic values (populated after initialize)
  String _currentVersion = '';
  String _minimumVersion = '1.0.0';
  String _latestVersion = '';
  bool _forceUpdate = false;
  String _updateMessageEn = '';
  String _updateMessageKo = '';

  String get currentVersion => _currentVersion;
  String get minimumVersion => _minimumVersion;
  String get latestVersion => _latestVersion;

  /// Play Store URL
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.sciencelab.science_lab_flutter';

  /// App Store URL (for future iOS release)
  static const String appStoreUrl =
      'https://apps.apple.com/app/visual-science-lab/id123456789';

  /// Initialize: fetch remote config + read package info
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      // 1. Read current app version
      final packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = packageInfo.version; // e.g. "1.20.2"

      // 2. Setup & fetch remote config
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Defaults (safe — won't trigger update dialog)
      await remoteConfig.setDefaults({
        'minimum_version': '1.0.0',
        'latest_version': _currentVersion,
        'force_update': false,
        'update_message_en': '',
        'update_message_ko': '',
      });

      // Fetch & activate
      await remoteConfig.fetchAndActivate();

      // 3. Read values
      _minimumVersion = remoteConfig.getString('minimum_version');
      _latestVersion = remoteConfig.getString('latest_version');
      _forceUpdate = remoteConfig.getBool('force_update');
      _updateMessageEn = remoteConfig.getString('update_message_en');
      _updateMessageKo = remoteConfig.getString('update_message_ko');

      _initialized = true;
      debugPrint('[ForceUpdate] current=$_currentVersion min=$_minimumVersion '
          'latest=$_latestVersion force=$_forceUpdate');
    } catch (e) {
      debugPrint('[ForceUpdate] Init failed: $e');
      // On failure, keep defaults — no update dialog shown
      _initialized = true;
    }
  }

  /// Check if update is needed
  bool isUpdateRequired() {
    if (kIsWeb) return false;
    if (_currentVersion.isEmpty) return false;
    return _compareVersions(_currentVersion, _minimumVersion) < 0;
  }

  /// Whether update is mandatory (can't dismiss)
  bool get isForced => _forceUpdate;

  /// Get localized update message
  String getUpdateMessage(String langCode) {
    if (langCode == 'ko' && _updateMessageKo.isNotEmpty) {
      return _updateMessageKo;
    }
    if (_updateMessageEn.isNotEmpty) return _updateMessageEn;
    return '';
  }

  /// Compare two version strings (e.g. "1.20.2" vs "1.20.0")
  /// Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final parts2 = v2.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }

  /// Get store URL based on platform
  String getStoreUrl() {
    if (kIsWeb) return playStoreUrl;
    if (Platform.isAndroid) return playStoreUrl;
    if (Platform.isIOS) return appStoreUrl;
    return playStoreUrl;
  }

  /// Launch store for update
  Future<void> launchStore() async {
    final url = Uri.parse(getStoreUrl());
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Check if user has skipped this version
  Future<bool> hasSkippedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('skippedVersion') == version;
  }

  /// Mark version as skipped
  Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('skippedVersion', version);
  }
}

/// Force Update Dialog Widget
class ForceUpdateDialog extends StatelessWidget {
  final bool isForced;
  final String currentVersion;
  final String requiredVersion;
  final String? customMessage;
  final VoidCallback? onSkip;

  const ForceUpdateDialog({
    super.key,
    required this.isForced,
    required this.currentVersion,
    required this.requiredVersion,
    this.customMessage,
    this.onSkip,
  });

  static Future<void> show(BuildContext context) {
    final service = ForceUpdateService();
    final langCode = Localizations.localeOf(context).languageCode;

    return showDialog(
      context: context,
      barrierDismissible: !service.isForced,
      builder: (context) => ForceUpdateDialog(
        isForced: service.isForced,
        currentVersion: service.currentVersion,
        requiredVersion: service.minimumVersion,
        customMessage: service.getUpdateMessage(langCode),
        onSkip: service.isForced
            ? null
            : () => service.skipVersion(service.minimumVersion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !isForced,
      child: AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.system_update, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.updateRequired,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customMessage != null && customMessage!.isNotEmpty
                  ? customMessage!
                  : l10n.updateDescription,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _VersionRow(label: l10n.currentVersionLabel, version: currentVersion),
                  const SizedBox(height: 8),
                  _VersionRow(label: l10n.requiredVersionLabel, version: requiredVersion, isRequired: true),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.updateBenefits,
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!isForced && onSkip != null)
            TextButton(
              onPressed: () {
                onSkip?.call();
                Navigator.pop(context);
              },
              child: Text(l10n.updateLater, style: const TextStyle(color: Colors.grey)),
            ),
          ElevatedButton(
            onPressed: () => ForceUpdateService().launchStore(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download, size: 18),
                const SizedBox(width: 8),
                Text(l10n.updateNow, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  final String label;
  final String version;
  final bool isRequired;

  const _VersionRow({required this.label, required this.version, this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isRequired ? Colors.orange.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'v$version',
            style: TextStyle(
              color: isRequired ? Colors.orange : Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
