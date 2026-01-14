// lib/ssp_generator_screens/ssp_statement_templates.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 📌 NEW: Import the models needed for getFinalStatementForControl
import 'package:nist_pocket_guide/models/information_system.dart';
import 'package:nist_pocket_guide/models/llm_objective_data.dart';


// ADVISORY: The 'objectiveTemplates' map below is now considered redundant
// as these templates are sourced from 'llm_enhanced_assessment_objectives.json'.
// It's commented out to prevent conflicts and maintain a single source of truth.
/*
const Map<String, Map<String, String>> objectiveTemplates = {
  "ac-2": {
    "ac-2_obj.a-1": "Account types allowed for use within the system are defined and documented by [roleAccountTypeDefReview] using the [directoryServiceName] and are reviewed [reviewFreqAccountTypeDefs].",
    // ... other templates ...
  },
  // ... other controls ...
};
*/

// -----------------------------------------------------------------------------
// FUNCTION 1: formatRichTextFromTemplate (Likely used by ObjectiveStatementEditorScreen)
// -----------------------------------------------------------------------------
// This function is designed to replace placeholders like [placeholder_key] with values for RichText display.
List<InlineSpan> formatRichTextFromTemplate(
  BuildContext context,
  String template,
  Map<String, String> blockValues, { // Expects keys *without* brackets, e.g., "AssignedRole"
  TextStyle? defaultStyle,
  TextStyle? placeholderStyle, // Style for the placeholder itself when not filled (e.g., "[Label]")
  TextStyle? filledValueStyle, // Style for the filled value
}) {
  final currentTheme = Theme.of(context);
  final effectiveDefaultStyle = defaultStyle ?? currentTheme.textTheme.bodyMedium ?? const TextStyle(color: Colors.black, fontSize: 14);
  final effectivePlaceholderStyle = placeholderStyle ?? TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontStyle: FontStyle.italic,
                                                              color: Colors.orange.shade800,
                                                              backgroundColor: Colors.orange.withAlpha((255 * 0.15).round()),
                                                            );
  final effectiveFilledValueStyle = filledValueStyle ?? TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: currentTheme.colorScheme.primary,
                                                            );

  List<InlineSpan> spans = [];
  if (template.isEmpty) return spans;

  RegExp placeholderRegExp = RegExp(r"\[([^\]]+)\]"); // Matches "[PlaceholderKey]"
  int currentIndex = 0;

  for (Match match in placeholderRegExp.allMatches(template)) {
    if (match.start > currentIndex) {
      spans.add(TextSpan(
          text: template.substring(currentIndex, match.start),
          style: effectiveDefaultStyle));
    }

    String placeholderKeyWithoutBrackets = match.group(1)!; // Key inside brackets, e.g., "AssignedRole"
    String placeholderWithBrackets = match.group(0)!;   // Full placeholder, e.g., "[AssignedRole]"
    String value = blockValues[placeholderKeyWithoutBrackets]?.trim() ?? '';

    if (value.isNotEmpty) {
      spans.add(TextSpan(text: value, style: effectiveFilledValueStyle));
    } else {
      // Show the placeholder itself (with brackets) using placeholderStyle
      spans.add(TextSpan(text: placeholderWithBrackets, style: effectivePlaceholderStyle));
    }
    currentIndex = match.end;
  }

  if (currentIndex < template.length) {
    spans.add(
        TextSpan(text: template.substring(currentIndex), style: effectiveDefaultStyle));
  }
  return spans;
}

// -----------------------------------------------------------------------------
// FUNCTION 2: substituteBlockValuesAndStyle (Restored from your other version)
// -----------------------------------------------------------------------------

// Templates presumably used by substituteBlockValuesAndStyle
const Map<String, String> combinedSummaryTemplates = {
  "ac-2": "[companyAgencyName] meticulously manages system accounts across [coreSystemToolName], [directoryServiceName], and [applicationPlatformName] by formally defining account types (reviewed [reviewFreqAccountTypeDefs] by [roleAccountTypeDefReview]), assigning responsible account managers ([defaultUserAccountManager], [defaultServiceAccountManager]), and establishing clear prerequisites (defined by [roleDefineMembershipPrereqs]) for group and role memberships, especially for sensitive PII/PHI access. Authorized users and their specific access privileges are managed via an [iamSolutionName], with account creation requiring formal, workflow-driven approvals by [approveRoleAccountCreate] via [serviceMgmtPlatformName]. Account lifecycle actions are policy-driven and largely automated by the [iamSolutionName] (triggered by [hrSystemName] events), with notifications for status changes sent to [notifiedRolesAccountStatus] within [timeframeAccountChanges]. System access is authorized based on validated roles (defined by [roleDefineSystemUsage]) and attributes, with all account usage being centrally monitored by [roleMonitorAccountUsage] via a [siemToolName]. All accounts and role assignments undergo regular reviews ([stdAccountReviewFreq] or [privAccountReviewFreq]) and attestations by [reviewRoleAccounts] using an [accessCertToolName], ensuring alignment with HR events and secure management of shared authenticators by [roleManageSharedAuths]. Access disablement/removal for leavers occurs within [timeframeDisableLeavers], and modification for movers within [timeframeModifyMovers].",
  // Add more combined summaries here if this map is used by substituteBlockValuesAndStyle
};

