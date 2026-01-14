// HTTP client for communicating with the NIST ChatBot API.
//
// This service handles all API communication with the enterprise NIST ChatBot
// service, including error handling, timeout management, SSL certificate
// acceptance, and response parsing. The API provides comprehensive cybersecurity
// guidance based on 6,425+ NIST documents with AI-powered responses.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../models/chat_models.dart';

/// Exception thrown when API communication fails.
class TIMAApiException implements Exception {
  const TIMAApiException({
    required this.message,
    this.statusCode,
    this.response,
  });

  final String message;
  final int? statusCode;
  final String? response;

  @override
  String toString() => 'TIMAApiException: $message';
}

/// Configuration for the TIMA Dialog RAG client.
class TIMAClientConfig {
  const TIMAClientConfig({
    this.baseUrl = 'http://localhost:8001', // TIMA Core Service as primary
    this.fallbackUrls = const [
      'http://127.0.0.1:8001',
      'http://10.0.2.2:8001', // Android emulator host
      'http://100.119.20.22:8001', // Tailscale network
      'http://172.20.0.2:8001', // Docker network
      'https://tima-nistbot.duckdns.org', // DuckDNS as fallback
    ],
    this.apiKey =
        'cc8139bf7b0be11a5264b8c8d84732529aac88dbb92a42a814783fb642313a06',
    this.timeout = const Duration(seconds: 30),
    this.retryAttempts = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.enableLogging = true, // Enable logging to debug issues
  });

  final String baseUrl;
  final List<String> fallbackUrls;
  final String? apiKey;
  final Duration timeout;
  final int retryAttempts;
  final Duration retryDelay;
  final bool enableLogging;

  TIMAClientConfig copyWith({
    String? baseUrl,
    List<String>? fallbackUrls,
    String? apiKey,
    Duration? timeout,
    int? retryAttempts,
    Duration? retryDelay,
    bool? enableLogging,
  }) {
    return TIMAClientConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      fallbackUrls: fallbackUrls ?? this.fallbackUrls,
      apiKey: apiKey ?? this.apiKey,
      timeout: timeout ?? this.timeout,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      retryDelay: retryDelay ?? this.retryDelay,
      enableLogging: enableLogging ?? this.enableLogging,
    );
  }
}

/// HTTP client for the TIMA Dialog RAG API.
class TIMADialogClient {
  TIMADialogClient({TIMAClientConfig? config, http.Client? httpClient})
    : _config = config ?? const TIMAClientConfig(),
      _httpClient = httpClient ?? _createHttpClient();

  final TIMAClientConfig _config;
  final http.Client _httpClient;
  String? _workingBaseUrl; // Cache the working URL

  /// Create an HTTP client that accepts self-signed certificates.
  static http.Client _createHttpClient() {
    final client = HttpClient();
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return IOClient(client);
  }

  /// Find a working endpoint from the configured URLs
  Future<String?> _findWorkingEndpoint() async {
    if (_workingBaseUrl != null) {
      return _workingBaseUrl; // Return cached working URL
    }

    final urlsToTry = [_config.baseUrl, ..._config.fallbackUrls];

    for (final url in urlsToTry) {
      try {
        if (_config.enableLogging) {
          print('Trying TIMA endpoint: $url');
        }

        final response = await _httpClient
            .get(Uri.parse('$url/health'), headers: _buildHeaders(url))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode >= 200 && response.statusCode < 400) {
          if (_config.enableLogging) {
            print('Found working TIMA endpoint: $url');
          }
          _workingBaseUrl = url; // Cache the working URL
          return url;
        }
      } catch (e) {
        if (_config.enableLogging) {
          print('Failed to connect to $url: $e');
        }
      }
    }

