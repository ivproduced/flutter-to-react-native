// File: lib/services/utils/oscal_parameter_resolver.dart
import 'package:flutter/material.dart'; // For debugPrint, or use a logger
import '../../models/oscal_models.dart'; // Ensure this path is correct
import 'package:flutter/foundation.dart';

class OscalParameterResolver {
  static Parameter? _findParamById(String id, List<Parameter> params) {
    for (final param in params) {
      if (param.id == id) {
        return param;
      }
      // Assuming 'props' is List<Prop>? and Prop has 'name' and 'value'
      for (final prop in param.props) {
        if (prop.name == 'alt-identifier' && prop.value == id) {
          return param;
        }
      }
    }
    return null;
  }

  static String _replaceParamsInString(
      String text, List<Parameter> params) {
    final paramPattern = RegExp(r'{{\s*insert:\s*param,\s*([\w\-\.]+)\s*}}');
    return text.replaceAllMapped(paramPattern, (match) {
      final paramId = match.group(1);
      if (paramId != null) {
        // Recursively resolve parameters found within parameter values (e.g., in choices)
        return resolveParameterDefinitional(paramId, params);
      }
      return match.group(0) ?? '';
    });
  }

  static String _formatChoices(List<String> choices) {
    if (choices.isEmpty) {
      return '[No choices available]';
    }
    if (choices.length == 1) {
      return choices.first;
    } else if (choices.length == 2) {
      return '${choices[0]} or ${choices[1]}';
    } else {
      return '${choices.sublist(0, choices.length - 1).join(', ')}, or ${choices.last}';
    }
  }

  static List<String> _deduplicateAndMergeSecurityPrivacy(List<String> inputs) {
    // Using a Set for efficient addition and deduplication (case-insensitive)
    final lowerInputs = inputs.map((e) => e.toLowerCase()).toList();
    bool hasSecurity = lowerInputs.any((text) => text.contains('security'));
    bool hasPrivacy = lowerInputs.any((text) => text.contains('privacy'));

    final uniqueTexts = <String>{};
    final result = <String>[];

    for (final text in inputs) {
        final lowerText = text.toLowerCase();
        // Complex merging logic for "security" and "privacy" might need to be adjusted
        // based on very specific requirements. This is a simplified interpretation.
        if (hasSecurity && hasPrivacy) {
            // If both are present globally, we might want to skip adding individual "security" or "privacy"
            // if the intent is to replace them with a combined term.
            if (lowerText == "security" || lowerText == "privacy") {
                continue; 
            }
        }
        if (uniqueTexts.add(lowerText)) {
            result.add(text);
        }
    }

    if (hasSecurity && hasPrivacy) {
        // Ensure the combined term is added if not already present in a similar form
        const combinedTerm = 'organization-defined security and privacy attributes';
        if (uniqueTexts.add(combinedTerm.toLowerCase())) {
             // Remove any less specific individual terms if the combined one is preferred
            result.removeWhere((t) => t.toLowerCase() == "security" || t.toLowerCase() == "privacy");
            result.add(combinedTerm);
        }
    }
    return result;
  }

  /// Resolves a parameter based on its OSCAL definition.
  /// This is for displaying the parameter's label, choices, or other definitional text.
  static String resolveParameterDefinitional(
      String paramId, List<Parameter> params) {
    final param = _findParamById(paramId, params);

    if (param == null) {
      debugPrint('❗ [Resolver] Missing param for ID: $paramId');
      return '[Unknown Param: $paramId]';
    }

    final aggregates = param.props
            .where((prop) => prop.name == 'aggregates')
            .map((prop) => prop.value) // Assuming Prop.value is String
            .toList();

    if (aggregates.isNotEmpty) {
      final resolvedAggregates = aggregates
          .map((aggId) => resolveParameterDefinitional(aggId, params))
          .toList();
      final finalAggregates =
          _deduplicateAndMergeSecurityPrivacy(resolvedAggregates);
      return finalAggregates.join(', ');
    }

    if (param.select != null && param.select!.choice.isNotEmpty) {
      final processedChoices = param.select!.choice
          .map((choice) =>
              _replaceParamsInString(choice, params)) // Assuming Choice.value is String
          .toList();
      final finalChoices =
          _deduplicateAndMergeSecurityPrivacy(processedChoices);
      return _formatChoices(finalChoices);
    }

    if (param.label != null && param.label!.isNotEmpty) {
      if (param.id.contains('_odp.') &&
          (param.select == null || param.select!.choice.isEmpty)) {
        return 'Organization-defined ${param.label!}';
      } else {
        return param.label!;
      }
    }

    if (param.values.isNotEmpty) {
      return param.values.first;
    }

    debugPrint(
        '❗ [Resolver] Unknown param even after select/label/values: $paramId');
    return '[Unresolved Param: $paramId]';
  }
}