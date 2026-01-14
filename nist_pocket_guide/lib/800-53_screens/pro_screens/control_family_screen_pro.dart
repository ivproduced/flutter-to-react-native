import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/bottom_nav_bar_pro.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/search_results_screen_pro.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/search_bar_widget.dart';
import '../../models/oscal_models.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/control_family_list_screen_pro.dart';
import '../../../app_data_manager.dart'; // adjust if needed
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/services/utils/upgrade_dialog.dart';

class ControlFamilyViewPro extends StatefulWidget {
  final PurchaseService purchaseService;

  const ControlFamilyViewPro({super.key, required this.purchaseService});

  @override
  State<ControlFamilyViewPro> createState() => _ControlFamilyViewProState();
}

class _ControlFamilyViewProState extends State<ControlFamilyViewPro> {
  late Catalog catalog;
  List<String> familyPrefixes = [];
  Map<String, String> familyTitles = {};
  bool isLoading = true;
  bool isGridView = false;

  @override
  void initState() {
    super.initState();
    final appData = AppDataManager();
    final groups = appData.catalog.groups;

    familyPrefixes =
        groups.map((g) => g.id.toUpperCase()).toList(); // 🔵 AC, AU, SC, etc.
    familyTitles = {
      for (var g in groups) g.id.toUpperCase(): g.title,
    }; // 🔵 AC -> Access Control, etc.

    setState(() {}); // ✅ Refresh page after loading prefixes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controls by Family')),
      bottomNavigationBar:
          widget.purchaseService.isPro
              ? BottomNavBar(
                selectedIndex: 0,
                onItemTapped: (index) {
                  // handle nav tap
                },
                purchaseService: widget.purchaseService,
              )
              : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.purchaseService.isPro
                        ? SearchBarWidget(
                          onSubmitted: (query) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => SearchResultsScreenPro(
                                      searchQuery: query,
                                      purchaseService: widget.purchaseService,
                                    ),
                              ),
                            );
                          },
                        )
                        : Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            title: const Text(
                              'Upgrade to Pro to unlock search',
                            ),
                            onTap:
                                () => showUpgradeDialog(
                                  context,
                                  widget.purchaseService,
                                ),
                          ),
                        ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Explore by Family',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        widget.purchaseService.isPro
                            ? IconButton(
                              icon: Icon(
                                isGridView ? Icons.grid_view : Icons.list,
                              ),
                              onPressed: () {
                                setState(() {
                                  isGridView = !isGridView;
                                });
                              },
                            )
                            : GestureDetector(
                              onTap:
                                  () => showUpgradeDialog(
                                    context,
                                    widget.purchaseService,
                                  ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.grid_view,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Pro',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    (isGridView && widget.purchaseService.isPro)
                        ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio:
                                    1.0, // Changed from 1.2 to 1.0 for taller tiles
                              ),
                          itemCount: familyPrefixes.length,
                          itemBuilder: (context, index) {
                            final prefix = familyPrefixes[index];
                            final title = familyTitles[prefix] ?? '';
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ControlFamilyListViewPro(
                                            familyPrefix: prefix,
                                            allControls:
                                                AppDataManager()
                                                    .catalog
                                                    .controls,
                                            purchaseService:
                                                widget.purchaseService,
                                          ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    16.0,
                                  ), // Reduced from 20.0 to 16.0
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blueAccent
                                            .withAlpha((0.15 * 255).round()),
                                        radius: 24, // Reduced from 28 to 24
                                        child: Text(
                                          prefix,
                                          style: const TextStyle(
                                            fontSize:
                                                20, // Reduced from 22 to 20
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ), // Reduced from 16 to 12
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14, // Reduced from 16 to 14
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                        : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: familyPrefixes.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final prefix = familyPrefixes[index];
                            final title = familyTitles[prefix] ?? '';
                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueAccent.withAlpha(
                                    (0.15 * 255).round(),
                                  ),
                                  radius: 24,
                                  child: Text(
                                    prefix,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 20,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ControlFamilyListViewPro(
                                            familyPrefix: prefix,
                                            allControls:
                                                AppDataManager()
                                                    .catalog
                                                    .controls,
                                            purchaseService:
                                                widget.purchaseService,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
