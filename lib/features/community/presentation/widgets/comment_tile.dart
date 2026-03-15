import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/comment.dart';
import '../../../../core/providers/language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'level_badge.dart';
import 'reaction_bar.dart';
import 'translate_button.dart';

/// 단일 댓글 카드
class CommentTile extends ConsumerWidget {
  final Comment comment;
  final void Function(String reactionType) onReact;
  final VoidCallback onReply;
  final VoidCallback onReport;
  final int replyCount;
  final bool showReplyButton;

  const CommentTile({
    super.key,
    required this.comment,
    required this.onReact,
    required this.onReply,
    required this.onReport,
    this.replyCount = 0,
    this.showReplyButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isKorean = ref.watch(isKoreanProvider);
    final ago = timeAgo(comment.createdAt, isKorean);

    return Container(
      margin: EdgeInsets.only(
        left: comment.isReply ? 32 : 0,
        bottom: 8,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: comment.isReply
            ? AppColors.bg.withValues(alpha: 0.5)
            : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 닉네임 + 레벨 + 시간 + 신고
          Row(
            children: [
              LevelBadge(level: comment.authorLevel, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: DecoratedNickname(
                  nickname: comment.authorNickname,
                  level: comment.authorLevel,
                  fontSize: 13,
                ),
              ),
              Text(
                ago,
                style: TextStyle(
                  color: AppColors.muted.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onReport,
                child: Icon(
                  Icons.more_horiz,
                  color: AppColors.muted.withValues(alpha: 0.4),
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 댓글 본문
          Text(
            comment.content,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          // 번역 버튼
          TranslateButton(
            text: comment.content,
            contentLanguageCode: comment.languageCode,
          ),

          const SizedBox(height: 8),

          // 리액션 바 + 답글 버튼
          Row(
            children: [
              Expanded(
                child: ReactionBar(
                  reactions: comment.reactions,
                  reactedBy: comment.reactedBy,
                  onReact: onReact,
                ),
              ),
              if (showReplyButton) ...[
                GestureDetector(
                  onTap: onReply,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.reply,
                        color: AppColors.muted,
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        replyCount > 0
                            ? (isKorean ? '답글 $replyCount' : '$replyCount replies')
                            : (isKorean ? '답글' : 'Reply'),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
