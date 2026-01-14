import 'dart:convert';
import 'package:http/http.dart' as http;

class NistChatService {
  final String endpoint = 'http://<your-server-url>/ask'; // Replace with your live or local backend

  Future<Map<String, dynamic>> sendQuery(String query) async {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get response');
    }

    final data = jsonDecode(response.body);

    final message = data['choices'][0]['message'];
    final content = message['content'] as String;
    final citations = message['context']?['citations'] ?? [];

    return {
      'answer': content,
      'citations': citations,
    };
  }
}