List<InlineSpan> substituteBlockValuesAndStyle(
  String template,
  Map<String, String> blockValues, // Expects keys *without* brackets for general placeholders
  String companyAgencyName,
  TextStyle normalStyle,
  TextStyle substitutedStyle,
) {
  if (kDebugMode) {
    print("--- substituteBlockValuesAndStyle ---");
    print("Template IN: $template");
    print("Block Values IN: $blockValues");
    print("Company/Agency Name IN: $companyAgencyName");
  }

  List<InlineSpan> spans = [];
  String currentText = template;

  // First, handle specific replacements for [companyAgencyName] and [The enterprise]
  currentText = currentText.replaceAllMapped(
    RegExp(r'\[(companyAgencyName|The enterprise)\]', caseSensitive: false), (match) {
      return companyAgencyName.isNotEmpty ? companyAgencyName : 'The Organization'; // Default
    });

  // Regex for general placeholders like [blockId].
  // This assumes keys in `blockValues` are the IDs *without* brackets.
  RegExp placeholderRegex = RegExp(r'\[([a-zA-Z0-9_-]+)\]');
  int currentIndex = 0;

  for (Match match in placeholderRegex.allMatches(currentText)) {
    if (match.start > currentIndex) {
      spans.add(TextSpan(text: currentText.substring(currentIndex, match.start), style: normalStyle));
    }

    String placeholderKey = match.group(1)!; // The ID inside the brackets (e.g., "coreSystemToolName")
    String? valueFromBlocks = blockValues[placeholderKey];

    if (valueFromBlocks != null && valueFromBlocks.trim().isNotEmpty) {
      spans.add(TextSpan(text: valueFromBlocks.trim(), style: substitutedStyle));
      if (kDebugMode) {
        print("  SUCCESS: Replaced '[$placeholderKey]' with '${valueFromBlocks.trim()}'");
      }
    } else {
      // Use the _formatKeyForMissing_for_substituteBlockValues associated with this function
      String missingFormatted = _formatKeyForMissingForSubstituteBlockValues(placeholderKey);
      // Display the formatted missing key, possibly with a different style to indicate it's missing.
      spans.add(TextSpan(text: '[$missingFormatted]', style: substitutedStyle.copyWith(fontStyle: FontStyle.italic, color: Colors.red.shade700)));
       if (kDebugMode) {
        print("  FALLBACK: Key '$placeholderKey' not in blockValues or empty. Using '[$missingFormatted]'");
      }
    }
    currentIndex = match.end;
  }

  if (currentIndex < currentText.length) {
    spans.add(TextSpan(text: currentText.substring(currentIndex), style: normalStyle));
  }

  if (kDebugMode) {
    print("-----------------------------");
  }
  return spans;
}

// Helper for substituteBlockValuesAndStyle (from your Macbook version)
// Renamed slightly to make its association clear and avoid potential future conflicts
String _formatKeyForMissingForSubstituteBlockValues(String key) {
  if (key.isEmpty) return 'PARAM - NOT SPECIFIED';
  String titleCase = key;
  if (key.contains('_') || key.contains('-')) { // Also check for hyphen
    titleCase = key.replaceAll('_', ' ').replaceAll('-', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ');
  } else {
    titleCase = key.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'), (Match m) => ' ');
    if (titleCase.isNotEmpty) {
       titleCase = titleCase.split(' ').map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
      }).join(' ');
    }
  }
  return titleCase.isNotEmpty ? '$titleCase - NOT SPECIFIED' : 'UNKNOWN PARAM - NOT SPECIFIED';
}

// -----------------------------------------------------------------------------
// HELPER for getFinalStatementForControl (and potentially other plain text needs)
// -----------------------------------------------------------------------------
// Expects `values` map to use keys *without* brackets (e.g., "AssignedRole").
String _replacePlaceholdersPlainText(String template, Map<String, String> values) {
  if (template.isEmpty) return "";
  StringBuffer sb = StringBuffer();
  RegExp placeholderRegExp = RegExp(r"\[([^\]]+)\]"); // Matches "[PlaceholderKey]"
  int currentIndex = 0;

  for (Match match in placeholderRegExp.allMatches(template)) {
    sb.write(template.substring(currentIndex, match.start));

    String placeholderKey = match.group(1)!; // Key inside brackets
    String value = values[placeholderKey]?.trim() ?? "";

    if (value.isNotEmpty) {
      sb.write(value);
    } else {
      sb.write("${match.group(0)!} (Needs Input)"); // e.g., "[Unfilled_Placeholder] (Needs Input)"
    }
    currentIndex = match.end;
  }
  sb.write(template.substring(currentIndex));
  return sb.toString();
}

