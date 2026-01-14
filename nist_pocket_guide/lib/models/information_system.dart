// lib/models/information_system.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nist_pocket_guide/models/assessment_objective_response.dart';
// 📌 Assuming SystemParameterBlock has toJson/fromJson for the list serialization later
import 'package:nist_pocket_guide/models/system_parameter_block.dart'; 
import 'package:nist_pocket_guide/models/user_input_model.dart';


class ControlImplementation {
  String status;
  String implementationDetails;
  List<String> evidence;
  String notes;
  List<UserParameterValue> userParameterValues;
  List<UserImplementationNarrative> userStatementPartNarratives;
  // ✨ --- REPLACED placeholderValues WITH llmObjectivePlaceholderValues --- ✨
  Map<String, Map<String, String>> llmObjectivePlaceholderValues; 
  // Key: Objective ID (e.g., "ac-2_obj.a-1")
  // Value: Map where Key is Placeholder Label (e.g., "[AssignedRole]") and Value is user's input

  ControlImplementation({
    required this.status,
    this.implementationDetails = '',
    List<String>? evidence,
    this.notes = '',
    List<UserParameterValue>? userParameterValues,
    List<UserImplementationNarrative>? userStatementPartNarratives,
    // ✨ Updated constructor parameter
    Map<String, Map<String, String>>? llmObjectivePlaceholderValues, 
  })  : evidence = evidence ?? [],
        userParameterValues = userParameterValues ?? [],
        userStatementPartNarratives = userStatementPartNarratives ?? [],
        // ✨ Initialize new field
        llmObjectivePlaceholderValues = llmObjectivePlaceholderValues ?? {}; 

  Map<String, dynamic> toJson() => {
        'status': status,
        'implementationDetails': implementationDetails,
        'evidence': evidence,
        'notes': notes,
        'userParameterValues': userParameterValues.map((e) => e.toJson()).toList(),
        'userStatementPartNarratives': userStatementPartNarratives.map((e) => e.toJson()).toList(),
        // ✨ Serialize new field. Storing as a map directly.
        // If your DB needs a string, you'd use jsonEncode(llmObjectivePlaceholderValues) here.
        'llmObjectivePlaceholderValues': llmObjectivePlaceholderValues, 
      };

