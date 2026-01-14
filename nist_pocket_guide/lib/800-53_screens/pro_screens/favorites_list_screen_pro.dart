import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_tile.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart'; // 👈 Needed for `Control`

class FavoritesScreen extends StatelessWidget {
  final PurchaseService purchaseService;
  const FavoritesScreen({super.key, required this.purchaseService});

  @override
  Widget build(BuildContext context) {
    final favoriteControls =
        AppDataManager().favoriteIds.value
            .map((id) => AppDataManager().getControlById(id))
            .whereType<Control>() // filters out nulls
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body:
          favoriteControls.isEmpty
              ? const Center(child: Text('No favorites added yet.'))
              : ListView.builder(
                itemCount: favoriteControls.length,
                cacheExtent: 1000.0,
                itemBuilder: (context, index) {
                  final control = favoriteControls[index];
                  return ControlTile(
                    control: control,
                    purchaseService: purchaseService,
                  );
                },
              ),
    );
  }
}
