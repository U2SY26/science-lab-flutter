import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/forum_post.dart';
import '../../../core/providers/community_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/user_profile_provider.dart';
import '../../../core/services/community_service.dart';
import '../../../core/services/device_id_service.dart';
import 'widgets/comment_section.dart';
import 'widgets/level_badge.dart';
import 'widgets/level_up_overlay.dart';
import 'widgets/pagination_bar.dart';
import 'widgets/report_dialog.dart';
import 'widgets/translate_button.dart';

/// 커뮤니티 탭 (포럼 메인)
class CommunityTab extends ConsumerWidget {
  const CommunityTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(forumProvider);
    final isKorean = ref.watch(isKoreanProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Text(
          isKorean ? '커뮤니티' : 'Community',
          style: const TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 카테고리 필터 칩
          _CategoryChips(
            selected: state.selectedCategory,
            isKorean: isKorean,
            onSelected: (cat) {
              ref.read(forumProvider.notifier).setCategory(cat);
            },
          ),

          // 글 목록
          Expanded(
            child: state.isLoading && state.posts.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : state.posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forum_outlined, color: AppColors.muted, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              isKorean ? '아직 글이 없습니다.\n첫 번째 글을 작성해보세요!' : 'No posts yet.\nBe the first to write!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: () => ref.read(forumProvider.notifier).loadPage(1),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: state.posts.length,
                          itemBuilder: (context, index) {
                            return _ForumPostTile(
                              post: state.posts[index],
                              isKorean: isKorean,
                              onTap: () => _openPost(context, state.posts[index].id),
                            );
                          },
                        ),
                      ),
          ),

          // 페이지네이션
          PaginationBar(
            currentPage: state.currentPage,
            totalPages: state.totalPages,
            onPageChanged: (page) {
              ref.read(forumProvider.notifier).loadPage(page);
            },
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 56),
        child: FloatingActionButton.small(
          backgroundColor: AppColors.accent,
          onPressed: () => _createPost(context),
          child: const Icon(Icons.edit, size: 20, color: AppColors.bg),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  void _openPost(BuildContext context, String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ForumPostScreen(postId: postId),
      ),
    );
  }

  void _createPost(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _CreatePostScreen()),
    );
  }
}

/// 카테고리 필터 칩 바
class _CategoryChips extends StatelessWidget {
  final String? selected;
  final bool isKorean;
  final ValueChanged<String?> onSelected;

