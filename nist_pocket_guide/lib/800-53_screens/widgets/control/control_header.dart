// --- widgets/control/control_header.dart ---

import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/services/utils/upgrade_dialog.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/badge_builder.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_implmentation_level.dart';

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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(
                      32,
                    ), // Capsule/pill shape
                  ),
                  constraints: const BoxConstraints(
                    minWidth:
                        72, // Slightly larger minimum width for detail page
                    minHeight: 56, // Slightly larger height for detail page
                  ),
                  child: Text(
                    id.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 26, // Bigger font size as requested
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                // Implementation Level Badges (if any)
                if (control.props.any(
                  (p) => p.name == 'implementation-level' && p.value.isNotEmpty,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ImplementationLevelChips(
                      implementationLevelProps:
                          control.props
                              .where(
                                (p) =>
                                    p.name == 'implementation-level' &&
                                    p.value.isNotEmpty,
                              )
                              .toList(),
                    ),
                  ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Center(
                  child: buildLargeBaselineBadgesRow(
                    context,
                    baselines,
                    control,
                  ),
                ),
              ],
            ),
            ValueListenableBuilder<Set<String>>(
              valueListenable: AppDataManager.instance.favoriteIds,
              builder: (context, favorites, _) {
                final isFavorite = favorites.contains(id);
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isPro ? Colors.amber : Colors.grey,
                  ),
                  onPressed:
                      isPro
                          ? () => AppDataManager.instance.toggleFavorite(id)
                          : () => showUpgradeDialog(context, purchaseService),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
