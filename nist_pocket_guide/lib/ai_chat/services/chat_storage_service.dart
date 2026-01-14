import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatStorageService {
  static const String _messagesKey = 'chat_messages';
  static const String _chatSessionsKey = 'chat_sessions';
  static const String _currentSessionIdKey = 'current_session_id';

  // Save current chat messages (legacy support)
  static Future<void> saveMessageHistory(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = ChatMessage.listToJson(messages);
      await prefs.setString(_messagesKey, jsonString);
    } catch (e) {
      // Error saving messages - silent fail for now
    }
  }

  static Future<List<ChatMessage>> restoreMessageHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_messagesKey);
    if (jsonString != null) {
      try {
        return ChatMessage.listFromJson(jsonString);
      } catch (e) {
        // Error restoring messages - return defaults
      }
    }
    return _getDefaultMessageHistory();
  }

  // Chat Sessions
  static Future<void> saveChatSessions(List<ChatSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = ChatSession.listToJson(sessions);
      await prefs.setString(_chatSessionsKey, jsonString);
    } catch (e) {
      // Error saving chat sessions - silent fail
    }
  }

  static Future<List<ChatSession>> restoreChatSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_chatSessionsKey);
    if (jsonString != null) {
      try {
        return ChatSession.listFromJson(jsonString);
      } catch (e) {
        // Error restoring chat sessions - return empty list
      }
    }
    return [];
  }

  static Future<void> setCurrentSessionId(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSessionIdKey, sessionId);
  }

  static Future<String?> getCurrentSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentSessionIdKey);
  }

  static Future<void> deleteSession(String sessionId) async {
    final sessions = await restoreChatSessions();
    sessions.removeWhere((session) => session.id == sessionId);
    await saveChatSessions(sessions);
  }

  static Future<void> updateSessionName(
    String sessionId,
    String newName,
  ) async {
    final sessions = await restoreChatSessions();
    final sessionIndex = sessions.indexWhere(
      (session) => session.id == sessionId,
    );
    if (sessionIndex != -1) {
      sessions[sessionIndex].name = newName;
      await saveChatSessions(sessions);
    }
  }

  static Future<ChatSession?> getSession(String sessionId) async {
    final sessions = await restoreChatSessions();
    try {
      return sessions.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveSession(ChatSession session) async {
    final sessions = await restoreChatSessions();
    final existingIndex = sessions.indexWhere((s) => s.id == session.id);

    if (existingIndex != -1) {
      sessions[existingIndex] = session;
    } else {
      sessions.add(session);
    }

    await saveChatSessions(sessions);
  }

  // Helper method to migrate legacy data
  static Future<void> migrateLegacyData() async {
    try {
      final legacyMessages = await restoreMessageHistory();
      final sessions = await restoreChatSessions();

      // If we have legacy messages but no sessions, create a session from them
      if (legacyMessages.isNotEmpty && sessions.isEmpty) {
        final legacySession = ChatSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Previous Chat',
          messages: legacyMessages,
        );
        await saveSession(legacySession);
        await setCurrentSessionId(legacySession.id);
      }
    } catch (e) {
      // Error during legacy migration - clear corrupted data
      // Clear any corrupted data
      await _clearCorruptedData();
    }
  }

  static Future<void> _clearCorruptedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_session_id');
      await prefs.remove('chat_sessions');
      await prefs.remove('messageHistory');
    } catch (e) {
      // Error clearing corrupted data - silent fail
    }
  }

  static Future<void> clearAll() async {
    // Public method to clear all chat data
    await _clearCorruptedData();
  }

  static List<ChatMessage> _getDefaultMessageHistory() {
    return [
      ChatMessage(
        role: "system",
        content:
            "You are a cybersecurity compliance assistant for NIST. Answer questions about NIST controls, RMF, and related topics.",
      ),
      ChatMessage(
        role: "assistant",
        content:
            "Hello! I'm NISTBot, your cybersecurity compliance assistant. Ask me anything about NIST controls, RMF, or related topics, and I'll do my best to help.",
      ),
    ];
  }
}
