// New ControlDashboardScreenPro

import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/bottom_nav_bar_pro.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/control_baseline_screen_pro.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/control_implementation_level_list_screen.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/control_family_screen_pro.dart';
import '../../../app_data_manager.dart'; // adjust if needed
import 'package:nist_pocket_guide/800-53_screens/pro_screens/all_controls_list_pro.dart';

class ControlDashboardScreenPro extends StatelessWidget {
  final PurchaseService purchaseService;
  const ControlDashboardScreenPro({super.key, required this.purchaseService});

  get familyPrefix => null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navOptions = [
      {
        'label': 'Controls by Family',
        'icon': Icons.folder_special_outlined,
        'color': Colors.blueAccent,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ControlFamilyViewPro(purchaseService: purchaseService),
            ),
          );
        },
      },
      {
        'label': 'Controls by Baseline',
        'icon': Icons.security_outlined,
        'color': Colors.green,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ControlBaselineScreenPro(
                    purchaseService: purchaseService,
                  ),
            ),
          );
        },
      },
      {
        'label': 'Controls by Implementation Level',
        'icon': Icons.label_important_outline,
        'color': Colors.orange,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ControlsByImplementationLevelScreen(
                    allControls: AppDataManager.instance.catalog.controls,
                    purchaseService: purchaseService,
                  ),
            ),
          );
        },
      },
      {
        'label': 'All Controls List',
        'icon': Icons.list_alt_outlined,
        'color': Colors.purple,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AllControlsListScreenPro(
                    allControls: AppDataManager.instance.catalog.controls,
                    purchaseService: purchaseService,
                  ),
            ),
          );
        },
      },
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('Explore Controls')),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          // handle nav tap
        },
        purchaseService: purchaseService,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explore Controls',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 28),
              ...navOptions.map(
                (opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: opt['onTap'] as VoidCallback,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: (opt['color'] as Color)
                                  .withAlpha((0.15 * 255).round()),
                              radius: 28,
                              child: Icon(
                                opt['icon'] as IconData,
                                color: opt['color'] as Color,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                opt['label'] as String,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
