// --- widgets/control/guidance_section.dart ---

import 'package:flutter/material.dart';

class GuidanceSection extends StatefulWidget {
  final String? guidanceText;

  const GuidanceSection({super.key, required this.guidanceText});

  @override
  State<GuidanceSection> createState() => _GuidanceSectionState();
}

class _GuidanceSectionState extends State<GuidanceSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.guidanceText == null || widget.guidanceText!.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpansionTile(
      title: Text(
        "NIST Guidance",
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.guidanceText!,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
