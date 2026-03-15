import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// 신고 확인 다이얼로그
void showReportDialog({
  required BuildContext context,
  required bool isKorean,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.flag_outlined, color: AppColors.accent2, size: 22),
          const SizedBox(width: 8),
          Text(
            isKorean ? '신고하기' : 'Report',
            style: const TextStyle(color: AppColors.ink, fontSize: 18),
          ),
        ],
      ),
      content: Text(
        isKorean
            ? '이 콘텐츠를 신고하시겠습니까?\n신고가 누적되면 자동으로 숨겨집니다.'
            : 'Report this content?\nContent will be hidden after multiple reports.',
        style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            isKorean ? '취소' : 'Cancel',
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: Text(
            isKorean ? '신고' : 'Report',
            style: const TextStyle(color: AppColors.accent2, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
