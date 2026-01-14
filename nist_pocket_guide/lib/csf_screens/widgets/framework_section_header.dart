import 'package:flutter/material.dart';
import '../../models/csf_models.dart';

/// Collapsible section header for each framework
class FrameworkSectionHeader extends StatelessWidget {
  final FrameworkType framework;
  final int controlCount;
  final bool isExpanded;
  final VoidCallback onToggle;
  
  const FrameworkSectionHeader({
    super.key,
    required this.framework,
    required this.controlCount,
    required this.isExpanded,
    required this.onToggle,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: framework.lightColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: framework.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(framework.icon, size: 20, color: framework.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                framework.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: framework.primaryColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: framework.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$controlCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: framework.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
