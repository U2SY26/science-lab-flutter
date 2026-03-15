import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/comment.dart';
import '../models/forum_post.dart';
import '../models/user_profile.dart';
import 'device_id_service.dart';

/// 커뮤니티 Firestore CRUD 서비스
///
/// 프라이버시 설계:
/// - authorId는 해시된 디바이스 ID (원본 복원 불가)
/// - reactedBy는 해시 ID 목록 (토글 용도만, UI에 노출하지 않음)
/// - reportedBy도 해시 ID 목록 (중복 신고 방지 용도만)
class CommunityService {
  static final CommunityService _instance = CommunityService._internal();
  factory CommunityService() => _instance;
  CommunityService._internal();

  final _db = FirebaseFirestore.instance;

  // 레이트 리밋 추적 (메모리 기반 — 앱 재시작으로 리셋되지만 기본 방어엔 충분)
  DateTime? _lastCommentTime;
  DateTime? _lastPostTime;
  static const _commentCooldown = Duration(seconds: 10);
  static const _postCooldown = Duration(seconds: 30);

  // 콘텐츠 길이 제한
  static const maxCommentLength = 500;
  static const maxPostTitleLength = 100;
  static const maxPostContentLength = 2000;

  CollectionReference get _users => _db.collection('users');
  CollectionReference get _comments => _db.collection('comments');
  CollectionReference get _forumPosts => _db.collection('forum_posts');
  CollectionReference get _blacklist => _db.collection('blacklist');
  CollectionReference get _quizResults => _db.collection('quiz_results');

  /// DeviceIdService 준비 여부 확인 + 해시 ID 반환
  String _requireDeviceId() {
    final id = DeviceIdService().androidId;
    if (id.isEmpty) throw Exception('Device ID not ready');
    return id;
  }

  // ── 유저 프로필 ─────────────────────────────────────────

  /// 유저 프로필 가져오기 (없으면 생성)
  Future<UserProfile> getOrCreateProfile() async {
    final deviceId = _requireDeviceId();

    final doc = await _users.doc(deviceId).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
    }

