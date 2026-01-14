import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/app_data_manager.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/control_detail_screen_pro.dart';
import 'package:nist_pocket_guide/800-53_screens/pro_screens/enhancement_detail_screen_pro.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/badge_builder.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/favorites_star.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_implmentation_level.dart';
import 'package:nist_pocket_guide/services/utils/upgrade_dialog.dart';

class ControlTile extends StatelessWidget {
  final Control control;
  final PurchaseService purchaseService;

  const ControlTile({
    super.key,
    required this.control,
    required this.purchaseService,
  });

  bool get isEnhancement => control.id.contains('.');

  @override
  Widget build(BuildContext context) {
    // Check if control is withdrawn based on OSCAL status property or title
    final bool isWithdrawn =
        control.props.any(
          (p) => p.name == 'status' && p.value.toLowerCase() == 'withdrawn',
        ) ||
        control.title.toLowerCase().contains('withdrawn');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      clipBehavior: Clip.antiAlias, // Prevent overflow
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          AppDataManager().addRecentControl(control.id);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      isEnhancement
                          ? EnhancementDetailScreenPro(
                            enhancement: control,
                            purchaseService: purchaseService,
                          )
                          : ControlDetailScreenPro(
                            control: control,
                            purchaseService: purchaseService,
                          ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(32), // Capsule shape
                ),
                constraints: const BoxConstraints(
                  minWidth: 64, // Ensures a minimum width for short IDs
                  minHeight: 48, // Consistent height
                ),
                child: Text(
                  isEnhancement
                      ? (() {
                        // Enhancement IDs are like AC-2.1 or AC-2.10
                        final parts = control.id.split('.');
                        if (parts.length == 2) {
                          final base = parts[0].toUpperCase();
                          final enh = parts[1];
                          return '$base($enh)';
                        }
                        return control.id.toUpperCase();
                      })()
                      : control.id.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18, // Consistent font size for all controls
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      control.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Show both badge types with compact spacing
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          // Baseline badges (L, M, H, P)
                          buildSmallBaselineBadgesRow(
                            context,
                            control.baselines,
                          ),
                          if (control.baselines.values.any((v) => v) &&
                              control.props.any(
                                (p) =>
                                    p.name == 'implementation-level' ||
                                    p.name == 'implementation_level',
                              ))
                            const SizedBox(width: 8),
                          // Implementation level chips
                          if (control.props.any(
                            (p) =>
                                p.name == 'implementation-level' ||
                                p.name == 'implementation_level',
                          ))
                            Expanded(
                              child: ImplementationLevelChips(
                                implementationLevelProps:
                                    control.props
                                        .where(
                                          (prop) =>
                                              prop.name ==
                                                  'implementation-level' ||
                                              prop.name ==
                                                  'implementation_level',
                                        )
                                        .toList(),
                                abbreviated:
                                    true, // Use abbreviated mode for control tiles
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isWithdrawn)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade700, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Withdrawn',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                purchaseService.isPro
                    ? FavoriteIconButton(controlId: control.id)
                    : GestureDetector(
                      onTap: () => showUpgradeDialog(context, purchaseService),
                      child: Icon(
                        Icons.star_border,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class NoteControlTile extends StatefulWidget {
  final Control control;
  final PurchaseService purchaseService;

  const NoteControlTile({
    super.key,
    required this.control,
    required this.purchaseService,
  });

  @override
  State<NoteControlTile> createState() => _NoteControlTileState();
}

class _NoteControlTileState extends State<NoteControlTile> {
  late String note;

  @override
  void initState() {
    super.initState();
    note = AppDataManager().notesPerControl[widget.control.id]?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final control = widget.control;
    final isEnhancement = control.id.contains('.');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          AppDataManager().addRecentControl(control.id);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      isEnhancement
                          ? EnhancementDetailScreenPro(
                            enhancement: control,
                            purchaseService: widget.purchaseService,
                          )
                          : ControlDetailScreenPro(
                            control: control,
                            purchaseService: widget.purchaseService,
                          ),
            ),
          );
          if (mounted) {
            setState(() {
              note = AppDataManager().notesPerControl[control.id]?.trim() ?? '';
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_formattedControlId(control.id)}: ${control.title}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  FavoriteIconButton(controlId: control.id),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                note.isEmpty ? 'No notes yet.' : note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              buildSmallBaselineBadgesRow(
                context,
                control.baselines,
                inCustomBaseline: control.inCustomBaseline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formattedControlId(String id) {
    if (id.contains('.')) {
      final parts = id.split('.');
      return '${parts[0].toUpperCase()}(${parts[1]})';
    }
    return id.toUpperCase();
  }
}
