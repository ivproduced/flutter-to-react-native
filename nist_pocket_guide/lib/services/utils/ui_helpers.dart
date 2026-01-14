// lib/utils/ui_helpers.dart
import 'package:flutter/material.dart';

Color getStatusColor(String? status, BuildContext context) { // Added context for theme access
  final colorScheme = Theme.of(context).colorScheme;
  switch (status) {
    case 'Implemented':
      return Colors.green.shade700; // Or colorScheme.primary for theme-based green
    case 'Partially Implemented':
      return Colors.orange.shade700; // Or colorScheme.secondary
    case 'Planned':
      return Colors.blue.shade700; // Or colorScheme.tertiary
    case 'Not Implemented':
      return Colors.red.shade700; // Or colorScheme.error
    case 'Not Applicable':
      return Colors.grey.shade600; // Or colorScheme.onSurface.withOpacity(0.6)
    default:
      return colorScheme.onSurface; // Default color if status is unknown
  }
}