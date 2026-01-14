import 'package:flutter/material.dart';
import '../../../models/oscal_models.dart'; // make sure this path points to your Parameter class

List<TextSpan> parseProseWithParams(String prose, List<Parameter> params) {
  final paramPattern = RegExp(r'{{\s*insert:\s*param,\s*([\w\-\.]+)\s*}}');
  final spans = <TextSpan>[];
  int lastMatchEnd = 0;

  for (final match in paramPattern.allMatches(prose)) {
    if (match.start > lastMatchEnd) {
      spans.add(TextSpan(
        text: prose.substring(lastMatchEnd, match.start),
        style: const TextStyle(fontWeight: FontWeight.normal),
      ));
    }
    
    final paramId = match.group(1);
    final param = findParamById(paramId!, params);

if (param != null && param.values.isNotEmpty) {
  final resolvedValue = param.values.first;
  final subSpans = parseProseWithParams(resolvedValue, params);
  spans.addAll(subSpans.map((s) => TextSpan(
    text: s.text,
    style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
  )));
} else {
  spans.add(const TextSpan(
    text: '[Unknown Param]',
    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
  ));
}


    lastMatchEnd = match.end;
  }

  if (lastMatchEnd < prose.length) {
    spans.add(TextSpan(
      text: prose.substring(lastMatchEnd),
      style: const TextStyle(fontWeight: FontWeight.normal),
    ));
  }

  return spans;
}
// Finds a Parameter by ID safely. Returns null if not found.
Parameter? findParamById(String id, List<Parameter> params) {
  for (final param in params) {
    if (param.id == id) {
      return param;
    }
  }
  return null;
}
