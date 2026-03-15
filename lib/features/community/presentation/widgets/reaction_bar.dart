import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/comment.dart';
import '../../../../core/services/device_id_service.dart';

/// 리액션 아이콘 바 (❤️ 👍 🔥 🧠)
class ReactionBar extends StatelessWidget {
  final Map<String, int> reactions;
  final Map<String, List<String>> reactedBy;
  final void Function(String reactionType) onReact;

  const ReactionBar({
    super.key,
    required this.reactions,
    required this.reactedBy,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final myId = DeviceIdService().androidId;

    return Row(
      children: ReactionType.values.map((type) {
        final count = reactions[type.name] ?? 0;
        final reacted = (reactedBy[type.name] ?? []).contains(myId);

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onReact(type.name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: reacted
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: reacted
                      ? AppColors.accent.withValues(alpha: 0.4)
                      : AppColors.cardBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(type.emoji, style: const TextStyle(fontSize: 14)),
                  if (count > 0) ...[
                    const SizedBox(width: 3),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: reacted ? AppColors.accent : AppColors.muted,
                        fontSize: 12,
                        fontWeight: reacted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
