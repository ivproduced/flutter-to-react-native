import 'package:supabase_flutter/supabase_flutter.dart';
import '../ai_chat/models/chat_message.dart';
import '../ai_chat/models/chat_session.dart';
import 'auth_service.dart';

class DataSyncService {
  static const String _chatSessionsTable = 'chat_sessions';
  static const String _chatMessagesTable = 'chat_messages';
  static const String _userSettingsTable = 'user_settings';
  static const String _aiUsageTable = 'ai_usage';

  // Singleton pattern
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // Check if user can sync (authenticated and not in guest mode)
  Future<bool> canSync() async {
    return _authService.isAuthenticated && !(await _authService.isGuestMode());
  }

  // Upload chat session to cloud
  Future<SyncResult> uploadChatSession(ChatSession session) async {
    if (!await canSync()) {
      return SyncResult.error('User not authenticated for sync');
    }

    try {
      final userId = _authService.currentUser!.id;

      // Upload session metadata
      final sessionData = {
        'id': session.id,
        'user_id': userId,
        'name': session.name,
        'created_at': session.createdAt.toIso8601String(),
        'updated_at': session.updatedAt.toIso8601String(),
      };

      await _client.from(_chatSessionsTable).upsert(sessionData);

      // Upload messages
      final messagesData =
          session.messages
              .map(
                (message) => {
                  'id': message.id ?? _generateId(),
                  'session_id': session.id,
                  'user_id': userId,
                  'role': message.role,
                  'content': message.content,
                  'created_at': message.timestamp.toIso8601String(),
                },
              )
              .toList();

      if (messagesData.isNotEmpty) {
        await _client.from(_chatMessagesTable).upsert(messagesData);
      }

      return SyncResult.success('Session uploaded successfully');
    } catch (e) {
      return SyncResult.error('Failed to upload session: $e');
    }
  }

  // Download chat sessions from cloud
  Future<SyncResult<List<ChatSession>>> downloadChatSessions() async {
    if (!await canSync()) {
      return SyncResult.error('User not authenticated for sync');
    }

    try {
      final userId = _authService.currentUser!.id;

      // Get all sessions for user
      final sessionsResponse = await _client
          .from(_chatSessionsTable)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final sessions = <ChatSession>[];

      for (final sessionData in sessionsResponse) {
        // Get messages for this session
        final messagesResponse = await _client
            .from(_chatMessagesTable)
            .select()
            .eq('session_id', sessionData['id'])
            .order('created_at', ascending: true);

        final messages =
            messagesResponse.map((messageData) {
              return ChatMessage(
                id: messageData['id'],
                role: messageData['role'],
                content: messageData['content'],
                timestamp: DateTime.parse(messageData['created_at']),
              );
            }).toList();

        final session = ChatSession(
          id: sessionData['id'],
          name: sessionData['name'],
          messages: messages,
          createdAt: DateTime.parse(sessionData['created_at']),
          updatedAt: DateTime.parse(sessionData['updated_at']),
        );

        sessions.add(session);
      }

      return SyncResult.success('Sessions downloaded successfully', sessions);
    } catch (e) {
      return SyncResult.error('Failed to download sessions: $e');
    }
  }

  // Sync chat sessions (upload local, download remote, merge)
  Future<SyncResult<List<ChatSession>>> syncChatSessions(
    List<ChatSession> localSessions,
  ) async {
    if (!await canSync()) {
      return SyncResult.error('User not authenticated for sync');
    }

    try {
      // Upload all local sessions
      for (final session in localSessions) {
        await uploadChatSession(session);
      }

      // Download all remote sessions
      final downloadResult = await downloadChatSessions();
      if (!downloadResult.isSuccess) {
        return SyncResult.error(downloadResult.error!);
      }

      return SyncResult.success(
        'Sessions synced successfully',
        downloadResult.data!,
      );
    } catch (e) {
      return SyncResult.error('Failed to sync sessions: $e');
    }
  }

