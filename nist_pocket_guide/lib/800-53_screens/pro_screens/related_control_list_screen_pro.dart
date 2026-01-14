import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_tile.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';

class RelatedControlsListScreenPro extends StatelessWidget {
  final List<String> controlIds;
  final PurchaseService purchaseService;

  const RelatedControlsListScreenPro({
    super.key,
    required this.controlIds,
    required this.purchaseService,
  });

  @override
  Widget build(BuildContext context) {
    final manager = AppDataManager.instance;
    final List<Control> controls = controlIds
        .map((id) => manager.getControlById(id))
        .whereType<Control>() // filters out nulls
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Related Controls')),
      body: controls.isEmpty
          ? const Center(child: Text('No related controls found.'))
          : ListView.builder(
              itemCount: controls.length,
              itemBuilder: (context, index) {
                final control = controls[index];
                return ControlTile(
                  control: control,
                  purchaseService: purchaseService,
                  );
              },
            ),
    );
  }
}
