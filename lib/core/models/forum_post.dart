import 'package:cloud_firestore/cloud_firestore.dart';

/// 포럼 글 모델
class ForumPost {
  final String id;
  final String authorId;
  final String authorNickname;
  final int authorLevel;
  final String title;
  final String content;
  final String category;
  final String languageCode;
  final int commentCount;
  final Map<String, int> reactions;
  final Map<String, List<String>> reactedBy;
  final List<String> reportedBy;
  final int reportCount;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ForumPost({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    required this.authorLevel,
    required this.title,
    required this.content,
    this.category = 'general',
    this.languageCode = 'en',
    this.commentCount = 0,
    this.reactions = const {},
    this.reactedBy = const {},
    this.reportedBy = const [],
    this.reportCount = 0,
    this.isHidden = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'authorId': authorId,
    'authorNickname': authorNickname,
    'authorLevel': authorLevel,
    'title': title,
    'content': content,
    'category': category,
    'languageCode': languageCode,
    'commentCount': commentCount,
    'reactions': reactions,
    'reactedBy': reactedBy.map((k, v) => MapEntry(k, v)),
    'reportedBy': reportedBy,
    'reportCount': reportCount,
    'isHidden': isHidden,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory ForumPost.fromDoc(DocumentSnapshot doc) {
    final raw = doc.data();
    if (raw == null) {
      return ForumPost(
        id: doc.id,
        authorId: '',
        authorNickname: '',
        authorLevel: 1,
        title: '',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    final map = raw as Map<String, dynamic>;
    return ForumPost(
      id: doc.id,
      authorId: map['authorId'] as String? ?? '',
      authorNickname: map['authorNickname'] as String? ?? '',
      authorLevel: map['authorLevel'] as int? ?? 1,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      category: map['category'] as String? ?? 'general',
      languageCode: map['languageCode'] as String? ?? 'en',
      commentCount: map['commentCount'] as int? ?? 0,
      reactions: Map<String, int>.from(map['reactions'] as Map? ?? {'heart': 0, 'thumbsUp': 0, 'fire': 0, 'brain': 0}),
      reactedBy: (map['reactedBy'] as Map?)?.map(
        (k, v) => MapEntry(k as String, List<String>.from(v as List? ?? [])),
      ) ?? {'heart': [], 'thumbsUp': [], 'fire': [], 'brain': []},
      reportedBy: List<String>.from(map['reportedBy'] as List? ?? []),
      reportCount: map['reportCount'] as int? ?? 0,
      isHidden: map['isHidden'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// 포럼 카테고리
enum ForumCategory {
  general,
  question,
  tip,
  bug;

  String label(bool isKorean) {
    switch (this) {
      case ForumCategory.general: return isKorean ? '자유 게시판' : 'General';
      case ForumCategory.question: return isKorean ? '질문 & 답변' : 'Q&A';
      case ForumCategory.tip: return isKorean ? '팁 & 노하우' : 'Tips & Tricks';
      case ForumCategory.bug: return isKorean ? '버그 신고' : 'Bug Reports';
    }
  }

  String get icon {
    switch (this) {
      case ForumCategory.general: return '💬';
      case ForumCategory.question: return '❓';
      case ForumCategory.tip: return '💡';
      case ForumCategory.bug: return '🐛';
    }
  }
}
