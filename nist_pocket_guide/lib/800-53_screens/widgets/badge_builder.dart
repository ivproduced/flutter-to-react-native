import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';

// 🔵 SMALL Badges for Control Family Lists
Widget buildSmallBaselineBadgesRow(
  BuildContext context,
  Map<String, bool> baselines, {
  bool inCustomBaseline = false,
}) {
  final baselineBadges = [
    {'key': 'LOW', 'label': 'L', 'color': Colors.green},
    {'key': 'MODERATE', 'label': 'M', 'color': Colors.orange},
    {'key': 'HIGH', 'label': 'H', 'color': Colors.red},
    {'key': 'PRIVACY', 'label': 'P', 'color': Colors.purple},
  ];

  return Wrap(
    spacing: 2.0,
    runSpacing: 2.0,
    children: [
      ...baselineBadges
          .where((badge) => baselines[badge['key']] == true)
          .map(
            (badge) => _buildSmallBadge(
              badge['label'] as String,
              badge['color'] as Color,
            ),
          ),
      if (inCustomBaseline) _buildSmallBadge('C', Colors.blueGrey),
    ],
  );
}

// Helper: Large Badge Builder
Widget _buildLargeBadge(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// Helper: Small Badge Builder
Widget _buildSmallBadge(String label, Color color) {
  return Container(
    margin: const EdgeInsets.only(left: 2),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

// 🔵 LARGE Badges for Statement / Detail Screens
Widget buildLargeBaselineBadgesRow(
  BuildContext context,
  Map<String, bool> baselines,
  Control control,
) {
  final baselineBadges = [
    {'key': 'LOW', 'label': 'LOW', 'color': Colors.green},
    {'key': 'MODERATE', 'label': 'MODERATE', 'color': Colors.orange},
    {'key': 'HIGH', 'label': 'HIGH', 'color': Colors.red},
    {'key': 'PRIVACY', 'label': 'PRIVACY', 'color': Colors.purple},
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children:
            baselineBadges
                .where((badge) => baselines[badge['key']] == true)
                .map(
                  (badge) => _buildLargeBadge(
                    badge['label'] as String,
                    badge['color'] as Color,
                  ),
                )
                .toList(),
      ),
    ],
  );
}
