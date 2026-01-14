// lib/models/assessment_objective_response.dart
import 'package:flutter/foundation.dart';

class AssessmentObjectiveResponse {
  String objectiveKey; // e.g., "ac-2_obj.a" (the Part.id)
  String objectiveProse; // Original OSCAL prose (non-nullable)
  String? userNotes;   // User's specific notes or overrides for this objective
  bool isMet; // Indicates if the user considers this objective met by the standard approach / blocks
  String? builtStatement; // To store the statement from ImplementationStatementBuilderScreen

  AssessmentObjectiveResponse({
    required this.objectiveKey,
    required this.objectiveProse,
    this.userNotes,
    this.builtStatement,
    bool? isMet,
  }) : isMet = isMet ?? false {
    assert(objectiveKey.isNotEmpty);
    assert(objectiveProse.isNotEmpty);
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      // Only print in debug mode
      if (kDebugMode) {
        print('DEBUG: AssessmentObjectiveResponse constructor for key: \u001b[33m$objectiveKey\u001b[0m, isMet: \u001b[35m$isMet\u001b[0m');
      }
    }
  }

  // 'isImplemented' might now depend on 'isMet'
  bool get isImplemented => isMet && (userNotes == null || userNotes!.trim().isNotEmpty); // Or just isMet

  Map<String, dynamic> toJson() => {
        'objectiveKey': objectiveKey,
        'objectiveProse': objectiveProse,
        'userNotes': userNotes,
        'isMet': isMet,
        'builtStatement': builtStatement,
      };

  factory AssessmentObjectiveResponse.fromJson(Map<String, dynamic> json) =>
      AssessmentObjectiveResponse(
        objectiveKey: json['objectiveKey'] as String,
        objectiveProse: json['objectiveProse'] as String? ?? 'Prose unavailable.', // Should be populated correctly
        userNotes: json['userNotes'] as String?,
        isMet: json['isMet'] as bool? ?? false, // Default to NOT met
        builtStatement: json['builtStatement'] as String?,
      );
}