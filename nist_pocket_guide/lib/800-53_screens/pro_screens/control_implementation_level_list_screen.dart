import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/services/purchase_service.dart';
import 'package:nist_pocket_guide/800-53_screens/widgets/control/control_tile.dart';

class ControlsByImplementationLevelScreen extends StatelessWidget {
  final List<Control> allControls;
  final PurchaseService purchaseService;

  const ControlsByImplementationLevelScreen({
    super.key,
    required this.allControls,
    required this.purchaseService,
  });

  @override
  Widget build(BuildContext context) {
    // Group controls by implementation level
    final Map<String, List<Control>> grouped = {};
    for (final control in allControls) {
      final level =
          control.props
              .firstWhere(
                (p) => p.name == 'implementation-level',
                orElse: () => Prop(name: '', value: 'Unspecified'),
              )
              .value;
      grouped.putIfAbsent(level, () => []).add(control);
    }

    // Define fixed order: Org, System, Org & System
    final orgControls = grouped['organization'] ?? [];
    final sysControls = grouped['system'] ?? [];
    // Controls with both organization and system levels
    final bothControls =
        allControls.where((c) {
          final props = c.props.map((p) => p.value.toLowerCase()).toSet();
          return props.contains('organization') && props.contains('system');
        }).toList();
    final entries = [
      {'Organization': orgControls},
      {'System': sysControls},
      {'Organization & System': bothControls},
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Controls by Implementation Level',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final label = entries[index].keys.first;
            final controlsList = entries[index][label]!;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
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
                  child: const Icon(
                    Icons.account_tree,
                    size: 24,
                    color: Colors.blueAccent,
                  ),
                ),
                title: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: Colors.grey,
                ),
                onTap:
                    controlsList.isEmpty
                        ? null
                        : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => _ImplementationLevelControlsListScreen(
                                  level: label,
                                  controls: controlsList,
                                  purchaseService: purchaseService,
                                ),
                          ),
                        ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ImplementationLevelControlsListScreen extends StatelessWidget {
  final String level;
  final List<Control> controls;
  final PurchaseService purchaseService;

  const _ImplementationLevelControlsListScreen({
    required this.level,
    required this.controls,
    required this.purchaseService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Implementation Level: $level',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controls.length,
        itemBuilder: (context, index) {
          return ControlTile(
            control: controls[index],
            purchaseService: purchaseService,
          );
        },
      ),
    );
  }
}
