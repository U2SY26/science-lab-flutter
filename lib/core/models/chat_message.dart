import 'dart:convert';

/// AI 채팅 메시지 모델
class ChatMessage {
  final String role;       // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.user(String content) => ChatMessage(
    role: 'user',
    content: content,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.assistant(String content) => ChatMessage(
    role: 'assistant',
    content: content,
    timestamp: DateTime.now(),
  );

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: json['role'] as String,
    content: json['content'] as String,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
  );

  /// OpenAI API 형식으로 변환
  Map<String, String> toApiMessage() => {
    'role': role,
    'content': content,
  };

  /// 리스트 JSON 직렬화
  static String encodeList(List<ChatMessage> messages) {
    return jsonEncode(messages.map((m) => m.toJson()).toList());
  }

  /// 리스트 JSON 역직렬화
  static List<ChatMessage> decodeList(String json) {
    final list = jsonDecode(json) as List;
    return list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }
}
