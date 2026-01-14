// lib/models/assessment_models.dart

import 'package:json_annotation/json_annotation.dart';

part 'assessment_models.g.dart';

/// Assessment methods as defined in NIST SP 800-53A
enum AssessmentMethod {
  @JsonValue('examine')
  examine,

  @JsonValue('interview')
  interview,

  @JsonValue('test')
  test,
}

/// Extension to provide human-readable names for assessment methods
extension AssessmentMethodExtension on AssessmentMethod {
  String get displayName {
    switch (this) {
      case AssessmentMethod.examine:
        return 'Examine';
      case AssessmentMethod.interview:
        return 'Interview';
      case AssessmentMethod.test:
        return 'Test';
    }
  }

  String get description {
    switch (this) {
      case AssessmentMethod.examine:
        return 'Review, inspect, observe, study, or analyze assessment objects';
      case AssessmentMethod.interview:
        return 'Conduct discussions with individuals or groups';
      case AssessmentMethod.test:
        return 'Exercise assessment objects under specified conditions';
    }
  }
}

/// Individual assessment objective from NIST SP 800-53A
@JsonSerializable()
class AssessmentObjective {
  /// Unique identifier for the assessment objective (e.g., "AC-1a.1(a)")
  final String id;

  /// Description of what needs to be assessed
  final String description;

  /// Primary assessment method for this objective
  final AssessmentMethod method;

  /// Additional assessment methods that may be used
  final List<AssessmentMethod> alternativeMethods;

  /// Assessment objects - what specifically to examine/interview/test
  final List<String> assessmentObjects;

  /// Potential evidence that may satisfy this objective
  final List<String> potentialEvidence;

  const AssessmentObjective({
    required this.id,
    required this.description,
    required this.method,
    this.alternativeMethods = const [],
    this.assessmentObjects = const [],
    this.potentialEvidence = const [],
  });

  factory AssessmentObjective.fromJson(Map<String, dynamic> json) =>
      _$AssessmentObjectiveFromJson(json);

  Map<String, dynamic> toJson() => _$AssessmentObjectiveToJson(this);
}

/// Assessment procedure for a specific control part (e.g., AC-1a, AC-1b)
@JsonSerializable()
class AssessmentProcedure {
  /// Identifier for the control part (e.g., "AC-1a", "AC-1b")
  final String partId;

  /// Human-readable title for this procedure
  final String title;

  /// List of assessment objectives for this procedure
  final List<AssessmentObjective> objectives;

  /// Supplemental guidance specific to assessing this part
  final String? assessmentGuidance;

  const AssessmentProcedure({
    required this.partId,
    required this.title,
    required this.objectives,
    this.assessmentGuidance,
  });

  factory AssessmentProcedure.fromJson(Map<String, dynamic> json) =>
      _$AssessmentProcedureFromJson(json);

  Map<String, dynamic> toJson() => _$AssessmentProcedureToJson(this);
}

/// Complete assessment information for a control from NIST SP 800-53A
@JsonSerializable()
class ControlAssessment {
  /// Control identifier (e.g., "AC-1")
  final String controlId;

  /// Title of the control being assessed
  final String controlTitle;

  /// List of assessment procedures for different parts of the control
  final List<AssessmentProcedure> procedures;

  /// General assessment guidance for the entire control
  final String? generalGuidance;

  /// References to relevant assessment standards or frameworks
  final List<String> references;

  /// Typical assessment scope and considerations
  final String? scopeGuidance;

  const ControlAssessment({
    required this.controlId,
    required this.controlTitle,
    required this.procedures,
    this.generalGuidance,
    this.references = const [],
    this.scopeGuidance,
  });

  factory ControlAssessment.fromJson(Map<String, dynamic> json) =>
      _$ControlAssessmentFromJson(json);

  Map<String, dynamic> toJson() => _$ControlAssessmentToJson(this);

  /// Get all unique assessment methods used across all procedures
  Set<AssessmentMethod> get allMethods {
    final methods = <AssessmentMethod>{};
    for (final procedure in procedures) {
      for (final objective in procedure.objectives) {
        methods.add(objective.method);
        methods.addAll(objective.alternativeMethods);
      }
    }
    return methods;
  }

  /// Get all unique assessment objects across all procedures
  Set<String> get allAssessmentObjects {
    final objects = <String>{};
    for (final procedure in procedures) {
      for (final objective in procedure.objectives) {
        objects.addAll(objective.assessmentObjects);
      }
    }
    return objects;
  }

  /// Get total number of assessment objectives
  int get totalObjectives {
    return procedures.fold(
      0,
      (total, procedure) => total + procedure.objectives.length,
    );
  }
}
