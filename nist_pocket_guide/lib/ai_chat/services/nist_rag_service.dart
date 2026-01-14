// NIST RAG Service for Enhanced NISTBot
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NISTRAGService {
  // Production endpoints - Updated to use TIMA Core Service
  static const String primaryUrl = 'http://localhost:8001';
  // Add additional production endpoints here as needed
  static const List<String> fallbackUrls = [
    'http://127.0.0.1:8001',
    'http://10.0.2.2:8001', // Android emulator
    'https://tima-nistbot.duckdns.org', // Previous working endpoint
  ];

  static const String apiKey =
      'cc8139bf7b0be11a5264b8c8d84732529aac88dbb92a42a814783fb642313a06';

  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $apiKey',
  };

  // Try multiple endpoints to find working service
  static Future<String> _getWorkingBaseUrl() async {
    final urls = [primaryUrl, ...fallbackUrls];

    for (final url in urls) {
      try {
        final response = await http
            .get(Uri.parse('$url/health'), headers: headers)
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          if (kDebugMode) {
            print('Found working RAG service at: $url');
          }
          return url;
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to connect to $url: $e');
        }
      }
    }
    throw Exception('No working RAG service endpoints found');
  }

  /// Check if the RAG service is healthy and ready
  static Future<bool> isHealthy() async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/health'), headers: headers)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('NIST RAG health check failed: $e');
      }
      return false;
    }
  }

  /// Ask a general NIST question with RAG context retrieval
  static Future<NISTRAGResponse> askQuestion(String question) async {
    try {
      final baseUrl = await _getWorkingBaseUrl();
      final response = await http
          .post(
            Uri.parse(
              '$baseUrl/api/question',
            ), // Updated to match your API endpoint
            headers: headers,
            body: jsonEncode({'question': question}),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        return NISTRAGResponse.fromJson(jsonDecode(response.body));
      } else {
        throw HttpException('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('NIST RAG ask question failed: $e');
      }
      rethrow;
    }
  }
}

/// Response from the NIST RAG service
class NISTRAGResponse {
  final bool success;
  final String question;
  final String response;
  final List<NISTSource> sources;
  final int sourceCount;
  final List<String>? mentionedControls;

  NISTRAGResponse({
    required this.success,
    required this.question,
    required this.response,
    required this.sources,
    required this.sourceCount,
    this.mentionedControls,
  });

  factory NISTRAGResponse.fromJson(Map<String, dynamic> json) {
    // Handle the actual API response format
    if (json['success'] == true && json['answer'] != null) {
      final answerData = json['answer'];

      // Extract the response text from the first relevant content
      String responseText = '';
      List<NISTSource> sources = [];

      if (answerData is Map<String, dynamic>) {
        // Get the first relevant content as the main response
        if (answerData['relevant_content'] != null &&
            answerData['relevant_content'] is List) {
          final relevantContent = answerData['relevant_content'] as List;
          if (relevantContent.isNotEmpty) {
            final firstContent = relevantContent[0];
            if (firstContent is Map && firstContent['content'] != null) {
              responseText = firstContent['content'] as String;
            }
          }

          // Convert relevant content to sources
          sources =
              relevantContent.map((content) {
                if (content is Map<String, dynamic>) {
                  return NISTSource(
                    documentType: content['document_type'] ?? 'Unknown',
                    source: content['source'] ?? 'Unknown',
                    contentPreview:
                        (content['content'] as String? ?? '').length > 200
                            ? '${content['content'].substring(0, 200)}...'
                            : content['content'] ?? '',
                  );
                }
                return NISTSource(
                  documentType: 'Unknown',
                  source: 'Unknown',
                  contentPreview: content.toString(),
                );
              }).toList();
        }
      }

      return NISTRAGResponse(
        success: true,
        question: json['question'] ?? answerData['question'] ?? '',
        response: responseText,
        sources: sources,
        sourceCount: sources.length,
        mentionedControls:
            answerData['mentioned_controls'] != null
                ? List<String>.from(answerData['mentioned_controls'])
                : null,
      );
    }

    // Fallback for legacy format
    return NISTRAGResponse(
      success: json['success'] ?? false,
      question: json['question'] ?? '',
      response: json['response'] ?? '',
      sources:
          (json['sources'] as List? ?? [])
              .map((s) => NISTSource.fromJson(s))
              .toList(),
      sourceCount: json['source_count'] ?? 0,
      mentionedControls:
          json['mentioned_controls'] != null
              ? List<String>.from(json['mentioned_controls'])
              : null,
    );
  }
}

/// Source document information from NIST database
class NISTSource {
  final String documentType;
  final String source;
  final String contentPreview;

  NISTSource({
    required this.documentType,
    required this.source,
    required this.contentPreview,
  });

  factory NISTSource.fromJson(Map<String, dynamic> json) {
    return NISTSource(
      documentType: json['document_type'] ?? json['documentType'] ?? '',
      source: json['source'] ?? '',
      contentPreview:
          json['content_preview'] ??
          json['contentPreview'] ??
          json['content'] ??
          '',
    );
  }
}
