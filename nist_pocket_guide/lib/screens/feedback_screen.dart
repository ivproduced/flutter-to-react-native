// lib/screens/feedback_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  String _selectedFeedbackType = 'General';
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _includeEmail = false;

  final List<String> _feedbackTypes = [
    'General',
    'Bug Report',
    'Feature Request',
    'Content Suggestion',
    'User Experience',
    'Performance Issue',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    size: 48,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We Value Your Feedback!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help us improve NIST Pocket Guide by sharing your thoughts, suggestions, or reporting issues.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rating Section
            Text(
              'How would you rate your experience?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildRatingSection(),

            const SizedBox(height: 24),

            // Feedback Type
            Text(
              'Feedback Type',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildFeedbackTypeSelector(),

            const SizedBox(height: 24),

            // Feedback Text
            Text(
              'Your Feedback',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feedbackController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: _getHintTextForFeedbackType(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: 24),

            // Optional Email
            Row(
              children: [
                Checkbox(
                  value: _includeEmail,
                  onChanged: (value) {
                    setState(() {
                      _includeEmail = value ?? false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Include my email for follow-up (optional)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),

            if (_includeEmail) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'your.email@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting...'),
                          ],
                        )
                        : const Text(
                          'Submit Feedback',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),

            const SizedBox(height: 16),

            // Alternative Contact
            Center(
              child: TextButton(
                onPressed: _openDirectEmail,
                child: Text(
                  'Or email us directly',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          final starIndex = index + 1;
          return GestureDetector(
            onTap: () {
              setState(() {
                _rating = starIndex;
              });
            },
            child: Icon(
              starIndex <= _rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 32,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFeedbackTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFeedbackType,
          isExpanded: true,
          items:
              _feedbackTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getIconForFeedbackType(type), size: 20),
                      const SizedBox(width: 12),
                      Text(type),
                    ],
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedFeedbackType = value ?? 'General';
            });
          },
        ),
      ),
    );
  }

  IconData _getIconForFeedbackType(String type) {
    switch (type) {
      case 'Bug Report':
        return Icons.bug_report_outlined;
      case 'Feature Request':
        return Icons.lightbulb_outline;
      case 'Content Suggestion':
        return Icons.content_paste_outlined;
      case 'User Experience':
        return Icons.person_outline;
      case 'Performance Issue':
        return Icons.speed_outlined;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  String _getHintTextForFeedbackType() {
    switch (_selectedFeedbackType) {
      case 'Bug Report':
        return 'Please describe the bug you encountered. Include steps to reproduce if possible...';
      case 'Feature Request':
        return 'What new feature would you like to see? How would it improve your experience...';
      case 'Content Suggestion':
        return 'What content improvements or additions would be helpful...';
      case 'User Experience':
        return 'How can we improve the app\'s usability and user experience...';
      case 'Performance Issue':
        return 'Please describe any performance issues you\'ve noticed...';
      default:
        return 'Please share your thoughts, suggestions, or feedback about NIST Pocket Guide...';
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      _showErrorDialog('Please provide your feedback before submitting.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Create email body with all feedback information
      final emailBody = _buildEmailBody();

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'feedback@nistpocketguide.com', // Replace with your actual email
        query: _encodeQueryParameters({
          'subject': 'NIST Pocket Guide Feedback - $_selectedFeedbackType',
          'body': emailBody,
        }),
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        _showSuccessDialog();
      } else {
        _showErrorDialog(
          'Unable to open email app. Please try the direct email option.',
        );
      }
    } catch (e) {
      _showErrorDialog(
        'An error occurred while submitting feedback. Please try again.',
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _buildEmailBody() {
    final buffer = StringBuffer();
    buffer.writeln('--- NIST Pocket Guide Feedback ---\n');

    if (_rating > 0) {
      buffer.writeln('Rating: ${'⭐' * _rating} ($_rating/5 stars)\n');
    }

    buffer.writeln('Feedback Type: $_selectedFeedbackType\n');

    if (_includeEmail && _emailController.text.trim().isNotEmpty) {
      buffer.writeln('Follow-up Email: ${_emailController.text.trim()}\n');
    }

    buffer.writeln('Feedback:');
    buffer.writeln(_feedbackController.text.trim());

    buffer.writeln('\n--- App Information ---');
    buffer.writeln('Build: 31');
    buffer.writeln('Platform: ${Theme.of(context).platform.name}');
    buffer.writeln('Timestamp: ${DateTime.now().toIso8601String()}');

    return buffer.toString();
  }

  String _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
        )
        .join('&');
  }

  Future<void> _openDirectEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'feedback@nistpocketguide.com', // Replace with your actual email
      query: 'subject=NIST Pocket Guide Feedback',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorDialog('Unable to open email app.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('Thank You!'),
              ],
            ),
            content: const Text(
              'Your feedback has been submitted. We appreciate you taking the time to help us improve NIST Pocket Guide.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Return to previous screen
                },
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 12),
                Text('Error'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
