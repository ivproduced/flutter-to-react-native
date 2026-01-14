import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';

class ImplementationLevelChips extends StatelessWidget {
  final List<Prop> implementationLevelProps;
  final bool abbreviated;

  const ImplementationLevelChips({
    super.key,
    required this.implementationLevelProps,
    this.abbreviated = false,
  });

  @override
  Widget build(BuildContext context) {
    if (implementationLevelProps.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < implementationLevelProps.length; i++) ...[
          if (i > 0) const SizedBox(width: 4.0), // Add spacing between chips
          Flexible(
            child: Chip(
              label: Text(
                abbreviated
                    ? _abbreviateLevel(implementationLevelProps[i].value)
                    : implementationLevelProps[i].value,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
              avatar: const Icon(
                Icons.account_tree,
                size: 12,
                color: Colors.blueGrey,
              ),
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
            ),
          ),
        ],
      ],
    );
  }

  String _abbreviateLevel(String value) {
    final lower = value.toLowerCase();
    // Super compact single letter abbreviations for control tiles
    if (lower.contains('organization')) return 'O';
    if (lower.contains('system')) return 'S';
    // For any other values, return the original text (no made-up abbreviations)
    return value;
  }
}
