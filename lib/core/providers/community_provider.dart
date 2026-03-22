import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment.dart';
import '../models/forum_post.dart';
import '../services/community_service.dart';
import '../services/moderation_service.dart';

/// 댓글 상태
class CommentState {
  final List<Comment> comments;
  final int totalCount;
  final int currentPage;
  final bool isLoading;
  final String? error;

  const CommentState({
    this.comments = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.isLoading = false,
    this.error,
  });

  int get totalPages => (totalCount / 5).ceil().clamp(1, 9999);

  CommentState copyWith({
    List<Comment>? comments,
    int? totalCount,
    int? currentPage,
    bool? isLoading,
    String? error,
  }) {
    return CommentState(
      comments: comments ?? this.comments,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 댓글 Notifier (시뮬레이션별)
class CommentNotifier extends StateNotifier<CommentState> {
  final String simId;
  final CommunityService _service = CommunityService();

  CommentNotifier(this.simId) : super(const CommentState()) {
    loadPage(1);
  }

  Future<void> loadPage(int page) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final comments = await _service.getCommentsPage(
        simId: simId,
        page: page,
      );
      final count = await _service.getCommentCount(simId);
      state = state.copyWith(
        comments: comments,
        totalCount: count,
        currentPage: page,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addComment(String content, {String? parentId, String languageCode = 'en'}) async {
    // 이전 에러 상태 초기화
    state = state.copyWith(error: null);

    // AI 모더레이션
    final pass = await ModerationService().checkContent(content);
    if (!pass) {
      state = state.copyWith(error: 'moderation_failed');
      return false;
    }

    try {
      final comment = await _service.addComment(
        simId: simId,
        content: content,
        parentId: parentId,
        languageCode: languageCode,
      );
      if (comment == null) {
        state = state.copyWith(error: 'blacklisted');
        return false;
      }

      // 포럼 댓글이면 commentCount 증가
      if (simId.startsWith('forum_')) {
        final postId = simId.replaceFirst('forum_', '');
        await _service.incrementCommentCount(postId);
      }

      // 현재 페이지 새로고침
      await loadPage(state.currentPage);
      return true;
    } catch (e) {
      debugPrint('[CommentNotifier] addComment error: $e');
      final msg = e.toString();
      if (msg.contains('rate_limited')) {
        state = state.copyWith(error: 'rate_limited');
      } else if (msg.contains('PERMISSION_DENIED') || msg.contains('permission-denied')) {
        state = state.copyWith(error: 'permission_denied');
      } else {
        state = state.copyWith(error: msg);
      }
      return false;
    }
  }

  Future<void> toggleReaction(String commentId, String reactionType) async {
    try {
      await _service.toggleReaction(
        collection: 'comments',
        docId: commentId,
        reactionType: reactionType,
      );
      await loadPage(state.currentPage);
    } catch (_) {}
  }

  Future<String> report(String commentId) async {
    try {
      return await _service.reportContent(
        collection: 'comments',
        docId: commentId,
      );
    } catch (e) {
      return 'error';
    }
  }
}

/// 시뮬레이션별 댓글 Provider
final commentProvider = StateNotifierProvider.family<CommentNotifier, CommentState, String>(
  (ref, simId) => CommentNotifier(simId),
);

// ── 포럼 ────────────────────────────────────────────────

/// 포럼 상태
class ForumState {
  final List<ForumPost> posts;
  final int totalCount;
  final int currentPage;
  final String? selectedCategory;
  final bool isLoading;
  final String? error;

  const ForumState({
    this.posts = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.selectedCategory,
    this.isLoading = false,
    this.error,
  });

  int get totalPages => (totalCount / 10).ceil().clamp(1, 9999);

  ForumState copyWith({
    List<ForumPost>? posts,
    int? totalCount,
    int? currentPage,
    String? selectedCategory,
    bool? isLoading,
    String? error,
    bool clearCategory = false,
  }) {
    return ForumState(
      posts: posts ?? this.posts,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 포럼 Notifier
class ForumNotifier extends StateNotifier<ForumState> {
  final CommunityService _service = CommunityService();

  ForumNotifier() : super(const ForumState()) {
    loadPage(1);
  }

  Future<void> loadPage(int page) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final posts = await _service.getForumPosts(
        page: page,
        category: state.selectedCategory,
      );
      final count = await _service.getForumPostCount(
        category: state.selectedCategory,
      );
      state = state.copyWith(
        posts: posts,
        totalCount: count,
        currentPage: page,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setCategory(String? category) async {
    state = state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
    );
    await loadPage(1);
  }

  Future<bool> addPost({
    required String title,
    required String content,
    required String category,
    String languageCode = 'en',
  }) async {
    // 이전 에러 상태 초기화
    state = state.copyWith(error: null);

    // AI 모더레이션
    final pass = await ModerationService().checkContent('$title $content');
    if (!pass) {
      state = state.copyWith(error: 'moderation_failed');
      return false;
    }

    try {
      final post = await _service.addForumPost(
        title: title,
        content: content,
        category: category,
        languageCode: languageCode,
      );
      if (post == null) {
        state = state.copyWith(error: 'blacklisted');
        return false;
      }

      await loadPage(1);
      return true;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('rate_limited')) {
        state = state.copyWith(error: 'rate_limited');
      } else {
        state = state.copyWith(error: msg);
      }
      return false;
    }
  }

  Future<String> report(String postId) async {
    try {
      return await _service.reportContent(
        collection: 'forum_posts',
        docId: postId,
      );
    } catch (e) {
      return 'error';
    }
  }
}

/// 포럼 Provider
final forumProvider = StateNotifierProvider<ForumNotifier, ForumState>(
  (ref) => ForumNotifier(),
);
