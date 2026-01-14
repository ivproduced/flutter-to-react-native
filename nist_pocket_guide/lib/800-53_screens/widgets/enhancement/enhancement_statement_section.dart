// --- widgets/enhancement/enhancement_statement_section.dart ---

import 'package:flutter/material.dart';
import '../../../models/oscal_models.dart';
import '../../../services/utils/param_substitution_util.dart';

class EnhancementStatementSection extends StatelessWidget {
  final List<Part> parts;
  final List<Parameter> params;

  const EnhancementStatementSection({
    super.key,
    required this.parts,
    required this.params,
  });

  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }

    final Part statementPart;
    try {
      statementPart = parts.firstWhere(
        (p) => p.name.toLowerCase() == 'statement',
      );
    } catch (e) {
      return const SizedBox.shrink();
    }

    // --- MODIFIED NULL CHECKS FOR PROSE ---
    final String currentProse =
        statementPart.prose ?? ""; // Default to empty string if null

    // If prose is effectively empty AND there are no subparts, don't render anything.
    if (currentProse.isEmpty && statementPart.subparts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enhancement Statement',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Only build if prose is not empty
        if (currentProse.isNotEmpty) // Use the non-nullable currentProse
          _buildRichText(
            context,
            currentProse,
          ), // Pass the non-nullable currentProse
        // If there was prose AND subparts, add some space
        if (currentProse.isNotEmpty && statementPart.subparts.isNotEmpty)
          const SizedBox(height: 12),

        ...statementPart.subparts.map(
          (subpart) => Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8),
            // --- PROVIDE DEFAULT FOR SUBPART.PROSE ---
            child: _buildRichText(
              context,
              subpart.prose ?? "", // Default to empty string if null
              partLabel: _getLabel(subpart),
              // baseIndent: 16, // baseIndent not used in current _buildRichText
            ),
          ),
        ),
      ],
    );
  }

  // textContent parameter is now non-nullable String
  Widget _buildRichText(
    BuildContext context,
    String textContent, {
    String? partLabel /*, double baseIndent = 0*/,
  }) {
    final hasLabel = partLabel != null && partLabel.isNotEmpty;
    final spans = <InlineSpan>[];

    if (hasLabel) {
      spans.add(
        TextSpan(
          text: '$partLabel ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    // substituteParamsIntoTextSpans expects a non-nullable String, which textContent now is
    spans.addAll(
      build80053TextSpans(
        context: context, // Named argument
        prose: textContent, // Named argument
        params: params, // Named argument
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: hasLabel ? 4.0 : 8.0),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: Colors.black, // Consistent with control statement section
          ),
          children: spans,
        ),
      ),
    );
  }

  String _getLabel(Part part) {
    try {
      final labelProp = part.props.firstWhere(
        (p) => p.name.toLowerCase() == 'label',
      );
      return labelProp.value.trim();
    } catch (e) {
      return '';
    }
  }
}
