// lib/services/feedback_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/feedback_screen.dart';

class FeedbackService {
  static const String _lastFeedbackPromptKey = 'last_feedback_prompt';
  static const String _appUsageCountKey = 'app_usage_count';
  static const String _feedbackGivenKey = 'feedback_given';
  static const String _appRatedKey = 'app_rated';

  // Show feedback prompt after 3 app sessions, then every 10 sessions
  static const int _initialFeedbackThreshold = 3;
  static const int _recurringFeedbackThreshold = 10;

  /// Increment usage count and potentially show feedback prompt
  static Future<void> trackAppUsage(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_appUsageCountKey) ?? 0;
    final newCount = currentCount + 1;

    await prefs.setInt(_appUsageCountKey, newCount);

    // Check if we should show feedback prompt
    if (_shouldShowFeedbackPrompt(newCount, prefs)) {
      // Show prompt after a delay to not interrupt app startup
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          _showFeedbackPrompt(context);
        }
      });
    }
  }

  /// Track that user viewed control details (good engagement signal)
  static Future<void> trackControlViewed(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final viewCount = prefs.getInt('control_views') ?? 0;

    await prefs.setInt('control_views', viewCount + 1);

    // Show feedback prompt after user has viewed 5 controls (engaged user)
    if (viewCount + 1 == 5 && !await _hasFeedbackBeenGiven()) {
      Future.delayed(const Duration(seconds: 1), () {
        if (context.mounted) {
          _showFeedbackPrompt(context, isEngagementBased: true);
        }
      });
    }
  }

  /// Track assessment objectives usage
  static Future<void> trackAssessmentUsage(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final assessmentCount = prefs.getInt('assessment_views') ?? 0;

    await prefs.setInt('assessment_views', assessmentCount + 1);

    // Show feedback prompt after user uses assessment objectives 3 times
    if (assessmentCount + 1 == 3 && !await _hasFeedbackBeenGiven()) {
      Future.delayed(const Duration(seconds: 1), () {
        if (context.mounted) {
          _showFeedbackPrompt(
            context,
            title: 'Loving the Assessment Objectives?',
            message:
                'Help us make this feature even better with your feedback!',
          );
        }
      });
    }
  }

  static bool _shouldShowFeedbackPrompt(
    int usageCount,
    SharedPreferences prefs,
  ) {
    final lastPrompt = prefs.getInt(_lastFeedbackPromptKey) ?? 0;
    final feedbackGiven = prefs.getBool(_feedbackGivenKey) ?? false;

    // Don't show if feedback already given
    if (feedbackGiven) return false;

    // Show after initial threshold
    if (usageCount >= _initialFeedbackThreshold && lastPrompt == 0) {
      return true;
    }

    // Show recurring prompts
    if (lastPrompt > 0 &&
        (usageCount - lastPrompt) >= _recurringFeedbackThreshold) {
      return true;
    }

    return false;
  }

  static Future<bool> _hasFeedbackBeenGiven() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_feedbackGivenKey) ?? false;
  }

  static Future<void> _showFeedbackPrompt(
    BuildContext context, {
    bool isEngagementBased = false,
    String? title,
    String? message,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.favorite, color: Colors.red.shade400),
                const SizedBox(width: 12),
                Text(
                  title ??
                      (isEngagementBased
                          ? 'Enjoying NIST Pocket Guide?'
                          : 'Rate NIST Pocket Guide'),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message ??
                      (isEngagementBased
                          ? 'We noticed you\'re actively using the app. Your feedback would help us improve!'
                          : 'If you find NIST Pocket Guide helpful, would you mind rating it or sharing your feedback?'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    return Icon(Icons.star, color: Colors.amber, size: 24);
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _recordFeedbackPromptShown(prefs);
                },
                child: const Text('Not Now'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openAppStore(context);
                  _recordFeedbackGiven(prefs);
                },
                child: const Text('Rate App'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FeedbackScreen(),
                    ),
                  );
                  _recordFeedbackGiven(prefs);
                },
                child: const Text('Give Feedback'),
              ),
            ],
          ),
    );
  }

  static Future<void> _recordFeedbackPromptShown(
    SharedPreferences prefs,
  ) async {
    final currentCount = prefs.getInt(_appUsageCountKey) ?? 0;
    await prefs.setInt(_lastFeedbackPromptKey, currentCount);
  }

  static Future<void> _recordFeedbackGiven(SharedPreferences prefs) async {
    await prefs.setBool(_feedbackGivenKey, true);
  }

  static Future<void> _openAppStore(BuildContext context) async {
    // Replace with your actual app store URLs
    const iosAppId = 'your-ios-app-id';
    const androidPackageName = 'com.yourcompany.nistpocketguide';

    Uri? storeUrl;

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      storeUrl = Uri.parse('https://apps.apple.com/app/id$iosAppId');
    } else if (Theme.of(context).platform == TargetPlatform.android) {
      storeUrl = Uri.parse(
        'https://play.google.com/store/apps/details?id=$androidPackageName',
      );
    }

    if (storeUrl != null && await canLaunchUrl(storeUrl)) {
      await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_appRatedKey, true);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open app store')),
        );
      }
    }
  }

  /// Manual feedback trigger for menu items
  static Future<void> showFeedbackScreen(BuildContext context) async {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const FeedbackScreen()));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_feedbackGivenKey, true);
  }

  /// Get feedback statistics (for admin/debug purposes)
  static Future<Map<String, dynamic>> getFeedbackStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'appUsageCount': prefs.getInt(_appUsageCountKey) ?? 0,
      'controlViews': prefs.getInt('control_views') ?? 0,
      'assessmentViews': prefs.getInt('assessment_views') ?? 0,
      'lastFeedbackPrompt': prefs.getInt(_lastFeedbackPromptKey) ?? 0,
      'feedbackGiven': prefs.getBool(_feedbackGivenKey) ?? false,
      'appRated': prefs.getBool(_appRatedKey) ?? false,
    };
  }

  /// Reset feedback tracking (for testing)
  static Future<void> resetFeedbackTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastFeedbackPromptKey);
    await prefs.remove(_appUsageCountKey);
    await prefs.remove(_feedbackGivenKey);
    await prefs.remove(_appRatedKey);
    await prefs.remove('control_views');
    await prefs.remove('assessment_views');
  }
}
