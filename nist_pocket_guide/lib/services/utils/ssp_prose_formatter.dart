// File: lib/ssp_generator_screens/utils/ssp_prose_formatter.dart
import 'package:flutter/material.dart';
import '../../models/oscal_models.dart';
import '../../services/utils/oscal_parameter_resolver.dart'; // Import the resolver
/// For SSP Module: Generates InlineSpans, prioritizing user values,
/// then falling back to definitional resolution.
List<InlineSpan> buildSspTextSpans({
  required BuildContext context,
  required String prose,
  required List<Parameter> definitionalParams, // OSCAL parameter definitions
  required Map<String, String> userParameterValues, // User-provided values
}) {
  final spans = <InlineSpan>[];
  final paramPattern = RegExp(r'{{\s*insert:\s*param,\s*([\w\-\.]+)\s*}}');
  int lastMatchEnd = 0;

  for (final match in paramPattern.allMatches(prose)) {
    if (match.start > lastMatchEnd) {
      spans.add(TextSpan(
        text: prose.substring(lastMatchEnd, match.start),
      ));
    }

    final paramId = match.group(1);
    String resolvedText;
    bool isUserProvided = false;

    if (paramId != null && userParameterValues.containsKey(paramId)) {
      final userValue = userParameterValues[paramId];
      if (userValue != null && userValue.isNotEmpty) {
        resolvedText = userValue;
        isUserProvided = true;
      } else {
        // User provided an empty value, or map contains an empty string
        resolvedText = '[$paramId value not provided]';
        // Or, if you prefer to fall back if user value is empty:
        // resolvedText = OscalParameterResolver.resolveParameterDefinitional(paramId, definitionalParams);
      }
    } else if (paramId != null) {
      // Fallback to definitional resolution if no user value
      resolvedText = OscalParameterResolver.resolveParameterDefinitional(paramId, definitionalParams);
    } else {
      resolvedText = match.group(0) ?? '[Invalid Placeholder]';
    }

    spans.add(TextSpan(
      text: resolvedText,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isUserProvided ? Colors.green.shade700 : Colors.blue.shade700, // Differentiate style
      ),
    ));
    lastMatchEnd = match.end;
  }

  if (lastMatchEnd < prose.length) {
    spans.add(TextSpan(
      text: prose.substring(lastMatchEnd),
    ));
  }
  return spans;
}