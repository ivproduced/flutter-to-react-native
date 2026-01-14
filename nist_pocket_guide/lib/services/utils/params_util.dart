import 'dart:collection'; // needed for Queue
import 'package:nist_pocket_guide/models/oscal_models.dart';
import 'package:flutter/foundation.dart';

List<Parameter> expandParams(List<Parameter> baseParams) {
  final Map<String, Parameter> paramMap = { for (var p in baseParams) p.id : p };
  final Set<String> visited = Set<String>.from(paramMap.keys);

  final Queue<String> toVisit = Queue<String>();
  toVisit.addAll(paramMap.keys);

  while (toVisit.isNotEmpty) {
    final currentId = toVisit.removeFirst();
    final currentParam = paramMap[currentId];

    if (currentParam == null) continue;

    final aggregates = currentParam.props
        .where((prop) => prop.name == 'aggregates')
        .map((prop) => prop.value);

    for (final aggId in aggregates) {
      if (!visited.contains(aggId)) {
        final aggregateCandidates = baseParams.where(
          (p) => p.id == aggId || p.props.any((prop) => prop.name == 'alt-identifier' && prop.value == aggId),    
          );

        final aggregateParam = aggregateCandidates.isNotEmpty ? aggregateCandidates.first : null;

        if (aggregateParam != null) {
          paramMap[aggregateParam.id] = aggregateParam;
          visited.add(aggregateParam.id);
          toVisit.add(aggregateParam.id);
        } else {
          debugPrint('❗ Missing aggregated param: $aggId');
        }
      }
    }
  }

  return paramMap.values.toList();
}
