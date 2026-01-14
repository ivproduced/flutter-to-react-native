import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_tile.dart';
import '../../../models/oscal_models.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';

class AllControlsListScreenPro extends StatelessWidget {
  final List<Control> allControls;
  final PurchaseService purchaseService;

  const AllControlsListScreenPro({
    super.key,
    required this.allControls,
    required this.purchaseService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Controls')),
      body: ListView.builder(
        itemCount: allControls.length,
        cacheExtent: 1000.0,
        itemBuilder: (context, index) {
          final control = allControls[index];
          return ControlTile(
            control: control,
            purchaseService: purchaseService,
          );
        },
      ),
    );
  }
}
