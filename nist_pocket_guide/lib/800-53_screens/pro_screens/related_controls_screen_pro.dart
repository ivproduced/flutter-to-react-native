// --- widgets/control/related_controls_screen.dart ---

import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_tile.dart'; // 🔥 Needed for badges

class RelatedControlsScreenPro extends StatelessWidget {
  final List<String> relatedControlIds;
  final PurchaseService purchaseService;

  const RelatedControlsScreenPro({
    super.key,
    required this.relatedControlIds,
    required this.purchaseService,
  });

  @override
  Widget build(BuildContext context) {
    final controls = AppDataManager().catalog.controls;
    final Set<String> cleanIds = relatedControlIds.map((id) => id.trim().toLowerCase()).toSet();
    final relatedControls = controls.where((c) => cleanIds.contains(c.id.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Related Controls'),
      ),
      body: relatedControls.isEmpty
          ? const Center(child: Text('No related controls found.'))
          : ListView.builder(
              itemCount: relatedControls.length,
              itemBuilder: (context, index) {
                final control = relatedControls[index];
                return ControlTile(
                  control: control,
                  purchaseService: purchaseService,
                 );
              },
            ),
    );
  }
}
