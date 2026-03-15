import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 디바이스 ID + Firebase Anonymous Auth 서비스
///
/// 프라이버시 보호: 원본 디바이스 ID를 절대 Firestore에 저장하지 않음.
/// SHA-256 해시를 사용하여 역추적 불가능한 익명 ID를 생성.
/// 블라인드 수준의 익명성 보장.
class DeviceIdService {
  static final DeviceIdService _instance = DeviceIdService._internal();
  factory DeviceIdService() => _instance;
  DeviceIdService._internal();

  static const _hashedIdKey = 'device_hashed_id';
  // 앱 고유 솔트 — 같은 디바이스 ID라도 다른 앱에서 다른 해시가 나옴
  static const _salt = 'science_lab_v1_anonymous';

  String? _hashedId;
  String? _firebaseUid;

  /// 해시된 익명 ID (Firestore 문서 키로 사용)
  String get androidId => _hashedId ?? '';
  String get firebaseUid => _firebaseUid ?? '';
  bool get isReady => _hashedId != null && _hashedId!.isNotEmpty;

  /// 초기화: 디바이스 ID 해시 생성 + Firebase Anonymous 로그인
  Future<void> initialize() async {
    await _loadHashedId();
    await _signInAnonymously();
    debugPrint('[DeviceIdService] hashedId=${_hashedId?.substring(0, 8)}..., uid=$_firebaseUid');
  }

  /// 원본 디바이스 ID를 SHA-256 해시하여 저장
  static String _hashDeviceId(String rawId) {
    final bytes = utf8.encode('$_salt:$rawId');
    return sha256.convert(bytes).toString(); // 64자 hex
  }

  Future<void> _loadHashedId() async {
    final prefs = await SharedPreferences.getInstance();
    _hashedId = prefs.getString(_hashedIdKey);

    if (_hashedId == null || _hashedId!.isEmpty) {
      try {
        String rawId;
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          final info = await DeviceInfoPlugin().androidInfo;
          rawId = info.id; // Android ID (SSAID)
        } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
          final info = await DeviceInfoPlugin().iosInfo;
          rawId = info.identifierForVendor ?? 'ios_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          rawId = 'web_${DateTime.now().millisecondsSinceEpoch}';
        }
        _hashedId = _hashDeviceId(rawId);
        await prefs.setString(_hashedIdKey, _hashedId!);
      } catch (e) {
        debugPrint('[DeviceIdService] Failed to get device ID: $e');
        _hashedId = _hashDeviceId('fallback_${DateTime.now().millisecondsSinceEpoch}');
        await prefs.setString(_hashedIdKey, _hashedId!);
      }
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        _firebaseUid = auth.currentUser!.uid;
      } else {
        final credential = await auth.signInAnonymously();
        _firebaseUid = credential.user?.uid;
      }
    } catch (e) {
      debugPrint('[DeviceIdService] Anonymous sign-in failed: $e');
    }
  }
}
