// Enhanced NISTBot chat screen with TIMA ChatBot API integration
// This screen integrates with the enterprise NIST ChatBot service including:
// - 6,425+ NIST documents in knowledge base
// - Ollama llama3.2:3b with cybersecurity expertise
// - Enterprise API with SSL and authentication
/// - Source citations and transparency
library;


import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

// Import existing chat components
import 'models/chat_message.dart';
import 'screens/chat_warning_screen.dart';
import 'services/chat_service.dart';

// Import TIMA ChatBot integration
import 'tima_integration/services/tima_dialog_client.dart';

class EnhancedNISTBotChatScreen extends StatefulWidget {
  const EnhancedNISTBotChatScreen({super.key});

  @override
  State<EnhancedNISTBotChatScreen> createState() =>
      _EnhancedNISTBotChatScreenState();
}

class _EnhancedNISTBotChatScreenState extends State<EnhancedNISTBotChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Existing NISTBot state
  List<ChatMessage> messageHistory = [
    ChatMessage(
      role: "system",
      content:
          "You are a cybersecurity compliance assistant for NIST. Answer questions about NIST controls, RMF, and related topics.",
      timestamp: DateTime.now(),
    ),
  ];

  bool _isLoading = false;
  bool _showWarning = false;

  // TIMA ChatBot integration state
  bool _timaEnabled = false;
  bool _timaHealthy = false;
  TIMADialogClient? _timaClient;
  Map<String, dynamic> _currentContext = {};
  List<String> _currentControls = [];

  @override
  void initState() {
    super.initState();
    _initializeTIMAService();
  }

  Future<void> _initializeTIMAService() async {
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
      setState(() {
        _timaEnabled = true;
        _timaHealthy = isHealthy;
      });

      if (isHealthy && kDebugMode) {
        print('TIMA Core Service initialized successfully');
      } else if (kDebugMode) {
        print('TIMA Core Service is not healthy - falling back to basic chat');
      }
    } catch (e) {
      setState(() {
        _timaEnabled = false;
        _timaHealthy = false;
      });
      if (kDebugMode) {
        print('Failed to initialize TIMA Core Service: $e');
        print('Check if TIMA Core Service is running and accessible');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _timaClient?.dispose();
    super.dispose();
  }

  void _addMessage(
    String role,
    String content, {
    Map<String, dynamic>? context,
    List<String>? controls,
  }) {
    final message = ChatMessage(
      role: role,
      content: content,
      timestamp: DateTime.now(),
    );

    setState(() {
      messageHistory.add(message);
      if (context != null) _currentContext = context;
      if (controls != null) _currentControls = controls;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    _controller.clear();
    _addMessage("user", message);

    setState(() {
      _isLoading = true;
    });

    try {
      if (_timaEnabled && _timaHealthy) {
        await _sendTIMAMessage(message);
      } else {
        await _sendFallbackMessage(message);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      // Don't add duplicate error message here since _sendTIMAMessage handles it
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendTIMAMessage(String message) async {
    try {
      if (_timaClient == null) {
        throw Exception('TIMA client not initialized');
      }

      final response = await _timaClient!.askQuestion(
        message,
        context: 'Enhanced NISTBot - Cybersecurity guidance request',
      );

      _addMessage("assistant", response.reply, context: response.context);
    } catch (e) {
      if (kDebugMode) {
        print('TIMA service error: $e');
      }
      // Fallback to regular chat service without rethrowing errors
      try {
        await _sendFallbackMessage(message);
      } catch (fallbackError) {
        if (kDebugMode) {
          print('Fallback service also failed: $fallbackError');
        }
        // Only add one error message here, don't rethrow
        _addMessage(
          "assistant",
          "I'm experiencing technical difficulties connecting to the NIST ChatBot service. Please try again later.",
        );
      }
    }
  }

  Future<void> _sendFallbackMessage(String message) async {
    final response = await ChatService.sendMessage(messageHistory);
    _addMessage("assistant", response);
  }

  Widget _buildContextInfo() {
    if (_currentContext.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NIST Context:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8.0),
          if (_currentContext['nist_context'] != null) ...[
            Text(
              'Controls Found: ${_currentContext['nist_context']['controls_found'] ?? 0}',
            ),
            Text('Model Used: ${_currentContext['model_used'] ?? 'N/A'}'),
            Text(
              'Processing Time: ${_currentContext['processing_time']?.toStringAsFixed(2) ?? 'N/A'}s',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlsList() {
    if (_currentControls.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Related Controls:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 4.0),
          ...(_currentControls.map(
            (control) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '• $control',
                style: TextStyle(fontSize: 12.0, color: Colors.green.shade700),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isStreaming) {
    final isUser = message.role == "user";
    final isSystem = message.role == "system";

    if (isSystem) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor:
                    _timaEnabled && _timaHealthy
                        ? Colors.green.shade100
                        : Colors.blue.shade100,
                child: Icon(
                  _timaEnabled && _timaHealthy ? Icons.smart_toy : Icons.chat,
                  size: 16,
                  color:
                      _timaEnabled && _timaHealthy
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: message.content,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser ? Colors.blue.shade900 : Colors.black87,
                        fontSize: 14.0,
                      ),
                      code: TextStyle(
                        backgroundColor: Colors.grey.shade200,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                  if (!isUser && !isStreaming) ...[
                    _buildContextInfo(),
                    _buildControlsList(),
                  ],
                  if (!isStreaming)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.shade100,
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    if (!_isLoading) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor:
                  _timaEnabled && _timaHealthy
                      ? Colors.green.shade100
                      : Colors.blue.shade100,
              child: Icon(
                _timaEnabled && _timaHealthy ? Icons.smart_toy : Icons.chat,
                size: 16,
                color:
                    _timaEnabled && _timaHealthy
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _timaEnabled && _timaHealthy
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _timaEnabled && _timaHealthy
                      ? 'Analyzing with NIST intelligence...'
                      : 'Thinking...',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    if (_showWarning) {
      return ChatWarningScreen(
        onAccept: () {
          setState(() {
            _showWarning = false;
          });
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced NISTBot'),
        backgroundColor:
            _timaEnabled && _timaHealthy
                ? Colors.green.shade100
                : Colors.blue.shade100,
        foregroundColor:
            _timaEnabled && _timaHealthy
                ? Colors.green.shade800
                : Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeTIMAService,
            tooltip: 'Refresh RAG Connection',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusIndicator(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messageHistory.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < messageHistory.length) {
                    return _buildMessageBubble(messageHistory[index], false);
                  } else {
                    return _buildLoadingIndicator();
                  }
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4.0,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText:
                            _timaEnabled && _timaHealthy
                                ? 'Ask about NIST controls, compliance, or security...'
                                : 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    backgroundColor:
                        _timaEnabled && _timaHealthy
                            ? Colors.green.shade100
                            : Colors.blue.shade100,
                    foregroundColor:
                        _timaEnabled && _timaHealthy
                            ? Colors.green.shade700
                            : Colors.blue.shade700,
                    mini: true,
                    child:
                        _isLoading
                            ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _timaEnabled && _timaHealthy
                                      ? Colors.green.shade700
                                      : Colors.blue.shade700,
                                ),
                              ),
                            )
                            : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
