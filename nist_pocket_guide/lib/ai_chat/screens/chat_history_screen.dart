import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/chat_storage_service.dart';

class ChatHistoryScreen extends StatefulWidget {
  final Function(List<ChatMessage>)? onLoadChatHistory;
  final String? currentSessionId;

  const ChatHistoryScreen({
    super.key,
    this.onLoadChatHistory,
    this.currentSessionId,
  });

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<ChatSession> chatSessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }

  Future<void> _loadChatSessions() async {
    try {
      final sessions = await ChatStorageService.restoreChatSessions();
      // Sort by most recent first
      sessions.sort(
        (a, b) => (b.lastMessageTime ?? b.updatedAt).compareTo(
          a.lastMessageTime ?? a.updatedAt,
        ),
      );

      setState(() {
        chatSessions = sessions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat history: $e')),
        );
      }
    }
  }

  Future<void> _deleteSession(ChatSession session) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Chat'),
            content: Text('Are you sure you want to delete "${session.name}"?'),
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
      await ChatStorageService.deleteSession(session.id);
      _loadChatSessions();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted "${session.name}"')));
      }
    }
  }

  Future<void> _editSessionName(ChatSession session) async {
    final controller = TextEditingController(text: session.name);

    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename Chat'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Chat name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (newName != null && newName.isNotEmpty && newName != session.name) {
      await ChatStorageService.updateSessionName(session.id, newName);
      _loadChatSessions();
    }
  }

  Future<void> _exportSession(ChatSession session) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Chat Export: ${session.name}');
      buffer.writeln('Created: ${session.createdAt}');
      buffer.writeln('Last Updated: ${session.updatedAt}');
      buffer.writeln('Messages: ${session.messages.length}');
      buffer.writeln('=' * 50);
      buffer.writeln();

      for (final message in session.messages) {
        if (message.role != 'system') {
          final role = message.role == 'user' ? 'You' : 'NISTBot';
          final timestamp = message.timestamp.toString();
          buffer.writeln('[$role] ($timestamp)');
          buffer.writeln(message.content);
          buffer.writeln();
        }
      }

      await Clipboard.setData(ClipboardData(text: buffer.toString()));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat exported to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exporting chat: $e')));
      }
    }
  }

  void _loadSession(ChatSession session) {
    if (widget.onLoadChatHistory != null && session.messages.isNotEmpty) {
      widget.onLoadChatHistory!(session.messages);
      // Ensure session ID is updated asynchronously
      ChatStorageService.setCurrentSessionId(session.id).then((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatSessions.isEmpty
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No chat history yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start a conversation to see it here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  itemCount: chatSessions.length,
                  itemBuilder: (context, index) {
                    final session = chatSessions[index];
                    final isCurrentSession =
                        session.id == widget.currentSessionId;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: isCurrentSession ? Colors.blue[50] : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isCurrentSession ? Colors.blue : Colors.grey,
                          child: const Icon(Icons.chat, color: Colors.white),
                        ),
                        title: Text(
                          session.name,
                          style: TextStyle(
                            fontWeight:
                                isCurrentSession
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.previewMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${session.messages.length} messages • ${_formatDate(session.lastMessageTime ?? session.updatedAt)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'rename':
                                _editSessionName(session);
                                break;
                              case 'export':
                                _exportSession(session);
                                break;
                              case 'delete':
                                _deleteSession(session);
                                break;
                            }
                          },
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'rename',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Rename'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'export',
                                  child: Row(
                                    children: [
                                      Icon(Icons.share),
                                      SizedBox(width: 8),
                                      Text('Export'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                        onTap: () => _loadSession(session),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
