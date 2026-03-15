/**
 * Cloud Functions for Science Lab Community Moderation
 *
 * 핵심 기능:
 * 1. onCommentReported — 댓글 신고 시 작성자 reportCount 증가 + 블랙리스트 체크
 * 2. onForumPostReported — 포럼 글 신고 시 동일 로직
 *
 * 보안 원칙:
 * - blacklist 컬렉션은 Cloud Functions에서만 write 가능
 * - users.reportCount, users.isBlacklisted는 Cloud Functions에서만 변경
 * - 클라이언트는 comments/forum_posts의 reportedBy 배열에 자기 ID만 추가 가능
 */

import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";

initializeApp();

const db = getFirestore();
const BLACKLIST_THRESHOLD = 5;

/**
 * 댓글 신고 처리
 * 트리거: comments/{commentId} 업데이트
 * 조건: reportedBy 배열 크기 증가 감지
 */
export const onCommentReported = onDocumentUpdated(
  "comments/{commentId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const oldReportCount = (before.reportedBy as string[] || []).length;
    const newReportCount = (after.reportedBy as string[] || []).length;

    // 신고가 새로 추가된 경우만 처리
    if (newReportCount <= oldReportCount) return;

    const authorId = after.authorId as string;
    if (!authorId) return;

    await processReport(authorId, event.data?.after.ref.path ?? "");
  }
);

/**
 * 포럼 글 신고 처리
 * 트리거: forum_posts/{postId} 업데이트
 * 조건: reportedBy 배열 크기 증가 감지
 */
export const onForumPostReported = onDocumentUpdated(
  "forum_posts/{postId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const oldReportCount = (before.reportedBy as string[] || []).length;
    const newReportCount = (after.reportedBy as string[] || []).length;

    if (newReportCount <= oldReportCount) return;

    const authorId = after.authorId as string;
    if (!authorId) return;

    await processReport(authorId, event.data?.after.ref.path ?? "");
  }
);

/**
 * 공통 신고 처리 로직
 * 1. 작성자의 users 문서에서 reportCount 증가
 * 2. reportCount >= 5이면 blacklist 컬렉션에 문서 생성
 * 3. users 문서의 isBlacklisted 플래그 설정
 */
async function processReport(
  authorId: string,
  contentPath: string
): Promise<void> {
  const userRef = db.collection("users").doc(authorId);

  try {
    const result = await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        console.warn(`User ${authorId} not found for report processing`);
        return {blacklisted: false, reportCount: 0};
      }

      const userData = userSnap.data()!;
      const currentReportCount = (userData.reportCount as number) || 0;
      const newReportCount = currentReportCount + 1;
      const shouldBlacklist = newReportCount >= BLACKLIST_THRESHOLD;

      // 유저 reportCount 증가
      tx.update(userRef, {
        reportCount: newReportCount,
        isBlacklisted: shouldBlacklist,
        updatedAt: FieldValue.serverTimestamp(),
      });

      // 블랙리스트 임계치 도달
      if (shouldBlacklist) {
        const blacklistRef = db.collection("blacklist").doc(authorId);
        tx.set(blacklistRef, {
          reason: "Cumulative reports exceeded threshold",
          totalReports: newReportCount,
          lastReportedContent: contentPath,
          createdAt: FieldValue.serverTimestamp(),
        }, {merge: true});

        // 해당 유저의 모든 콘텐츠 숨김 처리는 별도 함수에서 (비동기)
      }

      return {blacklisted: shouldBlacklist, reportCount: newReportCount};
    });

    console.log(
      `Report processed for user ${authorId}: ` +
      `reportCount=${result.reportCount}, blacklisted=${result.blacklisted}, ` +
      `content=${contentPath}`
    );

    // 블랙리스트된 유저의 모든 콘텐츠 숨김 처리 (트랜잭션 외부)
    if (result.blacklisted) {
      await hideAllContentByUser(authorId);
    }
  } catch (error) {
    console.error(`Failed to process report for user ${authorId}:`, error);
  }
}

/**
 * 블랙리스트된 유저의 모든 콘텐츠를 isHidden=true로 설정
 * 배치 write로 효율적으로 처리
 */
async function hideAllContentByUser(authorId: string): Promise<void> {
  const batch = db.batch();
  let count = 0;

  // 댓글 숨김
  const comments = await db
    .collection("comments")
    .where("authorId", "==", authorId)
    .where("isHidden", "==", false)
    .get();

  for (const doc of comments.docs) {
    batch.update(doc.ref, {isHidden: true});
    count++;
  }

  // 포럼 글 숨김
  const posts = await db
    .collection("forum_posts")
    .where("authorId", "==", authorId)
    .where("isHidden", "==", false)
    .get();

  for (const doc of posts.docs) {
    batch.update(doc.ref, {isHidden: true});
    count++;
  }

  if (count > 0) {
    await batch.commit();
    console.log(
      `Hidden ${count} content items from blacklisted user ${authorId}`
    );
  }
}