    if (_config.enableLogging) {
      print('No working TIMA endpoints found');
    }
    return null;
  }

  /// Send a chat message and get a response.
  Future<TIMAChatOutput> sendMessage(TIMAChatInput input) async {
    return _executeWithRetry(() => _sendMessageInternal(input));
  }

  /// Convenience method to ask a cybersecurity question directly.
  ///
  /// [question] - The cybersecurity question to ask
  /// [context] - Optional context about your organization or situation
  /// [sessionId] - Optional session ID for conversation tracking
  Future<TIMAChatOutput> askQuestion(
    String question, {
    String? context,
    String? sessionId,
  }) async {
    final input = TIMAChatInput.text(
      sessionId: sessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: question,
      metadata: context != null ? {'context': context} : {},
    );
    return sendMessage(input);
  }

  /// Checks if the TIMA RAG service is healthy and reachable.
  Future<bool> checkHealth() async {
    try {
      final workingUrl = await _findWorkingEndpoint();

      if (workingUrl == null) {
        print('No working TIMA Core Service endpoints found');
        return false;
      }

      print('TIMA Core Service health check passed at: $workingUrl');
      return true;
    } catch (e, stackTrace) {
      print('TIMA Core Service health check error: $e');
      if (_config.enableLogging) {
        print('Stack trace: $stackTrace');
      }
      return false;
    }
  }

  /// Get API information and version.
  Future<Map<String, dynamic>> getApiInfo() async {
    try {
      final workingUrl = await _findWorkingEndpoint();
      if (workingUrl == null) {
        throw TIMAApiException(message: 'No working TIMA endpoints available');
      }

      final response = await _httpClient
          .get(
            Uri.parse('$workingUrl/api/status'),
            headers: _buildHeaders(workingUrl),
          )
          .timeout(_config.timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      throw TIMAApiException(
        message: 'Failed to get API info',
        statusCode: response.statusCode,
        response: response.body,
      );
    } catch (e) {
      if (e is TIMAApiException) rethrow;
      throw TIMAApiException(message: 'Network error: $e');
    }
  }

  /// Internal method to send chat message.
  Future<TIMAChatOutput> _sendMessageInternal(TIMAChatInput input) async {
    try {
      // Find working endpoint first
      final workingUrl = await _findWorkingEndpoint();
      if (workingUrl == null) {
        throw TIMAApiException(message: 'No working TIMA endpoints available');
      }

      // Use different request formats based on the endpoint
      Map<String, dynamic> apiPayload;
      String endpoint;

      if (workingUrl.contains('duckdns.org')) {
        // DuckDNS format - simple question format for fallback
        apiPayload = {'question': input.text ?? ''};
        endpoint = '/ask'; // Try /ask endpoint for DuckDNS
      } else {
        // TIMA Core Service format - proper API specification
        apiPayload = {
          'question': input.text ?? '',
          'user_id': input.sessionId,
          'enhance_query': true,
          'conversational': true,
        };
        // Use NIST endpoint for cybersecurity questions, chat for general
        endpoint =
            _isNISTQuestion(input.text ?? '') ? '/api/v1/nist' : '/api/v1/chat';
      }

      final body = json.encode(apiPayload);

      if (_config.enableLogging) {
        print('TIMA Core Service Request to $workingUrl$endpoint: $body');
      }

      final response = await _httpClient
          .post(
            Uri.parse('$workingUrl$endpoint'),
            headers: _buildHeaders(workingUrl),
            body: body,
          )
          .timeout(_config.timeout);

      if (_config.enableLogging) {
        print('TIMA Core Service Response - Status: ${response.statusCode}');
        print('TIMA Core Service Response - Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Handle different response formats based on endpoint
        String reply;
        if (workingUrl.contains('duckdns.org')) {
          // DuckDNS format - response has 'answer' field
          reply = data['answer'] ?? '';
        } else {
          // TIMA Core Service format - response has 'response' field
          reply = data['response'] ?? '';
        }

        // Transform the response to match the expected output format
        final transformedResponse = {
          'reply': reply,
          'choices': <Map<String, dynamic>>[],
          'citations': <Map<String, dynamic>>[],
          'context': {
            'tima_core': data['metadata'] ?? {},
            'model_used': data['model'] ?? 'tima-core',
            'processing_time': data['processing_time'] ?? 0.0,
            'timestamp': DateTime.now().toIso8601String(),
            'service':
                workingUrl.contains('duckdns.org')
                    ? 'duckdns-service'
                    : 'tima-core-service',
            'endpoint': endpoint,
          },
        };

        return TIMAChatOutput.fromJson(transformedResponse);
      }

      // Handle error responses
      String errorMessage = 'Request failed';
      try {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        errorMessage =
            errorData['detail']?.toString() ??
            errorData['error']?.toString() ??
            errorMessage;
      } catch (_) {
        // Use default error message if response parsing fails
      }

      throw TIMAApiException(
        message: errorMessage,
        statusCode: response.statusCode,
        response: response.body,
      );
    } on SocketException catch (e) {
      throw TIMAApiException(
        message: 'Network connection failed: ${e.message}',
      );
    } on TimeoutException catch (_) {
      throw TIMAApiException(
        message: 'Request timed out after ${_config.timeout.inSeconds} seconds',
      );
    } catch (e) {
      if (e is TIMAApiException) rethrow;
      throw TIMAApiException(message: 'Unexpected error: $e');
    }
  }

  /// Execute a request with retry logic.
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int attempt = 0;
    while (attempt < _config.retryAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        if (_config.enableLogging) {
          print('TIMA Request attempt $attempt failed: $e');
        }

        // Don't retry on certain errors
        if (e is TIMAApiException) {
          // Don't retry client errors (4xx)
          if (e.statusCode != null &&
              e.statusCode! >= 400 &&
              e.statusCode! < 500) {
            rethrow;
          }
        }

        // If this was the last attempt, rethrow the error
        if (attempt >= _config.retryAttempts) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(_config.retryDelay * attempt);
      }
    }

    // This should never be reached, but just in case
    throw TIMAApiException(message: 'All retry attempts failed');
  }

  /// Build HTTP headers for requests.
  Map<String, String> _buildHeaders([String? endpointUrl]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'NIST-Pocket-Guide-Flutter/1.0',
    };

    // Use different authentication based on endpoint
    if (endpointUrl != null && endpointUrl.contains('duckdns.org')) {
      // DuckDNS endpoint uses X-API-Key
      headers['X-API-Key'] = 'tima-20250817-40a5f5a58e197231f3f0717ee7c89dd8';
    } else if (_config.apiKey != null) {
      // Local TIMA Core Service uses Bearer token
      headers['Authorization'] = 'Bearer ${_config.apiKey!}';
    }

    return headers;
  }

  /// Determine if a question is NIST/cybersecurity related
  bool _isNISTQuestion(String question) {
    final lowerQuestion = question.toLowerCase();
    final nistKeywords = [
      'ac-',
      'au-',
      'at-',
      'ca-',
      'cm-',
      'cp-',
      'ia-',
      'ir-',
      'ma-',
      'mp-',
      'pe-',
      'pl-',
      'ps-',
      'ra-',
      'sa-',
      'sc-',
      'si-',
      'sr-',
      'nist',
      'cybersecurity',
      'security control',
      'compliance',
      'framework',
      'risk',
      'vulnerability',
      'assessment',
      'authorization',
      'audit',
      'monitoring',
      'incident',
      'response',
      'access control',
      'encryption',
      'firewall',
    ];
    return nistKeywords.any((keyword) => lowerQuestion.contains(keyword));
  }

  /// Dispose of the client resources.
  void dispose() {
    _httpClient.close();
  }
}

