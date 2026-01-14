// File: lib/models/user_input_models.dart

import 'package:flutter/foundation.dart';

/// Represents the user-provided value for a specific OSCAL parameter
/// within a control or control statement part.
@immutable
class UserParameterValue {
  /// The ID of the control this parameter value belongs to (e.g., "ac-2").
  final String controlId;

  /// The ID of the specific OSCAL parameter (e.g., "ac-2_prm_1", "si-2_prm_3_odp").
  final String paramId;

  /// The user-provided value for the parameter.
  final String value;

  /// Optional: The ID of the specific statement part (e.g., "ac-2.a.1_smt", "si-2_smt.c")
  /// this parameter value is associated with.
  ///
  /// This is useful if the same `paramId` can appear in multiple parts of a control
  /// and might require different user inputs for each context.
  /// If a `paramId` is globally unique for its input within a `controlId`,
  /// this might be less critical or could be set to a common value (e.g., controlId).
  final String? statementPartId;

  const UserParameterValue({
    required this.controlId,
    required this.paramId,
    required this.value,
    this.statementPartId,
  });

  Map<String, dynamic> toJson() {
    return {
      'controlId': controlId,
      'paramId': paramId,
      'value': value,
      if (statementPartId != null) 'statementPartId': statementPartId,
    };
  }

  factory UserParameterValue.fromJson(Map<String, dynamic> json) {
    return UserParameterValue(
      controlId: json['controlId'] as String,
      paramId: json['paramId'] as String,
      value: json['value'] as String,
      statementPartId: json['statementPartId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserParameterValue &&
          runtimeType == other.runtimeType &&
          controlId == other.controlId &&
          paramId == other.paramId &&
          statementPartId == other.statementPartId && // Value is not part of equality for map keying
          value == other.value;


  @override
  int get hashCode =>
      controlId.hashCode ^
      paramId.hashCode ^
      statementPartId.hashCode ^ // Value is not part of hashcode for map keying
      value.hashCode;


  @override
  String toString() {
    return 'UserParameterValue(controlId: $controlId, statementPartId: $statementPartId, paramId: $paramId, value: $value)';
  }
}

/// Represents the user-written implementation narrative for a specific
/// control statement part.
@immutable
class UserImplementationNarrative {
  /// The ID of the control this narrative belongs to (e.g., "ac-2").
  final String controlId;

  /// The ID of the specific statement part this narrative describes
  /// (e.g., "ac-2.a.1_smt", "si-2_smt.c"). This should be a unique identifier
  /// for the part within the control.
  final String statementPartId;

  /// The user-written narrative text.
  /// This could be plain text, Markdown, or a serialized rich text format
  /// (e.g., JSON string representing Quill Delta).
  /// Using `dynamic` to allow flexibility, but often stored as String.
  final String narrativeText; // Changed to String for simplicity, can be JSON for rich text

  const UserImplementationNarrative({
    required this.controlId,
    required this.statementPartId,
    required this.narrativeText,
  });

  Map<String, dynamic> toJson() {
    return {
      'controlId': controlId,
      'statementPartId': statementPartId,
      'narrativeText': narrativeText,
    };
  }

  factory UserImplementationNarrative.fromJson(Map<String, dynamic> json) {
    return UserImplementationNarrative(
      controlId: json['controlId'] as String,
      statementPartId: json['statementPartId'] as String,
      narrativeText: json['narrativeText'] as String, // Assuming stored as string
    );
  }

   @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserImplementationNarrative &&
          runtimeType == other.runtimeType &&
          controlId == other.controlId &&
          statementPartId == other.statementPartId &&
          narrativeText == other.narrativeText;


  @override
  int get hashCode =>
      controlId.hashCode ^
      statementPartId.hashCode ^
      narrativeText.hashCode;

  @override
  String toString() {
    return 'UserImplementationNarrative(controlId: $controlId, statementPartId: $statementPartId, narrativeText: ${narrativeText.substring(0, narrativeText.length > 50 ? 50 : narrativeText.length)}...)';
  }
}
