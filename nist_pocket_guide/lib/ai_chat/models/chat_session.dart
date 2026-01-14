import 'dart:convert';
import 'chat_message.dart';

class ChatSession {
  final String id;
  String name;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.name,
    required this.messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'messages': messages.map((msg) => msg.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String,
    name: json['name'] as String,
    messages:
        (json['messages'] as List)
            .map((msgJson) => ChatMessage.fromJson(msgJson))
            .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  static List<ChatSession> listFromJson(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => ChatSession.fromJson(json)).toList();
  }

  static String listToJson(List<ChatSession> sessions) {
    return jsonEncode(sessions.map((session) => session.toJson()).toList());
  }

  // Helper method to get the first user message for preview
  String get previewMessage {
    for (final message in messages) {
      if (message.role == 'user' && message.content.isNotEmpty) {
        return message.content;
      }
    }
    return 'New conversation';
  }

  // Helper method to get the last message timestamp
  DateTime? get lastMessageTime {
    if (messages.isEmpty) return updatedAt;

    // Return the timestamp of the last message
    return messages.last.timestamp;
  }

  // Update the session's updated time
  void touch() {
    updatedAt = DateTime.now();
  }

  @override
  String toString() {
    return 'ChatSession(id: $id, name: $name, messages: ${messages.length})';
  }
}