/// Streaming variant of the TIMA Dialog client for real-time responses.
///
/// This extends the base client with streaming capabilities for
/// character-by-character response display, similar to your existing
/// NISTBot streaming interface.
class TIMADialogStreamingClient extends TIMADialogClient {
  TIMADialogStreamingClient({super.config, super.httpClient});

  /// Send a message and get a streaming response.
  ///
  /// This simulates streaming by breaking the response into chunks
  /// and yielding them progressively. In a real implementation,
  /// you might connect to a Server-Sent Events endpoint.
  Stream<String> sendMessageStreaming(TIMAChatInput input) async* {
    try {
      // Get the complete response first
      final output = await sendMessage(input);

      // Stream the response character by character
      final content = output.reply;
      const chunkSize = 3; // Characters per chunk
      const delay = Duration(milliseconds: 50); // Delay between chunks

      for (int i = 0; i < content.length; i += chunkSize) {
        final end =
            (i + chunkSize < content.length) ? i + chunkSize : content.length;
        final chunk = content.substring(i, end);

        yield chunk;

        // Add delay to simulate streaming
        if (i + chunkSize < content.length) {
          await Future.delayed(delay);
        }
      }
    } catch (e) {
      throw TIMAApiException(message: 'Streaming failed: $e');
    }
  }

  /// Send a message and get a complete streaming response event.
  ///
  /// This yields both the incremental text chunks and the final
  /// complete response with choices and citations.
  Stream<TIMAStreamingEvent> sendMessageStreamingComplete(
    TIMAChatInput input,
  ) async* {
    try {
      // Start with a typing indicator
      yield const TIMAStreamingEvent.typing();

      // Get the complete response
      final output = await sendMessage(input);

      // Stream the text content
      final content = output.reply;
      const chunkSize = 3;
      const delay = Duration(milliseconds: 50);
      String accumulatedText = '';

      for (int i = 0; i < content.length; i += chunkSize) {
        final end =
            (i + chunkSize < content.length) ? i + chunkSize : content.length;
        final chunk = content.substring(i, end);
        accumulatedText += chunk;

        yield TIMAStreamingEvent.textChunk(
          chunk: chunk,
          accumulated: accumulatedText,
        );

        if (i + chunkSize < content.length) {
          await Future.delayed(delay);
        }
      }

      // Yield the final complete response
      yield TIMAStreamingEvent.complete(output);
    } catch (e) {
      yield TIMAStreamingEvent.error(
        TIMAApiException(message: 'Streaming failed: $e'),
      );
    }
  }
}

/// Events emitted during streaming responses.
class TIMAStreamingEvent {
  const TIMAStreamingEvent._({
    required this.type,
    this.chunk,
    this.accumulated,
    this.output,
    this.error,
  });

  final TIMAStreamingEventType type;
  final String? chunk;
  final String? accumulated;
  final TIMAChatOutput? output;
  final TIMAApiException? error;

  /// Create a typing indicator event.
  const TIMAStreamingEvent.typing()
    : this._(type: TIMAStreamingEventType.typing);

  /// Create a text chunk event.
  const TIMAStreamingEvent.textChunk({
    required String chunk,
    required String accumulated,
  }) : this._(
         type: TIMAStreamingEventType.textChunk,
         chunk: chunk,
         accumulated: accumulated,
       );

  /// Create a complete response event.
  const TIMAStreamingEvent.complete(TIMAChatOutput output)
    : this._(type: TIMAStreamingEventType.complete, output: output);

  /// Create an error event.
  const TIMAStreamingEvent.error(TIMAApiException error)
    : this._(type: TIMAStreamingEventType.error, error: error);

  bool get isTyping => type == TIMAStreamingEventType.typing;
  bool get isTextChunk => type == TIMAStreamingEventType.textChunk;
  bool get isComplete => type == TIMAStreamingEventType.complete;
  bool get isError => type == TIMAStreamingEventType.error;
}

/// Types of streaming events.
enum TIMAStreamingEventType { typing, textChunk, complete, error }
