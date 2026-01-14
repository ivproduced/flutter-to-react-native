import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_tile.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';

class EnhancementListViewPro extends StatelessWidget {
  final List<Control> enhancements;
  final PurchaseService purchaseService;

  const EnhancementListViewPro({
    super.key,
    required this.enhancements,
    required this.purchaseService,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '📄 ControlEnhancementListViewPro rendering: ${enhancements.length} items',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Control Enhancements')),
      body:
          enhancements.isEmpty
              ? const Center(
                child: Text('No enhancements found for this control.'),
              )
              : ListView.builder(
                itemCount: enhancements.length,
                cacheExtent: 1000.0,
                itemBuilder: (context, index) {
                  final control = enhancements[index];
                  return ControlTile(
                    control: control,
                    purchaseService: purchaseService,
                  );
                },
              ),
    );
  }
}
