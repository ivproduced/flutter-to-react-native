// lib/models/llm_objective_data.dart
import 'package:flutter/foundation.dart';

// Utility for sorting control IDs naturally (e.g., AC-2 before AC-10)
// Your existing controlIdComparator seems fine for sorting, so I'll keep it as is.
// The primary issue is with parsing, not sorting at this stage.
int controlIdComparator(String idA, String idB) {
  RegExp idPattern = RegExp(r"([a-zA-Z]+)-(\d+)(?:\.([\w\d]+))?(?:\((\w+)\))?(?:_([a-zA-Z]+))?(?:\.([\w\d]+))?");
  Match? matchA = idPattern.firstMatch(idA.toLowerCase());
  Match? matchB = idPattern.firstMatch(idB.toLowerCase());

  if (matchA == null || matchB == null) {
    return idA.toLowerCase().compareTo(idB.toLowerCase());
  }
  String prefixA = matchA.group(1) ?? "";
  String prefixB = matchB.group(1) ?? "";
  int prefixCompare = prefixA.compareTo(prefixB);
  if (prefixCompare != 0) return prefixCompare;

  int numA = int.tryParse(matchA.group(2) ?? '0') ?? 0;
  int numB = int.tryParse(matchB.group(2) ?? '0') ?? 0;
  int numCompare = numA.compareTo(numB);
  if (numCompare != 0) return numCompare;

  String partIdA = matchA.group(3) ?? matchA.group(6) ?? "";
  String partIdB = matchB.group(3) ?? matchB.group(6) ?? "";

  if (partIdA.isNotEmpty || partIdB.isNotEmpty) {
    if (partIdA.isEmpty && partIdB.isNotEmpty) return -1;
    if (partIdA.isNotEmpty && partIdB.isEmpty) return 1;
    
    RegExp partPattern = RegExp(r"([a-zA-Z]+)(?:-(\d+))?");
    Match? partMatchA = partPattern.firstMatch(partIdA);
    Match? partMatchB = partPattern.firstMatch(partIdB);

    if (partMatchA != null && partMatchB != null) {
      String charPartA = partMatchA.group(1) ?? "";
      String charPartB = partMatchB.group(1) ?? "";
      int charPartCompare = charPartA.compareTo(charPartB);
      if (charPartCompare != 0) return charPartCompare;

      int numPartA = int.tryParse(partMatchA.group(2) ?? '0') ?? 0;
      int numPartB = int.tryParse(partMatchB.group(2) ?? '0') ?? 0;
      int numPartCompare = numPartA.compareTo(numPartB);
      if (numPartCompare != 0) return numPartCompare;
    } else {
        int partIdCompare = partIdA.compareTo(partIdB);
        if (partIdCompare != 0) return partIdCompare;
    }
  }
  
  String enhancementA = matchA.group(4) ?? "";
  String enhancementB = matchB.group(4) ?? "";
  if (enhancementA.isNotEmpty || enhancementB.isNotEmpty) {
    if (enhancementA.isEmpty && enhancementB.isNotEmpty) return -1;
    if (enhancementA.isNotEmpty && enhancementB.isEmpty) return 1;
    
    int numEnhA = int.tryParse(enhancementA) ?? 0;
    int numEnhB = int.tryParse(enhancementB) ?? 0;
    int enhancementCompare = numEnhA.compareTo(numEnhB);
    if (enhancementCompare != 0) return enhancementCompare;
  }

  String objSuffixA = matchA.group(5) ?? "";
  String objSuffixB = matchB.group(5) ?? "";
  int objSuffixCompare = objSuffixA.compareTo(objSuffixB);
  if (objSuffixCompare != 0) return objSuffixCompare;

  return idA.toLowerCase().compareTo(idB.toLowerCase());
}


class LlmControlObjectiveData {
  final String controlId;
  final String controlTitle;
  final List<LlmObjectiveStatement> llmGeneratedObjectiveStatements;
  
  // These fields might not be present in the "AC-2" JSON structure you provided at the top level
  // for an entry that contains "assessment_objectives". If they are optional or come from
  // other types of entries in your main JSON list, this is fine.
  // If they should come from "AC-2" structure, we need to map them or remove them.
  // For now, keeping them as per your original class structure but parsing for
  // llmGeneratedObjectiveStatements will use "assessment_objectives".
  final List<LlmPlaceholderDefinition> placeholders; // From 'placeholders_for_llm_generated_statements'
  final String? llmGeneratedControlSummary; // From 'llm_generated_control_summary'


  LlmControlObjectiveData({
    required this.controlId,
    required this.controlTitle,
    required this.llmGeneratedObjectiveStatements,
    required this.placeholders, // If this is not in your new JSON, it will be empty
    this.llmGeneratedControlSummary, // If this is not in your new JSON, it will be null
  });

