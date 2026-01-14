import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class ChatService {
  // Primary endpoint - DuckDNS
  static const String _apiUrl = 'https://tima-nistbot.duckdns.org/ask';
  // Backup endpoints for fallback
  static const List<String> _fallbackUrls = [
    'http://localhost:8001/api/v1/chat',
    'http://127.0.0.1:8001/api/v1/chat',
    'http://10.0.2.2:8001/api/v1/chat', // Android emulator
  ];
  static const Duration _timeout = Duration(seconds: 60);

  // API Keys for different services
  static const String _duckdnsApiKey =
      'tima-20250817-40a5f5a58e197231f3f0717ee7c89dd8';
  static const String _timaApiKey =
      'cc8139bf7b0be11a5264b8c8d84732529aac88dbb92a42a814783fb642313a06';

  static const List<String> loadingPhrases = [
    'Scraping gum off the firewall.',
    'Calibrating cyber-shenanigans.',
    'Encrypting your bad decisions.',
    'Is that MFA actually working?',
    'Patching holes faster than they appear.',
    'Debugging while the world burns.',
    'Turning coffee into code... and compliance.',
    'Hunting for vulnerabilities like it\'s 1999.',
    'Checking if your passwords are still \'password\'.',
    'Spinning up the hamster wheels of security.',
    'Making sure your data isn\'t wearing a "kick me" sign.',
    'Teaching AI the difference between good and evil.',
    'Convincing the firewall to play nice.',
    'Translating "it works on my machine" to enterprise.',
    'Bribing the intrusion detection system.',
    'Explaining to management why security isn\'t free.',
    'Wrangling certificates like a digital cowboy.',
    'Making backups of the backups of the backups.',
    'Ensuring compliance while maintaining sanity.',
    'Marketing\'s next \'cyberattack\'.',
    'Every click, a potential oops.',
    'Data\'s safe... terms and conditions apply.',
    'Running malware drills (with actual drills).',
    'Securing the coffee pot (from interns).',
    'Trust, but verify... and then panic.',
  ];

  static String getRandomLoadingPhrase() {
    return loadingPhrases[Random().nextInt(loadingPhrases.length)];
  }

  static String getApiUrl() => _apiUrl;

  static Future<String> sendMessage(List<ChatMessage> messageHistory) async {
    try {
      // Create a copy to avoid modifying the original
      final messagesCopy = List<ChatMessage>.from(messageHistory);
      trimMessageHistory(messagesCopy);

      // Get the latest user message as the question
      final userMessages =
          messagesCopy.where((msg) => msg.role == 'user').toList();
      final question = userMessages.isNotEmpty ? userMessages.last.content : '';

      // Try primary DuckDNS endpoint first
      try {
        print('Trying primary DuckDNS endpoint: $_apiUrl');
        final response = await http
            .post(
              Uri.parse(_apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'X-API-Key': _duckdnsApiKey,
              },
              body: jsonEncode({'question': question}),
            )
            .timeout(_timeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['answer'] != null) {
            print('Success from primary DuckDNS endpoint');
            return data['answer'] as String;
          }
        }
      } catch (e) {
        print('Primary DuckDNS endpoint failed: $e');
      }

      // Try fallback endpoints (TIMA Core Service format)
      for (final fallbackUrl in _fallbackUrls) {
        try {
          print('Trying fallback endpoint: $fallbackUrl');

          final timaRequestBody = {
            'message': question,
            'user_id': 'flutter_user',
            'temperature': 0.7,
            'max_tokens': 300,
          };

          final response = await http
              .post(
                Uri.parse(fallbackUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $_timaApiKey',
                },
                body: jsonEncode(timaRequestBody),
              )
              .timeout(_timeout);

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            print('Success from fallback endpoint: $fallbackUrl');

            if (data['response'] != null) {
              return data['response'] as String;
            } else if (data['answer'] != null) {
              return data['answer'] as String;
            }
          }
        } catch (e) {
          print('Fallback endpoint $fallbackUrl failed: $e');
          continue;
        }
      }

      // If all endpoints fail, return error message
      throw Exception('All endpoints failed. Services may be unavailable.');
    } catch (e) {
      print('Error in sendMessage: $e');
      return 'I apologize, but I\'m experiencing technical difficulties. Please try again later.';
    }
  }

  static void trimMessageHistory(List<ChatMessage> messages) {
    // Keep system message and last 10 messages to stay within token limits
    if (messages.length > 11) {
      final systemMessage = messages.first;
      final recentMessages = messages.skip(messages.length - 10).toList();
      messages.clear();
      messages.add(systemMessage);
      messages.addAll(recentMessages);
    }
  }
}
