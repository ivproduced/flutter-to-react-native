// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assessment_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssessmentObjective _$AssessmentObjectiveFromJson(Map<String, dynamic> json) =>
    AssessmentObjective(
      id: json['id'] as String,
      description: json['description'] as String,
      method: $enumDecode(_$AssessmentMethodEnumMap, json['method']),
      alternativeMethods:
          (json['alternativeMethods'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$AssessmentMethodEnumMap, e))
              .toList() ??
          const [],
      assessmentObjects:
          (json['assessmentObjects'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      potentialEvidence:
          (json['potentialEvidence'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AssessmentObjectiveToJson(
  AssessmentObjective instance,
) => <String, dynamic>{
  'id': instance.id,
  'description': instance.description,
  'method': _$AssessmentMethodEnumMap[instance.method]!,
  'alternativeMethods':
      instance.alternativeMethods
          .map((e) => _$AssessmentMethodEnumMap[e]!)
          .toList(),
  'assessmentObjects': instance.assessmentObjects,
  'potentialEvidence': instance.potentialEvidence,
};

const _$AssessmentMethodEnumMap = {
  AssessmentMethod.examine: 'examine',
  AssessmentMethod.interview: 'interview',
  AssessmentMethod.test: 'test',
};

AssessmentProcedure _$AssessmentProcedureFromJson(Map<String, dynamic> json) =>
    AssessmentProcedure(
      partId: json['partId'] as String,
      title: json['title'] as String,
      objectives:
          (json['objectives'] as List<dynamic>)
              .map(
                (e) => AssessmentObjective.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      assessmentGuidance: json['assessmentGuidance'] as String?,
    );

Map<String, dynamic> _$AssessmentProcedureToJson(
  AssessmentProcedure instance,
) => <String, dynamic>{
  'partId': instance.partId,
  'title': instance.title,
  'objectives': instance.objectives,
  'assessmentGuidance': instance.assessmentGuidance,
};

ControlAssessment _$ControlAssessmentFromJson(Map<String, dynamic> json) =>
    ControlAssessment(
      controlId: json['controlId'] as String,
      controlTitle: json['controlTitle'] as String,
      procedures:
          (json['procedures'] as List<dynamic>)
              .map(
                (e) => AssessmentProcedure.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
      generalGuidance: json['generalGuidance'] as String?,
      references:
          (json['references'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      scopeGuidance: json['scopeGuidance'] as String?,
    );

Map<String, dynamic> _$ControlAssessmentToJson(ControlAssessment instance) =>
    <String, dynamic>{
      'controlId': instance.controlId,
      'controlTitle': instance.controlTitle,
      'procedures': instance.procedures,
      'generalGuidance': instance.generalGuidance,
      'references': instance.references,
      'scopeGuidance': instance.scopeGuidance,
    };
