import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// ChatMessage class is imported from the main screen file
class ChatMessage {
  final String role;
  final String content;
  final List<String>? documentLinks;
  final DateTime? timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    this.documentLinks,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

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
              _buildStreamedText(content, context)
            else
              _buildStaticText(content, isUser),

            if (resolvedTitles.isNotEmpty && !isUser) ...[
              const SizedBox(height: 8),
              _buildReferences(resolvedTitles),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreamedText(String content, BuildContext context) {
    final strippedText = content.replaceAll(RegExp(r'\[doc\d+\]'), '');
    return Text(
      strippedText.trim(),
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  Widget _buildStaticText(String content, bool isUser) {
    final strippedText = content.replaceAll(RegExp(r'\[doc\d+\]'), '');
    return Text(
      strippedText.trim(),
      style: TextStyle(
        fontSize: 16,
        color: isUser ? Colors.white : Colors.black87,
        fontWeight: FontWeight.normal,
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
        if (message.timestamp != null)
          Text(
            _formatTimestamp(message.timestamp!),
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
        message.content.replaceAll(RegExp(r'\[doc\d+\]'), '').trim();
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
    // This would need to be implemented based on your existing logic
    // For now, returning empty list
    return [];
  }
}