  // Track AI usage for rate limiting
  Future<SyncResult> trackAIUsage({
    required String endpoint,
    required int tokensUsed,
  }) async {
    if (!await canSync()) {
      return SyncResult.success('Usage tracking skipped (guest mode)');
    }

    try {
      final userId = _authService.currentUser!.id;

      final usageData = {
        'user_id': userId,
        'endpoint': endpoint,
        'tokens_used': tokensUsed,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client.from(_aiUsageTable).insert(usageData);

      return SyncResult.success('Usage tracked successfully');
    } catch (e) {
      return SyncResult.error('Failed to track usage: $e');
    }
  }

  // Get AI usage statistics
  Future<SyncResult<AIUsageStats>> getAIUsageStats() async {
    if (!await canSync()) {
      return SyncResult.error('User not authenticated');
    }

    try {
      final userId = _authService.currentUser!.id;
      final now = DateTime.now();
      final dayAgo = now.subtract(const Duration(days: 1));
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      // Get usage for different time periods
      final dailyUsage = await _getUsageForPeriod(userId, dayAgo);
      final weeklyUsage = await _getUsageForPeriod(userId, weekAgo);
      final monthlyUsage = await _getUsageForPeriod(userId, monthAgo);

      final stats = AIUsageStats(
        dailyTokens: dailyUsage,
        weeklyTokens: weeklyUsage,
        monthlyTokens: monthlyUsage,
      );

      return SyncResult.success('Usage stats retrieved', stats);
    } catch (e) {
      return SyncResult.error('Failed to get usage stats: $e');
    }
  }

  // Save user settings to cloud
  Future<SyncResult> saveUserSettings(Map<String, dynamic> settings) async {
    if (!await canSync()) {
      return SyncResult.success('Settings saved locally only');
    }

    try {
      final userId = _authService.currentUser!.id;

      final settingsData = {
        'user_id': userId,
        ...settings,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from(_userSettingsTable).upsert(settingsData);

      return SyncResult.success('Settings saved to cloud');
    } catch (e) {
      return SyncResult.error('Failed to save settings: $e');
    }
  }

  // Load user settings from cloud
  Future<SyncResult<Map<String, dynamic>>> loadUserSettings() async {
    if (!await canSync()) {
      return SyncResult.error('User not authenticated');
    }

    try {
      final userId = _authService.currentUser!.id;

      final response =
          await _client
              .from(_userSettingsTable)
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (response == null) {
        return SyncResult.success('No settings found', <String, dynamic>{});
      }

      return SyncResult.success('Settings loaded', response);
    } catch (e) {
      return SyncResult.error('Failed to load settings: $e');
    }
  }

  // Set up real-time subscriptions for live sync
  void setupRealtimeSync(Function(Map<String, dynamic>) onSessionUpdate) {
    if (!_authService.isAuthenticated) return;

    final userId = _authService.currentUser!.id;

    // Listen for chat session changes
    _client
        .from(_chatSessionsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
          for (final session in data) {
            onSessionUpdate(session);
          }
        });
  }

  // Helper methods
  Future<int> _getUsageForPeriod(String userId, DateTime since) async {
    final response = await _client
        .from(_aiUsageTable)
        .select('tokens_used')
        .eq('user_id', userId)
        .gte('created_at', since.toIso8601String());

    return response.fold<int>(
      0,
      (sum, record) => sum + (record['tokens_used'] as int),
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

// Result class for sync operations
class SyncResult<T> {
  final bool isSuccess;
  final String? error;
  final String? message;
  final T? data;

  SyncResult.success(this.message, [this.data])
    : isSuccess = true,
      error = null;

  SyncResult.error(this.error) : isSuccess = false, message = null, data = null;
}

// AI Usage Statistics
class AIUsageStats {
  final int dailyTokens;
  final int weeklyTokens;
  final int monthlyTokens;

  AIUsageStats({
    required this.dailyTokens,
    required this.weeklyTokens,
    required this.monthlyTokens,
  });

  // Rate limiting checks
  bool isDailyLimitExceeded({int limit = 10000}) => dailyTokens > limit;
  bool isWeeklyLimitExceeded({int limit = 50000}) => weeklyTokens > limit;
  bool isMonthlyLimitExceeded({int limit = 200000}) => monthlyTokens > limit;

  double get dailyUsagePercentage => (dailyTokens / 10000) * 100;
  double get weeklyUsagePercentage => (weeklyTokens / 50000) * 100;
  double get monthlyUsagePercentage => (monthlyTokens / 200000) * 100;
}
