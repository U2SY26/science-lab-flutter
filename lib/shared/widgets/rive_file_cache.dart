import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

/// .riv 파일 인메모리 캐시 — persona 전환 시 재파싱 방지
class RiveFileCache {
  static final Map<String, RiveFile> _cache = {};

  /// personaId에 해당하는 .riv 파일 로드 (캐시 우선)
  static Future<RiveFile?> load(String personaId) async {
    if (_cache.containsKey(personaId)) return _cache[personaId];

    try {
      final data = await rootBundle.load('assets/rive/$personaId.riv');
      final file = RiveFile.import(data);
      _cache[personaId] = file;
      return file;
    } catch (e) {
      // .riv 파일 없음 — 폴백 사용
      return null;
    }
  }

  /// 특정 persona 캐시 존재 여부
  static bool has(String personaId) => _cache.containsKey(personaId);

  /// 캐시 전체 삭제
  static void clear() => _cache.clear();
}
