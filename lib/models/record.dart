import 'dart:convert';

class AiRecord {
  const AiRecord(
      {required this.id,
      required this.mode,
      required this.input,
      required this.output,
      required this.createdAt,
      required this.subtitle});
  final String id;
  final String mode;
  final String input;
  final String output;
  final DateTime createdAt;
  final String subtitle;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode,
        'input': input,
        'output': output,
        'createdAt': createdAt.toIso8601String(),
        'subtitle': subtitle,
      };
  factory AiRecord.fromJson(Map<String, dynamic> data) => AiRecord(
        id: data['id'] as String? ?? '',
        mode: data['mode'] as String? ?? 'translation',
        input: data['input'] as String? ?? '',
        output: data['output'] as String? ?? '',
        createdAt: DateTime.tryParse(data['createdAt'] as String? ?? '') ??
            DateTime.now(),
        subtitle: data['subtitle'] as String? ?? '',
      );
  static String encode(List<AiRecord> records) =>
      jsonEncode(records.map((e) => e.toJson()).toList());
  static List<AiRecord> decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => AiRecord.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class LocalChatMessage {
  const LocalChatMessage({required this.role, required this.content});
  final String role;
  final String content;
  Map<String, String> toJson() => {'role': role, 'content': content};
  factory LocalChatMessage.fromJson(Map<String, dynamic> json) =>
      LocalChatMessage(
        role: json['role'] as String? ?? 'user',
        content: json['content'] as String? ?? '',
      );
}

class ChatConversation {
  ChatConversation(
      {required this.id,
      required this.title,
      required this.updatedAt,
      List<LocalChatMessage>? messages})
      : messages = messages ?? [];
  final String id;
  String title;
  DateTime updatedAt;
  final List<LocalChatMessage> messages;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'New chat',
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        messages: (json['messages'] as List)
            .map((m) =>
                LocalChatMessage.fromJson(Map<String, dynamic>.from(m as Map)))
            .toList(),
      );
}
