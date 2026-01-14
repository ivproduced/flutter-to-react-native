import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/favorites_list_screen_pro.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/recents_list_screen_pro.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/notes_list_screen_pro.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/related_control_list_screen_pro.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/related_controls_screen_pro.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/enhancement_list_screen_pro.dart';
import 'package:nist_pocket_guide/services/utils/upgrade_dialog.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int)? onItemTapped;
  final PurchaseService purchaseService;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    this.onItemTapped,
    required this.purchaseService,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(0),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _quickAccessButton(
              context,
              Icons.star,
              purchaseService.isPro ? 'Favorites' : 'Favorites (Pro)',
              0,
            ),
            _quickAccessButton(
              context,
              Icons.note,
              purchaseService.isPro ? 'Notes' : 'Notes (Pro)',
              1,
            ),
            _quickAccessButton(context, Icons.history, 'Recent', 2),
          ],
        ),
      ),
    );
  }

  Widget _quickAccessButton(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0: // Favorites - Pro feature
            if (purchaseService.isPro) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => FavoritesScreen(purchaseService: purchaseService),
                ),
              );
            } else {
              showUpgradeDialog(context, purchaseService);
            }
            break;
          case 1: // Notes - Pro feature
            if (purchaseService.isPro) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotesScreen(purchaseService: purchaseService),
                ),
              );
            } else {
              showUpgradeDialog(context, purchaseService);
            }
            break;
          case 2: // Recent - Available to all
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        RecentControlsScreen(purchaseService: purchaseService),
              ),
            );
            break;
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color:
                (index == 0 || index == 1) && !purchaseService.isPro
                    ? Colors.grey.shade400
                    : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color:
                  (index == 0 || index == 1) && !purchaseService.isPro
                      ? Colors.grey.shade400
                      : null,
            ),
          ),
        ],
      ),
    );
  }
}

class StatementNavBar extends StatelessWidget {
  final Control control;
  final List<Control> enhancements;
  final PurchaseService purchaseService;
  final int selectedIndex;
  final void Function(int)? onItemTapped;

  const StatementNavBar({
    super.key,
    required this.selectedIndex,
    this.onItemTapped,
    required this.purchaseService,
    required this.control,
    required this.enhancements,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(0),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _quickAccessButton(context, Icons.upgrade, 'Enhancements', 0),
            _quickAccessButton(context, Icons.link, 'Related Controls', 1),
          ],
        ),
      ),
    );
  }

  Widget _quickAccessButton(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            if (enhancements.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No enhancements found for this control.'),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => EnhancementListViewPro(
                      enhancements: enhancements,
                      purchaseService: purchaseService,
                    ),
              ),
            );
            break;
          case 1: // Related Controls
            final relatedLinks =
                control.links
                    .where((link) => link.rel?.toLowerCase() == 'related')
                    .toList();

            if (relatedLinks.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No related controls for this control.'),
                ),
              );
              return;
            }

            final relatedControlIds =
                relatedLinks
                    .map(
                      (link) => link.href.replaceFirst('#', '').toLowerCase(),
                    )
                    .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => RelatedControlsListScreenPro(
                      controlIds: relatedControlIds,
                      purchaseService: purchaseService,
                    ),
              ),
            );
            break;
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class EnhancementNavBar extends StatelessWidget {
  final PurchaseService purchaseService;
  final int selectedIndex;
  final void Function(int)? onItemTapped;
  final Control enhancement; // Add this line to the class

  const EnhancementNavBar({
    super.key,
    required this.selectedIndex,
    this.onItemTapped,
    required this.purchaseService,
    required this.enhancement, // Add this line
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(0),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _quickAccessButton(context, Icons.link, 'Related Controls', 0),
          ],
        ),
      ),
    );
  }

  Widget _quickAccessButton(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            final relatedLinks =
                enhancement.links
                    .where((link) => link.rel?.toLowerCase() == 'related')
                    .toList();

            if (relatedLinks.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No related controls for this enhancement.'),
                ),
              );
              return;
            }

            final relatedControlIds =
                relatedLinks
                    .map(
                      (link) => link.href.replaceFirst('#', '').toLowerCase(),
                    )
                    .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => RelatedControlsScreenPro(
                      purchaseService: purchaseService,
                      relatedControlIds: relatedControlIds,
                    ),
              ),
            );
            break;
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class MainBottomNavBar extends StatelessWidget {
  final PurchaseService purchaseService;

  const MainBottomNavBar({super.key, required this.purchaseService});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(0),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navButton(context, Icons.star, 'Favorites', () {
              if (purchaseService.isPro) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) =>
                            FavoritesScreen(purchaseService: purchaseService),
                  ),
                );
              } else {
                showUpgradeDialog(context, purchaseService);
              }
            }),
            _navButton(context, Icons.note, 'Notes', () {
              if (purchaseService.isPro) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => NotesScreen(purchaseService: purchaseService),
                  ),
                );
              } else {
                showUpgradeDialog(context, purchaseService);
              }
            }),
            _navButton(context, Icons.restore, 'Restore', () {
              _handleRestorePurchases(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _navButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _handleRestorePurchases(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context); // capture early

    try {
      await purchaseService.restorePurchases();

      messenger.showSnackBar(
        const SnackBar(content: Text('Purchases restored successfully.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }
}