  factory ControlImplementation.fromJson(Map<String, dynamic> json) {
    Map<String, Map<String, String>> parsedLlmValues = {};
    // ✨ Logic to parse the new field from JSON
    dynamic rawLlmValues = json['llmObjectivePlaceholderValues'];

    if (rawLlmValues is Map) {
      // If it's already a map (e.g., from direct Dart object or some NoSQL DBs)
      try {
          rawLlmValues.forEach((key, value) {
            if (value is Map) { // Ensure inner value is also a map
              parsedLlmValues[key.toString()] = Map<String, String>.from(
                  value.map((k, v) => MapEntry(k.toString(), v.toString())));
            }
          });
      } catch (e, s) {
          if (kDebugMode) {
            print("Error parsing llmObjectivePlaceholderValues from Map: $e. Raw data: $rawLlmValues");
            print("Stack trace: $s");
          }
      }
    } else if (rawLlmValues is String && rawLlmValues.isNotEmpty) {
      // If it's a JSON string (e.g., from SQL DB text column)
      try {
        Map<String, dynamic> decodedMap = jsonDecode(rawLlmValues);
        decodedMap.forEach((key, value) {
          if (value is Map) { // Ensure inner value is also a map
            parsedLlmValues[key] = Map<String, String>.from(
                value.map((k, v) => MapEntry(k.toString(), v.toString())));
          }
        });
      } catch (e, s) {
        if (kDebugMode) {
          print("Error parsing llmObjectivePlaceholderValues from String: $e. Raw data: $rawLlmValues");
          print("Stack trace: $s");
        }
      }
    }
    // --- End of new field parsing logic ---

    return ControlImplementation(
      status: json['status'] as String? ?? 'Not Implemented',
      implementationDetails: json['implementationDetails'] as String? ?? '',
      // In your current code, you had: (json['evidence'] as List<dynamic>?)?.map((e) => e as String).toList() ?? []
      // It's safer to ensure toString() for robustness if items might not be strings.
      evidence: (json['evidence'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      notes: json['notes'] as String? ?? '',
      userParameterValues: (json['userParameterValues'] as List<dynamic>?)
              ?.map((e) => UserParameterValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      userStatementPartNarratives:
          (json['userStatementPartNarratives'] as List<dynamic>?)
                  ?.map((e) => UserImplementationNarrative.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
      // ✨ Pass parsed new field
      llmObjectivePlaceholderValues: parsedLlmValues,
    );
  }
}

class InformationSystem {
  String id;
  String name;
  String description;
  String atoStatus;
  String? selectedBaselineId;
  Map<String, ControlImplementation> controlImplementations;
  String notes;
  Map<String, List<AssessmentObjectiveResponse>> assessmentObjectiveResponses;
  Map<String, String> systemParameterBlockValues;
  String? companyAgencyName;
  List<SystemParameterBlock> customParameterBlockDefinitions;

  InformationSystem({
    required this.id,
    required this.name,
    this.description = '',
    this.atoStatus = 'In Development',
    this.selectedBaselineId,
    Map<String, ControlImplementation>? controlImplementations,
    this.notes = '',
    Map<String, List<AssessmentObjectiveResponse>>? assessmentObjectiveResponses,
    Map<String, String>? systemParameterBlockValues,
    List<SystemParameterBlock>? customParameterBlockDefinitions,
    this.companyAgencyName,
  })  : controlImplementations = controlImplementations ?? {},
        assessmentObjectiveResponses = assessmentObjectiveResponses ?? {},
        systemParameterBlockValues = systemParameterBlockValues ?? {},
        customParameterBlockDefinitions = customParameterBlockDefinitions ?? [];

  // --- Helper methods for JSON serialization/deserialization (from your current file) ---

  String controlImplementationsToJson() {
    final mapOfStringDynamic = controlImplementations.map(
      (key, value) => MapEntry(key, value.toJson()), // Uses the updated ControlImplementation.toJson()
    );
    return jsonEncode(mapOfStringDynamic);
  }

  static Map<String, ControlImplementation> controlImplementationsFromJson(String jsonString) {
    if (jsonString.isEmpty || jsonString == '{}') return {}; // Handle empty or empty JSON object string
    try {
      final Map<String, dynamic> decodedMap = jsonDecode(jsonString);
      return decodedMap.map(
        (key, value) => MapEntry(
            key, ControlImplementation.fromJson(value as Map<String, dynamic>)), // Uses updated FromJson
      );
    } catch (e, s) { // Added stack trace
      if (kDebugMode) {
        print("Error decoding controlImplementations: $e. JSON: $jsonString");
        print("Stack trace: $s");
      }
      return {};
    }
  }

  String assessmentObjectiveResponsesToJson() {
    final mapOfStringDynamic = assessmentObjectiveResponses.map(
      (controlId, responses) => MapEntry(
          controlId, responses.map((resp) => resp.toJson()).toList()),
    );
    return jsonEncode(mapOfStringDynamic);
  }

  static Map<String, List<AssessmentObjectiveResponse>>
      assessmentObjectiveResponsesFromJson(String jsonString) {
    if (jsonString.isEmpty || jsonString == '{}') return {};
    try {
      final Map<String, dynamic> decodedMap = jsonDecode(jsonString);
      return decodedMap.map(
        (controlId, value) => MapEntry(
            controlId,
            (value as List<dynamic>)
                .map((respJson) => AssessmentObjectiveResponse.fromJson(
                    respJson as Map<String, dynamic>))
                .toList()),
      );
    } catch (e, s) { // Added stack trace
      if (kDebugMode) {
        print("Error decoding assessmentObjectiveResponses: $e. JSON: $jsonString");
        print("Stack trace: $s");
      }
      return {};
    }
  }

  String systemParameterBlockValuesToJson() {
    return jsonEncode(systemParameterBlockValues);
  }

  static Map<String, String> systemParameterBlockValuesFromJson(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty || jsonString == '{}') return {};
    try {
      final Map<String, dynamic> decodedMap = jsonDecode(jsonString);
      return Map<String, String>.from(decodedMap);
    } catch (e, s) { // Added stack trace
      if (kDebugMode) {
        print("Error decoding systemParameterBlockValues: $e. JSON: $jsonString");
        print("Stack trace: $s");
      }
      return {};
    }
  }

  String customParameterBlockDefinitionsToJson() {
    if (customParameterBlockDefinitions.isEmpty) {
      return '[]'; 
    }
    // 📌 Assuming SystemParameterBlock has a toJson() method
    return jsonEncode(customParameterBlockDefinitions.map((e) => e.toJson()).toList());
  }

  static List<SystemParameterBlock> customParameterBlockDefinitionsFromJson(String jsonString) {
    if (jsonString.isEmpty || jsonString == '[]') {
      return [];
    }
    try {
      final List<dynamic> decodedList = jsonDecode(jsonString);
      // 📌 Assuming SystemParameterBlock has a fromJson() factory
      return decodedList.map((item) => SystemParameterBlock.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e, s) { // Added stack trace
      if (kDebugMode) {
        print("Error decoding customParameterBlockDefinitions: $e. JSON string was: $jsonString");
        print("Stack trace: $s");
      }
      return [];
    }
  }

  Map<String, dynamic> toMap() {
    final mapData = {
      'id': id,
      'name': name,
      'description': description,
      'atoStatus': atoStatus,
      'selectedBaselineId': selectedBaselineId,
      'controlImplementations': controlImplementationsToJson(),
      'notes': notes,
      'assessmentObjectiveResponses': assessmentObjectiveResponsesToJson(),
      'systemParameterBlockValues': systemParameterBlockValuesToJson(),
      'companyAgencyName': companyAgencyName,
      'customParameterBlockDefinitions': customParameterBlockDefinitionsToJson(),
    };
    // Removed the debug print from here as it was very verbose; errors should be caught in fromJson/toJson helpers.
    return mapData;
  }

  factory InformationSystem.fromMap(Map<String, dynamic> map) {
    return InformationSystem(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      atoStatus: map['atoStatus'] as String? ?? 'In Development',
      selectedBaselineId: map['selectedBaselineId'] as String?,
      controlImplementations:
          controlImplementationsFromJson(map['controlImplementations'] as String? ?? '{}'), 
      notes: map['notes'] as String? ?? '',
      assessmentObjectiveResponses: assessmentObjectiveResponsesFromJson(
          map['assessmentObjectiveResponses'] as String? ?? '{}'), 
      systemParameterBlockValues: systemParameterBlockValuesFromJson(
          map['systemParameterBlockValues'] as String?), 
      companyAgencyName: map['companyAgencyName'] as String?,
      customParameterBlockDefinitions: customParameterBlockDefinitionsFromJson(
          map['customParameterBlockDefinitions'] as String? ?? '[]'),
    );
  }
}

const List<String> controlStatusOptions = [
  'Not Implemented',
  'Planned',
  'Partially Implemented',
  'Implemented',
  'Not Applicable',
];

const List<String> atoStatusOptions = [
  'In Development',
  'Under Review',
  'Operational',
  'Decommissioned',
  'On Hold', // Kept your 'On Hold'
];