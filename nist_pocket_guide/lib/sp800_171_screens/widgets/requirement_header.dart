// lib/sp800_171_screens/widgets/requirement_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sp800_171_models.dart';
import '../../services/purchase_service.dart';
import '../../app_data_manager.dart';
import '../../services/utils/upgrade_dialog.dart';

class RequirementHeader extends StatelessWidget {
  final Sp800171Requirement requirement;
  final Color familyColor;

  const RequirementHeader({
    super.key,
    required this.requirement,
    required this.familyColor,
  });

  @override
  Widget build(BuildContext context) {
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final bool isPro = purchaseService.isPro;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                    color: familyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 72,
                    minHeight: 56,
                  ),
                  child: Text(
                    requirement.requirementId,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: familyColor,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  requirement.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                // Family badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: familyColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: familyColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    requirement.familyId,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: familyColor,
                    ),
                  ),
                ),
              ],
            ),
            // Favorite button
            ValueListenableBuilder<Set<String>>(
              valueListenable: AppDataManager.instance.favoriteIds,
              builder: (context, favorites, _) {
                final isFavorite = favorites.contains(requirement.requirementId);
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isPro ? Colors.amber : Colors.grey,
                  ),
                  onPressed: isPro
                      ? () => AppDataManager.instance.toggleFavorite(requirement.requirementId)
                      : () => showUpgradeDialog(context, purchaseService),
                  tooltip: isPro
                      ? (isFavorite ? 'Remove from favorites' : 'Add to favorites')
                      : 'Upgrade to Pro for favorites',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
