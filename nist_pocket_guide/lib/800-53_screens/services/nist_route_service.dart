// lib/800-53_screens/services/nist_route_service.dart
import 'package:flutter/material.dart';
import '../../../app_data_manager.dart';
import '../../services/purchase_service.dart';
import '../../models/oscal_models.dart';
import '../pro_screens/control_detail_screen_pro.dart';
import '../pro_screens/enhancement_detail_screen_pro.dart';

/// Centralized navigation service for 800-53 screens
/// Handles Pro/Free tier routing and consistent navigation patterns
class NistRouteService {
  /// Navigate to control detail screen (handles both controls and enhancements)
  /// Automatically detects pro status and control type
  static void navigateToControlDetail(
    BuildContext context, {
    required Control control,
    required PurchaseService purchaseService,
    String? returnRoute,
    String? returnLabel,
  }) {
    final isEnhancement = control.id.contains('.');
    
    // For now, always use Pro screens since free screens don't exist yet
    Widget destination;
    
    destination = isEnhancement
        ? EnhancementDetailScreenPro(
            enhancement: control,
            purchaseService: purchaseService,
            returnRoute: returnRoute,
            returnLabel: returnLabel,
          )
        : ControlDetailScreenPro(
            control: control,
            purchaseService: purchaseService,
            returnRoute: returnRoute,
            returnLabel: returnLabel,
          );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => destination,
        settings: RouteSettings(
          name: isEnhancement ? '/enhancement-detail' : '/control-detail',
        ),
      ),
    );
  }

  /// Navigate to control detail by ID (looks up control from AppDataManager)
  static void navigateToControlDetailById(
    BuildContext context, {
    required String controlId,
    required PurchaseService purchaseService,
    String? returnRoute,
    String? returnLabel,
  }) {
    final control = AppDataManager.instance.getControlById(controlId);
    
    if (control == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Control $controlId not found'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    navigateToControlDetail(
      context,
      control: control,
      purchaseService: purchaseService,
      returnRoute: returnRoute,
      returnLabel: returnLabel,
    );
  }
}