  const _CategoryChips({
    this.selected,
    required this.isKorean,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Chip(
              label: isKorean ? '전체' : 'All',
              isSelected: selected == null,
              onTap: () => onSelected(null),
            ),
            ...ForumCategory.values.map((cat) => _Chip(
              label: '${cat.icon} ${cat.label(isKorean)}',
              isSelected: selected == cat.name,
              onTap: () => onSelected(cat.name),
            )),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.accent : AppColors.muted,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

/// 포럼 글 타일
class _ForumPostTile extends StatelessWidget {
  final ForumPost post;
  final bool isKorean;
  final VoidCallback onTap;

  const _ForumPostTile({required this.post, required this.isKorean, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = ForumCategory.values.firstWhere(
      (c) => c.name == post.category,
      orElse: () => ForumCategory.general,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 + 작성자
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cat.label(isKorean),
                    style: const TextStyle(color: AppColors.accent, fontSize: 10),
                  ),
                ),
                const Spacer(),
                LevelBadge(level: post.authorLevel, size: 14),
                const SizedBox(width: 4),
                DecoratedNickname(nickname: post.authorNickname, level: post.authorLevel, fontSize: 12),
              ],
            ),
            const SizedBox(height: 8),

            // 제목
            Text(
              post.title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // 미리보기
            Text(
              post.content,
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // 하단 통계
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: AppColors.muted, size: 14),
                const SizedBox(width: 3),
                Text('${post.commentCount}', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(width: 12),
                Text('❤️', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 2),
                Text('${post.reactions['heart'] ?? 0}', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const Spacer(),
                Text(
                  timeAgo(post.createdAt, isKorean),
                  style: TextStyle(color: AppColors.muted.withValues(alpha: 0.5), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

/// 포럼 글 상세 화면
class _ForumPostScreen extends ConsumerStatefulWidget {
  final String postId;
  const _ForumPostScreen({required this.postId});

  @override
  ConsumerState<_ForumPostScreen> createState() => _ForumPostScreenState();
}

class _ForumPostScreenState extends ConsumerState<_ForumPostScreen> {
  ForumPost? _post;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    final post = await CommunityService().getForumPost(widget.postId);
    if (mounted) {
      setState(() {
        _post = post;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(backgroundColor: AppColors.card),
        body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_post == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(backgroundColor: AppColors.card),
        body: Center(
          child: Text(
            isKorean ? '글을 찾을 수 없습니다.' : 'Post not found.',
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Text(
          _post!.title,
          style: const TextStyle(color: AppColors.ink, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // 작성자 삭제 버튼
          if (_post!.authorId == DeviceIdService().androidId)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.card,
                    title: Text(isKorean ? '글 삭제' : 'Delete Post',
                        style: const TextStyle(color: AppColors.ink)),
                    content: Text(isKorean ? '이 글을 삭제하시겠습니까?' : 'Delete this post?',
                        style: const TextStyle(color: AppColors.muted)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false),
                          child: Text(isKorean ? '취소' : 'Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true),
                          child: Text(isKorean ? '삭제' : 'Delete',
                              style: const TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  final ok = await CommunityService().deleteForumPost(widget.postId);
                  if (mounted) {
                    if (ok) {
                      ref.read(forumProvider.notifier).loadPage(1);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isKorean ? '삭제에 실패했습니다.' : 'Failed to delete.'),
                      ));
                    }
                  }
                }
              },
            ),
          // 신고 버튼
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: AppColors.muted, size: 20),
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              showReportDialog(
                context: context,
                isKorean: isKorean,
                onConfirm: () async {
                  final result = await ref.read(forumProvider.notifier).report(widget.postId);
                  if (mounted) {
                    final msg = result == 'reported'
                        ? (isKorean ? '신고가 접수되었습니다.' : 'Report submitted.')
                        : result == 'already_reported'
                            ? (isKorean ? '이미 신고한 글입니다.' : 'Already reported.')
                            : (isKorean ? '오류가 발생했습니다.' : 'An error occurred.');
                    messenger.showSnackBar(
                      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 글 내용
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      LevelBadge(level: _post!.authorLevel, size: 18),
                      const SizedBox(width: 8),
                      DecoratedNickname(nickname: _post!.authorNickname, level: _post!.authorLevel),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _post!.content,
                    style: const TextStyle(color: AppColors.ink, fontSize: 15, height: 1.6),
                  ),
                  // 번역 버튼
                  TranslateButton(
                    text: _post!.content,
                    contentLanguageCode: _post!.languageCode,
                  ),
                ],
              ),
            ),

            Divider(color: AppColors.cardBorder, height: 1),

            // 댓글 섹션 (CommentSection 재사용, simId='forum_{postId}')
            CommentSection(simId: 'forum_${widget.postId}'),
          ],
        ),
      ),
    );
  }
}

/// 글 작성 화면
class _CreatePostScreen extends ConsumerStatefulWidget {
  const _CreatePostScreen();

  @override
  ConsumerState<_CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<_CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _category = 'general';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKorean = ref.watch(isKoreanProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Text(
          isKorean ? '새 글 작성' : 'New Post',
          style: const TextStyle(color: AppColors.ink, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(
              isKorean ? '게시' : 'Post',
              style: TextStyle(
                color: _isSubmitting ? AppColors.muted : AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 카테고리 선택
            DropdownButtonFormField<String>(
              initialValue: _category,
              dropdownColor: AppColors.card,
              style: const TextStyle(color: AppColors.ink),
              decoration: InputDecoration(
                labelText: isKorean ? '카테고리' : 'Category',
                labelStyle: const TextStyle(color: AppColors.muted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
              ),
              items: ForumCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat.name,
                  child: Text('${cat.icon} ${cat.label(isKorean)}'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _category = val ?? 'general'),
            ),
            const SizedBox(height: 12),

            // 제목
            TextField(
              controller: _titleController,
              maxLength: 100,
              style: const TextStyle(color: AppColors.ink, fontSize: 16),
              decoration: InputDecoration(
                labelText: isKorean ? '제목' : 'Title',
                labelStyle: const TextStyle(color: AppColors.muted),
                counterStyle: const TextStyle(color: AppColors.muted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 내용
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLength: 2000,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(color: AppColors.ink, fontSize: 14),
                decoration: InputDecoration(
                  labelText: isKorean ? '내용' : 'Content',
                  labelStyle: const TextStyle(color: AppColors.muted),
                  counterStyle: const TextStyle(color: AppColors.muted),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    final isKorean = ref.read(isKoreanProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSubmitting = true);

    final langCode = Localizations.localeOf(context).languageCode;
    final success = await ref.read(forumProvider.notifier).addPost(
      title: title,
      content: content,
      category: _category,
      languageCode: langCode,
    );

    if (mounted) {
      if (success) {
        // XP +8 (포럼 글 작성) + 레벨업 체크
        final leveledUp = await ref.read(userProfileProvider.notifier).addXpAndRefresh(8);
        if (leveledUp && mounted) {
          final p = ref.read(userProfileProvider).profile;
          LevelUpOverlay.show(context, p?.level ?? ref.read(currentLevelProvider),
            currentXp: p?.xp ?? 0, nextLevelXp: (p?.xp ?? 0) + (p?.xpToNextLevel ?? 0));
        }
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _isSubmitting = false);
        // 에러 피드백 표시
        final error = ref.read(forumProvider).error;
        final msg = _errorMessage(error, isKorean);
        messenger.showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  String _errorMessage(String? error, bool isKorean) {
    if (error == 'moderation_failed') {
      return isKorean ? '커뮤니티 가이드라인에 위반되는 내용입니다.' : 'Content violates community guidelines.';
    }
    if (error == 'blacklisted') {
      return isKorean ? '커뮤니티 이용이 제한된 계정입니다.' : 'Your account has been restricted.';
    }
    if (error == 'rate_limited') {
      return isKorean ? '잠시 후 다시 시도해주세요.' : 'Please wait before posting again.';
    }
    // 디버그: 실제 에러 메시지 포함하여 원인 파악
    if (kDebugMode && error != null) {
      return '[$error]';
    }
    return isKorean ? '오류가 발생했습니다. 네트워크 확인 후 재시도.' : 'An error occurred. Check network and retry.';
  }
}
