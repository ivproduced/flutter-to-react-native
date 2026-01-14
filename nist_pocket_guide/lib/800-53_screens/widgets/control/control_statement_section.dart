// --- widgets/control/control_statement_section.dart ---


import 'package:flutter/material.dart';
import '../../../models/oscal_models.dart'; // Assuming Prop, Parameter, Part models are here

// Helper enum and class moved outside ControlStatementSection
enum _MatchType { parameter, link }

class _MatchInfo {
  final Match match;
  final _MatchType type;
  _MatchInfo(this.match, this.type);
}

class ControlStatementSection extends StatelessWidget {
  final List<Part> parts;
  final List<Parameter> params;

  const ControlStatementSection({
    super.key,
    required this.parts,
    required this.params,
  });

 static String replaceParamsInString(String text, List<Parameter> params) {
    final paramPattern = RegExp(r'{{\s*insert:\s*param,\s*([\w\-\.]+)\s*}}');
    return text.replaceAllMapped(paramPattern, (match) {
      final paramId = match.group(1);
      if (paramId != null) {
        return resolveParam(paramId, params);
      }
      return ''; // Should not happen if regex matches
    });
  }
  static  String resolveParam(String paramId, List<Parameter> params) {
    final param = findParamById(paramId, params);

    if (param == null) {
      debugPrint('❗ Missing param for ID: $paramId');
      return '[Unknown Param: $paramId]'; // Provide paramId for better debugging
    }

    // Optional: Add check for referral prop if you implement Scenario 2 for parameter substitution
    // final referralProp = param.props.firstWhere(...)
    // if (referralProp.value.isNotEmpty) { return _resolveParam(referralProp.value, params); }


    final aggregates = param.props
        .where((prop) => prop.name == 'aggregates')
        .map((prop) => prop.value)
        .toList();

    if (aggregates.isNotEmpty) {
      final resolvedAggregates = aggregates
          .map((aggId) => resolveParam(aggId, params))
          .toList();
      final finalAggregates = deduplicateAndMergeSecurityPrivacy(resolvedAggregates);
      return finalAggregates.join(', ');
    }

    if (param.select != null && param.select!.choice.isNotEmpty) {
      final processedChoices = param.select!.choice
          .map((choice) => replaceParamsInString(choice, params))
          .toList();
      final finalChoices = deduplicateAndMergeSecurityPrivacy(processedChoices);
      return formatChoices(finalChoices);
    }

    if (param.label != null && param.label!.isNotEmpty) {
      // NIST OSCAL Guide: "For ODPs that do not have predefined selections (i.e., select is empty),
      // the label field contains human-readable text of what the organization is to define."
      // The "Organization-defined" prefix is often part of the label itself in well-formed ODPs,
      // or it's handled by how the label is constructed in the source OSCAL data.
      // Your original logic for _odp. seems specific; ensure it aligns with your OSCAL source.
      if (param.id.contains('_odp') && (param.select == null || param.select!.choice.isEmpty)) {
         return 'Organization-defined ${param.label!}'; // This prepends "Organization-defined"
      } else {
         return param.label!;
      }
    }

    if (param.values.isNotEmpty) {
      return param.values.first;
    }

    debugPrint('❗ Parameter has no resolvable content (aggregates, select, label, or values): $paramId');
    return '[Param $paramId not fully defined]';
  }


  @override
  Widget build(BuildContext context) {
    if (parts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Control Statement",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...parts.map((p) => _buildPart(context, p)),
      ],
    );
  }

  Widget _buildPart(BuildContext context, Part part, {double baseIndent = 0}) {
    final String label = part.props
        .firstWhere((p) => p.name == 'label', orElse: () => Prop(name: '', value: ''))
        .value;
    final bool hasLabel = label.isNotEmpty;
    final String proseContent = part.prose ?? part.title ?? '';


    final List<TextSpan> proseSpans = replaceParamsAsTextSpans(proseContent, params, context);

    Widget currentPartDisplay;

    if (hasLabel) {
      // Use a Row to achieve the hanging indent effect.
      // The label is the first child, and the prose (in an Expanded RichText) is the second.
      currentPartDisplay = Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns items to the top if they have different heights
        children: <Widget>[
          Text(
            '$label ', // e.g., "a. " (includes a trailing space for separation)
            style: const TextStyle( // Style for the label (e.g., "a.")
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic, // As per your original label styling
              color: Colors.black,
            ),
          ),
          Expanded( // The prose takes up the remaining horizontal space
            child: RichText(
              text: TextSpan(
                // Base style for the prose.
                // Styles from proseSpans (for parameters/references) will override parts of this.
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black),
                children: proseSpans,
              ),
            ),
          ),
        ],
      );
    } else {
      // If there's no label, just display the prose.
      // It will align to the current baseIndent due to the outer Padding.
      currentPartDisplay = RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black),
          children: proseSpans,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: baseIndent, bottom: 8.0), // Overall indent for this part
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          currentPartDisplay, // This is now the Row (label + prose) or just prose
          // Subparts are handled recursively and will also use this _buildPart logic.
          // Their baseIndent will be increased, achieving further indentation.
          ...part.subparts.map((subpart) => _buildPart(
                context,
                subpart,
                // The indent for sub-levels is increased relative to the current part's indent
                baseIndent: baseIndent + 16.0, 
              )),
        ],
      ),
    );
  }


  // --- Private helper functions ---

  static Parameter? findParamById(String id, List<Parameter> params) {
    for (final param in params) {
      if (param.id == id) {
        return param;
      }
      // Assuming 'alt-identifier' is a valid way to find params.
      // Consider if 'alt-identifier' should be unique or if multiple params can have the same.
      for (final prop in param.props) {
        if (prop.name == 'alt-identifier' && prop.value == id) {
          return param;
        }
      }
    }
    return null;
  }

 
