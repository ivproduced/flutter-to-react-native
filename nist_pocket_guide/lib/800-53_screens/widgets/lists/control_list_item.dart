import 'package:flutter/material.dart';
import '../../../models/oscal_models.dart';
import '../../../services/purchase_service.dart';
import '../control/control_tile.dart';

/// Optimized list item widget for controls with proper key usage
class ControlListItem extends StatelessWidget {
  final Control control;
  final PurchaseService purchaseService;

  const ControlListItem({
    super.key,
    required this.control,
    required this.purchaseService,
  });

  @override
  Widget build(BuildContext context) {
    return ControlTile(
      key: ValueKey(control.id), // Important for ListView performance
      control: control,
      purchaseService: purchaseService,
    );
  }
}
