import 'dart:convert';

class ChatMessage {
  final String? id;
  final String role;
  final String content;
  final List<String>? documentLinks;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.role,
    required this.content,
    this.documentLinks,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'content': content,
    'documentLinks': documentLinks,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String?,
    role: json['role'] as String,
    content: json['content'] as String,
    documentLinks:
        json['documentLinks'] != null
            ? List<String>.from(json['documentLinks'] as List)
            : null,
    timestamp:
        json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
  );

  static List<ChatMessage> listFromJson(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
  }

  static String listToJson(List<ChatMessage> messages) {
    return jsonEncode(messages.map((msg) => msg.toJson()).toList());
  }

  @override
  String toString() {
    return 'ChatMessage(role: $role, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.role == role &&
        other.content == content &&
        listEquals(other.documentLinks, documentLinks);
  }

  @override
  int get hashCode {
    return role.hashCode ^ content.hashCode ^ documentLinks.hashCode;
  }
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
