// --- widgets/control/control_header.dart ---

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/services/utils/upgrade_dialog.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/badge_builder.dart'; // ✅ Import your badge builder

class ControlHeader extends StatelessWidget {
  final String id;
  final String title;
  final Map<String, bool> baselines;
  final PurchaseService purchaseService;
  final Control control;

  const ControlHeader({
    super.key,
    required this.id,
    required this.title,
    required this.baselines,
    required this.purchaseService,
    required this.control,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPro = purchaseService.isPro;

    // Find all implementation-level props
    final implementationLevelProps = control.props
        .where((p) => p.name == 'implementation-level' && p.value.isNotEmpty)
        .toList();

    if (kDebugMode) {
      print('Implementation-level props: ${implementationLevelProps.map((p) => p.value).toList()}');
    } // Debugging line

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16), // Spacer for Star
            Text(
              id.toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            // Show implementation levels if present
            if (implementationLevelProps.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 0.0, bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_tree, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Text(
                      'Implementation Level: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      implementationLevelProps.map((p) => p.value).join(', '),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: buildLargeBaselineBadgesRow(context, baselines, control),
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: ValueListenableBuilder<Set<String>>(
            valueListenable: AppDataManager.instance.favoriteIds,
            builder: (context, favorites, _) {
              final isFavorite = favorites.contains(id);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isPro ? Colors.amber : Colors.grey,
                ),
                onPressed: isPro
                    ? () => AppDataManager.instance.toggleFavorite(id)
                    : () => showUpgradeDialog(context, purchaseService),
              );
            },
          ),
        ),
      ],
    );
  }
}