    final now = DateTime.now();
    final profile = UserProfile(
      androidId: deviceId,
      uid: DeviceIdService().firebaseUid,
      nickname: UserProfile.generateNickname(),
      createdAt: now,
      updatedAt: now,
    );
    await _users.doc(deviceId).set(profile.toMap());
    return profile;
  }

  /// 블랙리스트 여부 확인
  Future<bool> isBlacklisted() async {
    final deviceId = DeviceIdService().androidId;
    if (deviceId.isEmpty) return false;
    try {
      final doc = await _blacklist.doc(deviceId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('[CommunityService] isBlacklisted check failed: $e');
      return false;
    }
  }

  // ── 댓글 ────────────────────────────────────────────────

  /// 댓글 목록 (커서 기반 페이지네이션, 최신순)
  Future<List<Comment>> getComments({
    required String simId,
    int pageSize = 5,
    String? parentId,
    DocumentSnapshot? lastDoc,
  }) async {
    Query query = _comments
        .where('simId', isEqualTo: simId)
        .where('isHidden', isEqualTo: false);

    if (parentId == null) {
      query = query.where('parentId', isNull: true);
    } else {
      query = query.where('parentId', isEqualTo: parentId);
    }

    query = query.orderBy('createdAt', descending: parentId == null);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    final snapshot = await query.limit(pageSize).get();
    return snapshot.docs.map((doc) => Comment.fromDoc(doc)).toList();
  }

  /// 특정 페이지의 댓글 가져오기 (페이지 번호 기반 — 내부적으로 skip)
  Future<List<Comment>> getCommentsPage({
    required String simId,
    required int page,
    int pageSize = 5,
  }) async {
    Query query = _comments
        .where('simId', isEqualTo: simId)
        .where('isHidden', isEqualTo: false)
        .where('parentId', isNull: true)
        .orderBy('createdAt', descending: true);

    // 페이지 > 1이면 이전 페이지 문서들을 skip
    if (page > 1) {
      final skipCount = (page - 1) * pageSize;
      final skipSnap = await query.limit(skipCount).get();
      if (skipSnap.docs.isNotEmpty) {
        query = query.startAfterDocument(skipSnap.docs.last);
      }
    }

    final snapshot = await query.limit(pageSize).get();
    return snapshot.docs.map((doc) => Comment.fromDoc(doc)).toList();
  }

  /// 댓글 총 개수
  Future<int> getCommentCount(String simId) async {
    final snapshot = await _comments
        .where('simId', isEqualTo: simId)
        .where('parentId', isNull: true)
        .where('isHidden', isEqualTo: false)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// 댓글 작성 (레이트 리밋 + 길이 검증 포함)
  Future<Comment?> addComment({
    required String simId,
    required String content,
    String? parentId,
    String languageCode = 'en',
  }) async {
    if (await isBlacklisted()) return null;

    // 레이트 리밋 검사
    if (_lastCommentTime != null &&
        DateTime.now().difference(_lastCommentTime!) < _commentCooldown) {
      throw Exception('rate_limited');
    }

    // 콘텐츠 길이 검증
    final trimmed = content.trim();
    if (trimmed.isEmpty || trimmed.length > maxCommentLength) {
      throw Exception('invalid_content');
    }

    final profile = await getOrCreateProfile();
    final now = DateTime.now();

    final data = Comment(
      id: '',
      simId: simId,
      authorId: profile.androidId,
      authorNickname: profile.nickname,
      authorLevel: profile.level,
      content: trimmed,
      parentId: parentId,
      languageCode: languageCode,
      createdAt: now,
      updatedAt: now,
    ).toMap();

    final docRef = await _comments.add(data);
    _lastCommentTime = DateTime.now();

    final newDoc = await docRef.get();
    return Comment.fromDoc(newDoc);
  }

  // ── 리액션 ──────────────────────────────────────────────

  /// 리액션 토글 (댓글 또는 포럼 글)
  Future<void> toggleReaction({
    required String collection,
    required String docId,
    required String reactionType,
  }) async {
    final deviceId = _requireDeviceId();
    final ref = _db.collection(collection).doc(docId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final reactedBy = Map<String, List<dynamic>>.from(data['reactedBy'] ?? {});
      final reactions = Map<String, int>.from(data['reactions'] ?? {});

      final list = List<String>.from(reactedBy[reactionType] ?? []);
      if (list.contains(deviceId)) {
        list.remove(deviceId);
        reactions[reactionType] = ((reactions[reactionType] ?? 1) - 1).clamp(0, 999999);
      } else {
        list.add(deviceId);
        reactions[reactionType] = (reactions[reactionType] ?? 0) + 1;
      }
      reactedBy[reactionType] = list;

      tx.update(ref, {'reactions': reactions, 'reactedBy': reactedBy});
    });
  }

  // ── 신고 ────────────────────────────────────────────────

  /// 신고하기
  Future<String> reportContent({
    required String collection,
    required String docId,
  }) async {
    final deviceId = _requireDeviceId();
    final ref = _db.collection(collection).doc(docId);

    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return 'not_found';

      final data = snap.data() ?? {};
      final reportedBy = List<String>.from(data['reportedBy'] ?? []);

      if (reportedBy.contains(deviceId)) return 'already_reported';

      reportedBy.add(deviceId);
      final newCount = reportedBy.length;

      final updates = <String, dynamic>{
        'reportedBy': reportedBy,
        'reportCount': newCount,
      };

      // 3건 이상 신고 시 자동 숨김
      if (newCount >= 3) {
        updates['isHidden'] = true;
      }

      tx.update(ref, updates);

      // 작성자 누적 신고수 증가 + 블랙리스트 처리는 Cloud Functions가 담당
      // (onCommentReported / onForumPostReported 트리거)
      // 클라이언트는 reportedBy 배열에 자기 ID만 추가

      return 'reported';
    });
  }

  // ── 포럼 ────────────────────────────────────────────────

  /// 포럼 글 목록
  Future<List<ForumPost>> getForumPosts({
    required int page,
    int pageSize = 10,
    String? category,
  }) async {
    Query query = _forumPosts.where('isHidden', isEqualTo: false);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('createdAt', descending: true);

    if (page > 1) {
      final skipCount = (page - 1) * pageSize;
      final skipSnap = await query.limit(skipCount).get();
      if (skipSnap.docs.isNotEmpty) {
        query = query.startAfterDocument(skipSnap.docs.last);
      }
    }

    final snapshot = await query.limit(pageSize).get();
    return snapshot.docs.map((doc) => ForumPost.fromDoc(doc)).toList();
  }

  /// 포럼 글 총 개수
  Future<int> getForumPostCount({String? category}) async {
    Query query = _forumPosts.where('isHidden', isEqualTo: false);
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  /// 포럼 글 작성 (레이트 리밋 + 길이 검증 포함)
  Future<ForumPost?> addForumPost({
    required String title,
    required String content,
    required String category,
    String languageCode = 'en',
  }) async {
    if (await isBlacklisted()) return null;

    // 레이트 리밋 검사
    if (_lastPostTime != null &&
        DateTime.now().difference(_lastPostTime!) < _postCooldown) {
      throw Exception('rate_limited');
    }

    // 콘텐츠 길이 검증
    final trimTitle = title.trim();
    final trimContent = content.trim();
    if (trimTitle.isEmpty || trimTitle.length > maxPostTitleLength) {
      throw Exception('invalid_title');
    }
    if (trimContent.isEmpty || trimContent.length > maxPostContentLength) {
      throw Exception('invalid_content');
    }

    final profile = await getOrCreateProfile();
    final now = DateTime.now();

    final data = ForumPost(
      id: '',
      authorId: profile.androidId,
      authorNickname: profile.nickname,
      authorLevel: profile.level,
      title: trimTitle,
      content: trimContent,
      category: category,
      languageCode: languageCode,
      createdAt: now,
      updatedAt: now,
    ).toMap();

    final docRef = await _forumPosts.add(data);
    _lastPostTime = DateTime.now();

    final newDoc = await docRef.get();
    return ForumPost.fromDoc(newDoc);
  }

  /// 포럼 글 삭제 (작성자만)
  Future<bool> deleteForumPost(String postId) async {
    final deviceId = _requireDeviceId();
    try {
      final doc = await _forumPosts.doc(postId).get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (data['authorId'] != deviceId) return false;
      await _forumPosts.doc(postId).delete();
      return true;
    } catch (e) {
      debugPrint('[CommunityService] deleteForumPost failed: $e');
      return false;
    }
  }

  /// 포럼 글 수정 (작성자만)
  Future<bool> editForumPost({
    required String postId,
    required String title,
    required String content,
  }) async {
    final deviceId = _requireDeviceId();
    try {
      final doc = await _forumPosts.doc(postId).get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (data['authorId'] != deviceId) return false;
      await _forumPosts.doc(postId).update({
        'title': title.trim(),
        'content': content.trim(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('[CommunityService] editForumPost failed: $e');
      return false;
    }
  }

  /// 댓글 삭제 (작성자만)
  Future<bool> deleteComment(String commentId) async {
    final deviceId = _requireDeviceId();
    try {
      final doc = await _comments.doc(commentId).get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (data['authorId'] != deviceId) return false;
      await _comments.doc(commentId).delete();
      return true;
    } catch (e) {
      debugPrint('[CommunityService] deleteComment failed: $e');
      return false;
    }
  }

  /// 포럼 글 상세
  Future<ForumPost?> getForumPost(String postId) async {
    final doc = await _forumPosts.doc(postId).get();
    if (!doc.exists) return null;
    return ForumPost.fromDoc(doc);
  }

  /// 포럼 글 댓글 수 증가
  Future<void> incrementCommentCount(String postId) async {
    try {
      await _forumPosts.doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('[CommunityService] incrementCommentCount failed: $e');
    }
  }

  // ── 퀴즈 ────────────────────────────────────────────────

  /// 퀴즈 이미 완료했는지 확인
  Future<bool> hasCompletedQuiz(String simId) async {
    final deviceId = DeviceIdService().androidId;
    if (deviceId.isEmpty) return false;
    try {
      final doc = await _quizResults.doc('${deviceId}_$simId').get();
      return doc.exists;
    } catch (e) {
      debugPrint('[CommunityService] hasCompletedQuiz failed: $e');
      return false;
    }
  }

  /// 퀴즈 결과 저장
  Future<void> saveQuizResult({
    required String simId,
    required bool correct,
    required int xpAwarded,
  }) async {
    final deviceId = _requireDeviceId();
    await _quizResults.doc('${deviceId}_$simId').set({
      'simId': simId,
      'userId': deviceId,
      'correct': correct,
      'xpAwarded': xpAwarded,
      'createdAt': Timestamp.now(),
    });
  }

  // ── XP ──────────────────────────────────────────────────

  /// XP 및 레벨 초기화
  Future<void> resetXp() async {
    final deviceId = _requireDeviceId();
    await _users.doc(deviceId).update({
      'xp': 0,
      'level': 1,
      'updatedAt': Timestamp.now(),
    });
  }

  /// XP 추가 및 레벨 계산 (트랜잭션으로 race condition 방지)
  Future<({int newXp, int newLevel, bool leveledUp})> addXp(int amount) async {
    final deviceId = _requireDeviceId();
    final userRef = _users.doc(deviceId);

    return _db.runTransaction((tx) async {
      final doc = await tx.get(userRef);
      if (!doc.exists) throw Exception('User profile not found');

      final data = doc.data() as Map<String, dynamic>? ?? {};
      final oldXp = data['xp'] as int? ?? 0;
      final oldLevel = data['level'] as int? ?? 1;
      final newXp = oldXp + amount;
      final newLevel = UserProfile.calculateLevel(newXp);

      tx.update(userRef, {
        'xp': newXp,
        'level': newLevel,
        'updatedAt': Timestamp.now(),
      });

      return (newXp: newXp, newLevel: newLevel, leveledUp: newLevel > oldLevel);
    });
  }

  /// 보상형 광고 XP (일 3회 제한)
  Future<bool> canClaimAdReward() async {
    final deviceId = DeviceIdService().androidId;
    if (deviceId.isEmpty) return false;
    try {
      final doc = await _users.doc(deviceId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>? ?? {};
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastDate = data['lastAdRewardDate'] as String? ?? '';
      final count = data['dailyAdRewards'] as int? ?? 0;

      if (lastDate != today) return true;
      return count < 3;
    } catch (e) {
      debugPrint('[CommunityService] canClaimAdReward failed: $e');
      return false;
    }
  }

  Future<void> claimAdReward() async {
    final deviceId = _requireDeviceId();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final doc = await _users.doc(deviceId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>? ?? {};
    final lastDate = data['lastAdRewardDate'] as String? ?? '';

    if (lastDate != today) {
      await _users.doc(deviceId).update({
        'dailyAdRewards': 1,
        'lastAdRewardDate': today,
      });
    } else {
      await _users.doc(deviceId).update({
        'dailyAdRewards': FieldValue.increment(1),
      });
    }
  }
}
