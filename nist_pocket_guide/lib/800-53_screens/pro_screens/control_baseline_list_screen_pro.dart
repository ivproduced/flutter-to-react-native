import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_tile.dart';
import 'package:nist_pocket_guide/models/baseline_profile.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/services/control_search_service.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';

class ControlBaselineListScreenPro extends StatefulWidget {
  final BaselineProfile baseline;
  final PurchaseService purchaseService;

  const ControlBaselineListScreenPro({
    super.key,
    required this.baseline,
    required this.purchaseService,
  });

  @override
  State<ControlBaselineListScreenPro> createState() =>
      _ControlBaselineListScreenProState();
}

class _ControlBaselineListScreenProState
    extends State<ControlBaselineListScreenPro> {
  late List<Control> _baselineControls = [];

  @override
  void initState() {
    super.initState();
    final selectedIds =
        widget.baseline.selectedControlIds.map((e) => e.toLowerCase()).toSet();
    final baseControls = AppDataManager.instance.catalog.controls;
    // Use the search service to filter controls by selectedIds
    final List<Control> matchingControls = [];
    for (final baseControl in baseControls) {
      if (selectedIds.contains(baseControl.id.toLowerCase())) {
        matchingControls.add(baseControl);
      }
      for (final enhancement in baseControl.enhancements) {
        if (selectedIds.contains(enhancement.id.toLowerCase())) {
          matchingControls.add(enhancement);
        }
      }
    }
    matchingControls.sort(
      (a, b) => ControlSearchService.compareControlIds(a.id, b.id),
    );
    _baselineControls = matchingControls;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.baseline.title)),
      body:
          _baselineControls.isEmpty
              ? Center(
                child: Text(
                  'No controls in this baseline.',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
              )
              : Container(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withAlpha((0.02 * 255).round()),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                  itemCount: _baselineControls.length,
                  cacheExtent: 1000.0,
                  itemBuilder: (context, index) {
                    final control = _baselineControls[index];
                    return ControlTile(
                      control: control,
                      purchaseService: widget.purchaseService,
                    );
                  },
                ),
              ),
    );
  }
}
