// Example usage of the updated NIST ChatBot API client.
//
// This demonstrates how to use the new enterprise NIST ChatBot service
// with the updated endpoint and authentication.

import 'services/tima_dialog_client.dart';
import 'models/chat_models.dart';

/// Example function showing how to use the NIST ChatBot API
Future<void> demonstrateNISTChatBot() async {
  // Create client with default configuration (uses enterprise endpoint)
  final client = TIMADialogClient();

  try {
    // Check if the service is healthy
    final isHealthy = await client.checkHealth();
    print('NIST ChatBot Service Status: ${isHealthy ? "Online" : "Offline"}');

    if (!isHealthy) {
      print('Service is not available. Please check your connection.');
      return;
    }

    // Example 1: Simple question using convenience method
    print('\n--- Example 1: Simple Question ---');
    final response1 = await client.askQuestion(
      'What are the key security controls for cloud infrastructure?',
    );
    print(
      'Question: What are the key security controls for cloud infrastructure?',
    );
    print('Answer: ${response1.reply.substring(0, 200)}...');
    print('NIST Context: ${response1.context['nist_context']}');

    // Example 2: Question with organizational context
    print('\n--- Example 2: Question with Context ---');
    final response2 = await client.askQuestion(
      'How should we implement zero trust security?',
      context:
          'We are a healthcare organization with remote workers and patient data',
    );
    print('Question: How should we implement zero trust security?');
    print('Context: Healthcare organization with remote workers');
    print('Answer: ${response2.reply.substring(0, 200)}...');
    print('Processing Time: ${response2.context['processing_time']}s');
    print('Model Used: ${response2.context['model_used']}');

    // Example 3: Using the full TIMAChatInput model
    print('\n--- Example 3: Full Model Usage ---');
    final input = TIMAChatInput.text(
      sessionId: 'demo-session-123',
      text: 'What incident response procedures should we have in place?',
      metadata: {
        'context': 'Financial services company with online banking',
        'priority': 'high',
        'department': 'security',
      },
    );

    final response3 = await client.sendMessage(input);
    print(
      'Question: What incident response procedures should we have in place?',
    );
    print('Session ID: demo-session-123');
    print('Answer: ${response3.reply.substring(0, 200)}...');
    print('Response Context Keys: ${response3.context.keys.toList()}');

    // Example 4: Get API information
    print('\n--- Example 4: API Information ---');
    final apiInfo = await client.getApiInfo();
    print('API Info: $apiInfo');
  } catch (e) {
    print('Error occurred: $e');
  } finally {
    // Clean up resources
    client.dispose();
  }
}

/// Example of error handling with the NIST ChatBot API
Future<void> demonstrateErrorHandling() async {
  final client = TIMADialogClient();

  try {
    // This will demonstrate timeout handling
    final config = TIMAClientConfig(
      timeout: Duration(seconds: 1), // Very short timeout
      enableLogging: true,
    );
    final timeoutClient = TIMADialogClient(config: config);

    await timeoutClient.askQuestion('This might timeout due to short timeout');
  } on TIMAApiException catch (e) {
    print('TIMA API Error: ${e.message}');
    if (e.statusCode != null) {
      print('Status Code: ${e.statusCode}');
    }
    if (e.response != null) {
      print('Response: ${e.response}');
    }
  } catch (e) {
    print('Unexpected error: $e');
  } finally {
    client.dispose();
  }
}

/// Example usage with custom configuration
Future<void> demonstrateCustomConfiguration() async {
  // Custom configuration with logging enabled
  final config = TIMAClientConfig(
    baseUrl: 'https://74.96.98.72', // Using IP address instead of domain
    apiKey: 'tima-20250817-40a5f5a58e197231f3f0717ee7c89dd8',
    timeout: Duration(seconds: 90), // Longer timeout for complex queries
    retryAttempts: 5, // More retry attempts
    enableLogging: true, // Enable debug logging
  );

  final client = TIMADialogClient(config: config);

  try {
    final response = await client.askQuestion(
      'Provide a comprehensive security assessment framework for our organization',
      context:
          'Large enterprise with 10,000+ employees, hybrid cloud infrastructure, financial services sector',
    );

    print('Comprehensive Response Length: ${response.reply.length} characters');
    print('NIST Controls Found: ${response.context['nist_context']}');
  } catch (e) {
    print('Error with custom config: $e');
  } finally {
    client.dispose();
  }
}
