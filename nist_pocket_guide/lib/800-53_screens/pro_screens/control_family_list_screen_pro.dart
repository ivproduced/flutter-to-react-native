// control_family_list_screen_pro.dart

import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_tile.dart';
import '../../../models/oscal_models.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';

class ControlFamilyListViewPro extends StatelessWidget {
  final String familyPrefix;
  final List<Control> allControls;
  final PurchaseService purchaseService;

  const ControlFamilyListViewPro({
    super.key,
    required this.familyPrefix,
    required this.allControls,
    required this.purchaseService,
  });

  @override
  Widget build(BuildContext context) {
    final familyControls =
        allControls
            .where(
              (control) =>
                  control.id.toUpperCase().startsWith('$familyPrefix-') &&
                  !control.id.contains('.'),
            ) // Exclude enhancements
            .toSet()
            .toList(); // Remove duplicates

    return Scaffold(
      appBar: AppBar(title: Text('Controls: $familyPrefix Family')),
      body:
          familyControls.isEmpty
              ? const Center(child: Text('No controls found for this family.'))
              : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: familyControls.length,
                cacheExtent: 1000.0,
                itemBuilder: (context, index) {
                  final control = familyControls[index];
                  return ControlTile(
                    control: control,
                    purchaseService: purchaseService,
                  );
                },
              ),
    );
  }
}
