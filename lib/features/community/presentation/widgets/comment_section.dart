import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/community_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/user_profile_provider.dart';
import 'comment_tile.dart';
import 'level_up_overlay.dart';
import 'pagination_bar.dart';
import 'report_dialog.dart';

/// 시뮬레이션 페이지 하단 댓글 섹션 (재사용 가능)
class CommentSection extends ConsumerStatefulWidget {
  final String simId;

  const CommentSection({super.key, required this.simId});

  @override
  ConsumerState<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<CommentSection> {
  final _controller = TextEditingController();
  String? _replyToId;
  String? _replyToNickname;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commentProvider(widget.simId));
    final isKorean = ref.watch(isKoreanProvider);
    final isBlacklisted = ref.watch(isBlacklistedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: AppColors.accent, size: 18),
              const SizedBox(width: 6),
              Text(
                isKorean ? '댓글' : 'Comments',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (state.totalCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${state.totalCount}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // 입력창
        if (!isBlacklisted)
          _CommentInput(
            controller: _controller,
            replyToNickname: _replyToNickname,
            isKorean: isKorean,
            isLoading: state.isLoading,
            onCancelReply: () {
              setState(() {
                _replyToId = null;
                _replyToNickname = null;
              });
            },
            onSubmit: () => _submitComment(),
          ),

        if (isBlacklisted)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              isKorean
                  ? '커뮤니티 이용이 제한된 계정입니다.'
                  : 'Your account has been restricted.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),

        // 에러 메시지
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              _errorMessage(state.error!, isKorean),
              style: const TextStyle(color: AppColors.accent2, fontSize: 12),
            ),
          ),

        // 댓글 목록
        if (state.isLoading && state.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else if (state.comments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                isKorean ? '첫 번째 댓글을 남겨보세요!' : 'Be the first to comment!',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: state.comments.map((comment) {
                return CommentTile(
                  comment: comment,
                  onReact: (type) {
                    ref.read(commentProvider(widget.simId).notifier)
                        .toggleReaction(comment.id, type);
                  },
                  onReply: () {
                    setState(() {
                      _replyToId = comment.id;
                      _replyToNickname = comment.authorNickname;
                    });
                  },
                  onReport: () {
                    showReportDialog(
                      context: context,
                      isKorean: isKorean,
                      onConfirm: () {
                        ref.read(commentProvider(widget.simId).notifier)
                            .report(comment.id);
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),

        // 페이지네이션
        PaginationBar(
          currentPage: state.currentPage,
          totalPages: state.totalPages,
          onPageChanged: (page) {
            ref.read(commentProvider(widget.simId).notifier).loadPage(page);
          },
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final langCode = Localizations.localeOf(context).languageCode;
    final success = await ref.read(commentProvider(widget.simId).notifier)
        .addComment(text, parentId: _replyToId, languageCode: langCode);

    if (success) {
      _controller.clear();
      setState(() {
        _replyToId = null;
        _replyToNickname = null;
      });
      // XP +5 (댓글 작성) + 레벨업 체크
      final leveledUp = await ref.read(userProfileProvider.notifier).addXpAndRefresh(5);
      if (leveledUp && mounted) {
        final p = ref.read(userProfileProvider).profile;
        LevelUpOverlay.show(context, p?.level ?? ref.read(currentLevelProvider),
          currentXp: p?.xp ?? 0, nextLevelXp: (p?.xp ?? 0) + (p?.xpToNextLevel ?? 0));
      }
    }
  }

  String _errorMessage(String error, bool isKorean) {
    if (error == 'moderation_failed') {
      return isKorean
          ? '커뮤니티 가이드라인에 위반되는 내용입니다.'
          : 'This content violates community guidelines.';
    }
    if (error == 'blacklisted') {
      return isKorean
          ? '커뮤니티 이용이 제한된 계정입니다.'
          : 'Your account has been restricted.';
    }
    if (error == 'rate_limited') {
      return isKorean
          ? '잠시 후 다시 시도해주세요.'
          : 'Please wait a moment before posting again.';
    }
    return isKorean ? '오류가 발생했습니다.' : 'An error occurred.';
  }
}

/// 댓글 입력창
class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final String? replyToNickname;
  final bool isKorean;
  final bool isLoading;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmit;

  const _CommentInput({
    required this.controller,
    this.replyToNickname,
    required this.isKorean,
    required this.isLoading,
    required this.onCancelReply,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 답글 표시
          if (replyToNickname != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.reply, color: AppColors.accent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    isKorean
                        ? '$replyToNickname 님에게 답글'
                        : 'Replying to $replyToNickname',
                    style: const TextStyle(color: AppColors.accent, fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: const Icon(Icons.close, color: AppColors.muted, size: 14),
                  ),
                ],
              ),
            ),

          // 입력 필드
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLength: 500,
                  maxLines: 3,
                  minLines: 1,
                  style: const TextStyle(color: AppColors.ink, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: isKorean ? '댓글을 입력하세요...' : 'Write a comment...',
                    hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.5)),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.bg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.cardBorder),
                    ),
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isLoading ? null : onSubmit,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            color: AppColors.bg,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: AppColors.bg, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
