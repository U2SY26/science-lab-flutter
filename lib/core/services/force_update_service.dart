import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Force Update Service
/// Checks if the app needs to be updated and shows blocking dialog
class ForceUpdateService {
  static final ForceUpdateService _instance = ForceUpdateService._internal();
  factory ForceUpdateService() => _instance;
  ForceUpdateService._internal();

  /// Current app version (update this when releasing new versions)
  static const String currentVersion = '1.9.0';

  /// Minimum required version (can be updated from remote config later)
  /// This is the minimum version users must have to use the app
  static const String minimumRequiredVersion = '1.8.0';

  /// Play Store URL
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.sciencelab.flutter';

  /// App Store URL (for future iOS release)
  static const String appStoreUrl =
      'https://apps.apple.com/app/visual-science-lab/id123456789';

  /// Check if force update is needed
  bool isUpdateRequired() {
    if (kIsWeb) return false; // No force update for web

    return _compareVersions(currentVersion, minimumRequiredVersion) < 0;
  }

  /// Compare two version strings
  /// Returns: -1 if v1 < v2, 0 if equal, 1 if v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

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

  /// Check if user has skipped this version (for soft updates)
  Future<bool> hasSkippedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final skippedVersion = prefs.getString('skippedVersion');
    return skippedVersion == version;
  }

  /// Mark version as skipped (for soft updates only)
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
  final VoidCallback? onSkip;

  const ForceUpdateDialog({
    super.key,
    required this.isForced,
    required this.currentVersion,
    required this.requiredVersion,
    this.onSkip,
  });

  static Future<void> show(
    BuildContext context, {
    bool isForced = true,
    String? currentVersion,
    String? requiredVersion,
    VoidCallback? onSkip,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (context) => ForceUpdateDialog(
        isForced: isForced,
        currentVersion: currentVersion ?? ForceUpdateService.currentVersion,
        requiredVersion: requiredVersion ?? ForceUpdateService.minimumRequiredVersion,
        onSkip: onSkip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const Expanded(
              child: Text(
                'Update Required',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A new version of Visual Science Lab is available. Please update to continue using the app.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
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
                  _VersionRow(label: 'Current version', version: currentVersion),
                  const SizedBox(height: 8),
                  _VersionRow(label: 'Required version', version: requiredVersion, isRequired: true),
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
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'New simulations, bug fixes, and performance improvements!',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
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
              child: const Text('Later', style: TextStyle(color: Colors.grey)),
            ),
          ElevatedButton(
            onPressed: () => ForceUpdateService().launchStore(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 18),
                SizedBox(width: 8),
                Text('Update Now', style: TextStyle(fontWeight: FontWeight.bold)),
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