  factory LlmControlObjectiveData.fromJson(Map<String, dynamic> json) {
    // Determine the correct key for the objectives list in the JSON
    String objectivesJsonKey = "assessment_objectives"; // From your snippet
    if (json[objectivesJsonKey] is! List<dynamic> && json["objectives"] is List<dynamic>) {
        objectivesJsonKey = "objectives"; // Fallback
    }
    
    var parsedObjectiveStatements = (json[objectivesJsonKey] as List<dynamic>? ?? [])
        .map((e) {
          try {
            return LlmObjectiveStatement.fromJson(e as Map<String, dynamic>);
          } catch (ex, s) {
            if (kDebugMode) {
              print("🚨 FAILED to parse LlmObjectiveStatement from: $e. Error: $ex\nStack: $s");
            }
            return null; 
          }
        })
        .whereType<LlmObjectiveStatement>() 
        .toList();

    // Sort statements by objectiveId using the comparator
    parsedObjectiveStatements.sort((a, b) => controlIdComparator(a.objectiveId, b.objectiveId));

    // ✨ --- NEW LOGIC: Aggregate placeholders from all parsed statements --- ✨
    List<LlmPlaceholderDefinition> aggregatedPlaceholders = [];
    Set<String> seenPlaceholderIds = {}; // To ensure uniqueness in the flat list by ID
    for (var statement in parsedObjectiveStatements) {
      // statement.placeholders is already populated by LlmObjectiveStatement.fromJson
      // from 'placeholders_in_summary'
      for (var pDef in statement.placeholders) { 
        if (seenPlaceholderIds.add(pDef.id)) { // add returns true if element was new
          aggregatedPlaceholders.add(pDef);
        }
      }
    }
    // ✨ --- END NEW LOGIC --- ✨

    return LlmControlObjectiveData(
      controlId: json['control_id'] as String? ?? 'unknown_id',
      controlTitle: json['control_title'] as String? ?? 'Untitled',
      llmGeneratedObjectiveStatements: parsedObjectiveStatements,
      placeholders: aggregatedPlaceholders, // Use the new aggregated list
      llmGeneratedControlSummary: json['llm_generated_control_summary'] as String?,
    );
  }

  // This method remains useful for the UI if it needs placeholders specific to one objective,
  // and it will filter from the now correctly populated flat list.
  List<LlmPlaceholderDefinition> getPlaceholdersForObjective(String objectiveId) {
    return placeholders.where((p) {
      // p.id is like "ac-1_obj.a-1_ph_1"
      // objectiveId is like "ac-1_obj.a-1"
      return p.id.startsWith("${objectiveId}_ph_");
    }).toList();
  }
}


class LlmObjectiveStatement {
  final String objectiveId;
  final String objectiveProseOriginal; 
  final String llmGeneratedStatement;
  final String llmGeneratedQuestion;
  final List<LlmPlaceholderDefinition> placeholders; 
  final String? error; 

  LlmObjectiveStatement({
    required this.objectiveId,
    required this.objectiveProseOriginal,
    required this.llmGeneratedStatement,
    required this.llmGeneratedQuestion,
    required this.placeholders, 
    this.error,
  });

  factory LlmObjectiveStatement.fromJson(Map<String, dynamic> json) {
    
    // Parse placeholders from "placeholders_in_summary"
    var placeholderListJson = json['placeholders_in_statement'] as List<dynamic>? ?? [];
    List<LlmPlaceholderDefinition> parsedPlaceholders = placeholderListJson
        .map((p) {
          if (p is Map<String, dynamic>) {
            try {
              return LlmPlaceholderDefinition.fromJson(p);
            } catch (ex, s) {
              if (kDebugMode) {
                print("🚨 FAILED to parse LlmPlaceholderDefinition from: $p. Error: $ex\nStack: $s");
              }
              return null;
            }
          }
          return null;
        })
        .whereType<LlmPlaceholderDefinition>()
        .toList();

    return LlmObjectiveStatement(
      objectiveId: json['objective_key'] as String? ?? 'unknown_objective_key',
      objectiveProseOriginal: json['objective_prose_original'] as String? ?? 'Prose not available.',
      llmGeneratedStatement: json['llm_generated_implementation_statement'] as String? ?? 'Statement not available.',
      llmGeneratedQuestion: json['llm_generated_question'] as String? ?? 'Question not available.',
      placeholders: parsedPlaceholders, // Parsed from "placeholders_in_summary"
      error: json['error'] as String?,
    );
  }
}

class LlmPlaceholderDefinition {
  final String id;
  final String label;
  final String description;
  final List<String> examples;
  final String? frequencyGroupKey;
  /// New: If this placeholder is document-related, this key is used to group them for shared value logic within a control family.
  final String? documentGroupKey;
  /// New: If this placeholder is role-related, this key is used to group them for shared value logic within a control family.
  final String? roleGroupKey;
  /// New: Semantic group from JSON (if present)
  final String? semanticGroup;

  LlmPlaceholderDefinition({
    required this.id,
    required this.label,
    required this.description,
    this.examples = const [],
    this.frequencyGroupKey,
    this.documentGroupKey,
    this.roleGroupKey,
    this.semanticGroup,
  });

