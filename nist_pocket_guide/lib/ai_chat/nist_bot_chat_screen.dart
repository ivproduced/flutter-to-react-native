// lib/ai_chat/nist_bot_chat_screen.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

import 'models/chat_message.dart';
import 'models/chat_session.dart';
import 'screens/chat_warning_screen.dart';
import 'screens/chat_history_screen.dart';
import 'services/chat_service.dart';
import 'services/chat_storage_service.dart';
import 'constants/nist_documents.dart';
import 'tima_integration/services/tima_dialog_client.dart';

class NistBotChatScreen extends StatefulWidget {
  const NistBotChatScreen({super.key});

  @override
  State<NistBotChatScreen> createState() => _NistBotChatScreenState();
}

class _NistBotChatScreenState extends State<NistBotChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Static regex patterns for better performance
  static final RegExp _docPattern = RegExp(r'\[doc(\d+)\]');
  static final RegExp _docRemovalPattern = RegExp(r'\[doc\d+\]');

  List<ChatMessage> messageHistory = [
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

  String? _currentSessionId;
  ChatSession? _currentSession;
  bool _isStreaming = false;
  bool _isLoading = false;
  bool _showWarning = false;
  String _streamedText = '';
  String _loadingPhrase = '';
  List<String> _streamedResolvedTitles = [];

  // TIMA integration state
  bool _timaEnabled = false;
  bool _timaHealthy = false;
  TIMADialogClient? _timaClient;
  DateTime? _lastTimaRetry; // Add retry debouncing
  Timer? _streamingTimer; // Track the streaming timer for proper cleanup

  @override
  void initState() {
    super.initState();
    _showWarning = true;
    // Add a small delay to ensure widget is fully mounted before initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOrRestoreSession();
      _initializeTIMAService();
    });
  }

  Future<void> _initializeTIMAService() async {
    // Debounce retry attempts (prevent rapid retries)
    final now = DateTime.now();
    if (_lastTimaRetry != null &&
        now.difference(_lastTimaRetry!).inSeconds < 5) {
      return; // Skip if retried within last 5 seconds
    }
    _lastTimaRetry = now;

    try {
      _timaClient = TIMADialogClient(
        config: const TIMAClientConfig(
          baseUrl: 'http://localhost:8001', // TIMA Core Service as primary
          apiKey:
              'cc8139bf7b0be11a5264b8c8d84732529aac88dbb92a42a814783fb642313a06',
          timeout: Duration(seconds: 60),
          enableLogging: true,
        ),
      );
      final isHealthy = await _timaClient!.checkHealth();
      if (mounted) {
        setState(() {
          _timaEnabled = true;
          _timaHealthy = isHealthy;
        });
      }

      if (isHealthy && kDebugMode) {
        debugPrint('TIMA Core Service initialized successfully');
      } else if (kDebugMode) {
        debugPrint(
          'TIMA Core Service is not healthy - falling back to basic chat',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _timaEnabled = false;
          _timaHealthy = false;
        });
      }
      if (kDebugMode) {
        print('Failed to initialize TIMA Core Service: $e');
        print('Check if TIMA Core Service is running and accessible');
      }
    }
  }

  @override
  void dispose() {
    _streamingTimer?.cancel(); // Cancel any active streaming timer
    _controller.dispose();
    _scrollController.dispose();
    _timaClient?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showWarning) {
      return ChatWarningScreen(
        onAccept: () => setState(() => _showWarning = false),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _timaEnabled && _timaHealthy ? 'NISTBot - Enhanced' : 'NISTBot',
        ),
        backgroundColor:
            _timaEnabled && _timaHealthy ? Colors.green.shade100 : null,
        foregroundColor:
            _timaEnabled && _timaHealthy ? Colors.green.shade800 : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeTIMAService,
            tooltip: 'Refresh RAG Connection',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (value) {
              switch (value) {
                case 'new_chat':
                  _startNewChat();
                  break;
                case 'chat_history':
                  _openChatHistory();
                  break;
                case 'delete_chat':
                  _deleteCurrentChat();
                  break;
                case 'export_chat':
                  _exportCurrentChat();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'new_chat',
                    child: ListTile(
                      leading: Icon(Icons.add),
                      title: Text('New Chat'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'chat_history',
                    child: ListTile(
                      leading: Icon(Icons.history),
                      title: Text('Chat History'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_chat',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
                        'Delete Chat',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_chat',
                    child: ListTile(
                      leading: Icon(Icons.share),
                      title: Text('Export Chat'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusIndicator(),
            if (_currentSession != null && _currentSession!.name != 'New Chat')
              Container(
                color: Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentSession!.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: _buildChatArea()),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: messageHistory.length,
      // Add cache extent to improve scrolling performance
      cacheExtent: 500.0,
      itemBuilder: (context, index) {
        final message = messageHistory[index];

        // Skip system messages
        if (message.role == 'system') {
          return const SizedBox.shrink();
        }

        final isUser = message.role == 'user';
        final isLastMessage = index == messageHistory.length - 1;
        final isStreaming = _isStreaming && isLastMessage && !isUser;

        return EnhancedMessageBubble(
          key: ValueKey(
            'message_${message.timestamp.millisecondsSinceEpoch}',
          ), // Add key for better performance
          message: message,
          isStreaming: isStreaming,
          streamedText: isStreaming ? _streamedText : message.content,
          streamedResolvedTitles: isStreaming ? _streamedResolvedTitles : null,
          onRegenerate:
              isLastMessage && !isUser ? _regenerateLastResponse : null,
          onStreamComplete: () {
            if (mounted && messageHistory.isNotEmpty) {
              setState(() {
                _isStreaming = false;
                _streamedText = '';
                _streamedResolvedTitles = [];
              });
              _saveMessageHistory();
            }
          },
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          if (_isLoading || _isStreaming)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isStreaming
                          ? (_timaEnabled && _timaHealthy
                              ? 'Analyzing with NIST intelligence...'
                              : 'NISTBot is typing...')
                          : _loadingPhrase,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText:
                        _timaEnabled && _timaHealthy
                            ? 'Ask about NIST controls, compliance, or security...'
                            : 'Ask about NIST controls, RMF, or security practices...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isLoading && !_isStreaming,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _isLoading || _isStreaming ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading || _isStreaming) return;

    setState(() {
      messageHistory.add(ChatMessage(role: 'user', content: text));
      _controller.clear();
      _isLoading = true;
      _loadingPhrase = ChatService.getRandomLoadingPhrase();
    });

    _scrollToBottom();

    try {
      String response;

      // Try TIMA service first if available and healthy
      if (_timaEnabled && _timaHealthy && _timaClient != null) {
        try {
          final timaResponse = await _timaClient!.askQuestion(
            text,
            context: 'NISTBot - Cybersecurity guidance request',
          );
          response = timaResponse.reply;
        } catch (timaError) {
          if (kDebugMode) {
            print('TIMA service error, falling back to basic chat: $timaError');
          }
          // Update TIMA health status and fallback to basic chat
          if (mounted) {
            setState(() {
              _timaHealthy = false;
            });
          }
          response = await ChatService.sendMessage(messageHistory);
        }
      } else {
        // Use basic chat service
        response = await ChatService.sendMessage(messageHistory);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isStreaming = true;
          _streamedText = '';
          _streamedResolvedTitles = _resolveDocumentTitles(response);
          // Add empty assistant message - streamedText will be used for display
          messageHistory.add(ChatMessage(role: 'assistant', content: ''));
        });

        _startStreamingText(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isStreaming = false;
          messageHistory.add(
            ChatMessage(
              role: 'assistant',
              content:
                  'Sorry, I encountered an error: ${e.toString()}\n\nPlease make sure:\n• Ollama server is running\n• Network connection is available\n• Server endpoint is correct: ${ChatService.getApiUrl()}',
            ),
          );
        });
      }
    }

    _saveMessageHistory();
    _scrollToBottom();
  }

  void _startStreamingText(String fullText) {
    // Cancel any existing timer first
    _streamingTimer?.cancel();

    const streamDelay = Duration(
      milliseconds: 40, // Balanced speed for natural typing feel
    );
    int charIndex = 0;

    _streamingTimer = Timer.periodic(streamDelay, (timer) {
      if (!mounted || charIndex >= fullText.length) {
        timer.cancel();
        _streamingTimer = null; // Clear the reference
        if (mounted && messageHistory.isNotEmpty) {
          setState(() {
            _isStreaming = false;
            messageHistory[messageHistory.length - 1] = ChatMessage(
              role: 'assistant',
              content: fullText,
              documentLinks: _getDocumentLinksFromText(fullText),
            );
          });
          _saveMessageHistory();
        }
        return;
      }

      // Balanced character streaming - 1-2 characters based on text length
      final charsToAdd = fullText.length > 1000 ? 2 : 1;
      final endIndex = (charIndex + charsToAdd).clamp(0, fullText.length);
      final currentText = fullText.substring(0, endIndex);

      if (mounted) {
        setState(() {
          _streamedText = currentText;
        });
      }

      charIndex = endIndex;

      // Scroll every few updates for smooth following
      if (charIndex % 8 == 0) {
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        // Use jumpTo for better performance during rapid updates
        final isStreaming = _isStreaming;
        if (isStreaming) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          // Use smooth animation only for non-streaming updates
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });
  }

  void _regenerateLastResponse() {
    if (messageHistory.length < 2) return;

    // Remove the last assistant message and regenerate
    messageHistory.removeLast();
    _sendMessage();
  }

  Future<void> _initializeOrRestoreSession() async {
    // Always ensure UI is in a clean state
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isStreaming = false;
        _streamedText = '';
      });
    }

    try {
      // Migrate legacy data if needed
      await ChatStorageService.migrateLegacyData();

      // Get current session ID
      _currentSessionId = await ChatStorageService.getCurrentSessionId();

      if (_currentSessionId != null) {
        _currentSession = await ChatStorageService.getSession(
          _currentSessionId!,
        );

        // Validate session data before using it
        if (_currentSession != null &&
            _currentSession!.messages.isNotEmpty &&
            _currentSession!.messages.length >= 2) {
          if (mounted) {
            setState(() {
              messageHistory = List<ChatMessage>.from(
                _currentSession!.messages,
              );
              _isLoading = false;
              _isStreaming = false;
              _streamedText = '';
            });
          }
          return;
        }
      }

      // No valid current session, create new one
      await _createNewSession();
    } catch (e) {
      // If anything goes wrong with session loading, create a new session
      // Error initializing session: fallback to new session
      await _createNewSession();
    }
  }

  Future<void> _createNewSession() async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final defaultMessages = [
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

    try {
      _currentSession = ChatSession(
        id: sessionId,
        name: 'New Chat',
        messages: List<ChatMessage>.from(
          defaultMessages,
        ), // Create a copy to avoid reference issues
      );

      if (mounted) {
        setState(() {
          _currentSessionId = sessionId;
          messageHistory = List<ChatMessage>.from(
            defaultMessages,
          ); // Create a copy
          _isLoading = false;
          _isStreaming = false;
          _streamedText = '';
        });
      }

      await ChatStorageService.saveSession(_currentSession!);
      await ChatStorageService.setCurrentSessionId(sessionId);
    } catch (e) {
      // Error creating new session: fallback to working state
      // Fallback: at least set the UI to a working state
      if (mounted) {
        setState(() {
          messageHistory = List<ChatMessage>.from(defaultMessages);
          _isLoading = false;
          _isStreaming = false;
          _streamedText = '';
        });
      }
    }
  }

  void _startNewChat() async {
    // Save current session if it has content
    if (_currentSession != null && messageHistory.length > 2) {
      await _saveCurrentSession();
    }

    await _createNewSession();
  }

  void _openChatHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatHistoryScreen(
              onLoadChatHistory: (messages) {
                if (mounted) {
                  setState(() {
                    messageHistory = messages;
                    _isLoading = false;
                    _isStreaming = false;
                    _streamedText = '';
                  });
                }
                // Session system handles storage automatically
              },
              currentSessionId: _currentSessionId,
            ),
      ),
    );
  }

  Future<void> _saveCurrentSession() async {
    if (_currentSession != null) {
      _currentSession!.messages.clear();
      _currentSession!.messages.addAll(messageHistory);
      _currentSession!.touch();

      // Auto-name session based on first user message if still "New Chat"
      if (_currentSession!.name == 'New Chat' && messageHistory.length > 2) {
        for (final message in messageHistory) {
          if (message.role == 'user') {
            final name =
                message.content.length > 30
                    ? '${message.content.substring(0, 30)}...'
                    : message.content;
            _currentSession!.name = name;
            break;
          }
        }
      }

      await ChatStorageService.saveSession(_currentSession!);
    }
  }

  List<String> _getDocumentLinksFromText(String text) {
    final matches = _docPattern.allMatches(text);
    return matches.map((match) => 'doc${match.group(1)}').toList();
  }

  List<String> _resolveDocumentTitles(String text) {
    final docLinks = _getDocumentLinksFromText(text);
    return docLinks.map((docLink) {
      // Extract document key from docLink (e.g., "doc1" -> need to map to actual document)
      // This is a simplified version - you might need more sophisticated mapping
      for (final entry in nistDocTitles.entries) {
        if (text.contains(entry.key)) {
          return entry.value;
        }
      }
      return 'NIST Document'; // Fallback
    }).toList();
  }

  // Storage methods
  Future<void> _saveMessageHistory() async {
    // Legacy method - now only calls session save to avoid conflicts
    await _saveCurrentSession();
  }

  void _deleteCurrentChat() async {
    if (messageHistory.length <= 2) {
      // Only system and assistant greeting, just clear
      _startNewChat();
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Current Chat'),
            content: Text(
              'Are you sure you want to delete "${_currentSession?.name ?? 'this chat'}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      if (_currentSession != null) {
        await ChatStorageService.deleteSession(_currentSession!.id);
      }
      _startNewChat();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _exportCurrentChat() async {
    if (messageHistory.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No messages to export'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final chatContent = StringBuffer();
      chatContent.writeln(
        'NISTBot Chat Export: ${_currentSession?.name ?? 'Untitled'}',
      );
      chatContent.writeln(
        'Generated: ${DateFormat('MMM d, yyyy HH:mm').format(DateTime.now())}',
      );
      chatContent.writeln('=' * 50);
      chatContent.writeln();

      for (final message in messageHistory) {
        if (message.role == 'system') continue;

        final sender = message.role == 'user' ? 'You' : 'NISTBot';
        final timestamp = message.timestamp.toString();
        chatContent.writeln('[$sender] ($timestamp)');
        chatContent.writeln(
          message.content.replaceAll(_docRemovalPattern, '').trim(),
        );
        chatContent.writeln();
      }

      await Clipboard.setData(ClipboardData(text: chatContent.toString()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat exported to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting chat: $e'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildStatusIndicator() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_timaEnabled && _timaHealthy) {
      statusText = 'NIST RAG Intelligence Active';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (_timaEnabled && !_timaHealthy) {
      statusText = 'RAG Service Offline - Using Basic Chat Mode';
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else {
      statusText = 'Using Basic Chat Mode';
      statusColor = Colors.blue;
      statusIcon = Icons.chat;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!_timaHealthy)
            TextButton(
              onPressed: _initializeTIMAService,
              child: Text(
                'Retry',
                style: TextStyle(fontSize: 12, color: statusColor),
              ),
            ),
        ],
      ),
    );
  }
}

// Enhanced Message Bubble Widget
class EnhancedMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;
  final String? streamedText;
  final List<String>? streamedResolvedTitles;
  final Function()? onRegenerate;
  final Function()? onStreamComplete;

  const EnhancedMessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.streamedText,
    this.streamedResolvedTitles,
    this.onRegenerate,
    this.onStreamComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isAssistant = message.role == 'assistant';

    if (!isUser && !isAssistant) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildAvatar(isUser), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildMessageBubble(context, isUser),
                const SizedBox(height: 2),
                _buildMessageFooter(context, isUser),
              ],
            ),
          ),
          if (isUser) ...[const SizedBox(width: 8), _buildAvatar(isUser)],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return CircleAvatar(
      backgroundColor: isUser ? Colors.blue.shade400 : Colors.grey.shade600,
      radius: 20,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, bool isUser) {
    final content =
        isStreaming ? (streamedText ?? message.content) : message.content;
    final resolvedTitles =
        isStreaming ? (streamedResolvedTitles ?? []) : _getResolvedTitles();

    return GestureDetector(
      onLongPress: () => _showMessageActions(context, isUser),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade400 : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isStreaming && !isUser)
              Text(
                (streamedText ?? '')
                    .replaceAll(_NistBotChatScreenState._docRemovalPattern, '')
                    .trim(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.normal,
                ),
              )
            else
              MarkdownBody(
                data:
                    content
                        .replaceAll(
                          _NistBotChatScreenState._docRemovalPattern,
                          '',
                        )
                        .trim(),
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 16,
                    color: isUser ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),

            if (resolvedTitles.isNotEmpty && !isUser) ...[
              const SizedBox(height: 8),
              _buildReferences(resolvedTitles),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReferences(List<String> resolvedTitles) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, size: 16, color: Colors.blue.shade600),
              const SizedBox(width: 4),
              Text(
                'References:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final docName in resolvedTitles)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 2),
              child: Text(
                '• $docName',
                style: TextStyle(fontSize: 13, color: Colors.blue.shade600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context, bool isUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTimestamp(message.timestamp),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        if (!isUser && !isStreaming) ...[
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.copy,
            tooltip: 'Copy',
            onTap: () => _copyMessage(context),
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.refresh,
            tooltip: 'Regenerate',
            onTap: onRegenerate,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: Colors.grey.shade600),
      ),
    );
  }

  void _showMessageActions(BuildContext context, bool isUser) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _copyMessage(context);
                  },
                ),
                if (!isUser) ...[
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text('Regenerate Response'),
                    onTap: () {
                      Navigator.pop(context);
                      onRegenerate?.call();
                    },
                  ),
                ],
              ],
            ),
          ),
    );
  }

  void _copyMessage(BuildContext context) {
    final content =
        message.content
            .replaceAll(_NistBotChatScreenState._docRemovalPattern, '')
            .trim();
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  List<String> _getResolvedTitles() {
    if (message.documentLinks == null) return [];
    return message.documentLinks!.map((docLink) {
      for (final entry in nistDocTitles.entries) {
        if (docLink.contains(entry.key)) {
          return entry.value;
        }
      }
      return 'NIST Document';
    }).toList();
  }
}
