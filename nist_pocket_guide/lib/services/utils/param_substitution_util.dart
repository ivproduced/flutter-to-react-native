// File: lib/widgets/prose_display_utils.dart (or wherever your original function resides)
import 'package:flutter/material.dart';
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:nist_pocket_guide/services/utils/oscal_parameter_resolver.dart';

/// For 800-53 Module: Generates InlineSpans resolving params based on definitions.
List<InlineSpan> build80053TextSpans({
  required BuildContext context,
  required String prose,
  required List<Parameter>
  params, // OSCAL parameter definitions for the control
}) {
  final spans = <InlineSpan>[];
  final paramPattern = RegExp(r'{{\s*insert:\s*param,\s*([\w\-\.]+)\s*}}');
  int lastMatchEnd = 0;

  for (final match in paramPattern.allMatches(prose)) {
    if (match.start > lastMatchEnd) {
      spans.add(TextSpan(text: prose.substring(lastMatchEnd, match.start)));
    }

    final paramId = match.group(1);
    String resolvedText;

    if (paramId != null) {
      resolvedText = OscalParameterResolver.resolveParameterDefinitional(
        paramId,
        params,
      );
    } else {
      resolvedText = match.group(0) ?? '[Invalid Placeholder]';
    }

    spans.add(
      TextSpan(
        text: resolvedText,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontStyle:
              FontStyle.italic, // Added to match control statement section
          color:
              Colors.black, // Changed from Colors.blue.shade700 to Colors.black
        ),
      ),
    );

    lastMatchEnd = match.end;
  }

  if (lastMatchEnd < prose.length) {
    spans.add(TextSpan(text: prose.substring(lastMatchEnd)));
  }
  return spans;
}
