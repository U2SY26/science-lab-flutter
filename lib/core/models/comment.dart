import 'package:cloud_firestore/cloud_firestore.dart';

/// 댓글 모델 (시뮬레이션 댓글 + 포럼 댓글 공용)
class Comment {
  final String id;
  final String simId;
  final String authorId;
  final String authorNickname;
  final int authorLevel;
  final String content;
  final String? parentId;
  final String languageCode;
  final Map<String, int> reactions;
  final Map<String, List<String>> reactedBy;
  final List<String> reportedBy;
  final int reportCount;
  final bool isHidden;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Comment({
    required this.id,
    required this.simId,
    required this.authorId,
    required this.authorNickname,
    required this.authorLevel,
    required this.content,
    this.parentId,
    this.languageCode = 'en',
    this.reactions = const {},
    this.reactedBy = const {},
    this.reportedBy = const [],
    this.reportCount = 0,
    this.isHidden = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isReply => parentId != null;

  Map<String, dynamic> toMap() => {
    'simId': simId,
    'authorId': authorId,
    'authorNickname': authorNickname,
    'authorLevel': authorLevel,
    'content': content,
    'parentId': parentId,
    'languageCode': languageCode,
    'reactions': reactions,
    'reactedBy': reactedBy.map((k, v) => MapEntry(k, v)),
    'reportedBy': reportedBy,
    'reportCount': reportCount,
    'isHidden': isHidden,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory Comment.fromDoc(DocumentSnapshot doc) {
    final raw = doc.data();
    if (raw == null) {
      return Comment(
        id: doc.id,
        simId: '',
        authorId: '',
        authorNickname: '',
        authorLevel: 1,
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    final map = raw as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      simId: map['simId'] as String? ?? '',
      authorId: map['authorId'] as String? ?? '',
      authorNickname: map['authorNickname'] as String? ?? '',
      authorLevel: map['authorLevel'] as int? ?? 1,
      content: map['content'] as String? ?? '',
      parentId: map['parentId'] as String?,
      languageCode: map['languageCode'] as String? ?? 'en',
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

/// 리액션 타입
enum ReactionType {
  heart,
  thumbsUp,
  fire,
  brain;

  String get emoji {
    switch (this) {
      case ReactionType.heart: return '❤️';
      case ReactionType.thumbsUp: return '👍';
      case ReactionType.fire: return '🔥';
      case ReactionType.brain: return '🧠';
    }
  }
}
