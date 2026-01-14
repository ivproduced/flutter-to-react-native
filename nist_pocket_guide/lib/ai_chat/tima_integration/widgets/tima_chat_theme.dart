// Theme configuration for TIMA chat components.
//
// This provides consistent styling that integrates well with
// the existing NIST Pocket Guide design system.

import 'package:flutter/material.dart';

/// Theme configuration for TIMA chat components.
class TIMAChatTheme {
  const TIMAChatTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.userBubbleColor,
    required this.assistantBubbleColor,
    required this.userTextColor,
    required this.assistantTextColor,
    required this.choiceButtonColor,
    required this.choiceButtonTextColor,
    required this.citationColor,
    required this.headerColor,
    this.borderRadius = 12.0,
    this.messageBorderRadius = 16.0,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color userBubbleColor;
  final Color assistantBubbleColor;
  final Color userTextColor;
  final Color assistantTextColor;
  final Color choiceButtonColor;
  final Color choiceButtonTextColor;
  final Color citationColor;
  final Color headerColor;
  final double borderRadius;
  final double messageBorderRadius;

  /// Create a theme from the current Flutter theme context.
  factory TIMAChatTheme.fromContext(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TIMAChatTheme(
      backgroundColor: theme.scaffoldBackgroundColor,
      borderColor: theme.dividerColor,
      userBubbleColor: theme.primaryColor,
      assistantBubbleColor:
          isDark ? Colors.grey.shade800 : Colors.grey.shade100,
      userTextColor: Colors.white,
      assistantTextColor: theme.textTheme.bodyLarge?.color ?? Colors.black87,
      choiceButtonColor: theme.primaryColor.withValues(alpha: 0.1),
      choiceButtonTextColor: theme.primaryColor,
      citationColor: Colors.blue.shade600,
      headerColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
    );
  }

  /// Create a light theme variant.
  factory TIMAChatTheme.light() {
    return const TIMAChatTheme(
      backgroundColor: Colors.white,
      borderColor: Color(0xFFE0E0E0),
      userBubbleColor: Colors.blue,
      assistantBubbleColor: Color(0xFFF5F5F5),
      userTextColor: Colors.white,
      assistantTextColor: Colors.black87,
      choiceButtonColor: Color(0xFFE3F2FD),
      choiceButtonTextColor: Colors.blue,
      citationColor: Color(0xFF1976D2),
      headerColor: Color(0xFFFAFAFA),
    );
  }

  /// Create a dark theme variant.
  factory TIMAChatTheme.dark() {
    return const TIMAChatTheme(
      backgroundColor: Color(0xFF121212),
      borderColor: Color(0xFF333333),
      userBubbleColor: Colors.blue,
      assistantBubbleColor: Color(0xFF1E1E1E),
      userTextColor: Colors.white,
      assistantTextColor: Colors.white,
      choiceButtonColor: Color(0xFF1A237E),
      choiceButtonTextColor: Colors.blue,
      citationColor: Color(0xFF42A5F5),
      headerColor: Color(0xFF1E1E1E),
    );
  }
}
