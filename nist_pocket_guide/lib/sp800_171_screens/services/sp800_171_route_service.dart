// lib/sp800_171_screens/services/sp800_171_route_service.dart
import 'package:flutter/material.dart';
import '../../app_data_manager.dart';
import '../../models/sp800_171_models.dart';
import '../sp800_171_requirement_detail_screen.dart';

/// Centralized navigation service for SP 800-171 screens
/// Handles navigation patterns and requirement lookups
class Sp800171RouteService {
  /// Navigate to requirement detail screen
  static void navigateToRequirementDetail(
    BuildContext context, {
    required Sp800171Requirement requirement,
    required Color familyColor,
    String? returnRoute,
    String? returnLabel,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Sp800171RequirementDetailScreen(
          requirement: requirement,
          familyColor: familyColor,
          returnRoute: returnRoute,
          returnLabel: returnLabel,
        ),
        settings: const RouteSettings(
          name: '/sp800171-requirement-detail',
        ),
      ),
    );
  }

  /// Navigate to requirement detail by ID (looks up requirement from AppDataManager)
  static void navigateToRequirementDetailById(
    BuildContext context, {
    required String requirementId,
    String? returnRoute,
    String? returnLabel,
  }) {
    final requirement = AppDataManager.instance.getSp800171RequirementById(requirementId);
    
    if (requirement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Requirement $requirementId not found'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Get family color (default to teal if family not found)
    Color familyColor = const Color(0xFF00796B);
    final family = AppDataManager.instance.getSp800171FamilyById(requirement.familyId);
    if (family != null) {
      familyColor = _getFamilyColor(family.familyId);
    }

    navigateToRequirementDetail(
      context,
      requirement: requirement,
      familyColor: familyColor,
      returnRoute: returnRoute,
      returnLabel: returnLabel,
    );
  }

  /// Get color for a family ID
  static Color _getFamilyColor(String familyId) {
    switch (familyId.toLowerCase()) {
      case '03.01':
        return const Color(0xFF1976D2); // Blue
      case '03.02':
        return const Color(0xFF388E3C); // Green
      case '03.03':
        return const Color(0xFFF57C00); // Orange
      case '03.04':
        return const Color(0xFF7B1FA2); // Purple
      case '03.05':
        return const Color(0xFFC62828); // Red
      case '03.06':
        return const Color(0xFF00796B); // Teal
      case '03.08':
        return const Color(0xFF5D4037); // Brown
      case '03.10':
        return const Color(0xFF455A64); // Blue Grey
      case '03.11':
        return const Color(0xFFE64A19); // Deep Orange
      case '03.12':
        return const Color(0xFF6A1B9A); // Deep Purple
      case '03.13':
        return const Color(0xFF0097A7); // Cyan
      case '03.14':
        return const Color(0xFF00897B); // Teal Accent
      case '03.15':
        return const Color(0xFFAD1457); // Pink
      case '03.16':
        return const Color(0xFF558B2F); // Light Green
      case '03.17':
        return const Color(0xFFD84315); // Red Orange
      default:
        return const Color(0xFF00796B); // Default teal
    }
  }
}