  factory LlmPlaceholderDefinition.fromJson(Map<String, dynamic> json) {
    String? freqKey;
    String? docKey;
    String? roleKey;
    final label = json['label'] as String? ?? 'Unknown Label';
    final description = json['description'] as String? ?? 'No description.';
    final lowerLabel = label.toLowerCase();
    final lowerDesc = description.toLowerCase();
    // Frequency grouping (existing)
    if (lowerLabel.contains('frequency') || lowerLabel.contains('interval') || lowerLabel.contains('periodic') ||
        lowerDesc.contains('frequency') || lowerDesc.contains('interval') || lowerDesc.contains('periodic')) {
      if (lowerLabel.contains('frequency') || lowerDesc.contains('frequency')) {
        freqKey = 'frequency';
      } else if (lowerLabel.contains('interval') || lowerDesc.contains('interval')) {
        freqKey = 'interval';
      } else if (lowerLabel.contains('periodic') || lowerDesc.contains('periodic')) {
        freqKey = 'periodicity';
      }
    }
    // Document grouping (new)
    if (lowerLabel.contains('document') || lowerLabel.contains('doc') || lowerDesc.contains('document') || lowerDesc.contains('doc')) {
      docKey = 'document';
    }
    // Role grouping (new)
    if (lowerLabel.contains('role') || lowerLabel.contains('responsible') || lowerLabel.contains('assigned') ||
        lowerDesc.contains('role') || lowerDesc.contains('responsible') || lowerDesc.contains('assigned')) {
      roleKey = 'role';
    }
    // Use llm_examples if present, otherwise fall back to examples
    final examplesList = (json['llm_examples'] as List<dynamic>?) ?? (json['examples'] as List<dynamic>? ?? []);
    return LlmPlaceholderDefinition(
      id: json['id'] as String? ?? 'unknown_id',
      label: label,
      description: description,
      examples: examplesList.map((e) => e.toString()).toList(),
      frequencyGroupKey: freqKey,
      documentGroupKey: docKey,
      roleGroupKey: roleKey,
      semanticGroup: json['semantic_group'] as String?,
    );
  }

  String get objectiveIdRef {
      int lastUnderscorePh = id.lastIndexOf('_ph_');
      if (lastUnderscorePh != -1) {
          return id.substring(0, lastUnderscorePh);
      }
      return id; 
  }
}

// --- EXTENSIONS FOR FREQUENCY GROUPING ---
extension LlmPlaceholderDefinitionListExtensions on List<LlmPlaceholderDefinition> {
  /// Returns a map of frequencyGroupKey -> list of placeholders in that group (only for those with a group key).
  Map<String, List<LlmPlaceholderDefinition>> get frequencyGroups {
    final Map<String, List<LlmPlaceholderDefinition>> groups = {};
    for (final p in this) {
      if (p.frequencyGroupKey != null) {
        groups.putIfAbsent(p.frequencyGroupKey!, () => []).add(p);
      }
    }
    return groups;
  }

  /// Returns all placeholders that are part of any frequency group.
  List<LlmPlaceholderDefinition> get frequencyGroupedPlaceholders =>
      where((p) => p.frequencyGroupKey != null).toList();

  /// Returns all placeholders that are NOT part of any frequency group.
  List<LlmPlaceholderDefinition> get nonFrequencyGroupedPlaceholders =>
      where((p) => p.frequencyGroupKey == null).toList();

  /// Document groupings (for sharing within control family)
  Map<String, List<LlmPlaceholderDefinition>> get documentGroups {
    final Map<String, List<LlmPlaceholderDefinition>> groups = {};
    for (final p in this) {
      if (p.documentGroupKey != null) {
        groups.putIfAbsent(p.documentGroupKey!, () => []).add(p);
      }
    }
    return groups;
  }
  List<LlmPlaceholderDefinition> get documentGroupedPlaceholders =>
      where((p) => p.documentGroupKey != null).toList();
  List<LlmPlaceholderDefinition> get nonDocumentGroupedPlaceholders =>
      where((p) => p.documentGroupKey == null).toList();

  /// Role groupings (for sharing within control family)
  Map<String, List<LlmPlaceholderDefinition>> get roleGroups {
    final Map<String, List<LlmPlaceholderDefinition>> groups = {};
    for (final p in this) {
      if (p.roleGroupKey != null) {
        groups.putIfAbsent(p.roleGroupKey!, () => []).add(p);
      }
    }
    return groups;
  }
  List<LlmPlaceholderDefinition> get roleGroupedPlaceholders =>
      where((p) => p.roleGroupKey != null).toList();
  List<LlmPlaceholderDefinition> get nonRoleGroupedPlaceholders =>
      where((p) => p.roleGroupKey == null).toList();
}

extension LlmControlObjectiveDataFrequencyExt on LlmControlObjectiveData {
  /// Returns a map of frequency group key to all placeholders in this control that share that key.
  Map<String, List<LlmPlaceholderDefinition>> get frequencyPlaceholderGroups {
    return placeholders.frequencyGroups;
  }
}