// -----------------------------------------------------------------------------
// FUNCTION 3: getFinalStatementForControl
// -----------------------------------------------------------------------------
String getFinalStatementForControl(
  String controlId,
  ControlImplementation? controlImplementation,
  LlmControlObjectiveData? llmControlData,
  // String companyAgencyName, // Example: If main statement needs it for substituteBlockValuesAndStyle
  // Map<String, String> blockValuesForCombinedSummary, // Example: If using combinedSummaryTemplates
) {
  if (controlImplementation == null) {
    return "Control implementation details not available for $controlId.";
  }

  StringBuffer buffer = StringBuffer();

  // Part 1: Main Control Implementation Details
  if (controlImplementation.implementationDetails.isNotEmpty) {
    buffer.writeln("### ${controlId.toUpperCase()} Implementation Statement");
    // If controlImplementation.implementationDetails itself contains [placeholders]
    // and is intended to be processed by `substituteBlockValuesAndStyle` or similar,
    // you would call that function here.
    // Example (conceptual):
    // TextStyle normalStyle = const TextStyle(color: Colors.black); // Define appropriately
    // TextStyle substitutedStyle = normalStyle.copyWith(fontWeight: FontWeight.bold);
    // List<InlineSpan> mainSpans = substituteBlockValuesAndStyle(
    //   controlImplementation.implementationDetails, // Assuming this is a template string
    //   blockValuesForCombinedSummary, // The map of values for this template
    //   companyAgencyName,
    //   normalStyle,
    //   substitutedStyle
    // );
    // buffer.writeln(_spansToPlainText(mainSpans)); // Need a helper to convert spans to plain text for buffer
    buffer.writeln(controlImplementation.implementationDetails); // Current behavior
    buffer.writeln();
  } else {
    buffer.writeln("### ${controlId.toUpperCase()} Implementation Statement");
    buffer.writeln("*The overall implementation details for ${controlId.toUpperCase()} have not yet been defined.*");
    buffer.writeln();
  }

  // Part 2: Objective-Specific Statements (from LLM JSON and user inputs)
  if (llmControlData != null && llmControlData.llmGeneratedObjectiveStatements.isNotEmpty) {
    buffer.writeln("#### Objective-Specific Details:");
    for (var llmObjectiveStmt in llmControlData.llmGeneratedObjectiveStatements) {
      final userFilledValuesForThisObjective =
          controlImplementation.llmObjectivePlaceholderValues[llmObjectiveStmt.objectiveId] ?? {};

      // Transform keys from "[Label]" to "Label" for _replacePlaceholdersPlainText
      Map<String, String> transformedValues = {};
      userFilledValuesForThisObjective.forEach((keyWithBrackets, value) {
          transformedValues[keyWithBrackets.replaceAll('[','').replaceAll(']','')] = value;
      });

      String filledObjectiveStatement = _replacePlaceholdersPlainText(
          llmObjectiveStmt.llmGeneratedStatement,
          transformedValues
      );

      buffer.writeln("**${llmObjectiveStmt.objectiveId.toUpperCase()}:**");
      buffer.writeln(filledObjectiveStatement);
      buffer.writeln();
    }
  } else {
    buffer.writeln("_(No specific LLM-enhanced objective statements were processed for this control.)_");
    buffer.writeln();
  }

  // Part 3: Additional Notes from ControlImplementation
  if (controlImplementation.notes.isNotEmpty) {
    buffer.writeln("#### Additional Control Notes:");
    buffer.writeln(controlImplementation.notes);
    buffer.writeln();
  }

  return buffer.toString().trim();
}

// Helper function to convert List<InlineSpan> to plain text, if needed for getFinalStatementForControl
// String _spansToPlainText(List<InlineSpan> spans) {
//   StringBuffer buffer = StringBuffer();
//   for (var span in spans) {
//     if (span is TextSpan) {
//       buffer.write(span.text);
//       // Note: This doesn't recursively handle span.children if formatRichTextFromTemplate creates nested TextSpans.
//       // formatRichTextFromTemplate generally creates a flat list.
//     }
//   }
//   return buffer.toString();
// }

// This _formatKeyForMissing was originally from your PC version for formatRichTextFromTemplate.
// It might be different from the one expected by substituteBlockValuesAndStyle.
// I've kept the _formatKeyForMissing_for_substituteBlockValues with that function.
// If you only need one version, you can consolidate.
/*
String _formatKeyForMissing(String key, String prefix) {
  if (key.isEmpty) return '$prefix - NOT SPECIFIED';
  String titleCase = key;
  if (key.contains('_') || key.contains('-')) {
    titleCase = key.replaceAll('_', ' ').replaceAll('-', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  } else {
    titleCase = key.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'), (Match m) => ' ');
    if (titleCase.isNotEmpty) {
      titleCase = titleCase[0].toUpperCase() + titleCase.substring(1);
    }
  }
  return '$prefix: $titleCase';
}
*/