static List<TextSpan> replaceParamsAsTextSpans(String prose, List<Parameter> params, BuildContext context) {
  final spans = <TextSpan>[];
  final paramPattern = RegExp(r'{{\s*insert:\s*param,\s*([\w\-\.]+)\s*}}');
  // Pattern for links like [display text](#target-id)
  final linkPattern = RegExp(r'\[([^\]]+?)\]\((#[\w\-\.\/]+?)\)');

  List<_MatchInfo> allMatches = [];
  paramPattern.allMatches(prose).forEach((match) {
    allMatches.add(_MatchInfo(match, _MatchType.parameter));
  });
  linkPattern.allMatches(prose).forEach((match) {
    allMatches.add(_MatchInfo(match, _MatchType.link));
  });

  allMatches.sort((a, b) => a.match.start.compareTo(b.match.start));

  int lastMatchEnd = 0;

  for (final matchInfo in allMatches) {
    final match = matchInfo.match;
    if (match.start > lastMatchEnd) {
      spans.add(TextSpan(
        text: prose.substring(lastMatchEnd, match.start),
        // Default style inherited from RichText's TextSpan in _buildPart
      ));
    }

    if (matchInfo.type == _MatchType.parameter) {
      final paramId = match.group(1);
      if (paramId != null) {
        final resolved = resolveParam(paramId, params);
        spans.add(TextSpan(
          text: resolved,
          style: const TextStyle( // Parameters: bold and italic
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            // Color will be inherited (should be black by default from parent style)
          ),
        ));
      }
    } else if (matchInfo.type == _MatchType.link) {
      // This is where the change is:
      final displayText = match.group(1); // This is the text like "AU-2a"

      if (displayText != null) {
        spans.add(TextSpan(
          text: displayText, // Show only the display text part of the link
          style: const TextStyle( // References: just bold (and black by inheritance)
            fontWeight: FontWeight.bold,
            // Color will be inherited (should be black by default from parent style in _buildPart)
            // No decoration (underline)
          ),
          // No recognizer, so it's not tappable
        ));
      }
    }
    lastMatchEnd = match.end;
  }

  if (lastMatchEnd < prose.length) {
    spans.add(TextSpan(
      text: prose.substring(lastMatchEnd),
    ));
  }
  return spans;
}

 

 static String formatChoices(List<String> choices) {
    if (choices.isEmpty) return '';
    if (choices.length == 1) return choices.first;
    if (choices.length == 2) return '${choices[0]} or ${choices[1]}';
    return '${choices.sublist(0, choices.length - 1).join(', ')}, or ${choices.last}';
  }

 static List<String> deduplicateAndMergeSecurityPrivacy(List<String> inputs) {
    // Simplified deduplication, consider if case sensitivity is important
    final uniqueInputs = inputs.toSet().toList();
    
    // The security and privacy merging logic seems specific.
    // Ensure it behaves as expected with various inputs.
    final lowerInputs = uniqueInputs.map((e) => e.toLowerCase()).toList();
    bool hasSecurity = lowerInputs.any((text) => text.contains('security'));
    bool hasPrivacy = lowerInputs.any((text) => text.contains('privacy'));

    List<String> result = [];
    bool mergedTermAdded = false;

    if (hasSecurity && hasPrivacy) {
      // Preference to add merged term first if both are present
      result.add('organization-defined security and privacy attributes');
      mergedTermAdded = true;
    }

    for (final text in uniqueInputs) {
      final lower = text.toLowerCase();
      if (mergedTermAdded && (lower.contains('security') || lower.contains('privacy'))) {
        // If merged term was added, skip individual security/privacy terms
        continue;
      }
      result.add(text);
    }
    // If the result is just the merged term, or if no merge happened, this is fine.
    // If only one of security/privacy was present, it will be included.
    return result.toSet().toList(); // Final deduplication
  }
}