import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/baseline_profile.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/custom_baseline_builder_screen.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/control_baseline_list_screen_pro.dart';
import 'package:nist_pocket_guide/services/baseline_mananger.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/services/utils/upgrade_dialog.dart';

class ControlBaselineScreenPro extends StatefulWidget {
  final PurchaseService purchaseService;

  const ControlBaselineScreenPro({super.key, required this.purchaseService});

  @override
  State<ControlBaselineScreenPro> createState() =>
      _ControlBaselineScreenProState();
}

class _ControlBaselineScreenProState extends State<ControlBaselineScreenPro> {
  late List<BaselineProfile> availableBaselines;

  @override
  void initState() {
    super.initState();
    availableBaselines = [
      AppDataManager.instance.lowBaseline,
      AppDataManager.instance.moderateBaseline,
      AppDataManager.instance.highBaseline,
      AppDataManager.instance.privacyBaseline,
      ...AppDataManager.instance.userBaselines,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Controls by Baseline')),
      body:
          availableBaselines.isEmpty
              ? Center(
                child: Text(
                  'No baselines found.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 20,
                ),
                itemCount: availableBaselines.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final baseline = availableBaselines[index];
                  final isCustom = AppDataManager.instance.userBaselines.any(
                    (b) => b.id.toLowerCase() == baseline.id.toLowerCase(),
                  );
                  final accentColor =
                      isCustom
                          ? Colors.blueGrey.shade200
                          : _getBaselineAccentColor(baseline.id);
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 6,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                bottomLeft: Radius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          title: Text(
                            baseline.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            baseline.id,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                          onTap: () => _handleTap(baseline),
                          trailing:
                              isCustom
                                  ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 22),
                                        tooltip: 'Edit',
                                        onPressed:
                                            widget.purchaseService.isPro
                                                ? () => _handleEdit(baseline)
                                                : () => showUpgradeDialog(
                                                  context,
                                                  widget.purchaseService,
                                                ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 22,
                                        ),
                                        tooltip: 'Delete',
                                        onPressed:
                                            widget.purchaseService.isPro
                                                ? () => _confirmDeleteBaseline(
                                                  baseline,
                                                )
                                                : () => showUpgradeDialog(
                                                  context,
                                                  widget.purchaseService,
                                                ),
                                      ),
                                    ],
                                  )
                                  : null,
                        ),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Feature gate: Custom baseline creation is Pro-only
          if (!widget.purchaseService.isPro) {
            showUpgradeDialog(context, widget.purchaseService);
            return;
          }

          final changed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CustomBaselineBuilderScreen(),
            ),
          );
          if (changed == true && context.mounted) {
            await AppDataManager.instance.initialize();
            setState(() {
              availableBaselines = [
                AppDataManager.instance.lowBaseline,
                AppDataManager.instance.moderateBaseline,
                AppDataManager.instance.highBaseline,
                AppDataManager.instance.privacyBaseline,
                ...AppDataManager.instance.userBaselines,
              ];
            });
          }
        },
        icon: const Icon(Icons.add),
        label: Text(
          widget.purchaseService.isPro ? 'New Overlay' : 'New Overlay (Pro)',
        ),
        backgroundColor:
            widget.purchaseService.isPro
                ? theme.colorScheme.primary
                : Colors.grey.shade400,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
    );
  }

  Color _getBaselineAccentColor(String id) {
    switch (id.toLowerCase()) {
      case 'low':
        return Colors.green.shade300;
      case 'moderate':
        return Colors.orange.shade300;
      case 'high':
        return Colors.red.shade300;
      case 'privacy':
        return Colors.purple.shade300;
      default:
        return Colors.blueAccent.withAlpha((0.15 * 255).round());
    }
  }

  Future<void> _handleTap(BaselineProfile baseline) async {
    await AppDataManager.instance.initialize();
    if (!mounted) return;
    final updated = AppDataManager.instance.userBaselines.firstWhere(
      (b) => b.id == baseline.id,
      orElse: () => baseline,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ControlBaselineListScreenPro(
              baseline: updated,
              purchaseService: widget.purchaseService,
            ),
      ),
    );
  }

  Future<void> _handleEdit(BaselineProfile baseline) async {
    await AppDataManager.instance.initialize();
    if (!mounted) return;
    final updated = AppDataManager.instance.userBaselines.firstWhere(
      (b) => b.id == baseline.id,
      orElse: () => baseline,
    );
    if (!mounted) return;
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => CustomBaselineBuilderScreen(
              key: ValueKey(updated.id),
              existingBaseline: updated,
            ),
      ),
    );

    if (changed == true && mounted) {
      await AppDataManager.instance.initialize();
      if (!mounted) return;
      setState(() {
        availableBaselines = [
          AppDataManager.instance.lowBaseline,
          AppDataManager.instance.moderateBaseline,
          AppDataManager.instance.highBaseline,
          AppDataManager.instance.privacyBaseline,
          ...AppDataManager.instance.userBaselines,
        ];
      });
    }
  }

  void _confirmDeleteBaseline(BaselineProfile baseline) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Baseline?'),
            content: Text(
              'Are you sure you want to delete "${baseline.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    await BaselineManager.deleteUserBaseline(baseline.id);
    await AppDataManager.instance.initialize();

    if (!mounted) return;
    setState(() {
      availableBaselines = [
        AppDataManager.instance.lowBaseline,
        AppDataManager.instance.moderateBaseline,
        AppDataManager.instance.highBaseline,
        AppDataManager.instance.privacyBaseline,
        ...AppDataManager.instance.userBaselines,
      ];
    });
  }
}
