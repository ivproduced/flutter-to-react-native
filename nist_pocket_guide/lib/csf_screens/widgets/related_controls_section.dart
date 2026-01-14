import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/csf_models.dart';
import '../../models/csf_crosswalk_mappings.dart';
import '../../services/purchase_service.dart';
import '../../800-53_screens/services/nist_route_service.dart';
import '../../sp800_171_screens/services/sp800_171_route_service.dart';
import 'control_chip.dart';
import 'framework_section_header.dart';

/// Main widget for displaying cross-framework control mappings
class RelatedControlsSection extends StatefulWidget {
  final CsfSubcategory subcategory;

  const RelatedControlsSection({
    super.key,
    required this.subcategory,
  });

  @override
  State<RelatedControlsSection> createState() => _RelatedControlsSectionState();
}

class _RelatedControlsSectionState extends State<RelatedControlsSection> {
  bool _is80053Expanded = true;
  bool _is800171Expanded = false;

  @override
  Widget build(BuildContext context) {
    final purchaseService = Provider.of<PurchaseService>(context, listen: false);
    final has80053 = widget.subcategory.related80053Controls.isNotEmpty;
    final has800171 = widget.subcategory.related800171Controls.isNotEmpty;

    // Debug output
    debugPrint('🔍 CSF Subcategory: ${widget.subcategory.id}');
    debugPrint('   800-53 controls: ${widget.subcategory.related80053Controls}');
    debugPrint('   800-171 controls: ${widget.subcategory.related800171Controls}');
    debugPrint('   has80053: $has80053, has800171: $has800171');

    if (!has80053 && !has800171) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.compare_arrows,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Related Framework Controls',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),

        // 800-53 Section
        if (has80053) ...[
          FrameworkSectionHeader(
            framework: FrameworkType.sp80053,
            controlCount: widget.subcategory.related80053Controls.length,
            isExpanded: _is80053Expanded,
            onToggle: () => setState(() => _is80053Expanded = !_is80053Expanded),
          ),
          if (_is80053Expanded) ...[
            const SizedBox(height: 10),
            _buildControlChips(
              context,
              widget.subcategory.related80053Controls,
              FrameworkType.sp80053,
              purchaseService,
            ),
          ],
          const SizedBox(height: 12),
        ],

        // 800-171 Section
        if (has800171) ...[
          FrameworkSectionHeader(
            framework: FrameworkType.sp800171,
            controlCount: widget.subcategory.related800171Controls.length,
            isExpanded: _is800171Expanded,
            onToggle: () => setState(() => _is800171Expanded = !_is800171Expanded),
          ),
          if (_is800171Expanded) ...[
            const SizedBox(height: 10),
            _buildControlChips(
              context,
              widget.subcategory.related800171Controls,
              FrameworkType.sp800171,
              purchaseService,
            ),
          ],
        ],

        // Upgrade prompt for free users
        if (!purchaseService.isPro) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upgrade to Pro to navigate to control details',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildControlChips(
    BuildContext context,
    List<String> controlIds,
    FrameworkType framework,
    PurchaseService purchaseService,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: controlIds.map((controlId) {
        // Get title for 800-171 controls from mappings
        final title = framework == FrameworkType.sp800171
            ? sp800171ControlTitles[controlId]
            : null;

        return ControlChip(
          controlId: controlId.toUpperCase(),
          title: title,
          framework: framework,
          isPro: purchaseService.isPro,
          onTap: purchaseService.isPro
              ? () => _navigateToControl(context, controlId, framework, purchaseService)
              : null,
        );
      }).toList(),
    );
  }

  void _navigateToControl(
    BuildContext context,
    String controlId,
    FrameworkType framework,
    PurchaseService purchaseService,
  ) {
    if (framework == FrameworkType.sp80053) {
      NistRouteService.navigateToControlDetailById(
        context,
        controlId: controlId,
        purchaseService: purchaseService,
        returnRoute: '/csf-category-detail',
        returnLabel: widget.subcategory.subcategoryId,
      );
    } else if (framework == FrameworkType.sp800171) {
      Sp800171RouteService.navigateToRequirementDetailById(
        context,
        requirementId: controlId,
        returnRoute: '/csf-category-detail',
        returnLabel: widget.subcategory.subcategoryId,
      );
    }
  }
}
