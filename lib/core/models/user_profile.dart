import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 유저 프로필 모델
class UserProfile {
  final String androidId;
  final String uid;
  final String nickname;
  final int xp;
  final int level;
  final int reportCount;
  final bool isBlacklisted;
  final int dailyAdRewards;
  final String lastAdRewardDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.androidId,
    required this.uid,
    required this.nickname,
    this.xp = 0,
    this.level = 1,
    this.reportCount = 0,
    this.isBlacklisted = false,
    this.dailyAdRewards = 0,
    this.lastAdRewardDate = '',
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    int? xp,
    int? level,
    int? reportCount,
    bool? isBlacklisted,
    int? dailyAdRewards,
    String? lastAdRewardDate,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      androidId: androidId,
      uid: uid,
      nickname: nickname,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      reportCount: reportCount ?? this.reportCount,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
      dailyAdRewards: dailyAdRewards ?? this.dailyAdRewards,
      lastAdRewardDate: lastAdRewardDate ?? this.lastAdRewardDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'androidId': androidId,
    'uid': uid,
    'nickname': nickname,
    'xp': xp,
    'level': level,
    'reportCount': reportCount,
    'isBlacklisted': isBlacklisted,
    'dailyAdRewards': dailyAdRewards,
    'lastAdRewardDate': lastAdRewardDate,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      androidId: map['androidId'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      nickname: map['nickname'] as String? ?? '',
      xp: map['xp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      reportCount: map['reportCount'] as int? ?? 0,
      isBlacklisted: map['isBlacklisted'] as bool? ?? false,
      dailyAdRewards: map['dailyAdRewards'] as int? ?? 0,
      lastAdRewardDate: map['lastAdRewardDate'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// 닉네임 자동 생성: "Scientist_XXXX"
  static String generateNickname() {
    final hex = Random().nextInt(0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0');
    return 'Scientist_$hex';
  }

  /// 레벨 계산: 필요 XP = 30 * level (선형, 빠른 레벨업)
  static int calculateLevel(int totalXp) {
    int level = 1;
    int cumulative = 0;
    while (true) {
      final needed = 30 * level;
      if (cumulative + needed > totalXp) break;
      cumulative += needed;
      level++;
    }
    return level;
  }

  /// 다음 레벨까지 필요한 XP
  int get xpToNextLevel {
    int cumulative = 0;
    for (int i = 1; i < level; i++) {
      cumulative += 30 * i;
    }
    final needed = 30 * level;
    return cumulative + needed - xp;
  }

  /// 현재 레벨 진행률 (0.0 ~ 1.0)
  double get levelProgress {
    int cumulative = 0;
    for (int i = 1; i < level; i++) {
      cumulative += 30 * i;
    }
    final needed = 30 * level;
    if (needed == 0) return 0;
    return ((xp - cumulative) / needed).clamp(0.0, 1.0);
  }
}
