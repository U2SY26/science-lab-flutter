import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/community_service.dart';
import '../services/device_id_service.dart';

/// 유저 프로필 상태
class UserProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final bool isBlacklisted;
  final String? error;

  const UserProfileState({
    this.profile,
    this.isLoading = true,
    this.isBlacklisted = false,
    this.error,
  });

  UserProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    bool? isBlacklisted,
    String? error,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
      error: error,
    );
  }
}

/// 유저 프로필 Notifier
class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final CommunityService _service = CommunityService();

  UserProfileNotifier() : super(const UserProfileState());

  /// 초기화 (앱 시작 시 호출)
  Future<void> initialize() async {
    if (!DeviceIdService().isReady) return;

    state = state.copyWith(isLoading: true);
    try {
      final profile = await _service.getOrCreateProfile();
      final blacklisted = await _service.isBlacklisted();
      state = state.copyWith(
        profile: profile,
        isBlacklisted: blacklisted,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 프로필 새로고침
  Future<void> refresh() async {
    try {
      final profile = await _service.getOrCreateProfile();
      state = state.copyWith(profile: profile);
    } catch (_) {}
  }

  /// XP 및 레벨 초기화 후 프로필 새로고침
  Future<void> resetProfile() async {
    try {
      await _service.resetXp();
      await refresh();
    } catch (_) {}
  }

  /// XP 추가 후 프로필 새로고침 — 레벨업 여부 반환
  Future<bool> addXpAndRefresh(int amount) async {
    try {
      final result = await _service.addXp(amount);
      await refresh();
      return result.leveledUp;
    } catch (_) {
      return false;
    }
  }
}

/// 유저 프로필 Provider
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileState>(
  (ref) => UserProfileNotifier(),
);

/// 현재 레벨 편의 Provider
final currentLevelProvider = Provider<int>((ref) {
  return ref.watch(userProfileProvider).profile?.level ?? 1;
});

/// 블랙리스트 편의 Provider
final isBlacklistedProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).isBlacklisted;
});
